import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../core/database/app_database.dart';
import '../../core/models/models.dart';
import '../../shared/theme/app_theme.dart';
import 'goal_detail_sheet.dart';
import 'add_goal_form.dart';

// ════════════════════════════════════════════════════════════════════════════
// GRAPH PAGE — Obsidian-style Force Directed Graph
// ════════════════════════════════════════════════════════════════════════════

class GraphPage extends ConsumerWidget {
  const GraphPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalGraph = ref.watch(goalGraphProvider);
    final allDeps = ref.watch(allDependenciesProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          goalGraph.when(
            data: (goals) => allDeps.when(
              data: (deps) {
                if (goals.isEmpty) return const _EmptyGraph();
                return _GraphSimulator(goals: goals, deps: deps);
              },
              loading: () => const _GraphLoading(),
              error: (_, __) => const _GraphLoading(),
            ),
            loading: () => const _GraphLoading(),
            error: (e, _) => Center(child: Text('Error: $e', style: AppTypography.caption)),
          ),
          
          // Header
          const _Header(),
          
          // Floating Controls
          Positioned(
            bottom: 32,
            right: 16,
            child: _GraphControls(),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SIMULATOR — Handles the physics loop and rendering
// ════════════════════════════════════════════════════════════════════════════

class _GraphSimulator extends StatefulWidget {
  final List<GoalWithProgress> goals;
  final List<GoalDependency> deps;

  const _GraphSimulator({required this.goals, required this.deps});

  @override
  State<_GraphSimulator> createState() => _GraphSimulatorState();
}

class _GraphSimulatorState extends State<_GraphSimulator> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final List<_Node> _nodes = [];
  final List<_Edge> _edges = [];
  
  final TransformationController _transformCtrl = TransformationController();
  
  // Simulation Constants
  static const double repulsion = 120.0;
  static const double linkStrength = 0.08;
  static const double gravity = 0.015;
  static const double friction = 0.94;

  @override
  void initState() {
    super.initState();
    _initGraph();
    _ticker = createTicker(_onTick)..start();
  }

  void _initGraph() {
    _nodes.clear();
    _edges.clear();
    
    final rand = math.Random();
    final nodeMap = <String, _Node>{};

    for (var gwp in widget.goals) {
      final goal = gwp.goal as Goal;
      final isMain = goal.parentId == null || goal.parentId!.isEmpty;
      
      final node = _Node(
        id: goal.id,
        label: goal.name,
        color: _statusColor(gwp.status),
        weight: gwp.effectiveProgress,
        radius: isMain ? 10.0 : 4.5,
        isMain: isMain,
        x: (rand.nextDouble() - 0.5) * 500,
        y: (rand.nextDouble() - 0.5) * 500,
      );
      _nodes.add(node);
      nodeMap[goal.id] = node;
    }

    for (var dep in widget.deps) {
      if (nodeMap.containsKey(dep.goalId) && nodeMap.containsKey(dep.dependsOnId)) {
        _edges.add(_Edge(source: nodeMap[dep.dependsOnId]!, target: nodeMap[dep.goalId]!));
      }
    }

    for (var gwp in widget.goals) {
      final goal = gwp.goal as Goal;
      if (goal.parentId != null && nodeMap.containsKey(goal.parentId)) {
        _edges.add(_Edge(source: nodeMap[goal.parentId]!, target: nodeMap[goal.id]!, isParent: true));
      }
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;

    // 1. Repulsion (Nodes push each other away)
    for (int i = 0; i < _nodes.length; i++) {
      for (int j = i + 1; j < _nodes.length; j++) {
        final nodeA = _nodes[i];
        final nodeB = _nodes[j];
        
        double dx = nodeB.x - nodeA.x;
        double dy = nodeB.y - nodeA.y;
        double distanceSq = dx * dx + dy * dy + 0.1;
        
        if (distanceSq < 100000) { // Limit influence range
          double force = repulsion / distanceSq;
          double fx = dx * force;
          double fy = dy * force;
          
          nodeA.vx -= fx;
          nodeA.vy -= fy;
          nodeB.vx += fx;
          nodeB.vy += fy;
        }
      }
    }

    // 2. Link Attraction (Edges pull nodes together)
    for (var edge in _edges) {
      double dx = edge.target.x - edge.source.x;
      double dy = edge.target.y - edge.source.y;
      double dist = math.sqrt(dx * dx + dy * dy) + 0.1;
      
      double strength = edge.isParent ? linkStrength * 0.5 : linkStrength;
      double force = (dist - 100) * strength;
      
      double fx = (dx / dist) * force;
      double fy = (dy / dist) * force;
      
      edge.source.vx += fx;
      edge.source.vy += fy;
      edge.target.vx -= fx;
      edge.target.vy -= fy;
    }

    // 3. Central Gravity & Update Positions
    for (var node in _nodes) {
      node.vx -= node.x * gravity;
      node.vy -= node.y * gravity;
      
      node.vx *= friction;
      node.vy *= friction;
      
      node.x += node.vx;
      node.y += node.vy;
    }

    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    _transformCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _transformCtrl,
      minScale: 0.1,
      maxScale: 4.0,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      child: Center(
        child: GestureDetector(
          onTapUp: _handleTap,
          child: CustomPaint(
            size: Size.infinite,
            painter: _GraphPainter(nodes: _nodes, edges: _edges),
          ),
        ),
      ),
    );
  }

  void _handleTap(TapUpDetails details) {
    // Convert local tap to simulation space
    final matrix = _transformCtrl.value;
    final inverted = Matrix4.inverted(matrix);
    final scenePos = MatrixUtils.transformPoint(inverted, details.localPosition);
    
    // Find closest node
    _Node? closest;
    double minDist = 30.0; // Click radius
    
    for (var node in _nodes) {
      double d = math.sqrt(math.pow(node.x - scenePos.dx, 2) + math.pow(node.y - scenePos.dy, 2));
      if (d < minDist) {
        minDist = d;
        closest = node;
      }
    }
    
    if (closest != null) {
      final goal = widget.goals.firstWhere((g) => (g.goal as Goal).id == closest!.id).goal as Goal;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GoalDetailSheet(goal: goal)),
      );
    }
  }

