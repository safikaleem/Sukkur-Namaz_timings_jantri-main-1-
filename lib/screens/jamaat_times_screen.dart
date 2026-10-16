import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/world_translations.dart';
import '../l10n/world_translations_extra.dart';
import '../providers/settings_provider.dart';
import '../services/jamaat_times_service.dart';
import '../utils/app_theme.dart';

class JamaatTimesScreen extends StatefulWidget {
  const JamaatTimesScreen({super.key});

  @override
  State<JamaatTimesScreen> createState() => _JamaatTimesScreenState();
}

class _JamaatTimesScreenState extends State<JamaatTimesScreen> with WidgetsBindingObserver {
  int _selectedTabIndex = 0; // 0 = Individual Masajid, 1 = Combined Chart
  String _selectedPrayerFilter = 'All'; // 'All', 'Fajr', 'Zuhar', 'Asar', 'Maghrib', 'Isha', 'Jummah'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRemoteTimings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadRemoteTimings();
    }
  }

  Future<bool> _loadRemoteTimings() async {
    final success = await JamaatTimesService.instance.fetchRemoteGistTimings();
    if (mounted) setState(() {});
    return success;
  }

  String _t(
    SettingsProvider settings,
    String key, [
    String? ur,
    String? sd,
    String? ar,
  ]) {
    final lang = settings.language;
    final extraMap = additionalTranslations[lang];
    if (extraMap != null && extraMap.containsKey(key)) {
      return extraMap[key]!;
    }
    final map = worldTranslations[lang];
    if (map != null && map.containsKey(key)) {
      return map[key]!;
    }
    return settings.translate(key, ur ?? key, sd ?? ur ?? key, ar);
  }

  String _getMasjidName(SettingsProvider settings, JamaatMasjidInfo masjid) {
    final lang = settings.language;
    final extraMap = additionalTranslations[lang];
    if (extraMap != null && extraMap.containsKey(masjid.nameKey)) {
      return extraMap[masjid.nameKey]!;
    }
    final map = worldTranslations[lang];
    if (map != null && map.containsKey(masjid.nameKey)) {
      return map[masjid.nameKey]!;
    }
    final dynamicName = masjid.getNameFor(lang);
    if (dynamicName.isNotEmpty && dynamicName != masjid.nameKey) {
      return dynamicName;
    }
    return settings.translate(
      masjid.nameKey,
      masjid.getNameFor('urdu'),
      masjid.getNameFor('sindhi'),
      masjid.getNameFor('arabic'),
    );
  }

  String _getMasjidAddress(SettingsProvider settings, JamaatMasjidInfo masjid) {
    final lang = settings.language;
    final extraMap = additionalTranslations[lang];
    if (extraMap != null && extraMap.containsKey(masjid.addressKey)) {
      return extraMap[masjid.addressKey]!;
    }
    final map = worldTranslations[lang];
    if (map != null && map.containsKey(masjid.addressKey)) {
      return map[masjid.addressKey]!;
    }
    final dynamicAddress = masjid.getAddressFor(lang);
    if (dynamicAddress.isNotEmpty && dynamicAddress != masjid.addressKey) {
      return dynamicAddress;
    }
    return settings.translate(
      masjid.addressKey,
      masjid.getAddressFor('urdu'),
      masjid.getAddressFor('sindhi'),
      masjid.getAddressFor('arabic'),
    );
  }

  String _getPrayerDisplayName(SettingsProvider settings, String nameKey) {
    final lang = settings.language;
    final name = _t(settings, nameKey);
    if (lang == 'english') {
      const urduMap = {
        'Fajr': 'فجر',
        'Fajar': 'فجر',
        'Zuhar': 'ظہر',
        'Zuhr': 'ظہر',
        'Asar': 'عصر',
        'Asr': 'عصر',
        'Maghrib': 'مغرب',
        'Isha': 'عشاء',
        'Jummah': 'جمعہ',
      };
      final urdu = urduMap[nameKey];
      if (urdu != null) {
        return '$name ($urdu)';
      }
    }
    return name;
  }

  Map<String, String> _getJamaatNoticeNote(String lang) {
    switch (lang) {
      case 'urdu':
        return {
          'prefix': 'نوٹ:',
          'body':
              'مسجد کی جانب سے جماعت کے اوقات کی بروقت اطلاع موصول نہ ہونے کی صورت میں درج شدہ اوقات اور اصل اوقاتِ جماعت میں فرق ہو سکتا ہے۔ جماعت کے اوقات کی تبدیلی کی صورت میں اس کے اطلاق کی تاریخ درج کی جاتی ہے۔',
        };
      case 'sindhi':
        return {
          'prefix': 'نوٽ:',
          'body':
              'مسجد طرفان جماعت جي وقتن جي بروقت اطلاع نه ملڻ جي صورت ۾ لکيل وقتن ۽ اصل جماعت جي وقتن ۾ فرق ٿي سگهي ٿو. جماعت جي وقتن جي تبديليءَ جي صورت ۾ ان جي لاڳو ٿيڻ جي تاريخ لکي ويندي آهي.',
        };
      case 'arabic':
        return {
          'prefix': 'ملاحظة:',
          'body':
              'في حال عدم استلام تحديثات في الوقت المناسب من المسجد بشأن أوقات صلاة الجماعة، قد تختلف الأوقات المنشورة عن أوقات الجماعة الفعلية. وكلما تغير جدول الجماعة، سيتم تحديد تاريخ سريان التغيير.',
        };
      case 'indonesian':
        return {
          'prefix': 'Catatan:',
          'body':
              'Jika pembaruan tepat waktu mengenai waktu salat berjamaah tidak diterima dari Masjid, waktu yang dipublikasikan mungkin berbeda dari waktu salat berjamaah sebenarnya. Setiap kali jadwal salat berjamaah diubah, tanggal berlakunya perubahan akan dicantumkan.',
        };
      case 'french':
        return {
          'prefix': 'Remarque :',
          'body':
              'Si des mises à jour opportunes concernant les horaires de prière en Jama\'at ne sont pas reçues de la mosquée, les horaires publiés peuvent différer des horaires réels de la Jama\'at. Chaque fois que l\'horaire de la Jama\'at est modifié, la date d\'effet du changement sera indiquée.',
        };
      case 'hindi':
        return {
          'prefix': 'नोट:',
          'body':
              'यदि मस्जिद से जमात की नमाज़ के समय के बारे में समय पर अपडेट प्राप्त नहीं होते हैं, तो प्रकाशित समय वास्तविक जमात के समय से भिन्न हो सकता है। जब भी जमात के समय में बदलाव होगा, बदलाव के प्रभावी होने की तारीख दर्शाई जाएगी।',
        };
      case 'persian':
        return {
          'prefix': 'یادداشت:',
          'body':
              'در صورتی که به‌روزرسانی‌های به‌موقع در مورد اوقات نماز جماعت از سوی مسجد دریافت نشود، ممکن است اوقات اعلام‌شده با اوقات واقعی جماعت متفاوت باشد. هر زمان که برنامه جماعت تغییر کند، تاریخ اعمال تغییر مشخص خواهد شد.',
        };
      case 'turkish':
        return {
          'prefix': 'Not:',
          'body':
              'Mescitten cemaatle namaz vakitlerine ilişkin zamanında güncelleme alınmaması durumunda, yayınlanan vakitler gerçek cemaat vakitlerinden farklı olabilir. Cemaat programı her değiştiğinde, değişikliğin geçerlilik tarihi belirtilecektir.',
        };
      case 'bengali':
        return {
          'prefix': 'নোট:',
          'body':
              'মসজিদ থেকে জামাতের নামাজের সময় সম্পর্কিত সময়োপযোগী আপডেট না পাওয়া গেলে, প্রকাশিত সময়সূচী প্রকৃত জামাতের সময় থেকে ভিন্ন হতে পারে। যখনই জামাতের সময়সূচী পরিবর্তিত হবে, পরিবর্তনের কার্যকরের তারিখ নির্দেশ করা হবে।',
        };
      case 'english':
      default:
        return {
          'prefix': 'Note:',
          'body':
              'If timely updates regarding Jama\'at prayer times are not received from the Masjid, the published timings may differ from the actual Jama\'at times. Whenever the Jama\'at schedule is changed, the effective date of the change will be indicated.',
        };
    }
  }

  String _getIndividualTabTitle(SettingsProvider settings) {
    switch (settings.language) {
      case 'urdu':
        return 'انفرادی مساجد';
      case 'sindhi':
        return 'انفرادي مساجد';
      case 'arabic':
        return 'المساجد الفردية';
      case 'indonesian':
        return 'Masjid Individual';
      case 'turkish':
        return 'Bireysel Camiler';
      case 'bengali':
        return 'ব্যক্তিগত মসজিদ';
      case 'persian':
        return 'مساجد انفرادی';
      case 'hindi':
        return 'व्यक्तिगत मस्जिदें';
      case 'french':
        return 'Mosquées individuelles';
      default:
        return 'Individual Masajid';
    }
  }

  String _getCombinedTabTitle(SettingsProvider settings) {
    switch (settings.language) {
      case 'urdu':
        return 'مشترکہ چارٹ';
      case 'sindhi':
        return 'ملايل چارٽ';
      case 'arabic':
        return 'الجدول المشترك';
      case 'indonesian':
        return 'Bagan Gabungan';
      case 'turkish':
        return 'Birleşik Çizelge';
      case 'bengali':
        return 'সম্মিলিত চার্ট';
      case 'persian':
        return 'جدول ترکیبی';
      case 'hindi':
        return 'संयुक्त चार्ट';
      case 'french':
        return 'Tableau combiné';
      default:
        return 'Combined Chart';
    }
  }

  String _getCombinedSubtext(SettingsProvider settings) {
    switch (settings.language) {
      case 'urdu':
        return 'تمام مساجد کے باجماعت نمازوں کے اوقات ترتیب وار دیکھیں۔';
      case 'sindhi':
        return 'سڀني مساجدن جي باجماعت نمازن جا وقت ترتيب سان ڏسو.';
      case 'arabic':
        return 'عرض مواقيت صلاة الجماعة مرتبة زمنيًا لجميع المساجد.';
      case 'indonesian':
        return 'Lihat waktu shalat berjamaah yang diurutkan secara kronologis untuk semua Masjid.';
      case 'turkish':
        return 'Tüm Camiler için kronologique olarak sıralanmış cemaat namazı vakitlerini görüntüleyin.';
      case 'bengali':
        return 'সকল মসজিদের জামায়াতের নামাজের সময় ক্রমানুসারে দেখুন।';
      case 'persian':
        return 'نمایش زمان‌های نماز جماعت به ترتیب زمانی برای همه مساجد.';
      case 'hindi':
        return 'सभी मस्जिदों के लिए क्रमानुसार सामूहिक प्रार्थना के समय देखें।';
      case 'french':
        return 'Affichez les heures de prière en congrégation classées par ordre chronologique pour toutes les mosquées.';
      default:
        return 'View congregational prayer times sorted chronologically for all Masajid.';
    }
  }

  String _getMasajidLabel(SettingsProvider settings) {
    switch (settings.language) {
      case 'urdu':
        return 'مساجد';
      case 'sindhi':
        return 'مساجدون';
      case 'arabic':
        return 'المساجد';
      case 'hindi':
        return 'मस्जिदें';
      case 'indonesian':
        return 'Masjid';
      case 'turkish':
        return 'Camiler';
      case 'bengali':
        return 'মসজিদ';
      case 'persian':
        return 'مساجد';
      case 'french':
        return 'Mosquées';
      default:
        return 'Masajid';
    }
  }

  int _parseTimeToMinutes(String timeStr) {
    final clean = timeStr.trim();
    final lower = clean.toLowerCase();
    if (lower.contains('sunset') || clean.contains('غروب')) {
      return 18 * 60 + 30; // ~6:30 PM default for Maghrib sorting
    }

    final regExp = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM|am|pm)?');
    final match = regExp.firstMatch(clean);
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      final period = match.group(3)?.toUpperCase();

      if (period == 'PM' && hour < 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }
      return hour * 60 + minute;
    }
    return 9999;
  }

  String _getJamaatTimesUpdatedMessage(SettingsProvider settings) {
    switch (settings.language) {
      case 'urdu':
        return 'اوقاتِ جماعت تازہ ہو گئے';
      case 'sindhi':
        return 'جماعت جا وقت تازه ٿي ويا';
      case 'arabic':
        return 'تم تحديث مواقيت الجماعة';
      case 'indonesian':
        return 'Waktu jamaah telah diperbarui';
      case 'turkish':
        return 'Cemaat vakitleri güncellendi';
      case 'bengali':
        return 'জামাতের সময় আপডেট হয়েছে';
      case 'persian':
        return 'اوقات جماعت به‌روزرسانی شد';
      case 'hindi':
        return 'जमाअत का समय अपडेट हो गया';
      case 'french':
        return 'Horaires de la prière en groupe mis à jour';
      default:
        return "Jama'at times updated";
    }
  }

  String _getJamaatTimesFailedMessage(SettingsProvider settings) {
    switch (settings.language) {
      case 'urdu':
        return 'اوقاتِ جماعت تازہ نہ ہو سکے، انٹرنیٹ چیک کریں';
      case 'sindhi':
        return 'جماعت جا وقت تازه نه ٿي سگهيا، انٽرنيٽ چيڪ ڪريو';
      case 'arabic':
        return 'تعذر تحديث مواقيت الجماعة، تحقق من الاتصال';
      case 'indonesian':
        return 'Gagal memperbarui waktu jamaah, periksa koneksi';
      case 'turkish':
        return 'Cemaat vakitleri güncellenemedi, bağlantıyı kontrol edin';
      case 'bengali':
        return 'জামাতের সময় আপডেট করা যায়নি, ইন্টারনেট পরীক্ষা করুন';
      case 'persian':
        return 'به‌روزرسانی اوقات جماعت ناموفق بود، اینترنت را بررسی کنید';
      case 'hindi':
        return 'जमाअत का समय अपडेट नहीं हो सका, इंटरनेट जांचें';
      case 'french':
        return 'Échec de la mise à jour des horaires, vérifiez la connexion';
      default:
        return "Could not update Jama'at times. Check connection";
    }
  }

  String _getRefreshTimingsTooltip(SettingsProvider settings) {
    switch (settings.language) {
      case 'urdu':
        return 'اوقات تازہ کریں';
      case 'sindhi':
        return 'وقت تازه ڪريو';
      case 'arabic':
        return 'تحديث المواقيت';
      case 'indonesian':
        return 'Perbarui Waktu';
      case 'turkish':
        return 'Vakitleri Güncelle';
      case 'bengali':
        return 'সময় আপডেট করুন';
      case 'persian':
        return 'به‌روزرسانی اوقات';
      case 'hindi':
        return 'समय अपडेट करें';
      case 'french':
        return 'Actualiser les horaires';
      default:
        return 'Refresh Timings';
    }
  }

  void _showJamaatTableModal(
    BuildContext context,
    JamaatMasjidInfo masjid,
    SettingsProvider settings,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = settings.language;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isRefreshing = false;
        bool isPopping = false;
        final modalScrollController = ScrollController();
        double dragStartX = 0.0;
        double dragStartY = 0.0;
        bool canDismissFromTop = false;

        void safePop() {
          if (!isPopping && ctx.mounted) {
            isPopping = true;
            Navigator.of(ctx).pop();
          }
        }

        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final timing = JamaatTimesService.instance.getTimingFor(masjid);
            return Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (event) {
                dragStartX = event.position.dx;
                dragStartY = event.position.dy;
                // If modal is at the very top (Screenshot 2 state), allow downward swipe to dismiss.
                // If modal is scrolled down (Screenshot 1 state: offset > 1.0), do NOT allow dismiss;
                // downward swipe will only scroll the content back up to the top!
                if (modalScrollController.hasClients) {
                  canDismissFromTop = modalScrollController.offset <= 1.0;
                } else {
                  canDismissFromTop = true;
                }
              },
              onPointerMove: (event) {
                if (isPopping) return;
                final deltaX = (event.position.dx - dragStartX).abs();
                final deltaY = event.position.dy - dragStartY;

                // When user scrolls down the list (swiping finger up), cancel top dismiss
                if (modalScrollController.hasClients && modalScrollController.offset > 1.0) {
                  canDismissFromTop = false;
                }

                // Only close if started at the top (Screenshot 2) and dragging downwards vertically
                if (canDismissFromTop && deltaY > 40 && deltaY > deltaX) {
                  final currentOffset = modalScrollController.hasClients ? modalScrollController.offset : 0.0;
                  if (currentOffset <= 1.0) {
                    safePop();
                  } else {
                    canDismissFromTop = false;
                  }
                }
              },
              onPointerUp: (event) {
                if (isPopping) return;
                final deltaX = (event.position.dx - dragStartX).abs();
                final deltaY = event.position.dy - dragStartY;
                if (canDismissFromTop && deltaY > 25 && deltaY > deltaX) {
                  final currentOffset = modalScrollController.hasClients ? modalScrollController.offset : 0.0;
                  if (currentOffset <= 1.0) {
                    safePop();
                  }
                }
                canDismissFromTop = false;
              },
              onPointerCancel: (_) {
                canDismissFromTop = false;
              },
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.9,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A2224) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Drag Handle Area ─────────────────────────
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragUpdate: (details) {
                          if (details.primaryDelta != null && details.primaryDelta! > 4) {
                            if (modalScrollController.hasClients && modalScrollController.offset > 1.0) {
                              modalScrollController.animateTo(
                                0,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              );
                            } else {
                              safePop();
                            }
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(top: 12, bottom: 14),
                          alignment: Alignment.center,
                          child: Container(
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white30 : Colors.black26,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),

                      // ── Scrollable Content Area ──────────────────
                      Flexible(
                        child: SingleChildScrollView(
                          controller: modalScrollController,
                          physics: const ClampingScrollPhysics(),
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(ctx).padding.bottom + 16,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                // ── Header Card ──────────────────────────────────────
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E282A), const Color(0xFF151C1E)]
                        : [const Color(0xFF1B4332), const Color(0xFF2D6A4F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.black : const Color(0xFF1B4332))
                          .withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.access_time_filled_rounded,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getMasjidName(settings, masjid),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily:
                                  AppTheme.getFontForLanguage(context, lang),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getMasjidAddress(settings, masjid),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: isRefreshing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(
                              Icons.refresh_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                      tooltip: _getRefreshTimingsTooltip(settings),
                      onPressed: isRefreshing
                          ? null
                          : () async {
                              setModalState(() => isRefreshing = true);
                              final success = await JamaatTimesService.instance.fetchRemoteGistTimings();
                              if (context.mounted) {
                                setState(() {});
                              }
                              if (modalCtx.mounted) {
                                setModalState(() => isRefreshing = false);
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: success
                                        ? const Color(0xFF1B4332)
                                        : const Color(0xFFB00020),
                                    content: Text(
                                      success
                                          ? _getJamaatTimesUpdatedMessage(settings)
                                          : _getJamaatTimesFailedMessage(settings),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: AppTheme.getFontForLanguage(
                                          context,
                                          settings.language,
                                        ),
                                      ),
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                    ),
                    IconButton(
                      icon: Icon(
                        settings.favoriteMasjidId == masjid.id
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: settings.favoriteMasjidId == masjid.id
                            ? const Color(0xFFE5C158)
                            : Colors.white60,
                        size: 28,
                      ),
                      tooltip: _t(
                        settings,
                        'Set as Favorite Masjid for Jama\'at Alarms',
                        'باجماعت الارم کے لیے پسندیدہ مسجد مقرر کریں',
                        'باجماعت الارم لاءِ پسنديده مسجد مقرر ڪريو',
                        'تعيين كمسجد مفضل لمنبهات صلاة الجماعة',
                      ),
                      onPressed: () {
                        final isRemoving = settings.favoriteMasjidId == masjid.id;
                        settings.setFavoriteMasjidId(masjid.id);
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isRemoving
                                  ? _t(
                                      settings,
                                      'Removed from Favorite Masjids',
                                      'پسندیدہ مساجد سے ہٹا دیا گیا',
                                      'پسنديده مساجد مان هٽايو ويو',
                                      'تمت الإزالة من المساجد المفضلة',
                                    )
                                  : _t(
                                      settings,
                                      'Saved as Favorite Masjid for Jama\'at Alarms',
                                      'باجماعت نماز الارم کے لیے پسندیدہ مسجد منتخب ہو گئی',
                                      'باجماعت نماز الارم لاءِ پسنديده مسجد محفوظ ٿي وئي',
                                      'تم الحفظ كمسجد مفضل لمنبهات صلاة الجماعة',
                                    ),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Report Timing Difference Bar ──────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _reportTimingUpdate(context, settings, masjid, timing),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E282A)
                            : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF2E7D32).withValues(alpha: 0.4)
                              : const Color(0xFF1B4332).withValues(alpha: 0.25),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B4332).withValues(alpha: isDark ? 0.4 : 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              size: 18,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _t(
                                    settings,
                                    'Timing difference? Report to developer',
                                    'اوقات میں فرق ہے؟ تصویر/اطلاع بھیجیں',
                                    'وقتن ۾ فرق آهي؟ تصوير/اطلاع موڪليو',
                                    'اختلاف في المواقيت؟ أبلغ المطور',
                                  ),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: AppTheme.getFontForLanguage(context, lang),
                                    color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B4332),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _t(
                                    settings,
                                    'Tap to email clock photo or updated time',
                                    'گھڑی کی تصویر یا نیا وقت ای میل کرنے کے لیے ٹیپ کریں',
                                    'ڪلاڪ جي تصوير يا نئون وقت اي ميل ڪرڻ لاءِ ٽيپ ڪريو',
                                    'انقر لإرسال صورة الساعة أو الوقت الجديد',
                                  ),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: AppTheme.getFontForLanguage(context, lang),
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.mail_outline_rounded,
                            size: 18,
                            color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B4332),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ── Jama'at Timing Notice ─────────────────────────────
              Builder(
                builder: (context) {
                  final notice = _getJamaatNoticeNote(lang);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E282A).withValues(alpha: 0.7)
                            : const Color(0xFFF4F8F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF81C784).withValues(alpha: 0.25)
                              : const Color(0xFF1B4332).withValues(alpha: 0.18),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: isDark
                                  ? const Color(0xFF81C784)
                                  : const Color(0xFF1B4332),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${notice['prefix']} ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? const Color(0xFF81C784)
                                          : const Color(0xFF1B4332),
                                    ),
                                  ),
                                  TextSpan(
                                    text: notice['body'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1.45,
                                fontFamily: AppTheme.getFontForLanguage(context, lang),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              // ── Prayer Timings Table ──────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF222C2E)
                        : const Color(0xFFF7F9FA),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Table Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B4332).withValues(alpha: 0.12),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(17)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _t(settings, 'Prayer Name', 'نماز کا نام',
                                    'نماز جو نالو', 'اسم الصلاة'),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? const Color(0xFF81C784)
                                      : const Color(0xFF1B4332),
                                  fontFamily: AppTheme.getFontForLanguage(
                                      context, lang),
                                ),
                              ),
                            ),
                            Text(
                              _t(settings, 'Jama\'at Time', 'جماعت کا وقت',
                                  'جماعت جو وقت', 'وقت الجماعة'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? const Color(0xFF81C784)
                                    : const Color(0xFF1B4332),
                                fontFamily:
                                    AppTheme.getFontForLanguage(context, lang),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // Prayer Rows (Fajr, Zuhar, Asar, Maghrib, Isha, Jummah)
                      _buildPrayerTableRow(
                        context,
                        settings,
                        nameKey: 'Fajr',
                        customNote: timing.getNoteFor('Fajr', lang).isNotEmpty
                            ? timing.getNoteFor('Fajr', lang)
                            : null,
                        time: timing.fajr,
                        lastUpdated: timing.fajrUpdated,
                        icon: Icons.wb_twilight_rounded,
                        isDark: isDark,
                      ),
                      const Divider(height: 1),
                      _buildPrayerTableRow(
                        context,
                        settings,
                        nameKey: 'Zuhar',
                        subNoteKey: timing.zuharUpdated.trim().isEmpty ? 'Fixed' : null,
                        customNote: timing.getNoteFor('Zuhar', lang).isNotEmpty
                            ? timing.getNoteFor('Zuhar', lang)
                            : null,
                        time: timing.zuhar,
                        lastUpdated: timing.zuharUpdated,
                        icon: Icons.wb_sunny_rounded,
                        isDark: isDark,
                      ),
                      const Divider(height: 1),
                      _buildPrayerTableRow(
                        context,
                        settings,
                        nameKey: 'Asar',
                        customNote: timing.getNoteFor('Asar', lang).isNotEmpty
                            ? timing.getNoteFor('Asar', lang)
                            : null,
                        time: timing.asar,
                        lastUpdated: timing.asarUpdated,
                        icon: Icons.wb_cloudy_rounded,
                        isDark: isDark,
                      ),
                      const Divider(height: 1),
                      _buildPrayerTableRow(
                        context,
                        settings,
                        nameKey: 'Maghrib',
                        subNoteKey: 'According to daily Maghrib time',
                        customNote: timing.getNoteFor('Maghrib', lang).isNotEmpty
                            ? timing.getNoteFor('Maghrib', lang)
                            : null,
                        time: timing.maghrib,
                        lastUpdated: '',
                        icon: Icons.nights_stay_rounded,
                        isDark: isDark,
                      ),
                      const Divider(height: 1),
                      _buildPrayerTableRow(
                        context,
                        settings,
                        nameKey: 'Isha',
                        customNote: timing.getNoteFor('Isha', lang).isNotEmpty
                            ? timing.getNoteFor('Isha', lang)
                            : null,
                        time: timing.isha,
                        lastUpdated: timing.ishaUpdated,
                        icon: Icons.bedtime_rounded,
                        isDark: isDark,
                      ),
                      const Divider(height: 1),
                      _buildPrayerTableRow(
                        context,
                        settings,
                        nameKey: 'Jummah',
                        subNoteKey: timing.jummahUpdated.trim().isEmpty ? 'Fixed' : null,
                        customNote: timing.getNoteFor('Jummah', lang).isNotEmpty
                            ? timing.getNoteFor('Jummah', lang)
                            : null,
                        time: timing.jummah,
                        lastUpdated: timing.jummahUpdated,
                        icon: Icons.star_rounded,
                        isDark: isDark,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),

                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
  }

  Future<void> _reportTimingUpdate(
    BuildContext context,
    SettingsProvider settings,
    JamaatMasjidInfo masjid,
    JamaatTiming timing,
  ) async {
    final masjidName = _getMasjidName(settings, masjid);
    final masjidAddress = _getMasjidAddress(settings, masjid);
    final subject = '[Jama\'at Time Update] $masjidName, Sukkur';
    final body = '''Assalam-o-Alaikum,

Masjid: $masjidName
Address: $masjidAddress

Current App Timings:
- Fajr: ${timing.fajr}
- Zuhar: ${timing.zuhar}
- Asar: ${timing.asar}
- Maghrib: ${timing.maghrib}
- Isha: ${timing.isha}
- Jummah: ${timing.jummah}

Correct / Updated Timings:
- Fajr: 
- Zuhar: 
- Asar: 
- Maghrib: 
- Isha: 
- Jummah: 

(Please attach a photo of the Masjid clock/board if possible)

JazakAllah Khair
''';

    const email = 'mmsafiullah@yahoo.com';
    final emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final gmailUri = Uri.parse(
          'intent://compose?to=$email&subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}#Intent;scheme=mailto;package=com.google.android.gm;end',
        );
        if (await canLaunchUrl(gmailUri)) {
          await launchUrl(gmailUri, mode: LaunchMode.externalApplication);
          return;
        }
      }
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(emailUri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Could not launch email: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t(
                settings,
                'Please email update to mmsafiullah@yahoo.com',
                'براہ کرم نیا وقت mmsafiullah@yahoo.com پر ای میل کریں',
                'مهرباني ڪري نئون وقت mmsafiullah@yahoo.com تي اي ميل ڪريو',
                'يرجى إرسال التحديث إلى mmsafiullah@yahoo.com',
              ),
            ),
          ),
        );
      }
    }
  }

  Widget _buildPrayerTableRow(
    BuildContext context,
    SettingsProvider settings, {
    required String nameKey,
    String? subNoteKey,
    String? customNote,
    required String time,
    required String lastUpdated,
    required IconData icon,
    required bool isDark,
    bool isLast = false,
  }) {
    final lang = settings.language;
    String getPrayerDisplayName() {
      return _getPrayerDisplayName(settings, nameKey);
    }

    final bool hasCustomNote = customNote != null && customNote.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: const Color(0xFF2D6A4F),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  getPrayerDisplayName(),
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: AppTheme.getFontForLanguage(context, lang),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 95,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B4332).withValues(alpha: isDark ? 0.25 : 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF1B4332).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        time,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B4332),
                        ),
                      ),
                    ),
                  ),
                  if (!hasCustomNote) ...[
                    const SizedBox(height: 3),
                    Text(
                      subNoteKey != null
                          ? '(${_t(settings, subNoteKey)})'
                          : '${_t(settings, "Last Updated")}: \u200E${JamaatTiming.normalizeDate(lastUpdated)}\u200E',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark ? Colors.white70 : Colors.grey[700],
                        fontFamily: AppTheme.getFontForLanguage(context, lang),
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (hasCustomNote) ...[
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                customNote,
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? const Color(0xFFA5D6A7) : const Color(0xFF1B4332),
                  fontFamily: AppTheme.getFontForLanguage(context, lang),
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = settings.language;
    const accent = Color(0xFF1B4332);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121619) : const Color(0xFFF4F6F8),
      appBar: AppBar(
        centerTitle: true,
        leading: const SizedBox(width: 56),
        leadingWidth: 56,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white70 : Colors.black87,
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _t(
              settings,
              'Masajid Jama\'at Times (Sukkur)',
              'اوقاتِ جماعتِ مساجد (سکھر)',
              'مساجدن جي جماعت جا وقت (سکر)',
              'مواقيت الجماعة للمساجد (سَكَر)',
            ),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: settings.isRtl ? 20 : 17,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: _getRefreshTimingsTooltip(settings),
            onPressed: () async {
              final success = await _loadRemoteTimings();
              if (context.mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: success
                        ? const Color(0xFF1B4332)
                        : const Color(0xFFB00020),
                    content: Text(
                      success
                          ? _getJamaatTimesUpdatedMessage(settings)
                          : _getJamaatTimesFailedMessage(settings),
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: AppTheme.getFontForLanguage(
                          context,
                          settings.language,
                        ),
                      ),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        color: const Color(0xFF1B4332),
        onRefresh: _loadRemoteTimings,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
          children: [
            // ── Main Header Card ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E282A), const Color(0xFF151C1E)]
                      : [const Color(0xFF1B4332), const Color(0xFF2D6A4F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : accent).withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Lansdowne Bridge Featured Image
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/landsdowne_bridge.jpg'),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _t(
                      settings,
                      'Masajid Jama\'at Times (Sukkur)',
                      'اوقاتِ جماعتِ مساجد (سکھر)',
                      'مساجدن جي جماعت جا وقت (سکر)',
                      'مواقيت الجماعة للمساجد (سَكَر)',
                    ),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: AppTheme.getFontForLanguage(context, lang),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedTabIndex == 0
                        ? _t(
                            settings,
                            'Tap any Masjid below to view complete congregational (Jama\'at) prayer timings.',
                            'باجماعت نمازوں کے مکمل اوقات دیکھنے کے لیے ذیل میں کسی بھی مسجد پر ٹیپ کریں۔',
                            'باجماعت نمازن جا مڪمل وقت ڏسڻ لاءِ هيٺ ڏنل ڪنهن به مسجد تي ٽيپ ڪريو.',
                            'انقر على أي مسجد أعلاه لعرض مواقيت صلاة الجماعة الكاملة.',
                          )
                        : _getCombinedSubtext(settings),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ── Segmented Tab Selector (Individual Masajid vs Combined Chart) ──
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E2628)
                    : const Color(0xFFE8ECEF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF1B4332)
                      .withValues(alpha: isDark ? 0.3 : 0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTabIndex = 0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 0
                              ? const Color(0xFF1B4332)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _selectedTabIndex == 0
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF1B4332)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _getIndividualTabTitle(settings),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _selectedTabIndex == 0
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black87),
                            fontFamily:
                                AppTheme.getFontForLanguage(context, lang),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTabIndex = 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 1
                              ? const Color(0xFF1B4332)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _selectedTabIndex == 1
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF1B4332)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _getCombinedTabTitle(settings),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _selectedTabIndex == 1
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black87),
                            fontFamily:
                                AppTheme.getFontForLanguage(context, lang),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ── View Content: Individual List or Combined Chart ───────
            if (_selectedTabIndex == 1) ...[
              _buildPrayerFilterBar(context, settings, isDark, lang),
              const SizedBox(height: 16),
            ],

            if (_selectedTabIndex == 0)
              ..._buildIndividualMasajidList(context, settings, isDark, lang)
            else
              ..._buildCombinedChartView(context, settings, isDark, lang),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildPrayerFilterBar(
    BuildContext context,
    SettingsProvider settings,
    bool isDark,
    String lang,
  ) {
    final filterItems = [
      {'key': 'All', 'icon': Icons.grid_view_rounded},
      {'key': 'Fajr', 'icon': Icons.wb_twilight_rounded},
      {'key': 'Zuhar', 'icon': Icons.wb_sunny_rounded},
      {'key': 'Asar', 'icon': Icons.wb_cloudy_rounded},
      {'key': 'Maghrib', 'icon': Icons.nights_stay_rounded},
      {'key': 'Isha', 'icon': Icons.bedtime_rounded},
      {'key': 'Jummah', 'icon': Icons.star_rounded},
    ];

    String getPrayerFilterLabel(String key) {
      if (key == 'All') {
        switch (lang) {
          case 'urdu':
            return 'تمام نمازیں';
          case 'sindhi':
            return 'سڀ نمازون';
          case 'arabic':
            return 'جميع الصلوات';
          case 'indonesian':
            return 'Semua Shalat';
          case 'turkish':
            return 'Tüm Namazlar';
          case 'bengali':
            return 'সব নামায';
          case 'persian':
            return 'همه نمازها';
          case 'hindi':
            return 'सभी प्रार्थनाएं';
          case 'french':
            return 'Toutes les prières';
          default:
            return 'All Prayers';
        }
      }
      return _getPrayerDisplayName(settings, key);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final item in filterItems)
            GestureDetector(
              onTap: () => setState(
                  () => _selectedPrayerFilter = item['key'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _selectedPrayerFilter == item['key']
                      ? const Color(0xFF1B4332)
                      : (isDark ? const Color(0xFF1E2628) : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _selectedPrayerFilter == item['key']
                        ? const Color(0xFF1B4332)
                        : (isDark ? Colors.white24 : Colors.black12),
                    width: 1.2,
                  ),
                  boxShadow: _selectedPrayerFilter == item['key']
                      ? [
                          BoxShadow(
                            color: const Color(0xFF1B4332)
                                .withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 16,
                      color: _selectedPrayerFilter == item['key']
                          ? Colors.white
                          : (isDark
                              ? const Color(0xFF81C784)
                              : const Color(0xFF1B4332)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      getPrayerFilterLabel(item['key'] as String),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _selectedPrayerFilter == item['key']
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: _selectedPrayerFilter == item['key']
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                        fontFamily: AppTheme.getFontForLanguage(context, lang),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildIndividualMasajidList(
    BuildContext context,
    SettingsProvider settings,
    bool isDark,
    String lang,
  ) {
    final list = JamaatTimesService.instance.getMasjidList();
    return [
      for (final masjid in list)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildMasjidJamaatBar(
            context: context,
            settings: settings,
            masjid: masjid,
            isDark: isDark,
            lang: lang,
            onTap: () => _showJamaatTableModal(
              context,
              masjid,
              settings,
            ),
          ),
        ),
    ];
  }

  List<Widget> _buildCombinedChartView(
    BuildContext context,
    SettingsProvider settings,
    bool isDark,
    String lang,
  ) {
    final allMasajid = JamaatTimesService.instance.getMasjidList();
    final prayers = [
      {
        'key': 'Fajr',
        'icon': Icons.wb_twilight_rounded,
      },
      {
        'key': 'Zuhar',
        'icon': Icons.wb_sunny_rounded,
      },
      {
        'key': 'Asar',
        'icon': Icons.wb_cloudy_rounded,
      },
      {
        'key': 'Maghrib',
        'icon': Icons.nights_stay_rounded,
      },
      {
        'key': 'Isha',
        'icon': Icons.bedtime_rounded,
      },
      {
        'key': 'Jummah',
        'icon': Icons.star_rounded,
      },
    ];

    final activePrayers = _selectedPrayerFilter == 'All'
        ? prayers
        : prayers.where((p) => p['key'] == _selectedPrayerFilter).toList();

    String getPrayerDisplayName(String nameKey) {
      return _getPrayerDisplayName(settings, nameKey);
    }

    final widgets = <Widget>[];

    for (final p in activePrayers) {
      final pKey = p['key'] as String;
      final icon = p['icon'] as IconData;

      // Group masajid by their time for this prayer
      final timeMap = <String, List<JamaatMasjidInfo>>{};

      for (final masjid in allMasajid) {
        final timing = JamaatTimesService.instance.getTimingFor(masjid);
        String timeVal;
        switch (pKey) {
          case 'Fajr':
            timeVal = timing.fajr;
            break;
          case 'Zuhar':
            timeVal = timing.zuhar;
            break;
          case 'Asar':
            timeVal = timing.asar;
            break;
          case 'Maghrib':
            timeVal = timing.maghrib;
            break;
          case 'Isha':
            timeVal = timing.isha;
            break;
          case 'Jummah':
            timeVal = timing.jummah;
            break;
          default:
            timeVal = '';
        }
        timeMap.putIfAbsent(timeVal, () => []).add(masjid);
      }

      // Sort time slots chronologically
      final sortedTimes = timeMap.keys.toList()
        ..sort((a, b) => _parseTimeToMinutes(a).compareTo(_parseTimeToMinutes(b)));

      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2628) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF1B4332)
                  .withValues(alpha: isDark ? 0.3 : 0.15),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Prayer Header Banner
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF223033), const Color(0xFF182224)]
                        : [const Color(0xFF1B4332), const Color(0xFF2D6A4F)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        getPrayerDisplayName(pKey),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily:
                              AppTheme.getFontForLanguage(context, lang),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${allMasajid.length} ${_getMasajidLabel(settings)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Time Slots List
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    for (final timeSlot in sortedTimes) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF141A1C)
                              : const Color(0xFFF7F9FA),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Time Slot Badge
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1B4332)
                                        .withValues(alpha: isDark ? 0.3 : 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF1B4332)
                                          .withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Text(
                                      timeSlot,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? const Color(0xFF81C784)
                                            : const Color(0xFF1B4332),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(${timeMap[timeSlot]!.length} ${_getMasajidLabel(settings)})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.grey[600],
                                    fontFamily: AppTheme.getFontForLanguage(
                                        context, lang),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // List of Masajid under this time slot
                            for (final masjid in timeMap[timeSlot]!) ...[
                              InkWell(
                                onTap: () => _showJamaatTableModal(
                                  context,
                                  masjid,
                                  settings,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 6, horizontal: 4),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          image: const DecorationImage(
                                            image: AssetImage(
                                                'assets/images/masjid_2.jpg'),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _getMasjidName(settings, masjid),
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600,
                                                fontFamily:
                                                    AppTheme.getFontForLanguage(
                                                        context, lang),
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              _getMasjidAddress(settings, masjid),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark
                                                    ? Colors.white54
                                                    : Colors.grey[600],
                                                fontFamily:
                                                    AppTheme.getFontForLanguage(
                                                        context, lang),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        size: 16,
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.grey[400],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (masjid != timeMap[timeSlot]!.last)
                                Divider(
                                  height: 8,
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.04),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildMasjidJamaatBar({
    required BuildContext context,
    required SettingsProvider settings,
    required JamaatMasjidInfo masjid,
    required bool isDark,
    required String lang,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2628) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF1B4332).withValues(alpha: isDark ? 0.3 : 0.15),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF1B4332).withValues(alpha: 0.15),
                border: Border.all(
                  color: const Color(0xFF1B4332).withValues(alpha: 0.3),
                  width: 1,
                ),
                image: const DecorationImage(
                  image: AssetImage('assets/images/masjid_2.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getMasjidName(settings, masjid),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTheme.getFontForLanguage(context, lang),
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getMasjidAddress(settings, masjid),
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: AppTheme.getFontForLanguage(context, lang),
                      color: isDark ? Colors.white54 : Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1B4332).withValues(alpha: isDark ? 0.2 : 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _t(settings, "Jama'at Time", "جماعت کا وقت", "جماعت جو وقت", "وقت الجماعة"),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B4332),
                      fontFamily: AppTheme.getFontForLanguage(context, lang),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B4332),
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

