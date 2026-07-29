import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';

class DrSloganFooter extends StatelessWidget {
  const DrSloganFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    // Keyed off the timings actually in use, not the radio button: ticking
    // "World" before choosing a city still leaves the Jantri in force, and the
    // calculation-method disclaimer would be wrong there.
    final bool isWorld = settings.usesCalculatedTimings;

    final String text = isWorld
      ? settings.translate(
        'These timings are according to the calculation method, therefore a 3-minute precaution should be added to prayer timings (prayers and Iftar should be observed 3 minutes after the given times, while fasting should end 3 minutes before Subah Sadiq time).',
        'یہ اوقات کیلکیولیشن میتھڈ کے مطابق ہیں، لہٰذا نماز کے اوقات میں تین منٹ کی احتیاط شامل کی جائے (دیے گئے اوقات سے تین منٹ بعد نمازیں اور افطار کیا جائے، جبکہ روزہ صبح صادق کے وقت سے تین منٹ پہلے بند کیا جائے)',
        'هي وقت حسابي طريقي مطابق آهن، ان ڪري نماز جي وقتن ۾ ٽن منٽن جي احتياط شامل ڪئي وڃي (ڏنل وقتن کان ٽي منٽ پوءِ نماز ۽ افطار ڪيو وڃي، جڏهن ته روزو صبح صادق جي وقت کان ٽي منٽ اڳ بند ڪيو وڃي)',
        'هذه الأوقات مبنية على طريقة الحساب، لذا يجب تضمين احتياط 3 دقائق في أوقات الصلاة (يجب أداء الصلاة والإفطار بعد 3 دقائق من الأوقات المحددة، بينما يجب الإمساك عن الطعام قبل 3 دقائق من وقت الصبح الصادق).'
      )
      : settings.translate(
        'ماہر فلکیات حضرت سید کاکاخیل صاحب کا فرمانا ہے کہ تخریجِ جدید کے بعد اب یہ جنتری پنوعاقل، ہالیجی شریف،کرم پور،شکارپور،امروٹ شریف، پیرگوٹھ،خیرپور، پریالو اور شادی شہیدتک کے لئے قابل عمل ہے۔ البتہ شکارپور، امروٹ شریف اور پیر گوٹھ والے افطار اور شام کی نمازوں میں ایک منٹ کی تاخیر کریں۔',
        'ماہر فلکیات حضرت سید کاکاخیل صاحب کا فرمانا ہے کہ تخریجِ جدید کے بعد اب یہ جنتری پنوعاقل، ہالیجی شریف،کرم پور،شکارپور،امروٹ شریف، پیرگوٹھ،خیرپور، پریالو اور شادی شہیدتک کے لئے قابل عمل ہے۔ البتہ شکارپور، امروٹ شریف اور پیر گوٹھ والے افطار اور شام کی نمازوں میں ایک منٹ کی تاخیر کریں۔',
        'ماهر فلڪيات حضرت سيد ڪاڪاخيل صاحب جو فرمائڻ آهي ته جديد تخريج کان پوءِ هاڻي هي جنتري پنوعاقل، هاليجي شريف، ڪرم پور، شڪارپور، امروٽ شريف، پير ڳوٺ، خيرپور، پريالو ۽ شادي شهيد تائين لاءِ قابل عمل آهي. البته شڪارپور، امروٽ شريف ۽ پير ڳوٺ وارا افطار ۽ شام جي نمازن ۾ هڪ منٽ جي تاخير ڪن.',
        'وفقًا لعالم الفلك الشيخ سيد كاكاخيل حفظه الله، بعد الحسابات الجديدة، أصبح هذا التقويم ساريًا على بانو عاقل، هاليجي شريف، كرمبور، شيكاربور، أمروت شريف، بير کوت، خيربور، بريالو وشادي شهيد. ومع ذلك، يجب على سكان شيكاربور، أمروت شريف، وبير کوت الإمساك عن الإفطار مع الغروب دقيقة واحدة من الوقت الجدولي.'
    );

