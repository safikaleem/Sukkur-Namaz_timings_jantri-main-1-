import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../providers/settings_provider.dart';

class AnalogClockWidget extends StatelessWidget {
  final DateTime now;
  final bool isDark;
  final Color accentColor;
  final double size;
  final ClockStyle style;

  const AnalogClockWidget({
    super.key,
    required this.now,
    required this.isDark,
    required this.accentColor,
    this.size = 240,
    this.style = ClockStyle.classic,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ClockPainter(now, isDark, accentColor, style),
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  final DateTime now;
  final bool isDark;
  final Color accentColor;
  final ClockStyle style;

  _ClockPainter(this.now, this.isDark, this.accentColor, this.style);

  double get _sf => now.second / 60;

  @override
  void paint(Canvas canvas, Size size) {
    switch (style) {
      case ClockStyle.classic:   _paintClassic(canvas, size);
      case ClockStyle.minimal:   _paintMinimal(canvas, size);
      case ClockStyle.sketch:    _paintSketch(canvas, size);
      case ClockStyle.dusk:      _paintDusk(canvas, size);
      case ClockStyle.linen:     _paintLinen(canvas, size);
      case ClockStyle.rose:      _paintRose(canvas, size);
      case ClockStyle.sage:      _paintSage(canvas, size);
      case ClockStyle.carbon:    _paintCarbon(canvas, size);
      case ClockStyle.ocean:     _paintOcean(canvas, size);
      case ClockStyle.ivory:     _paintIvory(canvas, size);
      case ClockStyle.lavender:  _paintLavender(canvas, size);
      case ClockStyle.coral:     _paintCoral(canvas, size);
      case ClockStyle.mint:      _paintMint(canvas, size);
      case ClockStyle.peach:     _paintPeach(canvas, size);
      case ClockStyle.champagne: _paintChampagne(canvas, size);
    }
  }

  void _ring(Canvas canvas, Offset c, double r, Color track, Color arc, double w) {
    canvas.drawCircle(c, r,
        Paint()..color = track..style = PaintingStyle.stroke..strokeWidth = w);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2, _sf * 2 * math.pi, false,
      Paint()..color = arc..style = PaintingStyle.stroke..strokeWidth = w..strokeCap = StrokeCap.round,
    );
  }

  void _numbers(Canvas canvas, Offset center, double radius, Color color, double fontSize) {
    const labels = {0:'12',1:'1',2:'2',3:'3',4:'4',5:'5',6:'6',7:'7',8:'8',9:'9',10:'10',11:'11'};
    labels.forEach((i, label) {
      final angle  = (i / 12) * 2 * math.pi - math.pi / 2;
      final labelR = radius - 26;
      final pos    = Offset(center.dx + labelR * math.cos(angle), center.dy + labelR * math.sin(angle));
      final tp = TextPainter(
        text: TextSpan(text: label, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w400)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    });
  }

  void _ticks60(Canvas canvas, Offset center, double ringInset, Color major, Color minor) {
    for (int i = 0; i < 60; i++) {
      final angle    = (i / 60) * 2 * math.pi - math.pi / 2;
      final isMajor  = i % 5 == 0;
      final outer    = ringInset - 5;
      final inner    = isMajor ? ringInset - 15 : ringInset - 9;
      canvas.drawLine(
        Offset(center.dx + inner * math.cos(angle), center.dy + inner * math.sin(angle)),
        Offset(center.dx + outer * math.cos(angle), center.dy + outer * math.sin(angle)),
        Paint()..color = isMajor ? major : minor..strokeWidth = isMajor ? 1.5 : 0.8..strokeCap = StrokeCap.round,
      );
    }
  }

  // ── Classic ────────────────────────────────────────────────────────
  void _paintClassic(Canvas canvas, Size size) {
    final center    = Offset(size.width / 2, size.height / 2);
    final radius    = size.width / 2;
    final ringInset = radius - 3.5;

    canvas.drawCircle(center, radius,
        Paint()..color = isDark ? const Color(0xFF1C1C2E) : Colors.white);

    _ring(canvas, center, ringInset, accentColor.withOpacity(0.15), accentColor, 3.5);

    _ticks60(canvas, center, ringInset,
        isDark ? Colors.white60 : Colors.black45,
        isDark ? Colors.white24 : Colors.black12);

    _numbers(canvas, center, ringInset,
        isDark ? Colors.white70 : Colors.black87, radius * 0.115);

    _drawHand(canvas, center,
        angle: ((now.hour % 12 + now.minute / 60) / 12) * 2 * math.pi - math.pi / 2,
        length: radius * 0.48, width: 4.5, color: isDark ? Colors.white : Colors.black);
    _drawHand(canvas, center,
        angle: ((now.minute + now.second / 60) / 60) * 2 * math.pi - math.pi / 2,
        length: radius * 0.68, width: 2.5, color: isDark ? Colors.white : Colors.black);
    _drawHand(canvas, center,
        angle: _sf * 2 * math.pi - math.pi / 2,
        length: radius * 0.72, width: 1.2, color: accentColor);

    canvas.drawCircle(center, 4,   Paint()..color = accentColor);
    canvas.drawCircle(center, 2,   Paint()..color = isDark ? Colors.black : Colors.white);
  }

  // ── Minimal ────────────────────────────────────────────────────────
  void _paintMinimal(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawCircle(center, radius,
        Paint()..color = isDark ? const Color(0xFF12121A) : Colors.white);

    _ring(canvas, center, radius - 3.5, accentColor.withOpacity(0.12), accentColor, 2.5);

    for (int i = 0; i < 4; i++) {
      final angle   = (i / 4) * 2 * math.pi - math.pi / 2;
      final dotDist = radius - 10;
      final dotC    = Offset(center.dx + dotDist * math.cos(angle), center.dy + dotDist * math.sin(angle));
      canvas.drawCircle(dotC, 3.5, Paint()..color = isDark ? Colors.white38 : Colors.black45);
    }

    _drawHand(canvas, center,
        angle: ((now.hour % 12 + now.minute / 60) / 12) * 2 * math.pi - math.pi / 2,
        length: radius * 0.40, width: 3, color: isDark ? Colors.white : Colors.black87);
    _drawHand(canvas, center,
        angle: ((now.minute + now.second / 60) / 60) * 2 * math.pi - math.pi / 2,
        length: radius * 0.65, width: 1.5, color: accentColor);

    canvas.drawCircle(center, 2.5, Paint()..color = accentColor);
  }

  // ── Sketch ─────────────────────────────────────────────────────────
  // Ultra-clean: only dashes, no numbers, whisper-thin hands
  void _paintSketch(Canvas canvas, Size size) {
    final center    = Offset(size.width / 2, size.height / 2);
    final radius    = size.width / 2;
    final ringInset = radius - 3.5;

    canvas.drawCircle(center, radius,
        Paint()..color = isDark ? const Color(0xFF1A1A22) : Colors.white);

    _ring(canvas, center, ringInset, accentColor.withOpacity(0.12), accentColor, 2);

    for (int i = 0; i < 12; i++) {
      final angle      = (i / 12) * 2 * math.pi - math.pi / 2;
      final isCardinal = i % 3 == 0;
      final outer      = ringInset - 7;
      final inner      = isCardinal ? ringInset - 20 : ringInset - 13;
      canvas.drawLine(
        Offset(center.dx + inner * math.cos(angle), center.dy + inner * math.sin(angle)),
        Offset(center.dx + outer * math.cos(angle), center.dy + outer * math.sin(angle)),
        Paint()
          ..color = isDark
              ? Colors.white.withOpacity(isCardinal ? 0.70 : 0.32)
              : Colors.black.withOpacity(isCardinal ? 0.60 : 0.22)
          ..strokeWidth  = isCardinal ? 1.8 : 1.1
          ..strokeCap    = StrokeCap.round,
      );
    }

    _drawHand(canvas, center,
        angle: ((now.hour % 12 + now.minute / 60) / 12) * 2 * math.pi - math.pi / 2,
        length: radius * 0.44, width: 3.2, color: isDark ? Colors.white : Colors.black87);
    _drawHand(canvas, center,
        angle: ((now.minute + now.second / 60) / 60) * 2 * math.pi - math.pi / 2,
        length: radius * 0.66, width: 1.8, color: isDark ? Colors.white : Colors.black87);
    _drawHand(canvas, center,
        angle: _sf * 2 * math.pi - math.pi / 2,
        length: radius * 0.70, width: 1.1, color: accentColor);

    canvas.drawCircle(center, 3,   Paint()..color = accentColor);
    canvas.drawCircle(center, 1.5, Paint()..color = isDark ? Colors.black : Colors.white);
  }

  // ── Dusk ───────────────────────────────────────────────────────────
  // Always deep navy, clean white elements — like a luxury watch at night
  void _paintDusk(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const bg = Color(0xFF0C1638);

    canvas.drawCircle(center, radius, Paint()..color = bg);

    _ring(canvas, center, radius - 3.5, Colors.white.withOpacity(0.08), accentColor, 3);

    for (int i = 0; i < 12; i++) {
      final angle      = (i / 12) * 2 * math.pi - math.pi / 2;
      final isCardinal = i % 3 == 0;
      final dotR       = radius - 14;
      final dotC       = Offset(center.dx + dotR * math.cos(angle), center.dy + dotR * math.sin(angle));
      canvas.drawCircle(dotC, isCardinal ? 3.5 : 2,
          Paint()..color = Colors.white.withOpacity(isCardinal ? 0.80 : 0.40));
    }

    _drawHand(canvas, center,
        angle: ((now.hour % 12 + now.minute / 60) / 12) * 2 * math.pi - math.pi / 2,
        length: radius * 0.46, width: 4.5, color: Colors.white);
    _drawHand(canvas, center,
        angle: ((now.minute + now.second / 60) / 60) * 2 * math.pi - math.pi / 2,
        length: radius * 0.66, width: 2.5, color: Colors.white);
    _drawHand(canvas, center,
        angle: _sf * 2 * math.pi - math.pi / 2,
        length: radius * 0.70, width: 1.2, color: accentColor);

    canvas.drawCircle(center, 4.5, Paint()..color = accentColor);
    canvas.drawCircle(center, 2,   Paint()..color = bg);
  }

  // ── Linen ──────────────────────────────────────────────────────────
  // Warm ivory face, amber ring — cosy and warm
  void _paintLinen(Canvas canvas, Size size) {
    final center    = Offset(size.width / 2, size.height / 2);
    final radius    = size.width / 2;
    final ringInset = radius - 3.5;
    final bgColor   = isDark ? const Color(0xFF1E180C) : const Color(0xFFFFF9F0);
    const amber     = Color(0xFFD97706);
    final handColor = isDark ? const Color(0xFFD4C090) : const Color(0xFF3D1F0D);

    canvas.drawCircle(center, radius, Paint()..color = bgColor);

    _ring(canvas, center, ringInset, amber.withOpacity(0.15), amber, 3);

    _ticks60(canvas, center, ringInset,
        isDark ? Colors.white.withOpacity(0.50) : const Color(0xFF8B6914).withOpacity(0.60),
        isDark ? Colors.white.withOpacity(0.20) : const Color(0xFF8B6914).withOpacity(0.22));

    _numbers(canvas, center, ringInset, handColor.withOpacity(0.72), radius * 0.11);

    _drawHand(canvas, center,
        angle: ((now.hour % 12 + now.minute / 60) / 12) * 2 * math.pi - math.pi / 2,
        length: radius * 0.46, width: 4.5, color: handColor);
    _drawHand(canvas, center,
        angle: ((now.minute + now.second / 60) / 60) * 2 * math.pi - math.pi / 2,
        length: radius * 0.66, width: 2.5, color: handColor);
    _drawHand(canvas, center,
        angle: _sf * 2 * math.pi - math.pi / 2,
        length: radius * 0.70, width: 1.2, color: amber);

    canvas.drawCircle(center, 4,   Paint()..color = amber);
    canvas.drawCircle(center, 2,   Paint()..color = bgColor);
  }

  // ── Rose ───────────────────────────────────────────────────────────
  // White face, rose-pink accent — clean and feminine
  void _paintRose(Canvas canvas, Size size) {
    final center    = Offset(size.width / 2, size.height / 2);
    final radius    = size.width / 2;
    final ringInset = radius - 3.5;
    final bgColor   = isDark ? const Color(0xFF1F1018) : Colors.white;
    const rose      = Color(0xFFF472B6);
    final handColor = isDark ? Colors.white : Colors.black87;

    canvas.drawCircle(center, radius, Paint()..color = bgColor);

    _ring(canvas, center, ringInset, rose.withOpacity(0.15), rose, 3.5);

    _ticks60(canvas, center, ringInset,
        isDark ? Colors.white.withOpacity(0.50) : Colors.black.withOpacity(0.38),
        isDark ? Colors.white.withOpacity(0.18) : Colors.black.withOpacity(0.12));

    _numbers(canvas, center, ringInset,
        isDark ? Colors.white60 : Colors.black54, radius * 0.11);

    _drawHand(canvas, center,
        angle: ((now.hour % 12 + now.minute / 60) / 12) * 2 * math.pi - math.pi / 2,
        length: radius * 0.46, width: 4.5, color: handColor);
    _drawHand(canvas, center,
        angle: ((now.minute + now.second / 60) / 60) * 2 * math.pi - math.pi / 2,
        length: radius * 0.66, width: 2.5, color: handColor);
    _drawHand(canvas, center,
        angle: _sf * 2 * math.pi - math.pi / 2,
        length: radius * 0.70, width: 1.2, color: rose);

    canvas.drawCircle(center, 4,   Paint()..color = rose);
    canvas.drawCircle(center, 2,   Paint()..color = bgColor);
  }

  // ── Sage ───────────────────────────────────────────────────────────
  // Soft green-white face, emerald ring — natural and calm
  void _paintSage(Canvas canvas, Size size) {
    final center    = Offset(size.width / 2, size.height / 2);
    final radius    = size.width / 2;
    final ringInset = radius - 3.5;
    final bgColor   = isDark ? const Color(0xFF0A1A10) : const Color(0xFFF0FDF4);
    const sage      = Color(0xFF059669);
    final handColor = isDark ? Colors.white : const Color(0xFF065F46);

    canvas.drawCircle(center, radius, Paint()..color = bgColor);

    _ring(canvas, center, ringInset, sage.withOpacity(0.15), sage, 3.5);

    for (int i = 0; i < 12; i++) {
      final angle      = (i / 12) * 2 * math.pi - math.pi / 2;
      final isCardinal = i % 3 == 0;
      final outer      = ringInset - 7;
      final inner      = isCardinal ? ringInset - 19 : ringInset - 13;
      canvas.drawLine(
        Offset(center.dx + inner * math.cos(angle), center.dy + inner * math.sin(angle)),
        Offset(center.dx + outer * math.cos(angle), center.dy + outer * math.sin(angle)),
        Paint()
          ..color = isDark
              ? Colors.white.withOpacity(isCardinal ? 0.60 : 0.28)
              : sage.withOpacity(isCardinal ? 0.70 : 0.38)
          ..strokeWidth = isCardinal ? 2.0 : 1.2
          ..strokeCap   = StrokeCap.round,
      );
    }

    _numbers(canvas, center, ringInset,
        isDark ? Colors.white60 : sage.withOpacity(0.78), radius * 0.105);

    _drawHand(canvas, center,
        angle: ((now.hour % 12 + now.minute / 60) / 12) * 2 * math.pi - math.pi / 2,
        length: radius * 0.46, width: 4.5, color: handColor);
    _drawHand(canvas, center,
        angle: ((now.minute + now.second / 60) / 60) * 2 * math.pi - math.pi / 2,
        length: radius * 0.66, width: 2.5, color: handColor);
    _drawHand(canvas, center,
        angle: _sf * 2 * math.pi - math.pi / 2,
        length: radius * 0.70, width: 1.2, color: sage);

    canvas.drawCircle(center, 4,   Paint()..color = sage);
    canvas.drawCircle(center, 2,   Paint()..color = bgColor);
  }

  // ── Carbon ─────────────────────────────────────────────────────────
  // Always deep charcoal, clean white markers — dark elegance without glow
  void _paintCarbon(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const bg     = Color(0xFF18181B);

    canvas.drawCircle(center, radius, Paint()..color = bg);

    _ring(canvas, center, radius - 3.5, Colors.white.withOpacity(0.07), accentColor, 3);

    for (int i = 0; i < 12; i++) {
      final angle      = (i / 12) * 2 * math.pi - math.pi / 2;
      final isCardinal = i % 3 == 0;
      _drawRectMarker(canvas, center, radius - 8,
          angle: angle,
          markerWidth:  isCardinal ? 3.5 : 2.0,
          markerLength: isCardinal ? 12.0 : 6.5,
          color: Colors.white.withOpacity(isCardinal ? 0.75 : 0.38));
    }

    _drawHand(canvas, center,
        angle: ((now.hour % 12 + now.minute / 60) / 12) * 2 * math.pi - math.pi / 2,
        length: radius * 0.46, width: 4.5, color: Colors.white);
    _drawHand(canvas, center,
        angle: ((now.minute + now.second / 60) / 60) * 2 * math.pi - math.pi / 2,
        length: radius * 0.66, width: 2.5, color: Colors.white);
    _drawHand(canvas, center,
        angle: _sf * 2 * math.pi - math.pi / 2,
        length: radius * 0.70, width: 1.2, color: accentColor);

    canvas.drawCircle(center, 4.5, Paint()..color = accentColor);
    canvas.drawCircle(center, 2,   Paint()..color = bg);
  }

  // ── Ocean ──────────────────────────────────────────────────────────
  // Pale sky-blue face, ocean-blue accent — airy and fresh
  void _paintOcean(Canvas canvas, Size size) {
    final center    = Offset(size.width / 2, size.height / 2);
    final radius    = size.width / 2;
    final ringInset = radius - 3.5;
    final bgColor   = isDark ? const Color(0xFF071828) : const Color(0xFFF0F9FF);
    const ocean     = Color(0xFF0EA5E9);
    final handColor = isDark ? Colors.white : const Color(0xFF0C4A6E);

    canvas.drawCircle(center, radius, Paint()..color = bgColor);

    _ring(canvas, center, ringInset, ocean.withOpacity(0.15), ocean, 3.5);

    _ticks60(canvas, center, ringInset,
        isDark ? Colors.white.withOpacity(0.50) : ocean.withOpacity(0.60),
        isDark ? Colors.white.withOpacity(0.18) : ocean.withOpacity(0.20));

    _numbers(canvas, center, ringInset,
        isDark ? Colors.white60 : ocean.withOpacity(0.80), radius * 0.11);

    _drawHand(canvas, center,
        angle: ((now.hour % 12 + now.minute / 60) / 12) * 2 * math.pi - math.pi / 2,
        length: radius * 0.46, width: 4.5, color: handColor);
    _drawHand(canvas, center,
        angle: ((now.minute + now.second / 60) / 60) * 2 * math.pi - math.pi / 2,
        length: radius * 0.66, width: 2.5, color: handColor);
    _drawHand(canvas, center,
        angle: _sf * 2 * math.pi - math.pi / 2,
        length: radius * 0.70, width: 1.2, color: ocean);

    canvas.drawCircle(center, 4,   Paint()..color = ocean);
    canvas.drawCircle(center, 2,   Paint()..color = bgColor);
  }

  // ── Ivory ──────────────────────────────────────────────────────────
  void _paintIvory(Canvas canvas, Size size) {
    final center    = Offset(size.width / 2, size.height / 2);
    final radius    = size.width / 2;
    final ringInset = radius - 3.5;
    final bgColor   = isDark ? const Color(0xFF1C1A08) : const Color(0xFFFFFEF0);
    const gold      = Color(0xFFB7860C);
    final handColor = isDark ? const Color(0xFFE8D5A0) : const Color(0xFF3D2B00);
    canvas.drawCircle(center, radius, Paint()..color = bgColor);
    _ring(canvas, center, ringInset, gold.withOpacity(0.18), gold, 3.0);
    _ticks60(canvas, center, ringInset,
        isDark ? Colors.white.withOpacity(0.50) : gold.withOpacity(0.55),
        isDark ? Colors.white.withOpacity(0.18) : gold.withOpacity(0.22));
    _numbers(canvas, center, ringInset, handColor.withOpacity(0.78), radius * 0.115);
    _drawHand(canvas, center, angle: ((now.hour % 12 + now.minute / 60) / 12) * 2 * math.pi - math.pi / 2, length: radius * 0.46, width: 4.5, color: handColor);
    _drawHand(canvas, center, angle: ((now.minute + now.second / 60) / 60) * 2 * math.pi - math.pi / 2, length: radius * 0.66, width: 2.5, color: handColor);
    _drawHand(canvas, center, angle: _sf * 2 * math.pi - math.pi / 2, length: radius * 0.72, width: 1.0, color: gold);
    canvas.drawCircle(center, 4.5, Paint()..color = gold);
    canvas.drawCircle(center, 2.0, Paint()..color = bgColor);
  }

  // ── Lavender ───────────────────────────────────────────────────────
  void _paintLavender(Canvas canvas, Size size) {
    final center    = Offset(size.width / 2, size.height / 2);
    final radius    = size.width / 2;
    final ringInset = radius - 3.5;
    final bgColor   = isDark ? const Color(0xFF1A0A2E) : const Color(0xFFFAF7FF);
    const violet    = Color(0xFF7C3AED);
    final handColor = isDark ? const Color(0xFFC4B5FD) : const Color(0xFF2D1B69);
    canvas.drawCircle(center, radius, Paint()..color = bgColor);
    _ring(canvas, center, ringInset, violet.withOpacity(0.18), violet, 3.5);
    for (int i = 0; i < 12; i++) {
      final angle      = (i / 12) * 2 * math.pi - math.pi / 2;
      final isCardinal = i % 3 == 0;
      final outer = ringInset - 7; final inner = isCardinal ? ringInset - 18 : ringInset - 11;
      canvas.drawLine(
        Offset(center.dx + inner * math.cos(angle), center.dy + inner * math.sin(angle)),
        Offset(center.dx + outer * math.cos(angle), center.dy + outer * math.sin(angle)),
        Paint()..color = isDark ? violet.withOpacity(isCardinal ? 0.80 : 0.38) : violet.withOpacity(isCardinal ? 0.55 : 0.25)
               ..strokeWidth = isCardinal ? 2.0 : 1.1..strokeCap = StrokeCap.round,
      );
    }
    _numbers(canvas, center, ringInset, isDark ? const Color(0xFFC4B5FD) : violet.withOpacity(0.70), radius * 0.110);
    _drawHand(canvas, center, angle: ((now.hour % 12 + now.minute / 60) / 12) * 2 * math.pi - math.pi / 2, length: radius * 0.46, width: 4.5, color: handColor);
    _drawHand(canvas, center, angle: ((now.minute + now.second / 60) / 60) * 2 * math.pi - math.pi / 2, length: radius * 0.66, width: 2.5, color: handColor);
    _drawHand(canvas, center, angle: _sf * 2 * math.pi - math.pi / 2, length: radius * 0.70, width: 1.2, color: violet);
    canvas.drawCircle(center, 4.0, Paint()..color = violet);
    canvas.drawCircle(center, 2.0, Paint()..color = bgColor);
  }

  // ── Coral ──────────────────────────────────────────────────────────
  void _paintCoral(Canvas canvas, Size size) {
    final center    = Offset(size.width / 2, size.height / 2);
    final radius    = size.width / 2;
    final ringInset = radius - 3.5;
    final bgColor   = isDark ? const Color(0xFF1A0A08) : const Color(0xFFFFF5F2);
    const coral     = Color(0xFFE05A3A);
    final handColor = isDark ? Colors.white : const Color(0xFF7C2416);
    canvas.drawCircle(center, radius, Paint()..color = bgColor);
    _ring(canvas, center, ringInset, coral.withOpacity(0.18), coral, 3.5);
    _ticks60(canvas, center, ringInset,
        isDark ? Colors.white.withOpacity(0.48) : coral.withOpacity(0.45),
        isDark ? Colors.white.withOpacity(0.16) : coral.withOpacity(0.18));
    _numbers(canvas, center, ringInset, isDark ? Colors.white60 : coral.withOpacity(0.65), radius * 0.111);
    _drawHand(canvas, center, angle: ((now.hour % 12 + now.minute / 60) / 12) * 2 * math.pi - math.pi / 2, length: radius * 0.46, width: 4.5, color: handColor);
    _drawHand(canvas, center, angle: ((now.minute + now.second / 60) / 60) * 2 * math.pi - math.pi / 2, length: radius * 0.66, width: 2.5, color: handColor);
    _drawHand(canvas, center, angle: _sf * 2 * math.pi - math.pi / 2, length: radius * 0.70, width: 1.2, color: coral);
    canvas.drawCircle(center, 4.0, Paint()..color = coral);
    canvas.drawCircle(center, 2.0, Paint()..color = bgColor);
  }

  // ── Mint ───────────────────────────────────────────────────────────
  void _paintMint(Canvas canvas, Size size) {
    final center    = Offset(size.width / 2, size.height / 2);
    final radius    = size.width / 2;
    final ringInset = radius - 3.5;
    final bgColor   = isDark ? const Color(0xFF061A12) : const Color(0xFFF0FDF8);
    const mint      = Color(0xFF10B981);
    final handColor = isDark ? const Color(0xFFA7F3D0) : const Color(0xFF064E3B);
    canvas.drawCircle(center, radius, Paint()..color = bgColor);
    _ring(canvas, center, ringInset, mint.withOpacity(0.18), mint, 3.5);
    for (int i = 0; i < 4; i++) {
      final angle = (i / 4) * 2 * math.pi - math.pi / 2;
      final dotC  = Offset(center.dx + (ringInset - 10) * math.cos(angle), center.dy + (ringInset - 10) * math.sin(angle));
      canvas.drawCircle(dotC, 4.0, Paint()..color = isDark ? mint.withOpacity(0.60) : mint.withOpacity(0.45));
    }
    for (int i = 0; i < 12; i++) {
      if (i % 3 == 0) continue;
      final angle = (i / 12) * 2 * math.pi - math.pi / 2;
      final dotC  = Offset(center.dx + (ringInset - 10) * math.cos(angle), center.dy + (ringInset - 10) * math.sin(angle));
      canvas.drawCircle(dotC, 2.0, Paint()..color = isDark ? mint.withOpacity(0.35) : mint.withOpacity(0.28));
    }
    _drawHand(canvas, center, angle: ((now.hour % 12 + now.minute / 60) / 12) * 2 * math.pi - math.pi / 2, length: radius * 0.44, width: 4.5, color: handColor);
    _drawHand(canvas, center, angle: ((now.minute + now.second / 60) / 60) * 2 * math.pi - math.pi / 2, length: radius * 0.65, width: 2.5, color: handColor);
    _drawHand(canvas, center, angle: _sf * 2 * math.pi - math.pi / 2, length: radius * 0.70, width: 1.2, color: mint);
    canvas.drawCircle(center, 4.0, Paint()..color = mint);
    canvas.drawCircle(center, 2.0, Paint()..color = bgColor);
  }

  // ── Peach ──────────────────────────────────────────────────────────
  void _paintPeach(Canvas canvas, Size size) {
    final center    = Offset(size.width / 2, size.height / 2);
    final radius    = size.width / 2;
    final ringInset = radius - 3.5;
    final bgColor   = isDark ? const Color(0xFF1A1208) : const Color(0xFFFFF8F2);
    const peach     = Color(0xFFF97316);
    final handColor = isDark ? const Color(0xFFFED7AA) : const Color(0xFF7C3010);
    canvas.drawCircle(center, radius, Paint()..color = bgColor);
    _ring(canvas, center, ringInset, peach.withOpacity(0.18), peach, 3.5);
    _ticks60(canvas, center, ringInset,
        isDark ? Colors.white.withOpacity(0.48) : peach.withOpacity(0.42),
        isDark ? Colors.white.withOpacity(0.16) : peach.withOpacity(0.18));
    _numbers(canvas, center, ringInset, isDark ? Colors.white60 : peach.withOpacity(0.68), radius * 0.111);
    _drawHand(canvas, center, angle: ((now.hour % 12 + now.minute / 60) / 12) * 2 * math.pi - math.pi / 2, length: radius * 0.46, width: 4.5, color: handColor);
    _drawHand(canvas, center, angle: ((now.minute + now.second / 60) / 60) * 2 * math.pi - math.pi / 2, length: radius * 0.66, width: 2.5, color: handColor);
    _drawHand(canvas, center, angle: _sf * 2 * math.pi - math.pi / 2, length: radius * 0.70, width: 1.2, color: peach);
    canvas.drawCircle(center, 4.0, Paint()..color = peach);
    canvas.drawCircle(center, 2.0, Paint()..color = bgColor);
  }

  // ── Champagne ──────────────────────────────────────────────────────
  void _paintChampagne(Canvas canvas, Size size) {
    final center    = Offset(size.width / 2, size.height / 2);
    final radius    = size.width / 2;
    final ringInset = radius - 3.5;
    final bgColor   = isDark ? const Color(0xFF1A1608) : const Color(0xFFFEFBF0);
    const gold      = Color(0xFFC49A22);
    final handColor = isDark ? const Color(0xFFFDE68A) : const Color(0xFF4A3000);
    canvas.drawCircle(center, radius, Paint()..color = bgColor);
    _ring(canvas, center, ringInset, gold.withOpacity(0.20), gold, 3.0);
    for (int i = 0; i < 12; i++) {
      final angle      = (i / 12) * 2 * math.pi - math.pi / 2;
      final isCardinal = i % 3 == 0;
      _drawRectMarker(canvas, center, ringInset - 4,
          angle: angle,
          markerWidth: isCardinal ? 3.0 : 1.8,
          markerLength: isCardinal ? 11.0 : 6.0,
          color: isDark ? Colors.white.withOpacity(isCardinal ? 0.65 : 0.30) : gold.withOpacity(isCardinal ? 0.72 : 0.38));
    }
    _numbers(canvas, center, ringInset, isDark ? const Color(0xFFFDE68A) : gold.withOpacity(0.75), radius * 0.110);
    _drawHand(canvas, center, angle: ((now.hour % 12 + now.minute / 60) / 12) * 2 * math.pi - math.pi / 2, length: radius * 0.46, width: 4.5, color: handColor);
    _drawHand(canvas, center, angle: ((now.minute + now.second / 60) / 60) * 2 * math.pi - math.pi / 2, length: radius * 0.66, width: 2.5, color: handColor);
    _drawHand(canvas, center, angle: _sf * 2 * math.pi - math.pi / 2, length: radius * 0.72, width: 1.0, color: gold);
    canvas.drawCircle(center, 4.5, Paint()..color = gold);
    canvas.drawCircle(center, 2.0, Paint()..color = bgColor);
  }

  // ── Helpers ────────────────────────────────────────────────────────
  void _drawHand(Canvas canvas, Offset center,
      {required double angle, required double length, required double width, required Color color}) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final bool isSecond = width <= 1.5;
    final tailLength = isSecond ? length * 0.22 : length * 0.12;

    final path = Path();
    if (isSecond) {
      // Second hand (length along X, width along Y)
      path.moveTo(-tailLength, -width / 2);
      path.lineTo(length, -width / 2);
      path.lineTo(length, width / 2);
      path.lineTo(-tailLength, width / 2);
      path.close();
    } else {
      // Tapered Hour/Minute hand (length along X, width along Y)
      path.moveTo(-tailLength, -width * 0.8);
      path.lineTo(length * 0.95, -width * 0.3);
      path.lineTo(length, 0);
      path.lineTo(length * 0.95, width * 0.3);
      path.lineTo(-tailLength, width * 0.8);
      path.close();
    }

    // Shadow
    canvas.drawPath(
      path.shift(const Offset(2, 2)),
      Paint()
        ..color = Colors.black.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );

    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
    
    // 3D Inner highlight
    if (!isSecond) {
      final highlightPath = Path();
      highlightPath.moveTo(-tailLength * 0.8, 0);
      highlightPath.lineTo(length * 0.9, 0);
      canvas.drawPath(highlightPath, Paint()..color = Colors.white.withOpacity(0.2)..strokeWidth = width * 0.2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    }

    canvas.restore();
  }

  void _drawRectMarker(Canvas canvas, Offset center, double radius,
      {required double angle, required double markerWidth, required double markerLength, required Color color}) {
    final outerDist       = radius - 4;
    final markerCenterDist = outerDist - markerLength / 2;
    final markerCenter    = Offset(
      center.dx + markerCenterDist * math.cos(angle),
      center.dy + markerCenterDist * math.sin(angle),
    );
    canvas.save();
    canvas.translate(markerCenter.dx, markerCenter.dy);
    canvas.rotate(angle + math.pi / 2);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: markerWidth, height: markerLength),
      Paint()..color = color..style = PaintingStyle.fill,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ClockPainter old) =>
      old.now != now || old.isDark != isDark || old.accentColor != accentColor || old.style != style;
}
