import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../core/database/app_database.dart';
import '../../core/models/models.dart';
import '../../shared/theme/app_theme.dart';
import 'goal_detail_sheet.dart';
import 'add_goal_form.dart';

// ════════════════════════════════════════════════════════════════════════════
// GRAPH PAGE — Obsidian-style, high-performance
//
// Performance strategy:
//  • Layout is computed ONCE synchronously (max 400 iterations) then frozen.
//  • No AnimationController.repeat() — only a single one-shot entrance anim.
//  • Edges are painted in a single CustomPaint pass per frame.
//  • Node rebuilds are isolated — only changed nodes rebuild.
//  • Pan/zoom handled by InteractiveViewer (hardware-accelerated).
// ════════════════════════════════════════════════════════════════════════════

class GraphPage extends ConsumerWidget {
  const GraphPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalGraph = ref.watch(goalGraphProvider);
    final allDeps   = ref.watch(allDependenciesProvider);
    final size      = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Canvas ────────────────────────────────────────────────────
          goalGraph.when(
            data: (goals) => allDeps.when(
              data: (deps) {
                if (goals.isEmpty) return const _EmptyGraph();
                return _GraphView(
                  goals: goals,
                  deps: deps,
                  canvasSize: size,
                  onNodeTap: (goal) => _openDetail(context, goal),
                );
              },
              loading: () => const _GraphLoading(),
              error: (_, __) => const _GraphLoading(),
            ),
            loading: () => const _GraphLoading(),
            error: (e, _) => Center(
              child: Text('Error: $e',
                  style: AppTypography.body.copyWith(color: AppColors.accentRed)),
            ),
          ),

