class ParahQuarter {
  final int surahId;
  final int ayahId;
  final int page;
  const ParahQuarter(this.surahId, this.ayahId, this.page);
}

class Parah {
  final int number;
  final String english;
  final String arabic;
  final String urdu;
  final String sindhi;
  final int startPage;
  final int surahId;
  final int ayahId;
  final ParahQuarter arba;
  final ParahQuarter nisf;
  final ParahQuarter salasa;

  const Parah(this.number, this.english, this.arabic, this.urdu, this.sindhi, this.startPage, this.surahId, this.ayahId, this.arba, this.nisf, this.salasa);
}

class Surah {
  final int number;
  final String english;
  final String arabic;
  final String urdu;
  final String sindhi;
  final String arabicOnly;
  final int totalAyahs;
  final String revelationType;

  const Surah(this.number, this.english, this.arabic, this.urdu, this.sindhi, this.arabicOnly, this.totalAyahs, this.revelationType);
}

class QuranData {
  static const parahs = [
    Parah(1,  'Alif Lam Meem',            'الم',              'الم',              'الم',              2,   1,  1,   ParahQuarter(2, 46, 8),   ParahQuarter(2, 82, 12),   ParahQuarter(2, 112, 17)),
    Parah(2,  'Sayaqool',                 'سيقول',            'سيقول',            'سيقول',            21,  2,  142, ParahQuarter(2, 176, 25),  ParahQuarter(2, 210, 30),  ParahQuarter(2, 231, 35)),
    Parah(3,  'Tilkal Rusul',             'تلك الرسل',        'تلك الرسل',        'تلك الرسل',        39,  2,  253, ParahQuarter(2, 273, 43),  ParahQuarter(3, 20, 48),   ParahQuarter(3, 54, 52)),
    Parah(4,  'Lan Tana Loo',             'لن تنالوا',        'لن تنالوا',        'لن تنالوا',        57,  3,  93,  ParahQuarter(3, 129, 61),  ParahQuarter(3, 171, 66),  ParahQuarter(3, 200, 70)),
    Parah(5,  'Wal Mohsanat',             'والمحصنات',        'والمحصنات',        'والمحصنات',        75,  4,  24,  ParahQuarter(4, 59, 80),   ParahQuarter(4, 87, 84),   ParahQuarter(4, 115, 88)),
    Parah(6,  'La Yuhibbullah',           'لا يحب الله',      'لا يحب الله',      'لا يحب الله',      93, 4,  148, ParahQuarter(5, 5, 98),    ParahQuarter(5, 34, 103),   ParahQuarter(5, 56, 107)),
    Parah(7,  'Wa Iza Samiu',             'وإذا سمعوا',       'وإذا سمعوا',       'وإذا سمعوا',       111, 5,  82,  ParahQuarter(5, 115, 115), ParahQuarter(6, 41, 120),   ParahQuarter(6, 82, 125)),
    Parah(8,  'Wa Lau Annana',            'ولو أننا',         'ولو أننا',         'ولو أننا',         129, 6,  111, ParahQuarter(6, 140, 132), ParahQuarter(6, 165, 136),  ParahQuarter(7, 47, 142)),
    Parah(9,  'Qalal Malao',              'قال الملأ',        'قال الملأ',        'قال الملأ',        147, 7,  88,  ParahQuarter(7, 141, 151), ParahQuarter(7, 171, 156),  ParahQuarter(7, 206, 160)),
    Parah(10, 'Wa Alamu',                 'واعلموا',          'واعلموا',          'واعلموا',          165, 8,  41,  ParahQuarter(8, 75, 169),  ParahQuarter(9, 37, 175),   ParahQuarter(9, 66, 178)),
    Parah(11, 'Yatazeroon',               'يعتذرون',          'يعتذرون',          'يعتذرون',          183, 9,  93,  ParahQuarter(9, 129, 188),  ParahQuarter(10, 30, 192),  ParahQuarter(10, 70, 196)),
    Parah(12, 'Wa Ma Min Dabbah',         'وما من دابة',      'وما من دابة',      'وما من دابة',      201, 11, 6,   ParahQuarter(11, 49, 205),  ParahQuarter(11, 83, 209),  ParahQuarter(12, 20, 214)),
    Parah(13, 'Wa Ma Ubarri\'u',          'وما أبرئ',         'وما أبرئ',         'وما أبرئ',         219, 12, 53,  ParahQuarter(12, 104, 224), ParahQuarter(13, 18, 227),  ParahQuarter(14, 12, 232)),
    Parah(14, 'Rubama',                   'ربما',             'ربما',             'ربما',             237, 15, 1,   ParahQuarter(15, 99, 241),  ParahQuarter(16, 50, 246),  ParahQuarter(16, 89, 250)),
    Parah(15, 'Subhanallazi',             'سبحان الذي',       'سبحان الذي',       'سبحان الذي',       255, 17, 1,   ParahQuarter(17, 52, 260),  ParahQuarter(17, 100, 264), ParahQuarter(18, 31, 269)),
    Parah(16, 'Qal Alam',                 'قال ألم',          'قال ألم',          'قال ألم',          273, 18, 75,  ParahQuarter(19, 14, 278),  ParahQuarter(19, 98, 282),  ParahQuarter(20, 76, 286)),
    Parah(17, 'Iqtaraba',                 'اقترب',            'اقترب',            'اقترب',            291, 21, 1,   ParahQuarter(21, 50, 295),  ParahQuarter(21, 112, 299), ParahQuarter(22, 38, 304)),
    Parah(18, 'Qad Aflaha',               'قد أفلح',          'قد أفلح',          'قد أفلح',          309, 23, 1,   ParahQuarter(23, 77, 313),  ParahQuarter(24, 20, 318),  ParahQuarter(24, 50, 322)),
    Parah(19, 'Wa Qalallazina',           'وقال الذين',       'وقال الذين',       'وقال الذين',       327, 25, 21,  ParahQuarter(25, 77, 331),  ParahQuarter(26, 122, 336), ParahQuarter(27, 14, 341)),
    Parah(20, 'Amman Khalaq',             'أمن خلق',          'أمن خلق',          'أمن خلق',          345, 27, 56,  ParahQuarter(28, 13, 349),  ParahQuarter(28, 60, 355),  ParahQuarter(28, 88, 358)),
    Parah(21, 'Utlu Ma Oohia',            'اتل ما أوحي',      'اتل ما أوحي',      'اتل ما أوحي',      363, 29, 46,  ParahQuarter(30, 27, 367),  ParahQuarter(31, 19, 373),  ParahQuarter(32, 30, 377)),
    Parah(22, 'Wa Man Yaqnut',            'ومن يقنت',         'ومن يقنت',         'ومن يقنت',         381, 33, 31,  ParahQuarter(33, 68, 385),  ParahQuarter(34, 30, 389),  ParahQuarter(35, 14, 394)),
    Parah(23, 'Wa Mali',                  'ومالي',            'ومالي',            'ومالي',            399, 36, 28,  ParahQuarter(37, 74, 405),  ParahQuarter(37, 182, 409), ParahQuarter(38, 63, 412)),
    Parah(24, 'Faman Azlamu',             'فمن أظلم',         'فمن أظلم',         'فمن أظلم',         417, 39, 32,  ParahQuarter(39, 75, 421),  ParahQuarter(40, 50, 426),  ParahQuarter(41, 8, 430)),
    Parah(25, 'Elahe Yuruddu',            'إليه يرد',         'إليه يرد',         'إليه يرد',         435, 41, 47,  ParahQuarter(42, 29, 439),  ParahQuarter(43, 25, 443),  ParahQuarter(44, 29, 448)),
    Parah(26, 'Ha Meem',                  'حم',               'حم',               'حم',               453, 46, 1,   ParahQuarter(46, 35, 457),  ParahQuarter(48, 17, 463),  ParahQuarter(49, 10, 466)),
    Parah(27, 'Qala Fama Khatbukum',      'قال فما خطبكم',    'قال فما خطبكم',    'قال فما خطبكم',    471, 51, 31,  ParahQuarter(53, 32, 476),  ParahQuarter(55, 25, 480),  ParahQuarter(56, 74, 484)),
    Parah(28, 'Qad Sami Allah',           'قد سمع الله',      'قد سمع الله',      'قد سمع الله',      489, 58, 1,   ParahQuarter(59, 10, 494),  ParahQuarter(60, 13, 498),  ParahQuarter(64, 10, 504)),
    Parah(29, 'Tabarakallazi',            'تبارك الذي',       'تبارك الذي',       'تبارك الذي',       509, 67, 1,   ParahQuarter(68, 52, 513),  ParahQuarter(71, 28, 519),  ParahQuarter(74, 56, 524)),
    Parah(30, 'Amma',                     'عم',               'عم',               'عم',               529, 78, 1,   ParahQuarter(82, 19, 534),  ParahQuarter(88, 26, 539),  ParahQuarter(97, 5, 544)),
  ];

