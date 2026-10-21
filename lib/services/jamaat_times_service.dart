import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../data/timings_data.dart';

class JamaatTiming {
  final String fajr;
  final String fajrUpdated;
  final String fajrNoteUr;
  final String fajrNoteEn;
  final String zuhar;
  final String zuharUpdated;
  final String zuharNoteUr;
  final String zuharNoteEn;
  final String asar;
  final String asarUpdated;
  final String asarNoteUr;
  final String asarNoteEn;
  final String maghrib;
  final String maghribNoteUr;
  final String maghribNoteEn;
  final String isha;
  final String ishaUpdated;
  final String ishaNoteUr;
  final String ishaNoteEn;
  final String jummah;
  final String jummahUpdated;
  final String jummahNoteUr;
  final String jummahNoteEn;

  const JamaatTiming({
    required this.fajr,
    this.fajrUpdated = '',
    this.fajrNoteUr = '',
    this.fajrNoteEn = '',
    required this.zuhar,
    this.zuharUpdated = '',
    this.zuharNoteUr = '',
    this.zuharNoteEn = '',
    required this.asar,
    this.asarUpdated = '',
    this.asarNoteUr = '',
    this.asarNoteEn = '',
    required this.maghrib,
    this.maghribNoteUr = '',
    this.maghribNoteEn = '',
    required this.isha,
    this.ishaUpdated = '',
    this.ishaNoteUr = '',
    this.ishaNoteEn = '',
    required this.jummah,
    this.jummahUpdated = '',
    this.jummahNoteUr = '',
    this.jummahNoteEn = '',
  });

  String getNoteFor(String prayerKey, String language) {
    final key = prayerKey.toLowerCase();
    String ur = '';
    String en = '';
    switch (key) {
      case 'fajr':
      case 'fajar':
        ur = fajrNoteUr;
        en = fajrNoteEn;
        break;
      case 'zuhar':
      case 'zuhr':
        ur = zuharNoteUr;
        en = zuharNoteEn;
        break;
      case 'asar':
      case 'asr':
        ur = asarNoteUr;
        en = asarNoteEn;
        break;
      case 'maghrib':
        ur = maghribNoteUr;
        en = maghribNoteEn;
        break;
      case 'isha':
        ur = ishaNoteUr;
        en = ishaNoteEn;
        break;
      case 'jummah':
      case 'juma':
        ur = jummahNoteUr;
        en = jummahNoteEn;
        break;
    }
    if (language == 'english') {
      if (en.isNotEmpty) return en;
      if (ur.isNotEmpty) return ur;
    } else {
      if (ur.isNotEmpty) return ur;
      if (en.isNotEmpty) return en;
    }
    return '';
  }

  static String normalizeDate(String input) {
    final str = input.trim();
    if (str.isEmpty) return str;

    // YYYY-MM-DD
    final ymd = RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})$').firstMatch(str);
    if (ymd != null) {
      final year = ymd.group(1)!;
      final mIndex = int.tryParse(ymd.group(2)!) ?? 1;
      final day = ymd.group(3)!.padLeft(2, '0');
      const stdMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final mName = (mIndex >= 1 && mIndex <= 12) ? stdMonths[mIndex - 1] : 'Oct';
      return '$day $mName $year';
    }

    // DD-MM-YYYY
    final dmy = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})$').firstMatch(str);
    if (dmy != null) {
      final day = dmy.group(1)!.padLeft(2, '0');
      final mIndex = int.tryParse(dmy.group(2)!) ?? 1;
      final year = dmy.group(3)!;
      const stdMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final mName = (mIndex >= 1 && mIndex <= 12) ? stdMonths[mIndex - 1] : 'Oct';
      return '$day $mName $year';
    }

    // Month Day Year (e.g. Oct 04 2026 -> 04 Oct 2026)
    final mdy = RegExp(r'^([A-Za-z]+)\s+(\d{1,2})[,\s]+(\d{4})$').firstMatch(str);
    if (mdy != null) {
      final month = mdy.group(1)!;
      final day = mdy.group(2)!.padLeft(2, '0');
      final year = mdy.group(3)!;
      return '$day $month $year';
    }

    // Day Month Year (e.g. 4 Oct 2026 -> 04 Oct 2026)
    final dmyText = RegExp(r'^(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})$').firstMatch(str);
    if (dmyText != null) {
      final day = dmyText.group(1)!.padLeft(2, '0');
      final month = dmyText.group(2)!;
      final year = dmyText.group(3)!;
      return '$day $month $year';
    }

    return str;
  }

  static String _cleanPrayerTime(dynamic val, {String fallback = ''}) {
    if (val == null) return fallback;
    final s = val.toString().trim();
    if (s.isEmpty || s == '-' || s.toLowerCase() == 'off' || s.toLowerCase() == 'null' || s == '--:--') {
      return '';
    }
    return s;
  }

  factory JamaatTiming.fromJson(Map<String, dynamic> json) {
    final rawDefault = json['last_updated'] ?? json['lastUpdated'];
    final defaultDate = rawDefault != null ? normalizeDate(rawDefault.toString()) : '';

    String parseUpdated(String fieldKey, String altKey) {
      if (json[fieldKey] != null && json[fieldKey].toString().trim().isNotEmpty) {
        return normalizeDate(json[fieldKey].toString());
      }
      if (json[altKey] != null && json[altKey].toString().trim().isNotEmpty) {
        return normalizeDate(json[altKey].toString());
      }
      return defaultDate;
    }

    final fajrVal = _cleanPrayerTime(json['fajr']);
    final zuharVal = _cleanPrayerTime(json['zuhar']);
    final asarVal = _cleanPrayerTime(json['asar']);
    final maghribVal = _cleanPrayerTime(json['maghrib'], fallback: 'Sunset');
    final ishaVal = _cleanPrayerTime(json['isha']);
    final jummahVal = _cleanPrayerTime(json['jummah']);

    return JamaatTiming(
      fajr: fajrVal,
      fajrUpdated: fajrVal.isNotEmpty ? parseUpdated('fajr_updated', 'fajrUpdated') : '',
      fajrNoteUr: json['fajr_note_ur']?.toString() ?? json['fajrNoteUr']?.toString() ?? json['fajr_note']?.toString() ?? '',
      fajrNoteEn: json['fajr_note_en']?.toString() ?? json['fajrNoteEn']?.toString() ?? '',
      zuhar: zuharVal,
      zuharUpdated: zuharVal.isNotEmpty ? parseUpdated('zuhar_updated', 'zuharUpdated') : '',
      zuharNoteUr: json['zuhar_note_ur']?.toString() ?? json['zuharNoteUr']?.toString() ?? json['zuhar_note']?.toString() ?? '',
      zuharNoteEn: json['zuhar_note_en']?.toString() ?? json['zuharNoteEn']?.toString() ?? '',
      asar: asarVal,
      asarUpdated: asarVal.isNotEmpty ? parseUpdated('asar_updated', 'asarUpdated') : '',
      asarNoteUr: json['asar_note_ur']?.toString() ?? json['asarNoteUr']?.toString() ?? json['asar_note']?.toString() ?? '',
      asarNoteEn: json['asar_note_en']?.toString() ?? json['asarNoteEn']?.toString() ?? '',
      maghrib: maghribVal.isNotEmpty ? maghribVal : 'Sunset',
      maghribNoteUr: json['maghrib_note_ur']?.toString() ?? json['maghribNoteUr']?.toString() ?? json['maghrib_note']?.toString() ?? '',
      maghribNoteEn: json['maghrib_note_en']?.toString() ?? json['maghribNoteEn']?.toString() ?? '',
      isha: ishaVal,
      ishaUpdated: ishaVal.isNotEmpty ? parseUpdated('isha_updated', 'ishaUpdated') : '',
      ishaNoteUr: json['isha_note_ur']?.toString() ?? json['ishaNoteUr']?.toString() ?? json['isha_note']?.toString() ?? '',
      ishaNoteEn: json['isha_note_en']?.toString() ?? json['ishaNoteEn']?.toString() ?? '',
      jummah: jummahVal,
      jummahUpdated: jummahVal.isNotEmpty ? parseUpdated('jummah_updated', 'jummahUpdated') : '',
      jummahNoteUr: json['jummah_note_ur']?.toString() ?? json['jummahNoteUr']?.toString() ?? json['jummah_note']?.toString() ?? '',
      jummahNoteEn: json['jummah_note_en']?.toString() ?? json['jummahNoteEn']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'fajr': fajr,
        'fajr_updated': fajrUpdated,
        'zuhar': zuhar,
        if (zuharUpdated.isNotEmpty) 'zuhar_updated': zuharUpdated,
        'asar': asar,
        'asar_updated': asarUpdated,
        'maghrib': maghrib,
        if (maghribNoteUr.isNotEmpty) 'maghrib_note_ur': maghribNoteUr,
        if (maghribNoteEn.isNotEmpty) 'maghrib_note_en': maghribNoteEn,
        'isha': isha,
        'isha_updated': ishaUpdated,
        'jummah': jummah,
        if (jummahUpdated.isNotEmpty) 'jummah_updated': jummahUpdated,
      };
}

