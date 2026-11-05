import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart';

import '../providers/settings_provider.dart';
import '../services/developer_gist_service.dart';
import '../services/jamaat_times_service.dart';
import '../services/notification_health.dart';
import '../services/notification_service.dart';
import '../utils/app_theme.dart';
import 'developer_add_masjid_screen.dart';
import 'developer_gist_manager_screen.dart';
import 'developer_timings_log_screen.dart';

/// Unified Developer & Master Admin Dashboard (Control Center)
/// Accessible exclusively with Master PIN: 25081989.
class DeveloperDashboardScreen extends StatefulWidget {
  const DeveloperDashboardScreen({super.key});

  @override
  State<DeveloperDashboardScreen> createState() => _DeveloperDashboardScreenState();
}

class _DeveloperDashboardScreenState extends State<DeveloperDashboardScreen> {
  bool _isSyncing = false;
  String? _gistToken;
  bool _obscureMasterPin = true;

  // Diagnostics & Health State
  NotificationHealth? _healthStatus;
  bool _isLoadingHealth = false;
  bool? _hasCompassSensor;
  bool? _isGpsEnabled;
  LocationPermission? _locationPermission;

  final Map<String, int> _monthMap = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  @override
  void initState() {
    super.initState();
    _loadDeveloperStatus();
    _loadDiagnostics();
  }

  Future<void> _loadDeveloperStatus() async {
    final token = await DeveloperGistService.instance.getGistToken();
    if (mounted) {
      setState(() {
        _gistToken = token;
      });
    }
  }

  Future<void> _loadDiagnostics() async {
    setState(() => _isLoadingHealth = true);
    try {
      final health = await NotificationHealth.check();
      bool? hasSensor;
      try {
        hasSensor = await FlutterQiblah.androidDeviceSensorSupport();
      } catch (_) {}

      bool? gpsEnabled;
      LocationPermission? locPerm;
      try {
        gpsEnabled = await Geolocator.isLocationServiceEnabled();
        locPerm = await Geolocator.checkPermission();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _healthStatus = health;
          _hasCompassSensor = hasSensor;
          _isGpsEnabled = gpsEnabled;
          _locationPermission = locPerm;
          _isLoadingHealth = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingHealth = false);
    }
  }

