import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/database/app_database.dart';
import '../../core/models/models.dart';
import '../../core/services/productivity_service.dart';

class DayRingPainter extends CustomPainter {
  final List<ActivityLog> activities;
  final SleepLog? sleep;
  final double animProgress;
  final int? highlightedId;
  final DateTime currentTime;
  final bool showTimeIndicator;

  DayRingPainter({
    required this.activities,
    required this.sleep,
    required this.animProgress,
    this.highlightedId,
    required this.currentTime,
    required this.showTimeIndicator,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 24.0;

    // Background ring
    final bgPaint = Paint()
      ..color = const Color(0xFF18181F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    // Ticks & Labels
    _drawTicksAndLabels(canvas, center, radius, strokeWidth);

    // Activity Arcs
    final arcRect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);
    _drawSleepArc(canvas, arcRect, strokeWidth);
    _drawActivityArcs(canvas, arcRect, strokeWidth);

    // Current Time Indicator
    if (showTimeIndicator) {
      _drawTimeIndicator(canvas, center, radius, strokeWidth);
    }
  }

  void _drawTicksAndLabels(Canvas canvas, Offset center, double radius, double strokeWidth) {
    final tp = TextPainter(textDirection: TextDirection.ltr);
    final hours = [0, 6, 12, 18];
    for (final h in hours) {
      final angle = (h / 24) * 2 * math.pi - math.pi / 2;
      final labelRadius = radius - strokeWidth - 14;
      final lx = center.dx + labelRadius * math.cos(angle);
      final ly = center.dy + labelRadius * math.sin(angle);
      
      tp.text = TextSpan(
        text: h.toString(),
        style: const TextStyle(color: Color(0xFF3A3A50), fontSize: 9, fontFamily: 'Inter'),
      );
      tp.layout();
      tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));
    }
  }

  void _drawSleepArc(Canvas canvas, Rect rect, double strokeWidth) {
    if (sleep == null) return;
    final sleepPaint = Paint()
      ..color = const Color(0xFF1E1B4B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final startAngle = _timeToAngle(sleep!.sleepTime) - math.pi / 2;
    var sweepAngle = _timeToAngle(sleep!.wakeTime) - _timeToAngle(sleep!.sleepTime);
    if (sweepAngle < 0) sweepAngle += 2 * math.pi;
    sweepAngle *= animProgress;

    if (sweepAngle > 0) {
      canvas.drawArc(rect, startAngle, sweepAngle, false, sleepPaint);
    }
  }

  void _drawActivityArcs(Canvas canvas, Rect rect, double strokeWidth) {
    for (final a in activities) {
      final cat = ActivityCategory.fromKey(a.category);
      final isHighlighted = highlightedId == a.id;
      final opacity = isHighlighted ? 1.0 : 0.7;
      
      final paint = Paint()
        ..color = cat.color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHighlighted ? strokeWidth + 4 : strokeWidth
        ..strokeCap = StrokeCap.round;

      final startAngle = _timeToAngle(a.startTime) - math.pi / 2;
      var sweepAngle = _timeToAngle(a.endTime) - _timeToAngle(a.startTime);
      if (sweepAngle < 0) sweepAngle += 2 * math.pi;
      sweepAngle *= animProgress;

      if (sweepAngle > 0) {
        canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      }
    }
  }

  void _drawTimeIndicator(Canvas canvas, Offset center, double radius, double strokeWidth) {
    final totalMins = currentTime.hour * 60 + currentTime.minute;
    final angle = (totalMins / 1440) * 2 * math.pi - math.pi / 2;

    final innerRadius = radius - strokeWidth;
    final outerRadius = radius;

    final p1 = Offset(center.dx + innerRadius * math.cos(angle), center.dy + innerRadius * math.sin(angle));
    final p2 = Offset(center.dx + outerRadius * math.cos(angle), center.dy + outerRadius * math.sin(angle));

    final linePaint = Paint()
      ..color = const Color(0xFFEEEEF2).withValues(alpha: 0.4)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(p1, p2, linePaint);

    final dotPaint = Paint()..color = const Color(0xFFEEEEF2).withValues(alpha: 0.6);
    canvas.drawCircle(p1, 3.0, dotPaint);
  }

  double _timeToAngle(int millis) {
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    final mins = dt.hour * 60 + dt.minute;
    return (mins / 1440) * 2 * math.pi;
  }

  @override
  bool shouldRepaint(covariant DayRingPainter oldDelegate) {
    return oldDelegate.animProgress != animProgress ||
           oldDelegate.highlightedId != highlightedId ||
           oldDelegate.currentTime.minute != currentTime.minute ||
           oldDelegate.activities != activities ||
           oldDelegate.sleep != sleep;
  }

  static int? findActivityAt(Offset localPosition, Size size, List<ActivityLog> activities, SleepLog? sleep) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    
    final radius = size.width / 2;
    const strokeWidth = 24.0;
    if (dist < radius - strokeWidth - 10 || dist > radius + 10) return null;

    var angle = math.atan2(dy, dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;

    for (final a in activities.reversed) {
      final sDt = DateTime.fromMillisecondsSinceEpoch(a.startTime);
      final eDt = DateTime.fromMillisecondsSinceEpoch(a.endTime);
      final sMins = sDt.hour * 60 + sDt.minute;
      var eMins = eDt.hour * 60 + eDt.minute;
      if (eMins <= sMins) eMins += 1440;

      final sAngle = (sMins / 1440) * 2 * math.pi;
      final eAngle = (eMins / 1440) * 2 * math.pi;

      if (angle >= sAngle && angle <= eAngle) return a.id;
      if (eMins >= 1440 && angle <= eAngle - 2 * math.pi) return a.id;
    }
    return null;
  }
}