class PrayerMergeResult {
  final String time;
  final String updated;
  final String noteUr;
  final String noteEn;

  const PrayerMergeResult({
    required this.time,
    required this.updated,
    required this.noteUr,
    required this.noteEn,
  });
}

class JamaatMasjidInfo {
  final String id;
  final String nameKey;
  final String addressKey;
  final JamaatTiming defaultTimings;
  final bool isHidden;
  final Map<String, String> localizedNames;
  final Map<String, String> localizedAddresses;
  final String? pin;

  const JamaatMasjidInfo({
    required this.id,
    required this.nameKey,
    required this.addressKey,
    required this.defaultTimings,
    this.isHidden = false,
    this.localizedNames = const {},
    this.localizedAddresses = const {},
    this.pin,
  });

  String getNameFor(String language) {
    final lang = language.toLowerCase();
    if (localizedNames.containsKey(lang) && localizedNames[lang]!.isNotEmpty) {
      return localizedNames[lang]!;
    }
    if (lang == 'sindhi' || lang == 'arabic') {
      if (localizedNames.containsKey('urdu') && localizedNames['urdu']!.isNotEmpty) {
        return localizedNames['urdu']!;
      }
    }
    return nameKey;
  }

  String getAddressFor(String language) {
    final lang = language.toLowerCase();
    if (localizedAddresses.containsKey(lang) && localizedAddresses[lang]!.isNotEmpty) {
      return localizedAddresses[lang]!;
    }
    if (lang == 'sindhi' || lang == 'arabic') {
      if (localizedAddresses.containsKey('urdu') && localizedAddresses['urdu']!.isNotEmpty) {
        return localizedAddresses['urdu']!;
      }
    }
    return addressKey;
  }
}

class JamaatTimesService {
  static final JamaatTimesService instance = JamaatTimesService._();
  JamaatTimesService._();

