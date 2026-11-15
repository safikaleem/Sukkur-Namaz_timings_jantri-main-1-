import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/timings_data.dart';
import '../l10n/world_translations.dart';
import '../l10n/world_translations_extra.dart';
import '../models/namaz_timing.dart';
import '../providers/settings_provider.dart';
import '../services/jamaat_times_service.dart';
import '../services/multilingual_city_aliases.dart';
import '../utils/app_theme.dart';
import '../utils/hijri_converter.dart';
import '../utils/web_download_helper.dart';

/// Service to show preview and share branded Islamic prayer & Jama'at cards.
class TimingsShareService {
  static void showNamazShareModal({
    required BuildContext context,
    required DayTiming dayTiming,
    required DateTime date,
    required SettingsProvider settings,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TimingsShareModal(
        dayTiming: dayTiming,
        date: date,
        settings: settings,
        isMasjid: false,
      ),
    );
  }

  static void showMasjidShareModal({
    required BuildContext context,
    required JamaatMasjidInfo masjid,
    required JamaatTiming timing,
    required DateTime date,
    required SettingsProvider settings,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TimingsShareModal(
        masjid: masjid,
        masjidTiming: timing,
        date: date,
        settings: settings,
        isMasjid: true,
      ),
    );
  }
}

class _TimingsShareModal extends StatefulWidget {
  final DayTiming? dayTiming;
  final JamaatMasjidInfo? masjid;
  final JamaatTiming? masjidTiming;
  final DateTime date;
  final SettingsProvider settings;
  final bool isMasjid;

  const _TimingsShareModal({
    this.dayTiming,
    this.masjid,
    this.masjidTiming,
    required this.date,
    required this.settings,
    required this.isMasjid,
  });

  @override
  State<_TimingsShareModal> createState() => _TimingsShareModalState();
}