  static const surahs = [
    Surah(1,   'Al-Fatihah',     'الفاتحة',  'الفاتحہ',       'فاتحہ',    'الفاتحة',  7,   'Meccan'),
    Surah(2,   'Al-Baqarah',     'البقرة',   'البقرہ',        'بقره',     'البقرة',   286, 'Medinan'),
    Surah(3,   'Aal-E-Imran',    'آل عمران', 'آل عمران',      'آل عمران', 'آل عمران', 200, 'Medinan'),
    Surah(4,   'An-Nisa',        'النساء',   'النساء',        'نساء',     'النساء',   176, 'Medinan'),
    Surah(5,   'Al-Maidah',      'المائدة',  'المائدة',       'مائده',    'المائدة',  120, 'Medinan'),
    Surah(6,   'Al-Anam',        'الأنعام',  'الأنعام',       'انعام',    'الأنعام',  165, 'Meccan'),
    Surah(7,   'Al-Araf',        'الأعراف',  'الأعراف',       'اعراف',    'الأعراف',  206, 'Meccan'),
    Surah(8,   'Al-Anfal',       'الأنفال',  'الأنفال',       'انفال',    'الأنفال',  75,  'Medinan'),
    Surah(9,   'At-Tawbah',      'التوبة',   'التوبة',        'توبه',     'التوبة',   129, 'Medinan'),
    Surah(10,  'Yunus',          'يونس',     'یونس',          'يونس',     'يونس',     109, 'Meccan'),
    Surah(11,  'Hud',            'هود',      'ہود',           'هود',      'هود',      123, 'Meccan'),
    Surah(12,  'Yusuf',          'يوسف',     'یوسف',          'يوسف',     'يوسف',     111, 'Meccan'),
    Surah(13,  'Ar-Rad',         'الرعد',    'الرعد',         'رعد',      'الرعد',    43,  'Medinan'),
    Surah(14,  'Ibrahim',        'إبراهيم',  'ابراہیم',       'ابراهيم',  'إبراهيم',  52,  'Meccan'),
    Surah(15,  'Al-Hijr',        'الحجر',    'الحجر',         'حجر',      'الحجر',    99,  'Meccan'),
    Surah(16,  'An-Nahl',        'النحل',    'النحل',         'نحل',      'النحل',    128, 'Meccan'),
    Surah(17,  'Al-Isra',        'الإسراء',  'الإسراء',       'اسراء',    'الإسراء',  111, 'Meccan'),
    Surah(18,  'Al-Kahf',        'الكهف',    'الکہف',         'ڪهف',      'الكهف',    110, 'Meccan'),
    Surah(19,  'Maryam',         'مريم',     'مریم',          'مريم',     'مريم',     98,  'Meccan'),
    Surah(20,  'Ta-Ha',          'طه',       'طہ',            'طه',       'طه',       135, 'Meccan'),
    Surah(21,  'Al-Anbiya',      'الأنبياء', 'الأنبیاء',      'انبياء',   'الأنبياء', 112, 'Meccan'),
    Surah(22,  'Al-Hajj',        'الحج',     'الحج',          'حج',       'الحج',     78,  'Medinan'),
    Surah(23,  'Al-Muminun',     'المؤمنون', 'المومنون',      'مومنون',   'المؤمنون', 118, 'Meccan'),
    Surah(24,  'An-Nur',         'النور',    'النور',         'نور',      'النور',    64,  'Medinan'),
    Surah(25,  'Al-Furqan',      'الفرقان',  'الفرقان',       'فرقان',    'الفرقان',  77,  'Meccan'),
    Surah(26,  'Ash-Shuara',     'الشعراء',  'الشعراء',       'شاعر',     'الشعراء',  227, 'Meccan'),
    Surah(27,  'An-Naml',        'النمل',    'النمل',         'نمل',      'النمل',    93,  'Meccan'),
    Surah(28,  'Al-Qasas',       'القصص',    'القصص',         'قصص',      'القصص',    88,  'Meccan'),
    Surah(29,  'Al-Ankabut',     'العنكبوت', 'العنکبوت',      'عنڪبوت',   'العنكبوت', 69,  'Meccan'),
    Surah(30,  'Ar-Rum',         'الروم',    'الروم',         'روم',      'الروم',    60,  'Meccan'),
    Surah(31,  'Luqman',         'لقمان',    'لقمان',         'لقمان',    'لقمان',    34,  'Meccan'),
    Surah(32,  'As-Sajdah',      'السجدة',   'السجدہ',        'سجده',     'السجدة',   30,  'Meccan'),
    Surah(33,  'Al-Ahzab',       'الأحزاب',  'الأحزاب',       'احزاب',    'الأحزاب',  73,  'Medinan'),
    Surah(34,  'Saba',           'سبأ',      'سبا',           'سبا',      'سبأ',      54,  'Meccan'),
    Surah(35,  'Fatir',          'فاطر',     'فاطر',          'فاطر',     'فاطر',     45,  'Meccan'),
    Surah(36,  'Ya-Sin',         'يس',       'یسین',          'يس',       'يس',       83,  'Meccan'),
    Surah(37,  'As-Saffat',      'الصافات',  'الصافات',       'صافات',    'الصافات',  182, 'Meccan'),
    Surah(38,  'Sad',            'ص',        'صاد',           'صاد',      'ص',        88,  'Meccan'),
    Surah(39,  'Az-Zumar',       'الزمر',    'الزمر',         'زمر',      'الزمر',    75,  'Meccan'),
    Surah(40,  'Momin',          'مؤمن',     'مؤمن',          'مؤمن',     'مؤمن',     85,  'Meccan'),
    Surah(41,  'Ha Meem Sijda',  'حم السجدة','حم السجدہ',     'حم السجده','حم السجدة',54,  'Meccan'),
    Surah(42,  'Ash-Shura',      'الشورى',   'الشوری',        'شورى',     'الشورى',   53,  'Meccan'),
    Surah(43,  'Az-Zukhruf',     'الزخرف',   'الزخرف',        'زخرف',     'الزخرف',   89,  'Meccan'),
    Surah(44,  'Ad-Dukhan',      'الدخان',   'الدخان',        'دخان',     'الدخان',   59,  'Meccan'),
    Surah(45,  'Al-Jathiyah',    'الجاثية',  'الجاثیہ',       'جاثيه',    'الجاثية',  37,  'Meccan'),
    Surah(46,  'Al-Ahqaf',       'الأحقاف',  'الأحقاف',       'احقاف',    'الأحقاف',  35,  'Meccan'),
    Surah(47,  'Muhammad',       'محمد',     'محمد',          'محمد',     'محمد',     38,  'Medinan'),
    Surah(48,  'Al-Fath',        'الفتح',    'الفتح',         'فتح',      'الفتح',    29,  'Medinan'),
    Surah(49,  'Al-Hujurat',     'الحجرات',  'الحجرات',       'حجرات',    'الحجرات',  18,  'Medinan'),
    Surah(50,  'Qaf',            'ق',        'قاف',           'قاف',      'ق',        45,  'Meccan'),
    Surah(51,  'Adh-Dhariyat',   'الذاريات', 'الذاریات',      'ذاريات',   'الذاريات', 60,  'Meccan'),
    Surah(52,  'At-Tur',         'الطور',    'الطور',         'طور',      'الطور',    49,  'Meccan'),
    Surah(53,  'An-Najm',        'النجم',    'النجم',         'نجم',      'النجم',    62,  'Meccan'),
    Surah(54,  'Al-Qamar',       'القمر',    'القمر',         'قمر',      'القمر',    55,  'Meccan'),
    Surah(55,  'Ar-Rahman',      'الرحمن',   'الرحمن',        'رحمان',    'الرحمن',   78,  'Medinan'),
    Surah(56,  'Al-Waqiah',      'الواقعة',  'الواقعة',       'واقعه',    'الواقعة',  96,  'Meccan'),
    Surah(57,  'Al-Hadid',       'الحديد',   'الحدید',        'حديد',     'الحديد',   29,  'Medinan'),
    Surah(58,  'Al-Mujadila',    'المجادلة', 'المجادلة',      'مجادله',   'المجادلة', 22,  'Medinan'),
    Surah(59,  'Al-Hashr',       'الحشر',    'الحشر',         'حشر',      'الحشر',    24,  'Medinan'),
    Surah(60,  'Al-Mumtahanah',  'الممتحنة', 'الممتحنة',      'ممتحنه',   'الممتحنة', 13,  'Medinan'),
    Surah(61,  'As-Saf',         'الصف',     'الصف',          'صف',       'الصف',     14,  'Medinan'),
    Surah(62,  'Al-Jumuah',      'الجمعة',   'الجمعة',        'جمعه',     'الجمعة',   11,  'Medinan'),
    Surah(63,  'Al-Munafiqun',   'المنافقون','المنافقون',     'منافقون',  'المنافقون',11,  'Medinan'),
    Surah(64,  'At-Taghabun',    'التغابن',  'التغابن',       'تغابن',    'التغابن',  18,  'Medinan'),
    Surah(65,  'At-Talaq',       'الطلاق',   'الطلاق',        'طلاق',     'الطلاق',   12,  'Medinan'),
    Surah(66,  'At-Tahrim',      'التحريم',  'التحریم',       'تحريم',    'التحريم',  12,  'Medinan'),
    Surah(67,  'Al-Mulk',        'الملك',    'الملک',         'ملڪ',      'الملك',    30,  'Meccan'),
    Surah(68,  'Al-Qalam',       'القلم',    'القلم',         'قلم',      'القلم',    52,  'Meccan'),
    Surah(69,  'Al-Haqqah',      'الحاقة',   'الحاقة',        'حاقه',     'الحاقة',   52,  'Meccan'),
    Surah(70,  'Al-Maarij',      'المعارج',  'المعارج',       'معارج',    'المعارج',  44,  'Meccan'),
    Surah(71,  'Nuh',            'نوح',      'نوح',           'نوح',      'نوح',      28,  'Meccan'),
    Surah(72,  'Al-Jinn',        'الجن',     'الجن',          'جن',       'الجن',     28,  'Meccan'),
    Surah(73,  'Al-Muzzammil',   'المزمل',   'المزمل',        'مزمل',     'المزمل',   20,  'Meccan'),
    Surah(74,  'Al-Muddaththir', 'المدثر',   'المدثر',        'مدثر',     'المدثر',   56,  'Meccan'),
    Surah(75,  'Al-Qiyamah',     'القيامة',  'القیامة',       'قيامت',    'القيامة',  40,  'Meccan'),
    Surah(76,  'Dahr',           'الدهر',    'الدھر',         'دهر',      'الدهر',    31,  'Medinan'),
    Surah(77,  'Al-Mursalat',    'المرسلات', 'المرسلات',      'مرسلات',   'المرسلات', 50,  'Meccan'),
    Surah(78,  'An-Naba',        'النبأ',    'النبأ',         'نبا',      'النبأ',    40,  'Meccan'),
    Surah(79,  'An-Naziat',      'النازعات', 'النازعات',      'نازعات',   'النازعات', 46,  'Meccan'),
    Surah(80,  'Abasa',          'عبس',      'عبس',           'عبس',      'عبس',      42,  'Meccan'),
    Surah(81,  'At-Takwir',      'التكوير',  'التکویر',       'تڪوير',    'التكوير',  29,  'Meccan'),
    Surah(82,  'Al-Infitar',     'الانفطار', 'الانفطار',      'انفطار',   'الانفطار', 19,  'Meccan'),
    Surah(83,  'Al-Mutaffifin',  'المطففين', 'المطففین',      'مطففين',   'المطففين', 36,  'Meccan'),
    Surah(84,  'Al-Inshiqaq',    'الانشقاق', 'الانشقاق',      'انشقاق',   'الانشقاق', 25,  'Meccan'),
    Surah(85,  'Al-Buruj',       'البروج',   'البروج',        'بروج',     'البروج',   22,  'Meccan'),
    Surah(86,  'At-Tariq',       'الطارق',   'الطارق',        'طارق',     'الطارق',   17,  'Meccan'),
    Surah(87,  'Al-Ala',         'الأعلى',   'الأعلی',        'اعلى',     'الأعلى',   19,  'Meccan'),
    Surah(88,  'Al-Ghashiyah',   'الغاشية',  'الغاشیة',       'غاشيه',    'الغاشية',  26,  'Meccan'),
    Surah(89,  'Al-Fajr',        'الفجر',    'الفجر',         'فجر',      'الفجر',    30,  'Meccan'),
    Surah(90,  'Al-Balad',       'البلد',    'البلد',         'بلد',      'البلد',    20,  'Meccan'),
    Surah(91,  'Ash-Shams',      'الشمس',    'الشمس',         'شمس',      'الشمس',    15,  'Meccan'),
    Surah(92,  'Al-Layl',        'الليل',    'اللیل',         'ليل',      'الليل',    21,  'Meccan'),
    Surah(93,  'Ad-Duha',        'الضحى',    'الضحی',         'ضحى',      'الضحى',    11,  'Meccan'),
    Surah(94,  'An Sharah',      'ألم نشرح', 'الم نشرح',      'الم نشرح', 'ألم نشرح', 8,   'Meccan'),
    Surah(95,  'At-Tin',         'التين',    'التین',         'تين',      'التين',    8,   'Meccan'),
    Surah(96,  'Al-Alaq',        'العلق',    'العلق',         'علق',      'العلق',    19,  'Meccan'),
    Surah(97,  'Al-Qadr',        'القدر',    'القدر',         'قدر',      'القدر',    5,   'Meccan'),
    Surah(98,  'Al-Bayyinah',    'البينة',   'البینة',        'بينه',     'البينة',   8,   'Medinan'),
    Surah(99,  'Az-Zalzalah',    'الزلزلة',  'الزلزلة',       'زلزله',    'الزلزلة',  8,   'Medinan'),
    Surah(100, 'Al-Adiyat',      'العاديات', 'العادیات',      'عاديات',   'العاديات', 11,  'Meccan'),
    Surah(101, 'Al-Qariah',      'القارعة',  'القارعة',       'قارعه',    'القارعة',  11,  'Meccan'),
    Surah(102, 'At-Takathur',    'التكاثر',  'التکاثر',       'تڪاثر',    'التكاثر',  8,   'Meccan'),
    Surah(103, 'Al-Asr',         'العصر',    'العصر',         'عصر',      'العصر',    3,   'Meccan'),
    Surah(104, 'Al-Humazah',     'الهمزة',   'الهمزة',        'همزه',     'الهمزة',   9,   'Meccan'),
    Surah(105, 'Al-Fil',         'الفيل',    'الفیل',         'فيل',      'الفيل',    5,   'Meccan'),
    Surah(106, 'Quraysh',        'قريش',     'قریش',          'قريش',     'قريش',     4,   'Meccan'),
    Surah(107, 'Al-Maun',        'الماعون',  'الماعون',       'ماعون',    'الماعون',  7,   'Meccan'),
    Surah(108, 'Al-Kawthar',     'الكوثر',   'الکوثر',        'ڪوثر',     'الكوثر',   3,   'Meccan'),
    Surah(109, 'Al-Kafirun',     'الكافرون', 'الکافرون',      'ڪافرون',   'الكافرون', 6,   'Meccan'),
    Surah(110, 'An-Nasr',        'النصر',    'النصر',         'نصر',      'النصر',    3,   'Medinan'),
    Surah(111, 'Lahab',          'لهب',      'لہب',           'لهب',      'لهب',      5,   'Meccan'),
    Surah(112, 'Al-Ikhlas',      'الإخلاص',  'الإخلاص',       'اخلاص',    'الإخلاص',  4,   'Meccan'),
    Surah(113, 'Al-Falaq',       'الفلق',    'الفلق',         'فلق',      'الفلق',    5,   'Meccan'),
    Surah(114, 'An-Nas',         'الناس',    'الناس',         'ناس',      'الناس',    6,   'Meccan'),
  ];

