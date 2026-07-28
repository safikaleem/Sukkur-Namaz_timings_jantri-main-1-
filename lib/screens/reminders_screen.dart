import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/app_theme.dart';
import '../widgets/dr_slogan_footer.dart';
import '../widgets/dr_slogan_header.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';

// ── Data model for a custom reminder ─────────────────────────
class Reminder {
  final String id;
  final String prayerName;      // Fajr, Dhuhr, Asr, Maghrib, Isha
  final int offsetMinutes;      // negative = before, positive = after
  final String label;
  bool enabled;

  Reminder({
    required this.id,
    required this.prayerName,
    required this.offsetMinutes,
    required this.label,
    this.enabled = true,
  });

  String description(String language) {
    final urduNames = {
      'Intiha e Sehar': 'انتہائے سحر', 'Fajar': 'فجر',
      'Tulu Aftab': 'طلوع آفتاب', 'Ishraq': 'اشراق',
      'Zawal': 'زوال آفتاب', 'Zuhar': 'ظہر', 'Misl Awwal': 'مثل اول',
      'Asr Hanafi': 'عصر حنفی', 'Maghrib': 'مغرب', 'Isha': 'عشاء',
      'Fajr': 'فجر', 'Dhuhr': 'ظہر', 'Asr': 'عصر',
    };
    final sindhiNames = {
      'Intiha e Sehar': 'انتهاءِ سحر', 'Fajar': 'فجر',
      'Tulu Aftab': 'سج اڀرڻ', 'Ishraq': 'اشراق',
      'Zawal': 'زوالِ آفتاب', 'Zuhar': 'ظھر', 'Misl Awwal': 'مثل اول',
      'Asr Hanafi': 'عصر', 'Maghrib': 'مغرب', 'Isha': 'عشاء',
      'Fajr': 'فجر', 'Dhuhr': 'ظھر', 'Asr': 'عصر',
    };

    if (language == 'sindhi') {
      final pName = sindhiNames[prayerName] ?? prayerName;
      if (offsetMinutes == 0) return '$pName جَ وقت تي';
      final abs = offsetMinutes.abs();
      final dir = offsetMinutes < 0 ? 'اڳيان' : 'پوء';
      return '$pName کان $abs منٽ $dir';
    }
    if (language == 'urdu') {
      final pName = urduNames[prayerName] ?? prayerName;
      if (offsetMinutes == 0) return '$pName کے وقت';
      final abs = offsetMinutes.abs();
      final direction = offsetMinutes < 0 ? 'پہلے' : 'بعد';
      return '$pName سے $abs منٹ $direction';
    }
    if (language == 'arabic') {
      final arabicNames = {
        'Intiha e Sehar': 'نهاية السحر', 'Fajar': 'الفجر',
        'Tulu Aftab': 'الشروق', 'Ishraq': 'الإشراق',
        'Zawal': 'الزوال', 'Zuhar': 'الظهر', 'Zuhr': 'الظهر',
        'Misl Awwal': 'المثل الأول',
        'Asr Hanafi': 'العصر', 'Maghrib': 'المغرب', 'Isha': 'العشاء',
      };
      final pName = arabicNames[prayerName] ?? prayerName;
      if (offsetMinutes == 0) return 'عند $pName';
      final abs = offsetMinutes.abs();
      final direction = offsetMinutes < 0 ? 'قبل' : 'بعد';
      return '$abs دقيقة $direction $pName';
    }
    if (offsetMinutes == 0) return 'At $prayerName time';
    final abs = offsetMinutes.abs();
    final direction = offsetMinutes < 0 ? 'before' : 'after';
    return '$abs min $direction $prayerName';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'prayerName': prayerName,
    'offsetMinutes': offsetMinutes,
    'label': label,
    'enabled': enabled,
  };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
    id: json['id'] as String,
    prayerName: json['prayerName'] as String,
    offsetMinutes: json['offsetMinutes'] as int,
    label: json['label'] as String,
    enabled: json['enabled'] as bool? ?? true,
  );
}

