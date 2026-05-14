import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nexus/core/providers/providers.dart';
import 'package:nexus/core/database/app_database.dart';
import 'package:nexus/core/models/models.dart';
import 'package:nexus/shared/theme/app_theme.dart';
import 'graph_node_model.dart';
import 'graph_edge_model.dart';
import 'graph_physics_engine.dart';
import 'goal_graph_controller.dart';
import 'graph_canvas_painter.dart';
import 'graph_interaction_handler.dart';
import 'graph_positions_service.dart';
import 'goal_detail_sheet.dart';
import 'add_goal_form.dart';

// ════════════════════════════════════════════════════════════════════════════
// GOAL VISION PAGE — Obsidian-style Force Directed Graph
// ════════════════════════════════════════════════════════════════════════════

class GraphPage extends ConsumerStatefulWidget {
  const GraphPage({super.key});

  @override
  ConsumerState<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends ConsumerState<GraphPage> with TickerProviderStateMixin {
  late GoalGraphController _controller;
  bool _initialized = false;
  Map<String, Offset> _savedPositions = {};

  final Map<int, Color> accentColors = {
    0: const Color(0xFF9B6FF5), // Violet
    1: const Color(0xFF4A90D9), // Blue
    2: const Color(0xFFE8705A), // Coral
    3: const Color(0xFFD4A837), // Gold
    4: const Color(0xFF4AD97A), // Mint
    5: const Color(0xFFE8922B), // Orange
    6: const Color(0xFFCC5DE8), // Purple-pink
    7: const Color(0xFF4AB8E8), // Sky
  };

  @override
  void initState() {
    super.initState();
    _controller = GoalGraphController(vsync: this);
    _loadPersistedState();
  }

  Future<void> _loadPersistedState() async {
    _savedPositions = await GraphPositionsService.loadPositions();
    final viewport = await GraphPositionsService.loadViewport();
    if (viewport != null) {
      _controller.panOffset = viewport.panOffset;
      _controller.zoomLevel = viewport.zoomLevel;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncData(List<GoalWithProgress> goals, List<GoalDependency> deps) {
    final nodes = goals.map((gwp) {
      final g = gwp.goal;
      return GraphNode(
        id: g.id,
        label: g.name,
        sublabel: g.aim,
        status: _mapStatus(g.status),
        colorIndex: g.colorIndex,
        isMainGoal: g.parentId == null || g.parentId!.isEmpty,
        isSubGoal: g.parentId != null && g.parentId!.isNotEmpty,
        progress: gwp.effectiveProgress,
        depth: g.parentId == null ? 1 : 2, // Simplified depth for now
      );
    }).toList();

    final edges = <GraphEdge>[];
    
    // Sub-goal edges
    for (var gwp in goals) {
      if (gwp.goal.parentId != null && gwp.goal.parentId!.isNotEmpty) {
        edges.add(GraphEdge(
          sourceId: gwp.goal.parentId!,
          targetId: gwp.goal.id,
          type: EdgeType.subgoal,
        ));
      }
    }

    // Dependency edges
    for (var dep in deps) {
      edges.add(GraphEdge(
        sourceId: dep.dependsOnId,
        targetId: dep.goalId,
        type: EdgeType.dependency,
      ));
    }

    _controller.updateData(nodes, edges, savedPositions: _savedPositions);

    if (!_initialized && nodes.isNotEmpty) {
      _initialized = true;
      // Only run physics layout if we have NO saved positions for these nodes
      final allHaveSavedPositions = nodes.every((n) => _savedPositions.containsKey(n.id));
      if (!allHaveSavedPositions) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _controller.reset(MediaQuery.of(context).size);
        });
      } else {
        // Positions loaded from storage — just fit the viewport if no saved viewport
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_controller.zoomLevel == 1.0 && _controller.panOffset == Offset.zero) {
            _controller.fitAll(MediaQuery.of(context).size);
          }
        });
      }
    }
  }

  GoalStatus _mapStatus(String s) {
    switch (s.toLowerCase()) {
      case 'completed': return GoalStatus.completed;
      case 'blocked': return GoalStatus.blocked;
      case 'overdue': return GoalStatus.overdue;
      case 'in_progress': return GoalStatus.inProgress;
      default: return GoalStatus.notStarted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalGraphProvider);
    final depsAsync = ref.watch(allDependenciesProvider);

    return goalsAsync.when(
      data: (goals) => depsAsync.when(
        data: (deps) {
          _syncData(goals, deps);
          return _buildGraphView(goals);
        },
        loading: () => const _LoadingView(),
        error: (_, __) => const _LoadingView(),
      ),
      loading: () => const _LoadingView(),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildGraphView(List<GoalWithProgress> goals) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          // The Canvas Interaction Layer
          GraphInteractionHandler(
            controller: _controller,
            onNodeTap: (id) => showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (_) => GoalDetailSheet(
                goal: goals.firstWhere((gwp) => gwp.goal.id == id).goal as Goal,
              ),
            ),
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) => CustomPaint(
                size: Size.infinite,
                painter: GraphCanvasPainter(
                  nodes: _controller.nodes,
                  edges: _controller.edges,
                  panOffset: _controller.panOffset,
                  zoomLevel: _controller.zoomLevel,
                  rotationAngle: _controller.rotationAngle,
                  accentColors: accentColors,
                ),
              ),
            ),
          ),

          // Top Bar
          const _TopBar(),

          // Zoom Controls
          Positioned(
            top: 100,
            right: 16,
            child: _ZoomControls(controller: _controller),
          ),

          // Legend
          const Positioned(
            bottom: 20,
            left: 20,
            child: _Legend(),
          ),

          // Node Count
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(child: _NodeCountBadge(count: _controller.nodes.length)),
          ),

          // Minimap
          Positioned(
            bottom: 20,
            right: 20,
            child: _Minimap(controller: _controller, accentColors: accentColors),
          ),
        ],
      ),
    );
  }
}

