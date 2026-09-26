import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/settings_provider.dart';
import '../services/munajat_download_service.dart';
import '../utils/app_theme.dart';
import '../widgets/dr_slogan_footer.dart';
import 'munajat_reader_screen.dart';

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
      );
    } else {
      _showDownloadDialog(context, page, title);
    }
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
            return AlertDialog(
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
    });
  }

  String _translateNumber(int number, SettingsProvider settings) {
    if (settings.language == 'english') return number.toString();
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String numStr = number.toString();
    for (int i = 0; i < english.length; i++) {
      numStr = numStr.replaceAll(english[i], arabic[i]);
    }
    return numStr;
  }

  String _getMunajatTitle(SettingsProvider settings) {
    switch (settings.language) {
      case 'urdu': return 'مناجات';
      case 'sindhi': return 'مناجات';
      case 'arabic': return 'مناجاة';
      case 'bengali': return 'মুনাজাত';
      case 'hindi': return 'मुनाजात';
      case 'turkish': return 'Münacat';
      case 'indonesian': return 'Munajat';
      case 'french': return 'Munajat';
      case 'russian': return 'Мунаджат';
      case 'persian': return 'مناجات';
      default: return 'Munajat';
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

  String _getMunajatBooksLabel(SettingsProvider settings) {
    switch (settings.language) {
      case 'urdu': return 'مناجات کی کتب';
      case 'sindhi': return 'مناجات جون ڪتابون';
      case 'arabic': return 'كتب المناجاة';
      case 'bengali': return 'মুনাজাতের বই';
      case 'hindi': return 'मुनाजात की किताबें';
      case 'turkish': return 'Münacat Kitapları';
      case 'indonesian': return 'Buku Munajat';
      case 'french': return 'Livres de Munajat';
      case 'russian': return 'Книги Мунаджата';
      case 'persian': return 'کتاب‌های مناجات';
      default: return 'Munajat Books';
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

  String _getManzilTitle(Map<String, dynamic> item, SettingsProvider settings) {
    return settings.translate(
      item['en'] as String,
      item['ur'] as String,
      item['sd'] as String,
      item['ar'] as String,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !_showingManzils,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _showingManzils) {
          setState(() {
            _showingManzils = false;
          });
        }
      },
      child: Scaffold(
        backgroundColor: settings.displayThemeBg(isDark),
        body: SafeArea(
          child: _showingManzils
              ? _buildManzilsScreen(context, settings, isDark)
              : _buildBooksListScreen(context, settings, isDark),
        ),
      ),
    );
  }

  /// Screen 1: Munajat Books View (Displays Munajaat Maqbool & future books)
  Widget _buildBooksListScreen(BuildContext context, SettingsProvider settings, bool isDark) {
    final title = _getMunajatTitle(settings);
    final booksLabel = _getMunajatBooksLabel(settings);
    final munajaatMaqboolTitle = _getMunajaatMaqboolTitle(settings);
    final subtitle = _getSevenManzilsSubtitle(settings);
    final manzilsBadge = settings.translate('7 Manzils', '۷ منزلیں', '7 منزلون', '٧ منازل');

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
              // Section Header Label
              Padding(
                padding: const EdgeInsets.only(left: 4.0, right: 4.0, bottom: 12.0),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3F7A63),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      booksLabel,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                      ),
                    ),
                  ],
                ),
              ),

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

              // Future books can be added here easily!
            ],
          ),
        ),

        const DrSloganFooter(),
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

        const DrSloganFooter(),
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
            onTap: () => _openManzilPage(context, (item['pdfPage'] as int?) ?? pageVal, titleStr),
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
}