  // Pre-configured Sukkur masjids list
  static const List<JamaatMasjidInfo> sukkurMasjids = [
    JamaatMasjidInfo(
      id: 'babul_islam',
      nameKey: 'Masjid Babul Islam',
      addressKey: 'Anaj Bazar Sukkur',
      defaultTimings: JamaatTiming(
        fajr: '05:15 AM',
        fajrUpdated: '04 Oct 2026',
        zuhar: '01:15 PM',
        asar: '04:45 PM',
        asarUpdated: '04 Oct 2026',
        maghrib: '06:15 PM',
        isha: '08:00 PM',
        ishaUpdated: '04 Oct 2026',
        jummah: '01:15 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'ahmed_thanvi',
      nameKey: 'Masjid Molana Muhammad Ahmed Thanvi',
      addressKey: "Queen's Road Sukkur",
      defaultTimings: JamaatTiming(
        fajr: '05:15 AM',
        fajrUpdated: '04 Oct 2026',
        zuhar: '01:15 PM',
        asar: '04:45 PM',
        asarUpdated: '04 Oct 2026',
        maghrib: '06:15 PM',
        isha: '08:15 PM',
        ishaUpdated: '04 Oct 2026',
        jummah: '01:15 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'noor_masjid',
      nameKey: 'Noor Masjid',
      addressKey: 'Miani Road Sukkur',
      defaultTimings: JamaatTiming(
        fajr: '05:15 AM',
        fajrUpdated: '04 Oct 2026',
        zuhar: '01:15 PM',
        asar: '04:45 PM',
        asarUpdated: '04 Oct 2026',
        maghrib: '06:15 PM',
        isha: '08:00 PM',
        ishaUpdated: '04 Oct 2026',
        jummah: '01:15 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'madni_masjid',
      nameKey: 'Madni Masjid',
      addressKey: 'Shahi Bazar Sukkur',
      defaultTimings: JamaatTiming(
        fajr: '05:15 AM',
        fajrUpdated: '04 Oct 2026',
        zuhar: '01:15 PM',
        asar: '04:45 PM',
        asarUpdated: '04 Oct 2026',
        maghrib: '06:15 PM',
        isha: '08:00 PM',
        ishaUpdated: '04 Oct 2026',
        jummah: '01:15 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'masjid_darul_islam',
      nameKey: 'Masjid Darul Islam',
      addressKey: "Upper Queen's Road Sukkur",
      defaultTimings: JamaatTiming(
        fajr: '05:15 AM',
        fajrUpdated: '04 Oct 2026',
        zuhar: '01:15 PM',
        asar: '04:45 PM',
        asarUpdated: '04 Oct 2026',
        maghrib: '06:15 PM',
        isha: '08:00 PM',
        ishaUpdated: '04 Oct 2026',
        jummah: '01:15 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'noorani_masjid',
      nameKey: 'Noorani Masjid',
      addressKey: 'Katti Bazar Sukkur',
      defaultTimings: JamaatTiming(
        fajr: '05:15 AM',
        fajrUpdated: '04 Oct 2026',
        zuhar: '01:15 PM',
        asar: '04:45 PM',
        asarUpdated: '04 Oct 2026',
        maghrib: '06:15 PM',
        isha: '08:00 PM',
        ishaUpdated: '04 Oct 2026',
        jummah: '01:15 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'masjid_jamia_ashrafia',
      nameKey: 'Masjid Jamia Ashrafia',
      addressKey: 'Wallace Road Sukkur',
      defaultTimings: JamaatTiming(
        fajr: '05:15 AM',
        fajrUpdated: '04 Oct 2026',
        zuhar: '01:15 PM',
        asar: '04:45 PM',
        asarUpdated: '04 Oct 2026',
        maghrib: '06:15 PM',
        isha: '08:00 PM',
        ishaUpdated: '04 Oct 2026',
        jummah: '01:15 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'jamia_masjid',
      nameKey: 'Jamia Masjid',
      addressKey: 'Bunder Road Sukkur',
      defaultTimings: JamaatTiming(
        fajr: '05:15 AM',
        fajrUpdated: '04 Oct 2026',
        zuhar: '01:15 PM',
        asar: '04:45 PM',
        asarUpdated: '04 Oct 2026',
        maghrib: '06:15 PM',
        isha: '08:00 PM',
        ishaUpdated: '04 Oct 2026',
        jummah: '01:15 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'allah_wali_masjid',
      nameKey: 'Allah Wali Masjid',
      addressKey: 'Bunder Road Sukkur',
      defaultTimings: JamaatTiming(
        fajr: '05:15 AM',
        fajrUpdated: '04 Oct 2026',
        zuhar: '01:15 PM',
        asar: '04:45 PM',
        asarUpdated: '04 Oct 2026',
        maghrib: '06:15 PM',
        isha: '08:00 PM',
        ishaUpdated: '04 Oct 2026',
        jummah: '01:15 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'makki_masjid',
      nameKey: 'Makki Masjid',
      addressKey: 'Minara Road Sukkur',
      defaultTimings: JamaatTiming(
        fajr: '05:15 AM',
        fajrUpdated: '04 Oct 2026',
        zuhar: '01:15 PM',
        asar: '04:45 PM',
        asarUpdated: '04 Oct 2026',
        maghrib: '06:15 PM',
        isha: '08:00 PM',
        ishaUpdated: '04 Oct 2026',
        jummah: '01:15 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'gol_masjid',
      nameKey: 'Gol Masjid',
      addressKey: 'Barrage Road Sukkur',
      defaultTimings: JamaatTiming(
        fajr: '05:15 AM',
        fajrUpdated: '04 Oct 2026',
        zuhar: '01:15 PM',
        asar: '04:45 PM',
        asarUpdated: '04 Oct 2026',
        maghrib: '06:15 PM',
        isha: '08:00 PM',
        ishaUpdated: '04 Oct 2026',
        jummah: '01:15 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'masjid_manzilgah',
      nameKey: 'Masjid Manzilgah',
      addressKey: 'Bunder Road Sukkur',
      defaultTimings: JamaatTiming(
        fajr: '05:15 AM',
        fajrUpdated: '04 Oct 2026',
        zuhar: '01:15 PM',
        asar: '04:45 PM',
        asarUpdated: '04 Oct 2026',
        maghrib: '06:15 PM',
        isha: '08:00 PM',
        ishaUpdated: '04 Oct 2026',
        jummah: '01:15 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'masjid_ayesha',
      nameKey: 'Masjid Ayesha',
      addressKey: 'Chanchar Ghitti, Shahi Bazar Sukkur',
      defaultTimings: JamaatTiming(
        fajr: '05:15 AM',
        fajrUpdated: '04 Oct 2026',
        zuhar: '01:15 PM',
        asar: '04:45 PM',
        asarUpdated: '04 Oct 2026',
        maghrib: '06:15 PM',
        isha: '08:00 PM',
        ishaUpdated: '04 Oct 2026',
        jummah: '01:15 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'shamsi_masjid',
      nameKey: 'Shamsi Masjid',
      addressKey: 'Frere Road Sukkur',
      defaultTimings: JamaatTiming(
        fajr: '05:15 AM',
        fajrUpdated: '04 Oct 2026',
        zuhar: '01:15 PM',
        asar: '04:45 PM',
        asarUpdated: '04 Oct 2026',
        maghrib: '06:15 PM',
        isha: '08:00 PM',
        ishaUpdated: '04 Oct 2026',
        jummah: '01:15 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'safed_masjid',
      nameKey: 'Safed Masjid',
      addressKey: 'Husaini Road Sukkur',
      defaultTimings: JamaatTiming(
        fajr: '05:15 AM',
        fajrUpdated: '04 Oct 2026',
        zuhar: '01:15 PM',
        asar: '04:45 PM',
        asarUpdated: '04 Oct 2026',
        maghrib: '06:15 PM',
        isha: '08:00 PM',
        ishaUpdated: '04 Oct 2026',
        jummah: '01:15 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'masjid_al_farooq',
      nameKey: 'Masjid Al Farooq',
      addressKey: 'Barrage Road, Ghanta Ghar Sukkur',
      defaultTimings: JamaatTiming(
        fajr: '05:15 AM',
        fajrUpdated: '04 Oct 2026',
        zuhar: '01:15 PM',
        asar: '04:45 PM',
        asarUpdated: '04 Oct 2026',
        maghrib: '06:15 PM',
        isha: '08:00 PM',
        ishaUpdated: '04 Oct 2026',
        jummah: '01:15 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'makrani_masjid',
      nameKey: 'Makrani Masjid',
      addressKey: 'Bunder Road Sukkur',
      defaultTimings: JamaatTiming(
        fajr: '',
        fajrUpdated: '',
        zuhar: '01:30 PM',
        zuharUpdated: '21 Oct 2026',
        asar: '',
        asarUpdated: '',
        maghrib: 'Sunset',
        isha: '',
        ishaUpdated: '',
        jummah: '01:30 PM',
        jummahUpdated: '21 Oct 2026',
      ),
    ),
    JamaatMasjidInfo(
      id: 'masjid_dr_hafeezullah',
      nameKey: 'Masjid Hazrat Dr Hafeezullah Sahib Rahimahullah',
      addressKey: 'Professor Society, Kheer Thar Canal Road, near Darul Uloom Sukkur',
      defaultTimings: JamaatTiming(
        fajr: '05:15 AM',
        fajrUpdated: '14 Oct 2026',
        zuhar: '01:15 PM',
        asar: '04:45 PM',
        asarUpdated: '14 Oct 2026',
        maghrib: 'Sunset',
        isha: '08:00 PM',
        ishaUpdated: '14 Oct 2026',
        jummah: '01:15 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'shahi_jamia_masjid',
      nameKey: 'Shahi Jamia Masjid',
      addressKey: 'Purana Sukkur',
      localizedNames: {
        'urdu': 'شاہی جامع مسجد',
        'sindhi': 'شاهي جامع مسجد',
        'arabic': 'مسجد شاهي جامع',
        'hindi': 'शाही जामिया मस्जिद',
        'bengali': 'শাহী জামিয়া মসজিদ',
        'persian': 'مسجد شاهی جامع',
        'turkish': 'Şahi Camii',
        'french': 'Mosquée Shahi Jamia',
        'indonesian': 'Masjid Shahi Jamia',
      },
      localizedAddresses: {
        'urdu': 'پرانا سکھر',
        'sindhi': 'پراڻو سکر',
        'arabic': 'سَكَر القديمة',
        'hindi': 'पुराना सुक्कुर',
        'bengali': 'পুরানো সুক্কুর',
        'persian': 'سکر قدیم',
        'turkish': 'Eski Sukkur',
        'french': 'Vieux Sukkur',
        'indonesian': 'Sukkur Lama',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:00 AM',
        fajrUpdated: '15 Oct 2026',
        zuhar: '01:30 PM',
        asar: '04:45 PM',
        asarUpdated: '15 Oct 2026',
        maghrib: 'Sunset',
        isha: '08:00 PM',
        ishaUpdated: '15 Oct 2026',
        jummah: '02:00 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'jamia_masjid_bait_ul_hamd',
      nameKey: 'Jamia Masjid Bait ul Hamd',
      addressKey: 'Green City near NICVD Hospital Sukkur',
      localizedNames: {
        'urdu': 'جامع مسجد بیت الحمد',
        'sindhi': 'جامع مسجد بيت الحمد',
        'arabic': 'جامع مسجد بيت الحمد',
        'hindi': 'जामिया मस्जिद बैत-उल-हम्द',
        'bengali': 'জামিয়া মসজিদ বাইতুল হামদ',
        'persian': 'جامع مسجد بیت الحمد',
        'turkish': 'Beyt-ül Hamd Camii',
        'french': 'Grande Mosquée Bait-ul-Hamd',
        'indonesian': 'Masjid Agung Baitul Hamd',
      },
      localizedAddresses: {
        'urdu': 'گرین سٹی، نزد این آئی سی وی ڈی ہسپتال سکھر',
        'sindhi': 'گرين سٽي، ويجهو اين آءِ سي وي ڊي اسپتال سکر',
        'arabic': 'جرين سيتي، بالقرب من مستشفى NICVD، سَكَر',
        'hindi': 'ग्रीन सिटी, एनआईसीवीडी अस्पताल के पास, सुक्कुर',
        'bengali': 'গ্রিন সিটি, এনআইসিভিডি হাসপাতালের কাছে, সুক্কুর',
        'persian': 'گرین سیتی، نزدیک شفاخانه NICVD، سکر',
        'turkish': 'Green City, NICVD Hastanesi Yakını, Sukkur',
        'french': 'Green City, près de l\'hôpital NICVD, Sukkur',
        'indonesian': 'Green City, dekat Rumah Sakit NICVD, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '05:15 AM',
        fajrUpdated: '16 Oct 2026',
        zuhar: '01:15 PM',
        asar: '04:45 PM',
        asarUpdated: '16 Oct 2026',
        maghrib: 'Sunset',
        isha: '08:00 PM',
        ishaUpdated: '16 Oct 2026',
        jummah: '01:15 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'qadeemi_jamia_masjid_hazrat_imam_zain_ul_abidin',
      nameKey: 'Qadeemi Jamia Masjid Hazrat Imam Zain ul Abidin',
      addressKey: 'Bhusa Line Chowk, Sukkur',
      localizedNames: {
        'urdu': 'قدیمی جامع مسجد حضرت امام زین العابدین',
        'sindhi': 'قديمي جامع مسجد حضرت امام زين العابدين',
        'arabic': 'المسجد الجامع القديم لحضرة الإمام زين العابدين',
        'hindi': 'हज़रत इमाम ज़ैनुल आबिदीन की प्राचीन जामा मस्जिद',
        'bengali': 'হযরত ইমাম জয়নুল আবেদীনের প্রাচীন জামে মসজিদ',
        'persian': 'مسجد جامع قدیمی حضرت امام زین‌العابدین',
        'turkish': 'Hazreti İmam Zeynelâbidîn Eski Ulu Camii',
        'french': 'Ancienne Grande Mosquée Hazrat Imam Zain ul Abidin',
        'indonesian': 'Masjid Jami Kuno Hazrat Imam Zainul Abidin',
      },
      localizedAddresses: {
        'urdu': 'بھوسہ لائن چوک، سکھر',
        'sindhi': 'ڀوسا لائين چوڪ، سکر',
        'arabic': 'بوسا لاين تشوك، سُكّر',
        'hindi': 'भूसा लाइन चौक, सुक्कुर',
        'bengali': 'ভুসা লাইন চক, সুক্কুর',
        'persian': 'بھوسا لاین چوک، سکر',
        'turkish': 'Bhusa Line Kavşağı, Sukkur',
        'french': 'Bhusa Line Chowk, Sukkur',
        'indonesian': 'Bhusa Line Chowk, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:05 AM',
        fajrUpdated: '18 Oct 2026',
        zuhar: '02:00 PM',
        asar: '04:45 PM',
        asarUpdated: '18 Oct 2026',
        maghrib: 'Sunset',
        isha: '07:45 PM',
        ishaUpdated: '18 Oct 2026',
        jummah: '01:00 PM',
      ),
    ),
  ];

  final Map<String, JamaatTiming> _remoteCache = {};
  List<JamaatMasjidInfo> _dynamicMasjids = [];
  String _masterAdminPin = '25081989';
  final Map<String, String> _masjidPins = {};

  bool verifyMasjidPin(String masjidId, String inputPin) {
    final pin = inputPin.trim();
    if (pin.isEmpty) return false;

    // 1. Master admin PIN from remote JSON
    if (_masterAdminPin.isNotEmpty && pin == _masterAdminPin) {
      return true;
    }

    // 2. Masjid-specific PIN from remote JSON or Firestore
    final assigned = _masjidPins[masjidId];
    if (assigned != null && assigned.isNotEmpty) {
      return pin == assigned;
    }

    // 3. Masjid-specific PIN from local code definition
    final local = sukkurMasjids.firstWhere(
      (m) => m.id == masjidId,
      orElse: () => const JamaatMasjidInfo(
        id: '',
        nameKey: '',
        addressKey: '',
        defaultTimings: JamaatTiming(
          fajr: '',
          fajrUpdated: '',
          zuhar: '',
          asar: '',
          asarUpdated: '',
          maghrib: '',
          isha: '',
          ishaUpdated: '',
          jummah: '',
        ),
      ),
    );
    if (local.pin != null && local.pin!.isNotEmpty) {
      return pin == local.pin;
    }

    // No PIN configured for this masjid -> strictly locked!
    return false;
  }

  static Future<SharedPreferences> _getPrefs() async => await SharedPreferences.getInstance();

  /// Optional Gist URL for live updates from GitHub Gist
  String _gistRawUrl =
      'https://gist.githubusercontent.com/safikaleem/2afecaa5e4b86ab5227ee00a7416646a/raw/jamaat_times.json';

  void setGistUrl(String url) {
    _gistRawUrl = url;
  }

  /// Returns active list of masjids (merging local built-in list with any remote Gist additions/updates/deletions)
  List<JamaatMasjidInfo> getMasjidList() {
    final List<JamaatMasjidInfo> list = List.from(sukkurMasjids);
    for (final remote in _dynamicMasjids) {
      final index = list.indexWhere((m) => m.id == remote.id);
      if (remote.isHidden) {
        if (index >= 0) {
          list.removeAt(index);
        }
      } else {
        if (index >= 0) {
          final local = list[index];
          list[index] = JamaatMasjidInfo(
            id: remote.id,
            nameKey: remote.nameKey.isNotEmpty ? remote.nameKey : local.nameKey,
            addressKey: remote.addressKey.isNotEmpty ? remote.addressKey : local.addressKey,
            defaultTimings: remote.defaultTimings,
            isHidden: false,
            localizedNames: remote.localizedNames.isNotEmpty ? remote.localizedNames : local.localizedNames,
            localizedAddresses: remote.localizedAddresses.isNotEmpty ? remote.localizedAddresses : local.localizedAddresses,
            pin: remote.pin ?? _masjidPins[remote.id] ?? local.pin,
          );
        } else {
          list.add(remote);
        }
      }
    }
    return list.where((m) => !m.isHidden).toList();
  }

  /// Helper to convert time string into English 12-hour format with AM/PM & padded hours
  static String format12HourEnglish(String timeStr, {bool defaultPm = false}) {
    try {
      final clean = timeStr.trim();
      final isPM = clean.contains('PM');
      final isAM = clean.contains('AM');
      final digits = clean.replaceAll('AM', '').replaceAll('PM', '').trim();
      final parts = digits.split(':');
      if (parts.length >= 2) {
        int h = int.parse(parts[0]);
        int m = int.parse(parts[1]);
        String period = (isPM || (!isAM && (h >= 12 || defaultPm))) ? 'PM' : 'AM';
        if (h > 12) h -= 12;
        if (h == 0) h = 12;
        String hStr = h.toString().padLeft(2, '0');
        String mStr = m.toString().padLeft(2, '0');
        return '$hStr:$mStr $period';
      }
    } catch (_) {}
    return timeStr;
  }

  /// Returns live or default timing for a masjid by ID
  JamaatTiming getTimingFor(JamaatMasjidInfo info) {
    // 1. Fetch base timings from remote cache or fallback defaults
    final base = _remoteCache.containsKey(info.id)
        ? _remoteCache[info.id]!
        : info.defaultTimings;

    // 2. Fetch today's Maghrib time dynamically from Sukkur Jantri if base.maghrib is empty, "Sunset", or default
    String dynamicMaghrib = base.maghrib;
    if (dynamicMaghrib.isEmpty ||
        dynamicMaghrib.toLowerCase().contains('sunset') ||
        dynamicMaghrib == info.defaultTimings.maghrib) {
      final today = TimingsData.instance.timingFor(DateTime.now());
      if (today != null) {
        String baseTime = today.maghrib;
        final match = RegExp(r'\+\s*(\d+)').firstMatch(dynamicMaghrib);
        if (match != null) {
          final offsetMins = int.tryParse(match.group(1)!) ?? 0;
          try {
            final clean = baseTime.replaceAll('PM', '').replaceAll('AM', '').trim();
            final parts = clean.split(':');
            int h = int.parse(parts[0]);
            int m = int.parse(parts[1]);
            if (h < 12) h += 12;
            final dt = DateTime(2026, 1, 1, h, m).add(Duration(minutes: offsetMins));
            int outH = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
            String hStr = outH.toString().padLeft(2, '0');
            String mStr = dt.minute.toString().padLeft(2, '0');
            dynamicMaghrib = '$hStr:$mStr PM';
          } catch (_) {
            dynamicMaghrib = format12HourEnglish(baseTime, defaultPm: true);
          }
        } else {
          dynamicMaghrib = format12HourEnglish(baseTime, defaultPm: true);
        }
      } else {
        dynamicMaghrib = format12HourEnglish(base.maghrib, defaultPm: true);
      }
    } else {
      dynamicMaghrib = format12HourEnglish(dynamicMaghrib, defaultPm: true);
    }

    return JamaatTiming(
      fajr: format12HourEnglish(base.fajr),
      fajrUpdated: base.fajrUpdated,
      fajrNoteUr: base.fajrNoteUr,
      fajrNoteEn: base.fajrNoteEn,
      zuhar: format12HourEnglish(base.zuhar, defaultPm: true),
      zuharUpdated: base.zuharUpdated,
      zuharNoteUr: base.zuharNoteUr,
      zuharNoteEn: base.zuharNoteEn,
      asar: format12HourEnglish(base.asar, defaultPm: true),
      asarUpdated: base.asarUpdated,
      asarNoteUr: base.asarNoteUr,
      asarNoteEn: base.asarNoteEn,
      maghrib: dynamicMaghrib,
      maghribNoteUr: base.maghribNoteUr,
      maghribNoteEn: base.maghribNoteEn,
      isha: format12HourEnglish(base.isha, defaultPm: true),
      ishaUpdated: base.ishaUpdated,
      ishaNoteUr: base.ishaNoteUr,
      ishaNoteEn: base.ishaNoteEn,
      jummah: format12HourEnglish(base.jummah, defaultPm: true),
      jummahUpdated: base.jummahUpdated,
      jummahNoteUr: base.jummahNoteUr,
      jummahNoteEn: base.jummahNoteEn,
    );
  }

  static const String prefKeyJamaatCache = 'cached_jamaat_times_json';

  /// Loads cached timings from SharedPreferences so updated times are available
  /// immediately even if the device is offline or on slow network.
  Future<void> loadLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(prefKeyJamaatCache);
      if (cached != null && cached.isNotEmpty) {
        _parseAndApplyJson(cached);
      }
    } catch (e) {
      debugPrint('Failed to load local cached Jamaat times: $e');
    }
  }

  static Map<String, String> _extractLocalizedStrings(Map<String, dynamic> item, String baseKey) {
    final Map<String, String> result = {};

    // 1. Check nested maps (e.g. item['names'] or item['addresses'])
    final pluralKey = baseKey == 'name' ? 'names' : '${baseKey}es';
    if (item[pluralKey] is Map) {
      final map = item[pluralKey] as Map;
      map.forEach((k, v) {
        if (v != null && v.toString().trim().isNotEmpty) {
          result[k.toString().toLowerCase()] = v.toString().trim();
        }
      });
    }

    // 2. Check flat keys (e.g. name_ur, name_urdu, name_sd, etc.)
    const langKeyMappings = {
      'urdu': ['urdu', 'ur'],
      'sindhi': ['sindhi', 'sd'],
      'arabic': ['arabic', 'ar'],
      'hindi': ['hindi', 'hi'],
      'bengali': ['bengali', 'bn'],
      'persian': ['persian', 'fa'],
      'turkish': ['turkish', 'tr'],
      'french': ['french', 'fr'],
      'indonesian': ['indonesian', 'id'],
      'english': ['english', 'en'],
    };

    for (final entry in langKeyMappings.entries) {
      final langName = entry.key;
      for (final suffix in entry.value) {
        final key = '${baseKey}_$suffix';
        if (item[key] != null && item[key].toString().trim().isNotEmpty) {
          result[langName] = item[key].toString().trim();
          break;
        }
      }
    }

    return result;
  }

  bool _parseAndApplyJson(String jsonStr) {
    try {
      final data = json.decode(jsonStr);
      if (data is Map<String, dynamic> && data.containsKey('masjids')) {
        if (data['master_pin'] != null && data['master_pin'].toString().trim().isNotEmpty) {
          _masterAdminPin = data['master_pin'].toString().trim();
        }
        final masjids = data['masjids'] as List;
        final List<JamaatMasjidInfo> fetchedList = [];
        for (final item in masjids) {
          if (item is Map<String, dynamic> && item.containsKey('id')) {
            final id = item['id'].toString();
            final pin = item['pin']?.toString().trim();
            if (pin != null && pin.isNotEmpty) {
              _masjidPins[id] = pin;
            }
            final name = item['name'] ?? item['nameKey'] ?? id;
            final address = item['address'] ?? item['addressKey'] ?? 'Sukkur';
            final isHidden = item['hidden'] == true || item['enabled'] == false || item['removed'] == true;
            final timing = JamaatTiming.fromJson(item);
            final localizedNames = _extractLocalizedStrings(item, 'name');
            final localizedAddresses = _extractLocalizedStrings(item, 'address');

            // Gist is the authoritative baseline for all masjids & prayer times
            _remoteCache[id] = timing;
            fetchedList.add(JamaatMasjidInfo(
              id: id,
              nameKey: name,
              addressKey: address,
              defaultTimings: timing,
              isHidden: isHidden,
              localizedNames: localizedNames,
              localizedAddresses: localizedAddresses,
              pin: pin,
            ));
          }
        }
        if (fetchedList.isNotEmpty) {
          _dynamicMasjids = fetchedList;
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error parsing Jamaat JSON: $e');
    }
    return false;
  }

  /// Fetches updated timings from GitHub Gist immediately with cache-busting
  /// headers and query parameters to bypass CDN/ISP caches.
  static DateTime? _parseDate(String? str) {
    if (str == null || str.trim().isEmpty) return null;
    final s = str.trim();
    try {
      return DateTime.parse(s);
    } catch (_) {}
    final parts = s.split(RegExp(r'\s+'));
    if (parts.length >= 3) {
      final day = int.tryParse(parts[0]);
      final mStr = parts[1].toLowerCase();
      final year = int.tryParse(parts[2]);
      const months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
      final mIndex = months.indexOf(mStr.length >= 3 ? mStr.substring(0, 3) : mStr);
      if (day != null && year != null && mIndex != -1) {
        return DateTime(year, mIndex + 1, day);
      }
    }
    return null;
  }

  static int _compareCalendarDays(DateTime a, DateTime b) {
    final dayA = DateTime(a.year, a.month, a.day);
    final dayB = DateTime(b.year, b.month, b.day);
    return dayA.compareTo(dayB);
  }

  static int _compareDatesWithPrecedence({
    required DateTime? dateA, // incoming
    required DateTime? dateB, // current
    required bool isAFirestore,
  }) {
    if (dateA == null && dateB == null) {
      return isAFirestore ? 1 : 0;
    }
    if (dateA != null && dateB == null) return 1;
    if (dateA == null && dateB != null) return -1;

    final dayDiff = _compareCalendarDays(dateA!, dateB!);
    if (dayDiff != 0) return dayDiff;

    // Both dates are on the SAME CALENDAR DAY:
    // User requirement: "favour the app/firestore"
    if (isAFirestore) {
      return 1; // incoming is Firestore (app update), so incoming wins!
    } else {
      return -1; // incoming is Gist, so current (app/firestore) wins!
    }
  }

  static JamaatTiming mergePrayerByPrayer({
    required JamaatTiming current,
    required JamaatTiming incoming,
    required bool isIncomingFirestore,
  }) {
    PrayerMergeResult mergeSingle({
      required String currTime,
      required String currUpdated,
      required String currNoteUr,
      required String currNoteEn,
      required String incTime,
      required String incUpdated,
      required String incNoteUr,
      required String incNoteEn,
      required bool isMaghrib,
    }) {
      final cleanCurr = currTime.trim();
      final cleanInc = incTime.trim();

      // If incoming is explicitly 'off'
      if (cleanInc.toLowerCase() == 'off') {
        return PrayerMergeResult(
          time: isMaghrib ? 'Sunset' : '',
          updated: incUpdated,
          noteUr: incNoteUr,
          noteEn: incNoteEn,
        );
      }

      // If incoming has no time specified (empty / omitted)
      if (cleanInc.isEmpty || cleanInc == '-') {
        if (!isIncomingFirestore) {
          // Incoming is Gist: Gist explicitly says this prayer is empty / not set.
          final currDt = _parseDate(currUpdated);
          final incDt = _parseDate(incUpdated);
          // If current has a verified committee update from the app with a strictly newer date than Gist, keep committee update
          if (currDt != null && incDt != null && _compareCalendarDays(currDt, incDt) > 0) {
            return PrayerMergeResult(
              time: cleanCurr,
              updated: currUpdated,
              noteUr: currNoteUr,
              noteEn: currNoteEn,
            );
          }
          // Otherwise, Gist's empty / unset time wins!
          return PrayerMergeResult(
            time: isMaghrib ? 'Sunset' : '',
            updated: incUpdated,
            noteUr: incNoteUr,
            noteEn: incNoteEn,
          );
        } else {
          // Incoming is Firestore, and this prayer was not set by the committee.
          // Preserve whatever Gist/current has.
          return PrayerMergeResult(
            time: cleanCurr,
            updated: currUpdated,
            noteUr: currNoteUr,
            noteEn: currNoteEn,
          );
        }
      }

      // If current has no time specified, take incoming
      if (cleanCurr.isEmpty || cleanCurr == '-' || cleanCurr.toLowerCase() == 'off') {
        return PrayerMergeResult(
          time: cleanInc,
          updated: incUpdated,
          noteUr: incNoteUr.isNotEmpty ? incNoteUr : currNoteUr,
          noteEn: incNoteEn.isNotEmpty ? incNoteEn : currNoteEn,
        );
      }

      // Both have a time. Compare dates with Firestore precedence rule.
      final currDt = _parseDate(currUpdated);
      final incDt = _parseDate(incUpdated);

      final cmp = _compareDatesWithPrecedence(
        dateA: incDt,
        dateB: currDt,
        isAFirestore: isIncomingFirestore,
      );

      if (cmp > 0) {
        // Incoming wins
        return PrayerMergeResult(
          time: cleanInc,
          updated: incUpdated.isNotEmpty ? incUpdated : currUpdated,
          noteUr: incNoteUr.isNotEmpty ? incNoteUr : currNoteUr,
          noteEn: incNoteEn.isNotEmpty ? incNoteEn : currNoteEn,
        );
      } else {
        // Current wins
        return PrayerMergeResult(
          time: cleanCurr,
          updated: currUpdated,
          noteUr: currNoteUr.isNotEmpty ? currNoteUr : incNoteUr,
          noteEn: currNoteEn.isNotEmpty ? currNoteEn : incNoteEn,
        );
      }
    }

    final fajr = mergeSingle(
      currTime: current.fajr,
      currUpdated: current.fajrUpdated,
      currNoteUr: current.fajrNoteUr,
      currNoteEn: current.fajrNoteEn,
      incTime: incoming.fajr,
      incUpdated: incoming.fajrUpdated,
      incNoteUr: incoming.fajrNoteUr,
      incNoteEn: incoming.fajrNoteEn,
      isMaghrib: false,
    );

    final zuhar = mergeSingle(
      currTime: current.zuhar,
      currUpdated: current.zuharUpdated,
      currNoteUr: current.zuharNoteUr,
      currNoteEn: current.zuharNoteEn,
      incTime: incoming.zuhar,
      incUpdated: incoming.zuharUpdated,
      incNoteUr: incoming.zuharNoteUr,
      incNoteEn: incoming.zuharNoteEn,
      isMaghrib: false,
    );

    final asar = mergeSingle(
      currTime: current.asar,
      currUpdated: current.asarUpdated,
      currNoteUr: current.asarNoteUr,
      currNoteEn: current.asarNoteEn,
      incTime: incoming.asar,
      incUpdated: incoming.asarUpdated,
      incNoteUr: incoming.asarNoteUr,
      incNoteEn: incoming.asarNoteEn,
      isMaghrib: false,
    );

    final maghrib = mergeSingle(
      currTime: current.maghrib,
      currUpdated: '',
      currNoteUr: current.maghribNoteUr,
      currNoteEn: current.maghribNoteEn,
      incTime: incoming.maghrib,
      incUpdated: '',
      incNoteUr: incoming.maghribNoteUr,
      incNoteEn: incoming.maghribNoteEn,
      isMaghrib: true,
    );

    final isha = mergeSingle(
      currTime: current.isha,
      currUpdated: current.ishaUpdated,
      currNoteUr: current.ishaNoteUr,
      currNoteEn: current.ishaNoteEn,
      incTime: incoming.isha,
      incUpdated: incoming.ishaUpdated,
      incNoteUr: incoming.ishaNoteUr,
      incNoteEn: incoming.ishaNoteEn,
      isMaghrib: false,
    );

    final jummah = mergeSingle(
      currTime: current.jummah,
      currUpdated: current.jummahUpdated,
      currNoteUr: current.jummahNoteUr,
      currNoteEn: current.jummahNoteEn,
      incTime: incoming.jummah,
      incUpdated: incoming.jummahUpdated,
      incNoteUr: incoming.jummahNoteUr,
      incNoteEn: incoming.jummahNoteEn,
      isMaghrib: false,
    );

    return JamaatTiming(
      fajr: fajr.time,
      fajrUpdated: fajr.updated,
      fajrNoteUr: fajr.noteUr,
      fajrNoteEn: fajr.noteEn,
      zuhar: zuhar.time,
      zuharUpdated: zuhar.updated,
      zuharNoteUr: zuhar.noteUr,
      zuharNoteEn: zuhar.noteEn,
      asar: asar.time,
      asarUpdated: asar.updated,
      asarNoteUr: asar.noteUr,
      asarNoteEn: asar.noteEn,
      maghrib: maghrib.time.isNotEmpty ? maghrib.time : 'Sunset',
      maghribNoteUr: maghrib.noteUr,
      maghribNoteEn: maghrib.noteEn,
      isha: isha.time,
      ishaUpdated: isha.updated,
      ishaNoteUr: isha.noteUr,
      ishaNoteEn: isha.noteEn,
      jummah: jummah.time,
      jummahUpdated: jummah.updated,
      jummahNoteUr: jummah.noteUr,
      jummahNoteEn: jummah.noteEn,
    );
  }

  static JamaatTiming? _getDefaultTimingFor(String id) {
    for (final m in sukkurMasjids) {
      if (m.id == id) return m.defaultTimings;
    }
    return null;
  }

  static const String _firestoreProjectId = 'sukkur-salah';
  static const String _firestoreCollection = 'jamaat_times';
  static final Uri _firestoreCollectionUrl = Uri.parse(
    'https://firestore.googleapis.com/v1/projects/$_firestoreProjectId/databases/(default)/documents/$_firestoreCollection',
  );

  static Map<String, dynamic> _flattenFirestoreFields(Map<String, dynamic> fields) {
    final Map<String, dynamic> flat = {};
    for (final entry in fields.entries) {
      if (entry.value is Map) {
        final valMap = entry.value as Map;
        if (valMap.containsKey('stringValue')) {
          flat[entry.key] = valMap['stringValue'];
        } else if (valMap.containsKey('integerValue')) {
          flat[entry.key] = valMap['integerValue'];
        } else if (valMap.containsKey('booleanValue')) {
          flat[entry.key] = valMap['booleanValue'];
        }
      }
    }
    return flat;
  }

  static Map<String, dynamic> _timingToFirestoreFields(JamaatTiming timing) {
    final Map<String, dynamic> fields = {};

    void addPrayer(String key, String time, String updated) {
      final clean = time.trim();
      if (clean.toLowerCase() == 'off' || (clean.isEmpty && updated.isNotEmpty)) {
        fields[key] = {'stringValue': 'off'};
        fields['${key}_updated'] = {'stringValue': updated};
      } else if (clean.isNotEmpty && clean != '-') {
        fields[key] = {'stringValue': clean};
        if (updated.isNotEmpty) {
          fields['${key}_updated'] = {'stringValue': updated};
        }
      }
    }

    addPrayer('fajr', timing.fajr, timing.fajrUpdated);
    addPrayer('zuhar', timing.zuhar, timing.zuharUpdated);
    addPrayer('asar', timing.asar, timing.asarUpdated);
    addPrayer('isha', timing.isha, timing.ishaUpdated);
    addPrayer('jummah', timing.jummah, timing.jummahUpdated);

    fields['maghrib'] = {'stringValue': timing.maghrib.isNotEmpty ? timing.maghrib : 'Sunset'};
    fields['updated_at'] = {'stringValue': DateTime.now().toIso8601String()};
    return {'fields': fields};
  }

  /// Updates timings for a specific masjid, updates in-memory cache instantly,
  /// persists to local cache in the background, and syncs to Cloud Firestore.
  Future<bool> updateTimingForMasjid({
    required String masjidId,
    required JamaatTiming newTiming,
  }) async {
    try {
      // 1. Instant in-memory cache update
      _remoteCache[masjidId] = newTiming;

      // Update in _dynamicMasjids or create entry
      final index = _dynamicMasjids.indexWhere((m) => m.id == masjidId);
      if (index >= 0) {
        final m = _dynamicMasjids[index];
        _dynamicMasjids[index] = JamaatMasjidInfo(
          id: m.id,
          nameKey: m.nameKey,
          addressKey: m.addressKey,
          defaultTimings: newTiming,
          isHidden: m.isHidden,
          localizedNames: m.localizedNames,
          localizedAddresses: m.localizedAddresses,
          pin: m.pin,
        );
      } else {
        final local = sukkurMasjids.firstWhere(
          (m) => m.id == masjidId,
          orElse: () => sukkurMasjids.first,
        );
        _dynamicMasjids.add(JamaatMasjidInfo(
          id: local.id,
          nameKey: local.nameKey,
          addressKey: local.addressKey,
          defaultTimings: newTiming,
          isHidden: local.isHidden,
          localizedNames: local.localizedNames,
          localizedAddresses: local.localizedAddresses,
          pin: _masjidPins[local.id],
        ));
      }

      // 2. Persist to storage in background without blocking UI
      _persistCacheAsync(masjidId);

      // 3. Sync to Google Cloud Firestore in background
      _syncTimingToFirestore(masjidId, newTiming);

      return true;
    } catch (e) {
      debugPrint('Error saving updated timing for $masjidId: $e');
      return false;
    }
  }

  void _syncTimingToFirestore(String masjidId, JamaatTiming timing) async {
    try {
      final patchUrl = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$_firestoreProjectId/databases/(default)/documents/$_firestoreCollection/$masjidId',
      );
      final payload = _timingToFirestoreFields(timing);
      final response = await http
          .patch(
            patchUrl,
            headers: const {'Content-Type': 'application/json'},
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('Successfully synced timing for masjid $masjidId to Cloud Firestore');
      } else {
        debugPrint('Firestore sync returned status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('Background Firestore sync error for masjid $masjidId: $e');
    }
  }

  void _persistCacheAsync(String masjidId) async {
    try {
      final activeList = getMasjidList();
      final Map<String, dynamic> exportData = {
        'master_pin': _masterAdminPin,
        'masjids': activeList.map((m) {
          final t = _remoteCache[m.id] ?? m.defaultTimings;
          final jsonMap = t.toJson();
          jsonMap['id'] = m.id;
          jsonMap['name'] = m.nameKey;
          jsonMap['address'] = m.addressKey;
          final pin = _masjidPins[m.id] ?? m.pin;
          if (pin != null && pin.isNotEmpty) {
            jsonMap['pin'] = pin;
          }
          if (m.localizedNames.isNotEmpty) jsonMap['names'] = m.localizedNames;
          if (m.localizedAddresses.isNotEmpty) jsonMap['addresses'] = m.localizedAddresses;
          return jsonMap;
        }).toList(),
      };

      final prefs = await _getPrefs();
      await prefs.setString(prefKeyJamaatCache, json.encode(exportData));
    } catch (e) {
      debugPrint('Error persisting cache for $masjidId: $e');
    }
  }

  /// Fetches live timings from Google Cloud Firestore.
  Future<bool> fetchFirestoreTimings() async {
    try {
      final separator = _firestoreCollectionUrl.toString().contains('?') ? '&' : '?';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final freshUrl = '$_firestoreCollectionUrl${separator}t=$timestamp';

      final response = await http
          .get(Uri.parse(freshUrl))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic> &&
            data.containsKey('documents') &&
            data['documents'] is List) {
          final docs = data['documents'] as List;
          bool anyApplied = false;
          for (final doc in docs) {
            if (doc is Map<String, dynamic> &&
                doc.containsKey('name') &&
                doc.containsKey('fields')) {
              final name = doc['name'].toString();
              final masjidId = name.split('/').last;
              final fields = doc['fields'] as Map<String, dynamic>? ?? {};
              if (fields.containsKey('pin')) {
                final p = fields['pin'];
                if (p is Map && p['stringValue'] != null && p['stringValue'].toString().trim().isNotEmpty) {
                  _masjidPins[masjidId] = p['stringValue'].toString().trim();
                }
              }
              final flatJson = _flattenFirestoreFields(fields);
              if (flatJson.isNotEmpty) {
                final timing = JamaatTiming.fromJson(flatJson);

                // Merge prayer-by-prayer: incoming is from Firestore (isIncomingFirestore: true)
                final existingTiming = _remoteCache[masjidId] ?? _getDefaultTimingFor(masjidId);
                final mergedTiming = existingTiming != null
                    ? mergePrayerByPrayer(
                        current: existingTiming,
                        incoming: timing,
                        isIncomingFirestore: true,
                      )
                    : timing;

                _remoteCache[masjidId] = mergedTiming;

                final index = _dynamicMasjids.indexWhere((m) => m.id == masjidId);
                if (index >= 0) {
                  final m = _dynamicMasjids[index];
                  _dynamicMasjids[index] = JamaatMasjidInfo(
                    id: m.id,
                    nameKey: m.nameKey,
                    addressKey: m.addressKey,
                    defaultTimings: mergedTiming,
                    isHidden: m.isHidden,
                    localizedNames: m.localizedNames,
                    localizedAddresses: m.localizedAddresses,
                    pin: m.pin,
                  );
                }
                anyApplied = true;
              }
            }
          }
          if (anyApplied) {
            _persistCacheAsync('firestore_sync');
            return true;
          }
        }
      }
    } catch (e) {
      debugPrint('Firestore fetch error: $e');
    }
    return false;
  }


  /// Fetches updated timings from Google Cloud Firestore and GitHub Gist.
  /// Firestore holds live real-time committee updates, while Gist provides
  /// any new masjid registrations and fallback defaults.
  Future<bool> fetchRemoteGistTimings() async {
    bool anySuccess = false;

    // 1. First fetch Gist for baseline masjid list & defaults
    if (_gistRawUrl.isNotEmpty) {
      try {
        final separator = _gistRawUrl.contains('?') ? '&' : '?';
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final freshUrl = '$_gistRawUrl${separator}t=$timestamp';

        final response = await (kIsWeb
                ? http.get(Uri.parse(freshUrl))
                : http.get(
                    Uri.parse(freshUrl),
                    headers: const {
                      'Accept': 'application/json',
                      'Cache-Control': 'no-cache, no-store, must-revalidate',
                      'Pragma': 'no-cache',
                      'Expires': '0',
                    },
                  ))
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final applied = _parseAndApplyJson(response.body);
          if (applied) {
            anySuccess = true;
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(prefKeyJamaatCache, response.body);
            } catch (_) {}
          }
        }
      } catch (e) {
        debugPrint('Network error fetching Jamaat times from Gist: $e');
      }
    }

    // 2. Then overlay live committee updates from Google Cloud Firestore on top.
    // This guarantees that any update made by an Imam in Firestore is NEVER overwritten
    // by older Gist lines.
    try {
      final firestoreSuccess = await fetchFirestoreTimings();
      if (firestoreSuccess) anySuccess = true;
    } catch (e) {
      debugPrint('Firestore fetch error: $e');
    }

    if (!anySuccess && _remoteCache.isEmpty) {
      await loadLocalCache();
    }

    return anySuccess;
  }
}