// ── UI OVERLAYS ─────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('GOAL VISION', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 2, color: Colors.white)),
                Text('Interactive dependency graph', style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 24),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const AddGoalForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  final GoalGraphController controller;
  const _ZoomControls({required this.controller});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Column(
      children: [
        _btn(Icons.add, () => controller.zoom(1.25, Offset.zero, size)),
        const SizedBox(height: 8),
        _btn(Icons.remove, () => controller.zoom(0.8, Offset.zero, size)),
        const SizedBox(height: 8),
        _btn(Icons.fit_screen, () => controller.fitAll(size)),
        const SizedBox(height: 8),
        _btn(Icons.refresh, () async {
          await controller.reset(size);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Layout reset', style: GoogleFonts.inter(color: Colors.white)),
                backgroundColor: const Color(0xFF1E1E2A),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }),
      ],
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: const Color(0xCC121218),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2E2E42)),
        ),
        child: Icon(icon, color: Colors.white70, size: 18),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xE6121218),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2E2E42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _row(const Color(0xFF3FC47A), 'DONE'),
          _row(Colors.white54, 'ACTIVE'),
          _row(const Color(0xFFD94A4A), 'OVERDUE'),
          const SizedBox(height: 8),
          _row(Colors.white, 'MAIN GOAL', hollow: true),
          _row(Colors.white24, 'SUB GOAL', small: true),
        ],
      ),
    );
  }

  Widget _row(Color c, String l, {bool hollow = false, bool small = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: small ? 6 : 8, height: small ? 6 : 8,
            decoration: BoxDecoration(
              color: hollow ? Colors.transparent : c,
              shape: BoxShape.circle,
              border: hollow ? Border.all(color: c, width: 1) : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(l, style: GoogleFonts.inter(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ),
    );
  }
}

class _NodeCountBadge extends StatelessWidget {
  final int count;
  const _NodeCountBadge({required this.count});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: const Color(0xCC121218), borderRadius: BorderRadius.circular(99)),
    child: Text('$count GOALS', style: GoogleFonts.inter(color: Colors.white60, fontSize: 10, letterSpacing: 1)),
  );
}

class _Minimap extends StatelessWidget {
  final GoalGraphController controller;
  final Map<int, Color> accentColors;
  const _Minimap({required this.controller, required this.accentColors});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Container(
        width: 120, height: 90,
        decoration: BoxDecoration(
          color: const Color(0xE6121218),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF2E2E42)),
        ),
        clipBehavior: Clip.antiAlias,
        child: CustomPaint(
          painter: _MinimapPainter(controller: controller, accentColors: accentColors),
        ),
      ),
    );
  }
}

class _MinimapPainter extends CustomPainter {
  final GoalGraphController controller;
  final Map<int, Color> accentColors;
  _MinimapPainter({required this.controller, required this.accentColors});

  @override
  void paint(Canvas canvas, Size size) {
    if (controller.nodes.isEmpty) return;
    
    // Calculate bounds of all nodes
    double minX = controller.nodes.first.position.dx;
    double maxX = controller.nodes.first.position.dx;
    double minY = controller.nodes.first.position.dy;
    double maxY = controller.nodes.first.position.dy;

    for (var n in controller.nodes) {
      minX = math.min(minX, n.position.dx);
      maxX = math.max(maxX, n.position.dx);
      minY = math.min(minY, n.position.dy);
      maxY = math.max(maxY, n.position.dy);
    }

    final graphW = maxX - minX + 200;
    final graphH = maxY - minY + 200;
    final scale = math.min(size.width / graphW, size.height / graphH);
    
    final offset = Offset(size.width / 2 - (minX + maxX) / 2 * scale, size.height / 2 - (minY + maxY) / 2 * scale);

    // Draw Nodes
    for (var node in controller.nodes) {
      final pos = node.position * scale + offset;
      final radius = math.max(node.finalRadius * scale, 1.5);
      canvas.drawCircle(pos, radius, Paint()..color = accentColors[node.colorIndex] ?? Colors.white);
    }

    // Draw Viewport Rect
    final viewLeft = -controller.panOffset.dx / controller.zoomLevel;
    final viewTop = -controller.panOffset.dy / controller.zoomLevel;
    final viewRight = viewLeft + 400 / controller.zoomLevel; // Approx screen size
    final viewBottom = viewTop + 800 / controller.zoomLevel;

    final rectLeft = viewLeft * scale + offset.dx;
    final rectTop = viewTop * scale + offset.dy;
    final rectRight = viewRight * scale + offset.dx;
    final rectBottom = viewBottom * scale + offset.dy;

    canvas.drawRect(
      Rect.fromLTRB(rectLeft, rectTop, rectRight, rectBottom),
      Paint()..color = Colors.white.withValues(alpha: 0.08)..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      Rect.fromLTRB(rectLeft, rectTop, rectRight, rectBottom),
      Paint()..color = Colors.white.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) => const Scaffold(backgroundColor: Color(0xFF0A0A0F), body: Center(child: CircularProgressIndicator(color: Colors.white)));
}
