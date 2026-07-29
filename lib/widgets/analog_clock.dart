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
    // Keep the ring hairline-slim on small dials and never heavier than asked.
    final sw = math.min(w, r * 0.024);
    canvas.drawCircle(c, r,
        Paint()..color = track..style = PaintingStyle.stroke..strokeWidth = sw);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2, _sf * 2 * math.pi, false,
      Paint()..color = arc..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.round,
    );
  }

  void _numbers(Canvas canvas, Offset center, double radius, Color color, double fontSize) {
    const labels = {0:'12',1:'1',2:'2',3:'3',4:'4',5:'5',6:'6',7:'7',8:'8',9:'9',10:'10',11:'11'};
    labels.forEach((i, label) {
      final angle  = (i / 12) * 2 * math.pi - math.pi / 2;
      final labelR = radius * 0.845;
      final pos    = Offset(center.dx + labelR * math.cos(angle), center.dy + labelR * math.sin(angle));
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            height: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    });
  }

  void _ticks60(Canvas canvas, Offset center, double ringInset, Color major, Color minor) {
    for (int i = 0; i < 60; i++) {
      final angle    = (i / 60) * 2 * math.pi - math.pi / 2;
      final isMajor  = i % 5 == 0;
      final outer    = ringInset - ringInset * 0.040;
      final inner    = ringInset - ringInset * (isMajor ? 0.118 : 0.074);
      canvas.drawLine(
        Offset(center.dx + inner * math.cos(angle), center.dy + inner * math.sin(angle)),
        Offset(center.dx + outer * math.cos(angle), center.dy + outer * math.sin(angle)),
        Paint()
          ..color = isMajor ? major : minor
          ..strokeWidth = ringInset * (isMajor ? 0.013 : 0.006)
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  // ── Classic ────────────────────────────────────────────────────────
  void _paintClassic(Canvas canvas, Size size) {
    final center    = Offset(size.width / 2, size.height / 2);
    final radius    = size.width / 2;
    final ringInset = radius - 3.5;
    final bg        = isDark ? const Color(0xFF1C1C2E) : Colors.white;

    canvas.drawCircle(center, radius, Paint()..color = bg);

    _ring(canvas, center, ringInset, accentColor.withOpacity(0.15), accentColor, 3.5);

    _ticks60(canvas, center, ringInset,
        isDark ? Colors.white60 : Colors.black45,
        isDark ? Colors.white24 : Colors.black12);

    _numbers(canvas, center, ringInset,
        isDark ? Colors.white70 : Colors.black87, radius * 0.115);

    _hands(canvas, center, radius,
        hand: isDark ? Colors.white : const Color(0xFF14141C),
        second: accentColor,
        face: bg);
  }

  // ── Minimal ────────────────────────────────────────────────────────
  void _paintMinimal(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final bg     = isDark ? const Color(0xFF12121A) : Colors.white;

    canvas.drawCircle(center, radius, Paint()..color = bg);

    _ring(canvas, center, radius - 3.5, accentColor.withOpacity(0.12), accentColor, 2.5);

    for (int i = 0; i < 4; i++) {
      final angle   = (i / 4) * 2 * math.pi - math.pi / 2;
      final dotDist = radius - radius * 0.075;
      final dotC    = Offset(center.dx + dotDist * math.cos(angle), center.dy + dotDist * math.sin(angle));
      canvas.drawCircle(dotC, radius * 0.016, Paint()..color = isDark ? Colors.white38 : Colors.black45);
    }

    _hands(canvas, center, radius,
        hand: isDark ? Colors.white : Colors.black87,
        second: accentColor,
        face: bg);
  }

  // ── Sketch ─────────────────────────────────────────────────────────
  // Ultra-clean: only dashes, no numbers, whisper-thin hands
  void _paintSketch(Canvas canvas, Size size) {
    final center    = Offset(size.width / 2, size.height / 2);
    final radius    = size.width / 2;
    final ringInset = radius - 3.5;
    final bg        = isDark ? const Color(0xFF1A1A22) : Colors.white;

    canvas.drawCircle(center, radius, Paint()..color = bg);

    _ring(canvas, center, ringInset, accentColor.withOpacity(0.12), accentColor, 2);

    _ticks12(canvas, center, ringInset,
        cardinal: isDark ? Colors.white.withOpacity(0.70) : Colors.black.withOpacity(0.60),
        other: isDark ? Colors.white.withOpacity(0.32) : Colors.black.withOpacity(0.22));

    _hands(canvas, center, radius,
        hand: isDark ? Colors.white : Colors.black87,
        second: accentColor,
        face: bg);
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
      final dotR       = radius - radius * 0.10;
      final dotC       = Offset(center.dx + dotR * math.cos(angle), center.dy + dotR * math.sin(angle));
      canvas.drawCircle(dotC, radius * (isCardinal ? 0.024 : 0.014),
          Paint()..color = Colors.white.withOpacity(isCardinal ? 0.80 : 0.40));
    }

    _hands(canvas, center, radius, hand: Colors.white, second: accentColor, face: bg);
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

    _hands(canvas, center, radius, hand: handColor, second: amber, face: bgColor);
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

    _hands(canvas, center, radius, hand: handColor, second: rose, face: bgColor);
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

    _ticks12(canvas, center, ringInset,
        cardinal: isDark ? Colors.white.withOpacity(0.60) : sage.withOpacity(0.70),
        other: isDark ? Colors.white.withOpacity(0.28) : sage.withOpacity(0.38));

    _numbers(canvas, center, ringInset,
        isDark ? Colors.white60 : sage.withOpacity(0.78), radius * 0.105);

    _hands(canvas, center, radius, hand: handColor, second: sage, face: bgColor);
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
          markerWidth:  radius * (isCardinal ? 0.022 : 0.013),
          markerLength: radius * (isCardinal ? 0.085 : 0.048),
          color: Colors.white.withOpacity(isCardinal ? 0.75 : 0.38));
    }

    _hands(canvas, center, radius, hand: Colors.white, second: accentColor, face: bg);
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

    _hands(canvas, center, radius, hand: handColor, second: ocean, face: bgColor);
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

    _hands(canvas, center, radius, hand: handColor, second: gold, face: bgColor);
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
    _ticks12(canvas, center, ringInset,
        cardinal: violet.withOpacity(isDark ? 0.80 : 0.55),
        other: violet.withOpacity(isDark ? 0.38 : 0.25));
    _numbers(canvas, center, ringInset,
        isDark ? const Color(0xFFC4B5FD) : violet.withOpacity(0.70), radius * 0.110);

    _hands(canvas, center, radius, hand: handColor, second: violet, face: bgColor);
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
    _numbers(canvas, center, ringInset,
        isDark ? Colors.white60 : coral.withOpacity(0.65), radius * 0.111);

    _hands(canvas, center, radius, hand: handColor, second: coral, face: bgColor);
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

    final dotR = ringInset - ringInset * 0.078;
    for (int i = 0; i < 12; i++) {
      final angle      = (i / 12) * 2 * math.pi - math.pi / 2;
      final isCardinal = i % 3 == 0;
      final dotC = Offset(center.dx + dotR * math.cos(angle), center.dy + dotR * math.sin(angle));
      canvas.drawCircle(dotC, radius * (isCardinal ? 0.026 : 0.013),
          Paint()..color = mint.withOpacity(isDark
              ? (isCardinal ? 0.60 : 0.35)
              : (isCardinal ? 0.45 : 0.28)));
    }

    _hands(canvas, center, radius, hand: handColor, second: mint, face: bgColor);
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
    _numbers(canvas, center, ringInset,
        isDark ? Colors.white60 : peach.withOpacity(0.68), radius * 0.111);

    _hands(canvas, center, radius, hand: handColor, second: peach, face: bgColor);
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
          markerWidth:  radius * (isCardinal ? 0.019 : 0.011),
          markerLength: radius * (isCardinal ? 0.080 : 0.044),
          color: isDark
              ? Colors.white.withOpacity(isCardinal ? 0.65 : 0.30)
              : gold.withOpacity(isCardinal ? 0.72 : 0.38));
    }
    _numbers(canvas, center, ringInset,
        isDark ? const Color(0xFFFDE68A) : gold.withOpacity(0.75), radius * 0.110);

    _hands(canvas, center, radius, hand: handColor, second: gold, face: bgColor);
  }

  // ── Hands ──────────────────────────────────────────────────────────
  // Hour, minute and second hands + centre cap. Every dimension is a
  // fraction of the dial radius, so the hands stay slim and legible from
  // the 150px compact dial up to the 260px full-size one.
  void _hands(
    Canvas canvas,
    Offset center,
    double radius, {
    required Color hand,
    required Color second,
    required Color face,
  }) {
    final hourAngle   = ((now.hour % 12 + now.minute / 60) / 12) * 2 * math.pi - math.pi / 2;
    final minuteAngle = ((now.minute + now.second / 60) / 60) * 2 * math.pi - math.pi / 2;
    final secondAngle = _sf * 2 * math.pi - math.pi / 2;

    _blade(canvas, center, radius,
        angle: hourAngle, length: radius * 0.50, width: radius * 0.032, color: hand);
    _blade(canvas, center, radius,
        angle: minuteAngle, length: radius * 0.735, width: radius * 0.021, color: hand);
    _secondHand(canvas, center, radius, angle: secondAngle, color: second);

    // Centre cap — small accent disc with a face-coloured pin hole.
    canvas.drawCircle(center, radius * 0.030, Paint()..color = second);
    canvas.drawCircle(center, radius * 0.012, Paint()..color = face);
  }

  /// Slim tapered hour/minute hand with a rounded pivot and a soft,
  /// fixed-direction drop shadow (no thick outline, no glossy streak).
  void _blade(Canvas canvas, Offset center, double radius,
      {required double angle, required double length, required double width, required Color color}) {
    final w    = math.max(1.6, width);
    final tail = length * 0.13;

    final path = Path()
      ..moveTo(-tail, -w * 0.72)
      ..lineTo(length * 0.90, -w * 0.32)
      ..quadraticBezierTo(length, 0, length * 0.90, w * 0.32)
      ..lineTo(-tail, w * 0.72)
      ..close();

    void stamp(Offset origin, Paint paint, {bool pivot = true}) {
      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      canvas.rotate(angle);
      canvas.drawPath(path, paint);
      if (pivot) canvas.drawCircle(Offset.zero, w * 0.72, paint);
      canvas.restore();
    }

    // Shadow keeps a constant light direction instead of rotating with the hand.
    stamp(
      center + Offset(radius * 0.008, radius * 0.012),
      Paint()
        ..color = Colors.black.withOpacity(0.16)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.012),
    );

    stamp(center, Paint()..color = color..isAntiAlias = true);
  }

  /// Hairline second hand with a counterweight tail — the classic watch cue
  /// that reads clearly even at small sizes.
  void _secondHand(Canvas canvas, Offset center, double radius,
      {required double angle, required Color color}) {
    final w      = math.max(1.0, radius * 0.0095);
    final length = radius * 0.780;
    final tail   = radius * 0.185;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final paint = Paint()
      ..color = color
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawLine(Offset(-tail, 0), Offset(length, 0), paint);
    canvas.drawCircle(Offset(-tail * 0.62, 0), radius * 0.026, paint..style = PaintingStyle.fill);

    canvas.restore();
  }

  /// 12 slim index dashes (used by the number-less / dot-free faces).
  void _ticks12(Canvas canvas, Offset center, double ringInset,
      {required Color cardinal, required Color other}) {
    for (int i = 0; i < 12; i++) {
      final angle      = (i / 12) * 2 * math.pi - math.pi / 2;
      final isCardinal = i % 3 == 0;
      final outer      = ringInset - ringInset * 0.055;
      final inner      = ringInset - ringInset * (isCardinal ? 0.150 : 0.100);
      canvas.drawLine(
        Offset(center.dx + inner * math.cos(angle), center.dy + inner * math.sin(angle)),
        Offset(center.dx + outer * math.cos(angle), center.dy + outer * math.sin(angle)),
        Paint()
          ..color       = isCardinal ? cardinal : other
          ..strokeWidth = ringInset * (isCardinal ? 0.015 : 0.008)
          ..strokeCap   = StrokeCap.round,
      );
    }
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
