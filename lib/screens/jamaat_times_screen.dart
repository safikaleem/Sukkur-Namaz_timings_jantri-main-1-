import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/world_translations.dart';
import '../l10n/world_translations_extra.dart';
import '../providers/settings_provider.dart';
import '../services/jamaat_times_service.dart';
import '../utils/app_theme.dart';
import '../widgets/timings_share_card.dart';

class JamaatTimesScreen extends StatefulWidget {
  const JamaatTimesScreen({super.key});

  @override
  State<JamaatTimesScreen> createState() => _JamaatTimesScreenState();
}

class _JamaatTimesScreenState extends State<JamaatTimesScreen> with WidgetsBindingObserver {
  int _selectedTabIndex = 0; // 0 = Individual Masajid, 1 = Combined Chart
  String _selectedPrayerFilter = 'All'; // 'All', 'Fajr', 'Zuhar', 'Asar', 'Maghrib', 'Isha', 'Jummah'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRemoteTimings();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
              'مسجد کی جانب سے جماعت کے اوقات کی بروقت اطلاع موصول نہ ہونے کی صورت میں درج شدہ اوقات اور اصل اوقاتِ جماعت میں فرق ہو سکتا ہے۔ جماعت کے اوقات کی تبدیلی کی صورت میں اس کے اطلاق کی تاریخ درج کی جاتی ہے۔ (تازہ ترین باجماعت اوقات دیکھنے کے لیے انٹرنیٹ کنکشن کا فعال ہونا ضروری ہے۔)',
        };
      case 'sindhi':
        return {
          'prefix': 'نوٽ:',
          'body':
              'مسجد طرفان جماعت جي وقتن جي بروقت اطلاع نه ملڻ جي صورت ۾ لکيل وقتن ۽ اصل جماعت جي وقتن ۾ فرق ٿي سگهي ٿو. جماعت جي وقتن جي تبديليءَ جي صورت ۾ ان جي لاڳو ٿيڻ جي تاريخ لکي ويندي آهي. (تازو ترين باجماعت وقت ڏسڻ لاءِ انٽرنيٽ ڪنيڪشن جو فعال هجڻ ضروري آهي.)',
        };
      case 'arabic':
        return {
          'prefix': 'ملاحظة:',
          'body':
              'في حال عدم استلام تحديثات في الوقت المناسب من المسجد بشأن أوقات صلاة الجماعة، قد تختلف الأوقات المنشورة عن أوقات الجماعة الفعلية. وكلما تغير جدول الجماعة، سيتم تحديد تاريخ سريان التغيير. (يرجى التأكد من اتصالك بالإنترنت لعرض أحدث مواقيت صلاة الجماعة المحدثة.)',
        };
      case 'indonesian':
        return {
          'prefix': 'Catatan:',
          'body':
              'Jika pembaruan tepat waktu mengenai waktu salat berjamaah tidak diterima dari Masjid, waktu yang dipublikasikan mungkin berbeda dari waktu salat berjamaah sebenarnya. Setiap kali jadwal salat berjamaah diubah, tanggal berlakunya perubahan akan dicantumkan. (Pastikan koneksi internet Anda aktif untuk melihat waktu salat berjamaah terbaru.)',
        };
      case 'french':
        return {
          'prefix': 'Remarque :',
          'body':
              'Si des mises à jour opportunes concernant les horaires de prière en Jama\'at ne sont pas reçues de la mosquée, les horaires publiés peuvent différer des horaires réels de la Jama\'at. Chaque fois que l\'horaire de la Jama\'at est modifié, la date d\'effet du changement sera indiquée. (Veuillez vous assurer que votre connexion Internet est active pour voir les derniers horaires de Jama\'at mis à jour.)',
        };
      case 'hindi':
        return {
          'prefix': 'नोट:',
          'body':
              'यदि मस्जिद से जमात की नमाज़ के समय के बारे में समय पर अपडेट प्राप्त नहीं होते हैं, तो प्रकाशित समय वास्तविक जमात के समय से भिन्न हो सकता है। जब भी जमात के समय में बदलाव होगा, बदलाव के प्रभावी होने की तारीख दर्शाई जाएगी। (नवीनतम अपडेट किए गए जमात समय देखने के लिए कृपया सुनिश्चित करें कि आपका इंटरनेट कनेक्शन सक्रिय है।)',
        };
      case 'persian':
        return {
          'prefix': 'یادداشت:',
          'body':
              'در صورتی که به‌روزرسانی‌های به‌موقع در مورد اوقات نماز جماعت از سوی مسجد دریافت نشود، ممکن است اوقات اعلام‌شده با اوقات واقعی جماعت متفاوت باشد. هر زمان که برنامه جماعت تغییر کند، تاریخ اعمال تغییر مشخص خواهد شد. (لطفاً برای مشاهده آخرین اوقات به‌روزشده جماعت، از فعال بودن اتصال اینترنت خود اطمینان حاصل کنید.)',
        };
      case 'turkish':
        return {
          'prefix': 'Not:',
          'body':
              'Mescitten cemaatle namaz vakitlerine ilişkin zamanında güncelleme alınmaması durumunda, yayınlanan vakitler gerçek cemaat vakitlerinden farklı olabilir. Cemaat programı her değiştiğinde, değişikliğin geçerlilik tarihi belirtilecektir. (En güncel cemaat vakitlerini görebilmek için lütfen internet bağlantınızın aktif olduğundan emin olun.)',
        };
      case 'bengali':
        return {
          'prefix': 'নোট:',
          'body':
              'মসজিদ থেকে জামাতের নামাজের সময় সম্পর্কিত সময়োপযোগী আপডেট না পাওয়া গেলে, প্রকাশিত সময়সূচী প্রকৃত জামাতের সময় থেকে ভিন্ন হতে পারে। যখনই জামাতের সময়সূচী পরিবর্তিত হবে, পরিবর্তনের কার্যকরের তারিখ নির্দেশ করা হবে। (সর্বশেষ আপডেট করা জামাতের সময় দেখতে আপনার ইন্টারনেট সংযোগ চালু আছে তা নিশ্চিত করুন।)',
        };
      case 'english':
      default:
        return {
          'prefix': 'Note:',
          'body':
              'If timely updates regarding Jama\'at prayer times are not received from the Masjid, the published timings may differ from the actual Jama\'at times. Whenever the Jama\'at schedule is changed, the effective date of the change will be indicated. (Please ensure your internet connection is active to view the latest updated Jama\'at times.)',
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

  String _getIndividualSubtext(SettingsProvider settings) {
    switch (settings.language) {
      case 'urdu':
        return 'تمام ۱۰ زبانوں میں نام یا علاقے سے مسجد تلاش کریں، یا باجماعت اوقات دیکھنے کے لیے نیچے ٹیپ کریں۔';
      case 'sindhi':
        return 'سڀني ۱۰ ٻولين ۾ نالي يا علائقي سان مسجد ڳوليو، يا باجماعت وقت ڏسڻ لاءِ هيٺ ٽيپ ڪريو.';
      case 'arabic':
        return 'ابحث عن أي مسجد بالاسم أو المنطقة بجميع اللغات الـ 10، أو انقر أدناه لعرض مواقيت صلاة الجماعة.';
      case 'hindi':
        return 'सभी 10 भाषाओं में नाम या क्षेत्र से मस्जिद खोजें, या समय देखने के लिए नीचे टैप करें।';
      case 'bengali':
        return '১০টি ভাষায় নাম বা এলাকা দিয়ে মসজিদ খুঁজুন, অথবা সময়সূচি দেখতে নিচে ট্যাপ করুন।';
      case 'persian':
        return 'در تمام ۱۰ زبان با نام یا منطقه مسجد را جستجو کنید، یا برای مشاهده اوقات در زیر ضربه بزنید.';
      case 'turkish':
        return 'Sukkur camilerini 10 dilde ad veya bölge ile arayın veya vakitleri görmek için dokunun.';
      case 'french':
        return 'Recherchez une mosquée dans les 10 langues par nom ou quartier, ou appuyez ci-dessous.';
      case 'indonesian':
        return 'Cari masjid dalam 10 bahasa berdasarkan nama atau wilayah, atau ketuk di bawah untuk jadwal.';
      case 'english':
      default:
        return 'Search any Masjid by name or area in all 10 languages, or tap below to view complete congregational timings.';
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

  String _getNotSetLabel(SettingsProvider settings) {
    switch (settings.language) {
      case 'urdu':
        return 'طے نہیں';
      case 'sindhi':
        return 'مقرر ناهي';
      case 'arabic':
        return 'غير محدد';
      case 'hindi':
        return 'सेट नहीं है';
      case 'indonesian':
        return 'Belum Diatur';
      case 'turkish':
        return 'Ayarlanmadı';
      case 'bengali':
        return 'সেট করা নেই';
      case 'persian':
        return 'تنظیم نشده';
      case 'french':
        return 'Non défini';
      default:
        return 'Not Set';
    }
  }

  String _getTurnOffPrayerTooltip(SettingsProvider settings) {
    switch (settings.language) {
      case 'urdu':
        return 'جماعت کا وقت بند کریں / ختم کریں';
      case 'sindhi':
        return 'جماعت جو وقت بند ڪريو / ختم ڪريو';
      case 'arabic':
        return 'إيقاف وقت الجماعة / إزالة';
      case 'hindi':
        return 'जमात का समय बंद करें / हटाएं';
      case 'indonesian':
        return 'Matikan waktu Jamaah / Hapus';
      case 'turkish':
        return 'Cemaat vaktini kapat / Kaldır';
      case 'bengali':
        return 'জামায়াতের সময় বন্ধ করুন / মুছুন';
      case 'persian':
        return 'خاموش کردن وقت جماعت / حذف';
      case 'french':
        return 'Désactiver l\'heure de prière / Supprimer';
      default:
        return 'Turn Off / Clear Jama\'at Time';
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
                    IconButton(
                      icon: const Icon(
                        Icons.share_rounded,
                        color: Colors.white70,
                        size: 24,
                      ),
                      tooltip: _t(
                        settings,
                        'Share Masjid Jama\'at Times Card',
                        'مسجد باجماعت کارڈ شیئر کریں',
                        'مسجد باجماعت ڪارڊ شيئر ڪريو',
                        'مشاركة بطاقة صلاة الجماعة للمسجد',
                      ),
                      onPressed: () {
                        TimingsShareService.showMasjidShareModal(
                          context: context,
                          masjid: masjid,
                          timing: timing,
                          date: DateTime.now(),
                          settings: settings,
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

              const SizedBox(height: 14),

              // ── Masjid Committee Login / Edit Timings Button ─────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showMasjidAdminLoginDialog(
                      context,
                      masjid,
                      settings,
                      onUpdated: () {
                        setModalState(() {});
                        if (mounted) setState(() {});
                      },
                    ),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1B382B).withValues(alpha: 0.6)
                            : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF81C784).withValues(alpha: 0.5)
                              : const Color(0xFF2E7D32).withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B4332).withValues(alpha: isDark ? 0.5 : 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.admin_panel_settings_rounded,
                              size: 20,
                              color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B4332),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _t(settings, 'Masjid Committee Login'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: AppTheme.getFontForLanguage(context, lang),
                                    color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B4332),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _t(settings, 'Authorized mosque representative login'),
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
                            Icons.lock_open_rounded,
                            size: 18,
                            color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B4332),
                          ),
                        ],
                      ),
                    ),
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

  TimeOfDay _parseTimeOfDay(String timeStr, {TimeOfDay fallback = const TimeOfDay(hour: 12, minute: 0)}) {
    try {
      final clean = timeStr.trim().toUpperCase();
      if (clean == 'SUNSET' || clean.isEmpty) return fallback;
      final parts = clean.split(' ');
      final timeParts = parts[0].split(':');
      int h = int.parse(timeParts[0]);
      int m = int.parse(timeParts[1]);
      if (parts.length > 1) {
        if (parts[1] == 'PM' && h < 12) h += 12;
        if (parts[1] == 'AM' && h == 12) h = 0;
      }
      return TimeOfDay(hour: h, minute: m);
    } catch (_) {
      return fallback;
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minute = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  void _showMasjidAdminLoginDialog(
    BuildContext context,
    JamaatMasjidInfo masjid,
    SettingsProvider settings, {
    required VoidCallback onUpdated,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = settings.language;
    final pinController = TextEditingController();
    final focusNode = FocusNode();
    String? errorText;
    bool obscurePin = true;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dCtx, setDialogState) {
            void submitPin() {
              final pin = pinController.text.trim();
              if (JamaatTimesService.instance.verifyMasjidPin(masjid.id, pin)) {
                Navigator.of(dialogCtx).pop();
                _showEditJamaatTimesSheet(
                  context,
                  masjid,
                  settings,
                  onUpdated: onUpdated,
                );
              } else {
                setDialogState(() {
                  errorText = _t(settings, 'Invalid PIN. Contact admin if forgotten.');
                });
              }
            }

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF222C2E) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B4332).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.security_rounded,
                      color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B4332),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _t(settings, 'Enter Masjid PIN'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppTheme.getFontForLanguage(context, lang),
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getEnterPinSubtitle(settings),
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: AppTheme.getFontForLanguage(context, lang),
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _getMasjidName(settings, masjid),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppTheme.getFontForLanguage(context, lang),
                      color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B4332),
                    ),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () => focusNode.requestFocus(),
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1A2224) : const Color(0xFFF4F6F6),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: errorText != null
                                  ? Colors.redAccent
                                  : (focusNode.hasFocus
                                      ? (isDark ? const Color(0xFF81C784) : const Color(0xFF1B4332))
                                      : (isDark ? Colors.white24 : Colors.black12)),
                              width: (errorText != null || focusNode.hasFocus) ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.key_rounded,
                                size: 20,
                                color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B4332),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: List.generate(8, (index) {
                                      final text = pinController.text;
                                      final isFilled = index < text.length;
                                      if (isFilled) {
                                        return SizedBox(
                                          width: 16,
                                          child: Center(
                                            child: Text(
                                              obscurePin ? '●' : text[index],
                                              style: TextStyle(
                                                fontSize: obscurePin ? 13 : 16,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B4332),
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                      return SizedBox(
                                        width: 16,
                                        child: Center(
                                          child: Text(
                                            '—',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white30 : Colors.black26,
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 36),
                            ],
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          right: 44,
                          child: Opacity(
                            opacity: 0.0,
                            child: TextField(
                              controller: pinController,
                              focusNode: focusNode,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(8),
                              ],
                              autofocus: true,
                              cursorColor: Colors.transparent,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                counterText: '',
                              ),
                              onChanged: (_) {
                                if (errorText != null) {
                                  setDialogState(() => errorText = null);
                                } else {
                                  setDialogState(() {});
                                }
                              },
                              onSubmitted: (_) => submitPin(),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 4,
                          child: IconButton(
                            splashRadius: 18,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            icon: Icon(
                              obscurePin ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              size: 20,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                obscurePin = !obscurePin;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorText!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(
                    _t(settings, 'Cancel'),
                    style: TextStyle(
                      fontFamily: AppTheme.getFontForLanguage(context, lang),
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4332),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: submitPin,
                  child: Text(
                    _t(settings, 'Login & Edit Times'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTheme.getFontForLanguage(context, lang),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditJamaatTimesSheet(
    BuildContext context,
    JamaatMasjidInfo masjid,
    SettingsProvider settings, {
    required VoidCallback onUpdated,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = settings.language;
    final currentTiming = JamaatTimesService.instance.getTimingFor(masjid);

    String fajr = currentTiming.fajr;
    String zuhar = currentTiming.zuhar;
    String asar = currentTiming.asar;
    String isha = currentTiming.isha;
    String jummah = currentTiming.jummah;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sCtx, setSheetState) {
            Future<void> pickTimeFor(String currentVal, Function(String) onPicked, {TimeOfDay? fallback}) async {
              final initial = _parseTimeOfDay(currentVal, fallback: fallback ?? const TimeOfDay(hour: 12, minute: 0));
              final picked = await showTimePicker(
                context: sCtx,
                initialTime: initial,
                helpText: _getTimePickerHelpText(lang),
                confirmText: _getTimePickerConfirmText(lang),
                cancelText: _getTimePickerCancelText(lang),
                hourLabelText: _getTimePickerHourLabel(lang),
                minuteLabelText: _getTimePickerMinuteLabel(lang),
                builder: (pickerCtx, child) {
                  return Theme(
                    data: Theme.of(pickerCtx).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: const Color(0xFF1B4332),
                        onPrimary: Colors.white,
                        onSurface: isDark ? Colors.white : Colors.black87,
                        surface: isDark ? const Color(0xFF222C2E) : Colors.white,
                      ),
                      textTheme: Theme.of(pickerCtx).textTheme.apply(
                        fontFamily: AppTheme.getFontForLanguage(context, lang),
                      ),
                    ),
                    child: Directionality(
                      textDirection: settings.isRtl ? TextDirection.rtl : TextDirection.ltr,
                      child: child!,
                    ),
                  );
                },
              );
              if (picked != null) {
                final formatted = _formatTimeOfDay(picked);
                setSheetState(() {
                  onPicked(formatted);
                });
              }
            }

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sCtx).viewInsets.bottom + 20,
                top: 16,
                left: 18,
                right: 18,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1D2628) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black26,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B4332).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.edit_calendar_rounded,
                            color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B4332),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _t(settings, 'Update Jama\'at Times'),
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: AppTheme.getFontForLanguage(context, lang),
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                _getMasjidName(settings, masjid),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: AppTheme.getFontForLanguage(context, lang),
                                  color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B4332),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sCtx).pop(),
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Fajr
                    _buildEditPrayerRow(
                      context: context,
                      settings: settings,
                      isDark: isDark,
                      prayerNameKey: 'Fajr',
                      timeValue: fajr,
                      icon: Icons.wb_twilight_rounded,
                      onTap: () => pickTimeFor(fajr, (v) => fajr = v, fallback: const TimeOfDay(hour: 5, minute: 15)),
                      onClear: () => setSheetState(() => fajr = ''),
                    ),
                    const SizedBox(height: 8),

                    // Zuhar
                    _buildEditPrayerRow(
                      context: context,
                      settings: settings,
                      isDark: isDark,
                      prayerNameKey: 'Zuhar',
                      timeValue: zuhar,
                      icon: Icons.wb_sunny_rounded,
                      onTap: () => pickTimeFor(zuhar, (v) => zuhar = v, fallback: const TimeOfDay(hour: 13, minute: 15)),
                      onClear: () => setSheetState(() => zuhar = ''),
                    ),
                    const SizedBox(height: 8),

                    // Asar
                    _buildEditPrayerRow(
                      context: context,
                      settings: settings,
                      isDark: isDark,
                      prayerNameKey: 'Asar',
                      timeValue: asar,
                      icon: Icons.brightness_5_rounded,
                      onTap: () => pickTimeFor(asar, (v) => asar = v, fallback: const TimeOfDay(hour: 16, minute: 45)),
                      onClear: () => setSheetState(() => asar = ''),
                    ),
                    const SizedBox(height: 8),

                    // Maghrib (Locked - strictly follows Sukkur Jantri Sunset)
                    _buildEditPrayerRow(
                      context: context,
                      settings: settings,
                      isDark: isDark,
                      prayerNameKey: 'Maghrib',
                      timeValue: currentTiming.maghrib,
                      icon: Icons.nights_stay_rounded,
                      isLocked: true,
                      subtitle: _t(settings, 'Fixed at Sunset (Sukkur Jantri)'),
                      onTap: () {},
                    ),
                    const SizedBox(height: 8),

                    // Isha
                    _buildEditPrayerRow(
                      context: context,
                      settings: settings,
                      isDark: isDark,
                      prayerNameKey: 'Isha',
                      timeValue: isha,
                      icon: Icons.bedtime_rounded,
                      onTap: () => pickTimeFor(isha, (v) => isha = v, fallback: const TimeOfDay(hour: 20, minute: 0)),
                      onClear: () => setSheetState(() => isha = ''),
                    ),
                    const SizedBox(height: 8),

                    // Jummah
                    _buildEditPrayerRow(
                      context: context,
                      settings: settings,
                      isDark: isDark,
                      prayerNameKey: 'Jummah',
                      timeValue: jummah,
                      icon: Icons.star_rounded,
                      onTap: () => pickTimeFor(jummah, (v) => jummah = v, fallback: const TimeOfDay(hour: 13, minute: 15)),
                      onClear: () => setSheetState(() => jummah = ''),
                    ),
                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(
                                color: isDark ? Colors.white24 : Colors.black12,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.of(sCtx).pop(),
                            child: Text(
                              _t(settings, 'Cancel'),
                              style: TextStyle(
                                fontFamily: AppTheme.getFontForLanguage(context, lang),
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: const Color(0xFF1B4332),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                            label: Text(
                              _t(settings, 'Save & Update'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                fontFamily: AppTheme.getFontForLanguage(context, lang),
                              ),
                            ),
                            onPressed: () {
                              const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                              final now = DateTime.now();
                              final todayStr = '${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]} ${now.year}';
                              final updatedTiming = JamaatTiming(
                                fajr: fajr,
                                fajrUpdated: fajr != currentTiming.fajr ? todayStr : currentTiming.fajrUpdated,
                                fajrNoteUr: currentTiming.fajrNoteUr,
                                fajrNoteEn: currentTiming.fajrNoteEn,
                                zuhar: zuhar,
                                zuharUpdated: zuhar != currentTiming.zuhar ? todayStr : currentTiming.zuharUpdated,
                                zuharNoteUr: currentTiming.zuharNoteUr,
                                zuharNoteEn: currentTiming.zuharNoteEn,
                                asar: asar,
                                asarUpdated: asar != currentTiming.asar ? todayStr : currentTiming.asarUpdated,
                                asarNoteUr: currentTiming.asarNoteUr,
                                asarNoteEn: currentTiming.asarNoteEn,
                                maghrib: 'Sunset',
                                maghribNoteUr: currentTiming.maghribNoteUr,
                                maghribNoteEn: currentTiming.maghribNoteEn,
                                isha: isha,
                                ishaUpdated: isha != currentTiming.isha ? todayStr : currentTiming.ishaUpdated,
                                ishaNoteUr: currentTiming.ishaNoteUr,
                                ishaNoteEn: currentTiming.ishaNoteEn,
                                jummah: jummah,
                                jummahUpdated: jummah != currentTiming.jummah ? todayStr : currentTiming.jummahUpdated,
                                jummahNoteUr: currentTiming.jummahNoteUr,
                                jummahNoteEn: currentTiming.jummahNoteEn,
                              );

                              // 1. Immediately update cache & background persist
                              JamaatTimesService.instance.updateTimingForMasjid(
                                masjidId: masjid.id,
                                newTiming: updatedTiming,
                              );

                              // 2. Immediately close sheet
                              Navigator.of(sCtx).pop();

                              // 3. Immediately refresh parent list & details
                              onUpdated();

                              // 4. Immediately show confirmation snackbar
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFF1B4332),
                                    behavior: SnackBarBehavior.floating,
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _t(settings, 'Jama\'at times updated successfully!'),
                                            style: TextStyle(
                                              fontFamily: AppTheme.getFontForLanguage(context, lang),
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEditPrayerRow({
    required BuildContext context,
    required SettingsProvider settings,
    required bool isDark,
    required String prayerNameKey,
    required String timeValue,
    required IconData icon,
    required VoidCallback onTap,
    VoidCallback? onClear,
    bool isLocked = false,
    String? subtitle,
  }) {
    final lang = settings.language;
    final bool hasValidTime = timeValue.trim().isNotEmpty &&
        timeValue.trim() != '-' &&
        timeValue.trim().toLowerCase() != 'off' &&
        timeValue.trim() != '--:--';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLocked
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: const Color(0xFF1B4332),
                    content: Row(
                      children: [
                        const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _t(settings, 'Maghrib time is fixed according to Sukkur Jantri sunset time and cannot be changed.'),
                            style: TextStyle(
                              fontFamily: AppTheme.getFontForLanguage(context, lang),
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF222C2E) : const Color(0xFFF7F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF2D6A4F)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getPrayerDisplayName(settings, prayerNameKey),
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppTheme.getFontForLanguage(context, lang),
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppTheme.getFontForLanguage(context, lang),
                          color: isDark ? const Color(0xFF81C784) : const Color(0xFF2D6A4F),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isLocked
                      ? (isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.15))
                      : const Color(0xFF1B4332).withValues(alpha: isDark ? 0.3 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isLocked
                        ? (isDark ? Colors.white24 : Colors.grey.withValues(alpha: 0.3))
                        : const Color(0xFF1B4332).withValues(alpha: isDark ? 0.4 : 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Directionality(
                      textDirection: hasValidTime ? TextDirection.ltr : (settings.isRtl ? TextDirection.rtl : TextDirection.ltr),
                      child: Text(
                        hasValidTime ? '\u200E${timeValue.trim()}\u200E' : _getNotSetLabel(settings),
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          fontFamily: hasValidTime ? null : AppTheme.getFontForLanguage(context, lang),
                          color: isLocked
                              ? (isDark ? Colors.white70 : Colors.black87)
                              : (hasValidTime
                                  ? (isDark ? const Color(0xFF81C784) : const Color(0xFF1B4332))
                                  : (isDark ? Colors.white38 : Colors.black45)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      isLocked ? Icons.lock_outline_rounded : Icons.edit_rounded,
                      size: 15,
                      color: isLocked
                          ? (isDark ? Colors.white60 : Colors.black54)
                          : (isDark ? const Color(0xFF81C784) : const Color(0xFF1B4332)),
                    ),
                  ],
                ),
              ),
              if (!isLocked && onClear != null && hasValidTime) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: _getTurnOffPrayerTooltip(settings),
                  child: InkWell(
                    onTap: onClear,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.red.withValues(alpha: 0.25) : const Color(0xFFFFEBEE),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? Colors.red.withValues(alpha: 0.45) : const Color(0xFFEF9A9A),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: isDark ? Colors.redAccent[100] : const Color(0xFFC62828),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
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

    final cleanTime = time.trim();
    final bool isTimeSet = cleanTime.isNotEmpty &&
        cleanTime != '-' &&
        cleanTime.toLowerCase() != 'off' &&
        cleanTime.toLowerCase() != 'null' &&
        cleanTime != '--:--';

    final bool hasCustomNote = customNote != null && customNote.isNotEmpty;
    final String displayTime = isTimeSet ? cleanTime : '--:--';
    final bool showLastUpdated = isTimeSet && !hasCustomNote && (subNoteKey != null || lastUpdated.trim().isNotEmpty);

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
                color: isTimeSet ? const Color(0xFF2D6A4F) : (isDark ? Colors.white38 : Colors.grey),
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
                      color: isTimeSet
                          ? const Color(0xFF1B4332).withValues(alpha: isDark ? 0.25 : 0.08)
                          : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isTimeSet
                            ? const Color(0xFF1B4332).withValues(alpha: 0.2)
                            : (isDark ? Colors.white10 : Colors.black12),
                      ),
                    ),
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        displayTime,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isTimeSet
                              ? (isDark ? const Color(0xFF81C784) : const Color(0xFF1B4332))
                              : (isDark ? Colors.white38 : Colors.black38),
                        ),
                      ),
                    ),
                  ),
                  if (showLastUpdated) ...[
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
                        ? _getIndividualSubtext(settings)
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

            // ── Search Bar (Multi-language across 10 languages) ───────
            _buildSearchBar(context, settings, isDark, lang),

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

  /// Normalizes text across all 10 scripts (Arabic/Urdu/Sindhi/Persian/Latin/Indic)
  String _normalizeForSearch(String input) {
    if (input.isEmpty) return '';
    var s = input.trim().toLowerCase();

    // Remove Arabic/Urdu harakat / diacritics
    s = s.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '');

    // Normalize honorific symbols
    s = s.replaceAll('ﷺ', '').replaceAll('ﷻ', '');

    // Normalize Arabic / Urdu / Persian / Sindhi letters to common base
    s = s.replaceAll(RegExp(r'[يىیئ]'), 'ی');
    s = s.replaceAll(RegExp(r'[كکڪ]'), 'ک');
    s = s.replaceAll(RegExp(r'[ہھهة]'), 'ہ');
    s = s.replaceAll(RegExp(r'[أإآٱا]'), 'ا');
    s = s.replaceAll('ؤ', 'و');

    // Normalize European accents (Turkish / French)
    s = s.replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[ûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i');

    return s;
  }

  /// Checks if a masjid matches search query in ANY of the 10 languages
  /// Checks if a masjid matches search query in ANY of the 10 languages, including translations.
  bool _masjidMatchesSearch(JamaatMasjidInfo masjid, String query) {
    final cleanQuery = _normalizeForSearch(query);
    if (cleanQuery.isEmpty) return true;

    // Base candidates: id, keys, localized overrides
    final Set<String> candidates = {
      masjid.id,
      masjid.nameKey,
      masjid.addressKey,
      ...masjid.localizedNames.values,
      ...masjid.localizedAddresses.values,
    };

    // Add translated strings from additionalTranslations for all 10 languages
    for (final lang in additionalTranslations.keys) {
      final map = additionalTranslations[lang];
      if (map == null) continue;
      final nameTrans = map[masjid.nameKey];
      if (nameTrans != null && nameTrans.isNotEmpty) candidates.add(nameTrans);
      final addrTrans = map[masjid.addressKey];
      if (addrTrans != null && addrTrans.isNotEmpty) candidates.add(addrTrans);
    }

    // Add translated strings from worldTranslations for all supported languages
    for (final lang in worldTranslations.keys) {
      final map = worldTranslations[lang];
      if (map == null) continue;
      final nameTrans = map[masjid.nameKey];
      if (nameTrans != null && nameTrans.isNotEmpty) candidates.add(nameTrans);
      final addrTrans = map[masjid.addressKey];
      if (addrTrans != null && addrTrans.isNotEmpty) candidates.add(addrTrans);
    }

    // Normalise each candidate using the same routine as the query
    final normCandidates = candidates.map(_normalizeForSearch).toList();
    final combined = normCandidates.join(' ');
    final combinedNoSpaces = combined.replaceAll(' ', '');

    // Direct substring match (with or without spaces)
    if (combined.contains(cleanQuery) ||
        combinedNoSpaces.contains(cleanQuery.replaceAll(' ', ''))) {
      return true;
    }

    // Token‑based match – every token from the query must appear somewhere in the candidates
    final tokens = cleanQuery.split(' ').where((t) => t.isNotEmpty).toList();
    bool allTokensFound = true;
    for (final token in tokens) {
      if (!combined.contains(token) && !combinedNoSpaces.contains(token)) {
        allTokensFound = false;
        break;
      }
    }
    if (allTokensFound) return true;

    return false;
  }

  Widget _buildSearchBar(
    BuildContext context,
    SettingsProvider settings,
    bool isDark,
    String lang,
  ) {
    final isRtl = settings.isRtl;

    String getPlaceholder() {
      switch (lang) {
        case 'urdu':
          return 'مسجد کا نام یا علاقہ تلاش کریں...';
        case 'sindhi':
          return 'مسجد جو نالو يا علائقو ڳوليو...';
        case 'arabic':
          return 'ابحث باسم المسجد أو المنطقة...';
        case 'hindi':
          return 'मस्जिद का नाम या क्षेत्र खोजें...';
        case 'bengali':
          return 'মসজিদের নাম বা এলাকা অনুসন্ধান করুন...';
        case 'persian':
          return 'جستجوی نام مسجد یا منطقه...';
        case 'turkish':
          return 'Cami adı veya bölge ara...';
        case 'french':
          return 'Rechercher une mosquée ou un quartier...';
        case 'indonesian':
          return 'Cari nama masjid atau wilayah...';
        case 'english':
        default:
          return 'Search masjid name or area...';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2628) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _searchQuery.isNotEmpty
              ? const Color(0xFF1B4332)
              : (isDark ? Colors.white12 : const Color(0xFFE0E0E0)),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black87,
          fontFamily: AppTheme.getFontForLanguage(context, lang),
        ),
        decoration: InputDecoration(
          hintText: getPlaceholder(),
          hintTextDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          hintStyle: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white38 : Colors.black38,
            fontFamily: AppTheme.getFontForLanguage(context, lang),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF1B4332),
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: _t(settings, 'Clear', 'صاف کریں', 'صاف ڪريو', 'مسح'),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        ),
      ),
    );
  }

  Widget _buildEmptySearchState(
    BuildContext context,
    SettingsProvider settings,
    bool isDark,
    String lang,
  ) {
    String getEmptyTitle() {
      switch (lang) {
        case 'urdu':
          return 'کوئی مسجد نہیں ملی';
        case 'sindhi':
          return 'ڪابه مسجد نه ملي';
        case 'arabic':
          return 'لم يتم العثور على أي مسجد';
        case 'hindi':
          return 'कोई मस्जिद नहीं मिली';
        case 'bengali':
          return 'কোনো মসজিদ পাওয়া যায়নি';
        case 'persian':
          return 'هیچ مسجدی یافت نشد';
        case 'turkish':
          return 'Eşleşen cami bulunamadı';
        case 'french':
          return 'Aucune mosquée trouvée';
        case 'indonesian':
          return 'Tidak ada masjid yang ditemukan';
        default:
          return 'No Masajid Found';
      }
    }

    String getEmptySubtitle() {
      switch (lang) {
        case 'urdu':
          return 'براہ کرم کوئی دوسرا نام یا علاقہ تلاش کریں۔';
        case 'sindhi':
          return 'مهرباني ڪري ڪو ٻيو نالو يا علائقو ڳوليو.';
        case 'arabic':
          return 'يرجى محاولة البحث باسم آخر أو منطقة أخرى.';
        case 'hindi':
          return 'कृपया किसी अन्य नाम या क्षेत्र से खोजें।';
        case 'bengali':
          return 'অনুগ্রহ করে অন্য কোনো নাম বা এলাকা দিয়ে অনুসন্ধান করুন।';
        case 'persian':
          return 'لطفاً نام یا منطقه دیگری را جستجو کنید.';
        case 'turkish':
          return 'Lütfen başka bir ad veya bölge ile arayın.';
        case 'french':
          return 'Veuillez essayer un autre nom ou quartier.';
        case 'indonesian':
          return 'Silakan coba cari dengan nama atau wilayah lain.';
        default:
          return 'Please try searching with a different name or area.';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      margin: const EdgeInsets.only(top: 8, bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2628) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE8ECEF),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1B4332)
                  .withValues(alpha: isDark ? 0.25 : 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 40,
              color:
                  isDark ? const Color(0xFF81C784) : const Color(0xFF1B4332),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            getEmptyTitle(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
              fontFamily: AppTheme.getFontForLanguage(context, lang),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            getEmptySubtitle(),
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.black54,
              fontFamily: AppTheme.getFontForLanguage(context, lang),
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
    final all = JamaatTimesService.instance.getMasjidList();
    final list = all.where((m) => _masjidMatchesSearch(m, _searchQuery)).toList();
    if (list.isEmpty) {
      return [
        _buildEmptySearchState(context, settings, isDark, lang),
      ];
    }
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
    final allMasajid = JamaatTimesService.instance
        .getMasjidList()
        .where((m) => _masjidMatchesSearch(m, _searchQuery))
        .toList();
    if (allMasajid.isEmpty) {
      return [
        _buildEmptySearchState(context, settings, isDark, lang),
      ];
    }
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
        final clean = timeVal.trim();
        final finalVal = (clean.isEmpty || clean == '-' || clean.toLowerCase() == 'off' || clean == '--:--')
            ? '--:--'
            : clean;
        timeMap.putIfAbsent(finalVal, () => []).add(masjid);
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

  static String _getTimePickerHelpText(String language) {
    switch (language.toLowerCase()) {
      case 'urdu':
        return 'وقت منتخب کریں';
      case 'sindhi':
        return 'وقت چونڊيو';
      case 'arabic':
        return 'اختر الوقت';
      case 'persian':
      case 'farsi':
        return 'انتخاب زمان';
      case 'hindi':
        return 'समय चुनें';
      case 'bengali':
        return 'সময় নির্বাচন করুন';
      case 'turkish':
        return 'Zaman seçin';
      case 'french':
        return 'Sélectionner l\'heure';
      case 'indonesian':
        return 'Pilih Waktu';
      case 'english':
      default:
        return 'Select Time';
    }
  }

  static String _getTimePickerConfirmText(String language) {
    switch (language.toLowerCase()) {
      case 'urdu':
        return 'ٹھیک ہے';
      case 'sindhi':
        return 'ٺيڪ';
      case 'arabic':
        return 'موافق';
      case 'persian':
      case 'farsi':
        return 'تأیید';
      case 'hindi':
        return 'ठीक है';
      case 'bengali':
        return 'ठीक আছে';
      case 'turkish':
        return 'Tamam';
      case 'french':
        return 'OK';
      case 'indonesian':
        return 'OKE';
      case 'english':
      default:
        return 'OK';
    }
  }

  static String _getTimePickerCancelText(String language) {
    switch (language.toLowerCase()) {
      case 'urdu':
        return 'منسوخ';
      case 'sindhi':
        return 'منسوخ';
      case 'arabic':
        return 'إلغاء';
      case 'persian':
      case 'farsi':
        return 'لغو';
      case 'hindi':
        return 'رद्द करें';
      case 'bengali':
        return 'বাতিল';
      case 'turkish':
        return 'İptal';
      case 'french':
        return 'Annuler';
      case 'indonesian':
        return 'Batal';
      case 'english':
      default:
        return 'Cancel';
    }
  }

  static String _getTimePickerHourLabel(String language) {
    switch (language.toLowerCase()) {
      case 'urdu':
        return 'گھنٹہ';
      case 'sindhi':
        return 'ڪلاڪ';
      case 'arabic':
        return 'ساعة';
      case 'persian':
      case 'farsi':
        return 'ساعت';
      case 'hindi':
        return 'घंटा';
      case 'bengali':
        return 'ঘণ্টা';
      case 'turkish':
        return 'Saat';
      case 'french':
        return 'Heure';
      case 'indonesian':
        return 'Jam';
      case 'english':
      default:
        return 'Hour';
    }
  }

  static String _getTimePickerMinuteLabel(String language) {
    switch (language.toLowerCase()) {
      case 'urdu':
        return 'منٹ';
      case 'sindhi':
        return 'منٽ';
      case 'arabic':
        return 'دقيقة';
      case 'persian':
      case 'farsi':
        return 'دقیقه';
      case 'hindi':
        return 'मिनट';
      case 'bengali':
        return 'মিনিট';
      case 'turkish':
        return 'Dakika';
      case 'french':
        return 'Minute';
      case 'indonesian':
        return 'Menit';
      case 'english':
      default:
        return 'Minute';
    }
  }

  static String _getEnterPinSubtitle(SettingsProvider settings) {
    switch (settings.language.toLowerCase()) {
      case 'urdu':
        return 'اس مسجد کا 8 ہندسوں کا پن درج کریں';
      case 'sindhi':
        return 'هن مسجد جو 8 انگن وارو پن داخل ڪريو';
      case 'arabic':
        return 'أدخل رمز المسجد المكون من 8 أرقام';
      case 'persian':
      case 'farsi':
        return 'پین کد ۸ رقمی این مسجد را وارد کنید';
      case 'hindi':
        return 'इस मस्जिद का 8 अंकों का पिन दर्ज करें';
      case 'bengali':
        return 'এই মসজিদের ৮ অঙ্কের পিন দিন';
      case 'turkish':
        return 'Bu cami için 8 haneli PIN\'i girin';
      case 'french':
        return 'Entrez le code PIN à 8 chiffres de cette mosquée';
      case 'indonesian':
        return 'Masukkan 8 digit PIN untuk masjid ini';
      case 'english':
      default:
        return 'Enter 8-digit PIN for this mosque';
    }
  }
}

