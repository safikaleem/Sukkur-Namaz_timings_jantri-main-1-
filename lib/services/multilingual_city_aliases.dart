library;

/// Multi-language city alias mappings and normalization across 10 languages:
/// English, Urdu, Sindhi, Arabic, Hindi, Bengali, Persian, Turkish, French, and Indonesian.

class MultilingualCityAliases {
  MultilingualCityAliases._();

  /// Normalizes Latin diacritics and Arabic/Persian/Sindhi marks
  static String normalize(String input) {
    if (input.isEmpty) return '';
    var s = input.trim().toLowerCase();

    // 1. Remove Arabic/Urdu/Sindhi tashkeel, tatweel, and zero-width characters
    s = s.replaceAll(
      RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED\u0640\u200C\u200D\u200E\u200F\uFEFF]'),
      '',
    );

    // 2. Normalize letter variants in Arabic/Persian/Urdu/Sindhi
    s = s
        .replaceAll('آ', 'ا')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('ٱ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ھ', 'ہ')
        .replaceAll('ۀ', 'ه')
        .replaceAll('ي', 'ی')
        .replaceAll('ى', 'ی')
        .replaceAll('ك', 'ک')
        .replaceAll('ڪ', 'ک')
        .replaceAll('ڳ', 'گ')
        .replaceAll('ٻ', 'ب')
        .replaceAll('ڀ', 'ب')
        .replaceAll('ٺ', 'ٹ')
        .replaceAll('ٽ', 'ٹ')
        .replaceAll('ٿ', 'ت')
        .replaceAll('ڄ', 'ج')
        .replaceAll('ڃ', 'ج')
        .replaceAll('ڇ', 'چ')
        .replaceAll('ڏ', 'د')
        .replaceAll('ڌ', 'د')
        .replaceAll('ڊ', 'ڈ')
        .replaceAll('ڍ', 'ڈ')
        .replaceAll('ڙ', 'ڑ')
        .replaceAll('ڦ', 'ف')
        .replaceAll('کھ', 'ک')
        .replaceAll('ڱ', 'گ')
        .replaceAll('ڻ', 'ن')
        .replaceAll('ݨ', 'ن')
        .replaceAll('ں', 'ن');

    // 3. Remove Latin accents & Turkish/French diacritics
    s = s
        .replaceAll(RegExp(r'[àáâãäåā]'), 'a')
        .replaceAll(RegExp(r'[çćč]'), 'c')
        .replaceAll(RegExp(r'[èéêëē]'), 'e')
        .replaceAll(RegExp(r'[ğ]'), 'g')
        .replaceAll(RegExp(r'[ìíîïīı]'), 'i')
        .replaceAll(RegExp(r'[ñń]'), 'n')
        .replaceAll(RegExp(r'[òóôõöøō]'), 'o')
        .replaceAll(RegExp(r'[şśš]'), 's')
        .replaceAll(RegExp(r'[ùúûüū]'), 'u')
        .replaceAll(RegExp(r'[ýÿ]'), 'y');

