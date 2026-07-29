import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/azan_preview_sheet.dart';
import 'clock_style_screen.dart';
import 'date_time_settings_screen.dart';
import 'auto_silent_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
                    settings.translate('Settings', 'ترتیبات', 'سيٽنگون', 'الضبط'),
                    style: TextStyle(
                      fontSize: isRtl ? 28 : 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable content ────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 8),

                  // ── Date & Time ─────────────────────────────────────
                  _SectionLabel(
                      settings.translate('Date & Time', 'تاریخ اور وقت', 'تاريخ ۽ وقت', 'التاريخ والوقت'),
                      isDark),
                  _NavTile(
                    icon: Icons.access_time_rounded,
                    label: settings.translate(
                        'Date & Time Settings', 'تاریخ اور وقت کی ترتیبات', 'تاريخ ۽ وقت جون سيٽنگون', 'إعدادات التاريخ والوقت'),
                    subtitle: _timeFormatLabel(settings.timeFormat, settings),
                    isDark: isDark,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DateTimeSettingsScreen()),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Display Customization ────────────────────────────
                  _SectionLabel(settings.translate('Display', 'ڈسپلے', 'ڊسپلي', 'العرض'), isDark),
                  _NavTile(
                    icon: Icons.palette_rounded,
                    label: settings.translate(
                        'Display Customization', 'ڈسپلے کی تخصیص', 'ڊسپلي جي تخصيص', 'تخصيص العرض'),
                    subtitle: settings.translate(
                        'Choose display theme and clock style',
                        'تھیم اور گھڑی کا انداز منتخب کریں',
                        'ٿيم ۽ گهڙيال جو انداز چونڊيو',
                        'اختر الثيم وأسلوب الساعة'),
                    isDark: isDark,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ClockStyleScreen()),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Alerts & Sound ─────────────────────────────────
                  _SectionLabel(
                      settings.translate('Alerts & Sound', 'آوازیں', 'آوازون', 'التنبيهات والأصوات'), isDark),
                  _NavTile(
                    icon: Icons.volume_up_outlined,
                    label: settings.translate(
                        'Azan Sound', 'اذان کی آوازیں', 'اذان جا آواز', 'صوت الأذان'),
                    subtitle: settings.translate(
                        'Preview Azan sound', 'آواز کا جائزہ لیں', 'آواز جو جائزو وٺو', 'معاينة صوت الأذان'),
                    isDark: isDark,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const AzanPreviewSheet(isUrdu: false),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _NavTile(
                    icon: Icons.notifications_paused_rounded,
                    label: settings.translate('Auto-Silent (Jama\'at)', 'جماعت کے اوقات میں سائلنٹ', 'جماعت جي وقتن تي سائلنٽ', 'الوضع الصامت التلقائي (الجماعة)'),
                    subtitle: settings.translate(
                      settings.autoSilentEnabled ? 'Enabled' : 'Disabled',
                      settings.autoSilentEnabled ? 'آن ہے' : 'آف ہے',
                      settings.autoSilentEnabled ? 'آن آهي' : 'آف آهي',
                      settings.autoSilentEnabled ? 'مفعل' : 'معطل',
                    ),
                    isDark: isDark,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AutoSilentSettingsScreen(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Hijri Date Adjustment ───────────────────────────
                  _SectionLabel(
                      settings.translate('Hijri Date Adjustment', 'ہجری تاریخ کی ترتیب', 'هجري تاريخ جي ترتيب', 'ضبط التاريخ الهجري'),
                      isDark),
                  _HijriExpandable(isDark: isDark),

                  const SizedBox(height: 20),

                  // ── Default Settings ────────────────────────────────
                  _SectionLabel(
                      settings.translate('Default Settings', 'پہلے جیسی ترتیبات', 'ڊفالٽ سيٽنگون', 'الضبط الافتراضي'),
                      isDark),
                  _DefaultSettingsTile(isDark: isDark),

                  // Only true in Sukkur mode - a selected world city gets its
                  // timings from calculation, not from the Jantri.
                  if (settings.locationMode == LocationMode.sukkur) ...[
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        settings.translate(
                          'All timings from the local Sukkur Jantri',
                          'تمام اوقات سکھر کی مقامی جنتری سے لیے گئے ہیں',
                          'سڀ وقت سکر جي مقامي جنتري مان ورتا ويا آهن',
                          'جميع الأوقات مأخوذة من جنتري سكر المحلية',
                        ),
                        style: TextStyle(
                          fontSize: isRtl ? 14 : 12,
                          color: isDark ? Colors.white30 : Colors.black38,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
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

// ── Hijri date adjustment expandable card ─────────────────────────
class _HijriExpandable extends StatefulWidget {
  final bool isDark;
  const _HijriExpandable({required this.isDark});

  @override
  State<_HijriExpandable> createState() => _HijriExpandableState();
}

class _HijriExpandableState extends State<_HijriExpandable> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = widget.isDark;
    final adj = settings.hijriAdjustment;
    final isRtl = settings.isRtl;

    String adjLabel() {
      if (adj == 0) return settings.translate('No adjustment', 'کوئی تبدیلی نہیں', 'ڪا تبديلي ناھي', 'لا تعديل');
      final sign = adj > 0 ? '+' : '';
      final dayWord = settings.translate(
          adj.abs() == 1 ? 'day' : 'days',
          'دن',
          'ڏينھن',
          adj.abs() == 1 ? 'يوم' : 'أيام');
      return '$sign$adj $dayWord';
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Tappable header ────────────────────────────
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.calendar_month_rounded,
                          color: AppTheme.accent, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            settings.translate(
                                'Hijri Date Adjustment', 'ہجری تاریخ کی ترتیب', 'هجري تاريخ جي ترتيب', 'ضبط التاريخ الهجري'),
                            style: TextStyle(
                              fontSize: isRtl ? 17 : 14,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            adjLabel(),
                            style: TextStyle(
                              fontSize: isRtl ? 14 : 12,
                              color: isDark ? Colors.white38 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isDark ? Colors.white38 : Colors.black38,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ── Expandable controls ────────────────────────
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 1,
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.07),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Column(
                      children: [
                        Text(
                          settings.translate(
                              'Adjust the displayed Hijri date by ±2 days',
                              'ہجری تاریخ کو ±2 دن تک ایڈجسٹ کریں',
                              'هجري تاريخ کي ±2 ڏينهن تائين ايڊجسٽ ڪريو',
                              'ضبط التاريخ الهجري المعروض ب±2 أيام'),
                          style: TextStyle(
                            fontSize: isRtl ? 14 : 12,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _AdjBtn(
                              icon: Icons.remove,
                              enabled: adj > -2,
                              onTap: () => settings.setHijriAdjustment(adj - 1),
                            ),
                            const SizedBox(width: 20),
                            Container(
                              width: 120,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.accent.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                adjLabel(),
                                style: TextStyle(
                                  fontSize: isRtl ? 16 : 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.accent,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 20),
                            _AdjBtn(
                              icon: Icons.add,
                              enabled: adj < 2,
                              onTap: () => settings.setHijriAdjustment(adj + 1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (i) {
                            final val = i - 2;
                            return GestureDetector(
                              onTap: () => settings.setHijriAdjustment(val),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                width: val == adj ? 20 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: val == adj
                                      ? AppTheme.accent
                                      : (isDark
                                          ? Colors.white24
                                          : Colors.black26),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
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
    final isRtl = context.watch<SettingsProvider>().isRtl;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: isRtl ? 14 : 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: isDark ? Colors.white30 : Colors.black38,
        ),
      ),
    );
  }
}

// ── Time format label helper ───────────────────────────────────────
String _timeFormatLabel(TimeFormat fmt, SettingsProvider settings) {
  switch (fmt) {
    case TimeFormat.h12:
      return settings.translate('12 hour (1:00 PM)', '12 گھنٹے (1:00 PM)', '12 ڪلاڪ (1:00 PM)', '12 ساعة (1:00 م)');
    case TimeFormat.h24:
      return settings.translate('24 hour (13:00)', '24 گھنٹے (13:00)', '24 ڪلاڪ (13:00)', '24 ساعة (13:00)');
    case TimeFormat.system:
      return settings.translate('Automatic', 'خودکار', 'خودڪار', 'تلقائي');
  }
}

// ── Tappable nav row (arrow right) ────────────────────────────────
class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = context.watch<SettingsProvider>().isRtl;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.accent, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: isRtl ? 17 : 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: isRtl ? 14 : 12,
                        color: isDark ? Colors.white38 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDark ? Colors.white30 : Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── +/- button ─────────────────────────────────────────────────────
class _AdjBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _AdjBtn(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.3,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.accent, size: 20),
        ),
      ),
    );
  }
}

class _DefaultSettingsTile extends StatelessWidget {
  final bool isDark;

  const _DefaultSettingsTile({required this.isDark});

  void _showResetDialog(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.settings_backup_restore_rounded,
                    color: Colors.red, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                settings.translate('Reset Settings', 'ری سیٹ ترتیبات', 'سيٽنگون ري سيٽ ڪريو', 'إعادة تعيين الضبط'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                  settings.translate(
                    'Are you sure you want to reset all settings to their default values?',
                    'کیا آپ واقعی تمام ترتیبات کو ان کی ڈیفالٹ اقدار پر واپس لانا چاہتے ہیں؟',
                    'ڇا توہان واقعي سبھ سيٽنگون انھن جي ڊفالٽ قدرن تي واپس ڪرڻن چاہيو ٿو؟',
                    'هل تريد فعلاً إعادة تعيين جميع الضبط إلى قيمها الافتراضية؟',
                  ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: Text(
                      settings.translate('Cancel', 'کینسل', 'رد ڪريو', 'إلغاء'),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(dialogCtx);
                      context.read<SettingsProvider>().resetToDefaults();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              settings.translate(
                                'Settings reset to defaults',
                                'ترتیبات کو ڈیفالٹ پر ری سیٹ کر دیا گیا ہے',
                                'سيٽنگون ڊفالٽ تي ري سيٽ ڪيون ويون',
                                'تمت إعادة تعيين الضبط إلى الافتراضية',
                              ),
                          ),
                          backgroundColor: AppTheme.accent,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Text(settings.translate('Reset', 'ری سیٹ کریں', 'ري سيٽ ڪريو', 'إعادة تعيين')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isRtl = settings.isRtl;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
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
      child: InkWell(
        onTap: () => _showResetDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.settings_backup_restore_rounded, color: Colors.red, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settings.translate(
                          'Reset to Default Settings', 'ترتیبات ری سیٹ کریں', 'سيٽنگون ري سيٽ ڪريو', 'إعادة تعيين الضبط الافتراضي'),
                      style: TextStyle(
                        fontSize: isRtl ? 17 : 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      settings.translate(
                          'Restore all settings to application defaults',
                          'تمام ترتیبات کو ایپ ڈیفالٹس پر تبدیل کریں',
                          'سڀ سيٽنگون ايپ ڊفالٽس تي بحال ڪريو',
                          'استعادة جميع الضبط إلى افتراضيات التطبيق'),
                      style: TextStyle(
                        fontSize: isRtl ? 14 : 12,
                        color: isDark ? Colors.white38 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDark ? Colors.white30 : Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
