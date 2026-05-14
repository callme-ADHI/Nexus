import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'graph_node_model.dart';
import 'graph_edge_model.dart';
import 'graph_physics_engine.dart';

class GoalGraphController extends ChangeNotifier {
  final List<GraphNode> nodes = [];
  final List<GraphEdge> edges = [];

  Offset panOffset = Offset.zero;
  double zoomLevel = 1.0;
  double rotationAngle = 0.0;
  bool isSimulationActive = false;

  Ticker? _ticker;
  late AnimationController _rotationCtrl;
  late AnimationController _hoverAnimCtrl;

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

    _hoverAnimCtrl = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 150),
    );
  }

  void _onTick(Duration elapsed) {
    if (!isSimulationActive) return;
    
    // We'll define a virtual canvas size for physics
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
    }
    notifyListeners();
  }

  void startSimulation() {
    isSimulationActive = true;
    _ticker?.start();
    notifyListeners();
  }

  void stopSimulation() {
    isSimulationActive = false;
    _ticker?.stop();
    notifyListeners();
  }

  void restartSimulation() {
    for (var n in nodes) n.velocity = Offset.zero;
    if (!isSimulationActive) startSimulation();
  }

  void warmup() {
    const physicsSize = Size(1000, 1000);
    for (int i = 0; i < 120; i++) {
      GraphPhysicsEngine.applyForces(
        nodes: nodes,
        edges: edges,
        canvasSize: physicsSize,
      );
    }
  }

  void updateData(List<GraphNode> newNodes, List<GraphEdge> newEdges) {
    // Basic sync logic: preserve positions for existing nodes
    final oldPosMap = {for (var n in nodes) n.id: n.position};
    nodes.clear();
    nodes.addAll(newNodes);
    for (var n in nodes) {
      if (oldPosMap.containsKey(n.id)) {
        n.position = oldPosMap[n.id]!;
      }
    }
    edges.clear();
    edges.addAll(newEdges);
    
    // Update finalRadius based on connections
    for (var node in nodes) {
      int connections = edges.where((e) => e.sourceId == node.id || e.targetId == node.id).length;
      node.finalRadius = node.baseRadius + math.min(connections * 1.5, 8.0);
    }

    notifyListeners();
  }

  void pan(Offset delta) {
    panOffset += delta;
    notifyListeners();
  }

  void zoom(double factor, Offset focalPointScreen, Size screenSize) {
    final oldZoom = zoomLevel;
    zoomLevel = (zoomLevel * factor).clamp(0.25, 3.5);
    
    final focalPointCanvas = (focalPointScreen - panOffset) / oldZoom;
    panOffset -= (focalPointCanvas * (zoomLevel / oldZoom - 1.0)) * oldZoom;
    
    notifyListeners();
  }

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

    final graphW = maxX - minX + 160;
    final graphH = maxY - minY + 160;

    final scaleX = screenSize.width / graphW;
    final scaleY = screenSize.height / graphH;
    zoomLevel = math.min(scaleX, scaleY).clamp(0.25, 3.5);

    final centerX = (minX + maxX) / 2;
    final centerY = (minY + maxY) / 2;

    panOffset = Offset(
      screenSize.width / 2 - centerX * zoomLevel,
      screenSize.height / 2 - centerY * zoomLevel,
    );
    notifyListeners();
  }

  void reset(Size screenSize) {
    GraphPhysicsEngine.initializePositions(nodes, const Size(1000, 1000));
    warmup();
    fitAll(screenSize);
    restartSimulation();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _rotationCtrl.dispose();
    _hoverAnimCtrl.dispose();
    super.dispose();
  }
}
