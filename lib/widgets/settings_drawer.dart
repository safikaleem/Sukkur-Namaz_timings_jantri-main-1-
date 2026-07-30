import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../providers/settings_provider.dart' show SettingsProvider, DarkModeOption, LocationMode;
import '../utils/alert_mode.dart';
import '../utils/app_theme.dart';
import '../screens/about_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/world_prayers_screen.dart';

class SettingsDrawer extends StatefulWidget {
  final VoidCallback? onTapSukkur;
  /// Fired once the world screen has actually settled on a city, so the shell
  /// can drop the user on the Times tab for it.
  final VoidCallback? onWorldCitySelected;
  const SettingsDrawer({super.key, this.onTapSukkur, this.onWorldCitySelected});

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = info.version);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      width: 300,
      backgroundColor: isDark ? AppTheme.drawerDark : Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DrawerHeader(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // ── Sukkur ─────────────────────────────────
                  _DrawerItem(
                    icon: Icons.push_pin_rounded,
                    label: settings.translate('Sukkur', 'سکھر', 'سکر', 'سكر'),
                    // Same wording as the onboarding screen, so the attribution
                    // reads identically everywhere. Arabic already uses الشيخ
                    // in place of "Hazrat" and carries no صاحب.
                    subtitle: '(${settings.translate(
                      'Based on Hazrat Dr Hafeezullah Sahib Qaddasallahu sirrahu Jantri',
                      'بمطابق حضرت ڈاکٹر حفیظ اللہ صاحب قدس اللہ سرہ جنتری',
                      'حضرت ڊاڪٽر حفيظ الله صاحب قدس الله سره جي جنتري مطابق',
                      'بناءً على تقويم الشيخ الدكتور حفيظ الله قدس الله سره',
                    )})',
                    onTap: widget.onTapSukkur,
                  ),
                  _DrawerItem(
                    icon: Icons.public_rounded,
                    label: settings.translate('World Prayer Timings', 'دنیا بھر کی نمازیں', 'دنيا جي نمازون', 'أوقات الصلاة العالمية'),
                    onTap: () async {
                      // Closing the drawer disposes this widget, so grab the
                      // navigator and callback before popping it.
                      final navigator = Navigator.of(context);
                      final onSelected = widget.onWorldCitySelected;
                      navigator.pop();
                      final picked = await navigator.push<bool>(
                        MaterialPageRoute(builder: (_) => const WorldPrayersScreen()),
                      );
                      if (picked == true) onSelected?.call();
                    },
                  ),
                  const _Divider(),

                  // ── Volume (expandable, contains all prayer alerts) ──
                  _VolumeSection(settings: settings),

                  const _Divider(),
                  
                  _LanguageSection(settings: settings),
                  _DarkModeSection(settings: settings),
                  _CircleWidgetSection(settings: settings),

                  _DrawerItem(
                    icon: Icons.settings_rounded,
                    label: settings.translate('Settings', 'ترتیبات', 'سيٽنگون', 'الضبط'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),

                  // ── Test Notifications ──────────────────────────
                  _DrawerItem(
                    icon: Icons.notifications_active_rounded,
                    label: settings.translate('Test Notifications', 'اطلاعات کی جانچ کریں', 'نوٽيفڪيشن چيڪ ڪريو', 'اختبار الإشعارات'),
                    onTap: () async {
                      await NotificationService.instance.showTestNotification();
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),

                  const _Divider(),

                  // ── Contact Us (inline) ─────────────────────
                  const _ContactUsInline(),

                  const _Divider(),

                  // ── About ───────────────────────────────────
                  if (settings.locationMode == LocationMode.sukkur)
                    _DrawerItem(
                      icon: Icons.info_outline_rounded,
                      label: settings.translate(
                          'About Sukkur Salah',
                          'سکھر صلاۃ کے بارے میں',
                          'سکر صلاۃ بابت',
                          'حول صلاة سكر'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AboutScreen()),
                        );
                      },
                    ),

                  // ── Rate the App ────────────────────────────
                  _DrawerItem(
                    icon: Icons.star_rate_rounded,
                    label: settings.translate('Rate the App', 'ایپ کو ریٹ کریں', 'ايپ کي ريٽ ڪريو', 'قيم التطبيق'),
                    onTap: () => _rateApp(context),
                  ),

                  // ── Invite Friends ───────────────────────────
                  _DrawerItem(
                    icon: Icons.share_rounded,
                    label: settings.translate(
                        'Invite Friends to Sukkur Salah',
                        'دوستوں کو سکھر صلاۃ میں مدعو کریں',
                        'دوستن کي سکر صلاۃ ۾ دعوت ڏيو',
                        'شارك التطبيق'),
                    onTap: () => _shareApp(context),
                  ),

                  // ── Current Version ───────────────────────────
                  _DrawerItem(
                    icon: Icons.new_releases_rounded,
                    label: '${settings.translate('Current version', 'موجودہ ورژن', 'موجوده ورجن', 'الإصدار الحالي')} ${_version.isNotEmpty ? _version : '1.1.3'}',
                    onTap: () => _showWhatsNewDialog(context),
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

  void _shareApp(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.share_rounded,
                    color: AppTheme.accent, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                settings.translate('Invite Friends', 'دوستوں کو مدعو کریں', 'دوستن کي دعوت ڏيو', 'شارك التطبيق'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                settings.translate(
                    'Share Sukkur Salah with your friends and family',
                    'سکھر صلاۃ اپنے دوستوں اور خاندان کے ساتھ شیئر کریں',
                    'سکر صلاۃ پنهنجي دوستن ۽ خاندان سان شيئر ڪريو',
                    'شارك صلاة سكر مع أصدقائك وعائلتك'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(
                      settings.translate('Close', 'بند کریں', 'بند ڪريو', 'إغلاق'),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: Text(settings.translate('Share', 'شیئر کریں', 'شيئر ڪريو', 'مشاركة')),
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      SharePlus.instance.share(
                        ShareParams(
                          text: settings.translate(
                              'Sukkur Salah – Namaz timings for Sukkur. Download now:\nhttps://play.google.com/store/apps/details?id=pk.sukkur.salah',
                              'سکھر صلاۃ - سکھر کے نماز کے اوقات۔ ابھی ڈاؤن لوڈ کریں:\nhttps://play.google.com/store/apps/details?id=pk.sukkur.salah',
                              'سکر صلاۃ - سکر جي نماز جا وقت۔ هينئر ڊائونلوڊ ڪريو:\nhttps://play.google.com/store/apps/details?id=pk.sukkur.salah',
                              'صلاة سكر - مواقيت الصلاة في سكر. حمل الآن:\nhttps://play.google.com/store/apps/details?id=pk.sukkur.salah'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _rateApp(BuildContext context) async {
    final url = Uri.parse('https://play.google.com/store/apps/details?id=pk.sukkur.salah');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Play Store.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
  void _showWhatsNewDialog(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final versionStr = _version.isNotEmpty ? _version : '1.1.3';

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.accent, AppTheme.accent.withValues(alpha: 0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accent.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: const Icon(Icons.new_releases_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          settings.translate("What's New", 'نئے فیچرز', 'نوان فيچرز', 'ما الجديد'),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                            fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.accent.withValues(alpha: 0.15),
                                AppTheme.accent.withValues(alpha: 0.05)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3), width: 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded, size: 12, color: AppTheme.accent),
                              const SizedBox(width: 4),
                              Text(
                                '${settings.translate('Version', 'ورژن', 'ورجن', 'الإصدار')} $versionStr',
                                style: TextStyle(
                                  fontSize: settings.isRtl ? 12 : 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white70 : AppTheme.accent,
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
              ),
              const SizedBox(height: 20),
              // Content Area
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Version 1.1.3 ──────────────────────────────────
                  _buildNewFeatureItem(
                    context,
                    settings,
                    settings.translate(
                      'Monthly Jantri Now Fully Translated',
                      'ماہانہ جنتری اب مکمل ترجمہ شدہ',
                      'مهينووار جنتري هاڻي مڪمل ترجمو ٿيل',
                      'الجدول الشهري مترجم بالكامل الآن',
                    ),
                    settings.translate(
                      'The Monthly Schedule column headings - Date, Intiha e Sehar, Fajar, Zuhar and the rest - now appear in your chosen language instead of English, for both the Sukkur Jantri and world city timings.',
                      'ماہانہ شیڈیول کے کالموں کے عنوانات - تاریخ، انتہائے سحر، فجر، ظہر اور باقی سب - اب انگریزی کی بجائے آپ کی منتخب کردہ زبان میں دکھائی دیتے ہیں، سکھر کی جنتری اور دنیا بھر کے شہروں دونوں کے لیے۔',
                      'مهينووار شيڊيول جي ڪالمن جا عنوان - تاريخ، انتهاءِ سحر، فجر، ظهر ۽ باقي سڀ - هاڻي انگريزيءَ بدران توهان جي چونڊيل ٻوليءَ ۾ ڏيکارجن ٿا، سکر جي جنتري ۽ دنيا جي شهرن ٻنهي لاءِ.',
                      'تظهر عناوين أعمدة الجدول الشهري - التاريخ ونهاية السحر والفجر والظهر وغيرها - الآن بلغتك المختارة بدلاً من الإنجليزية، لجنتري سكر ولمدن العالم معًا.',
                    ),
                    icon: Icons.translate_rounded,
                    iconColor: const Color(0xFF8E24AA),
                  ),
                  _buildNewFeatureItem(
                    context,
                    settings,
                    settings.translate(
                      'Sharper Quran Pages',
                      'قرآن کے صفحات زیادہ واضح',
                      'قرآن جا صفحا وڌيڪ چٽا',
                      'صفحات القرآن أكثر وضوحًا',
                    ),
                    settings.translate(
                      'Mushaf pages are now rendered at your screen\'s own resolution with proper filtering, so the text looks noticeably crisper on high resolution displays.',
                      'مصحف کے صفحات اب آپ کی اسکرین کی اصل ریزولیوشن پر تیار ہوتے ہیں، اس لیے زیادہ ریزولیوشن والی اسکرینوں پر تحریر نمایاں طور پر صاف نظر آتی ہے۔',
                      'مصحف جا صفحا هاڻي توهان جي اسڪرين جي اصل ريزوليوشن تي تيار ٿين ٿا، ان ڪري وڏي ريزوليوشن واري اسڪرين تي لکڻي گهڻي صاف نظر اچي ٿي.',
                      'تُعرض صفحات المصحف الآن بدقة شاشتك نفسها مع معالجة أفضل، فيبدو النص أوضح بكثير على الشاشات عالية الدقة.',
                    ),
                    icon: Icons.menu_book_rounded,
                    iconColor: const Color(0xFF00897B),
                  ),
                  _buildNewFeatureItem(
                    context,
                    settings,
                    settings.translate(
                      'Redesigned Home Screen Widgets',
                      'ہوم اسکرین ویجٹس کی نئی شکل',
                      'هوم اسڪرين ويجٽس جي نئين شڪل',
                      'تصميم جديد لأدوات الشاشة الرئيسية',
                    ),
                    settings.translate(
                      'The home screen widgets have a slimmer, cleaner look, and the circle clock widget now shows AM/PM alongside the time.',
                      'ہوم اسکرین کے ویجٹس اب زیادہ پتلے اور صاف ہیں، اور سرکل کلاک ویجٹ میں وقت کے ساتھ AM/PM بھی دکھایا جاتا ہے۔',
                      'هوم اسڪرين جا ويجٽ هاڻي وڌيڪ سنهڙا ۽ صاف آهن، ۽ سرڪل ڪلاڪ ويجٽ ۾ وقت سان گڏ AM/PM به ڏيکاريو وڃي ٿو.',
                      'أصبحت أدوات الشاشة الرئيسية أنحف وأوضح، وتعرض أداة الساعة الدائرية الآن ص/م بجانب الوقت.',
                    ),
                    icon: Icons.widgets_rounded,
                    iconColor: const Color(0xFF3F51B5),
                  ),
                  _buildNewFeatureItem(
                    context,
                    settings,
                    settings.translate(
                      'Sukkur Always Uses the Jantri',
                      'سکھر ہمیشہ جنتری کے مطابق',
                      'سکر هميشه جنتري مطابق',
                      'سكر تعتمد الجنتري دائمًا',
                    ),
                    settings.translate(
                      'Sukkur now always shows the authentic Jantri timings and never falls back to calculated ones. After choosing a city you are also taken straight to the Times screen.',
                      'سکھر اب ہمیشہ اصل جنتری کے اوقات دکھاتا ہے اور کبھی حساب کیے گئے اوقات پر منتقل نہیں ہوتا۔ شہر منتخب کرنے کے بعد آپ سیدھا اوقات کی اسکرین پر پہنچ جاتے ہیں۔',
                      'سکر هاڻي هميشه اصل جنتري جا وقت ڏيکاري ٿو ۽ ڪڏهن به حساب ڪيل وقتن تي نه ويندو. شهر چونڊڻ کان پوءِ توهان سڌو وقتن جي اسڪرين تي پهچي ويندا.',
                      'تعرض سكر الآن دائمًا أوقات الجنتري الأصلية ولا تنتقل أبدًا إلى الأوقات المحسوبة. وبعد اختيار مدينة تنتقل مباشرة إلى شاشة الأوقات.',
                    ),
                    icon: Icons.verified_rounded,
                    iconColor: const Color(0xFF1E88E5),
                  ),
                  _buildNewFeatureItem(
                    context,
                    settings,
                    settings.translate(
                      'Your Last City Is Remembered',
                      'آپ کا آخری شہر محفوظ',
                      'توهان جو آخري شهر محفوظ',
                      'حفظ آخر مدينة اخترتها',
                    ),
                    settings.translate(
                      'Switching back to World Prayer Timings returns you to the city you were last using, instead of asking you to choose it again.',
                      'ورلڈ پریئر ٹائمنگز پر واپس جانے پر آپ کو وہی شہر ملتا ہے جو آپ آخری بار استعمال کر رہے تھے، دوبارہ منتخب کرنے کی ضرورت نہیں رہتی۔',
                      'ورلڊ پريئر ٽائمنگز تي واپس وڃڻ تي توهان کي اهوئي شهر ملي ٿو جيڪو توهان آخري ڀيرو استعمال ڪري رهيا هئا، وري چونڊڻ جي ضرورت نه ٿي رهي.',
                      'عند العودة إلى أوقات الصلاة العالمية تجد المدينة التي كنت تستخدمها آخر مرة، دون الحاجة إلى اختيارها من جديد.',
                    ),
                    icon: Icons.location_city_rounded,
                    iconColor: const Color(0xFF43A047),
                  ),
                  _buildNewFeatureItem(
                    context,
                    settings,
                    settings.translate(
                      'Clearer Analogue Clock',
                      'اینالاگ گھڑی زیادہ واضح',
                      'اينالاگ گھڙي وڌيڪ چٽي',
                      'ساعة تناظرية أوضح',
                    ),
                    settings.translate(
                      'The analogue clock hands are slimmer and easier to read across every clock style.',
                      'اینالاگ گھڑی کی سوئیاں اب پتلی اور ہر کلاک اسٹائل میں پڑھنے میں آسان ہیں۔',
                      'اينالاگ گھڙيءَ جون سُيون هاڻي سنهڙيون ۽ هر ڪلاڪ اسٽائل ۾ پڙهڻ ۾ آسان آهن.',
                      'أصبحت عقارب الساعة التناظرية أنحف وأسهل قراءة في جميع أنماط الساعة.',
                    ),
                    icon: Icons.schedule_rounded,
                    iconColor: const Color(0xFFF9A825),
                  ),
                  _buildNewFeatureItem(
                    context,
                    settings,
                    settings.translate(
                      'Neater Screen Layout',
                      'اسکرین کی بہتر ترتیب',
                      'اسڪرين جي بهتر ترتيب',
                      'تنسيق أنظف للشاشة',
                    ),
                    settings.translate(
                      'The advisory note at the bottom of the Today and Monthly screens now sits flush against the navigation bar, with no leftover gap.',
                      'آج اور ماہانہ اسکرین کے نیچے دی گئی ہدایت اب نیویگیشن بار سے بالکل ملی ہوئی ہے، درمیان میں کوئی خالی جگہ نہیں رہی۔',
                      'اڄ ۽ مهينووار اسڪرين جي هيٺان ڏنل هدايت هاڻي نيويگيشن بار سان بلڪل لڳل آهي، وچ ۾ ڪا خالي جاءِ نه رهي.',
                      'أصبح التنبيه أسفل شاشتي اليوم والشهر ملاصقًا لشريط التنقل تمامًا، دون فراغ متبقٍ.',
                    ),
                    icon: Icons.tune_rounded,
                    iconColor: const Color(0xFF6D4C41),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Close Button (Premium Full Width)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    settings.translate('Close', 'بند کریں', 'بند ڪريو', 'إغلاق'),
                    style: TextStyle(
                      fontSize: settings.isRtl ? 16 : 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildNewFeatureItem(
      BuildContext context, SettingsProvider settings, String title, String description,
      {required IconData icon, required Color iconColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: settings.isRtl ? 16 : 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: settings.isRtl ? 13 : 11.5,
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// ── Drawer Header ──────────────────────────────────────────────────
class _DrawerHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            settings.translate('Sukkur Salah', 'سکھر صلاۃ', 'سکر صلاۃ', 'صلاة سكر'),
            style: TextStyle(
              fontSize: settings.isRtl ? 28 : 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            settings.translate('Worldwide Prayer Timings', 'دنیا بھر کے نماز کے اوقات', 'دنيا ڀر جي نماز جا وقت', 'مواقيت الصلاة حول العالم'),
            style: TextStyle(
              fontSize: settings.isRtl ? 16 : 13,
              color: isDark ? Colors.white38 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Plain tap row ──────────────────────────────────────────────────
class _DrawerItem extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;

  const _DrawerItem({
    this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    final isRtl = settings.isRtl;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon,
                  color: isDark ? Colors.white54 : Colors.black54, size: 20),
              const SizedBox(width: 16),
            ] else
              const SizedBox(width: 36),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: isRtl ? 17 : 14,
                      color: isDark ? const Color(0xDEFFFFFF) : Colors.black87,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: isRtl ? 13 : 11,
                          height: 1.3,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
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

// ── Dark Mode expandable section ──────────────────────────────────
class _DarkModeSection extends StatefulWidget {
  final SettingsProvider settings;
  const _DarkModeSection({required this.settings});

  @override
  State<_DarkModeSection> createState() => _DarkModeSectionState();
}

class _DarkModeSectionState extends State<_DarkModeSection> {
  bool _expanded = false;

  String _currentLabel(SettingsProvider settings) {
    switch (widget.settings.darkModeOption) {
      case DarkModeOption.on:
        return settings.translate('On', 'آن', 'آن', 'تشغيل');
      case DarkModeOption.off:
        return settings.translate('Off', 'آف', 'آف', 'إيقاف');
      case DarkModeOption.auto:
        return settings.translate('Auto', 'خودکار', 'پاڻمرادو', 'تلقائي');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = widget.settings;
    final isRtl = settings.isRtl;
    final current = settings.darkModeOption;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.dark_mode_rounded,
                    color: isDark ? Colors.white54 : Colors.black54, size: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    settings.translate('Dark Mode', 'ڈارک موڈ', 'ڊارڪ موڊ', 'الوضع الليلي'),
                    style: TextStyle(
                      fontSize: isRtl ? 17 : 14,
                      color: isDark ? const Color(0xDEFFFFFF) : Colors.black87,
                    ),
                  ),
                ),
                Text(
                  _currentLabel(settings),
                  style: TextStyle(
                    fontSize: isRtl ? 15 : 12,
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      color: isDark ? Colors.white38 : Colors.black38,
                      size: 20),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(52, 0, 20, 12),
            child: Row(
              children: [
                _DarkModeOptionBtn(
                  label: settings.translate('On', 'آن', 'آن', 'تشغيل'),
                  selected: current == DarkModeOption.on,
                  isDark: isDark,
                  onTap: () =>
                      settings.setDarkModeOption(DarkModeOption.on),
                ),
                const SizedBox(width: 8),
                _DarkModeOptionBtn(
                  label: settings.translate('Off', 'آف', 'آف', 'إيقاف'),
                  selected: current == DarkModeOption.off,
                  isDark: isDark,
                  onTap: () =>
                      settings.setDarkModeOption(DarkModeOption.off),
                ),
                const SizedBox(width: 8),
                _DarkModeOptionBtn(
                  label: settings.translate('Automatic', 'خودکار', 'پاڻمرادو', 'تلقائي'),
                  selected: current == DarkModeOption.auto,
                  isDark: isDark,
                  onTap: () =>
                      settings.setDarkModeOption(DarkModeOption.auto),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DarkModeOptionBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _DarkModeOptionBtn({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = context.watch<SettingsProvider>().isRtl;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accent.withValues(alpha: 0.15)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppTheme.accent.withValues(alpha: 0.6)
                : (isDark ? Colors.white12 : Colors.black12),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isRtl ? 15 : 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? AppTheme.accent
                : (isDark ? Colors.white54 : Colors.black54),
          ),
        ),
      ),
    );
  }
}

// ── Divider ────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 20,
      endIndent: 20,
      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black12,
    );
  }
}

// ── Pre-Prayer Alerts section (toggle + tap to pick alert mode) ────
class _VolumeSection extends StatefulWidget {
  final SettingsProvider settings;
  const _VolumeSection({required this.settings});

  @override
  State<_VolumeSection> createState() => _VolumeSectionState();
}

class _VolumeSectionState extends State<_VolumeSection> {
  bool _expanded = false;

  static const _prayers = [
    ('Intiha e Sehar', 'انتہائے سحر', Icons.wb_twilight_rounded, false),
    ('Fajar', 'فجر', Icons.star_half_rounded, true),
    ('Tulu Aftab', 'طلوع آفتاب', Icons.wb_sunny_outlined, false),
    ('Ishraq', 'اشراق', Icons.sunny, false),
    ('Zawal', 'زوال آفتاب', Icons.wb_sunny_rounded, false),
    ('Zuhar', 'ظہر', Icons.wb_sunny_rounded, true),
    ('Misl Awwal', 'مثل اول', Icons.light_mode_outlined, true),
    ('Asr Hanafi', 'عصر حنفی', Icons.light_mode_rounded, true),
    ('Maghrib', 'مغرب', Icons.nights_stay_outlined, true),
    ('Isha', 'عشاء', Icons.nightlight_round, true),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = widget.settings;
    final isRtl = settings.isRtl;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Header ──────────────────────────────────────────
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.volume_up_rounded,
                    color: isDark ? Colors.white54 : Colors.black54, size: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    settings.translate('Prayer Alerts', 'نماز الرٹس', 'نماز الرٽس', 'تنبيهات الصلاة'),
                    style: TextStyle(
                      fontSize: isRtl ? 17 : 14,
                      color: isDark ? const Color(0xDEFFFFFF) : Colors.black87,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      color: isDark ? Colors.white38 : Colors.black38,
                      size: 20),
                ),
              ],
            ),
          ),
        ),
        // ── Prayer rows (animated) ───────────────────────────
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      settings.translate('All prayer alerts', 'تمام نماز الرٹس', 'سڀ نماز الرٽس', 'كل تنبيهات الصلاة'),
                      style: TextStyle(
                        fontSize: isRtl ? 15 : 13,
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          settings.isAnyPrayerEnabled
                              ? settings.translate('On', 'آن', 'آن', 'تشغيل')
                              : settings.translate('Off', 'آف', 'آف', 'إيقاف'),
                          style: TextStyle(
                            fontSize: isRtl ? 14 : 12,
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: settings.isAnyPrayerEnabled,
                          onChanged: (val) => settings.setAllPrayersEnabled(val),
                          activeColor: AppTheme.accent,
                          activeTrackColor: AppTheme.accent.withValues(alpha: 0.3),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(
                color: isDark ? Colors.white10 : Colors.black12,
                indent: 20,
                endIndent: 20,
                height: 1,
              ),
              const SizedBox(height: 8),
              for (final p in _prayers)
                _PrayerAlertRow(
                  name: p.$1,
                  urdu: p.$2,
                  icon: p.$3,
                  showAzan: p.$4,
                  isDark: isDark,
                  enabled: settings.isPrayerEnabled(p.$1),
                  mode: settings.getAlertMode(p.$1),
                  onEnabledChanged: (v) =>
                      settings.setPrayerEnabled(p.$1, v),
                  onModeChanged: (m) => settings.setAlertMode(p.$1, m),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Per-prayer row: toggle + tap name to reveal mode buttons ────────
class _PrayerAlertRow extends StatefulWidget {
  final String name;
  final String urdu;
  final IconData icon;
  final bool showAzan;
  final bool isDark;
  final bool enabled;
  final AlertMode mode;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<AlertMode> onModeChanged;

  const _PrayerAlertRow({
    required this.name,
    required this.urdu,
    required this.icon,
    required this.showAzan,
    required this.isDark,
    required this.enabled,
    required this.mode,
    required this.onEnabledChanged,
    required this.onModeChanged,
  });

  @override
  State<_PrayerAlertRow> createState() => _PrayerAlertRowState();
}

class _PrayerAlertRowState extends State<_PrayerAlertRow> {
  bool _modeOpen = false;

  // Sindhi prayer name map
  static const _sindhiNames = {
    'Intiha e Sehar': 'انتهاءِ سحر',
    'Fajar': 'فجر',
    'Tulu Aftab': 'سج اڀرڻ',
    'Ishraq': 'اشراق',
    'Zawal': 'زوالِ آفتاب',
    'Zuhar': 'ظھر',
    'Misl Awwal': 'مثل اول',
    'Asr Hanafi': 'عصر',
    'Maghrib': 'مغرب',
    'Isha': 'عشاء',
  };

  // Arabic prayer name map
  static const _arabicNames = {
    'Intiha e Sehar': 'نهاية السحر',
    'Fajar': 'الفجر',
    'Tulu Aftab': 'الشروق',
    'Ishraq': 'الإشراق',
    'Zawal': 'الزوال',
    'Zuhar': 'الظهر',
    'Misl Awwal': 'المثل الأول',
    'Asr Hanafi': 'العصر',
    'Maghrib': 'المغرب',
    'Isha': 'العشاء',
  };

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isRtl = settings.isRtl;
    final isSindhi = settings.isSindhi;
    final isArabic = settings.isArabic;

    // Pick the right display name for the prayer
    final String displayName = isSindhi
        ? (_sindhiNames[widget.name] ?? widget.name)
        : (isArabic
            ? (_arabicNames[widget.name] ?? widget.name)
            : (isRtl ? widget.urdu : widget.name));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Main row ────────────────────────────────────────
        InkWell(
          onTap: () => setState(() => _modeOpen = !_modeOpen),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(36, 6, 12, 6),
            child: Row(
              children: [
                Icon(widget.icon,
                    color: widget.isDark ? Colors.white38 : Colors.black45,
                    size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayName,
                    style: TextStyle(
                      fontSize: isRtl ? 16 : 13,
                      // Use Urdu font only for Urdu (not Sindhi — Naskh is cleaner for Sindhi)
                      fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                      height: isRtl ? 1.8 : null,
                      color: widget.isDark
                          ? const Color(0xDEFFFFFF)
                          : Colors.black87,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _modeOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      color: widget.isDark ? Colors.white38 : Colors.black38,
                      size: 16),
                ),
                const SizedBox(width: 4),
                Transform.scale(
                  scale: 0.75,
                  child: Switch(
                    value: widget.enabled,
                    onChanged: widget.onEnabledChanged,
                    activeThumbColor: AppTheme.accent,
                    activeTrackColor:
                        AppTheme.accent.withValues(alpha: 0.4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ),
        // ── Alert mode buttons (expand on tap) ───────────────
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState:
              _modeOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity),
          secondChild: IgnorePointer(
            ignoring: !widget.enabled,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: widget.enabled ? 1.0 : 0.35,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(60, 0, 20, 10),
                child: Row(
                  children: [
                    _ModeIconBtn(
                      icon: Icons.volume_off_rounded,
                      label: settings.translate('Silent', 'خاموش', 'خاموش', 'صامت'),
                      selected: widget.mode == AlertMode.silent,
                      activeColor: Colors.grey.shade600,
                      isDark: widget.isDark,
                      onTap: () => widget.onModeChanged(AlertMode.silent),
                    ),
                    const SizedBox(width: 6),
                    _ModeIconBtn(
                      icon: Icons.vibration_rounded,
                      label: settings.translate('Vibration', 'وائبریشن', 'وائبريشن', 'اهتزاز'),
                      selected: widget.mode == AlertMode.vibrate,
                      activeColor: Colors.orange,
                      isDark: widget.isDark,
                      onTap: () {
                        HapticFeedback.vibrate();
                        widget.onModeChanged(AlertMode.vibrate);
                      },
                    ),
                    const SizedBox(width: 6),
                    _ModeIconBtn(
                      icon: Icons.volume_up_rounded,
                      label: settings.translate('Beep', 'آواز', 'آواز', 'صوت'),
                      selected: widget.mode == AlertMode.loud,
                      activeColor: AppTheme.accent,
                      isDark: widget.isDark,
                      onTap: () => widget.onModeChanged(AlertMode.loud),
                    ),
                    if (widget.showAzan) ...[
                      const SizedBox(width: 6),
                      _ModeIconBtn(
                        icon: Icons.mosque_rounded,
                        label: settings.translate('Azan', 'اذان', 'اذان', 'أذان'),
                        selected: widget.mode == AlertMode.azan,
                        activeColor: const Color(0xFF2E7D32),
                        isDark: widget.isDark,
                        onTap: () => widget.onModeChanged(AlertMode.azan),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Alert mode icon button ──────────────────────────────────────────
class _ModeIconBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color activeColor;
  final bool isDark;
  final VoidCallback onTap;

  const _ModeIconBtn({
    required this.icon,
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        constraints: const BoxConstraints(minWidth: 40),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: 0.15)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? activeColor.withValues(alpha: 0.55)
                : (isDark ? Colors.white12 : Colors.black12),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: selected
                    ? activeColor
                    : (isDark ? Colors.white54 : Colors.black45)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: settings.isRtl ? 10.5 : 8.5,
                fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? activeColor
                    : (isDark ? Colors.white70 : Colors.black54),
              ),
              maxLines: 1,
              overflow: TextOverflow.visible,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Language selector (expandable English / Urdu) ─────────────────
class _LanguageSection extends StatefulWidget {
  final SettingsProvider settings;
  const _LanguageSection({required this.settings});

  @override
  State<_LanguageSection> createState() => _LanguageSectionState();
}

class _LanguageSectionState extends State<_LanguageSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = widget.settings.isRtl;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Header ──────────────────────────────────────────
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.language_rounded,
                    color: isDark ? Colors.white54 : Colors.black54, size: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.settings.translate('Language', 'زبان', 'ٻولي', 'اللغة'),
                    style: TextStyle(
                      fontSize: isRtl ? 17 : 14,
                      color: isDark ? const Color(0xDEFFFFFF) : Colors.black87,
                    ),
                  ),
                ),
                Text(
                  // The selected language's own name - never translate() here,
                  // which would resolve against the selected language itself
                  // and fall back to 'English' for every world language.
                  widget.settings.languageName,
                  style: TextStyle(
                    fontSize: isRtl ? 15 : 12,
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      color: isDark ? Colors.white38 : Colors.black38,
                      size: 20),
                ),
              ],
            ),
          ),
        ),
        // ── Language options ─────────────────────────────────
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(52, 0, 20, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              // Driven off SettingsProvider.languageNames so the picker and the
              // header label can never disagree about a language's name.
              children: [
                for (final entry in SettingsProvider.languageNames.entries)
                  _LangOption(
                    label: entry.value,
                    selected: widget.settings.language == entry.key,
                    isDark: isDark,
                    onTap: () => widget.settings.setLanguage(entry.key),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LangOption extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _LangOption({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isRtl = settings.isRtl;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accent.withValues(alpha: 0.15)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppTheme.accent.withValues(alpha: 0.6)
                : (isDark ? Colors.white12 : Colors.black12),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isRtl ? 15 : 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            fontFamily: (label == 'اردو')
                ? AppTheme.urduFont
                : (label == 'سنڌي'
                    ? AppTheme.getSindhiFont(context)
                    : 'sans-serif'), // 'عربي' and 'English' both use system font
            color: selected
                ? AppTheme.accent
                : (isDark ? Colors.white54 : Colors.black54),
          ),
        ),
      ),
    );
  }
}

// ── Contact Us inline (ExpansionTile) ─────────────────────────────
class _ContactUsInline extends StatelessWidget {
  const _ContactUsInline();

  static Future<void> _openGmail() async {
    const email = 'mmsafiullah@yahoo.com';
    Uri uri;
    if (Platform.isAndroid) {
      uri = Uri.parse(
        'intent://compose?to=$email#Intent;scheme=mailto;package=com.google.android.gm;end',
      );
    } else if (Platform.isIOS) {
      uri = Uri.parse('googlegmail:///co?to=$email');
    } else {
      uri = Uri(scheme: 'mailto', path: email);
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(Uri(scheme: 'mailto', path: email),
          mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> _openMap() async {
    final uri = Uri.parse('https://maps.app.goo.gl/KhS6dMVmqgSTYzdT7');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    final isRtl = settings.isRtl;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(Icons.mail_outline_rounded,
            color: isDark ? Colors.white54 : Colors.black54, size: 20),
        title: Text(
          settings.translate('Contact Us', 'ہم سے رابطہ کریں', 'اسان سان رابطو ڪريو', 'تواصل معنا'),
          style: TextStyle(
            fontSize: isRtl ? 17 : 14,
            color: isDark ? const Color(0xDEFFFFFF) : Colors.black87,
            fontWeight: FontWeight.w400,
          ),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : AppTheme.accent.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppTheme.accent.withValues(alpha: 0.15),
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settings.translate(
                    'For queries or feedback, reach us at',
                    'کسی بھی سوال یا تجویز کے لیے ای میل کریں',
                    'ڪنهن به سوال يا تجويز لاءِ اي ميل ڪريو',
                    'لأي استفسار أو اقتراح، يرجى مراسلتنا على',
                  ),
                  style: TextStyle(
                    fontSize: isRtl ? 14 : 12,
                    height: 1.5,
                    color: isDark ? Colors.white54 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _openGmail,
                  child: Row(
                    children: [
                      Icon(Icons.alternate_email_rounded,
                          color: AppTheme.accent, size: 15),
                      const SizedBox(width: 8),
                      Text(
                        'mmsafiullah@yahoo.com',
                        style: TextStyle(
                          fontSize: isRtl ? 15 : 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accent,
                          decoration: TextDecoration.underline,
                          decorationColor: AppTheme.accent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_rounded,
                        color: isDark ? Colors.white38 : Colors.black87,
                        size: 15),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            settings.translate(
                              'Or feel free to visit at Masjid Babul Islam, Anaj Bazar, Sukkur',
                              'یا مسجد بابُ الاسلام، اناج بازار سکھر تشریف لائیں',
                              'يا مسجد بابُ الاسلام، اناج بازار سکر تشريف آڻيو',
                              'أو تفضل بزيارتنا في مسجد باب الإسلام، سكر',
                            ),
                            style: TextStyle(
                              fontSize: isRtl ? 14 : 12,
                              color: isDark ? Colors.white60 : Colors.black87,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: _openMap,
                            child: Text(
                              settings.translate(
                                'View location on Google Maps',
                                'گوگل میپ پر مقام دیکھیں',
                                'گوگل ميپ تي مقام ڏسو',
                                'عرض الموقع على خرائط جوجل',
                              ),
                              style: TextStyle(
                                fontSize: isRtl ? 13 : 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.accent,
                                decoration: TextDecoration.underline,
                                decorationColor: AppTheme.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Circle Widget expandable section ──────────────────────────────────
class _CircleWidgetSection extends StatefulWidget {
  final SettingsProvider settings;
  const _CircleWidgetSection({required this.settings});

  @override
  State<_CircleWidgetSection> createState() => _CircleWidgetSectionState();
}

class _CircleWidgetSectionState extends State<_CircleWidgetSection> {
  bool _expanded = false;

  String _currentLabel(SettingsProvider settings) {
    switch (widget.settings.circleWidgetStyle) {
      case 'analog':
        return settings.translate('Analog', 'اینالاگ', 'اينالاگ', 'تناظري');
      case 'digital':
      default:
        return settings.translate('Digital', 'ڈیجیٹل', 'ڊجيٽل', 'رقمي');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = widget.settings;
    final isRtl = settings.isRtl;
    final current = settings.circleWidgetStyle;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.widgets_rounded,
                    color: isDark ? Colors.white54 : Colors.black54, size: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    settings.translate('Widget Clock', 'ویجیٹ کلاک', 'ويجيٽ ڪلاڪ', 'ساعة الودجت'),
                    style: TextStyle(
                      fontSize: isRtl ? 17 : 14,
                      color: isDark ? const Color(0xDEFFFFFF) : Colors.black87,
                    ),
                  ),
                ),
                Text(
                  _currentLabel(settings),
                  style: TextStyle(
                    fontSize: isRtl ? 15 : 12,
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      color: isDark ? Colors.white38 : Colors.black38,
                      size: 20),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(52, 0, 20, 12),
            child: Row(
              children: [
                _DarkModeOptionBtn(
                  label: settings.translate('Digital', 'ڈیجیٹل', 'ڊجيٽل', 'رقمي'),
                  selected: current == 'digital',
                  isDark: isDark,
                  onTap: () =>
                      settings.setCircleWidgetStyle('digital'),
                ),
                const SizedBox(width: 8),
                _DarkModeOptionBtn(
                  label: settings.translate('Analog', 'اینالاگ', 'اينالاگ', 'تناظري'),
                  selected: current == 'analog',
                  isDark: isDark,
                  onTap: () =>
                      settings.setCircleWidgetStyle('analog'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
