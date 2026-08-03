import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../providers/settings_provider.dart' show SettingsProvider, DarkModeOption;
import '../utils/alert_mode.dart';
import '../utils/app_theme.dart';
import '../screens/about_screen.dart';
import '../screens/notification_health_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/world_prayers_screen.dart';
import 'widget_selection_sheet.dart';
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
                  _PrayerWidgetSection(settings: settings),

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

                  // ── Notification Health ─────────────────────────
                  // A test notification proves the app can show one *now*; this
                  // is the separate question of whether the phone will still
                  // deliver the ones scheduled for hours from now.
                  _DrawerItem(
                    icon: Icons.health_and_safety_outlined,
                    label: settings.translate('Notification Health',
                        'اطلاعات کی حالت', 'اطلاعن جي حالت', 'حالة الإشعارات'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationHealthScreen()),
                      );
                    },
                  ),

                  const _Divider(),

                  // ── Contact Us (inline) ─────────────────────
                  const _ContactUsInline(),

                  const _Divider(),

                  // ── About ───────────────────────────────────
                  // Shown in every mode. The screen itself drops the Jantri
                  // image for a world city and keeps the text, so a traveller
                  // still gets to read what the app is.
                  _DrawerItem(
                    icon: Icons.info_outline_rounded,
                    label: settings.translate(
                        'About Sukkur Salah',
                        'سکھر صلاة کے بارے میں',
                        'سکر صلاة بابت',
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
                        'دوستوں کو سکھر صلاة میں مدعو کریں',
                        'دوستن کي سکر صلاة ۾ دعوت ڏيو',
                        'شارك التطبيق'),
                    onTap: () => _shareApp(context),
                  ),

                  // ── Current Version ───────────────────────────
                  _DrawerItem(
                    icon: Icons.new_releases_rounded,
                    label: '${settings.translate('Current version', 'موجودہ ورژن', 'موجوده ورجن', 'الإصدار الحالي')} ${_version.isNotEmpty ? _version : '1.1.5'}',
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
                    'سکھر صلاة اپنے دوستوں اور خاندان کے ساتھ شیئر کریں',
                    'سکر صلاة پنهنجي دوستن ۽ خاندان سان شيئر ڪريو',
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
                              'سکھر صلاة - سکھر کے نماز کے اوقات۔ ابھی ڈاؤن لوڈ کریں:\nhttps://play.google.com/store/apps/details?id=pk.sukkur.salah',
                              'سکر صلاة - سکر جي نماز جا وقت۔ هينئر ڊائونلوڊ ڪريو:\nhttps://play.google.com/store/apps/details?id=pk.sukkur.salah',
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
    final versionStr = _version.isNotEmpty ? _version : '1.1.5';

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
                  // ── Version 1.1.5 ──────────────────────────────────
                  // Everything since 1.1.3 is still listed: 1.1.4 went out
                  // only hours earlier, so almost every user reaching this
                  // dialog is coming from 1.1.3 and has seen none of it.
                  _buildNewFeatureItem(
                    context,
                    settings,
                    settings.translate(
                      'Complete 16 Line Tajweed Quran',
                      'مکمل ۱۶ سطری تجویدی قرآن',
                      'مڪمل 16 سٽن وارو تجويدي قرآن',
                      'مصحف التجويد الكامل بستة عشر سطرًا',
                    ),
                    settings.translate(
                      'The full colour coded Tajweed Quran is built into the app - all thirty Paras, readable offline, with translation and your reading position remembered.',
                      'مکمل رنگین تجویدی قرآن ایپ میں شامل ہے - تیس کے تیس پارے، انٹرنیٹ کے بغیر پڑھیں، ترجمے کے ساتھ، اور آپ کا صفحہ محفوظ رہتا ہے۔',
                      'مڪمل رنگين تجويدي قرآن ايپ ۾ شامل آهي - ٽيهه ئي پارا، انٽرنيٽ کان سواءِ پڙهو، ترجمي سان، ۽ توهان جو صفحو محفوظ رهي ٿو.',
                      'مصحف التجويد الملون كامل داخل التطبيق - الأجزاء الثلاثون كلها، يُقرأ دون إنترنت، مع الترجمة وحفظ موضع قراءتك.',
                    ),
                    icon: Icons.auto_stories_rounded,
                    iconColor: const Color(0xFF00695C),
                  ),
                  _buildNewFeatureItem(
                    context,
                    settings,
                    settings.translate(
                      'World Prayer Timings for Any City',
                      'دنیا کے کسی بھی شہر کے نماز کے اوقات',
                      'دنيا جي ڪنهن به شهر جا نماز جا وقت',
                      'أوقات الصلاة لأي مدينة في العالم',
                    ),
                    settings.translate(
                      'Search any city in the world, or use your current location, and get its six daily prayer times. You can also pick the calculation method and the Asr juristic method yourself.',
                      'دنیا کے کسی بھی شہر کو تلاش کریں یا اپنا موجودہ مقام استعمال کریں اور وہاں کے چھ نمازوں کے اوقات دیکھیں۔ حساب کا طریقہ اور عصر کا فقہی طریقہ بھی آپ خود منتخب کر سکتے ہیں۔',
                      'دنيا جي ڪنهن به شهر کي ڳوليو يا پنهنجي موجوده جڳهه استعمال ڪريو ۽ اتان جي ڇهن نمازن جا وقت ڏسو. حساب جو طريقو ۽ عصر جو فقهي طريقو به توهان پاڻ چونڊي سگهو ٿا.',
                      'ابحث عن أي مدينة في العالم أو استخدم موقعك الحالي لتحصل على أوقات الصلوات الست فيها. ويمكنك أيضًا اختيار طريقة الحساب ومذهب العصر بنفسك.',
                    ),
                    icon: Icons.travel_explore_rounded,
                    iconColor: const Color(0xFF0277BD),
                  ),
                  _buildNewFeatureItem(
                    context,
                    settings,
                    settings.translate(
                      'Search Any City Instantly',
                      'کوئی بھی شہر فوراً تلاش کریں',
                      'ڪو به شهر فوري طور ڳوليو',
                      'ابحث عن أي مدينة فورًا',
                    ),
                    settings.translate(
                      'Type a single letter and cities appear straight away, each with its country and coordinates. Over two hundred thousand places are built into the app, so the search needs no internet at all.',
                      'ایک حرف لکھتے ہی شہر سامنے آ جاتے ہیں، ہر ایک کے ساتھ اس کا ملک اور نقشے کے مقامات۔ دو لاکھ سے زیادہ مقامات ایپ کے اندر موجود ہیں، اس لیے تلاش کے لیے انٹرنیٹ کی ضرورت نہیں۔',
                      'هڪ اکر لکڻ سان ئي شهر سامهون اچي وڃن ٿا، هر هڪ سان گڏ ان جو ملڪ ۽ نقشي جا نقطا. ٻه لک کان وڌيڪ جڳهون ايپ اندر موجود آهن، ان ڪري ڳولا لاءِ انٽرنيٽ جي ضرورت ناهي.',
                      'اكتب حرفًا واحدًا فتظهر المدن فورًا، ومع كل منها بلدها وإحداثياتها. أكثر من مئتي ألف موقع مضمّنة داخل التطبيق، فلا تحتاج البحث إلى إنترنت.',
                    ),
                    icon: Icons.search_rounded,
                    iconColor: const Color(0xFF0277BD),
                  ),
                  _buildNewFeatureItem(
                    context,
                    settings,
                    settings.translate(
                      'Now Available in Ten Languages',
                      'اب دس زبانوں میں دستیاب',
                      'هاڻي ڏهن ٻولين ۾ دستياب',
                      'متوفر الآن بعشر لغات',
                    ),
                    settings.translate(
                      'The whole app - prayer names, notifications, the monthly schedule and every screen - is available in English, Urdu, Sindhi, Arabic, Turkish, French, Hindi, Bengali, Indonesian and Persian.',
                      'پوری ایپ - نمازوں کے نام، اطلاعات، ماہانہ شیڈیول اور ہر اسکرین - انگریزی، اردو، سندھی، عربی، ترکی، فرانسیسی، ہندی، بنگالی، انڈونیشی اور فارسی میں دستیاب ہے۔',
                      'سڄي ايپ - نمازن جا نالا، اطلاعون، مهينووار شيڊيول ۽ هر اسڪرين - انگريزي، اردو، سنڌي، عربي، ترڪي، فرانسيسي، هندي، بنگالي، انڊونيشي ۽ فارسي ۾ دستياب آهي.',
                      'التطبيق بأكمله - أسماء الصلوات والإشعارات والجدول الشهري وكل شاشة - متاح بالإنجليزية والأردية والسندية والعربية والتركية والفرنسية والهندية والبنغالية والإندونيسية والفارسية.',
                    ),
                    icon: Icons.translate_rounded,
                    iconColor: const Color(0xFF8E24AA),
                  ),
                  _buildNewFeatureItem(
                    context,
                    settings,
                    settings.translate(
                      'World Cities Now Show Their Own Local Time',
                      'دنیا کے شہر اب اپنے مقامی وقت کے مطابق',
                      'دنيا جا شهر هاڻي پنهنجي مقامي وقت مطابق',
                      'مدن العالم تعرض توقيتها المحلي الآن',
                    ),
                    settings.translate(
                      'Prayer times for a selected city were being shown on your own phone\'s clock, which could put them hours out. Every city is now calculated in its own time zone, with summer time handled automatically.',
                      'منتخب شہر کے نماز کے اوقات آپ کے اپنے فون کی گھڑی کے مطابق دکھائے جا رہے تھے، جس سے وہ کئی گھنٹے غلط ہو سکتے تھے۔ اب ہر شہر کا حساب اس کے اپنے ٹائم زون میں ہوتا ہے، اور سمر ٹائم خود بخود شامل ہو جاتا ہے۔',
                      'چونڊيل شهر جا نماز جا وقت توهان جي پنهنجي فون جي گھڙي مطابق ڏيکاريا پيا وڃن، جنهن سان اهي ڪيترائي ڪلاڪ غلط ٿي سگهيا ٿي. هاڻي هر شهر جو حساب سندس پنهنجي ٽائم زون ۾ ٿئي ٿو، ۽ سمر ٽائيم پاڻمرادو شامل ٿئي ٿو.',
                      'كانت أوقات الصلاة للمدينة المختارة تُعرض بساعة هاتفك، ما قد يجعلها خاطئة بساعات. تُحسب كل مدينة الآن بمنطقتها الزمنية، مع مراعاة التوقيت الصيفي تلقائيًا.',
                    ),
                    icon: Icons.public_rounded,
                    iconColor: const Color(0xFF1E88E5),
                  ),
                  _buildNewFeatureItem(
                    context,
                    settings,
                    settings.translate(
                      'Correct Timings for Northern Cities',
                      'شمالی شہروں کے درست اوقات',
                      'اترين شهرن جا درست وقت',
                      'أوقات صحيحة للمدن الشمالية',
                    ),
                    settings.translate(
                      'Cities such as London and Glasgow now use the twilight rule their own mosques follow, and an Isha that falls after midnight is no longer read as midday.',
                      'لندن اور گلاسگو جیسے شہروں میں اب وہی شفق کا اصول استعمال ہوتا ہے جو وہاں کی مساجد اپناتی ہیں، اور آدھی رات کے بعد آنے والی عشاء اب دوپہر نہیں سمجھی جاتی۔',
                      'لنڊن ۽ گلاسگو جهڙن شهرن ۾ هاڻي اهوئي شفق جو اصول استعمال ٿئي ٿو جيڪو اتان جون مسجدون اپنائين ٿيون، ۽ اڌ رات کان پوءِ ايندڙ عشا هاڻي منجهند نه سمجهي ويندي.',
                      'تستخدم مدن مثل لندن وغلاسكو الآن قاعدة الشفق التي تتبعها مساجدها، ولم تعد صلاة العشاء الواقعة بعد منتصف الليل تُقرأ على أنها ظهرًا.',
                    ),
                    icon: Icons.nights_stay_rounded,
                    iconColor: const Color(0xFF5E35B1),
                  ),
                  _buildNewFeatureItem(
                    context,
                    settings,
                    settings.translate(
                      'Works Inside the Arctic Circle Too',
                      'قطبِ شمالی کے علاقوں میں بھی کام کرتا ہے',
                      'قطب شمالي وارن علائقن ۾ به ڪم ڪري ٿو',
                      'يعمل داخل الدائرة القطبية أيضًا',
                    ),
                    settings.translate(
                      'In places like Longyearbyen and Tromso the sun can stay up, or stay down, for weeks, and the app could not show a timetable at all. Those days now follow the nearest workable latitude, as the scholars advise.',
                      'لانگ ایئربین اور ٹرومسو جیسے مقامات پر سورج کئی ہفتوں تک نہ ڈوبتا ہے نہ نکلتا ہے، اور ایپ وہاں اوقات دکھا ہی نہیں سکتی تھی۔ ان دنوں کے لیے اب قریب ترین قابلِ عمل عرض البلد کے مطابق اوقات لیے جاتے ہیں، جیسا کہ علماء کی رہنمائی ہے۔',
                      'لانگ ايئربين ۽ ٽرومسو جهڙن هنڌن تي سج ڪيترائي هفتا نه لهندو آهي نه اڀرندو آهي، ۽ ايپ اتي وقت ڏيکاري ئي نه سگهندي هئي. انهن ڏينهن لاءِ هاڻي ويجهي ۾ ويجهي قابل عمل ويڪرائي ڦاڪ مطابق وقت ورتا وڃن ٿا، جيئن عالمن جي رهنمائي آهي.',
                      'في أماكن مثل لونجيربين وترومسو قد تبقى الشمس طالعة أو غائبة لأسابيع، ولم يكن التطبيق يستطيع عرض جدول أصلًا. تتبع تلك الأيام الآن أقرب خط عرض صالح، وفق ما يرشد إليه أهل العلم.',
                    ),
                    icon: Icons.ac_unit_rounded,
                    iconColor: const Color(0xFF00838F),
                  ),
                  _buildNewFeatureItem(
                    context,
                    settings,
                    settings.translate(
                      'City Names Always Appear',
                      'شہر کا نام ہمیشہ ظاہر',
                      'شهر جو نالو هميشه ظاهر',
                      'اسم المدينة يظهر دائمًا',
                    ),
                    settings.translate(
                      'Some cities, London among them, were saved with a blank name and showed nothing on the Times screen. The name is now always found.',
                      'کچھ شہر، جن میں لندن بھی شامل ہے، خالی نام کے ساتھ محفوظ ہو جاتے تھے اور اوقات کی اسکرین پر کچھ نظر نہیں آتا تھا۔ اب نام ہمیشہ مل جاتا ہے۔',
                      'ڪجهه شهر، جن ۾ لنڊن به شامل آهي، خالي نالي سان محفوظ ٿي ويندا هئا ۽ وقتن جي اسڪرين تي ڪجهه نظر نه ايندو هو. هاڻي نالو هميشه ملي ٿو.',
                      'كانت بعض المدن، ومنها لندن، تُحفظ باسم فارغ فلا يظهر شيء في شاشة الأوقات. أصبح الاسم يُعثر عليه دائمًا الآن.',
                    ),
                    icon: Icons.location_city_rounded,
                    iconColor: const Color(0xFF43A047),
                  ),
                  _buildNewFeatureItem(
                    context,
                    settings,
                    settings.translate(
                      'Choose Your Notification Time Zone',
                      'اطلاع کا ٹائم زون خود منتخب کریں',
                      'اطلاع جو ٽائم زون پاڻ چونڊيو',
                      'اختر المنطقة الزمنية للإشعار',
                    ),
                    settings.translate(
                      'If you follow a city you are not in, you can now choose whether alerts ring at that city\'s real prayer moment or at the time shown on your own clock.',
                      'اگر آپ کسی ایسے شہر کے اوقات دیکھ رہے ہیں جہاں آپ موجود نہیں، تو اب آپ خود طے کر سکتے ہیں کہ اطلاع اس شہر کے اصل وقت پر بجے یا آپ کی اپنی گھڑی کے مطابق۔',
                      'جيڪڏهن توهان اهڙي شهر جا وقت ڏسي رهيا آهيو جتي توهان موجود ناهيو، ته هاڻي توهان پاڻ طئي ڪري سگهو ٿا ته اطلاع ان شهر جي اصل وقت تي وڄي يا توهان جي پنهنجي گھڙي مطابق.',
                      'إذا كنت تتابع مدينة لست فيها، يمكنك الآن اختيار أن يرن التنبيه في وقت الصلاة الحقيقي لتلك المدينة أو في الوقت المعروض على ساعتك.',
                    ),
                    icon: Icons.schedule_rounded,
                    iconColor: const Color(0xFF00897B),
                  ),
                  _buildNewFeatureItem(
                    context,
                    settings,
                    settings.translate(
                      'More Dependable Prayer Alerts',
                      'نماز کی اطلاعات زیادہ قابلِ اعتماد',
                      'نماز جون اطلاعون وڌيڪ ڀروسي جوڳيون',
                      'تنبيهات صلاة أكثر موثوقية',
                    ),
                    settings.translate(
                      'Alerts are now scheduled two weeks ahead and are replaced one by one instead of being cleared first, so the phone is never left with no prayer alerts pending.',
                      'اطلاعات اب دو ہفتے پہلے سے مقرر ہوتی ہیں اور پہلے مٹانے کے بجائے ایک ایک کر کے تبدیل ہوتی ہیں، اس لیے فون کبھی بھی اطلاعات کے بغیر نہیں رہتا۔',
                      'اطلاعون هاڻي ٻه هفتا اڳ ۾ مقرر ٿين ٿيون ۽ پهرين ميٽڻ بدران هڪ هڪ ڪري تبديل ٿين ٿيون، ان ڪري فون ڪڏهن به اطلاعن کان سواءِ نه ٿو رهي.',
                      'تُجدول التنبيهات الآن قبل أسبوعين وتُستبدل واحدًا تلو الآخر بدل مسحها أولًا، فلا يبقى الهاتف دون تنبيهات صلاة معلّقة.',
                    ),
                    icon: Icons.notifications_active_rounded,
                    iconColor: const Color(0xFF3F51B5),
                  ),
                  _buildNewFeatureItem(
                    context,
                    settings,
                    settings.translate(
                      'New Notification Health Screen',
                      'اطلاعات کی حالت کی نئی اسکرین',
                      'اطلاعن جي حالت جي نئين اسڪرين',
                      'شاشة جديدة لحالة الإشعارات',
                    ),
                    settings.translate(
                      'If your phone is set to delay or block prayer alerts, the app now tells you and offers a Fix button for each setting instead of staying silent about it.',
                      'اگر آپ کا فون نماز کی اطلاعات کو دیر یا بند کر رہا ہو تو ایپ اب خاموش رہنے کی بجائے آپ کو بتاتی ہے اور ہر ترتیب کے لیے ٹھیک کرنے کا بٹن دیتی ہے۔',
                      'جيڪڏهن توهان جو فون نماز جون اطلاعون دير يا بند ڪري رهيو هجي ته ايپ هاڻي خاموش رهڻ بدران توهان کي ٻڌائي ٿي ۽ هر ترتيب لاءِ درست ڪرڻ جو بٽڻ ڏئي ٿي.',
                      'إذا كان هاتفك يؤخر تنبيهات الصلاة أو يمنعها، يخبرك التطبيق الآن ويقدم زر إصلاح لكل إعداد بدل أن يصمت.',
                    ),
                    icon: Icons.health_and_safety_rounded,
                    iconColor: const Color(0xFFF9A825),
                  ),
                  _buildNewFeatureItem(
                    context,
                    settings,
                    settings.translate(
                      'Pick Your Home Screen Widget',
                      'اپنا ہوم اسکرین ویجٹ منتخب کریں',
                      'پنهنجو هوم اسڪرين ويجٽ چونڊيو',
                      'اختر أداة الشاشة الرئيسية',
                    ),
                    settings.translate(
                      'A new sheet shows every home screen widget with a picture of it, so you can see how each one looks before adding it.',
                      'ایک نئی فہرست ہر ہوم اسکرین ویجٹ کو اس کی تصویر کے ساتھ دکھاتی ہے، تاکہ آپ لگانے سے پہلے دیکھ سکیں کہ ہر ایک کیسا لگے گا۔',
                      'هڪ نئين فهرست هر هوم اسڪرين ويجٽ کي ان جي تصوير سان ڏيکاري ٿي، ته جيئن توهان لڳائڻ کان اڳ ڏسي سگهو ته هر هڪ ڪيئن لڳندو.',
                      'تعرض قائمة جديدة كل أداة للشاشة الرئيسية مع صورة لها، لترى شكل كل واحدة قبل إضافتها.',
                    ),
                    icon: Icons.dashboard_customize_rounded,
                    iconColor: const Color(0xFF7B1FA2),
                  ),
                  _buildNewFeatureItem(
                    context,
                    settings,
                    settings.translate(
                      'You Will Be Told About New Updates',
                      'نئی اپ ڈیٹ کی اطلاع مل جائے گی',
                      'نئين اپڊيٽ جي اطلاع ملي ويندي',
                      'سيتم إعلامك بالتحديثات الجديدة',
                    ),
                    settings.translate(
                      'When a newer version reaches the Play Store, the app now tells you as soon as you open it, and keeps reminding you until you install it.',
                      'جب پلے اسٹور پر نیا ورژن آ جائے تو ایپ کھولتے ہی آپ کو بتا دیتی ہے، اور جب تک آپ اسے انسٹال نہ کر لیں یاد دلاتی رہتی ہے۔',
                      'جڏهن پلي اسٽور تي نئون ورزن اچي وڃي ته ايپ کولڻ سان ئي توهان کي ٻڌائي ٿي، ۽ جيستائين توهان ان کي انسٽال نه ڪريو ياد ڏياريندي رهي ٿي.',
                      'عندما يصل إصدار أحدث إلى متجر Play، يخبرك التطبيق فور فتحه، ويظل يذكّرك حتى تثبّته.',
                    ),
                    icon: Icons.system_update_rounded,
                    iconColor: const Color(0xFF2E7D32),
                  ),
                  _buildNewFeatureItem(
                    context,
                    settings,
                    settings.translate(
                      'Quran Page Turning Fixed in Every Language',
                      'قرآن کے صفحے ہر زبان میں درست پلٹتے ہیں',
                      'قرآن جا صفحا هر ٻوليءَ ۾ درست ورن ٿا',
                      'تصفح صفحات القرآن صحيح بكل اللغات',
                    ),
                    settings.translate(
                      'In the 16 line Tajweed Quran, swiping right moves to the next page in every language, not only in English.',
                      'سولہ سطری تجویدی قرآن میں دائیں سوائپ کرنے پر اگلا صفحہ اب ہر زبان میں آتا ہے، صرف انگریزی میں نہیں۔',
                      'سورهن سٽن واري تجويدي قرآن ۾ ساڄي پاسي سوائپ ڪرڻ سان ايندڙ صفحو هاڻي هر ٻوليءَ ۾ اچي ٿو، رڳو انگريزيءَ ۾ نه.',
                      'في مصحف التجويد ذي الستة عشر سطرًا، يؤدي السحب يمينًا إلى الصفحة التالية بكل اللغات، لا بالإنجليزية وحدها.',
                    ),
                    icon: Icons.menu_book_rounded,
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
            settings.translate('Sukkur Salah', 'سکھر صلاة', 'سکر صلاة', 'صلاة سكر'),
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

// ── Prayer Widget section ──────────────────────────────────
class _PrayerWidgetSection extends StatelessWidget {
  final SettingsProvider settings;
  const _PrayerWidgetSection({required this.settings});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = settings.isRtl;

    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => WidgetSelectionSheet(
            settings: settings,
            isDark: isDark,
            isRtl: isRtl,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.widgets_rounded,
                color: isDark ? Colors.white54 : Colors.black54, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                settings.translate('Prayer Widgets', 'نماز ویجیٹس', 'نماز ويجيٽس', 'ودجت الصلاة'),
                style: TextStyle(
                  fontSize: isRtl ? 17 : 14,
                  color: isDark ? const Color(0xDEFFFFFF) : Colors.black87,
                ),
              ),
            ),
            Icon(Icons.add_circle_outline,
                color: isDark ? Colors.white38 : Colors.black38,
                size: 20),
          ],
        ),
      ),
    );
  }
}