          // ── Header ────────────────────────────────────────────────────
          _Header(
            onAdd: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const AddGoalForm(),
            ),
          ),

          // ── Legend ────────────────────────────────────────────────────
          const Positioned(
            bottom: 24,
            right: 16,
            child: _Legend(),
          ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, Goal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GoalDetailSheet(goal: goal),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// FORCE LAYOUT — computed synchronously, one shot
// ════════════════════════════════════════════════════════════════════════════

class _ForceLayout {
  static const double _repulsion  = 9000;
  static const double _attraction = 0.045;
  static const double _idealDist  = 190;
  static const double _damping    = 0.80;
  static const double _centerG    = 0.003;
  static const double _minEnergy  = 0.25;
  static const int    _maxSteps   = 400;

  /// Compute stable node positions for [ids] given [edges] within [bounds].
  static Map<String, Offset> compute({
    required List<String> ids,
    required List<(String, String)> edges,
    required Size bounds,
  }) {
    if (ids.isEmpty) return {};

    final rng = math.Random(42); // fixed seed → deterministic layout
    final pos = <String, Offset>{};
    final vel = <String, Offset>{};

    // Initialize on a circle
    final cx = bounds.width  / 2;
    final cy = bounds.height / 2;
    final r  = math.min(bounds.width, bounds.height) * 0.30;

    for (int i = 0; i < ids.length; i++) {
      final angle = (2 * math.pi * i) / ids.length;
      pos[ids[i]] = Offset(
        cx + r * math.cos(angle) + (rng.nextDouble() - 0.5) * 20,
        cy + r * math.sin(angle) + (rng.nextDouble() - 0.5) * 20,
      );
      vel[ids[i]] = Offset.zero;
    }

    // Iterate
    for (int step = 0; step < _maxSteps; step++) {
      double totalEnergy = 0;

      for (int i = 0; i < ids.length; i++) {
        Offset force = Offset.zero;
        final posI = pos[ids[i]]!;

        // Repulsion from all others
        for (int j = 0; j < ids.length; j++) {
          if (i == j) continue;
          final delta = posI - pos[ids[j]]!;
          final dist  = delta.distance.clamp(5.0, 500.0);
          force += delta / (dist * dist) * _repulsion;
        }

        // Spring attraction along edges
        for (final (a, b) in edges) {
          final other = a == ids[i] ? b : (b == ids[i] ? a : null);
          if (other == null || !pos.containsKey(other)) continue;
          final delta = pos[other]! - posI;
          final dist  = delta.distance.clamp(1.0, double.infinity);
          final disp  = dist - _idealDist;
          force += delta / dist * disp * _attraction;
        }

        // Weak center gravity
        force += (Offset(cx, cy) - posI) * _centerG;

        final v = ((vel[ids[i]]! + force * 0.016) * _damping);
        vel[ids[i]] = v;
        pos[ids[i]] = posI + v;
        totalEnergy += v.distanceSquared;
      }

      if (totalEnergy < _minEnergy) break;
    }

    return pos;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// GRAPH VIEW — the actual interactive widget
// ════════════════════════════════════════════════════════════════════════════

class _GraphView extends StatefulWidget {
  final List<GoalWithProgress> goals;
  final List<GoalDependency>   deps;
  final Size                   canvasSize;
  final ValueChanged<Goal>     onNodeTap;

  const _GraphView({
    required this.goals,
    required this.deps,
    required this.canvasSize,
    required this.onNodeTap,
  });

  @override
  State<_GraphView> createState() => _GraphViewState();
}

class _GraphViewState extends State<_GraphView>
    with SingleTickerProviderStateMixin {

  late Map<String, Offset> _positions;
  late List<(String, String)> _edges;

  // One-shot entrance animation
  late final AnimationController _entranceCtrl;
  late final Animation<double>   _entranceFade;
  late final Animation<double>   _entranceScale;

  // Dragged node
  String? _dragId;

  @override
  void initState() {
    super.initState();

    _edges = _buildEdges();
    _computeLayout();

    // One-shot entrance — runs once, 600ms, never repeats
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entranceFade = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _entranceScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutBack),
    );
    _entranceCtrl.forward();
  }

  @override
  void didUpdateWidget(_GraphView old) {
    super.didUpdateWidget(old);
    // Recompute layout only when the number of goals changes
    if (old.goals.length != widget.goals.length) {
      _edges = _buildEdges();
      _computeLayout();
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  List<(String, String)> _buildEdges() {
    final edges = <(String, String)>[];
    for (final d in widget.deps) {
      edges.add((d.goalId, d.dependsOnId));
    }
    for (final gwp in widget.goals) {
      final goal = gwp.goal as Goal;
      if (goal.parentId != null && goal.parentId!.isNotEmpty) {
        edges.add((goal.id, goal.parentId!));
      }
    }
    return edges;
  }

  void _computeLayout() {
    final ids = widget.goals.map((g) => (g.goal as Goal).id).toList();
    // Use a canvas 3× the screen size for panning room
    final layoutBounds = Size(
      widget.canvasSize.width  * 2.5,
      widget.canvasSize.height * 2.5,
    );
    _positions = _ForceLayout.compute(
      ids: ids,
      edges: _edges,
      bounds: layoutBounds,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _entranceFade,
      child: ScaleTransition(
        scale: _entranceScale,
        child: InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(double.infinity),
          minScale: 0.25,
          maxScale: 3.0,
          child: SizedBox(
            // Canvas is larger than screen to allow panning
            width:  widget.canvasSize.width  * 2.5,
            height: widget.canvasSize.height * 2.5,
            child: Stack(
              children: [
                // Edge layer — single CustomPaint
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _EdgePainter(
                        goals: widget.goals,
                        deps: widget.deps,
                        positions: _positions,
                      ),
                    ),
                  ),
                ),

                // Node layer
                ...widget.goals.map((gwp) {
                  final goal = gwp.goal as Goal;
                  final pos  = _positions[goal.id] ?? Offset(
                    widget.canvasSize.width  * 1.25,
                    widget.canvasSize.height * 1.25,
                  );

                  return Positioned(
                    left: pos.dx - 48,
                    top:  pos.dy - 48,
                    child: _NodeTile(
                      gwp: gwp,
                      onTap: () => widget.onNodeTap(goal),
                      onDragStart: () => setState(() => _dragId = goal.id),
                      onDragUpdate: (delta) {
                        if (_dragId == goal.id) {
                          setState(() {
                            _positions[goal.id] = pos + delta;
                          });
                        }
                      },
                      onDragEnd: () => setState(() => _dragId = null),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// EDGE PAINTER — single pass, bezier curves + arrows
// ════════════════════════════════════════════════════════════════════════════

class _EdgePainter extends CustomPainter {
  final List<GoalWithProgress> goals;
  final List<GoalDependency>   deps;
  final Map<String, Offset>    positions;

  const _EdgePainter({
    required this.goals,
    required this.deps,
    required this.positions,
  });

  static final _depPaint = Paint()
    ..color = const Color(0x882563EB) // accentBlue semi-transparent
    ..strokeWidth = 1.8
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  static final _parentPaint = Paint()
    ..color = const Color(0x44FFFFFF)
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    // Dependency edges (solid blue with arrow)
    for (final dep in deps) {
      final from = positions[dep.dependsOnId];
      final to   = positions[dep.goalId];
      if (from == null || to == null) continue;
      _drawArrow(canvas, from, to, _depPaint, dashed: false);
    }

    // Parent-child edges (dashed grey)
    for (final gwp in goals) {
      final goal = gwp.goal as Goal;
      if (goal.parentId == null || goal.parentId!.isEmpty) continue;
      final from = positions[goal.parentId!];
      final to   = positions[goal.id];
      if (from == null || to == null) continue;
      _drawArrow(canvas, from, to, _parentPaint, dashed: true);
    }
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Paint paint, {required bool dashed}) {
    final mid  = (from + to) / 2;
    // Slight upward ctrl point for curvature
    final perp = Offset(-(to.dy - from.dy), to.dx - from.dx).normalized * 30;
    final ctrl = mid + perp;

    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, to.dx, to.dy);

    if (dashed) {
      _drawDashed(canvas, path, paint);
    } else {
      canvas.drawPath(path, paint);
    }

    // Arrow head (only for dep edges)
    if (!dashed) {
      final angle = math.atan2(to.dy - ctrl.dy, to.dx - ctrl.dx);
      const aLen = 10.0;
      const aAng = 0.38;
      canvas.drawLine(to,
          Offset(to.dx - aLen * math.cos(angle - aAng), to.dy - aLen * math.sin(angle - aAng)),
          paint);
      canvas.drawLine(to,
          Offset(to.dx - aLen * math.cos(angle + aAng), to.dy - aLen * math.sin(angle + aAng)),
          paint);
    }
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    const dash = 7.0;
    const gap  = 5.0;
    final metrics = path.computeMetrics().toList();
    for (final m in metrics) {
      double dist = 0;
      bool   draw = true;
      while (dist < m.length) {
        final next = (dist + (draw ? dash : gap)).clamp(0.0, m.length);
        if (draw) canvas.drawPath(m.extractPath(dist, next), paint);
        dist = next;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(_EdgePainter old) =>
      old.positions != positions ||
      old.goals.length != goals.length ||
      old.deps.length != deps.length;
}

extension on Offset {
  Offset get normalized {
    final d = distance;
    return d < 0.001 ? Offset.zero : this / d;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// NODE TILE
// ════════════════════════════════════════════════════════════════════════════

class _NodeTile extends StatefulWidget {
  final GoalWithProgress gwp;
  final VoidCallback     onTap;
  final VoidCallback     onDragStart;
  final ValueChanged<Offset> onDragUpdate;
  final VoidCallback     onDragEnd;

  const _NodeTile({
    required this.gwp,
    required this.onTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  State<_NodeTile> createState() => _NodeTileState();
}

class _NodeTileState extends State<_NodeTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tapCtrl;
  late final Animation<double>   _tapScale;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _tapScale = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goal     = widget.gwp.goal as Goal;
    final progress = widget.gwp.effectiveProgress;
    final status   = widget.gwp.status;
    final accent   = _statusColor(status);

    return GestureDetector(
      onTap: () {
        _tapCtrl.forward(from: 0).then((_) => _tapCtrl.reverse());
        widget.onTap();
      },
      onPanStart: (_) => widget.onDragStart(),
      onPanUpdate: (d) => widget.onDragUpdate(d.delta),
      onPanEnd: (_) => widget.onDragEnd(),
      child: ScaleTransition(
        scale: _tapScale,
        child: SizedBox(
          width: 96,
          height: 96,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Node circle with progress arc
              SizedBox(
                width: 56,
                height: 56,
                child: CustomPaint(
                  painter: _NodePainter(
                    progress: progress,
                    accent: accent,
                  ),
                  child: Center(
                    child: Text(
                      '${progress.round()}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Label
              SizedBox(
                width: 90,
                child: Text(
                  goal.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(GoalStatus s) => switch (s) {
    GoalStatus.blocked    => const Color(0xFF444444),
    GoalStatus.notStarted => const Color(0xFF666666),
    GoalStatus.inProgress => const Color(0xFF2563EB),
    GoalStatus.completed  => const Color(0xFF27AE60),
    GoalStatus.overdue    => const Color(0xFFE74C3C),
  };
}

class _NodePainter extends CustomPainter {
  final double progress;
  final Color  accent;

  const _NodePainter({required this.progress, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Glow
    canvas.drawCircle(
      center,
      radius + 4,
      Paint()
        ..color = accent.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Background circle
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = accent.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill,
    );

    // Border ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = accent.withValues(alpha: 0.45)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 1),
        -math.pi / 2,
        2 * math.pi * (progress / 100),
        false,
        Paint()
          ..color = accent
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_NodePainter old) =>
      old.progress != progress || old.accent != accent;
}

// ════════════════════════════════════════════════════════════════════════════
// HEADER
// ════════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  final VoidCallback onAdd;
  const _Header({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          MediaQuery.of(context).padding.top + AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.85),
              Colors.black.withValues(alpha: 0.0),
            ],
            stops: const [0.55, 1.0],
          ),
        ),
        child: Row(
          children: [
            Text('Goal Graph', style: AppTypography.pageTitle),
            const Spacer(),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.button,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.add, size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
        color: Colors.black.withValues(alpha: 0.80),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _row(const Color(0xFF2563EB), 'In Progress'),
          _row(const Color(0xFF27AE60), 'Completed'),
          _row(const Color(0xFFE74C3C), 'Overdue'),
          _row(const Color(0xFF666666), 'Not Started'),
          _row(const Color(0xFF444444), 'Blocked'),
        ],
      ),
    );
  }

  Widget _row(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.18),
              border: Border.all(color: color, width: 1.5),
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.caption.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// EMPTY + LOADING
// ════════════════════════════════════════════════════════════════════════════

class _EmptyGraph extends StatelessWidget {
  const _EmptyGraph();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.hub_outlined, color: AppColors.textSecondary, size: 56),
          const SizedBox(height: 20),
          Text('Goal graph is empty',
              style: AppTypography.cardTitle.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(
            'Long-press the nav bubble and select the\n"+" button to add your first goal.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _GraphLoading extends StatelessWidget {
  const _GraphLoading();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: AppColors.accentBlue));
}