// ── Reminders Screen ─────────────────────────────────────────
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<Reminder> _reminders = [];
  bool _loaded = false;

  static const _storageKey = 'custom_reminders';

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _reminders = list.map((e) => Reminder.fromJson(e)).toList();
    }
    if (!mounted) return;
    setState(() => _loaded = true);
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_reminders.map((r) => r.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
    // Re-schedule so the saved reminders actually fire as notifications.
    Future.delayed(const Duration(milliseconds: 150), () async {
      await NotificationService.instance.scheduleWeeklyNotifications();
    });
  }

  void _addReminder(Reminder r) {
    setState(() => _reminders.add(r));
    _saveReminders();
  }

  void _toggleReminder(int index, bool value) {
    setState(() => _reminders[index].enabled = value);
    _saveReminders();
  }

  void _deleteReminder(String id) {
    // Delete by id, not by the captured build index — two quick swipes before a
    // rebuild could otherwise remove the wrong reminder.
    setState(() => _reminders.removeWhere((r) => r.id == id));
    _saveReminders();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    final isRtl = settings.isRtl;

    return Scaffold(
      backgroundColor: settings.displayThemeBg(isDark),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SizedBox(
                height: 36,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 42),
                    Text(
                      settings.translate('Reminders', 'اطلاعات', 'ياد دهانيون', 'تذكيرات'),
                      style: TextStyle(
                        fontSize: isRtl ? 26 : 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showAddReminderSheet(context),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.add_rounded, color: AppTheme.accent, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(child: DrSloganHeader()),
            const SizedBox(height: 12),
            Expanded(
              child: !_loaded
                  ? Center(child: CircularProgressIndicator(color: AppTheme.accent))
                  : _reminders.isEmpty
                      ? _buildEmptyState(context, settings)
                      : _buildReminderList(context, settings),
            ),
            const DrSloganFooter(),
          ],
        ),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context, SettingsProvider settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = settings.isRtl;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.alarm_add_rounded, size: 64,
                color: AppTheme.accent.withOpacity(0.25)),
            const SizedBox(height: 20),
            Text(
              settings.translate(
                'No reminders yet',
                'ابھی تک کوئی اطلاع نہیں',
                'اڳی وقت ڊڪ ياد ناهين',
                'لا توجد تذكيرات حتى الآن',
              ),
              style: TextStyle(
                fontSize: isRtl ? 21 : 17,
                color: isDark ? Colors.white54 : Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              settings.translate(
                'Tap + to add a custom reminder before or after any prayer.',
                'کسی بھی نماز سے پہلے یا بعد میں حسب ضرورت اطلاع شامل کرنے کے لیے + کو تھپتھپائیں۔',
                '+ دٻايو ته ڪنهن به نماز کان اڳيان يا پوءِ ڪسٽمائيزڊ ياد شامل ڪريو۔',
                'اضغط على + لإضافة تذكير مخصص قبل أو بعد أي صلاة.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isRtl ? 16 : 13,
                color: isDark ? Colors.white30 : Colors.black45,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Reminder list ──────────────────────────────────────────
  Widget _buildReminderList(BuildContext context, SettingsProvider settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = settings.isRtl;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _reminders.length,
      itemBuilder: (ctx, i) {
        final r = _reminders[i];
        return Dismissible(
          key: Key(r.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 24),
          ),
          onDismissed: (_) => _deleteReminder(r.id),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: r.enabled
                    ? AppTheme.accent.withOpacity(0.2)
                    : (isDark ? Colors.transparent : Colors.black.withOpacity(0.05)),
              ),
              boxShadow: isDark ? null : [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: r.enabled ? AppTheme.accent.withOpacity(0.1) : (isDark ? Colors.white12 : Colors.black.withOpacity(0.05)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.alarm_rounded,
                      color: r.enabled ? AppTheme.accent : (isDark ? Colors.white24 : Colors.black26), size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.label,
                        style: TextStyle(
                          fontSize: isRtl ? 17 : 14,
                          fontWeight: FontWeight.w600,
                          color: r.enabled ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white38 : Colors.black45),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        r.description(settings.language),
                        style: TextStyle(
                          fontSize: isRtl ? 15 : 12,
                          color: r.enabled ? (isDark ? Colors.white54 : Colors.black54) : (isDark ? Colors.white24 : Colors.black38),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: r.enabled,
                  onChanged: (v) => _toggleReminder(i, v),
                  activeColor: AppTheme.accent,
                  activeTrackColor: AppTheme.accent.withOpacity(0.3),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Add Reminder Sheet ─────────────────────────────────────
  void _showAddReminderSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.read<SettingsProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddReminderForm(onSave: _addReminder, settings: settings),
    );
  }
}

// ── Add Reminder Form ────────────────────────────────────────
class _AddReminderForm extends StatefulWidget {
  final void Function(Reminder) onSave;
  final SettingsProvider settings;
  const _AddReminderForm({required this.onSave, required this.settings});

  @override
  State<_AddReminderForm> createState() => _AddReminderFormState();
}

class _AddReminderFormState extends State<_AddReminderForm> {
  String _selectedPrayer = 'Fajar';
  String _direction = 'before';   // before | after | at
  int _minutes = 15;
  final _labelController = TextEditingController();

  static const _prayers = [
    'Intiha e Sehar',
    'Fajar',
    'Tulu Aftab',
    'Ishraq',
    'Zawal',
    'Zuhar',
    'Misl Awwal',
    'Asr Hanafi',
    'Maghrib',
    'Isha'
  ];
  static const _minuteOptions = [5, 10, 15, 20, 30, 45, 60];

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _save() {
    final settings = widget.settings;
    final language = settings.language;
    final offset = _direction == 'at' ? 0 : _direction == 'before' ? -_minutes : _minutes;

    final urduNames = {
      'Intiha e Sehar': 'انتہائے سحر', 'Fajar': 'فجر',
      'Tulu Aftab': 'طلوع آفتاب', 'Ishraq': 'اشراق',
      'Zawal': 'زوال آفتاب', 'Zuhar': 'ظہر', 'Misl Awwal': 'مثل اول',
      'Asr Hanafi': 'عصر حنفی', 'Maghrib': 'مغرب', 'Isha': 'عشاء',
    };
    final sindhiNames = {
      'Intiha e Sehar': 'انتهاءِ سحر', 'Fajar': 'فجر',
      'Tulu Aftab': 'سج اڀرڻ', 'Ishraq': 'اشراق',
      'Zawal': 'زوالِ آفتاب', 'Zuhar': 'ظھر', 'Misl Awwal': 'مثل اول',
      'Asr Hanafi': 'عصر', 'Maghrib': 'مغرب', 'Isha': 'عشاء',
    };

    String defaultLabel;
    if (language == 'sindhi') {
      final p = sindhiNames[_selectedPrayer] ?? _selectedPrayer;
      defaultLabel = _direction == 'at' ? '$p جَ وقت تي' : '$p کان $_minutes منٽ ${_direction == 'before' ? 'اڳيان' : 'پوء'}';
    } else if (language == 'urdu') {
      final p = urduNames[_selectedPrayer] ?? _selectedPrayer;
      defaultLabel = _direction == 'at' ? '$p کا وقت' : '$p سے $_minutes منٹ ${_direction == 'before' ? 'پہلے' : 'بعد'}';
    } else if (language == 'arabic') {
      final arabicNames = {
        'Intiha e Sehar': 'نهاية السحر', 'Fajar': 'الفجر',
        'Tulu Aftab': 'الشروق', 'Ishraq': 'الإشراق',
        'Zawal': 'الزوال', 'Zuhar': 'الظهر', 'Zuhr': 'الظهر',
        'Misl Awwal': 'المثل الأول',
        'Asr Hanafi': 'العصر', 'Maghrib': 'المغرب', 'Isha': 'العشاء',
      };
      final p = arabicNames[_selectedPrayer] ?? _selectedPrayer;
      defaultLabel = _direction == 'at' ? 'عند $p' : '$_minutes دقيقة ${_direction == 'before' ? 'قبل' : 'بعد'} $p';
    } else {
      defaultLabel = '${_direction == 'at' ? 'At' : '$_minutes min $_direction'} $_selectedPrayer';
    }

    final label = _labelController.text.trim().isEmpty ? defaultLabel : _labelController.text.trim();
    widget.onSave(Reminder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      prayerName: _selectedPrayer,
      offsetMinutes: offset,
      label: label,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = widget.settings;
    final isRtl = settings.isRtl;
    final isSindhi = settings.isSindhi;

    final urduNames = {
      'Intiha e Sehar': 'انتہائے سحر', 'Fajar': 'فجر', 'Tulu Aftab': 'طلوع آفتاب',
      'Ishraq': 'اشراق', 'Zawal': 'زوال آفتاب', 'Zuhar': 'ظہر',
      'Misl Awwal': 'مثل اول', 'Asr Hanafi': 'عصر حنفی', 'Maghrib': 'مغرب', 'Isha': 'عشاء',
    };
    final sindhiNames = {
      'Intiha e Sehar': 'انتهاءِ سحر', 'Fajar': 'فجر', 'Tulu Aftab': 'سج اڀرڻ',
      'Ishraq': 'اشراق', 'Zawal': 'زوالِ آفتاب', 'Zuhar': 'ظھر',
      'Misl Awwal': 'مثل اول', 'Asr Hanafi': 'عصر', 'Maghrib': 'مغرب', 'Isha': 'عشاء',
    };
    final arabicNames = {
      'Intiha e Sehar': 'نهاية السحر', 'Fajar': 'الفجر', 'Tulu Aftab': 'الشروق',
      'Ishraq': 'الإشراق', 'Zawal': 'الزوال', 'Zuhar': 'الظهر',
      'Misl Awwal': 'المثل الأول', 'Asr Hanafi': 'العصر', 'Maghrib': 'المغرب', 'Isha': 'العشاء',
    };

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              settings.translate('New Reminder', 'نئی اطلاع', 'نئين ياد', 'تذكير جديد'),
              style: TextStyle(fontSize: isRtl ? 24 : 20, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 20),

            _sectionLabel(settings.translate('Prayer', 'نماز', 'نماز', 'الصلاة'), isDark),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _prayers.map((p) {
                final isSelected = p == _selectedPrayer;
                final displayName = settings.language == 'arabic' ? (arabicNames[p] ?? p)
                    : isSindhi ? (sindhiNames[p] ?? p)
                    : (isRtl ? (urduNames[p] ?? p) : p);
                return GestureDetector(
                  onTap: () => setState(() => _selectedPrayer = p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.accent.withOpacity(0.2)
                          : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppTheme.accent : (isDark ? Colors.white12 : Colors.black12),
                      ),
                    ),
                    child: Text(displayName, style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: isSelected ? AppTheme.accent : (isDark ? Colors.white54 : Colors.black54),
                    )),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),
            _sectionLabel(settings.translate('When', 'کب', 'ڪدھن', 'متى'), isDark),
            const SizedBox(height: 8),
            Row(
              children: ['before', 'at', 'after'].map((d) {
                final isSelected = d == _direction;
                final lbl = d == 'at'
                    ? settings.translate('At prayer time', 'وقت پر', 'وقت تي', 'في وقت الصلاة')
                    : (d == 'before'
                        ? settings.translate('Before', 'پہلے', 'اڳيان', 'قبل')
                        : settings.translate('After', 'بعد میں', 'پوء', 'بعد'));
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _direction = d),
                    child: Container(
                      margin: EdgeInsets.only(right: d != 'after' ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.accent.withOpacity(0.2)
                            : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppTheme.accent : (isDark ? Colors.white12 : Colors.black12),
                        ),
                      ),
                      child: Text(lbl, style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: isSelected ? AppTheme.accent : (isDark ? Colors.white54 : Colors.black54),
                      )),
                    ),
                  ),
                );
              }).toList(),
            ),

            if (_direction != 'at') ...[
              const SizedBox(height: 20),
              _sectionLabel(settings.translate('Minutes', 'منٹس', 'منٽ', 'دقائق'), isDark),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _minuteOptions.map((m) {
                  final isSelected = m == _minutes;
                  return GestureDetector(
                    onTap: () => setState(() => _minutes = m),
                    child: Container(
                      width: 52,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.accent.withOpacity(0.2)
                            : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppTheme.accent : (isDark ? Colors.white12 : Colors.black12),
                        ),
                      ),
                      child: Text('$m', style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: isSelected ? AppTheme.accent : (isDark ? Colors.white54 : Colors.black54),
                      )),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 20),
            _sectionLabel(settings.translate('Label (optional)', 'لیبل (اختیاری)', 'ليبل (اختياري)', 'العنوان (اختياري)'), isDark),
            const SizedBox(height: 8),
            TextField(
              controller: _labelController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
              decoration: InputDecoration(
                hintText: settings.translate(
                  'e.g. Prepare for Fajr',
                  'مثال کے طور پر: فجر کی تیاری کریں',
                  'مثلاڹ: فجر لاءِ تياري ڪريو',
                  'على سبيل المثال: استعد للفجر',
                ),
                hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black38, fontSize: 14),
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppTheme.accent)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  settings.translate('Save Reminder', 'اطلاع محفوظ کریں', 'ياد محفوظ ڪريو', 'حفظ التذكير'),
                  style: TextStyle(fontSize: isRtl ? 18 : 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, bool isDark) {
    final isRtl = widget.settings.isRtl;
    return Text(
      text,
      style: TextStyle(
        fontSize: isRtl ? 14 : 12,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white38 : Colors.black45,
        letterSpacing: 0.5,
      ),
    );
  }
}
