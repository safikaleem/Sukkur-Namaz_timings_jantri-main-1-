// All visible Urdu strings in one place.
class S {
  S._();

  // App
  static const appName           = 'سکھر جنتری';
  static const city              = 'سکھر';
  static String get year => toArabicNumerals(DateTime.now().year);

  // Navigation tabs
  static const tabHome           = 'آج';
  static const tabMonthly        = 'ماہانہ';
  static const tabSettings       = 'ترتیبات';

  // Prayer names
  static const fajr              = 'فجر';
  static const zuhr              = 'ظہر';
  static const asr               = 'عصر';
  static const maghrib           = 'مغرب';
  static const isha              = 'عشاء';
  static const sunrise           = 'طلوعِ آفتاب';

  // Home screen
  static const nextPrayer        = 'اگلی نماز';
  static const timeRemaining     = 'اگلی نماز تک';
  static const noData            = 'آج کے نماز کے اوقات دستیاب نہیں';
  static const todayPrayers      = 'نماز کے اوقات';
  static const jumaGreeting      = 'جمعہ مبارک';
  static const allDonePrayers    = 'آج کی تمام نمازیں ادا ہو گئی';

  // Monthly screen
  static const monthlyTitle      = 'ماہانہ جدول';
  static const dateLabel         = 'تاریخ';
  static const noMonthData       = 'ڈیٹا دستیاب نہیں';

  // Settings / drawer
  static const settingsTitle     = 'ترتیبات';
  static const notifSection      = 'اذان کی اطلاعات';
  static const allNotif          = 'تمام اطلاعات';
  static const allNotifSub       = 'تمام نمازوں کی اطلاع آن/آف';
  static const prayerSelect      = 'نماز کا انتخاب';
  static const themeSection      = 'تھیم';
  static const darkMode          = 'ڈارک موڈ';
  static const darkModeSub       = 'رات کا موڈ';
  static const aboutSection      = 'ایپ کے بارے میں';
  static const appNameLabel      = 'ایپ کا نام';
  static const versionLabel      = 'ورژن';
  static const cityLabel         = 'شہر';
  static const yearLabel         = 'سال';
  static const footerNote        = 'تمام اوقات سکھر کی مقامی جنتری سے لیے گئے ہیں';
  static const versionValue      = '1.0.0';
  static const cityValue         = 'سکھر، سندھ، پاکستان';
  static const notifSuffix       = 'کی اطلاع';

  // Sukkur-specific info
  static const sukkurInfoSection = 'سکھر کی معلومات';
  static const qiblaLabel        = 'قبلہ رخ';
  static const qiblaValue        = '۲۶۳° (مغرب)';
  static const methodLabel       = 'طریقہ حساب';
  static const methodValue       = 'یونی آف اسلامک سائنسز، کراچی';
  static const timezoneLabel     = 'وقت کا علاقہ';
  static const timezoneValue     = 'PKT +۵:۰۰';
  static const coordLabel        = 'مقام';
  static const coordValue        = '۲۷.۷°N ، ۶۸.۹°E';

  // Notification body
  static const notifBody         = 'نماز کا وقت ہو گیا';

  // Urdu month names (index 1–12)
  static const months = [
    '', 'جنوری', 'فروری', 'مارچ', 'اپریل', 'مئی', 'جون',
    'جولائی', 'اگست', 'ستمبر', 'اکتوبر', 'نومبر', 'دسمبر',
  ];

  static const monthsUrdu = months;

  static const monthsSindhi = [
    '', 'جنوري', 'فيبروري', 'مارچ', 'اپريل', 'مئي', 'جون',
    'جولاءِ', 'آگسٽ', 'سيپٽمبر', 'آڪٽوبر', 'نومبر', 'ڊسمبر',
  ];

  static const monthsArabic = [
    '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  static List<String> getMonths(String language) {
    if (language == 'sindhi') return monthsSindhi;
    if (language == 'arabic') return monthsArabic;
    return monthsUrdu;
  }

  // Urdu day names (Monday=0 … Sunday=6)
  static const weekdays = [
    'پیر', 'منگل', 'بدھ', 'جمعرات', 'جمعہ', 'ہفتہ', 'اتوار',
  ];

  static const weekdaysUrdu = weekdays;

  static const weekdaysSindhi = [
    'سومر', 'اڱارو', 'اربع', 'خميس', 'جمعو', 'ڇنڇر', 'آچر',
  ];

  static const weekdaysArabic = [
    'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد',
  ];

  static List<String> getWeekdays(String language) {
    if (language == 'sindhi') return weekdaysSindhi;
    if (language == 'arabic') return weekdaysArabic;
    return weekdaysUrdu;
  }

  // Hijri month names (index 1–12)
  static const hijriMonths = [
    '', 'محرم', 'صفر', 'ربیع الاول', 'ربیع الثانی',
    'جمادی الاول', 'جمادی الثانی', 'رجب', 'شعبان',
    'رمضان', 'شوال', 'ذوالقعدہ', 'ذوالحجہ',
  ];

  static const hijriMonthsUrdu = hijriMonths;

  static const hijriMonthsSindhi = [
    '', 'محرم', 'صفر', 'ربيع الاول', 'ربيع الثاني',
    'جمادي الاول', 'جمادي الثاني', 'رجب', 'شعبان',
    'رمضان', 'شوال', 'ذوالقعده', 'ذوالحجه',
  ];

  static const hijriMonthsArabic = [
    '', 'محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر',
    'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان',
    'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة',
  ];

  static List<String> getHijriMonths(String language) {
    if (language == 'sindhi') return hijriMonthsSindhi;
    if (language == 'arabic') return hijriMonthsArabic;
    return hijriMonthsUrdu;
  }

  static const nextPrayerUrdu = nextPrayer;
  static const nextPrayerSindhi = 'اڳلي نماز';
  static const nextPrayerArabic = 'الصلاة القادمة';

  static String getNextPrayerLabel(String language) {
    if (language == 'sindhi') return nextPrayerSindhi;
    if (language == 'arabic') return nextPrayerArabic;
    return nextPrayerUrdu;
  }

  static bool get isFriday => DateTime.now().weekday == DateTime.friday;

  static String toArabicNumerals(int n) {
    const w = ['0','1','2','3','4','5','6','7','8','9'];
    const a = ['۰','۱','۲','۳','۴','۵','۶','۷','۸','۹'];
    var s = n.toString();
    for (int i = 0; i < 10; i++) s = s.replaceAll(w[i], a[i]);
    return s;
  }

  static String todayGregorian(String language) {
    final now = DateTime.now();
    final day   = getWeekdays(language)[now.weekday - 1];
    final month = getMonths(language)[now.month];
    final d     = toArabicNumerals(now.day);
    final y     = toArabicNumerals(now.year);
    return '$day، $d $month $y';
  }
}
