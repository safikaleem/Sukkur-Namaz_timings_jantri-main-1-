import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/settings_provider.dart';
import '../data/ahmiyat_ramzan_data.dart';
import '../services/munajat_download_service.dart';
import '../services/ahmiyat_ramzan_download_service.dart';
import '../utils/app_theme.dart';
import 'munajat_reader_screen.dart';
import 'ahmiyat_ramzan_reader_screen.dart';

class MunajatScreen extends StatefulWidget {
  const MunajatScreen({super.key});

  @override
  State<MunajatScreen> createState() => _MunajatScreenState();
}

class _MunajatScreenState extends State<MunajatScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<int> _favoriteManzils = [];
  bool _showingManzils = false; // false = Books view, true = Manzil list view
  bool _showingAhmiyatRamzan = false; // true = Ahmiyat-e-Ramzan chapters view
  final TextEditingController _ramzanSearchController = TextEditingController();
  String _ramzanSearchQuery = '';

  final List<Map<String, dynamic>> _manzilsData = [
    {
      'num': 1,
      'en': '1st Manzil (Saturday)',
      'ur': 'پہلی منزل (ہفتہ)',
      'sd': 'پهرين منزل (هفتو)',
      'ar': 'المنزل الأول (السبت)',
      'page': 10,
      'pdfPage': 9,
    },
    {
      'num': 2,
      'en': '2nd Manzil (Sunday)',
      'ur': 'دوسری منزل (اتوار)',
      'sd': 'ٻي منزل (آچر)',
      'ar': 'المنزل الثاني (الأحد)',
      'page': 28,
      'pdfPage': 27,
    },
    {
      'num': 3,
      'en': '3rd Manzil (Monday)',
      'ur': 'تیسری منزل (پیر)',
      'sd': 'ٽين منزل (سومر)',
      'ar': 'المنزل الثالث (الإثنين)',
      'page': 48,
      'pdfPage': 47,
    },
    {
      'num': 4,
      'en': '4th Manzil (Tuesday)',
      'ur': 'چوتھی منزل (منگل)',
      'sd': 'چوٿين منزل (اڱارو)',
      'ar': 'المنزل الرابع (الثلاثاء)',
      'page': 66,
      'pdfPage': 65,
    },
    {
      'num': 5,
      'en': '5th Manzil (Wednesday)',
      'ur': 'پانچویں منزل (بدھ)',
      'sd': 'پنجين منزل (اربع)',
      'ar': 'المنزل الخامس (الأربعاء)',
      'page': 86,
      'pdfPage': 85,
    },
    {
      'num': 6,
      'en': '6th Manzil (Thursday)',
      'ur': 'چھٹی منزل (جمعرات)',
      'sd': 'ڇھين منزل (خميس)',
      'ar': 'المنزل السادس (الخميس)',
      'page': 102,
      'pdfPage': 101,
    },
    {
      'num': 7,
      'en': '7th Manzil (Friday)',
      'ur': 'ساتویں منزل (جمعہ)',
      'sd': 'ستين منزل (جمعو)',
      'ar': 'المنزل السابع (الجمعة)',
      'page': 120,
      'pdfPage': 119,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFavorites();
    MunajatDownloadService.instance.autoDownload();
    AhmiyatRamzanDownloadService.instance.autoDownload();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _ramzanSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList('favorite_manzils') ?? [];
    setState(() {
      _favoriteManzils = favs.map((e) => int.tryParse(e) ?? 0).where((n) => n > 0).toList();
    });
  }

  Future<void> _toggleFavorite(int num) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favoriteManzils.contains(num)) {
        _favoriteManzils.remove(num);
      } else {
        _favoriteManzils.add(num);
      }
    });
    await prefs.setStringList('favorite_manzils', _favoriteManzils.map((e) => e.toString()).toList());
  }

  Future<void> _openManzilPage(BuildContext context, int page, String title) async {
    final settings = context.read<SettingsProvider>();
    settings.updateMunajatReadingPosition(page);
    final service = MunajatDownloadService.instance;
    final isAvailable = await service.isMunajatAvailable();

    if (!context.mounted) return;

    if (isAvailable) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MunajatReaderScreen(
            initialPage: page,
            title: title,
          ),
        ),
      ).then((_) {
        if (mounted) setState(() {});
      });
    } else {
      _showDownloadDialog(context, page, title);
    }
  }

  int _getManzilForPage(int page) {
    if (page >= 120) return 7;
    if (page >= 102) return 6;
    if (page >= 86) return 5;
    if (page >= 66) return 4;
    if (page >= 48) return 3;
    if (page >= 28) return 2;
    return 1;
  }

  String _getManzilTitle(Map<String, dynamic> manzil, SettingsProvider settings) {
    final en = manzil['en'] as String;
    final ur = manzil['ur'] as String;
    final sd = manzil['sd'] as String;
    final ar = manzil['ar'] as String;
    return settings.translate(en, ur, sd, ar);
  }

  Widget _buildContinueReading(BuildContext context, SettingsProvider settings, bool isDark) {
    final lastPage = settings.munajatLastPage;
    if (lastPage == null || lastPage < 1) {
      return const SizedBox.shrink();
    }

    final int manzilNum = _getManzilForPage(lastPage);
    final manzilData = _manzilsData.firstWhere(
      (m) => m['num'] == manzilNum,
      orElse: () => _manzilsData.first,
    );

    final String titleEn = manzilData['en'];
    final String titleLocal = _getManzilTitle(manzilData, settings);
    final String titleArabic = manzilData['ar'];
    final String subtitle = '${settings.translate("Page", "صفحہ", "صفحو", "صفحة")} $lastPage';
    final int progressPercent = ((lastPage / 137) * 100).clamp(0, 100).toInt();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _openManzilPage(context, lastPage, titleLocal);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3F7A63), Color(0xFF2E5E4C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E5E4C).withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  settings.translate('CONTINUE READING', 'پڑھنا جاری رکھیں', 'پڙهڻ جاري رکو', 'مواصلة القراءة').toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: settings.language == 'english' ? 10 : 12,
                                    fontFamily: settings.language == 'english' ? null : AppTheme.getFontForLanguage(context, settings.language),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: settings.language == 'english' ? 1.5 : 0.0,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  settings.language == 'english' ? titleEn : titleLocal,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: settings.language == 'english' ? 18 : 20,
                                    fontFamily: settings.language == 'english' ? null : AppTheme.urduFont,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: settings.language == 'english' ? 13 : 15,
                                    fontFamily: settings.language == 'english' ? null : AppTheme.getFontForLanguage(context, settings.language),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            titleArabic,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontFamily: AppTheme.urduFont,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progressPercent / 100.0,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDownloadDialog(BuildContext context, int targetPage, String title) {
    final settings = context.read<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const sageAccent = Color(0xFF3F7A63);
    double progress = MunajatDownloadService.instance.currentProgress;
    void Function(void Function())? stateUpdater;
    bool dialogClosed = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            stateUpdater = setDialogState;
            return PopScope(
              canPop: false,
              child: AlertDialog(
                backgroundColor: settings.displayThemeCard(isDark),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text(
                  settings.translate('Downloading Munajat Maqbool', 'مناجات مقبول ڈاؤن لوڈ ہو رہی ہے', 'مناجات مقبول ڊائون لوڊ ٿي رهي آهي', 'تحميل مناجاة مقبول'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress > 0 ? progress : null,
                        minHeight: 8,
                        backgroundColor: isDark ? Colors.white10 : Colors.black12,
                        color: sageAccent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: sageAccent,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    MunajatDownloadService.instance.downloadMunajat(
      onProgress: (downloaded, total, currentProgress) {
        if (stateUpdater != null) {
          stateUpdater!(() {
            progress = currentProgress;
          });
        }
      },
    ).then((bytes) {
      if (!context.mounted) return;
      if (!dialogClosed) {
        dialogClosed = true;
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (bytes != null && bytes.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MunajatReaderScreen(
              initialPage: targetPage,
              title: title,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              settings.translate(
                'Could not download Munajat PDF. Please check your internet connection.',
                'مناجات پی ڈی ایف ڈاؤن لوڈ نہیں ہو سکی۔ براہ کرم اپنا انٹرنیٹ کنکشن چیک کریں۔',
                'مناجات پي ڊي ايف ڊائون لوڊ نه ٿي سگهي. مهرباني ڪري پنهنجو انٽرنيٽ ڪنيڪشن چيڪ ڪريو.',
                'تعذر تحميل ملف مناجاة PDF. يرجى التحقق من اتصالك بالإنترنت.',
              ),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }).catchError((e) {
      if (!context.mounted) return;
      if (!dialogClosed) {
        dialogClosed = true;
        Navigator.of(context, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            settings.translate(
              'Could not download Munajat PDF. Please check your internet connection.',
              'مناجات پی ڈی ایف ڈاؤن لوڈ نہیں ہو سکی۔ براہ کرم اپنا انٹرنیٹ کنکشن چیک کریں۔',
              'مناجات پي ڊي ايف ڊائون لوڊ نه ٿي سگهي. مهرباني ڪري پنهنجو انٽرنيٽ ڪنيڪشن چيڪ ڪريو.',
              'تعذر تحميل ملف مناجاة PDF. يرجى التحقق من اتصالك بالإنترنت.',
            ),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    });
  }

  String _translateNumber(int number, SettingsProvider settings) {
    final lang = settings.language;
    if (lang == 'english' || lang == 'french' || lang == 'indonesian' || lang == 'turkish' || lang == 'russian') {
      return number.toString();
    }
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    if (lang == 'bengali') {
      const bengali = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
      String s = number.toString();
      for (int i = 0; i < 10; i++) {
        s = s.replaceAll(english[i], bengali[i]);
      }
      return s;
    }
    if (lang == 'hindi') {
      const hindi = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
      String s = number.toString();
      for (int i = 0; i < 10; i++) {
        s = s.replaceAll(english[i], hindi[i]);
      }
      return s;
    }
    if (lang == 'urdu' || lang == 'persian') {
      const urduPersian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
      String s = number.toString();
      for (int i = 0; i < 10; i++) {
        s = s.replaceAll(english[i], urduPersian[i]);
      }
      return s;
    }
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String numStr = number.toString();
    for (int i = 0; i < english.length; i++) {
      numStr = numStr.replaceAll(english[i], arabic[i]);
    }
    return numStr;
  }

  String _getBooksTitle(SettingsProvider settings) {
    switch (settings.language) {
      case 'urdu': return 'کتب';
      case 'sindhi': return 'ڪتاب';
      case 'arabic': return 'الكتب';
      case 'bengali': return 'বইসমূহ';
      case 'hindi': return 'किताबें';
      case 'turkish': return 'Kitaplar';
      case 'indonesian': return 'Buku';
      case 'french': return 'Livres';
      case 'russian': return 'Книги';
      case 'persian': return 'کتاب‌ها';
      default: return 'Books';
    }
  }

  String _getMunajaatMaqboolTitle(SettingsProvider settings) {
    switch (settings.language) {
      case 'urdu': return 'مناجاتِ مقبول';
      case 'sindhi': return 'مناجاتِ مقبول';
      case 'arabic': return 'مناجاة مقبول';
      case 'bengali': return 'মুনাজاتے মাকবুল';
      case 'hindi': return 'मुनाजाते मकबूल';
      case 'turkish': return 'Münacat-ı Makbul';
      case 'indonesian': return 'Munajat Maqbul';
      case 'french': return 'Munajaat Maqbool';
      case 'russian': return 'Мунаджат Макбуль';
      case 'persian': return 'مناجات مقبول';
      default: return 'Munajaat Maqbool';
    }
  }

  String _getAhmiyatRamzanTitle(SettingsProvider settings) {
    switch (settings.language) {
      case 'urdu': return 'اہمیتِ رمضان';
      case 'sindhi': return 'اهميتِ رمضان';
      case 'arabic': return 'أهمية رمضان';
      case 'bengali': return 'আহমিয়াতে রমযান';
      case 'hindi': return 'अहमियत-ए-रमज़ान';
      case 'turkish': return 'Ahmiyet-i Ramazan';
      case 'indonesian': return 'Ahmiyat-e-Ramzan';
      case 'french': return 'Ahmiyat-e-Ramzan';
      case 'russian': return 'Важность Рамадана';
      case 'persian': return 'اهمیت رمضان';
      default: return 'Ahmiyat-e-Ramzan';
    }
  }

  String _getAhmiyatRamzanSubtitle(SettingsProvider settings) {
    switch (settings.language) {
      case 'urdu': return 'فضائل، مسائل و برکاتِ رمضان';
      case 'sindhi': return 'فضيلتون، مسئلا ۽ برڪتون';
      case 'arabic': return 'فضائل وأحكام وبركات شهر رمضان';
      case 'bengali': return 'রমযানের ফযীলত, আহকাম ও বরকত';
      case 'hindi': return 'रमज़ान की फ़ज़ीलत, अहकाम और बरकतें';
      case 'turkish': return "Ramazan'ın faziletleri, hükümleri ve bereketleri";
      case 'indonesian': return 'Keutamaan, hukum & berkah Ramadhan';
      case 'french': return 'Vertus, règles et bénédictions du Ramadan';
      case 'russian': return 'Достоинства, предписания и благословения Рамадана';
      case 'persian': return 'فضایل، احکام و برکات ماه رمضان';
      default: return 'Virtues, rulings & blessings of Ramadan';
    }
  }


  String _getAhmiyatRamzanBadge(SettingsProvider settings) {
    switch (settings.language) {
      case 'urdu': return '۱۳ ابواب';
      case 'sindhi': return '13 باب';
      case 'arabic': return '١٣ باباً';
      case 'bengali': return '১৩টি অধ্যায়';
      case 'hindi': return '13 अध्याय';
      case 'turkish': return '13 Bölüm';
      case 'indonesian': return '13 Bab';
      case 'french': return '13 Chapitres';
      case 'persian': return '۱۳ فصل';
      default: return '13 Chapters';
    }
  }



  String _getSevenManzilsSubtitle(SettingsProvider settings) {
    switch (settings.language) {
      case 'urdu': return '۷ روزانہ منزلیں (ہفتہ تا جمعہ)';
      case 'sindhi': return '7 روزانيون منزلون (هفتو تا جمعو)';
      case 'arabic': return '٧ منازل يومية (السبت إلى الجمعة)';
      case 'bengali': return '৭টি দৈনিক মঞ্জিল (শনিবার থেকে শুক্রবার)';
      case 'hindi': return '7 दैनिक मंजिल (शनिवार से शुक्रवार)';
      case 'turkish': return '7 Günlük Menzil (Cumartesi - Cuma)';
      case 'indonesian': return '7 Manzil Harian (Sabtu hingga Jumat)';
      case 'french': return '7 Manzils quotidiens (du samedi au vendredi)';
      case 'russian': return '7 ежедневных мандзилей (с субботы по пятницу)';
      case 'persian': return '۷ منزل روزانه (شنبه تا جمعه)';
      default: return '7 Daily Manzils (Saturday to Friday)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !_showingManzils && !_showingAhmiyatRamzan,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (_showingAhmiyatRamzan) {
            setState(() {
              _showingAhmiyatRamzan = false;
              _ramzanSearchQuery = '';
              _ramzanSearchController.clear();
            });
          } else if (_showingManzils) {
            setState(() {
              _showingManzils = false;
            });
          }
        }
      },
      child: Scaffold(
        backgroundColor: settings.displayThemeBg(isDark),
        body: SafeArea(
          child: _showingAhmiyatRamzan
              ? _buildAhmiyatRamzanScreen(context, settings, isDark)
              : _showingManzils
                  ? _buildManzilsScreen(context, settings, isDark)
                  : _buildBooksListScreen(context, settings, isDark),
        ),
      ),
    );
  }

  /// Screen 1: Books View (Displays Munajaat Maqbool & Ahmiyat-e-Ramzan)
  Widget _buildBooksListScreen(BuildContext context, SettingsProvider settings, bool isDark) {
    final title = _getBooksTitle(settings);
    final munajaatMaqboolTitle = _getMunajaatMaqboolTitle(settings);
    final subtitle = _getSevenManzilsSubtitle(settings);
    final manzilsBadge = settings.translate('7 Manzils', '۷ منزلیں', '7 منزلون', '٧ منازل');

    final ahmiyatRamzanTitle = _getAhmiyatRamzanTitle(settings);
    final ahmiyatRamzanSubtitle = _getAhmiyatRamzanSubtitle(settings);
    final chaptersBadge = _getAhmiyatRamzanBadge(settings);

    return Column(
      children: [
        // Header Bar
        Directionality(
          textDirection: settings.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.menu_rounded,
                      size: 22,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                    ),
                  ),
                ),
                const SizedBox(width: 36),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Body List of Books
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            children: [
              // Book 1: Munajaat Maqbool
              Container(
                margin: const EdgeInsets.only(bottom: 12.0),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2B2C33) : Colors.white,
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _showingManzils = true;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                        child: Directionality(
                          textDirection: settings.isRtl ? TextDirection.rtl : TextDirection.ltr,
                          child: Row(
                            children: [
                              // Circular Logo Emblem
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: const Color(0xFF3F7A63).withValues(alpha: 0.12),
                                  border: Border.all(
                                    color: const Color(0xFF3F7A63).withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                  image: const DecorationImage(
                                    image: AssetImage('assets/images/munajat_logo.png'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 16),

                              // Book Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      munajaatMaqboolTitle,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                        fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      subtitle,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? Colors.white60 : Colors.black54,
                                        fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // Badge Pill
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3F7A63).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        manzilsBadge,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? const Color(0xFF6BB396) : const Color(0xFF3F7A63),
                                          fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Arrow Chevron Icon
                              Icon(
                                settings.isRtl
                                    ? Icons.chevron_left_rounded
                                    : Icons.chevron_right_rounded,
                                size: 28,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Book 2: Ahmiyat-e-Ramzan
              Container(
                margin: const EdgeInsets.only(bottom: 12.0),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2B2C33) : Colors.white,
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _showingAhmiyatRamzan = true;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                        child: Directionality(
                          textDirection: settings.isRtl ? TextDirection.rtl : TextDirection.ltr,
                          child: Row(
                            children: [
                              // Ahmiyat-e-Ramzan Logo Emblem Container
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.12),
                                  border: Border.all(
                                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.12),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  image: const DecorationImage(
                                    image: AssetImage('assets/images/ahmiyat_ramzan_logo.jpg'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 16),

                              // Book Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ahmiyatRamzanTitle,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                        fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      ahmiyatRamzanSubtitle,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? Colors.white60 : Colors.black54,
                                        fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // Badge Pill
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3F7A63).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        chaptersBadge,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? const Color(0xFF6BB396) : const Color(0xFF3F7A63),
                                          fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Arrow Chevron Icon
                              Icon(
                                settings.isRtl
                                    ? Icons.chevron_left_rounded
                                    : Icons.chevron_right_rounded,
                                size: 28,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Screen 2: Manzils Screen (7 Daily Manzils inside Munajaat Maqbool)
  Widget _buildManzilsScreen(BuildContext context, SettingsProvider settings, bool isDark) {
    final title = _getMunajaatMaqboolTitle(settings);
    final manzilTab = settings.translate('Manzil', 'منزل', 'منزل', 'منزل');
    final favoriteTab = settings.translate('Favorite', 'پسندیدہ', 'پسنديده', 'المفضلة');
    const sageAccent = Color(0xFF3F7A63);

    return Column(
      children: [
        // Header Bar with Hamburger in original position & Back button slightly below it
        Directionality(
          textDirection: settings.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Start Column: Hamburger on top, Back button slightly below
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hamburger Menu Button (Original Position)
                    GestureDetector(
                      onTap: () => Scaffold.of(context).openDrawer(),
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.menu_rounded,
                          size: 22,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Back Button (Slightly below Hamburger)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showingManzils = false;
                        });
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Icon(
                            settings.isRtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                            size: 22,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                    ),
                  ),
                ),

                const SizedBox(width: 36),
              ],
            ),
          ),
        ),

        _buildContinueReading(context, settings, isDark),

        // Tab Bar
        TabBar(
          controller: _tabController,
          indicatorColor: sageAccent,
          indicatorWeight: 3.5,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: sageAccent,
          unselectedLabelColor: isDark ? Colors.white54 : Colors.black45,
          labelStyle: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            fontFamily: AppTheme.getFontForLanguage(context, settings.language),
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            fontFamily: AppTheme.getFontForLanguage(context, settings.language),
          ),
          dividerColor: Colors.transparent,
          tabs: [
            Tab(text: manzilTab),
            Tab(text: favoriteTab),
          ],
        ),

        const SizedBox(height: 8),

        // Tab Content View
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildManzilListTab(context, settings, isDark, isFavoriteOnly: false),
              _buildManzilListTab(context, settings, isDark, isFavoriteOnly: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManzilListTab(
    BuildContext context,
    SettingsProvider settings,
    bool isDark, {
    required bool isFavoriteOnly,
  }) {
    final searchHint = settings.translate('Search Manzil...', 'منزل تلاش کریں...', 'منزل ڳوليو...', 'ابحث عن منزل...');
    final noLabel = settings.translate('No.', 'نمبر', 'نمبر', 'رقم');
    final nameLabel = settings.translate('Name', 'نام', 'نالو', 'الاسم');
    final pageLabel = settings.translate('Page', 'صفحہ', 'صفحو', 'صفحة');
    const sageAccent = Color(0xFF3F7A63);

    var list = _manzilsData;
    if (isFavoriteOnly) {
      list = list.where((m) => _favoriteManzils.contains(m['num'] as int)).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((m) {
        final titleLocal = _getManzilTitle(m, settings).toLowerCase();
        final titleEn = (m['en'] as String).toLowerCase();
        final numStr = (m['num'] as int).toString();
        return titleLocal.contains(q) || titleEn.contains(q) || numStr.contains(q);
      }).toList();
    }

    return Column(
      children: [
        // Search Box
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C3E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
                fontFamily: AppTheme.getFontForLanguage(context, settings.language),
              ),
              decoration: InputDecoration(
                hintText: searchHint,
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 14,
                  fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                ),
                prefixIcon: const Icon(Icons.search_rounded, color: sageAccent, size: 22),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 6),

        // Table Header Pill Bar (No. | Name | Page)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3F7A63), Color(0xFF2E5E4C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E5E4C).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  child: Text(
                    noLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      nameLabel,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                      ),
                    ),
                  ),
                ),
                Text(
                  pageLabel,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                  ),
                ),
                const SizedBox(width: 40), // Space matching favorite heart icon
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Manzil Cards List
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Text(
                    isFavoriteOnly
                        ? settings.translate('No favorite manzils yet', 'ابھی تک کوئی پسندیدہ منزل نہیں', 'اڃا تائين ڪا پسنديده منزل ناهي', 'لا توجد منازل مفضلة بعد')
                        : settings.translate('No manzil found', 'کوئی منزل نہیں ملی', 'ڪا منزل نه ملي', 'لم يتم العثور على منزل'),
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 14,
                      fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    final numVal = item['num'] as int;
                    final pageVal = item['page'] as int;
                    final titleStr = _getManzilTitle(item, settings);
                    final isFav = _favoriteManzils.contains(numVal);

                    return _buildManzilTile(
                      context,
                      item: item,
                      numVal: numVal,
                      pageVal: pageVal,
                      titleStr: titleStr,
                      isFav: isFav,
                      isDark: isDark,
                      settings: settings,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildManzilTile(
    BuildContext context, {
    required Map<String, dynamic> item,
    required int numVal,
    required int pageVal,
    required String titleStr,
    required bool isFav,
    required bool isDark,
    required SettingsProvider settings,
  }) {
    final pageLabel = settings.translate('Page', 'صفحہ', 'صفحو', 'صفحة');

    return Container(
      margin: const EdgeInsets.only(bottom: 10.0, left: 16.0, right: 16.0),
      constraints: const BoxConstraints(minHeight: 76.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B2C33) : Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openManzilPage(context, pageVal, titleStr),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 18.0),
              child: Directionality(
                textDirection: settings.isRtl ? TextDirection.rtl : TextDirection.ltr,
                child: Row(
                  children: [
                    // Badge Number Circle
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: const Color(0xFF3F7A63).withValues(alpha: 0.12),
                            image: const DecorationImage(
                              image: AssetImage('assets/images/munajat_logo.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: -4,
                          left: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3F7A63),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? const Color(0xFF2B2C33) : Colors.white,
                                width: 2,
                              ),
                            ),
                            constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                            alignment: Alignment.center,
                            child: Text(
                              _translateNumber(numVal, settings),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 14),

                    // Manzil Name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            titleStr,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['en'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Page Button Pill (Dark Sage Green)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3F7A63), Color(0xFF2E5E4C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.menu_book_rounded, color: Colors.white, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            '$pageLabel ${_translateNumber(pageVal, settings)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Favorite Heart Icon
                    GestureDetector(
                      onTap: () => _toggleFavorite(numVal),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? Colors.redAccent : (isDark ? Colors.white24 : Colors.black26),
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // Ahmiyat-e-Ramzan (13 Chapters Index Screen)
  // ==========================================

  Future<void> _openAhmiyatRamzanPage(BuildContext context, int page, String title) async {
    final settings = context.read<SettingsProvider>();
    settings.updateAhmiyatRamzanReadingPosition(page);
    final service = AhmiyatRamzanDownloadService.instance;
    final isAvailable = await service.isPdfAvailable();

    if (!context.mounted) return;

    if (isAvailable) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AhmiyatRamzanReaderScreen(
            initialPage: page,
            title: title,
          ),
        ),
      ).then((_) {
        if (mounted) setState(() {});
      });
    } else {
      _showAhmiyatRamzanDownloadDialog(context, page, title);
    }
  }

  void _showAhmiyatRamzanDownloadDialog(BuildContext context, int targetPage, String title) {
    final settings = context.read<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const sageAccent = Color(0xFF3F7A63);
    double progress = AhmiyatRamzanDownloadService.instance.currentProgress;
    void Function(void Function())? stateUpdater;
    bool dialogClosed = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            stateUpdater = setDialogState;
            return PopScope(
              canPop: false,
              child: AlertDialog(
                backgroundColor: settings.displayThemeCard(isDark),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text(
                  settings.translate(
                    'Downloading Ahmiyat-e-Ramzan',
                    'اہمیتِ رمضان ڈاؤن لوڈ ہو رہی ہے',
                    'اهميتِ رمضان ڊائون لوڊ ٿي رهي آهي',
                    'تحميل أهمية رمضان',
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress > 0 ? progress : null,
                        minHeight: 8,
                        backgroundColor: isDark ? Colors.white10 : Colors.black12,
                        color: sageAccent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: sageAccent,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    AhmiyatRamzanDownloadService.instance.downloadPdf(
      onProgress: (downloaded, total, currentProgress) {
        if (stateUpdater != null) {
          stateUpdater!(() {
            progress = currentProgress;
          });
        }
      },
    ).then((bytes) {
      if (!context.mounted) return;
      if (!dialogClosed) {
        dialogClosed = true;
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (bytes != null && bytes.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AhmiyatRamzanReaderScreen(
              initialPage: targetPage,
              title: title,
            ),
          ),
        ).then((_) {
          if (mounted) setState(() {});
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              settings.translate(
                'Could not download Ahmiyat-e-Ramzan PDF. Please check your internet connection.',
                'اہمیتِ رمضان پی ڈی ایف ڈاؤن لوڈ نہیں ہو سکی۔ براہ کرم اپنا انٹرنیٹ کنکشن چیک کریں۔',
                'اهميتِ رمضان پي ڊي ايف ڊائون لوڊ نه ٿي سگهي. مهرباني ڪري پنهنجو انٽرنيٽ ڪنيڪشن چيڪ ڪريو.',
                'تعذر تحميل ملف أهمية رمضان PDF. يرجى التحقق من اتصالك بالإنترنت.',
              ),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }).catchError((e) {
      if (!context.mounted) return;
      if (!dialogClosed) {
        dialogClosed = true;
        Navigator.of(context, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            settings.translate(
              'Could not download Ahmiyat-e-Ramzan PDF. Please check your internet connection.',
              'اہمیتِ رمضان پی ڈی ایف ڈاؤن لوڈ نہیں ہو سکی۔ براہ کرم اپنا انٹرنیٹ کنکشن چیک کریں۔',
              'اهميتِ رمضان پي ڊي ايف ڊائون لوڊ نه ٿي سگهي. مهرباني ڪري پنهنجو انٽرنيٽ ڪنيڪشن چيڪ ڪريو.',
              'تعذر تحميل ملف أهمية رمضان PDF. يرجى التحقق من اتصالك بالإنترنت.',
            ),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    });
  }

  Widget _buildAhmiyatRamzanContinueReading(BuildContext context, SettingsProvider settings, bool isDark) {
    final lastPage = settings.ahmiyatRamzanLastPage;
    if (lastPage == null || lastPage < 1) {
      return const SizedBox.shrink();
    }

    AhmiyatRamzanTopic activeTopic = AhmiyatRamzanData.topics.first;
    for (final t in AhmiyatRamzanData.topics) {
      if (lastPage >= t.page) {
        activeTopic = t;
      }
    }

    final String titleLocal = activeTopic.getTitle(settings.language);
    final String authorLocal = activeTopic.getAuthor(settings.language);
    final String subtitle = '${settings.translate("Page", "صفحہ", "صفحو", "صفحة")} ${_translateNumber(lastPage, settings)}';
    final int progressPercent = ((lastPage / 137) * 100).clamp(0, 100).toInt();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _openAhmiyatRamzanPage(context, lastPage, titleLocal);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3F7A63), Color(0xFF2E5E4C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E5E4C).withValues(alpha: 0.25),
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_stories_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            settings.translate(
                              'CONTINUE READING',
                              'مطالعہ جاری رکھیں',
                              'پڙهڻ جاري رکو',
                              'متابعة القراءة',
                            ),
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                              fontWeight: FontWeight.bold,
                              letterSpacing: settings.language == 'english' ? 1.2 : 0.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            titleLocal,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$authorLocal • $subtitle',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progressPercent / 100.0,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Screen 3: Ahmiyat-e-Ramzan Index View (13 Chapters)
  Widget _buildAhmiyatRamzanScreen(BuildContext context, SettingsProvider settings, bool isDark) {
    final title = _getAhmiyatRamzanTitle(settings);
    const sageAccent = Color(0xFF3F7A63);

    final searchHint = settings.translate(
      'Search Chapters or Authors...',
      'ابواب یا مصنفین تلاش کریں...',
      'باب يا مصنف ڳوليو...',
      'ابحث عن الفصول أو المؤلفين...',
    );
    final noLabel = settings.translate('No.', 'نمبر', 'نمبر', 'رقم');
    final nameLabel = settings.translate('Title & Author', 'عنوان و مصنف', 'عنوان ۽ مصنف', 'العنوان والمؤلف');
    final pageLabel = settings.translate('Page', 'صفحہ', 'صفحو', 'صفحة');

    var list = AhmiyatRamzanData.topics;
    if (_ramzanSearchQuery.trim().isNotEmpty) {
      final q = _ramzanSearchQuery.trim().toLowerCase();
      list = list.where((topic) {
        final numStr = topic.num.toString();
        final pageStr = topic.page.toString();
        final titleCur = topic.getTitle(settings.language).toLowerCase();
        final authorCur = topic.getAuthor(settings.language).toLowerCase();
        final matchesAnyTitle = topic.titles.values.any((v) => v.toLowerCase().contains(q));
        final matchesAnyAuthor = topic.authors.values.any((v) => v.toLowerCase().contains(q));
        return numStr.contains(q) ||
            pageStr.contains(q) ||
            titleCur.contains(q) ||
            authorCur.contains(q) ||
            matchesAnyTitle ||
            matchesAnyAuthor;
      }).toList();
    }

    return Column(
      children: [
        // Header Bar
        Directionality(
          textDirection: settings.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Scaffold.of(context).openDrawer(),
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.menu_rounded,
                          size: 22,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showingAhmiyatRamzan = false;
                          _ramzanSearchQuery = '';
                          _ramzanSearchController.clear();
                        });
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Icon(
                            settings.isRtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                            size: 22,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                    ),
                  ),
                ),
                const SizedBox(width: 36),
              ],
            ),
          ),
        ),

        // Continue Reading Banner (if last read exists)
        _buildAhmiyatRamzanContinueReading(context, settings, isDark),

        // Search Box
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C3E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _ramzanSearchController,
              onChanged: (val) => setState(() => _ramzanSearchQuery = val),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
                fontFamily: AppTheme.getFontForLanguage(context, settings.language),
              ),
              decoration: InputDecoration(
                hintText: searchHint,
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 14,
                  fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                ),
                prefixIcon: const Icon(Icons.search_rounded, color: sageAccent, size: 22),
                suffixIcon: _ramzanSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _ramzanSearchController.clear();
                          setState(() => _ramzanSearchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 6),

        // Table Header Pill Bar (No. | Title & Author | Page)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3F7A63), Color(0xFF2E5E4C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E5E4C).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  child: Text(
                    noLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      nameLabel,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                      ),
                    ),
                  ),
                ),
                Text(
                  pageLabel,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Topic Cards List
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Text(
                    settings.translate(
                      'No topics found',
                      'کوئی موضوع نہیں ملا',
                      'ڪو موضوع نه مليو',
                      'لم يتم العثور على موضوع',
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 14,
                      fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final topic = list[index];
                    return _buildAhmiyatRamzanTopicTile(
                      context,
                      topic: topic,
                      isDark: isDark,
                      settings: settings,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAhmiyatRamzanTopicTile(
    BuildContext context, {
    required AhmiyatRamzanTopic topic,
    required bool isDark,
    required SettingsProvider settings,
  }) {
    final pageLabel = settings.translate('Page', 'صفحہ', 'صفحو', 'صفحة');
    final titleStr = topic.getTitle(settings.language);
    final authorStr = topic.getAuthor(settings.language);

    return Container(
      margin: const EdgeInsets.only(bottom: 10.0, left: 16.0, right: 16.0),
      constraints: const BoxConstraints(minHeight: 76.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B2C33) : Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openAhmiyatRamzanPage(context, topic.page, titleStr),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 16.0),
              child: Directionality(
                textDirection: settings.isRtl ? TextDirection.rtl : TextDirection.ltr,
                child: Row(
                  children: [
                    // Badge Number Circle with Ahmiyat-e-Ramzan Logo Thumbnail
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                              width: 1.2,
                            ),
                            image: const DecorationImage(
                              image: AssetImage('assets/images/ahmiyat_ramzan_logo.jpg'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: -4,
                          left: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3F7A63),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? const Color(0xFF2B2C33) : Colors.white,
                                width: 2,
                              ),
                            ),
                            constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                            alignment: Alignment.center,
                            child: Text(
                              _translateNumber(topic.num, settings),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 14),

                    // Topic Title & Author in light text below
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            titleStr,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            authorStr,
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.black54,
                              fontSize: 12.5,
                              fontWeight: FontWeight.normal,
                              fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Page Button Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3F7A63), Color(0xFF2E5E4C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.menu_book_rounded, color: Colors.white, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            '$pageLabel ${_translateNumber(topic.page, settings)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 6),

                    Icon(
                      settings.isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                      size: 22,
                      color: isDark ? Colors.white38 : Colors.black26,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
