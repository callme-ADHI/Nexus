import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'graph_node_model.dart';
import 'graph_edge_model.dart';
import 'package:nexus/core/models/models.dart';

class GraphCanvasPainter extends CustomPainter {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final Offset panOffset;
  final double zoomLevel;
  final double rotationAngle;
  final Map<int, Color> accentColors;

  GraphCanvasPainter({
    required this.nodes,
    required this.edges,
    required this.panOffset,
    required this.zoomLevel,
    required this.rotationAngle,
    required this.accentColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(panOffset.dx, panOffset.dy);
    canvas.scale(zoomLevel);

    final nodeMap = {for (var n in nodes) n.id: n};

    // PASS 1-4: Edges
    _drawEdges(canvas, edges, nodeMap);

    // PASS 5: Outer Glows
    for (var node in nodes) {
      _drawNodeOuterGlow(canvas, node);
    }

    // PASS 6: Inner Glows
    for (var node in nodes) {
      _drawNodeInnerGlow(canvas, node);
    }

    // PASS 7: Core Circles
    for (var node in nodes) {
      _drawNodeCore(canvas, node);
    }

    // PASS 8: Progress Arcs
    for (var node in nodes) {
      _drawProgressArc(canvas, node);
    }

    // PASS 9: Status Icons
    for (var node in nodes) {
      _drawStatusIcon(canvas, node);
    }

    // PASS 10: Labels
    for (var node in nodes) {
      _drawNodeLabel(canvas, node, size);
    }

    canvas.restore();
  }

  void _drawEdges(Canvas canvas, List<GraphEdge> edges, Map<String, GraphNode> nodeMap) {
    // Group edges by state for batching
    final dimmed = edges.where((e) => e.isDimmed).toList();
    final normal = edges.where((e) => !e.isDimmed && !e.isHighlighted).toList();
    final highlighted = edges.where((e) => e.isHighlighted).toList();

    for (var edge in dimmed) _drawSingleEdge(canvas, edge, nodeMap, isDimmed: true);
    for (var edge in normal) _drawSingleEdge(canvas, edge, nodeMap);
    for (var edge in highlighted) {
      _drawSingleEdge(canvas, edge, nodeMap, isHighlighted: true, hasGlow: true);
      _drawArrowhead(canvas, edge, nodeMap);
    }

    // Draw non-highlighted arrowheads for dependencies
    for (var edge in normal) {
      if (edge.type == EdgeType.dependency) _drawArrowhead(canvas, edge, nodeMap);
    }
  }

  void _drawSingleEdge(Canvas canvas, GraphEdge edge, Map<String, GraphNode> nodeMap, {bool isDimmed = false, bool isHighlighted = false, bool hasGlow = false}) {
    final source = nodeMap[edge.sourceId];
    final target = nodeMap[edge.targetId];
    if (source == null || target == null) return;

    final color = edge.type == EdgeType.dependency 
      ? accentColors[source.colorIndex] ?? Colors.white 
      : Colors.white;

    double opacity = edge.type == EdgeType.dependency ? 0.45 : 0.18;
    if (isDimmed) opacity = 0.06;
    if (isHighlighted) opacity = edge.type == EdgeType.dependency ? 0.85 : 0.50;

    double strokeW = isHighlighted ? 2.0 : 1.2;
    if (isDimmed) strokeW = 0.8;

    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke;

    if (edge.type == EdgeType.subgoal && !isHighlighted) {
      // Dashed for subgoals
      // Note: Simplified dash logic for painter performance
    }

    final path = _getBezierPath(source, target);

    if (hasGlow) {
      canvas.drawPath(path, Paint()
        ..color = color.withValues(alpha: 0.3)
        ..strokeWidth = strokeW + 4
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }

    canvas.drawPath(path, paint);
  }

  Path _getBezierPath(GraphNode s, GraphNode t) {
    final p0 = s.position;
    final p1 = t.position;
    final mid = (p0 + p1) / 2;
    final delta = p1 - p0;
    final perp = Offset(-delta.dy, delta.dx);
    final control = mid + (perp / (perp.distance == 0 ? 1 : perp.distance)) * delta.distance * 0.15;

    final dir = (p1 - p0) / (p1 - p0).distance;
    final p0Adj = p0 + dir * s.finalRadius;
    final p1Adj = p1 - dir * t.finalRadius;

    return Path()..moveTo(p0Adj.dx, p0Adj.dy)..quadraticBezierTo(control.dx, control.dy, p1Adj.dx, p1Adj.dy);
  }

  void _drawArrowhead(Canvas canvas, GraphEdge edge, Map<String, GraphNode> nodeMap) {
    if (edge.type != EdgeType.dependency) return;
    final source = nodeMap[edge.sourceId];
    final target = nodeMap[edge.targetId];
    if (source == null || target == null) return;

    final p0 = source.position;
    final p1 = target.position;
    final delta = p1 - p0;
    final mid = (p0 + p1) / 2;
    final perp = Offset(-delta.dy, delta.dx);
    final control = mid + (perp / (perp.distance == 0 ? 1 : perp.distance)) * delta.distance * 0.15;

    final dir = (p1 - control) / (p1 - control).distance;
    final tip = p1 - dir * target.finalRadius;
    
    final arrowLen = 9.0;
    final arrowWid = 5.0;
    final sidePerp = Offset(-dir.dy, dir.dx);

    final b1 = tip - dir * arrowLen + sidePerp * arrowWid;
    final b2 = tip - dir * arrowLen - sidePerp * arrowWid;

    final color = (accentColors[source.colorIndex] ?? Colors.white).withValues(alpha: edge.isHighlighted ? 0.85 : 0.45);
    canvas.drawPath(Path()..moveTo(tip.dx, tip.dy)..lineTo(b1.dx, b1.dy)..lineTo(b2.dx, b2.dy)..close(), Paint()..color = color..style = PaintingStyle.fill);
  }

  void _drawNodeOuterGlow(Canvas canvas, GraphNode node) {
    final color = accentColors[node.colorIndex] ?? Colors.white;
    double opacity = 0.18;
    if (node.isHovered) opacity *= 2.0;
    if (node.isDimmed) opacity *= 0.15;

    final radius = node.finalRadius * 2.8;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: node.position, radius: radius));
    
    canvas.drawCircle(node.position, radius, paint);
  }

