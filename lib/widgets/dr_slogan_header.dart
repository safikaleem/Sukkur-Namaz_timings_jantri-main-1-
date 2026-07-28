import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';

class DrSloganHeader extends StatelessWidget {
  final Color? textColor;
  final Color? subColor;
  final double scale;

  const DrSloganHeader({
    super.key,
    this.textColor,
    this.subColor,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    // The Jantri attribution belongs to the Sukkur timings only. Guarding here
    // rather than at each call site means it can never reappear on a screen
    // that forgets to check, and covers any screen added later.
    if (settings.locationMode != LocationMode.sukkur) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedTextColor = textColor ?? (isDark ? Colors.white : Colors.black87);
    final resolvedSubColor = subColor ?? (isDark ? Colors.white60 : Colors.black54);

    final isSindhi = settings.language == 'sindhi';
    final String? font = settings.language == 'sindhi' 
        ? AppTheme.getSindhiFont(context) 
        : (settings.language == 'arabic' ? null : AppTheme.urduFont);

    final String title = settings.translate('جنتری', 'جنتری', 'جنتري', 'التقويم');
    final String name = settings.translate('حضرت ڈاکٹر حفیظ اللہ صاحب', 'حضرت ڈاکٹر حفیظ اللہ صاحب', 'حضرت ڊاڪٽر حفيظ الله صاحب', 'الشيخ الدكتور حفيظ الله');
    final String sub = settings.translate('قَدَّسَ اللہ سِرَّہُ', 'قَدَّسَ اللہ سِرَّہُ', 'قَدَّسَ اللهُ سِرَّهُ', 'قَدَّسَ اللهُ سِرَّهُ');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: font,
            fontSize: 15 * scale,
            color: resolvedSubColor,
            height: 1.4,
          ),
        ),
        Text(
          name,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: font,
            fontSize: isSindhi ? 18 * scale : 22 * scale,
            color: resolvedTextColor,
            fontWeight: FontWeight.w700,
            height: 1.6,
          ),
        ),
        Text(
          sub,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: font,
            fontSize: 15 * scale,
            color: resolvedSubColor,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
