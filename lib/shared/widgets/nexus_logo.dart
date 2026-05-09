import 'package:flutter/material.dart';

// ════════════════════════════════════════════════════════════════════════════
// NEXUS LOGO — Bold N drawn as an upward arrow slash
// Minimal, formal, white strokes on transparent background
// ════════════════════════════════════════════════════════════════════════════

class NexusLogo extends StatelessWidget {
  final double size;
  final Color color;

  const NexusLogo({
    super.key,
    this.size = 48,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _NexusLogoPainter(color: color),
      ),
    );
  }
}

class _NexusLogoPainter extends CustomPainter {
  final Color color;
  const _NexusLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final strokeW = w * 0.115;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final pad = strokeW / 2;

    // Left vertical stroke
    canvas.drawLine(
      Offset(pad, h - pad),
      Offset(pad, pad),
      paint,
    );

    // Diagonal stroke (N cross — top-left to bottom-right)
    canvas.drawLine(
      Offset(pad, pad),
      Offset(w - pad, h - pad),
      paint,
    );

    // Right vertical stroke (shorter — arrow up effect)
    canvas.drawLine(
      Offset(w - pad, h - pad),
      Offset(w - pad, pad),
      paint,
    );

    // Arrow head at top-right
    final arrowSize = w * 0.26;
    final tipX = w - pad;
    final tipY = pad;

    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = strokeW * 0.9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Left wing of arrow
    canvas.drawLine(
      Offset(tipX, tipY),
      Offset(tipX - arrowSize * 0.75, tipY + arrowSize * 0.55),
      arrowPaint,
    );
    // Right wing of arrow
    canvas.drawLine(
      Offset(tipX, tipY),
      Offset(tipX + arrowSize * 0.05, tipY + arrowSize * 0.85),
      arrowPaint,
    );
  }

  @override
  bool shouldRepaint(_NexusLogoPainter old) => old.color != color;
}