    // The Sukkur (Kaka Khel) text is written in Urdu whatever the app language,
    // so it always needs the Urdu font and RTL. The world text is translated,
    // so it must follow the selected language instead - otherwise Bengali,
    // Hindi, Turkish, French and Indonesian render right-to-left in a
    // Nastaliq font and are unreadable.
    final bool textIsRtl = isWorld ? settings.isRtl : true;
    final String? font = switch (settings.language) {
      'sindhi' => AppTheme.getSindhiFont(context),
      'arabic' => null,
      'urdu' => AppTheme.urduFont,
      _ => isWorld ? null : AppTheme.urduFont,
    };

    // Responsively scale down font size on smaller devices to ensure it fits nicely.
    final double fontSize = screenWidth < 360
        ? 9.2
        : (screenWidth < 400 ? 9.8 : 10.5);

    // Nastaliq (Urdu/Sindhi) cascades diagonally with tall ascenders and deep
    // descenders. At 1.40 the glyphs get clipped top and bottom, so give those
    // scripts a taller line box.
    final bool isNastaliq =
        settings.language == 'urdu' || settings.language == 'sindhi';
    final double lineHeight = isNastaliq ? 1.9 : 1.4;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth < 360 ? 8.0 : 12.0,
        vertical: 6.0,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A1A2E)
            : const Color(0xFFF0F4FF),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : const Color(0xFF4A6FA5).withValues(alpha: 0.25),
            width: 0.8,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final direction =
              textIsRtl ? TextDirection.rtl : TextDirection.ltr;
          final baseStyle = TextStyle(
            fontFamily: font,
            fontSize: fontSize,
            color: isDark ? Colors.white70 : Colors.black87,
            height: lineHeight,
          );

          // Measure with the style the Text will actually resolve to - the
          // ambient DefaultTextStyle merged in, and the user's text scaling
          // applied - otherwise the chosen size overflows anyway.
          final effectiveStyle =
              DefaultTextStyle.of(context).style.merge(baseStyle);

          final size = _fittingFontSize(
            text: text,
            style: effectiveStyle,
            direction: direction,
            textScaler: MediaQuery.textScalerOf(context),
            maxWidth: constraints.maxWidth,
          );

          return Text(
            text,
            textDirection: direction,
            textAlign: TextAlign.center,
            // The size above is chosen so the text fits inside this many
            // lines. The cap plus ellipsis is a backstop for the pathological
            // case where even the smallest size cannot fit - then at least the
            // truncation is visible rather than a silent chop.
            maxLines: _hardMaxLines,
            overflow: TextOverflow.ellipsis,
            style: baseStyle.copyWith(fontSize: size),
          );
        },
      ),
    );
  }
}

/// Prefer this many lines; shrink the text to reach it if that stays legible.
const int _preferredMaxLines = 3;

/// Never exceed this many lines.
const int _hardMaxLines = 4;

/// Smallest size worth shrinking to in order to win back a line.
const double _minSizeForPreferred = 8.0;

/// Absolute floor - below this the footer stops being readable.
const double _minSize = 6.0;

/// Largest font size at or below [style].fontSize that lets [text] fit inside
/// [_preferredMaxLines], falling back to [_hardMaxLines] when three lines would
/// require an unreadably small size. Shrinking rather than clipping is what
/// keeps the longer translations - Urdu especially - fully visible.
double _fittingFontSize({
  required String text,
  required TextStyle style,
  required TextDirection direction,
  required TextScaler textScaler,
  required double maxWidth,
}) {
  final base = style.fontSize ?? 10.5;
  if (maxWidth <= 0 || !maxWidth.isFinite) return base;

  // Measure against a hair less width than we have, so rounding between the
  // measuring pass and the real layout cannot tip the last line over.
  final measureWidth = maxWidth - 1.0;

  bool fits(double size, int lines) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style.copyWith(fontSize: size)),
      textDirection: direction,
      textAlign: TextAlign.center,
      textScaler: textScaler,
      maxLines: lines,
    )..layout(maxWidth: measureWidth);
    return !painter.didExceedMaxLines;
  }

  double? largestThatFits(int lines, double floor) {
    for (var size = base; size >= floor; size -= 0.2) {
      if (fits(size, lines)) return size;
    }
    return null;
  }

  return largestThatFits(_preferredMaxLines, _minSizeForPreferred) ??
      largestThatFits(_hardMaxLines, _minSize) ??
      _minSize;
}
