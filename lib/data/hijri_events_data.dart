import 'package:flutter/material.dart';
import '../providers/settings_provider.dart';

class HijriEvent {
  final String id;
  final int month; // 1 to 12
  final int day;   // 1 to 30
  final String titleKey;
  final String descKey;
  final IconData icon;
  final String category; // 'eid', 'blessed_night', 'fasting', 'historical'

  const HijriEvent({
    required this.id,
    required this.month,
    required this.day,
    required this.titleKey,
    required this.descKey,
    required this.icon,
    required this.category,
  });

  String getTitle(SettingsProvider settings) {
    return settings.translate(titleKey, titleKey, titleKey, titleKey);
  }

  String getDescription(SettingsProvider settings) {
    return settings.translate(descKey, descKey, descKey, descKey);
  }
}

class HijriEventsData {
  static const List<HijriEvent> events = [
    // Muharram (1)
    HijriEvent(
      id: 'islamic_new_year',
      month: 1,
      day: 1,
      titleKey: 'Islamic New Year (1st Muharram)',
      descKey: 'Beginning of the Hijri New Year 1448 AH.',
      icon: Icons.calendar_month_rounded,
      category: 'historical',
    ),
    HijriEvent(
      id: 'ashura',
      month: 1,
      day: 10,
      titleKey: 'Yaum-e-Ashura (10th Muharram)',
      descKey: 'Day of Ashura - Recommended Sunnah fasting on 9th & 10th Muharram.',
      icon: Icons.favorite_rounded,
      category: 'fasting',
    ),

    // Rabi-ul-Awwal (3)
    HijriEvent(
      id: '12_rabi_ul_awwal',
      month: 3,
      day: 12,
      titleKey: '12 Rabi-ul-Awwal',
      descKey: 'Blessed birth anniversary of Prophet Muhammad ﷺ.',
      icon: Icons.auto_awesome_rounded,
      category: 'historical',
    ),

    // Rajab (7)
    HijriEvent(
      id: 'shab_e_meraj',
      month: 7,
      day: 27,
      titleKey: 'Shab-e-Meraj (27 Rajab)',
      descKey: 'The miraculous Ascension journey of Prophet Muhammad ﷺ.',
      icon: Icons.nights_stay_rounded,
      category: 'historical',
    ),

    // Sha'ban (8)
    HijriEvent(
      id: 'shab_e_barat',
      month: 8,
      day: 15,
      titleKey: 'Shab-e-Barat (15 Sha\'ban)',
      descKey: 'Night of Forgiveness & Salvation - Recommended night prayers and fasting.',
      icon: Icons.stars_rounded,
      category: 'blessed_night',
    ),

    // Ramzan (9)
    HijriEvent(
      id: 'ramzan_first',
      month: 9,
      day: 1,
      titleKey: '1st Ramzan-ul-Mubarak',
      descKey: 'Beginning of the Holy Month of Ramzan fasting.',
      icon: Icons.brightness_3_rounded,
      category: 'fasting',
    ),
    HijriEvent(
      id: 'laylatul_qadr',
      month: 9,
      day: 27,
      titleKey: 'Laylat al-Qadr (Night of Power)',
      descKey: 'Better than 1,000 months - Blessed odd night of Ramzan.',
      icon: Icons.light_mode_rounded,
      category: 'blessed_night',
    ),

    // Shawwal (10)
    HijriEvent(
      id: 'eid_ul_fitr',
      month: 10,
      day: 1,
      titleKey: 'Eid-ul-Fitr (1st Shawwal)',
      descKey: 'Blessed festival of Fitr after completing Ramzan.',
      icon: Icons.celebration_rounded,
      category: 'eid',
    ),

    // Dhul Hijjah (12)
    HijriEvent(
      id: 'day_of_arafah',
      month: 12,
      day: 9,
      titleKey: 'Day of Arafah (9 Dhul Hijjah)',
      descKey: 'The day of Hajj & recommended Sunnah fasting for non-pilgrims.',
      icon: Icons.landscape_rounded,
      category: 'fasting',
    ),
    HijriEvent(
      id: 'eid_ul_adha',
      month: 12,
      day: 10,
      titleKey: 'Eid-ul-Adha (10 Dhul Hijjah)',
      descKey: 'Festival of Sacrifice honoring Prophet Ibrahim (A.S).',
      icon: Icons.volunteer_activism_rounded,
      category: 'eid',
    ),
  ];

  static String getMonthName(int monthIndex1Based, SettingsProvider settings) {
    if (monthIndex1Based < 1 || monthIndex1Based > 12) return '';
    final key = _monthKeys[monthIndex1Based - 1];
    return settings.translate(key, key, key, key);
  }

  static const List<String> _monthKeys = [
    'Muharram', 'Safar', 'Rabi al-Awwal', 'Rabi al-Thani',
    'Jumada al-Awwal', 'Jumada al-Thani', 'Rajab', 'Sha\'ban',
    'Ramadan', 'Shawwal', 'Dhu al-Qi\'dah', 'Dhu al-Hijjah'
  ];
}
