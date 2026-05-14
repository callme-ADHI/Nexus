import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'graph_node_model.dart';
import 'graph_edge_model.dart';
import 'graph_physics_engine.dart';
import 'graph_positions_service.dart';

class GoalGraphController extends ChangeNotifier {
  final List<GraphNode> nodes = [];
  final List<GraphEdge> edges = [];

  Offset panOffset = Offset.zero;
  double zoomLevel = 1.0;
  double rotationAngle = 0.0;
  bool isSimulationActive = false;

  // Debounce timer for saving positions after drag
  Timer? _saveDebounce;

  Ticker? _ticker;
  late AnimationController _rotationCtrl;

  GoalGraphController({required TickerProvider vsync}) {
    _ticker = vsync.createTicker(_onTick);
    _rotationCtrl = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 8),
    )..repeat();
    _rotationCtrl.addListener(() {
      rotationAngle = _rotationCtrl.value * 2 * math.pi;
      notifyListeners();
    });
  }

  // ── Physics Tick ──────────────────────────────────────────────────────────

  void _onTick(Duration elapsed) {
    if (!isSimulationActive) return;

    const physicsSize = Size(1000, 1000);
    GraphPhysicsEngine.applyForces(
      nodes: nodes,
      edges: edges,
      canvasSize: physicsSize,
    );

    double maxV = 0;
    for (var n in nodes) {
      maxV = math.max(maxV, n.velocity.distance);
    }

    if (maxV < 0.3) {
      stopSimulation();
      // Auto-save positions after physics settles
      _persistCurrentPositions();
    }
    notifyListeners();
  }

  void startSimulation() {
    isSimulationActive = true;
    if (!(_ticker?.isActive ?? false)) {
      _ticker?.start();
    }
    notifyListeners();
  }

  void stopSimulation() {
    isSimulationActive = false;
    _ticker?.stop();
    notifyListeners();
  }

  // ── Data Sync ─────────────────────────────────────────────────────────────

  /// [savedPositions] = previously persisted positions from shared_preferences.
  void updateData(
    List<GraphNode> newNodes,
    List<GraphEdge> newEdges, {
    required Map<String, Offset> savedPositions,
  }) {
    // Preserve in-memory positions (highest priority: what is currently showing)
    final inMemoryPosMap = {for (var n in nodes) n.id: n.position};

    nodes.clear();
    nodes.addAll(newNodes);

    for (var n in nodes) {
      if (inMemoryPosMap.containsKey(n.id)) {
        // Already placed in this session — keep it
        n.position = inMemoryPosMap[n.id]!;
      } else if (savedPositions.containsKey(n.id)) {
        // Restore persisted position
        n.position = savedPositions[n.id]!;
      }
      // Otherwise position stays at Offset.zero — will be laid out by initialise()
    }

    edges.clear();
    edges.addAll(newEdges);

    // Update finalRadius based on connection count
    for (var node in nodes) {
      final connections = edges
          .where((e) => e.sourceId == node.id || e.targetId == node.id)
          .length;
      node.finalRadius = node.baseRadius + math.min(connections * 1.5, 8.0);
    }

    notifyListeners();
  }

  // ── Node Drag ─────────────────────────────────────────────────────────────

  /// Called every frame during a drag — moves node, no physics restart.
  void moveNode(GraphNode node, Offset canvasPosition) {
    node.position = canvasPosition;
    node.velocity = Offset.zero;
    notifyListeners();
  }

  /// Called when a drag is released — saves layout, no physics restart.
  void onNodeDropped() {
    _scheduleSave();
  }

  // ── Viewport ──────────────────────────────────────────────────────────────

  void pan(Offset delta) {
    panOffset += delta;
    notifyListeners();
    _scheduleViewportSave();
  }

  /// [scaleDelta] is the ratio between current and previous frame scale.
  /// [focalPoint] is in screen coordinates.
  void zoomAt(double scaleDelta, Offset focalPoint) {
    final oldZoom = zoomLevel;
    zoomLevel = (zoomLevel * scaleDelta).clamp(0.15, 4.0);

    // Adjust pan so the focal point stays fixed on screen
    final focalCanvas = (focalPoint - panOffset) / oldZoom;
    panOffset = focalPoint - focalCanvas * zoomLevel;

    notifyListeners();
    _scheduleViewportSave();
  }

  /// Button-based zoom (centres on screen centre).
  void zoom(double factor, Offset focalPointScreen, Size screenSize) {
    final focal = focalPointScreen == Offset.zero
        ? Offset(screenSize.width / 2, screenSize.height / 2)
        : focalPointScreen;
    zoomAt(factor, focal);
  }

  // ── Fit / Reset ───────────────────────────────────────────────────────────

  void fitAll(Size screenSize) {
    if (nodes.isEmpty) return;

    double minX = nodes.first.position.dx;
    double maxX = nodes.first.position.dx;
    double minY = nodes.first.position.dy;
    double maxY = nodes.first.position.dy;

    for (var n in nodes) {
      minX = math.min(minX, n.position.dx);
      maxX = math.max(maxX, n.position.dx);
      minY = math.min(minY, n.position.dy);
      maxY = math.max(maxY, n.position.dy);
    }

    final graphW = maxX - minX + 200;
    final graphH = maxY - minY + 200;

    final scaleX = screenSize.width / graphW;
    final scaleY = screenSize.height / graphH;
    zoomLevel = math.min(scaleX, scaleY).clamp(0.15, 4.0);

    final centerX = (minX + maxX) / 2;
    final centerY = (minY + maxY) / 2;

    panOffset = Offset(
      screenSize.width / 2 - centerX * zoomLevel,
      screenSize.height / 2 - centerY * zoomLevel,
    );
    notifyListeners();
  }

  Future<void> reset(Size screenSize) async {
    stopSimulation();
    await GraphPositionsService.clearPositions();

    GraphPhysicsEngine.initializePositions(nodes, const Size(1000, 1000));
    _warmup();
    fitAll(screenSize);

    // Let physics settle visually for a moment then stop
    startSimulation();
  }

  void _warmup() {
    const physicsSize = Size(1000, 1000);
    for (int i = 0; i < 150; i++) {
      GraphPhysicsEngine.applyForces(
        nodes: nodes,
        edges: edges,
        canvasSize: physicsSize,
      );
    }
  }

  // ── Persistence Helpers ───────────────────────────────────────────────────

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 400), _persistCurrentPositions);
  }

  void _scheduleViewportSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 800), () {
      GraphPositionsService.saveViewport(
        panOffset: panOffset,
        zoomLevel: zoomLevel,
      );
    });
  }

  void _persistCurrentPositions() {
    final map = {for (var n in nodes) n.id: n.position};
    GraphPositionsService.savePositions(map);
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _ticker?.dispose();
    _rotationCtrl.dispose();
    super.dispose();
  }
}