    return s.trim();
  }

  /// Multilingual city name mappings: Alias (normalized) -> English city name(s) in cities.txt
  static final Map<String, List<String>> _aliasMap = {
    // ── Pakistan ─────────────────────────────────────────────────────────────
    'کراچی': ['Karachi'],
    'کراتی': ['Karachi'],
    'karaci': ['Karachi'],
    'कराची': ['Karachi'],
    'করাচি': ['Karachi'],
    'لاہور': ['Lahore'],
    'لاهور': ['Lahore'],
    'lahor': ['Lahore'],
    'लाहौर': ['Lahore'],
    'লাহোর': ['Lahore'],
    'اسلام اباد': ['Islamabad'],
    'اسلم اباد': ['Islamabad'],
    'इस्लामाबाद': ['Islamabad'],
    'ইসলামাবাদ': ['Islamabad'],
    'راولپنڈی': ['Rawalpindi'],
    'راولبندی': ['Rawalpindi'],
    'रावलपिंडी': ['Rawalpindi'],
    'রাওয়ালপিন্ডি': ['Rawalpindi'],
    'فیصل اباد': ['Faisalabad'],
    'فيصل اباد': ['Faisalabad'],
    'لایلبور': ['Faisalabad'],
    'لائلپور': ['Faisalabad'],
    'फैसलाबाद': ['Faisalabad'],
    'ফয়সালাবাদ': ['Faisalabad'],
    'ملتان': ['Multan'],
    'مولتان': ['Multan'],
    'मुल्तान': ['Multan'],
    'মুলতান': ['Multan'],
    'پشاور': ['Peshawar'],
    'بیشاور': ['Peshawar'],
    'पेशावर': ['Peshawar'],
    'পেশোয়ার': ['Peshawar'],
    'کوئٹہ': ['Quetta'],
    'کوئٹه': ['Quetta'],
    'کویٹہ': ['Quetta'],
    'کویته': ['Quetta'],
    'کویتہ': ['Quetta'],
    'क्वेटा': ['Quetta'],
    'কোয়েটা': ['Quetta'],
    'سیالکوٹ': ['Sialkot'],
    'سیالکوت': ['Sialkot'],
    'सियालकोट': ['Sialkot'],
    'শিয়ালকোট': ['Sialkot'],
    'گوجرانوالہ': ['Gujranwala'],
    'گوجرانواله': ['Gujranwala'],
    'غوجرانوالا': ['Gujranwala'],
    'गुजरांवाला': ['Gujranwala'],
    'গুজরানওয়ালা': ['Gujranwala'],
    'حیدراباد': ['Hyderabad'],
    'حيدراباد': ['Hyderabad'],
    'हैदराबाद': ['Hyderabad'],
    'হায়দরাবাদ': ['Hyderabad'],
    'لاڑکانہ': ['Larkana'],
    'لاڑکانو': ['Larkana'],
    'لارکانہ': ['Larkana'],
    'لارکانا': ['Larkana'],
    'لارکانه': ['Larkana'],
    'لارکانو': ['Larkana'],
    'लारकाना': ['Larkana'],
    'لاركانا': ['Larkana'],
    'لاركانة': ['Larkana'],
    'نواب شاہ': ['Nawabshah'],
    'نوابشاہ': ['Nawabshah'],
    'نواب شاه': ['Nawabshah'],
    'نوابشاه': ['Nawabshah'],
    'نوابشاهه': ['Nawabshah'],
    'नवाबशाह': ['Nawabshah'],
    'میرپور خاص': ['Mirpur Khas'],
    'میرپورخاص': ['Mirpur Khas'],
    'ميرپور خاص': ['Mirpur Khas'],
    'ميرپورخاص': ['Mirpur Khas'],
    'मीरपुर ख़ास': ['Mirpur Khas'],
    'مردان': ['Mardan'],
    'मरदान': ['Mardan'],
    'মারদান': ['Mardan'],
    'گجرات': ['Gujrat'],
    'غوجرات': ['Gujrat'],
    'गुजरात': ['Gujrat'],
    'গুজরাট': ['Gujrat'],
    'قصور': ['Kasur'],
    'कसूर': ['Kasur'],
    'কসুর': ['Kasur'],
    'رحیم یار خان': ['Rahim Yar Khan'],
    'رحیمیارخان': ['Rahim Yar Khan'],
    'रहीम यार ख़ान': ['Rahim Yar Khan'],
    'اوکاڑہ': ['Okara'],
    'اوکاره': ['Okara'],
    'اوکارا': ['Okara'],
    'ओकारा': ['Okara'],
    'وہاڑی': ['Vehari'],
    'وهاری': ['Vehari'],
    'विहारी': ['Vehari'],
    'خانیوال': ['Khanewal'],
    'खानेवाल': ['Khanewal'],
    'ڈیرہ غازی خان': ['Dera Ghazi Khan'],
    'دیره غازی خان': ['Dera Ghazi Khan'],
    'डेरा गाज़ी खान': ['Dera Ghazi Khan'],
    'ڈیرہ اسماعیل خان': ['Dera Ismail Khan'],
    'دیره اسماعیل خان': ['Dera Ismail Khan'],
    'डेरा इस्माइल खान': ['Dera Ismail Khan'],
    'مظفر اباد': ['Muzaffarabad'],
    'مظفراباد': ['Muzaffarabad'],
    'मुज़फ़्फ़राबाद': ['Muzaffarabad'],
    'گلگت': ['Gilgit'],
    'جلجت': ['Gilgit'],
    'गिलगित': ['Gilgit'],
    'سکردو': ['Skardu'],
    'اسکردو': ['Skardu'],
    'اسکاردو': ['Skardu'],
    'स्कर्दू': ['Skardu'],
    'چترال': ['Chitral'],
    'चित्राल': ['Chitral'],
    'ایبٹ اباد': ['Abbottabad'],
    'ایبٹاباد': ['Abbottabad'],
    'ابت اباد': ['Abbottabad'],
    'ऐबटाबाद': ['Abbottabad'],
    'ہری پور': ['Haripur'],
    'هری بور': ['Haripur'],
    'हरिपुर': ['Haripur'],
    'کوہاٹ': ['Kohat'],
    'کوهات': ['Kohat'],
    'कोहाट': ['Kohat'],
    'بنوں': ['Bannu'],
    'بنو': ['Bannu'],
    'بنون': ['Bannu'],
    'बन्नू': ['Bannu'],
    'جھنگ': ['Jhang'],
    'جهنگ': ['Jhang'],
    'झंग': ['Jhang'],
    'چکوال': ['Chakwal'],
    'चकवाल': ['Chakwal'],
    'جہلم': ['Jhelum'],
    'جهلم': ['Jhelum'],
    'झेलम': ['Jhelum'],
    'اٹک': ['Attock'],
    'اتک': ['Attock'],
    'अटक': ['Attock'],
    'خضدار': ['Khuzdar'],
    'खुजदार': ['Khuzdar'],
    'گوادر': ['Gwadar'],
    'گودر': ['Gwadar'],
    'ग्वादर': ['Gwadar'],
    'تربت': ['Turbat'],
    'توربات': ['Turbat'],
    'तुरबत': ['Turbat'],
    'شیخوپورہ': ['Sheikhupura'],
    'شیخوبوره': ['Sheikhupura'],
    'शेखूपुरा': ['Sheikhupura'],
    'ساہیوال': ['Sahiwal'],
    'ساهیوال': ['Sahiwal'],
    'साहीवाल': ['Sahiwal'],
    'شکارپور': ['Shikarpur'],
    'شیکاربور': ['Shikarpur'],
    'शिकारपुर': ['Shikarpur'],
    'جیکب اباد': ['Jacobabad'],
    'جیکباباد': ['Jacobabad'],
    'یعقوب اباد': ['Jacobabad'],
    'जैकोबाबाद': ['Jacobabad'],
    'خیرپور': ['Khairpur'],
    'خیربور': ['Khairpur'],
    'खैरपुर': ['Khairpur'],
    'کوٹری': ['Kotri'],
    'کوتری': ['Kotri'],
    'कोटड़ी': ['Kotri'],
    'بدین': ['Badin'],
    'बदीन': ['Badin'],
    'ٹھٹہ': ['Thatta'],
    'تھٹہ': ['Thatta'],
    'ٹھٹو': ['Thatta'],
    'ठट्ठा': ['Thatta'],
    'دادو': ['Dadu'],
    'दादू': ['Dadu'],
    'گھوٹکی': ['Ghotki'],
    'گهوتکی': ['Ghotki'],
    'घोटकी': ['Ghotki'],
    'پنوعاقل': ['Pano Aqil'],
    'پنو عاقل': ['Pano Aqil'],
    'पन्नू आकिल': ['Pano Aqil'],
    'روہڑی': ['Rohri'],
    'روهری': ['Rohri'],
    'रोहड़ी': ['Rohri'],

    // ── Middle East & Islamic Holy Cities ─────────────────────────────────────
    'مکہ': ['Makkah', 'Mecca'],
    'مکه': ['Makkah', 'Mecca'],
    'مکہ مکرمہ': ['Makkah'],
    'مکه مکرمه': ['Makkah'],
    'मक्का': ['Makkah', 'Mecca'],
    'মক্কা': ['Makkah', 'Mecca'],
    'mecca': ['Makkah', 'Mecca'],
    'mekkah': ['Makkah', 'Mecca'],
    'mekke': ['Makkah', 'Mecca'],
    'la mecque': ['Makkah', 'Mecca'],
    'مدینہ': ['Madinah', 'Medina'],
    'مدینه': ['Madinah', 'Medina'],
    'المدینہ': ['Madinah', 'Medina'],
    'المدینه': ['Madinah', 'Medina'],
    'مدینہ منورہ': ['Madinah'],
    'مدینه منوره': ['Madinah'],
    'मदीना': ['Madinah', 'Medina'],
    'মদিনা': ['Madinah', 'Medina'],
    'medina': ['Madinah', 'Medina'],
    'medine': ['Madinah', 'Medina'],
    'جدہ': ['Jeddah'],
    'جده': ['Jeddah'],
    'जेद्दा': ['Jeddah'],
    'জেদ্দা': ['Jeddah'],
    'jedda': ['Jeddah'],
    'cidde': ['Jeddah'],
    'ریاض': ['Riyadh'],
    'الریاض': ['Riyadh'],
    'रियाद': ['Riyadh'],
    'রিয়াদ': ['Riyadh'],
    'riyad': ['Riyadh'],
    'دمام': ['Dammam'],
    'الدمام': ['Dammam'],
    'dammam': ['Dammam'],
    'دبئی': ['Dubai'],
    'دبی': ['Dubai'],
    'दुबई': ['Dubai'],
    'দুবাই': ['Dubai'],
    'dubay': ['Dubai'],
    'ابوظہبی': ['Abu Dhabi'],
    'ابوظبی': ['Abu Dhabi'],
    'अबू धाबी': ['Abu Dhabi'],
    'আবুধাবি': ['Abu Dhabi'],
    'abu dabi': ['Abu Dhabi'],
    'شارجہ': ['Sharjah'],
    'شارجه': ['Sharjah'],
    'الشارقہ': ['Sharjah'],
    'الشارقه': ['Sharjah'],
    'शारजाह': ['Sharjah'],
    'শারজাহ': ['Sharjah'],
    'şarika': ['Sharjah'],
    'شارقة': ['Sharjah'],
    'عجمان': ['Ajman'],
    'راس الخیمہ': ['Ras Al Khaimah'],
    'راس الخیمه': ['Ras Al Khaimah'],
    'دوحہ': ['Doha'],
    'دوحه': ['Doha'],
    'الدوحہ': ['Doha'],
    'الدوحه': ['Doha'],
    'दोहा': ['Doha'],
    'দোহা': ['Doha'],
    'کویت': ['Kuwait City'],
    'الکویت': ['Kuwait City'],
    'کويت': ['Kuwait City'],
    'कुवैत': ['Kuwait City'],
    'কুয়েত': ['Kuwait City'],
    'kuveyt': ['Kuwait City'],
    'مسقط': ['Muscat'],
    'मस्कट': ['Muscat'],
    'মাস্কাট': ['Muscat'],
    'maskat': ['Muscat'],
    'منامہ': ['Manama'],
    'منامه': ['Manama'],
    'المنامہ': ['Manama'],
    'المنامه': ['Manama'],
    'मनामा': ['Manama'],
    'মানামা': ['Manama'],
    'قاہرہ': ['Cairo'],
    'قاهره': ['Cairo'],
    'القاہرہ': ['Cairo'],
    'القاهره': ['Cairo'],
    'काहिरा': ['Cairo'],
    'কায়রো': ['Cairo'],
    'kairo': ['Cairo'],
    'kahire': ['Cairo'],
    'le caire': ['Cairo'],
    'اسکندریہ': ['Alexandria'],
    'الاسکندریہ': ['Alexandria'],
    'الإسکندریہ': ['Alexandria'],
    'الإسكندرية': ['Alexandria'],
    'सिकंदरिया': ['Alexandria'],
    'iskenderiye': ['Alexandria'],
    'استنبول': ['Istanbul'],
    'استانبول': ['Istanbul'],
    'إسطنبول': ['Istanbul'],
    'اسطنبول': ['Istanbul'],
    'इस्तांबुल': ['Istanbul'],
    'ইস্তাম্বুল': ['Istanbul'],
    'istambul': ['Istanbul'],
    'انقرہ': ['Ankara'],
    'انقره': ['Ankara'],
    'آنکارا': ['Ankara'],
    'अंकारा': ['Ankara'],
    'আঙ্কারা': ['Ankara'],
    'ازمیر': ['Izmir'],
    'إزمير': ['Izmir'],
    'تہران': ['Tehran'],
    'طہران': ['Tehran'],
    'طهران': ['Tehran'],
    'تهران': ['Tehran'],
    'तेहरान': ['Tehran'],
    'তেহরান': ['Tehran'],
    'tahran': ['Tehran'],
    'teheran': ['Tehran'],
    'مشہد': ['Mashhad'],
    'مشهد': ['Mashhad'],
    'मशहद': ['Mashhad'],
    'اصفہان': ['Isfahan'],
    'اصفهان': ['Isfahan'],
    'شیراز': ['Shiraz'],
    'تبریز': ['Tabriz'],
    'قم': ['Qom'],
    'بغداد': ['Baghdad'],
    'बगदाद': ['Baghdad'],
    'বাগদাদ': ['Baghdad'],
    'bagdad': ['Baghdad'],
    'کربلا': ['Karbala'],
    'کربلاء': ['Karbala'],
    'कर्बला': ['Karbala'],
    'نجف': ['Najaf'],
    'النجف': ['Najaf'],
    'नजफ़': ['Najaf'],
    'بصرہ': ['Basra'],
    'بصره': ['Basra'],
    'البصرہ': ['Basra'],
    'البصره': ['Basra'],
    'دمشق': ['Damascus'],
    'الدمشق': ['Damascus'],
    'दमिश्क़': ['Damascus'],
    'দামেস্ক': ['Damascus'],
    'sam': ['Damascus'],
    'şam': ['Damascus'],
    'damas': ['Damascus'],
    'حلب': ['Aleppo'],
    'بیروت': ['Beirut'],
    'बेरुत': ['Beirut'],
    'বৈরুত': ['Beirut'],
    'beyrut': ['Beirut'],
    'عمان': ['Amman'],
    'अम्मान': ['Amman'],
    'আম্মান': ['Amman'],
    'یروشلم': ['Jerusalem'],
    'یروشلیم': ['Jerusalem'],
    'القدس': ['Jerusalem'],
    'قدس': ['Jerusalem'],
    'بیت المقدس': ['Jerusalem'],
    'यरूशलम': ['Jerusalem'],
    'জেরুজালেম': ['Jerusalem'],
    'kudus': ['Jerusalem'],
    'yerusalem': ['Jerusalem'],
    'کابل': ['Kabul'],
    'काबुल': ['Kabul'],
    'কাবুল': ['Kabul'],
    'قندھار': ['Kandahar'],
    'قندهار': ['Kandahar'],
    'कंधार': ['Kandahar'],

    // ── South & South-East Asia ───────────────────────────────────────────────
    'ڈھاکہ': ['Dhaka'],
    'دھاکہ': ['Dhaka'],
    'دکا': ['Dhaka'],
    'ढाका': ['Dhaka'],
    'ঢাকা': ['Dhaka'],
    'dacca': ['Dhaka'],
    'چٹاگانگ': ['Chittagong'],
    'চট্টগ্রাম': ['Chittagong'],
    'سلہٹ': ['Sylhet'],
    'সিলেট': ['Sylhet'],
    'دہلی': ['Delhi'],
    'دلی': ['Delhi'],
    'दिल्ली': ['Delhi'],
    'দিল্লি': ['Delhi'],
    'نئی دہلی': ['New Delhi'],
    'نیو دہلی': ['New Delhi'],
    'नई दिल्ली': ['New Delhi'],
    'নয়া দিল্লি': ['New Delhi'],
    'ممبئی': ['Mumbai'],
    'بمبئی': ['Mumbai'],
    'मुंबई': ['Mumbai'],
    'মুম্বাই': ['Mumbai'],
    'کولکاتا': ['Kolkata'],
    'کلکتہ': ['Kolkata'],
    'कोलकाता': ['Kolkata'],
    'কলকাতা': ['Kolkata'],
    'چنائی': ['Chennai'],
    'مدراس': ['Chennai'],
    'चेन्नई': ['Chennai'],
    'بنگلور': ['Bengaluru'],
    'बेंगलुरु': ['Bengaluru'],
    'لکھنؤ': ['Lucknow'],
    'लखनऊ': ['Lucknow'],
    'آگرہ': ['Agra'],
    'आगरा': ['Agra'],
    'سری نگر': ['Srinagar'],
    'سرینگر': ['Srinagar'],
    'श्रीनगर': ['Srinagar'],
    'کولمبو': ['Colombo'],
    'कोलंबो': ['Colombo'],
    'کوالالمپور': ['Kuala Lumpur'],
    'کوالا لمپور': ['Kuala Lumpur'],
    'كوالالمبور': ['Kuala Lumpur'],
    'क्वालालंपुर': ['Kuala Lumpur'],
    'কুয়ালালামপুর': ['Kuala Lumpur'],
    'جکارتہ': ['Jakarta'],
    'جاکارتا': ['Jakarta'],
    'جاكارتا': ['Jakarta'],
    'जकार्ता': ['Jakarta'],
    'জাকার্তা': ['Jakarta'],
    'سرابایا': ['Surabaya'],
    'سورابایا': ['Surabaya'],
    'بانڈونگ': ['Bandung'],
    'باندونگ': ['Bandung'],
    'مدان': ['Medan'],

    // ── Europe, Americas & Beyond ─────────────────────────────────────────────
    'لندن': ['London'],
    'लंदन': ['London'],
    'লন্ডন': ['London'],
    'londres': ['London'],
    'برمنگھم': ['Birmingham'],
    'बर्मिंघम': ['Birmingham'],
    'مانچسٹر': ['Manchester'],
    'मैनचेस्टर': ['Manchester'],
    'پیرس': ['Paris'],
    'باریس': ['Paris'],
    'पेरिस': ['Paris'],
    'প্যারিস': ['Paris'],
    'برلن': ['Berlin'],
    'बर्लिन': ['Berlin'],
    'বার্লিন': ['Berlin'],
    'فرینکفرٹ': ['Frankfurt'],
    'فرانکفورت': ['Frankfurt'],
    'फ्रैंकफर्ट': ['Frankfurt'],
    'ایمسٹرڈم': ['Amsterdam'],
    'امستردام': ['Amsterdam'],
    'एम्स्टर्डम': ['Amsterdam'],
    'روم': ['Rome'],
    'روما': ['Rome'],
    'रोम': ['Rome'],
    'میڈرڈ': ['Madrid'],
    'مدرید': ['Madrid'],
    'मैड्रिड': ['Madrid'],
    'بارسلونا': ['Barcelona'],
    'برشلونہ': ['Barcelona'],
    'برشلونه': ['Barcelona'],
    'बार्सिलोना': ['Barcelona'],
    'جنیوا': ['Geneva'],
    'ژنو': ['Geneva'],
    'جينيف': ['Geneva'],
    'موسکو': ['Moscow'],
    'ماسکو': ['Moscow'],
    'نیویارک': ['New York'],
    'نیو یارک': ['New York'],
    'نيويورك': ['New York'],
    'न्यूयॉर्क': ['New York'],
    'নিউ ইয়র্ক': ['New York'],
    'شکاگو': ['Chicago'],
    'شیکاغو': ['Chicago'],
    'শিকাগো': ['Chicago'],
    'لاس اینجلس': ['Los Angeles'],
    'لوس انجلوس': ['Los Angeles'],
    'लॉस एंजिल्स': ['Los Angeles'],
    'ہیوسٹن': ['Houston'],
    'هیوستن': ['Houston'],
    'ह्यूस्टन': ['Houston'],
    'ٹورنٹو': ['Toronto'],
    'تورونتو': ['Toronto'],
    'टोरंटो': ['Toronto'],
    'টরন্টো': ['Toronto'],
    'سڈنی': ['Sydney'],
    'سیدنی': ['Sydney'],
    'सिडनी': ['Sydney'],
    'میلبورن': ['Melbourne'],
    'ملبورن': ['Melbourne'],
    'मेलबर्न': ['Melbourne'],
    'ٹوکیو': ['Tokyo'],
    'طوکیو': ['Tokyo'],
    'टोक्यो': ['Tokyo'],
    'بیجنگ': ['Beijing'],
    'بکین': ['Beijing'],
  };

  /// Country alias mappings: Alias (normalized) -> English Country name in country_names.dart
  static final Map<String, String> _countryAliasMap = {
    'پاکستان': 'Pakistan',
    'باكستان': 'Pakistan',
    'پاڪستان': 'Pakistan',
    'पाकिस्तान': 'Pakistan',
    'পাকিস্তান': 'Pakistan',
    'سعودی عرب': 'Saudi Arabia',
    'سعودیه': 'Saudi Arabia',
    'السعودیہ': 'Saudi Arabia',
    'السعودية': 'Saudi Arabia',
    'سعودی': 'Saudi Arabia',
    'سعودي': 'Saudi Arabia',
    'सऊदी अरब': 'Saudi Arabia',
    'সৌদি আরব': 'Saudi Arabia',
    'arab saudi': 'Saudi Arabia',
    'arabie saoudite': 'Saudi Arabia',
    'suudi arabistan': 'Saudi Arabia',
    'بھارت': 'India',
    'ہندوستان': 'India',
    'هندوستان': 'India',
    'هند': 'India',
    'الهند': 'India',
    'भारत': 'India',
    'ভারত': 'India',
    'inde': 'India',
    'hindistan': 'India',
    'ترکی': 'Turkey',
    'تركيا': 'Turkey',
    'ترکیہ': 'Turkey',
    'ترکیه': 'Turkey',
    'तुर्की': 'Turkey',
    'তুরস্ক': 'Turkey',
    'turkiye': 'Turkey',
    'turquie': 'Turkey',
    'امارات': 'United Arab Emirates',
    'الامارات': 'United Arab Emirates',
    'یو اے ای': 'United Arab Emirates',
    'संयुक्त अरब अमीरात': 'United Arab Emirates',
    'সংযুক্ত আরব আমিরাত': 'United Arab Emirates',
    'birlesik arap emirlikleri': 'United Arab Emirates',
    'emirats arabes unis': 'United Arab Emirates',
    'مصر': 'Egypt',
    'misir': 'Egypt',
    'egypte': 'Egypt',
    'मिस्र': 'Egypt',
    'মিসর': 'Egypt',
    'ایران': 'Iran',
    'ইরান': 'Iran',
    'ईरान': 'Iran',
    'بنگلہ دیش': 'Bangladesh',
    'بنگله دیش': 'Bangladesh',
    'بنغلاديش': 'Bangladesh',
    'বাংলাদেশ': 'Bangladesh',
    'बांग्लादेश': 'Bangladesh',
    'انڈونیشیا': 'Indonesia',
    'اندونیسیا': 'Indonesia',
    'إندونيسيا': 'Indonesia',
    'ইন্ডোনেশিয়া': 'Indonesia',
    'इंडोनेशिया': 'Indonesia',
    'برطانیہ': 'United Kingdom',
    'بريطانيا': 'United Kingdom',
    'যুক্তরাজ্য': 'United Kingdom',
    'यूनाइटेड किंगडम': 'United Kingdom',
    'royaume-uni': 'United Kingdom',
    'birlesik krallik': 'United Kingdom',
    'امریکہ': 'United States',
    'امريکہ': 'United States',
    'امريكا': 'United States',
    'যুক্তরাষ্ট্র': 'United States',
    'अमेरिका': 'United States',
    'etats-unis': 'United States',
    'amerika birlesik devletleri': 'United States',
    'فرانس': 'France',
    'fransa': 'France',
    'جرمنی': 'Germany',
    'جرمني': 'Germany',
    'المانيا': 'Germany',
    'allemagne': 'Germany',
    'almanya': 'Germany',
    'کینیڈا': 'Canada',
    'ڪئناڊا': 'Canada',
    'کندا': 'Canada',
    'kanada': 'Canada',
    'افغانستان': 'Afghanistan',
    'عراق': 'Iraq',
    'irak': 'Iraq',
    'شام': 'Syria',
    'سوریا': 'Syria',
    'suriye': 'Syria',
    'فلسطین': 'Palestinian Territory',
    'عمان': 'Oman',
    'قطر': 'Qatar',
    'بحرین': 'Bahrain',
    'کویت': 'Kuwait',
    'ملائیشیا': 'Malaysia',
    'ملیشیا': 'Malaysia',
    'malezya': 'Malaysia',
  };

  /// Returns matching English city names for [query] across all 10 languages
  static List<String> getMatchingEnglishCities(String query) {
    final clean = normalize(query);
    if (clean.isEmpty) return const [];

    final matches = <String>[];
    final seen = <String>{};

    final candidates = <String>[clean];
    if (clean.startsWith('ال') && clean.length > 4) {
      candidates.add(clean.substring(2));
    }

    for (final cand in candidates) {
      // 1. Direct exact alias match
      final direct = _aliasMap[cand];
      if (direct != null) {
        for (final city in direct) {
          if (seen.add(city.toLowerCase())) {
            matches.add(city);
          }
        }
      }

      // 2. Prefix match across aliases (e.g. typing "کر" matches "کراچی" -> Karachi)
      for (final entry in _aliasMap.entries) {
        if (entry.key.startsWith(cand)) {
          for (final city in entry.value) {
            if (seen.add(city.toLowerCase())) {
              matches.add(city);
            }
          }
        }
      }
    }

    return matches;
  }

  /// Returns matching English country names for [query] across all 10 languages
  static List<String> getMatchingCountries(String query) {
    final clean = normalize(query);
    if (clean.isEmpty) return const [];

    final matches = <String>[];
    final seen = <String>{};

    final candidates = <String>[clean];
    if (clean.startsWith('ال') && clean.length > 4) {
      candidates.add(clean.substring(2));
    }

    for (final cand in candidates) {
      final direct = _countryAliasMap[cand];
      if (direct != null && seen.add(direct.toLowerCase())) {
        matches.add(direct);
      }

      for (final entry in _countryAliasMap.entries) {
        if (entry.key.startsWith(cand)) {
          final c = entry.value;
          if (seen.add(c.toLowerCase())) {
            matches.add(c);
          }
        }
      }
    }

    return matches;
  }
}
