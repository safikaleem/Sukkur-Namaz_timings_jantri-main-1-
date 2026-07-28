import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';

class DateTimeSettingsScreen extends StatelessWidget {
  const DateTimeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = settings.isRtl;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_rounded,
                      size: 20,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    settings.translate('Date & Time', 'تاریخ اور وقت', 'تاريخ ۽ وقت', 'التاريخ والوقت'),
                    style: TextStyle(
                      fontSize: isRtl ? 28 : 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ───────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 8),

                  // ── Time Format section ───────────────────────────
                  _SectionLabel(
                    settings.translate('TIME FORMAT', 'وقت کی شکل', 'وقت جي شڪل', 'صيغة الوقت'),
                    isDark,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              )
                            ],
                    ),
                    child: Column(
                      children: [
                        _TimeFormatTile(
                          label: settings.translate(
                              'Automatic (based on Phone setting)',
                              'خودکار (فون کی ترتیب کے مطابق)',
                              'خودڪار (فون جي سيٽنگ موجب)',
                              'تلقائي (حسب إعداد الهاتف)'),
                          subtitle: settings.translate('System default', 'سسٹم ڈیفالٹ', 'سسٽم ڊفالٽ', 'افتراضي النظام'),
                          value: TimeFormat.system,
                          groupValue: settings.timeFormat,
                          isDark: isDark,
                          isFirst: true,
                          onChanged: (v) => settings.setTimeFormat(v),
                        ),
                        _Divider(isDark: isDark),
                        _TimeFormatTile(
                          label: settings.translate(
                              'Use 12 hour format',
                              '12 گھنٹے کی شکل استعمال کریں',
                              '12 ڪلاڪ جي شڪل استعمال ڪريو',
                              'استخدام صيغة 12 ساعة'),
                          subtitle: settings.translate('PM 1:00', 'PM 1:00', 'شام 1:00', 'م 1:00'),
                          value: TimeFormat.h12,
                          groupValue: settings.timeFormat,
                          isDark: isDark,
                          onChanged: (v) => settings.setTimeFormat(v),
                        ),
                        _Divider(isDark: isDark),
                        _TimeFormatTile(
                          label: settings.translate(
                              'Use 24 hour format',
                              '24 گھنٹے کی شکل استعمال کریں',
                              '24 ڪلاڪ جي شڪل استعمال ڪريو',
                              'استخدام صيغة 24 ساعة'),
                          subtitle: '13:00',
                          value: TimeFormat.h24,
                          groupValue: settings.timeFormat,
                          isDark: isDark,
                          isLast: true,
                          onChanged: (v) => settings.setTimeFormat(v),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section label ──────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SectionLabel(this.text, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: isDark ? Colors.white30 : Colors.black38,
        ),
      ),
    );
  }
}

// ── Single radio option tile ───────────────────────────────────────
class _TimeFormatTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final TimeFormat value;
  final TimeFormat groupValue;
  final bool isDark;
  final bool isFirst;
  final bool isLast;
  final ValueChanged<TimeFormat> onChanged;

  const _TimeFormatTile({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.isDark,
    required this.onChanged,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(12) : Radius.zero,
        bottom: isLast ? const Radius.circular(12) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected
                          ? AppTheme.accent
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppTheme.accent
                      : (isDark ? Colors.white30 : Colors.black26),
                  width: selected ? 6 : 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Thin divider inside card ───────────────────────────────────────
class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 16,
      endIndent: 16,
      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
    );
  }
}
