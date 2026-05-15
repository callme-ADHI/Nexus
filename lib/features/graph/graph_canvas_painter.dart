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

    // Pass 1: Edges (below nodes)
    _drawAllEdges(canvas, nodeMap);

    // Pass 2: Node outer glows
    for (var node in nodes) _drawNodeGlow(canvas, node);

    // Pass 3: Node cores + borders
    for (var node in nodes) _drawNodeCore(canvas, node);

    // Pass 4: Progress arcs
    for (var node in nodes) _drawProgressArc(canvas, node);

    // Pass 5: Labels
    for (var node in nodes) _drawNodeLabel(canvas, node);

    canvas.restore();
  }

  // ── EDGES ────────────────────────────────────────────────────────────────

  void _drawAllEdges(Canvas canvas, Map<String, GraphNode> nodeMap) {
    // Draw in order: dimmed → normal → highlighted (painter's algorithm)
    final dimmed = edges.where((e) => e.isDimmed).toList();
    final normal = edges.where((e) => !e.isDimmed && !e.isHighlighted).toList();
    final highlighted = edges.where((e) => e.isHighlighted).toList();

    for (var e in dimmed) _drawEdge(canvas, e, nodeMap, isDimmed: true);
    for (var e in normal) _drawEdge(canvas, e, nodeMap);
    for (var e in highlighted) _drawEdge(canvas, e, nodeMap, isHighlighted: true);
  }

  void _drawEdge(
    Canvas canvas,
    GraphEdge edge,
    Map<String, GraphNode> nodeMap, {
    bool isDimmed = false,
    bool isHighlighted = false,
  }) {
    final src = nodeMap[edge.sourceId];
    final tgt = nodeMap[edge.targetId];
    if (src == null || tgt == null) return;

    final color = edge.type == EdgeType.dependency
        ? (accentColors[src.colorIndex] ?? Colors.white)
        : Colors.white;

    double alpha = edge.type == EdgeType.dependency ? 0.50 : 0.20;
    if (isDimmed) alpha = 0.05;
    if (isHighlighted) alpha = 0.90;

    double strokeW = isHighlighted ? 1.8 : 1.0;
    if (isDimmed) strokeW = 0.6;

    // Compute path (straight or curved to avoid node overlap)
    final result = _buildEdgePath(src, tgt);
    final path = result.path;
    final arrowDir = result.arrowDir;
    final arrowTip = result.arrowTip;

    // Glow pass for highlighted edges
    if (isHighlighted) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.25)
          ..strokeWidth = strokeW + 5
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }

    // Main line
    final linePaint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Sub-goal edges: dashed
    if (edge.type == EdgeType.subgoal) {
      _drawDashedPath(canvas, path, linePaint);
    } else {
      canvas.drawPath(path, linePaint);
    }

    // Arrowhead for dependency edges
    if (edge.type == EdgeType.dependency) {
      _drawArrowhead(
        canvas,
        tip: arrowTip,
        dir: arrowDir,
        color: color.withValues(alpha: alpha),
        size: isHighlighted ? 10.0 : 7.0,
      );
    }
  }

  // ── PATH COMPUTATION ─────────────────────────────────────────────────────

  static const double _avoidRadius = 6.0; // extra clearance

  ({Path path, Offset arrowDir, Offset arrowTip}) _buildEdgePath(
    GraphNode src,
    GraphNode tgt,
  ) {
    final p0 = src.position;
    final p1 = tgt.position;
    final delta = p1 - p0;
    final dist = delta.distance;

    if (dist < 1) {
      return (
        path: Path(),
        arrowDir: const Offset(1, 0),
        arrowTip: p1,
      );
    }

    final dir = delta / dist;

    // Clip line to node surfaces (not their centres)
    final startPt = p0 + dir * (src.finalRadius + 2);
    final endPt = p1 - dir * (tgt.finalRadius + 2);

    // Check if the straight segment passes through any other node
    bool needsCurve = false;
    for (var node in nodes) {
      if (node.id == src.id || node.id == tgt.id) continue;
      final d = _distPointToSegment(node.position, startPt, endPt);
      if (d < node.finalRadius + _avoidRadius) {
        needsCurve = true;
        break;
      }
    }

    if (!needsCurve) {
      // Straight line — arrowhead points exactly along dir
      final path = Path()
        ..moveTo(startPt.dx, startPt.dy)
        ..lineTo(endPt.dx, endPt.dy);
      return (path: path, arrowDir: dir, arrowTip: endPt);
    }

    // Curved arc — perpendicular bulge
    final perp = Offset(-dir.dy, dir.dx);
    final mid = (startPt + endPt) / 2;
    final ctrl = mid + perp * (dist * 0.22);

    final path = Path()
      ..moveTo(startPt.dx, startPt.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, endPt.dx, endPt.dy);

    // Tangent at t=1: derivative of quadratic bezier = 2*(endPt - ctrl)
    final tangent = endPt - ctrl;
    final arrowDir = tangent / tangent.distance;

    return (path: path, arrowDir: arrowDir, arrowTip: endPt);
  }

  static double _distPointToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;
    final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (len2 == 0) return (p - a).distance;
    final t = ((ap.dx * ab.dx + ap.dy * ab.dy) / len2).clamp(0.0, 1.0);
    final closest = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
    return (p - closest).distance;
  }

  void _drawArrowhead(
    Canvas canvas, {
    required Offset tip,
    required Offset dir,
    required Color color,
    required double size,
  }) {
    final perp = Offset(-dir.dy, dir.dx);
    final base = tip - dir * size;
    final p1 = base + perp * (size * 0.45);
    final p2 = base - perp * (size * 0.45);

    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..close(),
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    // Approximate dashes by computing points along the path
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double dist = 0;
      const double dashLen = 6.0;
      const double gapLen = 4.0;
      bool drawing = true;
      while (dist < metric.length) {
        final segLen = drawing ? dashLen : gapLen;
        final end = math.min(dist + segLen, metric.length);
        if (drawing) {
          canvas.drawPath(metric.extractPath(dist, end), paint);
        }
        dist = end;
        drawing = !drawing;
      }
    }
  }

  // ── NODES ────────────────────────────────────────────────────────────────

  void _drawNodeGlow(Canvas canvas, GraphNode node) {
    if (node.isDimmed) return;
    final color = accentColors[node.colorIndex] ?? Colors.white;
    final glowAlpha = node.isHovered ? 0.30 : 0.12;
    final radius = node.finalRadius * 2.5;

    canvas.drawCircle(
      node.position,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: glowAlpha),
            color.withValues(alpha: 0),
          ],
        ).createShader(
          Rect.fromCircle(center: node.position, radius: radius),
        ),
    );
  }

  void _drawNodeCore(Canvas canvas, GraphNode node) {
    final color = accentColors[node.colorIndex] ?? Colors.white;
    final r = node.finalRadius;

    // Status-based fill and border colours
    Color fillColor;
    Color borderColor;
    double borderWidth;

    switch (node.status) {
      case GoalStatus.notStarted:
        fillColor = const Color(0xFF0A0A0A);
        borderColor = color.withValues(alpha: node.isDimmed ? 0.15 : 0.55);
        borderWidth = 1.5;
      case GoalStatus.inProgress:
        fillColor = color.withValues(alpha: node.isDimmed ? 0.04 : 0.12);
        borderColor = color.withValues(alpha: node.isDimmed ? 0.2 : 0.85);
        borderWidth = 1.8;
      case GoalStatus.completed:
        fillColor = const Color(0xFF27AE60).withValues(alpha: node.isDimmed ? 0.05 : 0.15);
        borderColor = const Color(0xFF27AE60).withValues(alpha: node.isDimmed ? 0.2 : 1.0);
        borderWidth = 1.8;
      case GoalStatus.blocked:
        fillColor = const Color(0xFF0A0A0A);
        borderColor = const Color(0xFF333333).withValues(alpha: node.isDimmed ? 0.15 : 1.0);
        borderWidth = 1.0;
      case GoalStatus.overdue:
        fillColor = const Color(0xFFE74C3C).withValues(alpha: node.isDimmed ? 0.03 : 0.08);
        borderColor = const Color(0xFFE74C3C).withValues(alpha: node.isDimmed ? 0.2 : 0.85);
        borderWidth = 1.8;
    }

    canvas.drawCircle(node.position, r, Paint()..color = fillColor..style = PaintingStyle.fill);
    canvas.drawCircle(node.position, r, Paint()..color = borderColor..style = PaintingStyle.stroke..strokeWidth = borderWidth);

    // Rotating ring for main goals
    if (node.isMainGoal) {
      canvas.save();
      canvas.translate(node.position.dx, node.position.dy);
      canvas.rotate(rotationAngle);
      canvas.drawCircle(
        Offset.zero, r + 5.0,
        Paint()
          ..color = color.withValues(alpha: node.isDimmed ? 0.08 : 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
      // Marker dots
      final mp = Paint()..color = color.withValues(alpha: node.isDimmed ? 0.2 : 0.8)..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(r + 5.0, 0), 2, mp);
      canvas.drawCircle(Offset(-(r + 5.0), 0), 2, mp);
      canvas.restore();
    }
  }

  void _drawProgressArc(Canvas canvas, GraphNode node) {
    if (node.status == GoalStatus.blocked || node.progress <= 0) return;

    final color = node.status == GoalStatus.completed
        ? const Color(0xFF27AE60)
        : (accentColors[node.colorIndex] ?? Colors.white);

    final sweep = (node.progress / 100.0).clamp(0.0, 1.0) * 2 * math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: node.position, radius: node.finalRadius + 3),
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..color = color.withValues(alpha: node.isDimmed ? 0.15 : 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawNodeLabel(Canvas canvas, GraphNode node) {
    final alpha = node.isHovered ? 1.0 : (node.isDimmed ? 0.20 : 0.75);

    // Title-case the label
    final label = node.label
        .toLowerCase()
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');

    final style = TextStyle(
      color: Colors.white.withValues(alpha: alpha),
      fontSize: node.isMainGoal ? 11.5 : 10.5,
      fontWeight: node.isMainGoal ? FontWeight.w600 : FontWeight.w400,
      fontFamily: 'Inter',
      letterSpacing: 0.2,
    );

    final tp = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 120);

    // Position label below node (always below for consistency)
    final labelX = node.position.dx - tp.width / 2;
    final labelY = node.position.dy + node.finalRadius + 6;

    // Background pill for hovered labels
    if (node.isHovered) {
      final bg = Rect.fromLTWH(labelX - 6, labelY - 3, tp.width + 12, tp.height + 6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bg, const Radius.circular(4)),
        Paint()..color = const Color(0xF0050505),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bg, const Radius.circular(4)),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
    }

    tp.paint(canvas, Offset(labelX, labelY));
  }

  @override
  bool shouldRepaint(covariant GraphCanvasPainter old) =>
      old.panOffset != panOffset ||
      old.zoomLevel != zoomLevel ||
      old.rotationAngle != rotationAngle ||
      old.nodes != nodes ||
      old.edges != edges;
}