  Color _statusColor(GoalStatus s) => switch (s) {
    GoalStatus.completed  => const Color(0xFF00FF7F), // Neon Spring Green
    GoalStatus.inProgress => const Color(0xFF00BFFF), // Deep Sky Blue
    GoalStatus.overdue    => const Color(0xFFFF4500), // Orange Red
    GoalStatus.blocked    => const Color(0xFFFFD700), // Gold
    GoalStatus.notStarted => const Color(0xFF888888),
  };
}

// ════════════════════════════════════════════════════════════════════════════
// PAINTER — High performance rendering
// ════════════════════════════════════════════════════════════════════════════

class _GraphPainter extends CustomPainter {
  final List<_Node> nodes;
  final List<_Edge> edges;

  _GraphPainter({required this.nodes, required this.edges});

  @override
  void paint(Canvas canvas, Size size) {
    final paintEdge = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.2;

    final paintParentEdge = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 0.8;

    // Draw Edges
    for (var edge in edges) {
      canvas.drawLine(
        Offset(edge.source.x, edge.source.y),
        Offset(edge.target.x, edge.target.y),
        edge.isParent ? paintParentEdge : paintEdge,
      );
    }

    // Draw Nodes
    for (var node in nodes) {
      final nodePaint = Paint()
        ..color = node.color
        ..style = PaintingStyle.fill;
      
      // Node Glow
      final glowPaint = Paint()
        ..color = node.color.withValues(alpha: 0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, node.isMain ? 8.0 : 4.0);

      canvas.drawCircle(Offset(node.x, node.y), node.radius * 1.8, glowPaint);
      canvas.drawCircle(Offset(node.x, node.y), node.radius, nodePaint);

      // Label (Small and clean)
      if (node.label.length > 0) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: node.label.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: node.isMain ? 0.8 : 0.5),
              fontSize: node.isMain ? 8 : 6,
              fontWeight: node.isMain ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: 0.5,
              fontFamily: 'Inter',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(node.x + node.radius + 4, node.y - (node.isMain ? 4 : 3)));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ════════════════════════════════════════════════════════════════════════════
// MODELS
// ════════════════════════════════════════════════════════════════════════════

class _Node {
  final String id;
  final String label;
  final Color color;
  final double weight;
  final double radius;
  final bool isMain;
  double x, y;
  double vx = 0, vy = 0;

  _Node({
    required this.id,
    required this.label,
    required this.color,
    required this.weight,
    required this.radius,
    required this.isMain,
    required this.x,
    required this.y,
  });
}

class _Edge {
  final _Node source;
  final _Node target;
  final bool isParent;
  _Edge({required this.source, required this.target, this.isParent = false});
}

// ════════════════════════════════════════════════════════════════════════════
// COMPONENTS
// ════════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('GOAL NETWORK', style: AppTypography.sectionHeader.copyWith(letterSpacing: 2, color: Colors.white)),
              Text('Interactive dependency graph', style: AppTypography.caption.copyWith(color: Colors.white38)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 20),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const AddGoalForm(),
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _GraphControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _indicator(const Color(0xFF00FF7F), 'Done', size: 10),
              const SizedBox(width: 12),
              _indicator(const Color(0xFF00BFFF), 'Active', size: 10),
              const SizedBox(width: 12),
              _indicator(const Color(0xFFFF4500), 'Overdue', size: 10),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _indicator(Colors.white, 'Main Goal', size: 12),
              const SizedBox(width: 12),
              _indicator(Colors.white54, 'Sub Goal', size: 6),
            ],
          ),
        ],
      ),
    );
  }

  Widget _indicator(Color c, String l, {double size = 6}) {
    return Row(
      children: [
        Container(width: size, height: size, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(l.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _EmptyGraph extends StatelessWidget {
  const _EmptyGraph();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('NO CONNECTIONS FOUND', style: AppTypography.caption),
    );
  }
}

class _GraphLoading extends StatelessWidget {
  const _GraphLoading();
  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator(color: Colors.white));
}
