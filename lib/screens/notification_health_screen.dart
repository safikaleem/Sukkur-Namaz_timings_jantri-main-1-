import 'package:flutter/material.dart';
// Conditional, exactly as notification_service.dart imports it: the real plugin
// does not build for web, where the stub stands in for it.
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    if (dart.library.html) '../services/notification_stub.dart'
    show PendingNotificationRequest;
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../services/notification_health.dart';
import '../services/notification_service.dart';
import '../utils/app_theme.dart';

/// Why prayer alerts are late or missing, in terms the user can act on.
///
/// Everything here is a live reading, not a stored flag: the permissions this
/// checks are routinely revoked long after onboarding granted them, and until
/// now the app absorbed that silently and simply started arriving late.
class NotificationHealthScreen extends StatefulWidget {
  const NotificationHealthScreen({super.key});

  @override
  State<NotificationHealthScreen> createState() =>
      _NotificationHealthScreenState();
}

class _NotificationHealthScreenState extends State<NotificationHealthScreen>
    with WidgetsBindingObserver {
  NotificationHealth? _health;
  List<PendingNotificationRequest> _pending = const [];
  bool _rescheduling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Every fix sends the user out to a system settings page. Re-reading on the
    // way back is what turns the row green without them having to guess.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final health = await NotificationHealth.check();
    final pending = await NotificationService.instance.pendingNotifications();
    if (!mounted) return;
    setState(() {
      _health = health;
      _pending = pending;
    });
  }

  Future<void> _reschedule(SettingsProvider settings) async {
    setState(() => _rescheduling = true);
    try {
      await NotificationService.instance.scheduleWeeklyNotifications();
    } finally {
      if (mounted) setState(() => _rescheduling = false);
    }
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final muted = isDark ? Colors.white54 : Colors.black54;
    final health = _health;

    return Scaffold(
      backgroundColor: settings.displayThemeBg(isDark),
      appBar: AppBar(
        title: Text(settings.translate('Notification Health', 'اطلاعات کی حالت',
            'اطلاعن جي حالت', 'حالة الإشعارات')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
      ),
      body: health == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _summary(settings, health, isDark, textColor, muted),
                  const SizedBox(height: 16),
                  _checks(settings, health, isDark, textColor, muted),
                  const SizedBox(height: 16),
                  _queue(settings, isDark, textColor, muted),
                  const SizedBox(height: 16),
                  _actions(settings),
                ],
              ),
            ),
    );
  }

  Widget _card(SettingsProvider settings, bool isDark, List<Widget> children) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: settings.displayThemeCard(isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: settings.displayThemeCardBorder(isDark)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      );

  Widget _summary(SettingsProvider settings, NotificationHealth health,
      bool isDark, Color textColor, Color muted) {
    final ok = health.isHealthy;
    final Color tone =
        ok ? const Color(0xFF2E7D32) : (health.isSilenced ? Colors.red : Colors.orange);
    final String headline = ok
        ? settings.translate('Prayer alerts are set up correctly',
            'نماز کی اطلاعات درست طریقے سے سیٹ ہیں', 'نماز جون اطلاعون درست آهن',
            'تنبيهات الصلاة مضبوطة بشكل صحيح')
        : health.isSilenced
            ? settings.translate('Prayer alerts are turned off',
                'نماز کی اطلاعات بند ہیں', 'نماز جون اطلاعون بند آهن',
                'تنبيهات الصلاة متوقفة')
            : settings.translate('Prayer alerts may arrive late',
                'نماز کی اطلاعات دیر سے آ سکتی ہیں',
                'نماز جون اطلاعون دير سان اچي سگهن ٿيون',
                'قد تصل تنبيهات الصلاة متأخرة');

    return _card(settings, isDark, [
      Row(
        children: [
          Icon(ok ? Icons.check_circle : Icons.warning_amber_rounded,
              color: tone, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              headline,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: textColor),
            ),
          ),
        ],
      ),
      if (!ok) ...[
        const SizedBox(height: 10),
        Text(
          settings.translate(
            'Fix the items marked below. Each one opens the phone\'s own settings page.',
            'نیچے نشان زد چیزیں ٹھیک کریں۔ ہر ایک فون کی اپنی سیٹنگز کھولے گی۔',
            'هيٺ نشان ٿيل شيون درست ڪريو. هر هڪ فون جي پنهنجي سيٽنگ کوليندي.',
            'أصلح العناصر المحددة أدناه. كل عنصر يفتح صفحة إعدادات الهاتف.',
          ),
          style: TextStyle(fontSize: 13, color: muted),
        ),
      ],
    ]);
  }

  Widget _checks(SettingsProvider settings, NotificationHealth health,
      bool isDark, Color textColor, Color muted) {
    return _card(settings, isDark, [
      Text(
        settings.translate('Permissions', 'اجازتیں', 'اجازتون', 'الأذونات'),
        style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accent),
      ),
      const SizedBox(height: 12),
      _row(
        settings: settings,
        textColor: textColor,
        muted: muted,
        ok: health.notificationsAllowed,
        title: settings.translate('Show notifications', 'اطلاعات دکھائیں',
            'اطلاعون ڏيکاريو', 'إظهار الإشعارات'),
        detail: settings.translate(
          'Without this nothing appears at all.',
          'اس کے بغیر کچھ بھی ظاہر نہیں ہوگا۔',
          'هن کان سواءِ ڪجهه به ظاهر نه ٿيندو.',
          'بدون هذا لن يظهر أي شيء.',
        ),
        onFix: () => _fix(NotificationBlocker.notificationsBlocked),
      ),
      _row(
        settings: settings,
        textColor: textColor,
        muted: muted,
        ok: health.exactAlarmsAllowed,
        title: settings.translate('Exact alarms', 'درست الارم', 'صحيح الارم',
            'المنبهات الدقيقة'),
        detail: settings.translate(
          'Without this the phone delays every prayer alert.',
          'اس کے بغیر فون ہر اطلاع کو دیر سے دکھاتا ہے۔',
          'هن کان سواءِ فون هر اطلاع دير سان ڏيکاريندو.',
          'بدون هذا يؤخر الهاتف كل تنبيه.',
        ),
        onFix: () => _fix(NotificationBlocker.exactAlarmsBlocked),
      ),
      _row(
        settings: settings,
        textColor: textColor,
        muted: muted,
        ok: health.batteryUnrestricted,
        title: settings.translate('Unrestricted battery', 'بیٹری کی پابندی نہیں',
            'بيٽري جي پابندي ناهي', 'بطارية غير مقيدة'),
        detail: settings.translate(
          'Battery saving can delay or stop prayer alerts.',
          'بیٹری سیونگ اطلاعات کو دیر یا بند کر سکتی ہے۔',
          'بيٽري سيونگ اطلاعون دير يا بند ڪري سگهي ٿي.',
          'قد يؤخر توفير البطارية التنبيهات أو يوقفها.',
        ),
        onFix: () => _fix(NotificationBlocker.batteryRestricted),
      ),
      if (health.hasAutoStartScreen) ...[
        const Divider(height: 24),
        Text(
          settings.translate(
            'This phone also has an Autostart list. Prayer alerts stop completely if the app is removed from recent apps, unless it is allowed there.',
            'اس فون میں آٹو اسٹارٹ کی فہرست بھی ہے۔ اگر ایپ کو حالیہ ایپس سے ہٹا دیا جائے تو اطلاعات مکمل بند ہو جاتی ہیں، جب تک وہاں اجازت نہ ہو۔',
            'هن فون ۾ آٽو اسٽارٽ لسٽ به آهي. جيڪڏهن ايپ کي تازين ايپس مان هٽايو ويو ته اطلاعون بلڪل بند ٿي وينديون، جيستائين اتي اجازت نه هجي.',
            'يحتوي هذا الهاتف على قائمة التشغيل التلقائي. تتوقف التنبيهات تمامًا إذا أُزيل التطبيق من التطبيقات الأخيرة ما لم يُسمح له هناك.',
          ),
          style: TextStyle(fontSize: 13, color: muted),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: NotificationHealth.openAutoStart,
          icon: const Icon(Icons.play_circle_outline),
          label: Text(settings.translate('Open Autostart settings',
              'آٹو اسٹارٹ سیٹنگز کھولیں', 'آٽو اسٽارٽ سيٽنگ کوليو',
              'فتح إعدادات التشغيل التلقائي')),
        ),
      ],
    ]);
  }

  Future<void> _fix(NotificationBlocker blocker) async {
    await NotificationHealth.fix(blocker);
    // didChangeAppLifecycleState refreshes on return, but the exact-alarm
    // request can resolve without ever leaving the app.
    await _refresh();
  }

  Widget _row({
    required SettingsProvider settings,
    required Color textColor,
    required Color muted,
    required bool ok,
    required String title,
    required String detail,
    required VoidCallback onFix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ok ? Icons.check_circle : Icons.cancel,
              color: ok ? const Color(0xFF2E7D32) : Colors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor)),
                if (!ok) ...[
                  const SizedBox(height: 2),
                  Text(detail, style: TextStyle(fontSize: 12, color: muted)),
                ],
              ],
            ),
          ),
          if (!ok)
            TextButton(
              onPressed: onFix,
              child: Text(settings.translate('Fix', 'ٹھیک کریں', 'درست ڪريو',
                  'إصلاح')),
            ),
        ],
      ),
    );
  }

  Widget _queue(SettingsProvider settings, bool isDark, Color textColor,
      Color muted) {
    return _card(settings, isDark, [
      Text(
        settings.translate('Scheduled alerts', 'شیڈول شدہ اطلاعات',
            'شيڊول ٿيل اطلاعون', 'التنبيهات المجدولة'),
        style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accent),
      ),
      const SizedBox(height: 8),
      Text(
        _pending.isEmpty
            ? settings.translate(
                'Nothing is queued. Tap Reschedule below.',
                'کوئی اطلاع قطار میں نہیں۔ نیچے دوبارہ شیڈول کریں۔',
                'ڪا به اطلاع قطار ۾ ناهي. هيٺ ٻيهر شيڊول ڪريو.',
                'لا يوجد شيء في قائمة الانتظار. اضغط إعادة الجدولة أدناه.')
            : settings
                .translate(
                    '{n} alerts are queued with the phone, covering the next {d} days.',
                    'فون میں {n} اطلاعات قطار میں ہیں، اگلے {d} دن کے لیے۔',
                    'فون ۾ {n} اطلاعون قطار ۾ آهن، ايندڙ {d} ڏينهن لاءِ.',
                    'تم جدولة {n} تنبيهًا على الهاتف لمدة {d} يومًا القادمة.')
                .replaceAll('{n}', '${_pending.length}')
                .replaceAll(
                    '{d}', '${NotificationService.scheduleHorizonDays}'),
        style: TextStyle(fontSize: 13, color: muted),
      ),
    ]);
  }

  Widget _actions(SettingsProvider settings) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  settings.translate(
                      'Not receiving prayer alerts? Press Reschedule now',
                      'نماز کی اطلاعات موصول نہیں ہو رہیں؟ ابھی دوبارہ شیڈول کریں دبائیں',
                      'نماز جون اطلاعون نه پيون ملن؟ هاڻي ٻيهر شيڊول ڪريو کي دٻايو',
                      'لا تتلقى تنبيهات الصلاة؟ اضغط على إعادة الجدولة الآن'),
                  style: const TextStyle(fontSize: 13, color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _rescheduling ? null : () => _reschedule(settings),
            icon: _rescheduling
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            label: Text(settings.translate('Reschedule now',
                'ابھی دوبارہ شیڈول کریں', 'هاڻي ٻيهر شيڊول ڪريو',
                'إعادة الجدولة الآن')),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: NotificationService.instance.showTestNotification,
            icon: const Icon(Icons.notifications_active_outlined),
            label: Text(settings.translate('Send a test notification',
                'ٹیسٹ اطلاع بھیجیں', 'ٽيسٽ اطلاع موڪليو',
                'إرسال إشعار تجريبي')),
          ),
        ),
      ],
    );
  }
}
