import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nexus/core/providers/providers.dart';
import 'package:nexus/core/database/app_database.dart';
import 'package:nexus/core/models/models.dart';
import 'graph_node_model.dart';
import 'graph_edge_model.dart';
import 'goal_graph_controller.dart';
import 'graph_canvas_painter.dart';
import 'graph_interaction_handler.dart';
import 'graph_positions_service.dart';
import 'goal_detail_sheet.dart';
import 'add_goal_form.dart';

// ════════════════════════════════════════════════════════════════════════════
// GOAL VISION PAGE — Obsidian-style Force-Directed Graph
// ════════════════════════════════════════════════════════════════════════════

class GraphPage extends ConsumerStatefulWidget {
  const GraphPage({super.key});
  @override
  ConsumerState<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends ConsumerState<GraphPage>
    with TickerProviderStateMixin {
  late GoalGraphController _controller;
  bool _initialized = false;
  Map<String, Offset> _savedPositions = {};

  // Accent palette — one colour per goal colorIndex
  static const Map<int, Color> _accents = {
    0: Color(0xFF9B6FF5),
    1: Color(0xFF4A90D9),
    2: Color(0xFFE8705A),
    3: Color(0xFFD4A837),
    4: Color(0xFF4AD97A),
    5: Color(0xFFE8922B),
    6: Color(0xFFCC5DE8),
    7: Color(0xFF4AB8E8),
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
    if (viewport != null && mounted) {
      _controller.panOffset = viewport.panOffset;
      _controller.zoomLevel = viewport.zoomLevel;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Data sync ─────────────────────────────────────────────────────────────

  void _syncData(
    List<GoalWithProgress> goals,
    List<GoalDependency> deps,
  ) {
    final nodes = goals.map((gwp) {
      final g = gwp.goal;
      return GraphNode(
        id: g.id,
        label: g.name,
        sublabel: g.aim,
        status: GoalStatus.fromString(g.status),
        colorIndex: g.colorIndex,
        isMainGoal: g.parentId == null || g.parentId!.isEmpty,
        isSubGoal: g.parentId != null && g.parentId!.isNotEmpty,
        progress: gwp.effectiveProgress,
        depth: (g.parentId == null || g.parentId!.isEmpty) ? 1 : 2,
      );
    }).toList();

    final edges = <GraphEdge>[];

    // Sub-goal edges
    for (var gwp in goals) {
      final g = gwp.goal;
      if (g.parentId != null && g.parentId!.isNotEmpty) {
        edges.add(GraphEdge(
          sourceId: g.parentId!,
          targetId: g.id,
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
      final allHaveSaved = nodes.every((n) => _savedPositions.containsKey(n.id));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!allHaveSaved) {
          _controller.reset(MediaQuery.of(context).size);
        } else if (_controller.zoomLevel == 1.0 &&
            _controller.panOffset == Offset.zero) {
          _controller.fitAll(MediaQuery.of(context).size);
        }
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalGraphProvider);
    final depsAsync = ref.watch(allDependenciesProvider);

    return goalsAsync.when(
      data: (goals) => depsAsync.when(
        data: (deps) {
          _syncData(goals, deps);
          return _buildScaffold(goals);
        },
        loading: () => const _LoadingView(),
        error: (_, __) => const _LoadingView(),
      ),
      loading: () => const _LoadingView(),
      error: (e, _) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('Error: $e',
              style: GoogleFonts.inter(color: Colors.white54)),
        ),
      ),
    );
  }

  Widget _buildScaffold(List<GoalWithProgress> goals) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Canvas ──────────────────────────────────────────────────────
          GraphInteractionHandler(
            controller: _controller,
            onNodeTap: (id) {
              final match = goals.firstWhere(
                (g) => g.goal.id == id,
                orElse: () => goals.first,
              );
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) => GoalDetailSheet(goal: match.goal as Goal),
              );
            },
            child: ListenableBuilder(
              listenable: _controller,
              builder: (_, __) => CustomPaint(
                size: Size.infinite,
                painter: GraphCanvasPainter(
                  nodes: _controller.nodes,
                  edges: _controller.edges,
                  panOffset: _controller.panOffset,
                  zoomLevel: _controller.zoomLevel,
                  rotationAngle: _controller.rotationAngle,
                  accentColors: _accents,
                ),
              ),
            ),
          ),

          // ── Top bar ─────────────────────────────────────────────────────
          _TopBar(goals: goals),

          // ── Right-side controls ─────────────────────────────────────────
          Positioned(
            top: 100,
            right: 14,
            child: _ZoomControls(controller: _controller),
          ),

          // ── Bottom overlays ─────────────────────────────────────────────
          Positioned(
            bottom: 24,
            left: 14,
            child: const _Legend(),
          ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: _NodeCountBadge(count: _controller.nodes.length),
            ),
          ),
          Positioned(
            bottom: 24,
            right: 14,
            child: _Minimap(controller: _controller, accents: _accents),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// TOP BAR
// ════════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  final List<GoalWithProgress> goals;
  const _TopBar({required this.goals});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'GOAL VISION',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Dependency graph',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white24,
                    ),
                  ),
                ],
              ),
            ),
            _SmallBtn(
              icon: Icons.add,
              onTap: () => showModalBottomSheet(
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

// ════════════════════════════════════════════════════════════════════════════
// ZOOM CONTROLS
// ════════════════════════════════════════════════════════════════════════════

class _ZoomControls extends StatelessWidget {
  final GoalGraphController controller;
  const _ZoomControls({required this.controller});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Btn(icon: Icons.add, onTap: () => controller.zoom(1.25, Offset.zero, size)),
          _divider,
          _Btn(icon: Icons.remove, onTap: () => controller.zoom(0.8, Offset.zero, size)),
          _divider,
          _Btn(icon: Icons.fit_screen_outlined, onTap: () => controller.fitAll(size)),
          _divider,
          _Btn(
            icon: Icons.refresh,
            onTap: () async {
              await controller.reset(size);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Layout reset',
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                  backgroundColor: const Color(0xFF0A0A0A),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.white12),
                  ),
                  duration: const Duration(seconds: 2),
                ));
              }
            },
          ),
        ],
      ),
    );
  }

  static Widget get _divider =>
      Container(height: 0.5, color: Colors.white.withValues(alpha: 0.07));
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _Btn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, color: Colors.white38, size: 17),
        ),
      );
}