  static const Map<int, int> surahStartPages = {
    1:2,   2:3,   3:46,  4:70,  5:97,  6:116, 7:137, 8:160, 9:169, 10:188,
    11:200,12:213,13:225,14:231,15:236,16:241,17:255,18:265,19:276, 20:282,
    21:291,22:300,23:309,24:316,25:325,26:331,27:340,28:348,29:358, 30:365,
    31:371,32:374,33:377,34:386,35:392,36:397,37:402,38:409,39:413, 40:421,
    41:430,42:435,43:441,44:447,45:449,46:453,47:457,48:461,49:464, 50:467,
    51:469,52:472,53:474,54:476,55:479,56:482,57:485,58:489,59:492, 60:496,
    61:498,62:500,63:501,64:503,65:505,66:507,67:509,68:511,69:513, 70:515,
    71:517,72:519,73:521,74:522,75:524,76:525,77:527,78:529,79:530, 80:531,
    81:533,82:533,83:534,84:535,85:536,86:537,87:538,88:538,89:539, 90:540,
    91:541,92:541,93:542,94:542,95:543,96:543,97:544,98:544,99:545, 100:545,
    101:545,102:546,103:546,104:546,105:547,106:547,107:547,108:547,109:548,110:548,
    111:548,112:548,113:549,114:549
  };

  static int getParahForPage(int page) {
    for (int i = parahs.length - 1; i >= 0; i--) {
      if (page >= parahs[i].startPage) {
        return parahs[i].number;
      }
    }
    return 1;
  }
}