  DateTime? _parseDate(String dateStr) {
    try {
      final clean = dateStr.trim();
      if (clean.isEmpty) return null;
      final parts = clean.split(RegExp(r'\s+'));
      if (parts.length >= 3) {
        final day = int.tryParse(parts[0]);
        final monthStr = parts[1].toLowerCase().substring(0, 3);
        final month = _monthMap[monthStr];
        final year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          return DateTime(year, month, day);
        }
      }
    } catch (_) {}
    return null;
  }

  DateTime? _getLatestUpdateDate(JamaatTiming timing) {
    DateTime? latest;
    final dates = [
      _parseDate(timing.fajrUpdated),
      _parseDate(timing.zuharUpdated),
      _parseDate(timing.asarUpdated),
      _parseDate(timing.ishaUpdated),
      _parseDate(timing.jummahUpdated),
    ];
    for (final d in dates) {
      if (d != null) {
        if (latest == null || d.isAfter(latest)) {
          latest = d;
        }
      }
    }
    return latest;
  }

  Future<void> _triggerCloudSync() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final bool useUrdu = ['urdu', 'sindhi', 'arabic', 'persian'].contains(settings.language);
    String t(String en, String ur) => useUrdu ? ur : en;
    final urduFont = useUrdu ? AppTheme.getFontForLanguage(context, 'urdu') : null;

    setState(() => _isSyncing = true);
    final success = await JamaatTimesService.instance.fetchRemoteGistTimings(force: true);
    await _loadDeveloperStatus();
    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? t('Cloud Firestore & GitHub Gist synced successfully!', 'کلاؤڈ فائر اسٹور اور گٹ ہب گسٹ کامیابی سے سنک ہو گئے!')
                : t('Could not reach server. Showing local database cache.', 'سرور سے رابطہ نہ ہو سکا۔ مقامی ڈیٹا دکھایا جا رہا ہے۔'),
            style: TextStyle(fontFamily: urduFont),
          ),
          backgroundColor: success ? const Color(0xFF1B4332) : const Color(0xFFB00020),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showGistTokenDialog() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final bool useUrdu = ['urdu', 'sindhi', 'arabic', 'persian'].contains(settings.language);
    String t(String en, String ur) => useUrdu ? ur : en;
    final urduFont = useUrdu ? AppTheme.getFontForLanguage(context, 'urdu') : null;

    final controller = TextEditingController(text: _gistToken ?? '');
    bool obscure = true;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.key_rounded, color: Color(0xFF1B4332)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t('GitHub PAT Token', 'گٹ ہب پرسنل ایکسس ٹوکن'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: urduFont),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t(
                  'Personal Access Token (classic) with "gist" scope to authorize remote sync:',
                  'ریموٹ سنک کی اجازت کے لیے "gist" اسکوپ والا پرسنل ایکسس ٹوکن درج کریں:',
                ),
                style: TextStyle(fontSize: 12, fontFamily: urduFont),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                obscureText: obscure,
                decoration: InputDecoration(
                  hintText: 'ghp_xxxxxxxxxxxx',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 20),
                    onPressed: () => setDialogState(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(t('Cancel', 'منسوخ'), style: TextStyle(fontFamily: urduFont)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4332),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final val = controller.text.trim();
                await DeveloperGistService.instance.saveGistToken(val);
                if (!dialogCtx.mounted) return;
                Navigator.pop(dialogCtx);
                if (!mounted) return;
                setState(() => _gistToken = val.isEmpty ? null : val);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      t('GitHub token saved successfully!', 'گٹ ہب ٹوکن کامیابی سے محفوظ ہو گیا!'),
                      style: TextStyle(fontFamily: urduFont),
                    ),
                    backgroundColor: const Color(0xFF1B4332),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Text(t('Save Token', 'ٹوکن محفوظ کریں'), style: TextStyle(fontFamily: urduFont)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangeMasterPinDialog() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final bool useUrdu = ['urdu', 'sindhi', 'arabic', 'persian'].contains(settings.language);
    String t(String en, String ur) => useUrdu ? ur : en;
    final urduFont = useUrdu ? AppTheme.getFontForLanguage(context, 'urdu') : null;

    final currentMaster = JamaatTimesService.instance.masterAdminPin;
    final pinController = TextEditingController(text: currentMaster);
    final confirmController = TextEditingController();
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E282A) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.password_rounded, color: Color(0xFFD97706), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t('Change Master PIN', 'ماسٹر پن تبدیل کریں'),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: urduFont),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t(
                        'Set a new master PIN to protect developer settings and unlock any masjid:',
                        'ڈویلپر سیٹنگز کے تحفظ اور تمام مساجد تک رسائی کے لیے نیا ماسٹر پن مقرر کریں:',
                      ),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontFamily: urduFont,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: pinController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: t('New Master PIN', 'نیا ماسٹر پن'),
                        hintText: t('e.g. 25081989', 'مثلاً 25081989'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: t('Confirm New Master PIN', 'نئے ماسٹر پن کی تصدیق'),
                        hintText: t('Re-enter PIN', 'پن دوبارہ درج کریں'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: Text(t('Cancel', 'منسوخ'), style: TextStyle(fontFamily: urduFont)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4332),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newPin = pinController.text.trim();
                          final confirmPin = confirmController.text.trim();

                          if (newPin.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  t('PIN cannot be empty.', 'پن خالی نہیں ہو سکتا۔'),
                                  style: TextStyle(fontFamily: urduFont),
                                ),
                              ),
                            );
                            return;
                          }
                          if (newPin != confirmPin) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  t('PINs do not match.', 'دونوں پن مماثل نہیں ہیں۔'),
                                  style: TextStyle(fontFamily: urduFont),
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          final res = await JamaatTimesService.instance.updateMasterPin(newPin);
                          setDialogState(() => isSaving = false);

                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);

                          if (!mounted) return;
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res.message, style: TextStyle(fontFamily: urduFont)),
                              backgroundColor: res.success ? const Color(0xFF1B4332) : const Color(0xFFB00020),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(t('Save PIN', 'پن محفوظ کریں'), style: TextStyle(fontFamily: urduFont)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _exportNetworkReport() async {
    final allMasajid = JamaatTimesService.instance.getMasjidList(includeHidden: true);
    final now = DateTime.now();
    final dayStr = now.day.toString().padLeft(2, '0');
    final monthKeys = _monthMap.keys.toList();
    final monthStr = monthKeys.firstWhere((k) => _monthMap[k] == now.month).toUpperCase();
    final dateFormatted = '$dayStr $monthStr ${now.year}';

    final buffer = StringBuffer();
    buffer.writeln('🕌 *Sukkur Salah - Complete Masajid Timings Report*');
    buffer.writeln('📅 Generated: $dateFormatted');
    buffer.writeln('📊 Total Network Mosques: ${allMasajid.length}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━');

    int counter = 1;
    for (final m in allMasajid) {
      final timing = JamaatTimesService.instance.getTimingFor(m);
      buffer.writeln('$counter. *${m.nameKey}* (${m.addressKey})');
      buffer.writeln('   • Fajr: ${timing.fajr}');
      buffer.writeln('   • Zuhar: ${timing.zuhar}');
      buffer.writeln('   • Asar: ${timing.asar}');
      buffer.writeln('   • Isha: ${timing.isha}');
      buffer.writeln('   • Jummah: ${timing.jummah}');
      if (m.isHidden) {
        buffer.writeln('   ⚠️ Status: Hidden in User App');
      }
      buffer.writeln();
      counter++;
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('Generated via Sukkur Salah Developer Control Center');

    final text = buffer.toString();
    try {
      await Share.share(text, subject: 'Sukkur Salah - Masajid Timings Report ($dateFormatted)');
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        final bool useUrdu = ['urdu', 'sindhi', 'arabic', 'persian'].contains(settings.language);
        final urduFont = useUrdu ? AppTheme.getFontForLanguage(context, 'urdu') : null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              useUrdu ? 'مکمل نیٹ ورک رپورٹ کلپ بورڈ پر کاپی ہو گئی!' : 'Full network report copied to clipboard!',
              style: TextStyle(fontFamily: urduFont),
            ),
            backgroundColor: const Color(0xFF1B4332),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _copyRawJson() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final bool useUrdu = ['urdu', 'sindhi', 'arabic', 'persian'].contains(settings.language);
    final urduFont = useUrdu ? AppTheme.getFontForLanguage(context, 'urdu') : null;

    final jsonStr = JamaatTimesService.instance.exportRawGistJson();
    await Clipboard.setData(ClipboardData(text: jsonStr));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            useUrdu
                ? 'مکمل Gist JSON کلپ بورڈ پر کاپی ہو گیا! گٹ ہب پر پیسٹ کریں۔'
                : 'Complete Gist JSON copied to clipboard! Ready to paste into GitHub.',
            style: TextStyle(fontFamily: urduFont),
          ),
          backgroundColor: const Color(0xFF1B4332),
          action: SnackBarAction(
            label: useUrdu ? 'شیئر' : 'Share',
            textColor: Colors.white,
            onPressed: () {
              Share.share(jsonStr, subject: 'masajid_timings.json');
            },
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _confirmClearCache() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final bool useUrdu = ['urdu', 'sindhi', 'arabic', 'persian'].contains(settings.language);
    String t(String en, String ur) => useUrdu ? ur : en;
    final urduFont = useUrdu ? AppTheme.getFontForLanguage(context, 'urdu') : null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.cleaning_services_rounded, color: Color(0xFFE53935)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t('Clear Cache & Re-Sync?', 'کیشے صاف کریں اور دوبارہ سنک کریں؟'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: urduFont),
              ),
            ),
          ],
        ),
        content: Text(
          t(
            'This will wipe locally stored mosque timings and re-download fresh data from Firestore & GitHub Gist.',
            'یہ مقامی طور پر محفوظ شدہ اوقات کو صاف کر کے فائر اسٹور اور گٹ ہب سے تازہ ڈیٹا ڈاؤن لوڈ کرے گا۔',
          ),
          style: TextStyle(fontSize: 13, fontFamily: urduFont),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('Cancel', 'منسوخ'), style: TextStyle(fontFamily: urduFont)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t('Clear & Re-Sync', 'صاف کریں اور سنک کریں'), style: TextStyle(fontFamily: urduFont)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isSyncing = true);
      await JamaatTimesService.instance.clearCacheAndReload();
      await _loadDiagnostics();
      if (mounted) {
        setState(() => _isSyncing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t('Local cache cleared and fresh timings loaded!', 'مقامی کیشے صاف ہو گیا اور تازہ اوقات لوڈ ہو گئے!'),
              style: TextStyle(fontFamily: urduFont),
            ),
            backgroundColor: const Color(0xFF1B4332),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _testAdhanNotification() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final bool useUrdu = ['urdu', 'sindhi', 'arabic', 'persian'].contains(settings.language);
    final urduFont = useUrdu ? AppTheme.getFontForLanguage(context, 'urdu') : null;

    try {
      await NotificationService.instance.showTestNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              useUrdu
                  ? 'ٹیسٹ اذان اور نوٹیفکیشن بھیج دیا گیا! نوٹیفکیشن ٹرے اور آواز چیک کریں۔'
                  : 'Test Adhan notification triggered! Check your notification tray and sound.',
              style: TextStyle(fontFamily: urduFont),
            ),
            backgroundColor: const Color(0xFF1B4332),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              useUrdu ? 'خرابی: $e' : 'Error triggering test: $e',
              style: TextStyle(fontFamily: urduFont),
            ),
            backgroundColor: const Color(0xFFB00020),
          ),
        );
      }
    }
  }

  Future<void> _showScheduledAlarmsDialog() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final bool useUrdu = ['urdu', 'sindhi', 'arabic', 'persian'].contains(settings.language);
    String t(String en, String ur) => useUrdu ? ur : en;
    final urduFont = useUrdu ? AppTheme.getFontForLanguage(context, 'urdu') : null;

    final list = await NotificationService.instance.pendingNotifications();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF182325) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.alarm_on_rounded, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t('Scheduled Prayer Alarms (${list.length})', 'شیڈول شدہ نماز الارمز (${list.length})'),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: urduFont),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              if (list.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      t(
                        'No pending alarms in system queue.\nOpen Settings to verify alerts or wait for schedule.',
                        'سسٹم قطار میں کوئی زیر التواء الارم نہیں ہے۔\nسیٹنگز کھولیں یا شیڈول کا انتظار کریں۔',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontFamily: urduFont),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final item = list[i];
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(0xFF1B4332).withValues(alpha: 0.15),
                          child: Text('${i + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B4332))),
                        ),
                        title: Text(item.title ?? 'Prayer Notification', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(item.body ?? 'ID: ${item.id}', style: const TextStyle(fontSize: 11.5)),
                        trailing: Text('#${item.id}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.grey)),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showBulkShiftDialog() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final bool useUrdu = ['urdu', 'sindhi', 'arabic', 'persian'].contains(settings.language);
    String t(String en, String ur) => useUrdu ? ur : en;
    final urduFont = useUrdu ? AppTheme.getFontForLanguage(context, 'urdu') : null;

    String selectedPrayer = 'asar';
    int deltaMinutes = 15;
    bool isShifting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
          final previewBefore = selectedPrayer == 'asar' ? '05:00 PM' : '07:30 PM';
          final previewAfter = JamaatTimesService.shiftTimeString(previewBefore, deltaMinutes);

          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF182325) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.more_time_rounded, color: Color(0xFF00796B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t('Seasonal Bulk Timing Shift', 'سیزنل ٹائمنگ ایڈجسٹر'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: urduFont),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t(
                      'Shift prayer timing across all active masajid in town at once (e.g. seasonal Asr/Isha shift):',
                      'شہر کی تمام فعال مساجد کے اوقات بیک وقت آگے یا پیچھے کریں (مثلاً سیزنل عصر/عشاء کی تبدیلی):',
                    ),
                    style: TextStyle(fontSize: 12.5, fontFamily: urduFont),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: selectedPrayer,
                    decoration: InputDecoration(
                      labelText: t('Select Prayer', 'نماز منتخب کریں'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem(value: 'fajr', child: Text(t('Fajr', 'فجر'))),
                      DropdownMenuItem(value: 'zuhar', child: Text(t('Zuhar', 'ظہر'))),
                      DropdownMenuItem(value: 'asar', child: Text(t('Asar', 'عصر'))),
                      DropdownMenuItem(value: 'isha', child: Text(t('Isha', 'عشاء'))),
                      DropdownMenuItem(value: 'jummah', child: Text(t('Jummah', 'جمعہ'))),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedPrayer = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: deltaMinutes,
                    decoration: InputDecoration(
                      labelText: t('Time Shift Amount', 'وقت کا فرق'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 15, child: Text('+15 Minutes (Later)')),
                      DropdownMenuItem(value: 10, child: Text('+10 Minutes (Later)')),
                      DropdownMenuItem(value: 5, child: Text('+5 Minutes (Later)')),
                      DropdownMenuItem(value: -5, child: Text('-5 Minutes (Earlier)')),
                      DropdownMenuItem(value: -10, child: Text('-10 Minutes (Earlier)')),
                      DropdownMenuItem(value: -15, child: Text('-15 Minutes (Earlier)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => deltaMinutes = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00796B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF00796B).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(previewBefore, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF00796B)),
                        const SizedBox(width: 8),
                        Text(previewAfter, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF00796B))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isShifting ? null : () => Navigator.pop(dialogCtx),
                child: Text(t('Cancel', 'منسوخ'), style: TextStyle(fontFamily: urduFont)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00796B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: isShifting
                    ? null
                    : () async {
                        setDialogState(() => isShifting = true);
                        final count = await JamaatTimesService.instance.bulkShiftPrayerTiming(
                          prayerKey: selectedPrayer,
                          deltaMinutes: deltaMinutes,
                        );
                        if (!dialogCtx.mounted) return;
                        Navigator.pop(dialogCtx);
                        if (!mounted) return;
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              t('Successfully shifted $selectedPrayer for $count masajid!', '$count مساجد کے لیے $selectedPrayer کا وقت تبدیل ہو گیا!'),
                              style: TextStyle(fontFamily: urduFont),
                            ),
                            backgroundColor: const Color(0xFF1B4332),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      },
                child: isShifting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(t('Apply Shift', 'تبدیلی لاگو کریں'), style: TextStyle(fontFamily: urduFont)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allMasajid = JamaatTimesService.instance.getMasjidList(includeHidden: true);
    final bool useUrdu = ['urdu', 'sindhi', 'arabic', 'persian'].contains(settings.language);
    String t(String en, String ur) => useUrdu ? ur : en;
    final urduFont = useUrdu ? AppTheme.getFontForLanguage(context, 'urdu') : null;

    // Compute live stats
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = today.subtract(const Duration(days: 7));
    final thirtyDaysAgo = today.subtract(const Duration(days: 30));

    int updatedToday = 0;
    int updatedThisWeek = 0;
    int updatedThisMonth = 0;
    int totalDefault = 0;
    int totalHidden = 0;

    for (final m in allMasajid) {
      if (m.isHidden) totalHidden++;
      final timing = JamaatTimesService.instance.getTimingFor(m);
      final latest = _getLatestUpdateDate(timing);
      if (latest == null) {
        totalDefault++;
      } else {
        if (!latest.isBefore(today)) updatedToday++;
        if (!latest.isBefore(sevenDaysAgo)) updatedThisWeek++;
        if (!latest.isBefore(thirtyDaysAgo)) updatedThisMonth++;
      }
    }

    final currentMasterPin = JamaatTimesService.instance.masterAdminPin;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101719) : const Color(0xFFF4F6F6),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF182325) : const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.terminal_rounded, size: 20, color: Color(0xFF81C784)),
            const SizedBox(width: 8),
            Text(
              t('Developer Hub', 'ڈویلپر ہب'),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: urduFont),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: t('Sync Cloud & Gist', 'کلاؤڈ اور گسٹ سنک کریں'),
            icon: _isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.sync_rounded),
            onPressed: _isSyncing ? null : _triggerCloudSync,
          ),
          IconButton(
            tooltip: t('Lock & Exit Developer Mode', 'ڈویلپر موڈ بند کریں'),
            icon: const Icon(Icons.lock_outline_rounded),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    t('Developer session locked.', 'ڈویلپر سیشن بند کر دیا گیا۔'),
                    style: TextStyle(fontFamily: urduFont),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _triggerCloudSync();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // ── Top Executive Banner ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1C2B2A), const Color(0xFF131D1E)]
                      : [const Color(0xFF1B4332), const Color(0xFF0F291E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF81C784).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF81C784).withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shield_rounded, size: 13, color: Color(0xFF81C784)),
                            const SizedBox(width: 4),
                            Text(
                              t('DEVELOPER ACTIVE', 'ڈویلپر موڈ فعال'),
                              style: TextStyle(
                                color: const Color(0xFF81C784),
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                                fontFamily: urduFont,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        t('v1.4.7 • Production', 'v1.4.7 • پروڈکشن'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11.5,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t('Sukkur Salah Control Center', 'سکھر صلاۃ کنٹرول سینٹر'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      fontFamily: urduFont,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t(
                      'Unified management for Live Timings, Remote GitHub Gist, Hijri Offsets & App Security.',
                      'اوقاتِ باجماعت، ریموٹ گٹ ہب گسٹ، ہجری تاریخ اور ایپ سیکیورٹی کا مربوط نظام۔',
                    ),
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.35,
                      fontFamily: urduFont,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Connectivity Pills
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPill(
                        icon: Icons.cloud_done_rounded,
                        label: t('Firestore: Live', 'فائر اسٹور: فعال'),
                        color: const Color(0xFF81C784),
                        isDark: isDark,
                        fontFamily: urduFont,
                      ),
                      _buildPill(
                        icon: _gistToken != null ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                        label: _gistToken != null
                            ? t('Gist: Configured', 'گسٹ: منسلک')
                            : t('Gist: Token Missing', 'گسٹ: ٹوکن غیر موجود'),
                        color: _gistToken != null ? const Color(0xFF81C784) : const Color(0xFFFFB74D),
                        isDark: isDark,
                        onTap: _showGistTokenDialog,
                        fontFamily: urduFont,
                      ),
                      _buildPill(
                        icon: Icons.mosque_rounded,
                        label: t('${allMasajid.length} Masajid Registered', 'کل رجسٹرڈ مساجد: ${allMasajid.length}'),
                        color: const Color(0xFF64B5F6),
                        isDark: isDark,
                        fontFamily: urduFont,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Live Network Overview Grid ────────────────────────
            Row(
              children: [
                _buildMetricCard(
                  title: t('Total', 'کل مساجد'),
                  value: '${allMasajid.length}',
                  icon: Icons.mosque_rounded,
                  color: const Color(0xFF81C784),
                  isDark: isDark,
                  fontFamily: urduFont,
                ),
                const SizedBox(width: 6),
                _buildMetricCard(
                  title: t('Today', 'آج'),
                  value: '$updatedToday',
                  icon: Icons.today_rounded,
                  color: const Color(0xFF4DD0E1),
                  isDark: isDark,
                  fontFamily: urduFont,
                ),
                const SizedBox(width: 6),
                _buildMetricCard(
                  title: t('This Week', 'اس ہفتے'),
                  value: '$updatedThisWeek',
                  icon: Icons.flash_on_rounded,
                  color: const Color(0xFFFFD54F),
                  isDark: isDark,
                  fontFamily: urduFont,
                ),
                const SizedBox(width: 6),
                _buildMetricCard(
                  title: t('This Month', 'اس ماہ'),
                  value: '$updatedThisMonth',
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF64B5F6),
                  isDark: isDark,
                  fontFamily: urduFont,
                ),
                const SizedBox(width: 6),
                _buildMetricCard(
                  title: totalHidden > 0
                      ? t('Hidden', 'پوشیدہ')
                      : t('Default', 'بنیادی'),
                  value: totalHidden > 0 ? '$totalHidden' : '$totalDefault',
                  icon: totalHidden > 0 ? Icons.visibility_off_rounded : Icons.history_rounded,
                  color: totalHidden > 0 ? const Color(0xFFE57373) : const Color(0xFFE0E0E0),
                  isDark: isDark,
                  fontFamily: urduFont,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── SECTION 1: CORE MODULES ────────────────────────────
            _buildSectionHeader(t('CORE MODULES', 'بنیادی ماڈیولز'), isDark, urduFont),
            const SizedBox(height: 10),

            // Module 1: Masjid Timings & Change Log
            _buildActionCard(
              context: context,
              icon: Icons.calendar_month_rounded,
              iconBgColor: const Color(0xFF2E7D32),
              title: t('Masjid Timings & Change Log', 'مساجد لاگ و اوقاتِ باجماعت'),
              subtitle: t(
                'Live audit of all masajid, edit prayer times, toggle visibility & manage committee PINs',
                'تمام مساجد کی لائیو نگرانی، اوقات میں ترمیم، پوشیدہ کرنے اور کمیٹی پن کوڈ کا انتظام',
              ),
              badgeText: t('$updatedThisWeek updated recently', '$updatedThisWeek حالیہ اپڈیٹس'),
              badgeColor: const Color(0xFF2E7D32),
              isDark: isDark,
              fontFamily: urduFont,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DeveloperTimingsLogScreen()),
                );
                if (mounted) setState(() {});
              },
            ),

            const SizedBox(height: 10),

            // Module 2: Add New Masjid
            _buildActionCard(
              context: context,
              icon: Icons.add_business_rounded,
              iconBgColor: const Color(0xFF00796B),
              title: t('Register New Masjid', 'نئی مسجد رجسٹر کریں'),
              subtitle: t(
                'Add new mosque across all 10 languages with GPS coordinates, sector & committee PIN',
                '10 زبانوں، جی پی ایس لوکیشن، سیکٹر اور کمیٹی پن کے ساتھ نئی مسجد شامل کریں',
              ),
              badgeText: t('10 Languages', '10 زبانیں'),
              badgeColor: const Color(0xFF00796B),
              isDark: isDark,
              fontFamily: urduFont,
              onTap: () async {
                final added = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const DeveloperAddMasjidScreen()),
                );
                if (added == true && mounted) {
                  _triggerCloudSync();
                }
              },
            ),

            const SizedBox(height: 10),

            // Module 3: Hijri Calendar & Moon Sighting
            _buildActionCard(
              context: context,
              icon: Icons.nightlight_round,
              iconBgColor: const Color(0xFF3949AB),
              title: t('Hijri Calendar & Moon Sighting', 'ہجری کیلنڈر اور رویتِ ہلال'),
              subtitle: t(
                'Adjust Islamic month start dates dynamically on GitHub Gist without releasing an app store update',
                'ایپ اپڈیٹ کے بغیر گٹ ہب گسٹ کے ذریعے اسلامی مہینوں کی تاریخیں تبدیل کریں',
              ),
              badgeText: t('Live Gist', 'لائیو گسٹ'),
              badgeColor: const Color(0xFF3949AB),
              isDark: isDark,
              fontFamily: urduFont,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DeveloperGistManagerScreen(initialTabIndex: 0),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            // Module 4: In-App Announcements & Popups
            _buildActionCard(
              context: context,
              icon: Icons.campaign_rounded,
              iconBgColor: const Color(0xFFD81B60),
              title: t('Announcements & Popups', 'اعلانات اور پاپ اپ الرٹس'),
              subtitle: t(
                'Configure Ramadan/Eid alert popups, persistent banners & urgent notices for all users',
                'رمضان/عید الرٹس، بینرز اور تمام صارفین کے لیے اہم اعلانات کا انتظام',
              ),
              badgeText: t('In-App Alerts', 'ایپ الرٹس'),
              badgeColor: const Color(0xFFD81B60),
              isDark: isDark,
              fontFamily: urduFont,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DeveloperGistManagerScreen(initialTabIndex: 1),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            // Module 5: Seasonal Bulk Timing Shifter
            _buildActionCard(
              context: context,
              icon: Icons.more_time_rounded,
              iconBgColor: const Color(0xFF00796B),
              title: t('Seasonal Bulk Timing Shifter', 'سیزنل ٹائمنگ ایڈجسٹر'),
              subtitle: t(
                'Shift prayer timings across all active masajid (+15/-15 mins) with an instant preview confirmation',
                'تمام فعال مساجد کے اوقات سیزن کے مطابق بیک وقت (+15 یا -15 منٹ) تبدیل کریں',
              ),
              badgeText: t('Town-Wide', 'پورے شہر کے لیے'),
              badgeColor: const Color(0xFF00796B),
              isDark: isDark,
              fontFamily: urduFont,
              onTap: _showBulkShiftDialog,
            ),

            const SizedBox(height: 20),

            // ── SECTION 2: NOTIFICATION & ADHAN LAB ──────────────
            _buildSectionHeader(t('NOTIFICATION & ADHAN LAB', 'نوٹیفکیشن اور اذان لیب'), isDark, urduFont),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF182325) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE65100).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.notifications_active_rounded, color: Color(0xFFE65100), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t('Adhan Engine & System Health', 'اذان انجن اور سسٹم صحت'),
                              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, fontFamily: urduFont),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              t('Live background wake-lock and alarm permissions check', 'پس منظر اور الارم کی اجازتوں کی لائیو جانچ'),
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? Colors.white60 : Colors.black54,
                                fontFamily: urduFont,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: t('Re-check permissions', 'دوبارہ جانچیں'),
                        icon: _isLoadingHealth
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.refresh_rounded, size: 18),
                        onPressed: _isLoadingHealth ? null : _loadDiagnostics,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildStatusPill(
                        label: t('Exact Alarms', 'درست الارمز'),
                        isOk: _healthStatus?.exactAlarmsAllowed == true,
                        isDark: isDark,
                        onFix: () => NotificationHealth.fix(NotificationBlocker.exactAlarmsBlocked),
                      ),
                      _buildStatusPill(
                        label: t('Battery Unrestricted', 'بیٹری بلا روک ٹوک'),
                        isOk: _healthStatus?.batteryUnrestricted == true,
                        isDark: isDark,
                        onFix: () => NotificationHealth.fix(NotificationBlocker.batteryRestricted),
                      ),
                      _buildStatusPill(
                        label: t('Notifications', 'نوٹیفکیشنز'),
                        isOk: _healthStatus?.notificationsAllowed == true,
                        isDark: isDark,
                        onFix: () => NotificationHealth.fix(NotificationBlocker.notificationsBlocked),
                      ),
                    ],
                  ),
                  const Divider(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE65100),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.volume_up_rounded, size: 16),
                          label: Text(t('Test Adhan Now', 'فوری اذان ٹیسٹ'), style: TextStyle(fontSize: 12, fontFamily: urduFont)),
                          onPressed: _testAdhanNotification,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.alarm_rounded, size: 16),
                          label: Text(t('Scheduled Queue', 'شیڈول قطار'), style: TextStyle(fontSize: 12, fontFamily: urduFont)),
                          onPressed: _showScheduledAlarmsDialog,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── SECTION 3: SECURITY & CLOUD ENGINE ────────────────
            _buildSectionHeader(t('SECURITY & CLOUD ENGINE', 'سیکیورٹی اور کلاؤڈ انجن'), isDark, urduFont),
            const SizedBox(height: 10),

            // Master PIN Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF182325) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFFD97706).withValues(alpha: 0.3) : const Color(0xFFD97706).withValues(alpha: 0.25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.security_rounded, color: Color(0xFFD97706), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('Master Developer PIN', 'ماسٹر ڈویلپر پن کوڈ'),
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: urduFont),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              _obscureMasterPin ? '••••••••' : currentMasterPin,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                letterSpacing: 1.5,
                                color: Color(0xFFD97706),
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => setState(() => _obscureMasterPin = !_obscureMasterPin),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Icon(
                                  _obscureMasterPin ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  size: 16,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4332),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.edit_rounded, size: 14),
                    label: Text(t('Change', 'تبدیل کریں'), style: TextStyle(fontSize: 12, fontFamily: urduFont)),
                    onPressed: _showChangeMasterPinDialog,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Cloud Sync & Token Engine
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF182325) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1976D2).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.cloud_sync_rounded, color: Color(0xFF1976D2), size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t('GitHub Personal Access Token', 'گٹ ہب پرسنل ایکسس ٹوکن'),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: urduFont),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _gistToken != null
                                  ? t('Token: ${_gistToken!.substring(0, 6)}••••••••', 'ٹوکن: ${_gistToken!.substring(0, 6)}••••••••')
                                  : t('Not set (Required to write changes to Gist)', 'درج نہیں (گسٹ پر اپڈیٹ کے لیے ضروری)'),
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: urduFont,
                                color: _gistToken != null
                                    ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
                                    : const Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        onPressed: _showGistTokenDialog,
                        child: Text(
                          _gistToken != null ? t('Edit Token', 'ٹوکن بدلیں') : t('Set Token', 'ٹوکن درج کریں'),
                          style: TextStyle(fontSize: 11.5, fontFamily: urduFont),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  // Row 1: Force Sync & Export Report
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: _isSyncing
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh_rounded, size: 16),
                          label: Text(t('Force Cloud Sync', 'کلاؤڈ سنک کریں'), style: TextStyle(fontSize: 12, fontFamily: urduFont)),
                          onPressed: _isSyncing ? null : _triggerCloudSync,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B4332),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.share_rounded, size: 16),
                          label: Text(t('Export Report', 'رپورٹ ایکسپورٹ'), style: TextStyle(fontSize: 12, fontFamily: urduFont)),
                          onPressed: _exportNetworkReport,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Row 2: Raw JSON & Clear Cache
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.data_object_rounded, size: 16),
                          label: Text(t('Copy Raw JSON', 'را Gist JSON'), style: TextStyle(fontSize: 12, fontFamily: urduFont)),
                          onPressed: _copyRawJson,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFE53935),
                            side: BorderSide(color: const Color(0xFFE53935).withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.cleaning_services_rounded, size: 16),
                          label: Text(t('Reset Cache', 'کیشے ری سیٹ'), style: TextStyle(fontSize: 12, fontFamily: urduFont)),
                          onPressed: _confirmClearCache,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── SECTION 4: HARDWARE & SENSOR DIAGNOSTICS ──────────
            _buildSectionHeader(t('HARDWARE & SENSOR DIAGNOSTICS', 'ہارڈویئر اور سینسرز'), isDark, urduFont),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF182325) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF673AB7).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.explore_rounded, color: Color(0xFF673AB7), size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t('Qibla Compass & Location Sensors', 'قبلہ کمپاس اور لوکیشن سینسرز'),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: urduFont),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              t('Verifies hardware magnetometer & GPS chip accuracy', 'مقناطیسی اور جی پی ایس سینسر کی حالت'),
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? Colors.white60 : Colors.black54,
                                fontFamily: urduFont,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (_hasCompassSensor == true ? const Color(0xFF2E7D32) : const Color(0xFFD97706)).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: (_hasCompassSensor == true ? const Color(0xFF2E7D32) : const Color(0xFFD97706)).withValues(alpha: 0.25)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _hasCompassSensor == true ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                                    size: 13,
                                    color: _hasCompassSensor == true ? const Color(0xFF2E7D32) : const Color(0xFFD97706),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      t('Compass Sensor', 'کمپاس سینسر'),
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: urduFont),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _hasCompassSensor == true
                                    ? t('Detected (Ready)', 'موجود ہے (فعال)')
                                    : t('Not detected / Inactive', 'غیر دستیاب'),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _hasCompassSensor == true ? const Color(0xFF2E7D32) : const Color(0xFFD97706),
                                  fontWeight: FontWeight.w600,
                                  fontFamily: urduFont,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (_isGpsEnabled == true ? const Color(0xFF2E7D32) : const Color(0xFFD97706)).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: (_isGpsEnabled == true ? const Color(0xFF2E7D32) : const Color(0xFFD97706)).withValues(alpha: 0.25)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _isGpsEnabled == true ? Icons.location_on_rounded : Icons.location_off_rounded,
                                    size: 13,
                                    color: _isGpsEnabled == true ? const Color(0xFF2E7D32) : const Color(0xFFD97706),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      t('GPS Service', 'جی پی ایس سروس'),
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: urduFont),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _isGpsEnabled == true
                                    ? (_locationPermission != null
                                        ? t('Active (${_locationPermission!.name})', 'فعال (${_locationPermission!.name})')
                                        : t('Active & Enabled', 'فعال ہے'))
                                    : t('Location disabled', 'بند ہے'),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _isGpsEnabled == true ? const Color(0xFF2E7D32) : const Color(0xFFD97706),
                                  fontWeight: FontWeight.w600,
                                  fontFamily: urduFont,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill({
    required String label,
    required bool isOk,
    required bool isDark,
    VoidCallback? onFix,
  }) {
    final color = isOk ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isOk ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? (isOk ? const Color(0xFF81C784) : const Color(0xFFEF5350)) : color,
            ),
          ),
          if (!isOk && onFix != null) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: onFix,
              child: const Text(
                'Fix',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, decoration: TextDecoration.underline, color: Color(0xFFD32F2F)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark, [String? urduFont]) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          fontFamily: urduFont,
          color: isDark ? Colors.white38 : Colors.black45,
        ),
      ),
    );
  }

  Widget _buildPill({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    VoidCallback? onTap,
    String? fontFamily,
  }) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: fontFamily,
              color: isDark ? Colors.white : Colors.white,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: content,
      );
    }
    return content;
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
    String? fontFamily,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF182325) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black12,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: color),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 9.5,
                color: isDark ? Colors.white60 : Colors.black54,
                fontWeight: FontWeight.w500,
                fontFamily: fontFamily,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required bool isDark,
    required VoidCallback onTap,
    String? fontFamily,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF182325) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconBgColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                fontFamily: fontFamily,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: fontFamily,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                          height: 1.3,
                          fontFamily: fontFamily,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? Colors.white30 : Colors.black26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
