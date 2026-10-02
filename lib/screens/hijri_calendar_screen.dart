import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/hijri_events_data.dart';
import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';
import '../utils/hijri_converter.dart';

class HijriCalendarScreen extends StatefulWidget {
  const HijriCalendarScreen({super.key});

  @override
  State<HijriCalendarScreen> createState() => _HijriCalendarScreenState();
}

class _HijriCalendarScreenState extends State<HijriCalendarScreen> {
  int? _selectedMonthFilter; // null = all months
  int? _selectedYear;

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = settings.language;

    // Get current Hijri Date from HijriConverter
    final hijriTodayResult = HijriConverter.getTodayResult(adjustment: settings.hijriAdjustment);
    final currentHijriYear = hijriTodayResult.hYear;
    final activeYear = _selectedYear ?? currentHijriYear;

    final hijriDate = HijriConverter.todayHijri(
      adjustment: settings.hijriAdjustment,
      language: lang,
    );
    const accent = Color(0xFFD4A574); // Warm Islamic Gold accent

    final filteredEvents = _selectedMonthFilter == null
        ? HijriEventsData.events
        : HijriEventsData.events
            .where((e) => e.month == _selectedMonthFilter)
            .toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121619) : const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: Text(
          settings.translate(
            'Islamic Hijri Events',
            'اسلامی ہجری تقویم و ایام',
            'اسلامي هجري تقويم ۽ ڏينهن',
            'التقويم والأحداث الهجرية',
          ),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: CustomScrollView(
        slivers: [
          // ── Current Hijri Header Card ─────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
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
                          .withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_month_rounded,
                            color: accent, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          settings.translate(
                            'Today in Hijri Calendar',
                            'آج ہجری تاریخ',
                            'اڄ هجري تاريخ',
                            'اليوم في التقويم الهجري',
                          ),
                          style: const TextStyle(
                            color: accent,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      hijriDate,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppTheme.getFontForLanguage(context, lang),
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      settings.translate(
                        'Tap any month below to view major blessed Islamic events & dates.',
                        'ذیل میں کسی بھی مہینے پر ٹیپ کر کے اسلامی ایام دیکھیں:',
                        'هيٺان ڪنهن به مهيني تي ٽيپ ڪري اسلامي ڏينهن ڏسو:',
                        'اضغط على أي شهر لعرض الأحداث الهجرية المباركة.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Hijri Year Selector Row ─────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [currentHijriYear - 1, currentHijriYear, currentHijriYear + 1].map((year) {
                  final isSelected = activeYear == year;
                  final label = '$year AH${year == currentHijriYear ? " (${settings.translate('Current', 'موجودہ', 'موجوده', 'الحالي')})" : ""}';
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF1B4332),
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedYear = year;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── Month Filter Horizontal List ─────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 46,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: 13, // 0 = All, 1-12 = Months
                itemBuilder: (context, index) {
                  final isAll = index == 0;
                  final isSelected = isAll
                      ? _selectedMonthFilter == null
                      : _selectedMonthFilter == index;
                  final monthName = isAll
                      ? settings.translate('All Events', 'تمام ایام', 'تمام ڏينهن', 'جميع الأحداث')
                      : HijriEventsData.getMonthName(index, settings);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(
                        monthName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF2D6A4F),
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedMonthFilter = isAll ? null : index;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Events List Cards ────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final event = filteredEvents[index];
                  final monthName =
                      HijriEventsData.getMonthName(event.month, settings);
                  final (catColor, catLabel) = _getCategoryBadge(event.category, settings);

                  final gDate = HijriConverter.gregorianForHijri(activeYear, event.month, event.day);
                  final formattedGDate = HijriConverter.formatGregorianDate(gDate, lang);
                  final hijriEventDateStr = HijriConverter.formatHijriEventDate(
                      event.day, event.month, activeYear, lang, monthName);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E2628)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  event.icon,
                                  color: catColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.getTitle(settings),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: AppTheme.getFontForLanguage(context, lang),
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.event,
                                              size: 14,
                                              color: isDark ? Colors.white54 : Colors.black54,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              hijriEventDateStr,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: accent,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: catColor.withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            catLabel,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: catColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today_rounded,
                                          size: 12,
                                          color: isDark ? Colors.white60 : Colors.black54,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            '${settings.translate('Gregorian', 'عیسوی', 'عيسوي', 'ميلادي')}: $formattedGDate',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: isDark ? Colors.white70 : Colors.black87,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Divider(
                            color: isDark ? Colors.white10 : Colors.black12,
                            height: 1,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            event.getDescription(settings),
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              fontFamily: AppTheme.getFontForLanguage(context, lang),
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: filteredEvents.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  (Color, String) _getCategoryBadge(String cat, SettingsProvider settings) {
    switch (cat) {
      case 'eid':
        return (
          const Color(0xFF388E3C),
          settings.translate('Eid Festival', 'عید الفطر/الاضحیٰ', 'عيد الفطر/الاضحيٰ', 'عيد')
        );
      case 'blessed_night':
        return (
          const Color(0xFF7B1FA2),
          settings.translate('Blessed Night', 'مبارک رات', 'مبارڪ رات', 'ليلة مباركة')
        );
      case 'fasting':
        return (
          const Color(0xFFE65100),
          settings.translate('Sunnah Fasting', 'مستحب روزہ', 'مستحب روزو', 'صيام مستحب')
        );
      default:
        return (
          const Color(0xFF1976D2),
          settings.translate('Historical Event', 'تاریخی واقعہ', 'تاريخي واقعو', 'حدث تاريخي')
        );
    }
  }
}
