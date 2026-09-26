import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A custom Tasbeeh icon matching the user's reference design:
/// A clean circular ring of 10 bold spherical beads, with an upright minaret
/// stem and small top loop at the 12 o'clock position.
class TasbeehBeadIcon extends StatelessWidget {
  final double size;
  final Color color;

  const TasbeehBeadIcon({
    super.key,
    this.size = 24.0,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _TasbeehBeadPainter(color: color),
    );
  }
}

class _TasbeehBeadPainter extends CustomPainter {
  final Color color;

  _TasbeehBeadPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final beadPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, w * 0.065)
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final stringPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, w * 0.035)
      ..isAntiAlias = true;

    // ── 1. Circular Bead Ring ─────────────────────────────────────────────────
    final cx = w * 0.5;
    final cy = h * 0.56;
    final radius = w * 0.31;

    // Connect beads with thin string circle
    canvas.drawCircle(Offset(cx, cy), radius, stringPaint);

    // ── 2. 10 Bold Round Beads ────────────────────────────────────────────────
    const int beadCount = 10;
    final beadR = math.max(1.5, w * 0.088);

    List<Offset> beadCenters = [];
    for (int i = 0; i < beadCount; i++) {
      final double angle = -math.pi / 2 + (i * 2 * math.pi / beadCount);
      final dx = cx + radius * math.cos(angle);
      final dy = cy + radius * math.sin(angle);
      beadCenters.add(Offset(dx, dy));
    }

    for (int i = 0; i < beadCenters.length; i++) {
      final r = (i == 0) ? beadR * 1.15 : beadR;
      canvas.drawCircle(beadCenters[i], r, beadPaint);
    }

    // ── 3. Top Minaret Stem & Hanging Ring (12 o'clock) ──────────────────────
    final topBead = beadCenters[0];
    final stemTopY = topBead.dy - h * 0.12;

    // Stem
    canvas.drawLine(
      Offset(cx, topBead.dy - beadR * 0.8),
      Offset(cx, stemTopY),
      strokePaint,
    );

    // Top loop ring
    final loopRadius = math.max(1.0, w * 0.055);
    final loopCenter = Offset(cx, stemTopY - loopRadius - w * 0.02);
    canvas.drawCircle(loopCenter, loopRadius, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _TasbeehBeadPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}


