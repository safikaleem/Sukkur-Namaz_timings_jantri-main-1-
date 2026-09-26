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

  static const monthsEnglish = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const monthsHindi = [
    '', 'जनवरी', 'फरवरी', 'मार्च', 'अप्रैल', 'मई', 'जून',
    'जुलाई', 'अगस्त', 'सितंबर', 'अक्टूबर', 'नवंबर', 'दिसंबर',
  ];

  static const monthsBengali = [
    '', 'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
    'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর',
  ];

  static const monthsTurkish = [
    '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];

  static const monthsIndonesian = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  static const monthsFrench = [
    '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
  ];

  static const monthsRussian = [
    '', 'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];

  static const monthsPersian = [
    '', 'ژانویه', 'فوریه', 'مارس', 'آوریل', 'مه', 'ژوئن',
    'ژوئیه', 'اوت', 'سپتامبر', 'اکتبر', 'نوامبر', 'دسامبر',
  ];

  static List<String> getMonths(String language) {
    if (language == 'sindhi') return monthsSindhi;
    if (language == 'arabic') return monthsArabic;
    if (language == 'english') return monthsEnglish;
    if (language == 'hindi') return monthsHindi;
    if (language == 'bengali') return monthsBengali;
    if (language == 'turkish') return monthsTurkish;
    if (language == 'indonesian') return monthsIndonesian;
    if (language == 'french') return monthsFrench;
    if (language == 'russian') return monthsRussian;
    if (language == 'persian') return monthsPersian;
    return monthsUrdu;
  }

  // Urdu day names (Monday=0 … Sunday=6)
  static const weekdays = [
    'پیر', 'منگل', 'بدھ', 'جمعرات', 'جمعہ', 'ہفتہ', 'اتوار',
  ];

  static const weekdaysUrdu = weekdays;

  static const weekdaysEnglish = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  static const weekdaysSindhi = [
    'سومر', 'اڱارو', 'اربع', 'خميس', 'جمعو', 'ڇنڇر', 'آچر',
  ];

  static const weekdaysArabic = [
    'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد',
  ];

  static const weekdaysHindi = [
    'सोमवार', 'मंगलवार', 'बुधवार', 'गुरुवार', 'शुक्रवार', 'शनिवार', 'रविवार',
  ];

  static const weekdaysBengali = [
    'সোমবার', 'মঙ্গলবার', 'বুধবার', 'বৃহস্পতিবার', 'শুক্রবার', 'শনিবার', 'রবিবার',
  ];

  static const weekdaysTurkish = [
    'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar',
  ];

  static const weekdaysIndonesian = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
  ];

  static const weekdaysFrench = [
    'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche',
  ];

  static const weekdaysRussian = [
    'Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье',
  ];

  static const weekdaysPersian = [
    'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنج‌شنبه', 'جمعه', 'شنبه', 'یکشنبه',
  ];

  static List<String> getWeekdays(String language) {
    if (language == 'sindhi') return weekdaysSindhi;
    if (language == 'arabic') return weekdaysArabic;
    if (language == 'english') return weekdaysEnglish;
    if (language == 'hindi') return weekdaysHindi;
    if (language == 'bengali') return weekdaysBengali;
    if (language == 'turkish') return weekdaysTurkish;
    if (language == 'indonesian') return weekdaysIndonesian;
    if (language == 'french') return weekdaysFrench;
    if (language == 'russian') return weekdaysRussian;
    if (language == 'persian') return weekdaysPersian;
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
    for (int i = 0; i < 10; i++) {
      s = s.replaceAll(w[i], a[i]);
    }
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
