import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';

class AutoSilentSettingsScreen extends StatefulWidget {
  const AutoSilentSettingsScreen({super.key});

  @override
  State<AutoSilentSettingsScreen> createState() => _AutoSilentSettingsScreenState();
}

class _AutoSilentSettingsScreenState extends State<AutoSilentSettingsScreen> {
  static const _nativeChannel = MethodChannel('pk.sukkur.salah/native_helper');

  Future<void> _checkAndRequestDndPermission(SettingsProvider settings) async {
    try {
      final bool hasPermission = await _nativeChannel.invokeMethod<bool>('checkDndPermission') ?? false;
      if (!hasPermission && mounted) {
        _showDndPermissionDialog(context);
      }
    } catch (e) {
      debugPrint('Error checking DND permission: $e');
    }
  }

  void _showDndPermissionDialog(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: settings.displayThemeBg(Theme.of(context).brightness == Brightness.dark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          settings.translate('Permission Required', 'اجازت درکار ہے', 'اجازت گهربل آهي', 'مطلوبة إذن'),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          settings.translate(
            'To set the phone to Silent mode automatically, this app needs "Do Not Disturb" (Notification Policy Access) permission. Please grant it in the next settings screen.',
            'فون کو خود بخود سائلنٹ موڈ پر سیٹ کرنے کے لیے، اس ایپ کو "ڈسٹرب نہ کریں" (نوٹیفکیشن پالیسی تک رسائی) کی اجازت درکار ہے۔ براہ کرم اگلی سیٹنگز اسکرین پر اس کی اجازت دیں۔',
            'فون کي خود بخود سائلنٽ موڊ تي سيٽ ڪرڻ لاءِ، هن ايپ کي "ڊسٽرب نه ڪريو" (نوٽيفڪيشن پاليسي تائين رسائي) جي اجازت گهربل آهي. مهرباني ڪري ايندڙ سيٽنگز اسڪرين تي ان جي اجازت ڏيو.',
            'لضبط الهاتف على الوضع الصامت تلقائياً، يحتاج هذا التطبيق إلى إذن "عدم الإزعاج" (وصول سياسة الإشعارات). يُرجى منحه في شاشة الضبط التالية.',
          ),
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              settings.setAutoSilentMode('vibrate'); // Revert to vibrate fallback
            },
            child: Text(
              settings.translate('Use Vibrate Instead', 'وائبریشن استعمال کریں', 'وائبريشن استعمال ڪريو', 'استخدام الاهتزاز بدلاً'),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await _nativeChannel.invokeMethod('openDndSettings');
            },
            child: Text(settings.translate('Open Settings', 'سیٹنگز کھولیں', 'سيٽنگون کوليو', 'فتح الضبط')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = settings.isRtl;

    // Sunrise is never included here - it is not a prayer. A calculated world
    // city also drops Misl Awwal, which is jantri-only.
    final prayers = settings.locationMode == LocationMode.sukkur
        ? ['Fajar', 'Zuhar', 'Misl Awwal', 'Asr Hanafi', 'Maghrib', 'Isha']
        : ['Fajar', 'Zuhar', 'Asr Hanafi', 'Maghrib', 'Isha'];
    final prayerDisplayNames = {
      'Fajar': settings.translate('Fajar', 'فجر', 'فجر', 'الفجر'),
      'Zuhar': settings.translate('Zuhar', 'ظہر', 'ظھر', 'الظهر'),
      'Misl Awwal': settings.translate('Misl Awwal', 'مثل اول', 'مثل اول', 'المثل الأول'),
      // A calculated city has plain "Asr", not the jantri's "Asr Hanafi".
      'Asr Hanafi': settings.locationMode == LocationMode.sukkur
          ? settings.translate('Asr', 'عصر حنفی', 'عصر', 'العصر')
          : settings.translate('Asr', 'عصر', 'عصر', 'العصر'),
      'Maghrib': settings.translate('Maghrib', 'مغرب', 'مغرب', 'المغرب'),
      'Isha': settings.translate('Isha', 'عشاء', 'عشاء', 'العشاء'),
    };

    final prayerIcons = {
      'Fajar': Icons.star_half_rounded,
      'Zuhar': Icons.wb_sunny_rounded,
      'Misl Awwal': Icons.light_mode_outlined,
      'Asr Hanafi': Icons.light_mode_rounded,
      'Maghrib': Icons.nights_stay_outlined,
      'Isha': Icons.nightlight_round,
    };

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: settings.displayThemeBg(isDark),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            settings.translate('Auto-Silent (Jama\'at)', 'جماعت کے اوقات میں سائلنٹ', 'جماعت جي وقتن تي سائلنٽ', 'الصمت التلقائي (الجماعة)'),
            style: TextStyle(
              fontSize: settings.isRtl ? 22 : 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Enable Feature Switch Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: settings.displayThemeCard(isDark),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: settings.displayThemeCardBorder(isDark)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.notifications_paused_rounded, color: AppTheme.accent, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              settings.translate('Automatic Silencer', 'خودکار سائلنٹ موڈ', 'خودڪار سائلنٽ موڊ', 'الصمت التلقائي'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              settings.translate(
                                'Mute device automatically during congregation',
                                'باجماعت نماز کے دوران فون کو خاموش کریں',
                                'باجماعت نماز دوران فون کي سائلنٽ ڪريو',
                                'كتم الجهاز تلقائياً أثناء صلاة الجماعة',
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: settings.autoSilentEnabled,
                        activeColor: AppTheme.accent,
                        onChanged: (val) {
                          settings.setAutoSilentEnabled(val);
                          if (val && settings.autoSilentMode == 'silent') {
                            _checkAndRequestDndPermission(settings);
                          }
                        },
                      ),
                    ],
                  ),
                  if (settings.autoSilentEnabled) ...[
                    const Divider(height: 24),
                    // Mode Selector: Vibrate vs Silent
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          settings.translate('Mute Mode', 'سائلنٹ کا انداز', 'سائلنٽ جو طريقو', 'وضع الصمت'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Row(
                          children: [
                            ChoiceChip(
                              label: Text(settings.translate('Vibrate', 'وائبریشن', 'وائبريشن', 'اهتزاز')),
                              selected: settings.autoSilentMode == 'vibrate',
                              selectedColor: AppTheme.accent.withValues(alpha: 0.2),
                              labelStyle: TextStyle(
                                color: settings.autoSilentMode == 'vibrate' ? AppTheme.accent : (isDark ? Colors.white54 : Colors.black54),
                                fontWeight: FontWeight.w600,
                              ),
                              onSelected: (selected) {
                                if (selected) settings.setAutoSilentMode('vibrate');
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: Text(settings.translate('Silent', 'سائلنٹ', 'سائلنٽ', 'صامت')),
                              selected: settings.autoSilentMode == 'silent',
                              selectedColor: AppTheme.accent.withValues(alpha: 0.2),
                              labelStyle: TextStyle(
                                color: settings.autoSilentMode == 'silent' ? AppTheme.accent : (isDark ? Colors.white54 : Colors.black54),
                                fontWeight: FontWeight.w600,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  settings.setAutoSilentMode('silent');
                                  _checkAndRequestDndPermission(settings);
                                }
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (!settings.autoSilentEnabled) ...[
              const SizedBox(height: 16),
              // ── Custom Silent Window Card ─────────────
              _buildCustomSilentCard(context, settings, isDark, isRtl),
            ],

            if (settings.autoSilentEnabled) ...[
              const SizedBox(height: 20),
              // Section Title
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
                child: Text(
                  settings.translate('PRAYER TIMINGS CUSTOMIZATION', 'نمازوں کی تخصیص', 'نمازن جي تخصيص', 'تخصيص أوقات الصلاة').toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: isDark ? Colors.white30 : Colors.black38,
                  ),
                ),
              ),

              // Loop through all prayers
              ...prayers.map((prayer) {
                final offset = settings.getAutoSilentOffset(prayer);
                final duration = settings.getAutoSilentDuration(prayer);
                final displayName = prayerDisplayNames[prayer]!;
                final icon = prayerIcons[prayer]!;
                final isPrayerEnabled = settings.isAutoSilentPrayerEnabled(prayer);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: settings.displayThemeCard(isDark),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: settings.displayThemeCardBorder(isDark)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon, color: AppTheme.accent, size: 22),
                          const SizedBox(width: 12),
                          Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          Switch(
                            value: isPrayerEnabled,
                            activeColor: AppTheme.accent,
                            onChanged: (val) {
                              settings.setAutoSilentPrayerEnabled(prayer, val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Controls row: Offset and Duration
                      Opacity(
                        opacity: isPrayerEnabled ? 1.0 : 0.4,
                        child: AbsorbPointer(
                          absorbing: !isPrayerEnabled,
                          child: Row(
                            children: [
                              // Offset adjuster
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      settings.translate('Start after Azan', 'اذان کے کتنی دیر بعد', 'اذان کان ڪيتري دير بعد', 'البدء بعد الأذان'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.white38 : Colors.black45,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        _buildAdjustBtn(Icons.remove, () {
                                          if (offset > 0) settings.setAutoSilentOffset(prayer, offset - 1);
                                        }, isDark),
                                        Container(
                                          width: 48,
                                          alignment: Alignment.center,
                                          child: Text(
                                            settings.translate('$offset min', '$offset منٹ', '$offset منٽ', '$offset د'),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                        ),
                                        _buildAdjustBtn(Icons.add, () {
                                          if (offset < 60) settings.setAutoSilentOffset(prayer, offset + 1);
                                        }, isDark),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Duration adjuster
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      settings.translate('Silence Duration', 'خاموشی کا دورانیہ', 'خاموشي جو دورانيو', 'مدة الصمت'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.white38 : Colors.black45,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        _buildAdjustBtn(Icons.remove, () {
                                          if (duration > 5) settings.setAutoSilentDuration(prayer, duration - 1);
                                        }, isDark),
                                        Container(
                                          width: 48,
                                          alignment: Alignment.center,
                                          child: Text(
                                            settings.translate('$duration min', '$duration منٹ', '$duration منٽ', '$duration د'),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                        ),
                                        _buildAdjustBtn(Icons.add, () {
                                          if (duration < 120) settings.setAutoSilentDuration(prayer, duration + 1);
                                        }, isDark),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustBtn(IconData icon, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.accent.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.accent, size: 18),
      ),
    );
  }

  Widget _buildCustomSilentCard(
    BuildContext context,
    SettingsProvider settings,
    bool isDark,
    bool isRtl,
  ) {
    final startTod = TimeOfDay(
      hour: settings.customSilentStartHour,
      minute: settings.customSilentStartMinute,
    );
    final endTod = TimeOfDay(
      hour: settings.customSilentEndHour,
      minute: settings.customSilentEndMinute,
    );

    int durationMins = (endTod.hour * 60 + endTod.minute) - (startTod.hour * 60 + startTod.minute);
    if (durationMins <= 0) {
      durationMins += 24 * 60; // crosses midnight
    }

    final durationHours = durationMins ~/ 60;
    final durationRemainingMins = durationMins % 60;
    final hrLabel = settings.translate('hr', 'گھنٹہ', 'ڪلاڪ', 'ساعة');
    final minLabel = settings.translate('min', 'منٹ', 'منٽ', 'دقيقة');
    final durationStr = durationHours > 0
        ? (durationRemainingMins > 0 ? '$durationHours $hrLabel $durationRemainingMins $minLabel' : '$durationHours $hrLabel')
        : '$durationMins $minLabel';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2628) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: settings.customSilentEnabled
              ? (isDark
                  ? const Color(0xFF81C784).withValues(alpha: 0.5)
                  : const Color(0xFF2E7D32).withValues(alpha: 0.35))
              : (isDark ? Colors.white10 : Colors.black12),
          width: settings.customSilentEnabled ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with Switch
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: settings.customSilentEnabled
                        ? const Color(0xFF1B4332).withValues(alpha: isDark ? 0.4 : 0.12)
                        : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.more_time_rounded,
                    size: 20,
                    color: settings.customSilentEnabled
                        ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
                        : (isDark ? Colors.white38 : Colors.black38),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.translate(
                          'Custom Silent Window',
                          'کسٹم سائلنٹ دورانیہ',
                          'ڪسٽم سائلنٽ دورانيو',
                          'فترة الصامت المخصصة',
                        ),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        settings.translate(
                          'Mute phone during custom hours & minutes',
                          'مخصوص گھنٹوں اور منٹوں کے دوران فون کو خودکار سائلنٹ کریں',
                          'مخصوص ڪلاڪن ۽ منٽن دوران فون کي پاڻمرادو سائلنٽ ڪريو',
                          'كتم الهاتف خلال الساعات والدقائق المحددة',
                        ),
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: settings.customSilentEnabled,
                  activeColor: AppTheme.accent,
                  onChanged: (val) {
                    if (val && settings.autoSilentMode == 'silent') {
                      _checkAndRequestDndPermission(settings);
                    }
                    settings.setCustomSilentEnabled(val);
                  },
                ),
              ],
            ),
          ),

          if (settings.customSilentEnabled) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // From (Start Time)
                      Expanded(
                        child: _buildTimePickerTile(
                          context: context,
                          label: settings.translate('From (Start)', 'آغاز (شروع)', 'آغاز (شروع)', 'من (البدء)'),
                          timeOfDay: startTod,
                          isDark: isDark,
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: startTod,
                              helpText: settings.translate('Select Start Time', 'آغاز کا وقت منتخب کریں', 'شروعات جو وقت چونڊيو', 'حدد وقت البدء'),
                            );
                            if (picked != null) {
                              settings.setCustomSilentTimes(
                                startHour: picked.hour,
                                startMinute: picked.minute,
                                endHour: settings.customSilentEndHour,
                                endMinute: settings.customSilentEndMinute,
                              );
                            }
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(
                          isRtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
                          color: isDark ? Colors.white38 : Colors.black26,
                          size: 20,
                        ),
                      ),
                      // To (End Time)
                      Expanded(
                        child: _buildTimePickerTile(
                          context: context,
                          label: settings.translate('To (End)', 'اختتام (ختم)', 'پڄاڻي (ختم)', 'إلى (الانتهاء)'),
                          timeOfDay: endTod,
                          isDark: isDark,
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: endTod,
                              helpText: settings.translate('Select End Time', 'اختتام کا وقت منتخب کریں', 'پڄاڻي جو وقت چونڊيو', 'حدد وقت الانتهاء'),
                            );
                            if (picked != null) {
                              settings.setCustomSilentTimes(
                                startHour: settings.customSilentStartHour,
                                startMinute: settings.customSilentStartMinute,
                                endHour: picked.hour,
                                endMinute: picked.minute,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Calculated duration badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1B4332).withValues(alpha: 0.25)
                          : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF2E7D32).withValues(alpha: 0.4)
                            : const Color(0xFF1B4332).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 6),
                        Text(
                          '${settings.translate('Duration', 'دورانیہ', 'دورانيو', 'المدة')}: $durationStr',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B4332),
                            fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimePickerTile({
    required BuildContext context,
    required String label,
    required TimeOfDay timeOfDay,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final period = timeOfDay.period == DayPeriod.am ? 'AM' : 'PM';
    int hour12 = timeOfDay.hourOfPeriod;
    if (hour12 == 0) hour12 = 12;
    final timeStr = '${hour12.toString().padLeft(2, '0')}:${timeOfDay.minute.toString().padLeft(2, '0')} $period';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151C1E) : const Color(0xFFF8FAF9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12,
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B4332),
                ),
                const SizedBox(width: 6),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    '\u200E$timeStr\u200E',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