class _SmallBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SmallBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Icon(icon, color: Colors.white54, size: 17),
        ),
      );
}

// ════════════════════════════════════════════════════════════════════════════
// LEGEND
// ════════════════════════════════════════════════════════════════════════════

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _dot(const Color(0xFF27AE60), 'COMPLETED'),
          _dot(Colors.white38, 'IN PROGRESS'),
          _dot(const Color(0xFFE74C3C), 'OVERDUE'),
          const SizedBox(height: 5),
          _edge(solid: true, label: 'DEPENDS ON'),
          _edge(solid: false, label: 'SUB-GOAL'),
        ],
      ),
    );
  }

  Widget _dot(Color c, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 7),
          Text(label,
              style: GoogleFonts.inter(
                  color: Colors.white24,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0)),
        ]),
      );

  Widget _edge({required bool solid, required String label}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          CustomPaint(
              size: const Size(18, 8),
              painter: _EdgeLegendPainter(solid: solid)),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.inter(
                  color: Colors.white24,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0)),
        ]),
      );
}

class _EdgeLegendPainter extends CustomPainter {
  final bool solid;
  const _EdgeLegendPainter({required this.solid});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final y = size.height / 2;

    if (solid) {
      canvas.drawLine(Offset(0, y), Offset(size.width - 5, y), p);
      // Arrowhead
      const tip = Offset(18, 4);
      canvas.drawPath(
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(tip.dx - 4, tip.dy - 2.5)
          ..lineTo(tip.dx - 4, tip.dy + 2.5)
          ..close(),
        Paint()..color = Colors.white24..style = PaintingStyle.fill,
      );
    } else {
      double x = 0;
      while (x < size.width) {
        canvas.drawLine(
            Offset(x, y), Offset(math.min(x + 3, size.width), y), p);
        x += 5;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ════════════════════════════════════════════════════════════════════════════
// NODE COUNT BADGE
// ════════════════════════════════════════════════════════════════════════════

class _NodeCountBadge extends StatelessWidget {
  final int count;
  const _NodeCountBadge({required this.count});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(99),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Text(
          '$count GOALS',
          style: GoogleFonts.inter(
            color: Colors.white24,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      );
}

// ════════════════════════════════════════════════════════════════════════════
// MINIMAP
// ════════════════════════════════════════════════════════════════════════════

class _Minimap extends StatelessWidget {
  final GoalGraphController controller;
  final Map<int, Color> accents;
  const _Minimap({required this.controller, required this.accents});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (_, __) => Container(
        width: 110,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        clipBehavior: Clip.antiAlias,
        child: CustomPaint(
          painter: _MinimapPainter(controller: controller, accents: accents),
        ),
      ),
    );
  }
}

class _MinimapPainter extends CustomPainter {
  final GoalGraphController controller;
  final Map<int, Color> accents;
  _MinimapPainter({required this.controller, required this.accents});

  @override
  void paint(Canvas canvas, Size size) {
    final nodes = controller.nodes;
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

    final graphW = maxX - minX + 120;
    final graphH = maxY - minY + 120;
    final scale = math.min(size.width / graphW, size.height / graphH);
    final cx = size.width / 2 - (minX + maxX) / 2 * scale;
    final cy = size.height / 2 - (minY + maxY) / 2 * scale;
    final offset = Offset(cx, cy);

    // Nodes
    for (var n in nodes) {
      final pos = n.position * scale + offset;
      final r = math.max(n.finalRadius * scale, 1.2);
      canvas.drawCircle(
          pos, r, Paint()..color = (accents[n.colorIndex] ?? Colors.white).withValues(alpha: 0.7));
    }

    // Viewport rect
    final vl = -controller.panOffset.dx / controller.zoomLevel;
    final vt = -controller.panOffset.dy / controller.zoomLevel;
    final vr = vl + 400 / controller.zoomLevel;
    final vb = vt + 800 / controller.zoomLevel;

    final rect = Rect.fromLTRB(
      vl * scale + offset.dx,
      vt * scale + offset.dy,
      vr * scale + offset.dx,
      vb * scale + offset.dy,
    );
    canvas.drawRect(rect,
        Paint()..color = Colors.white.withValues(alpha: 0.05)..style = PaintingStyle.fill);
    canvas.drawRect(
        rect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => true;
}

// ════════════════════════════════════════════════════════════════════════════
// LOADING VIEW
// ════════════════════════════════════════════════════════════════════════════

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white24,
            strokeWidth: 1,
          ),
        ),
      );
}
