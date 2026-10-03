import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/world_translations.dart';
import '../providers/settings_provider.dart';
import '../services/jamaat_times_service.dart';
import '../utils/app_theme.dart';

class JamaatTimesScreen extends StatefulWidget {
  const JamaatTimesScreen({super.key});

  @override
  State<JamaatTimesScreen> createState() => _JamaatTimesScreenState();
}

class _JamaatTimesScreenState extends State<JamaatTimesScreen> {
  @override
  void initState() {
    super.initState();
    _loadRemoteTimings();
  }

  Future<void> _loadRemoteTimings() async {
    await JamaatTimesService.instance.fetchRemoteGistTimings();
    if (mounted) setState(() {});
  }

  String _t(
    SettingsProvider settings,
    String key, [
    String? ur,
    String? sd,
    String? ar,
  ]) {
    final lang = settings.language;
    final map = worldTranslations[lang];
    if (map != null && map.containsKey(key)) {
      return map[key]!;
    }
    return settings.translate(key, ur ?? key, sd ?? ur ?? key, ar);
  }

  void _showJamaatTableModal(
    BuildContext context,
    JamaatMasjidInfo masjid,
    SettingsProvider settings,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = settings.language;
    final timing = JamaatTimesService.instance.getTimingFor(masjid);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
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
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag Handle ──────────────────────────────────────
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white30 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // ── Header Card ──────────────────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
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
                            _t(settings, masjid.nameKey),
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
                            _t(settings, masjid.addressKey),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

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
                        subNoteKey: 'Fixed',
                        time: timing.zuhar,
                        lastUpdated: '',
                        icon: Icons.wb_sunny_rounded,
                        isDark: isDark,
                      ),
                      const Divider(height: 1),
                      _buildPrayerTableRow(
                        context,
                        settings,
                        nameKey: 'Asar',
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
                        subNoteKey: 'Fixed',
                        time: timing.jummah,
                        lastUpdated: '',
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
        );
      },
    );
  }

  Widget _buildPrayerTableRow(
    BuildContext context,
    SettingsProvider settings, {
    required String nameKey,
    String? subNoteKey,
    required String time,
    required String lastUpdated,
    required IconData icon,
    required bool isDark,
    bool isLast = false,
  }) {
    final lang = settings.language;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF2D6A4F),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _t(settings, nameKey),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
                fontFamily: AppTheme.getFontForLanguage(context, lang),
              ),
            ),
          ),
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
              const SizedBox(height: 3),
              Text(
                subNoteKey != null
                    ? '(${_t(settings, subNoteKey)})'
                    : '${_t(settings, "Last Updated")}: \u200E${JamaatTiming.normalizeDate(lastUpdated)}\u200E',
                style: TextStyle(
                  fontSize: 10.5,
                  color: isDark ? Colors.white54 : Colors.grey[600],
                  fontFamily: AppTheme.getFontForLanguage(context, lang),
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.end,
              ),
            ],
          ),
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
        title: Text(
          _t(
            settings,
            'Masjid Jama\'at Times (Sukkur)',
            'مساجد باجماعت اوقات (سکھر)',
            'مسجدن جا باجماعت وقت (سکر)',
            'مواقيت الجماعة للمساجد (سَكَر)',
          ),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Main Header Card ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.access_time_filled_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _t(
                      settings,
                      'Masjid Jama\'at Times (Sukkur)',
                      'مساجد باجماعت اوقات (سکھر)',
                      'مسجدن جا باجماعت وقت (سکر)',
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
                    _t(
                      settings,
                      'Tap any Masjid below to view complete congregational (Jama\'at) prayer timings.',
                      'باجماعت نمازوں کے مکمل اوقات دیکھنے کے لیے ذیل میں کسی بھی مسجد پر ٹیپ کریں۔',
                      'باجماعت نمازن جا مڪمل وقت ڏسڻ لاءِ هيٺ ڏنل ڪنهن به مسجد تي ٽيپ ڪريو.',
                      'انقر على أي مسجد أعلاه لعرض مواقيت صلاة الجماعة الكاملة.',
                    ),
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

            const SizedBox(height: 24),

            // ── Dynamic Mosque List Bars ───────────────────────────────
            for (final masjid in JamaatTimesService.instance.getMasjidList())
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
          ],
        ),
      ),
    );
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.mosque_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t(settings, masjid.nameKey),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTheme.getFontForLanguage(context, lang),
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _t(settings, masjid.addressKey),
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