class _TimingsShareModalState extends State<_TimingsShareModal> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isProcessing = false;
  late DateTime _selectedDate;
  late DayTiming? _currentDayTiming;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.date;
    _currentDayTiming = widget.dayTiming;
  }

  void _selectDate(DateTime newDate) {
    if (DateUtils.isSameDay(_selectedDate, newDate)) return;
    setState(() {
      _selectedDate = newDate;
      _currentDayTiming = TimingsData.instance.timingFor(newDate);
    });
  }

  Future<Uint8List?> _captureCardBytes() async {
    final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _shareImage() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    final lang = widget.settings.language;

    try {
      final pngBytes = await _captureCardBytes();
      if (pngBytes == null) throw Exception('Render boundary not found');

      final filename = 'sukkur_salah_${DateTime.now().millisecondsSinceEpoch}.png';

      if (kIsWeb) {
        bool shared = false;
        try {
          final xFile = XFile.fromData(
            pngBytes,
            mimeType: 'image/png',
            name: filename,
          );
          // ignore: deprecated_member_use
          final result = await Share.shareXFiles([xFile]);
          if (result.status == ShareResultStatus.success) {
            shared = true;
          }
        } catch (_) {
          shared = false;
        }

        if (!shared) {
          saveImageOnWeb(pngBytes, filename);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF0F5A44),
                content: Text(
                  _tWebShareSuccess(lang),
                  style: TextStyle(
                    fontFamily: AppTheme.getFontForLanguage(context, lang),
                    fontSize: 15,
                  ),
                  textDirection: _isRtl(lang) ? TextDirection.rtl : TextDirection.ltr,
                ),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      } else {
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/$filename';
        final file = File(filePath);
        await file.writeAsBytes(pngBytes, flush: true);

        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile(file.path)],
        );
      }
    } catch (e) {
      if (mounted) {
        _copyOrShareText();
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _downloadImage() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    final lang = widget.settings.language;

    try {
      final pngBytes = await _captureCardBytes();
      if (pngBytes == null) throw Exception('Render boundary not found');

      final filename = 'sukkur_salah_${DateTime.now().millisecondsSinceEpoch}.png';

      if (kIsWeb) {
        saveImageOnWeb(pngBytes, filename);
      } else {
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/$filename';
        final file = File(filePath);
        await file.writeAsBytes(pngBytes, flush: true);

        // ignore: deprecated_member_use
        await Share.shareXFiles([XFile(file.path)]);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0F5A44),
            content: Text(
              _tDownloadSuccess(lang),
              style: TextStyle(
                fontFamily: AppTheme.getFontForLanguage(context, lang),
                fontSize: 15,
              ),
              textDirection: _isRtl(lang) ? TextDirection.rtl : TextDirection.ltr,
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _copyOrShareText();
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _copyOrShareText() {
    final lang = widget.settings.language;
    final buffer = StringBuffer();
    if (widget.isMasjid) {
      final m = widget.masjid;
      final t = widget.masjidTiming;
      buffer.writeln('🕌 ${TimingsShareCard.getMasjidUrduName(m)}');
      if (TimingsShareCard.getMasjidUrduAddress(m).isNotEmpty) {
        buffer.writeln('📍 ${TimingsShareCard.getMasjidUrduAddress(m)}');
      }
      buffer.writeln('📅 ${_formatDate(widget.date)}');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('🌅 فجر: ${TimingsShareCard._formatMasjidTime(t?.fajr)}');
      buffer.writeln('🕛 ظہر: ${TimingsShareCard._formatMasjidTime(t?.zuhar)}');
      buffer.writeln('🌇 عصر: ${TimingsShareCard._formatMasjidTime(t?.asar)}');
      buffer.writeln('🌆 مغرب: ${TimingsShareCard._formatMasjidTime(t?.maghrib)}');
      buffer.writeln('🌙 عشاء: ${TimingsShareCard._formatMasjidTime(t?.isha)}');
      buffer.writeln('🕌 جمعہ: ${TimingsShareCard._formatMasjidTime(t?.jummah)}');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('سکھر صلاة (ایپلیکیشن)');
      buffer.writeln('نماز اور جماعت کے اوقات جاننے کے لیے Play Store سے ابھی Sukkur Salah ایپلیکیشن ڈاؤن لوڈ کریں');
    } else {
      final d = _currentDayTiming ?? widget.dayTiming;
      final isSukkur = widget.settings.locationMode == LocationMode.sukkur;
      final cityPair = TimingsShareCard.getCityNames(widget.settings);
      final cityUrdu = cityPair.urdu;
      final cityEnglish = cityPair.english;

      if (isSukkur) {
        buffer.writeln('🕌 مستند اوقاتِ نماز برائے سکھر • Sukkur');
      } else {
        buffer.writeln('🕌 اوقاتِ نماز برائے $cityUrdu • $cityEnglish');
      }
      buffer.writeln('📅 ${_formatDate(_selectedDate)}');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
      if (d != null) {
        final timings = d.allTimings;
        for (final pt in timings) {
          final urdu = pt.name == 'Intiha e Sehar' ? 'انتہائے سحر' : pt.urduName;
          final eng = TimingsShareCard._englishNameFor(pt.name);
          buffer.writeln('$urdu ($eng): ${pt.displayTime} ${pt.displayIsPm ? "PM" : "AM"}');
        }
      }
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('سکھر صلاة (ایپلیکیشن)');
      buffer.writeln('نماز کے اوقات جاننے کے لیے Play Store سے ابھی Sukkur Salah ایپلیکیشن ڈاؤن لوڈ کریں');
      if (!widget.isMasjid && isSukkur) {
        buffer.writeln('مسجد باب الاسلام، اناج بازار، سکھر');
      }
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _tCopySuccess(lang),
          style: TextStyle(fontFamily: AppTheme.getFontForLanguage(context, lang)),
          textDirection: _isRtl(lang) ? TextDirection.rtl : TextDirection.ltr,
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const months = ['جنوری', 'فروری', 'مارچ', 'اپریل', 'مئی', 'جون', 'جولائی', 'اگست', 'ستمبر', 'اکتوبر', 'نومبر', 'دسمبر'];
    const days = ['پیر', 'منگل', 'بدھ', 'جمعرات', 'جمعہ', 'ہفتہ', 'اتوار'];
    final dName = days[date.weekday - 1];
    final mName = months[date.month - 1];
    return '$dName، ${date.day} $mName ${date.year}ء';
  }

  static String _formatDatePill(DateTime d, String lang) {
    const urduMonths = ['جنوری', 'فروری', 'مارچ', 'اپریل', 'مئی', 'جون', 'جولائی', 'اگست', 'ستمبر', 'اکتوبر', 'نومبر', 'دسمبر'];
    const urduDays = ['پیر', 'منگل', 'بدھ', 'جمعرات', 'جمعہ', 'ہفتہ', 'اتوار'];
    const engMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const engDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    if (lang == 'english') {
      return '${engDays[d.weekday - 1]}، ${d.day} ${engMonths[d.month - 1]}';
    } else {
      return '${urduDays[d.weekday - 1]}، ${d.day} ${urduMonths[d.month - 1]}';
    }
  }

  Widget _buildDateOption({
    required DateTime date,
    required bool isSelected,
    required bool isDark,
    required String? font,
  }) {
    final lang = widget.settings.language;
    final dateText = _formatDatePill(date, lang);

    return InkWell(
      onTap: () => _selectDate(date),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0F5A44)
              : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0F5A44)
                : (isDark ? Colors.white12 : Colors.black12),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                dateText,
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 13.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Translations for all 10 languages ─────────────────────────────────
  static String _tHeader(String lang, bool isMasjid) {
    if (isMasjid) {
      switch (lang) {
        case 'sindhi': return 'مسجد ڪارڊ شيئر ڪريو';
        case 'arabic': return 'مشاركة بطاقة المسجد';
        case 'bengali': return 'মসজিদ কার্ড শেয়ার করুন';
        case 'indonesian': return 'Bagikan Kartu Masjid';
        case 'turkish': return 'Cami Kartını Paylaş';
        case 'french': return 'Partager la carte de la mosquée';
        case 'hindi': return 'मस्जिद कार्ड शेयर करें';
        case 'persian': return 'اشتراک‌گذاری کارت مسجد';
        case 'english': return 'Share Masjid Card';
        default: return 'مسجد کارڈ شیئر کریں';
      }
    } else {
      switch (lang) {
        case 'sindhi': return 'نماز جي وقتن جو ڪارڊ شيئر ڪريو';
        case 'arabic': return 'مشاركة بطاقة مواقيت الصلاة';
        case 'bengali': return 'নামাজের সময়সূচি কার্ড শেয়ার করুন';
        case 'indonesian': return 'Bagikan Kartu Jadwal Sholat';
        case 'turkish': return 'Namaz Vakitleri Kartını Paylaş';
        case 'french': return 'Partager la carte des prières';
        case 'hindi': return 'नमाज़ के समय का कार्ड शेयर करें';
        case 'persian': return 'اشتراک‌گذاری کارت اوقات نماز';
        case 'english': return 'Share Prayer Timings Card';
        default: return 'اوقاتِ نماز کارڈ شیئر کریں';
      }
    }
  }

  static String _tShare(String lang) {
    switch (lang) {
      case 'sindhi': return 'ڪارڊ شيئر ڪريو';
      case 'arabic': return 'مشاركة البطاقة';
      case 'bengali': return 'কার্ড শেয়ার করুন';
      case 'indonesian': return 'Bagikan Kartu';
      case 'turkish': return 'Kartı Paylaş';
      case 'french': return 'Partager la carte';
      case 'hindi': return 'कार्ड शेयर करें';
      case 'persian': return 'اشتراک‌گذاری کارت';
      case 'english': return 'Share Card';
      default: return 'کارڈ شیئر کریں';
    }
  }

  static String _tDownload(String lang) {
    switch (lang) {
      case 'sindhi': return 'ڊائون لوڊ (PNG)';
      case 'arabic': return 'تحميل (PNG)';
      case 'bengali': return 'ডাউনলোড (PNG)';
      case 'indonesian': return 'Unduh (PNG)';
      case 'turkish': return 'İndir (PNG)';
      case 'french': return 'Télécharger (PNG)';
      case 'hindi': return 'डाउनलोड (PNG)';
      case 'persian': return 'دانلود (PNG)';
      case 'english': return 'Save (PNG)';
      default: return 'ڈاؤن لوڈ (PNG)';
    }
  }

  static String _tCopy(String lang) {
    switch (lang) {
      case 'sindhi': return 'ٽيڪسٽ ڪاپي ڪريو';
      case 'arabic': return 'نسخ النص';
      case 'bengali': return 'টেক্সট কপি করুন';
      case 'indonesian': return 'Salin teks';
      case 'turkish': return 'Metni kopyala';
      case 'french': return 'Copier le texte';
      case 'hindi': return 'टेक्स्ट कॉपी करें';
      case 'persian': return 'کپی متن';
      case 'english': return 'Copy text';
      default: return 'ٹیکسٹ کاپی کریں';
    }
  }

  static String _tPreparing(String lang) {
    switch (lang) {
      case 'sindhi': return 'تيار ٿي رهيو آهي...';
      case 'arabic': return 'جارٍ التحضير...';
      case 'bengali': return 'প্রস্তুত হচ্ছে...';
      case 'indonesian': return 'Menyiapkan...';
      case 'turkish': return 'Hazırlanıyor...';
      case 'french': return 'Préparation...';
      case 'hindi': return 'तैयार हो रहा है...';
      case 'persian': return 'در حال آماده‌سازی...';
      case 'english': return 'Preparing...';
      default: return 'تیار ہو رہا ہے...';
    }
  }

  static String _tDownloadSuccess(String lang) {
    switch (lang) {
      case 'sindhi': return 'تصوير ڊائون لوڊ ٿي وئي آهي!';
      case 'arabic': return 'تم تحميل صورة البطاقة بنجاح!';
      case 'bengali': return 'কার্ড সফলভাবে ডাউনলোড হয়েছে!';
      case 'indonesian': return 'Gambar kartu berhasil diunduh!';
      case 'turkish': return 'Kart resmi başarıyla indirildi!';
      case 'french': return 'Image de la carte téléchargée avec succès !';
      case 'hindi': return 'कार्ड की छवि सफलतापूर्वक डाउनलोड हो गई!';
      case 'persian': return 'تصویر کارت با موفقیت دانلود شد!';
      case 'english': return 'Card image downloaded successfully!';
      default: return 'تصویر ڈاؤن لوڈ ہو گئی ہے!';
    }
  }

  static String _tWebShareSuccess(String lang) {
    switch (lang) {
      case 'sindhi': return 'ڪارڊ محفوظ ٿي ويو ۽ واٽس ايپ کلي رهيو آهي!';
      case 'arabic': return 'تم حفظ البطاقة وفتح واتساب!';
      case 'bengali': return 'কার্ড সংরক্ষিত হয়েছে এবং হোয়াটসঅ্যাপ খোলা হচ্ছে!';
      case 'indonesian': return 'Kartu disimpan & membuka WhatsApp!';
      case 'turkish': return 'Kart kaydedildi ve WhatsApp açılıyor!';
      case 'french': return 'Carte enregistrée et ouverture de WhatsApp !';
      case 'hindi': return 'कार्ड सुरक्षित हो गया और व्हाट्सएप खुल रहा है!';
      case 'persian': return 'کارت ذخیره شد و واتس‌اپ باز می‌شود!';
      case 'english': return 'Card saved & opening WhatsApp!';
      default: return 'کارڈ محفوظ ہو گیا اور واٹس ایپ کھل رہا ہے!';
    }
  }

  static String _tCopySuccess(String lang) {
    switch (lang) {
      case 'sindhi': return 'نماز جا وقت ڪاپي ڪيا ويا';
      case 'arabic': return 'تم نسخ مواقيت الصلاة';
      case 'bengali': return 'নামাজের সময়সূচি ক্লিপবোর্ডে কপি করা হয়েছে';
      case 'indonesian': return 'Jadwal sholat disalin ke papan klip';
      case 'turkish': return 'Namaz vakitleri panoya kopyalandı';
      case 'french': return 'Horaires de prière copiés dans le presse-papiers';
      case 'hindi': return 'नमाज़ के समय क्लिपबोर्ड पर कॉपी हो गए';
      case 'persian': return 'اوقات نماز در کلیپ‌بورد کپی شد';
      case 'english': return 'Prayer timings copied to clipboard';
      default: return 'اوقاتِ نماز کاپی کر لیے گئے';
    }
  }

  static bool _isRtl(String lang) {
    return lang == 'urdu' || lang == 'sindhi' || lang == 'arabic' || lang == 'persian';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenH = MediaQuery.of(context).size.height;
    final lang = widget.settings.language;
    final font = AppTheme.getFontForLanguage(context, lang);
    final isRtl = _isRtl(lang);
    final isUrdu = lang == 'urdu';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final date1 = (DateUtils.isSameDay(widget.date, today) || DateUtils.isSameDay(widget.date, tomorrow))
        ? today
        : DateTime(widget.date.year, widget.date.month, widget.date.day);
    final date2 = (DateUtils.isSameDay(widget.date, today) || DateUtils.isSameDay(widget.date, tomorrow))
        ? tomorrow
        : date1.add(const Duration(days: 1));

    return Container(
      height: screenH * 0.90,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141A1E) : const Color(0xFFF7FAF8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header (Screenshot 3) - Translated into all 10 languages
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              children: [
                Expanded(
                  child: Text(
                    _tHeader(lang, widget.isMasjid),
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: isUrdu ? 20 : 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Date options (Today & Tomorrow dates only, without "Today" / "Tomorrow" labels)
          if (!widget.isMasjid) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Row(
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                children: [
                  Expanded(
                    child: _buildDateOption(
                      date: date1,
                      isSelected: DateUtils.isSameDay(_selectedDate, date1),
                      isDark: isDark,
                      font: font,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDateOption(
                      date: date2,
                      isSelected: DateUtils.isSameDay(_selectedDate, date2),
                      isDark: isDark,
                      font: font,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Card preview (Scrollable)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: RepaintBoundary(
                    key: _cardKey,
                    child: TimingsShareCard(
                      dayTiming: _currentDayTiming,
                      masjid: widget.masjid,
                      masjidTiming: widget.masjidTiming,
                      date: _selectedDate,
                      settings: widget.settings,
                      isMasjid: widget.isMasjid,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Actions (Screenshot 2) - Translated into all 10 languages with both Download & Share
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF182026) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              children: [
                // Copy text button
                IconButton.filledTonal(
                  onPressed: _copyOrShareText,
                  icon: const Icon(Icons.copy_rounded),
                  tooltip: _tCopy(lang),
                ),
                const SizedBox(width: 8),

                // Save / Download Button (Works in Chrome & Mobile)
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F5A44),
                      side: const BorderSide(color: Color(0xFF0F5A44), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isProcessing ? null : _downloadImage,
                    icon: const Icon(Icons.download_rounded, size: 19),
                    label: Text(
                      _tDownload(lang),
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: isUrdu ? 16 : 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Share Button (Works in Chrome & Mobile)
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F5A44),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _isProcessing ? null : _shareImage,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.share_rounded, size: 19),
                    label: Text(
                      _isProcessing ? _tPreparing(lang) : _tShare(lang),
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: isUrdu ? 16 : 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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

/// The actual visual card widget rendered & captured as an image
class TimingsShareCard extends StatelessWidget {
  final DayTiming? dayTiming;
  final JamaatMasjidInfo? masjid;
  final JamaatTiming? masjidTiming;
  final DateTime date;
  final SettingsProvider settings;
  final bool isMasjid;

  const TimingsShareCard({
    super.key,
    this.dayTiming,
    this.masjid,
    this.masjidTiming,
    required this.date,
    required this.settings,
    required this.isMasjid,
  });

  static String _formatUrduDate(DateTime d) {
    const months = ['جنوری', 'فروری', 'مارچ', 'اپریل', 'مئی', 'جون', 'جولائی', 'اگست', 'ستمبر', 'اکتوبر', 'نومبر', 'دسمبر'];
    const days = ['پیر', 'منگل', 'بدھ', 'جمعرات', 'جمعہ', 'ہفتہ', 'اتوار'];
    final dName = days[d.weekday - 1];
    final mName = months[d.month - 1];
    return '$dName، ${d.day} $mName ${d.year}ء';
  }

  static String _formatMasjidTime(String? time) {
    if (time == null || time.trim().isEmpty) return '--:--';
    final t = time.trim();
    if (t.toLowerCase() == 'sunset') {
      return 'غروبِ آفتاب';
    }
    return t;
  }

  static IconData _iconForPrayer(String name) {
    switch (name) {
      case 'Intiha e Sehar':
        return Icons.wb_twilight_rounded;
      case 'Fajar':
        return Icons.wb_twilight_rounded;
      case 'Tulu Aftab':
        return Icons.wb_sunny_outlined;
      case 'Ishraq':
        return Icons.brightness_high_rounded;
      case 'Zawal':
        return Icons.wb_sunny_rounded;
      case 'Zuhar':
        return Icons.wb_sunny_rounded;
      case 'Misl Awwal':
        return Icons.sunny;
      case 'Asr Hanafi':
      case 'Asr':
        return Icons.wb_cloudy_rounded;
      case 'Maghrib':
        return Icons.nights_stay_outlined;
      case 'Isha':
        return Icons.nightlight_round;
      default:
        return Icons.access_time_rounded;
    }
  }

  static String _englishNameFor(String key) {
    switch (key) {
      case 'Intiha e Sehar':
        return 'Intiha e Sehar';
      case 'Fajar':
      case 'Fajr':
        return 'Fajr';
      case 'Tulu Aftab':
        return 'Sunrise';
      case 'Ishraq':
        return 'Ishraq';
      case 'Zawal':
        return 'Zawal';
      case 'Zuhar':
      case 'Zuhr':
        return 'Zuhr';
      case 'Misl Awwal':
        return 'Misl-e-Awwal';
      case 'Asr Hanafi':
      case 'Asr':
        return 'Asr';
      case 'Maghrib':
        return 'Maghrib';
      case 'Isha':
        return 'Isha';
      default:
        return key;
    }
  }

  static String getMasjidUrduName(JamaatMasjidInfo? masjid) {
    if (masjid == null) return 'مسجد';
    final extra = additionalTranslations['urdu'];
    if (extra != null && extra.containsKey(masjid.nameKey)) {
      return extra[masjid.nameKey]!;
    }
    final world = worldTranslations['urdu'];
    if (world != null && world.containsKey(masjid.nameKey)) {
      return world[masjid.nameKey]!;
    }
    final dyn = masjid.getNameFor('urdu');
    if (dyn.isNotEmpty && dyn != masjid.nameKey) return dyn;
    return masjid.nameKey;
  }

  static String getMasjidUrduAddress(JamaatMasjidInfo? masjid) {
    if (masjid == null) return '';
    final extra = additionalTranslations['urdu'];
    if (extra != null && extra.containsKey(masjid.addressKey)) {
      return extra[masjid.addressKey]!;
    }
    final world = worldTranslations['urdu'];
    if (world != null && world.containsKey(masjid.addressKey)) {
      return world[masjid.addressKey]!;
    }
    final dyn = masjid.getAddressFor('urdu');
    if (dyn.isNotEmpty && dyn != masjid.addressKey) return dyn;
    return masjid.addressKey;
  }

  static const Map<String, String> _englishToUrdu = {
    // Pakistan - Major Cities
    'karachi': 'کراچی',
    'lahore': 'لاہور',
    'islamabad': 'اسلام آباد',
    'rawalpindi': 'راولپنڈی',
    'faisalabad': 'فیصل آباد',
    'multan': 'ملتان',
    'peshawar': 'پشاور',
    'quetta': 'کوئٹہ',
    'sialkot': 'سیالکوٹ',
    'gujranwala': 'گوجرانوالہ',
    'gujrat': 'گجرات',
    'hyderabad': 'حیدرآباد',
    'larkana': 'لاڑکانہ',
    'sukkur': 'سکھر',
    'nawabshah': 'نواب شاہ',
    'shaheed benazirabad': 'شہید بینظیر آباد',
    'mirpur khas': 'میرپور خاص',
    'mirpurkhas': 'میرپور خاص',
    'mardan': 'مردان',
    'kasur': 'قصور',
    'rahim yar khan': 'رحیم یار خان',
    'okara': 'اوکاڑہ',
    'vehari': 'وہاڑی',
    'khanewal': 'خانیوال',
    'dera ghazi khan': 'ڈیرہ غازی خان',
    'dg khan': 'ڈیرہ غازی خان',
    'd.g. khan': 'ڈیرہ غازی خان',
    'dera ismail khan': 'ڈیرہ اسماعیل خان',
    'di khan': 'ڈیرہ اسماعیل خان',
    'd.i. khan': 'ڈیرہ اسماعیل خان',
    'muzaffarabad': 'مظفر آباد',
    'gilgit': 'گلگت',
    'skardu': 'سکردو',
    'bahawalpur': 'بہاولپور',
    'sargodha': 'سرگودھا',
    'sheikhupura': 'شیخوپورہ',
    'jhang': 'جھنگ',
    'chiniot': 'چنیوٹ',
    'abbottabad': 'ایبٹ آباد',
    'mansehra': 'مانسہرہ',
    'mingora': 'مینگورہ',
    'swat': 'سوات',
    'kohat': 'کوہاٹ',
    'bannu': 'بنوں',
    'shikarpur': 'شکارپور',
    'khairpur': 'خیرپور',
    'jacobabad': 'جیکب آباد',
    'ghotki': 'گھوٹکی',
    'badin': 'بدین',
    'thatta': 'ٹھٹھہ',
    'mirpur': 'میرپور',
    'kotli': 'کوٹلی',
    'turbat': 'تربت',
    'gwadar': 'گوادر',
    'hub': 'حب',
    'zhob': 'ژوب',
    'chaman': 'چمن',
    'attock': 'اٹک',
    'chakwal': 'چکوال',
    'jhelum': 'جہلم',
    'mandi bahauddin': 'منڈی بہاؤالدین',
    'hafizabad': 'حافظ آباد',
    'toba tek singh': 'ٹوبہ ٹیک سنگھ',
    'sahiwal': 'ساہیوال',
    'pakpattan': 'پاکپتن',
    'bahawalnagar': 'بہاولنگر',
    'lodhran': 'لودھراں',
    'muzaffargarh': 'مظفر گڑھ',
    'layyah': 'لیہ',
    'bhakkar': 'بھکر',
    'mianwali': 'میانوالی',
    'khushab': 'خوشاب',
    'wazirabad': 'وزیر آباد',
    'kamoke': 'کامونکے',
    'muridke': 'مریدکے',
    'swabi': 'صوابی',
    'charsadda': 'چارسدہ',
    'nowshera': 'نوشہرہ',
    'dadu': 'دادو',
    'tando adam': 'ٹنڈو آدم',
    'tando allahyar': 'ٹنڈو الہٰ یار',
    'umerkot': 'عمرکوٹ',
    'kotri': 'کوٹری',
    'pano aqil': 'پنوعاقل',
    'pannu aqil': 'پنوعاقل',
    'kandhkot': 'کندھ کوٹ',
    'kashmore': 'کشمور',
    'shahdadkot': 'شہداد کوٹ',
    'khuzdar': 'خضدار',
    'sibi': 'سبی',
    'haripur': 'ہری پور',
    'batkhela': 'بٹ خیلہ',

    // Islamic & Middle Eastern Cities
    'makkah': 'مکہ مکرمہ',
    'mecca': 'مکہ مکرمہ',
    'madinah': 'مدینہ منورہ',
    'medina': 'مدینہ منورہ',
    'riyadh': 'ریاض',
    'jeddah': 'جدہ',
    'dammam': 'دمام',
    'khobar': 'الخبر',
    'dubai': 'دبئی',
    'abu dhabi': 'ابوظہبی',
    'sharjah': 'شارجہ',
    'ajman': 'عجمان',
    'doha': 'دوحہ',
    'muscat': 'مسقط',
    'manama': 'منامہ',
    'kuwait': 'کویت سٹی',
    'kuwait city': 'کویت سٹی',
    'cairo': 'قاہرہ',
    'alexandria': 'اسکندریہ',
    'istanbul': 'استنبول',
    'ankara': 'انقرہ',
    'bursa': 'بورصہ',
    'konya': 'قونیہ',
    'tehran': 'تہران',
    'mashhad': 'مشہد',
    'isfahan': 'اصفہان',
    'baghdad': 'بغداد',
    'basra': 'بصرہ',
    'najaf': 'نجف اشرف',
    'karbala': 'کربلا معلی',
    'erbil': 'اربیل',
    'damascus': 'دمشق',
    'aleppo': 'حلب',
    'amman': 'عمان',
    'beirut': 'بیروت',
    'jerusalem': 'القدس',
    'al-quds': 'القدس',
    'gaza': 'غزہ',
    'sana\'a': 'صنعاء',
    'sanaa': 'صنعاء',
    'kabul': 'کابل',
    'kandahar': 'قندھار',
    'herat': 'ہرات',
    'tashkent': 'تاشقند',
    'samarkand': 'سمرقند',
    'bukhara': 'بخارا',
    'baku': 'باکو',

    // South & East Asia
    'delhi': 'دہلی',
    'new delhi': 'نئی دہلی',
    'mumbai': 'ممبئی',
    'kolkata': 'کولکتہ',
    'chennai': 'چنئی',
    'bengaluru': 'بنگلور',
    'bangalore': 'بنگلور',
    'hyderabad (india)': 'حیدرآباد دکن',
    'lucknow': 'لکھنؤ',
    'agra': 'آگرہ',
    'aligarh': 'علی گڑھ',
    'srinagar': 'سری نگر',
    'jammu': 'جموں',
    'dhaka': 'ڈھاکہ',
    'chittagong': 'چٹاگانگ',
    'sylhet': 'سلہٹ',
    'colombo': 'کولمبو',
    'kuala lumpur': 'کوالالمپور',
    'jakarta': 'جکارتہ',
    'surabaya': 'سورابایا',
    'singapore': 'سنگاپور',
    'bangkok': 'بنکاک',
    'beijing': 'بیجنگ',
    'shanghai': 'شنگھائی',
    'tokyo': 'ٹوکیو',
    'seoul': 'سیول',

    // Europe, Americas, Australia, Africa
    'london': 'لندن',
    'birmingham': 'برمنگھم',
    'manchester': 'مانچسٹر',
    'bradford': 'بریڈفورڈ',
    'leeds': 'لیڈز',
    'glasgow': 'گلاسگو',
    'paris': 'پیرس',
    'berlin': 'برلن',
    'frankfurt': 'فرینکفرٹ',
    'munich': 'میونخ',
    'rome': 'روم',
    'milan': 'میلان',
    'madrid': 'میڈرڈ',
    'barcelona': 'بارسلونا',
    'amsterdam': 'ایمسٹرڈیم',
    'brussels': 'برسلز',
    'vienna': 'ویانا',
    'zurich': 'زیورخ',
    'geneva': 'جنیوا',
    'stockholm': 'اسٹاک ہوم',
    'oslo': 'اوسلو',
    'copenhagen': 'کوپن ہیگن',
    'moscow': 'ماسکو',
    'new york': 'نیویارک',
    'chicago': 'شکاگو',
    'los angeles': 'لاس اینجلس',
    'houston': 'ہیوسٹن',
    'dallas': 'ڈیلاس',
    'washington': 'واشنگٹن',
    'toronto': 'ٹورنٹو',
    'montreal': 'مانٹریال',
    'vancouver': 'وینکوور',
    'sydney': 'سڈنی',
    'melbourne': 'میلبورن',
    'perth': 'پرتھ',
    'auckland': 'آکلینڈ',
    'johannesburg': 'جوہانسبرگ',
    'cape town': 'کیپ ٹاؤن',

    // China & East Asian Major Cities
    'guiyang': 'گوئی یانگ',
    'guangzhou': 'گوانگژو',
    'shenzhen': 'شینزین',
    'chengdu': 'چینگدو',
    'wuhan': 'وہان',
    'tianjin': 'تیانجین',
    'hangzhou': 'ہانگژو',
    'chongqing': 'چونگ کنگ',
    'nanjing': 'نانجنگ',
    'xian': 'شیان',
    "xi'an": 'شیان',
    'harbin': 'ہاربن',
    'kunming': 'کنمنگ',
    'dalian': 'ڈالیان',
    'qingdao': 'چنگڈاؤ',
    'shenyang': 'شینیانگ',
    'jinan': 'جینان',
    'changsha': 'چانگشا',
    'fuzhou': 'فوزو',
    'urumqi': 'ارومچی',
    'lhasa': 'لہاسا',
    'haikou': 'ہائیکو',
    'taipei': 'تائی پے',
    'hong kong': 'ہانگ کانگ',
    'macau': 'مکاؤ',
  };

  static String _transliterateEnglishToUrdu(String input) {
    final s = input.trim();
    if (s.isEmpty) return '';
    final words = s.split(RegExp(r'\s+'));
    return words.map(_transliterateWord).join(' ');
  }

  static String _transliterateWord(String word) {
    final w = word.toLowerCase().trim();
    if (w.isEmpty) return '';

    if (_englishToUrdu.containsKey(w)) {
      return _englishToUrdu[w]!;
    }

    final rules = [
      ['tion', 'شن'],
      ['sion', 'شن'],
      ['land', 'لینڈ'],
      ['ville', 'ول'],
      ['burgh', 'برگ'],
      ['burg', 'برگ'],
      ['ford', 'فورڈ'],
      ['port', 'پورٹ'],
      ['field', 'فیلڈ'],
      ['wood', 'وڈ'],
      ['town', 'ٹاؤن'],
      ['city', 'سٹی'],
      ['ton', 'ٹن'],
      ['yang', 'یانگ'],
      ['ying', 'ینگ'],
      ['yong', 'یونگ'],
      ['yuan', 'یوان'],
      ['jiang', 'جیانگ'],
      ['xiang', 'شیانگ'],
      ['liang', 'لیانگ'],
      ['guang', 'گوانگ'],
      ['huang', 'ہوانگ'],
      ['zhang', 'ژانگ'],
      ['shang', 'شانگ'],
      ['chang', 'چانگ'],
      ['gui', 'گوئی'],
      ['zhou', 'ژو'],
      ['chen', 'چین'],
      ['shen', 'شین'],
      ['zheng', 'ژینگ'],
      ['feng', 'فینگ'],
      ['meng', 'مینگ'],
      ['peng', 'پینگ'],
      ['teng', 'تینگ'],
      ['deng', 'ڈینگ'],
      ['geng', 'گینگ'],
      ['keng', 'کینگ'],
      ['heng', 'ہینگ'],
      ['ling', 'لنگ'],
      ['ming', 'منگ'],
      ['ning', 'ننگ'],
      ['ping', 'پنگ'],
      ['ting', 'ٹنگ'],
      ['qing', 'چنگ'],
      ['xing', 'شنگ'],
      ['jing', 'جنگ'],
      ['ding', 'ڈنگ'],
      ['sch', 'ش'],
      ['tch', 'چ'],
      ['kh', 'خ'],
      ['gh', 'غ'],
      ['sh', 'ش'],
      ['ch', 'چ'],
      ['zh', 'ژ'],
      ['th', 'تھ'],
      ['ph', 'ف'],
      ['bh', 'بھ'],
      ['dh', 'دھ'],
      ['jh', 'جھ'],
      ['ck', 'ک'],
      ['qu', 'کو'],
      ['ng', 'نگ'],
      ['ee', 'ی'],
      ['oo', 'و'],
      ['ou', 'او'],
      ['ai', 'ائی'],
      ['ay', 'ے'],
      ['ey', 'ے'],
      ['ea', 'ی'],
      ['oa', 'و'],
      ['ia', 'یا'],
      ['io', 'یو'],
      ['ua', 'وا'],
      ['ue', 'وے'],
      ['ui', 'وئی'],
    ];

    final sb = StringBuffer();
    int i = 0;
    while (i < w.length) {
      bool matched = false;
      for (final r in rules) {
        if (w.startsWith(r[0], i)) {
          sb.write(r[1]);
          i += r[0].length;
          matched = true;
          break;
        }
      }
      if (matched) continue;

      final c = w[i];
      final isFirst = (i == 0);
      final isLast = (i == w.length - 1);

      switch (c) {
        case 'a':
          sb.write(isFirst ? 'آ' : 'ا');
          break;
        case 'e':
          sb.write(isFirst ? 'ای' : (isLast ? 'ہ' : 'ی'));
          break;
        case 'i':
          sb.write(isFirst ? 'ای' : 'ی');
          break;
        case 'o':
          sb.write(isFirst ? 'او' : 'و');
          break;
        case 'u':
          sb.write(isFirst ? 'او' : 'و');
          break;
        case 'y':
          sb.write(isFirst ? 'ی' : 'ی');
          break;
        case 'b': sb.write('ب'); break;
        case 'c':
          if (i + 1 < w.length && (w[i+1] == 'e' || w[i+1] == 'i' || w[i+1] == 'y')) {
            sb.write('س');
          } else {
            sb.write('ک');
          }
          break;
        case 'd': sb.write('ڈ'); break;
        case 'f': sb.write('ف'); break;
        case 'g': sb.write('گ'); break;
        case 'h': sb.write('ہ'); break;
        case 'j': sb.write('ج'); break;
        case 'k': sb.write('ک'); break;
        case 'l': sb.write('ل'); break;
        case 'm': sb.write('م'); break;
        case 'n': sb.write('ن'); break;
        case 'p': sb.write('پ'); break;
        case 'q': sb.write('ق'); break;
        case 'r': sb.write('ر'); break;
        case 's': sb.write('س'); break;
        case 't': sb.write('ٹ'); break;
        case 'v': sb.write('و'); break;
        case 'w': sb.write('و'); break;
        case 'x': sb.write('کس'); break;
        case 'z': sb.write('ز'); break;
        default:
          if (c != "'" && c != "-") {
            sb.write(c);
          }
      }
      i++;
    }

    return sb.toString();
  }

  static ({String urdu, String english}) getCityNames(SettingsProvider settings) {
    if (settings.isKarachi ||
        (settings.cityName?.toLowerCase() == 'karachi') ||
        (settings.cityName == 'کراچی') ||
        (settings.cityName == 'ڪراچي')) {
      return (urdu: 'کراچی', english: 'Karachi');
    }

    final raw = settings.cityName?.trim();
    if (raw == null || raw.isEmpty) {
      return (urdu: 'سکھر', english: 'Sukkur');
    }

    final cityClean = raw.split(',').first.trim();
    final lower = cityClean.toLowerCase();

    if (_englishToUrdu.containsKey(lower)) {
      return (urdu: _englishToUrdu[lower]!, english: _formatEnglishCity(cityClean));
    }

    for (final entry in _englishToUrdu.entries) {
      if (entry.value == cityClean || entry.value == raw) {
        return (urdu: entry.value, english: _formatEnglishCity(entry.key));
      }
    }

    final hasUrduChars = RegExp(r'[\u0600-\u06FF]').hasMatch(cityClean);
    if (hasUrduChars) {
      final matches = MultilingualCityAliases.getMatchingEnglishCities(cityClean);
      final eng = matches.isNotEmpty ? matches.first : cityClean;
      return (urdu: cityClean, english: _formatEnglishCity(eng));
    } else {
      final normalized = MultilingualCityAliases.normalize(cityClean);
      for (final entry in _englishToUrdu.entries) {
        if (MultilingualCityAliases.normalize(entry.key) == normalized) {
          return (urdu: entry.value, english: _formatEnglishCity(cityClean));
        }
      }
      final transliterated = _transliterateEnglishToUrdu(cityClean);
      return (urdu: transliterated, english: _formatEnglishCity(cityClean));
    }
  }

  static String _formatEnglishCity(String name) {
    if (name.isEmpty) return '';
    if (RegExp(r'[\u0600-\u06FF]').hasMatch(name)) return name;

    return name
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + (word.length > 1 ? word.substring(1).toLowerCase() : ''))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final isSukkur = settings.locationMode == LocationMode.sukkur;
    final cityPair = getCityNames(settings);
    final cityUrdu = cityPair.urdu;
    final cityEnglish = cityPair.english;
    final hijriStr = HijriConverter.hijriForDate(date, adjustment: settings.hijriAdjustment, language: 'urdu');

    return Container(
      width: 420,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: AssetImage('assets/images/islamic_card_bg.png'),
          fit: BoxFit.fill,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 78, 22, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Bismillah (Refined size & positioned clear of the moon icon)
          const Text(
            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            style: TextStyle(
              fontFamily: AppTheme.urduFont,
              fontSize: 19.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F3E2E),
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 5),

          // ── Card Header ──────────────────────────────────────────────
          if (isMasjid) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2.5),
              decoration: BoxDecoration(
                color: const Color(0xFF8B6508).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF8B6508).withValues(alpha: 0.4)),
              ),
              child: const Text(
                'اوقاتِ جماعت',
                style: TextStyle(
                  fontFamily: AppTheme.urduFont,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B6508),
                  height: 1.3,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              getMasjidUrduName(masjid),
              style: const TextStyle(
                fontFamily: AppTheme.urduFont,
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F3E2E),
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            if (getMasjidUrduAddress(masjid).isNotEmpty)
              Text(
                getMasjidUrduAddress(masjid),
                style: const TextStyle(
                  fontFamily: AppTheme.urduFont,
                  fontSize: 13.5,
                  color: Color(0xFF5D4037),
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
          ] else if (isSukkur) ...[
            const Text(
              'مستند اوقاتِ نماز برائے سکھر',
              style: TextStyle(
                fontFamily: AppTheme.urduFont,
                fontSize: 20,
                color: Color(0xFF8B6508),
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 2),
            const Text(
              '(جنتری حضرت ڈاکٹر حفیظ اللہ صاحب قدس اللہ سرہٗ)',
              style: TextStyle(
                fontFamily: AppTheme.urduFont,
                fontSize: 13,
                color: Color(0xFF4A6B5D),
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 2),
            const Text(
              'Sukkur',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F3E2E),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            Text(
              'اوقاتِ نماز برائے $cityUrdu',
              style: const TextStyle(
                fontFamily: AppTheme.urduFont,
                fontSize: 20,
                color: Color(0xFF8B6508),
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 2),
            Text(
              cityEnglish,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F3E2E),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 8),

          // ── Date Banner ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF0F3E2E).withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF8B6508).withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    _formatUrduDate(date),
                    style: const TextStyle(
                      fontFamily: AppTheme.urduFont,
                      fontSize: 14,
                      color: Color(0xFF0F3E2E),
                      fontWeight: FontWeight.bold,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(color: Color(0xFF8B6508), shape: BoxShape.circle),
                ),
                Flexible(
                  child: Text(
                    hijriStr,
                    style: const TextStyle(
                      fontFamily: AppTheme.urduFont,
                      fontSize: 14,
                      color: Color(0xFF8B6508),
                      fontWeight: FontWeight.bold,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Timings Grid / Table ─────────────────────────────────────
          if (isMasjid) ...[
            _buildMasjidRow('فجر', _formatMasjidTime(masjidTiming?.fajr), Icons.wb_twilight_rounded),
            _buildMasjidRow('ظہر', _formatMasjidTime(masjidTiming?.zuhar), Icons.wb_sunny_rounded),
            _buildMasjidRow('عصر', _formatMasjidTime(masjidTiming?.asar), Icons.wb_cloudy_rounded),
            _buildMasjidRow('مغرب', _formatMasjidTime(masjidTiming?.maghrib), Icons.nights_stay_outlined),
            _buildMasjidRow('عشاء', _formatMasjidTime(masjidTiming?.isha), Icons.nightlight_round),
            _buildMasjidRow('جمعہ', _formatMasjidTime(masjidTiming?.jummah), Icons.mosque_rounded),
          ] else ...[
            if (dayTiming != null)
              ...dayTiming!.allTimings.map((pt) {
                final urduName = pt.name == 'Intiha e Sehar'
                    ? 'انتہائے سحر'
                    : (pt.name == 'Zawal' ? 'زوالِ آفتاب' : pt.urduName);
                final englishName = _englishNameFor(pt.name);
                final timeFormatted = '${pt.displayTime} ${pt.displayIsPm ? "PM" : "AM"}';
                final icon = _iconForPrayer(pt.name);

                return _buildPrayerRow(
                  name: urduName,
                  englishName: englishName,
                  time: timeFormatted,
                  icon: icon,
                  isHighlight: false,
                );
              }),
          ],

          const SizedBox(height: 14),

          // ── Footer ───────────────────────────────────────────────────
          // Exactly as requested:
          // NO "منجانب"
          // Top: [App Logo on right side] + سکھر صلاة (ایپلیکیشن)
          // Middle (RTL): Play Store سے ابھی Sukkur Salah ایپلی کیشن ڈاؤن لوڈ کریں
          // Bottom (RTL): مسجد باب الاسلام، اناج بازار، سکھر (Only on general prayer card, not on jamat times card)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F3E2E).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF8B6508).withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                // Row 1: Logo on the right side of sukkur salah (RTL)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  textDirection: TextDirection.rtl,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF8B6508), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B6508).withValues(alpha: 0.25),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/favicon.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'سکھر صلاة (ایپلیکیشن)',
                      style: TextStyle(
                        fontFamily: AppTheme.urduFont,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F3E2E),
                        height: 1.4,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),

                const SizedBox(height: 3),

                // Row 2: Urdu prompt before Play Store (in right side / RTL)
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontFamily: AppTheme.urduFont,
                      fontSize: 13,
                      color: Color(0xFF8B6508),
                      height: 1.45,
                    ),
                    children: [
                      TextSpan(
                        text: isMasjid
                            ? 'نماز اور جماعت کے اوقات جاننے کے لیے\n'
                            : 'نماز کے اوقات جاننے کے لیے\n',
                      ),
                      const TextSpan(
                        text: 'Play Store ',
                        style: TextStyle(
                          fontFamily: 'sans-serif',
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F3E2E),
                        ),
                      ),
                      const TextSpan(text: 'سے ابھی '),
                      const TextSpan(
                        text: 'Sukkur Salah ',
                        style: TextStyle(
                          fontFamily: 'sans-serif',
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F3E2E),
                        ),
                      ),
                      const TextSpan(text: 'ایپلیکیشن ڈاؤن لوڈ کریں'),
                    ],
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),

                // Row 3: Masjid Babul Islam, Anaj Bazar, Sukkur (Only for general prayer times card in Sukkur mode)
                if (!isMasjid && isSukkur) ...[
                  const SizedBox(height: 3),
                  const Text(
                    'مسجد باب الاسلام، اناج بازار، سکھر',
                    style: TextStyle(
                      fontFamily: AppTheme.urduFont,
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F3E2E),
                      height: 1.3,
                    ),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerRow({
    required String name,
    String? englishName,
    required String time,
    required IconData icon,
    bool isHighlight = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isHighlight
            ? const Color(0xFF8B6508).withValues(alpha: 0.12)
            : const Color(0xFF0F3E2E).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlight
              ? const Color(0xFF8B6508).withValues(alpha: 0.45)
              : const Color(0xFF8B6508).withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          // ── Column 1 (Left): English prayer name (straight column, aligned left, no brackets)
          SizedBox(
            width: 105,
            child: Text(
              englishName ?? '',
              textAlign: TextAlign.left,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: const TextStyle(
                fontFamily: 'sans-serif',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A3525),
                letterSpacing: 0.2,
              ),
            ),
          ),

          // ── Column 2 (Center): Prayer Time with Icon inside pill (perfectly centered)
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F3E2E).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF0F3E2E).withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 14,
                      color: const Color(0xFF8B6508),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      time,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        fontFamily: 'sans-serif',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F3E2E),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Column 3 (Right): Urdu prayer name (straight column, aligned right, Nastaleeq)
          SizedBox(
            width: 105,
            child: Text(
              name,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: const TextStyle(
                fontFamily: AppTheme.urduFont,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F3E2E),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasjidRow(String name, String time, IconData icon, {bool isHighlight = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isHighlight
            ? const Color(0xFF8B6508).withValues(alpha: 0.14)
            : const Color(0xFF0F3E2E).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlight
              ? const Color(0xFF8B6508).withValues(alpha: 0.45)
              : const Color(0xFF8B6508).withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          // Left side: Time (Strictly Left in all languages & cities)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: isHighlight ? const Color(0xFF8B6508).withValues(alpha: 0.15) : const Color(0xFF0F3E2E).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF8B6508).withValues(alpha: 0.25)),
            ),
            child: Text(
              time,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                fontFamily: 'sans-serif',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F3E2E),
                letterSpacing: 0.4,
              ),
            ),
          ),

          const Spacer(),

          // Right side: Urdu Name + Icon (Strictly Right, No English in Jamaat)
          Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              // Icon capsule on far right
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B6508).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF8B6508).withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: const Color(0xFF8B6508),
                ),
              ),

              const SizedBox(width: 8),

              // Urdu Name
              Text(
                name,
                style: const TextStyle(
                  fontFamily: AppTheme.urduFont,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F3E2E),
                  height: 1.3,
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