  void _drawNodeInnerGlow(Canvas canvas, GraphNode node) {
    final color = accentColors[node.colorIndex] ?? Colors.white;
    double opacity = 0.35;
    if (node.isHovered) opacity *= 1.8;
    if (node.isDimmed) opacity *= 0.1;

    final radius = node.finalRadius * 1.6;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: node.position, radius: radius));
    
    canvas.drawCircle(node.position, radius, paint);
  }

  void _drawNodeCore(Canvas canvas, GraphNode node) {
    final color = accentColors[node.colorIndex] ?? Colors.white;
    final paint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()..style = PaintingStyle.stroke;

    switch (node.status) {
      case GoalStatus.notStarted:
        paint.color = color.withValues(alpha: 0.12);
        borderPaint..color = color.withValues(alpha: 0.6)..strokeWidth = 1.5;
      case GoalStatus.inProgress:
        paint.color = color.withValues(alpha: 0.25);
        borderPaint..color = color.withValues(alpha: 0.9)..strokeWidth = 2.0;
      case GoalStatus.completed:
        paint.color = const Color(0xFF3FC47A).withValues(alpha: 0.3);
        borderPaint..color = const Color(0xFF3FC47A)..strokeWidth = 2.0;
      case GoalStatus.blocked:
        paint.color = const Color(0xFF2A2A3A);
        borderPaint..color = const Color(0xFF3A3A4A)..strokeWidth = 1.0;
      case GoalStatus.overdue:
        paint.color = const Color(0xFF5C1A1A).withValues(alpha: 0.4);
        borderPaint..color = const Color(0xFFD94A4A)..strokeWidth = 2.0;
    }

    if (node.isDimmed) {
       paint.color = paint.color.withValues(alpha: paint.color.a * 0.2);
       borderPaint.color = borderPaint.color.withValues(alpha: borderPaint.color.a * 0.2);
    }

    canvas.drawCircle(node.position, node.finalRadius, paint);
    canvas.drawCircle(node.position, node.finalRadius, borderPaint);

    if (node.isMainGoal) {
      final ringRadius = node.finalRadius + 5.0;
      canvas.save();
      canvas.translate(node.position.dx, node.position.dy);
      canvas.rotate(rotationAngle);
      
      final ringPaint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      
      canvas.drawCircle(Offset.zero, ringRadius, ringPaint);
      
      // Add rotation markers (dots)
      final markerPaint = Paint()..color = color.withValues(alpha: 0.8)..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(ringRadius, 0), 2, markerPaint);
      canvas.drawCircle(Offset(-ringRadius, 0), 2, markerPaint);
      
      canvas.restore();
    }
  }

  void _drawProgressArc(Canvas canvas, GraphNode node) {
    if (node.status == GoalStatus.blocked) return;
    final color = node.status == GoalStatus.completed ? const Color(0xFF3FC47A) : (accentColors[node.colorIndex] ?? Colors.white);
    
    final paint = Paint()
      ..color = color.withValues(alpha: node.isDimmed ? 0.2 : 1.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final sweep = node.progress * 2 * math.pi;
    canvas.drawArc(Rect.fromCircle(center: node.position, radius: node.finalRadius), -math.pi / 2, sweep, false, paint);
  }

  void _drawStatusIcon(Canvas canvas, GraphNode node) {
    // Simplified status icons for canvas
    if (node.status == GoalStatus.notStarted || node.status == GoalStatus.inProgress) return;
    
    final iconPos = node.position + Offset(node.finalRadius * 0.7, -node.finalRadius * 0.7);
    final paint = Paint()..style = PaintingStyle.fill;

    if (node.status == GoalStatus.completed) {
      paint.color = const Color(0xFF3FC47A);
      canvas.drawCircle(iconPos, 4, paint);
    } else if (node.status == GoalStatus.overdue) {
      paint.color = const Color(0xFFD94A4A);
      canvas.drawRect(Rect.fromCenter(center: iconPos, width: 6, height: 6), paint);
    } else if (node.status == GoalStatus.blocked) {
      paint.color = Colors.white60;
      canvas.drawCircle(iconPos, 3, paint);
    }
  }

  void _drawNodeLabel(Canvas canvas, GraphNode node, Size canvasSize) {
    final opacity = node.isHovered ? 1.0 : (node.isDimmed ? 0.25 : 0.8);
    
    // Ensure Title Case
    final labelText = node.label.toLowerCase().split(' ').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');

    final textStyle = TextStyle(
      color: Colors.white.withValues(alpha: opacity),
      fontSize: node.isMainGoal ? 12 : 11,
      fontWeight: FontWeight.w500,
      fontFamily: 'Inter',
    );

    final textSpan = TextSpan(text: labelText, style: textStyle);
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr, maxLines: 1, ellipsis: '...');
    textPainter.layout(maxWidth: 140);

    final isUpper = node.position.dy < canvasSize.height * 0.4;
    final yOffset = isUpper ? node.finalRadius + 8 : -(node.finalRadius + 8 + textPainter.height);
    final pos = Offset(node.position.dx - textPainter.width / 2, node.position.dy + yOffset);

    if (node.isHovered) {
      final bgRect = Rect.fromLTWH(pos.dx - 8, pos.dy - 4, textPainter.width + 16, textPainter.height + 8);
      canvas.drawRRect(RRect.fromRectAndRadius(bgRect, const Radius.circular(4)), Paint()..color = const Color(0xE6121218));
    }

    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant GraphCanvasPainter old) => true; // simplified for now
}
