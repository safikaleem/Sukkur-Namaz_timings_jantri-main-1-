import 'package:flutter/material.dart';

/// A two-tone push pin: coloured cap (grip + collar) over a separate needle.
/// Material's Icons.push_pin is a single-colour glyph, so it cannot show the
/// cap and the needle in different colours - this draws them instead.
class PinIcon extends StatelessWidget {
  final double size;

  /// Override the theme-derived colours. Left null, the pin follows the
  /// current brightness.
  final Color? capColor;
  final Color? needleColor;

  const PinIcon({
    super.key,
    this.size = 20,
    this.capColor,
    this.needleColor,
  });

  // Light: red cap, black needle.
  static const _capLight = Color(0xFFD32F2F);
  static const _needleLight = Colors.black;

  // Dark: a lighter red reads better against a dark background, and the needle
  // mirrors the light theme by taking the background's opposite - near-white
  // instead of black, which would otherwise disappear.
  static const _capDark = Color(0xFFEF5350);
  static const _needleDark = Color(0xFFECEFF1);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PinPainter(
          capColor: capColor ?? (isDark ? _capDark : _capLight),
          needleColor: needleColor ?? (isDark ? _needleDark : _needleLight),
        ),
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  final Color capColor;
  final Color needleColor;

  _PinPainter({required this.capColor, required this.needleColor});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final cx = size.width / 2;

    // Needle: tapers from under the collar down to a point.
    final needle = Path()
      ..moveTo(cx - s * 0.045, s * 0.46)
      ..lineTo(cx + s * 0.045, s * 0.46)
      ..lineTo(cx, s * 1.0)
      ..close();
    canvas.drawPath(needle, Paint()..color = needleColor);

    final cap = Paint()..color = capColor;

    // Grip.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - s * 0.17, 0, cx + s * 0.17, s * 0.34),
        Radius.circular(s * 0.06),
      ),
      cap,
    );

    // Collar.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - s * 0.30, s * 0.32, cx + s * 0.30, s * 0.46),
        Radius.circular(s * 0.05),
      ),
      cap,
    );
  }

  @override
  bool shouldRepaint(_PinPainter old) =>
      old.capColor != capColor || old.needleColor != needleColor;
}
