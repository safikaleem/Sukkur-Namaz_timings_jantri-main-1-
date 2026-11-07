import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../data/timings_data.dart';
import 'developer_gist_service.dart';

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

  static bool _isExplicitlyOff(dynamic val) {
    if (val == null) return false;
    final s = val.toString().trim().toLowerCase();
    return s == 'off' || s == '-' || s == '--:--';
  }

  factory JamaatTiming.fromJson(Map<String, dynamic> json) {
    final rawDefault = json['last_updated'] ?? json['lastUpdated'];
    final defaultDate = rawDefault != null ? normalizeDate(rawDefault.toString()) : '';

    String parseUpdated(String fieldKey, String altKey) {
      if (json.containsKey(fieldKey)) {
        return normalizeDate(json[fieldKey]?.toString() ?? '');
      }
      if (json.containsKey(altKey)) {
        return normalizeDate(json[altKey]?.toString() ?? '');
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
      fajrUpdated: (fajrVal.isNotEmpty || _isExplicitlyOff(json['fajr']))
          ? parseUpdated('fajr_updated', 'fajrUpdated')
          : '',
      fajrNoteUr: json['fajr_note_ur']?.toString() ?? json['fajrNoteUr']?.toString() ?? json['fajr_note']?.toString() ?? '',
      fajrNoteEn: json['fajr_note_en']?.toString() ?? json['fajrNoteEn']?.toString() ?? '',
      zuhar: zuharVal,
      zuharUpdated: (zuharVal.isNotEmpty || _isExplicitlyOff(json['zuhar']))
          ? parseUpdated('zuhar_updated', 'zuharUpdated')
          : '',
      zuharNoteUr: json['zuhar_note_ur']?.toString() ?? json['zuharNoteUr']?.toString() ?? json['zuhar_note']?.toString() ?? '',
      zuharNoteEn: json['zuhar_note_en']?.toString() ?? json['zuharNoteEn']?.toString() ?? '',
      asar: asarVal,
      asarUpdated: (asarVal.isNotEmpty || _isExplicitlyOff(json['asar']))
          ? parseUpdated('asar_updated', 'asarUpdated')
          : '',
      asarNoteUr: json['asar_note_ur']?.toString() ?? json['asarNoteUr']?.toString() ?? json['asar_note']?.toString() ?? '',
      asarNoteEn: json['asar_note_en']?.toString() ?? json['asarNoteEn']?.toString() ?? '',
      maghrib: maghribVal.isNotEmpty ? maghribVal : 'Sunset',
      maghribNoteUr: json['maghrib_note_ur']?.toString() ?? json['maghribNoteUr']?.toString() ?? json['maghrib_note']?.toString() ?? '',
      maghribNoteEn: json['maghrib_note_en']?.toString() ?? json['maghribNoteEn']?.toString() ?? '',
      isha: ishaVal,
      ishaUpdated: (ishaVal.isNotEmpty || _isExplicitlyOff(json['isha']))
          ? parseUpdated('isha_updated', 'ishaUpdated')
          : '',
      ishaNoteUr: json['isha_note_ur']?.toString() ?? json['ishaNoteUr']?.toString() ?? json['isha_note']?.toString() ?? '',
      ishaNoteEn: json['isha_note_en']?.toString() ?? json['ishaNoteEn']?.toString() ?? '',
      jummah: jummahVal,
      jummahUpdated: (jummahVal.isNotEmpty || _isExplicitlyOff(json['jummah']))
          ? parseUpdated('jummah_updated', 'jummahUpdated')
          : '',
      jummahNoteUr: json['jummah_note_ur']?.toString() ?? json['jummahNoteUr']?.toString() ?? json['jummah_note']?.toString() ?? '',
      jummahNoteEn: json['jummah_note_en']?.toString() ?? json['jummahNoteEn']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'fajr': fajr,
        'fajr_updated': fajrUpdated,
        if (fajrNoteUr.isNotEmpty) 'fajr_note_ur': fajrNoteUr,
        if (fajrNoteEn.isNotEmpty) 'fajr_note_en': fajrNoteEn,
        'zuhar': zuhar,
        'zuhar_updated': zuharUpdated,
        if (zuharNoteUr.isNotEmpty) 'zuhar_note_ur': zuharNoteUr,
        if (zuharNoteEn.isNotEmpty) 'zuhar_note_en': zuharNoteEn,
        'asar': asar,
        'asar_updated': asarUpdated,
        if (asarNoteUr.isNotEmpty) 'asar_note_ur': asarNoteUr,
        if (asarNoteEn.isNotEmpty) 'asar_note_en': asarNoteEn,
        'maghrib': maghrib,
        if (maghribNoteUr.isNotEmpty) 'maghrib_note_ur': maghribNoteUr,
        if (maghribNoteEn.isNotEmpty) 'maghrib_note_en': maghribNoteEn,
        'isha': isha,
        'isha_updated': ishaUpdated,
        if (ishaNoteUr.isNotEmpty) 'isha_note_ur': ishaNoteUr,
        if (ishaNoteEn.isNotEmpty) 'isha_note_en': ishaNoteEn,
        'jummah': jummah,
        'jummah_updated': jummahUpdated,
        if (jummahNoteUr.isNotEmpty) 'jummah_note_ur': jummahNoteUr,
        if (jummahNoteEn.isNotEmpty) 'jummah_note_en': jummahNoteEn,
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

class JamaatTimesService extends ChangeNotifier {
  static final JamaatTimesService instance = JamaatTimesService._();
  JamaatTimesService._();

  // Pre-configured Sukkur masjids list (all 70 masjids built-in)
  static const List<JamaatMasjidInfo> sukkurMasjids = [
    JamaatMasjidInfo(
      id: 'babul_islam',
      nameKey: 'Masjid Babul Islam',
      addressKey: 'Anaj Bazar Sukkur',
      pin: '25354555',
      defaultTimings: JamaatTiming(
        fajr: '06:15 AM',
        fajrUpdated: '02 Nov 2026',
        zuhar: '01:15 PM',
        asar: '04:30 PM',
        asarUpdated: '20 Oct 2026',
        maghrib: 'Sunset',
        isha: '07:15 PM',
        ishaUpdated: '05 Nov 2026',
        jummah: '01:15 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'ahmed_thanvi',
      nameKey: 'Masjid Molana Muhammad Ahmed Thanvi',
      addressKey: 'Queen\'s Road Sukkur',
      pin: '32103210',
      defaultTimings: JamaatTiming(
        fajr: '06:10 AM',
        fajrUpdated: '03 Nov 2026',
        zuhar: '01:15 PM',
        asar: '04:30 PM',
        asarUpdated: '04 Nov 2026',
        maghrib: 'Sunset',
        isha: '08:00 PM',
        ishaUpdated: '04 Oct 2026',
        jummah: '01:15 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'noor_masjid',
      nameKey: 'Noor Masjid',
      addressKey: 'Miani Road Sukkur',
      pin: '22332233',
      defaultTimings: JamaatTiming(
        fajr: '06:10 AM',
        fajrUpdated: '24 Oct 2026',
        zuhar: '01:45 PM',
        asar: '04:30 PM',
        asarUpdated: '24 Oct 2026',
        maghrib: 'Sunset',
        isha: '07:30 PM',
        ishaUpdated: '04 Nov 2026',
        jummah: '01:30 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'madni_masjid',
      nameKey: 'Madni Masjid',
      addressKey: 'Shahi Bazar Sukkur',
      pin: '11335577',
      defaultTimings: JamaatTiming(
        fajr: '06:10 AM',
        fajrUpdated: '29 Oct 2026',
        zuhar: '01:30 PM',
        asar: '04:30 PM',
        asarUpdated: '19 Oct 2026',
        maghrib: 'sunset',
        isha: '08:00 PM',
        ishaUpdated: '04 Oct 2026',
        jummah: '01:30 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'masjid_darul_islam',
      nameKey: 'Masjid Darul Islam',
      addressKey: 'Upper Queen\'s Road Sukkur',
      pin: '00997755',
      defaultTimings: JamaatTiming(
        fajr: '06:10 AM',
        fajrUpdated: '30 Oct 2026',
        zuhar: '01:30 PM',
        zuharUpdated: '30 Oct 2026',
        asar: '04:30 PM',
        asarUpdated: '21 Oct 2026',
        maghrib: 'Sunset',
        isha: '07:15 PM',
        ishaUpdated: '02 Nov 2026',
        jummah: '01:00 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'noorani_masjid',
      nameKey: 'Noorani Masjid',
      addressKey: 'Katti Bazar Sukkur',
      pin: '00447860',
      defaultTimings: JamaatTiming(
        fajr: '06:00 AM',
        fajrUpdated: '20 Oct 2026',
        zuhar: '01:45 PM',
        asar: '04:45 PM',
        asarUpdated: '12 Oct 2026',
        maghrib: 'sunset',
        isha: '07:45 PM',
        ishaUpdated: '20 Oct 2026',
        jummah: '01:45 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'masjid_jamia_ashrafia',
      nameKey: 'Masjid Jamia Ashrafia',
      addressKey: 'Wallace Road Sukkur',
      pin: '31300313',
      defaultTimings: JamaatTiming(
        fajr: '06:15 AM',
        fajrUpdated: '03 Nov 2026',
        zuhar: '01:45 PM',
        zuharUpdated: '31 Oct 2026',
        asar: '04:30 PM',
        asarUpdated: '31 Oct 2026',
        maghrib: 'Sunset',
        isha: '08:00 PM',
        ishaUpdated: '31 Oct 2026',
        jummah: '01:45 PM',
        jummahUpdated: '04 Oct 2026',
      ),
    ),
    JamaatMasjidInfo(
      id: 'jamia_masjid',
      nameKey: 'Markazi Jama Masjid',
      addressKey: 'Bunder Road, Sukkur',
      pin: '34561234',
      localizedNames: {
        'urdu': 'مرکزی جامع مسجد',
        'sindhi': 'مرڪزي جامع مسجد',
        'arabic': 'المسجد الجامع المركزي',
        'hindi': 'مرकज़ी जामा मस्जिद',
        'bengali': 'মাররাজি জামে মসজিদ',
        'persian': 'مسجد جامع مرکزی',
        'turkish': 'Merkezi Cuma Camii',
        'french': 'Mosquée Markazi Jama',
        'indonesian': 'Masjid Markazi Jama',
      },
      localizedAddresses: {
        'urdu': 'بندر روڈ، سکھر',
        'sindhi': 'بندر روڊ، سکر',
        'arabic': 'شارع بندر، سكر',
        'hindi': 'बंदर रोड, सुक्कुर',
        'bengali': 'বান্দর রোড, সুক্কুর',
        'persian': 'جاده بندر، سکر',
        'turkish': 'Bunder Road, Sukkur',
        'french': 'Bunder Road, Sukkur',
        'indonesian': 'Bunder Road, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:10 AM',
        fajrUpdated: '02 Nov 2026',
        zuhar: '01:30 PM',
        asar: '04:45 PM',
        asarUpdated: '22 Oct 2026',
        maghrib: 'sunset',
        isha: '08:45 PM',
        ishaUpdated: '22 Oct 2026',
        jummah: '02:30 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'allah_wali_masjid',
      nameKey: 'Allah Wali Masjid',
      addressKey: 'Bunder Road Sukkur',
      pin: '98769876',
      defaultTimings: JamaatTiming(
        fajr: '06:15 AM',
        fajrUpdated: '01 Nov 2026',
        zuhar: '01:45 PM',
        asar: '04:45 PM',
        asarUpdated: '20 Oct 2026',
        maghrib: 'Sunset',
        isha: '08:45 PM',
        ishaUpdated: '17 Oct 2026',
        jummah: '01:55 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'makki_masjid',
      nameKey: 'Jama Makki Masjid',
      addressKey: 'Minara Road, Sukkur',
      pin: '78603130',
      localizedNames: {
        'urdu': 'جامع مکی مسجد',
        'sindhi': 'جامع مڪي مسجد',
        'arabic': 'جامع مسجد المكي',
        'hindi': 'जामा मक्की मस्जिद',
        'bengali': 'জামে মাক্কী মসজিদ',
        'persian': 'مسجد جامع مکی',
        'turkish': 'Makki Cuma Camii',
        'french': 'Mosquée Jama Makki',
        'indonesian': 'Masjid Jama Makki',
      },
      localizedAddresses: {
        'urdu': 'مینارہ روڈ، سکھر',
        'sindhi': 'مينارا روڊ، سکر',
        'arabic': 'شارع المنارة، سكر',
        'hindi': 'मिनारा रोड, सुक्कुर',
        'bengali': 'মিনারা রোড, সুক্কুর',
        'persian': 'جاده مناره، سکر',
        'turkish': 'Minara Road, Sukkur',
        'french': 'Minara Road, Sukkur',
        'indonesian': 'Minara Road, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:15 AM',
        fajrUpdated: '01 Nov 2026',
        zuhar: '02:00 PM',
        asar: '04:30 PM',
        asarUpdated: '31 Oct 2026',
        maghrib: 'Sunset',
        maghribNoteUr: 'جماعت اذان کے 2 منٹ بعد ادا کی جائے گی',
        isha: '07:45 PM',
        ishaUpdated: '28 Oct 2026',
        jummah: '01:35 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'gol_masjid',
      nameKey: 'Gol Jamia Masjid',
      addressKey: 'Barrage Colony, Sukkur',
      pin: '44888844',
      localizedNames: {
        'urdu': 'گول جامعہ مسجد',
        'sindhi': 'گول جامعہ مسجد',
        'arabic': 'جامعة المسجد الدائري',
        'hindi': 'गोल जामिया मस्जिद',
        'bengali': 'গোল জামিয়া মসজিদ',
        'persian': 'مسجد جامعۀ گول',
        'turkish': 'Gol Cuma Camii',
        'french': 'Mosquée Jamia Gol',
        'indonesian': 'Masjid Jamia Gol',
      },
      localizedAddresses: {
        'urdu': 'بیراج کالونی، سکھر',
        'sindhi': 'بيراج ڪالوني، سکر',
        'arabic': 'حي براج، سكر',
        'hindi': 'बैराज कॉलोनी, सुक्कुर',
        'bengali': 'ব্যারাজ কলোনি, সুক্কুর',
        'persian': 'شهرک سد، سکر',
        'turkish': 'Barrage Colony, Sukkur',
        'french': 'Barrage Colony, Sukkur',
        'indonesian': 'Barrage Colony, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:15 AM',
        fajrUpdated: '02 Nov 2026',
        zuhar: '01:45 PM',
        zuharUpdated: '02 Nov 2026',
        asar: '04:30 PM',
        asarUpdated: '02 Nov 2026',
        maghrib: 'Sunset',
        isha: '07:45 PM',
        ishaUpdated: '04 Oct 2026',
        jummah: '02:30 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'masjid_manzilgah',
      nameKey: 'Masjid Manzilgah',
      addressKey: 'Bunder Road Sukkur',
      pin: '22662266',
      defaultTimings: JamaatTiming(
        fajr: '06:10 AM',
        fajrUpdated: '01 Nov 2026',
        zuhar: '02:30 PM',
        asar: '04:30 PM',
        asarUpdated: '29 Oct 2026',
        maghrib: 'Sunset',
        isha: '07:30 PM',
        ishaUpdated: '29 Oct 2026',
        jummah: '02:30 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'masjid_ayesha',
      nameKey: 'Masjid Ayesha',
      addressKey: 'Chanchar Ghitti, Shahi Bazar Sukkur',
      pin: '88447878',
      defaultTimings: JamaatTiming(
        fajr: '06:10 AM',
        fajrUpdated: '01 Nov 2026',
        zuhar: '01:45 PM',
        asar: '04:45 PM',
        asarUpdated: '20 Oct 2026',
        maghrib: 'Sunset',
        isha: '08:00 PM',
        ishaUpdated: '14 Oct 2026',
        jummah: '01:45 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'shamsi_masjid',
      nameKey: 'Shamsi Masjid',
      addressKey: 'Frere Road Sukkur',
      pin: '31415161',
      defaultTimings: JamaatTiming(
        fajr: '06:05 AM',
        fajrUpdated: '01 Nov 2026',
        zuhar: '01:30 PM',
        asar: '04:30 PM',
        asarUpdated: '20 Oct 2026',
        maghrib: 'Sunset',
        isha: '07:30 PM',
        ishaUpdated: '17 Oct 2026',
        jummah: '01:30 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'safed_masjid',
      nameKey: 'Jama Safaid Masjid',
      addressKey: 'Husaini Road, Sukkur',
      pin: '37475767',
      localizedNames: {
        'urdu': 'جامع سفید مسجد',
        'sindhi': 'جامع سفيد مسجد',
        'arabic': 'مسجد الجامع السفيد',
        'hindi': 'जामा सफेद मस्जिद',
        'bengali': 'জামে সাফেদ মসজিদ',
        'persian': 'مسجد جامع سفید',
        'turkish': 'Safaid Cuma Camii',
        'french': 'Mosquée Jama Safaid',
        'indonesian': 'Masjid Jama Safaid',
      },
      localizedAddresses: {
        'urdu': 'حسینی روڈ، سکھر',
        'sindhi': 'حسيني روڊ، سکر',
        'arabic': 'شارع الحسيني، سكر',
        'hindi': 'हुसैनी रोड, सुक्कुर',
        'bengali': 'হুসাইনি রোড, সুক্কুর',
        'persian': 'جاده حسینی، سکر',
        'turkish': 'Husaini Road, Sukkur',
        'french': 'Husaini Road, Sukkur',
        'indonesian': 'Husaini Road, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:10 AM',
        fajrUpdated: '02 Nov 2026',
        zuhar: '01:30 PM',
        asar: '04:30 PM',
        asarUpdated: '27 Oct 2026',
        maghrib: 'Sunset',
        isha: '07:30 PM',
        ishaUpdated: '22 Oct 2026',
        jummah: '01:30 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'masjid_al_farooq',
      nameKey: 'Masjid Al Farooq',
      addressKey: 'Barrage Road, Ghanta Ghar Sukkur',
      pin: '21314151',
      defaultTimings: JamaatTiming(
        fajr: '06:10 AM',
        fajrUpdated: '24 Oct 2026',
        zuhar: '01:30 PM',
        asar: '04:30 PM',
        asarUpdated: '04 Nov 2026',
        maghrib: 'Sunset',
        isha: '07:30 PM',
        ishaUpdated: '29 Oct 2026',
        jummah: '01:30 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'masjid_dr_hafeezullah',
      nameKey: 'Masjid Hazrat Dr Hafeezullah Sahib Rahimahullah',
      addressKey: 'Professor Society, Kheer Thar Canal Road, near Darul Uloom Sukkur',
      pin: '11002200',
      defaultTimings: JamaatTiming(
        fajr: '06:10 AM',
        fajrUpdated: '30 Oct 2026',
        zuhar: '01:45 PM',
        asar: '04:30 PM',
        asarUpdated: '30 Oct 2026',
        maghrib: 'Sunset',
        isha: '07:30 PM',
        ishaUpdated: '24 Oct 2026',
        jummah: '01:45 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'shahi_jamia_masjid',
      nameKey: 'Shahi Jamia Masjid',
      addressKey: 'Purana Sukkur',
      pin: '33007777',
      defaultTimings: JamaatTiming(
        fajr: '06:10 AM',
        fajrUpdated: '22 Oct 2026',
        zuhar: '01:30 PM',
        asar: '04:30 PM',
        asarUpdated: '30 Oct 2026',
        maghrib: 'Sunset',
        isha: '07:45 PM',
        ishaUpdated: '22 Oct 2026',
        jummah: '02:00 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'jamia_masjid_bait_ul_hamd',
      nameKey: 'Jamia Masjid Bait ul Hamd',
      addressKey: 'Green City near NICVD Hospital Sukkur',
      pin: '89890123',
      defaultTimings: JamaatTiming(
        fajr: '06:10 AM',
        fajrUpdated: '25 Oct 2026',
        zuhar: '01:30 PM',
        asar: '04:30 PM',
        asarUpdated: '31 Oct 2026',
        maghrib: 'Sunset',
        isha: '07:30 PM',
        ishaUpdated: '18 Oct 2026',
        jummah: '',
        jummahNoteUr: 'فی الحال اس مسجد میں نمازِ جمعہ ادا نہیں کی جاتی۔',
      ),
    ),
    JamaatMasjidInfo(
      id: 'masjid_bilal',
      nameKey: 'Masjid bilal',
      addressKey: 'Air Port Road',
      isHidden: true,
      localizedNames: {
        'urdu': 'مسجد بلال',
        'sindhi': '',
        'arabic': '',
        'hindi': '',
        'bengali': '',
        'persian': '',
        'turkish': '',
        'french': '',
        'indonesian': '',
      },
      localizedAddresses: {
        'urdu': 'ائر پورٹ روڈ',
        'sindhi': '',
        'arabic': '',
        'hindi': '',
        'bengali': '',
        'persian': '',
        'turkish': '',
        'french': '',
        'indonesian': '',
      },
      defaultTimings: JamaatTiming(
        fajr: '05:15 AM',
        fajrUpdated: '16 Oct 2026',
        zuhar: '01:30 PM',
        asar: '04:45 PM',
        asarUpdated: '16 Oct 2026',
        maghrib: 'sunset',
        isha: '08:00 PM',
        ishaUpdated: '16 Oct 2026',
        jummah: '01:30 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'qadeemi_jamia_masjid_hazrat_imam_zain_ul_abidin',
      nameKey: 'Qadeemi Jamia Masjid Hazrat Imam Zain ul Abidin',
      addressKey: 'Bhusa Line Chowk, Sukkur',
      pin: '66968676',
      localizedNames: {
        'urdu': 'قدیمی جامع مسجد حضرت امام زین العابدین',
        'sindhi': 'قديمي جامع مسجد حضرت امام زين العابدين',
        'arabic': 'المسجد الجامع القديم لحضرة الإمام زين العابدين،',
        'hindi': 'हज़रत इमाम ज़ैनुल आबिदीन की प्राचीन जामा मस्जिद',
        'bengali': 'হযরত ইমাম জয়নুল আবেদীনের প্রাচীন জামে মসজিদ',
        'persian': 'مسجد جامع قدیمی حضرت امام زین‌العابدین',
        'turkish': 'Hazreti İmam Zeynelâbidîn\'in Eski Ulu Camii',
        'french': 'L’ancienne grande mosquée de Hazrat Imam Zain ul Abideen',
        'indonesian': 'Masjid Jami Kuno Hazrat Imam Zainul Abidin',
      },
      localizedAddresses: {
        'urdu': 'بھوسہ لائن چوک، سکھر',
        'sindhi': 'ڀوسا لائين چوڪ، سکر',
        'arabic': 'بوسا لاين تشوك، سُكّر',
        'hindi': 'भूसा लाइन चौक, सक्कर',
        'bengali': 'ভুসা লাইন চক, সুক্কুর',
        'persian': 'بھوسا لاین چوک، سکھر',
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
        maghrib: 'sunset',
        isha: '07:30 PM',
        ishaUpdated: '24 Oct 2026',
        jummah: '01:00 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'bukhari_masjid',
      nameKey: 'Bukhari Masjid',
      addressKey: 'Mission Road, near Bolan Hotel, Sukkur',
      pin: '12399000',
      localizedNames: {
        'urdu': 'بخاری مسجد',
        'sindhi': 'بخاري مسجد',
        'arabic': 'مسجد البخاري',
        'hindi': 'बुख़ारी मस्जिद',
        'bengali': 'বোখারী মসজিদ',
        'persian': 'مسجد بخاری',
        'turkish': 'Buhârî Camii',
        'french': 'Mosquée Al-Boukhari',
        'indonesian': 'Masjid Bukhari',
      },
      localizedAddresses: {
        'urdu': 'مشن روڈ، نزد بولان ہوٹل، سکھر',
        'sindhi': 'مشن روڊ، بولان هوٽل ڀرسان، سکر',
        'arabic': 'طريق ميشن، بالقرب من فندق بولان، سُكّر',
        'hindi': 'मिशन रोड, बोलान होटल के पास, सुक्कुर',
        'bengali': 'মিশন রোড, বোলান হোটেলের কাছে, সুক্কুর',
        'persian': 'خیابان میشن، نزدیک هتل بولان، سوکور',
        'turkish': 'Mission Caddesi, Bolan Oteli yakını, Sukkur',
        'french': 'Route Mission, près de l\'Hôtel Bolan, Sukkur',
        'indonesian': 'Jalan Mission, dekat Hotel Bolan, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:20 AM',
        fajrUpdated: '04 Nov 2026',
        zuhar: '01:00 PM',
        asar: '04:30 PM',
        asarUpdated: '22 Oct 2026',
        maghrib: 'Sunset',
        maghribNoteUr: 'جماعت اِس وقت (غروبِ آفتاب) کے 5 منٹ بعد ادا کی جائے گی',
        isha: '07:15 PM',
        ishaUpdated: '04 Nov 2026',
        jummah: '12:52 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'masjid_khatamunabiyeen',
      nameKey: 'Masjid Khatamunabiyeen ﷺ',
      addressKey: 'Sindhi Society, near NAB Court, Sukkur',
      pin: '44001230',
      localizedNames: {
        'urdu': 'مسجد خاتم النبیین ﷺ',
        'sindhi': 'مسجد خاتم النبيين ﷺ',
        'arabic': 'مسجد خاتم النبيين ﷺ',
        'hindi': 'मस्जिद ख़ातमुन्नबिय्यीन ﷺ',
        'bengali': 'মসজিদ খাতামুন নাবিয়্যিন ﷺ',
        'persian': 'مسجد خاتم‌النبیین ﷺ',
        'turkish': 'Mescid Hatemünnebiyyin ﷺ',
        'french': 'Mosquée Khatamun Nabiyyin ﷺ',
        'indonesian': 'Masjid Khatamun Nabiyyin ﷺ',
      },
      localizedAddresses: {
        'urdu': 'سندھی سوسائٹی، نزد نیب کورٹ، سکھر',
        'sindhi': 'سنڌي سوسائٽي، ويجهو نيب ڪورٽ، سکر',
        'arabic': 'سندهي سوسايتي، بالقرب من محكمة ناب، سكر',
        'hindi': 'सिंधी सोसाइटी, नैब कोर्ट के पास, सुक्कुर',
        'bengali': 'সিন্ধি সোসাইটি, এনএবি কোর্টের কাছে, সুক্কুর',
        'persian': 'سندی سوسایتی، نزدیک دادگاه نیب، سکر',
        'turkish': 'Sindhi Society, NAB Mahkemesi yakını, Sukkur',
        'french': 'Sindhi Society, près du tribunal NAB, Sukkur',
        'indonesian': 'Sindhi Society, dekat Pengadilan NAB, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:15 AM',
        fajrUpdated: '31 Oct 2026',
        zuhar: '01:00 PM',
        asar: '04:30 PM',
        asarUpdated: '23 Oct 2026',
        maghrib: 'Sunset',
        isha: '07:30 PM',
        ishaUpdated: '23 Oct 2026',
        jummah: '01:00 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'jamia_masjid_naseer',
      nameKey: 'Jamia Masjid Naseer',
      addressKey: 'Sheikh Shaheen Road, Sukkur',
      pin: '32145608',
      localizedNames: {
        'urdu': 'جامع مسجد نصیر',
        'sindhi': 'جامع مسجد نصير',
        'arabic': 'جامع مسجد نصير',
        'hindi': 'जामिया मस्जिद नसीर',
        'bengali': 'জামিয়া মসজিদ নাসির',
        'persian': 'مسجد جامع نصیر',
        'turkish': 'Naseer Camii',
        'french': 'Grande Mosquée Naseer',
        'indonesian': 'Masjid Jami Naseer',
      },
      localizedAddresses: {
        'urdu': 'شیخ شہین روڈ، سکھر',
        'sindhi': 'شيخ شهين روڊ، سکر',
        'arabic': 'طريق الشيخ شهين، سكر',
        'hindi': 'शेख शहीन रोड, सुक्कुर',
        'bengali': 'শেখ শহীন রোড, সুক্কুর',
        'persian': 'سرک شیخ شهین، سکر',
        'turkish': 'Şeyh Şahin Yolu, Sukkur',
        'french': 'Route Sheikh Shaheen, Sukkur',
        'indonesian': 'Jalan Sheikh Shaheen, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '05:40 AM',
        fajrUpdated: '01 Nov 2026',
        zuhar: '02:30 PM',
        asar: '04:55 PM',
        asarUpdated: '31 Oct 2026',
        maghrib: 'Sunset',
        isha: '09:45 PM',
        ishaUpdated: '23 Oct 2026',
        jummah: '03:15 PM',
        jummahUpdated: '23 Oct 2026',
      ),
    ),
    JamaatMasjidInfo(
      id: 'markazi_jamia_masjid_riyaz_ul_jannah',
      nameKey: 'Markazi Jamia Masjid Riyaz ul Jannah (Jamia Darul Uloom)',
      addressKey: 'Government Society, Sukkur',
      pin: '88669900',
      localizedNames: {
        'urdu': 'مرکزی جامع مسجد ریاض الجنہ (جامعہ دارالعلوم)',
        'sindhi': 'مرڪزي جامع مسجد رياض الجنة (جامعه دارالعلوم)',
        'arabic': 'المسجد الجامع المركزي رياض الجنة (جامعة دار العلوم)',
        'hindi': 'मरकज़ी जामिया मस्जिद रियाज़ उल जन्नह (जामिया दारुल उलूम)',
        'bengali': 'মারকাজি জামিয়া মসজিদ রিয়াজুল জান্নাহ (জামিয়া দারুল উলূম)',
        'persian': 'مسجد جامع مرکزی ریاض‌الجنه (جامعه دارالعلوم)',
        'turkish': 'Merkez Camii Riyazü\'l-Cenne (Camia Darü\'l-Ulûm)',
        'french': 'Mosquée Centrale Riyaz ul Jannah (Jamia Darul Uloom)',
        'indonesian': 'Masjid Jami Pusat Riyazul Jannah (Jamia Darul Uloom)',
      },
      localizedAddresses: {
        'urdu': 'گورنمنٹ سوسائٹی، سکھر',
        'sindhi': 'گورنمينٽ سوسائٽي، سکر',
        'arabic': 'الحي الحكومي، سكر',
        'hindi': 'गवर्नमेंट सोसाइटी, सुक्कुर',
        'bengali': 'গভর্নমেন্ট সোসাইটি, সুক্কুর',
        'persian': 'گورنمنت سوسایتی، سکر',
        'turkish': 'Government Society, Sukkur',
        'french': 'Government Society, Sukkur',
        'indonesian': 'Government Society, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:00 AM',
        fajrUpdated: '26 Oct 2026',
        zuhar: '02:00 PM',
        zuharUpdated: '23 Oct 2026',
        asar: '04:45 PM',
        asarUpdated: '23 Oct 2026',
        maghrib: 'sunset',
        isha: '09:00 PM',
        ishaUpdated: '23 Oct 2026',
        jummah: '01:30 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'madina_masjid',
      nameKey: 'Madina Masjid',
      addressKey: 'Cloth Market, Sukkur',
      pin: '11770055',
      localizedNames: {
        'urdu': 'مدینہ مسجد',
        'sindhi': 'مدينه مسجد',
        'arabic': 'مسجد المدينة',
        'hindi': 'मदीना मस्जिद',
        'bengali': 'মদিনা মসজিদ',
        'persian': 'مسجد مدینه',
        'turkish': 'Medine Mescidi',
        'french': 'Mosquée Madina',
        'indonesian': 'Masjid Madinah',
      },
      localizedAddresses: {
        'urdu': 'کپڑا مارکیٹ، سکھر',
        'sindhi': 'ڪپڙا مارڪيٽ، سکر',
        'arabic': 'سوق القماش، سكر',
        'hindi': 'कपड़ा मार्केट, सुक्कुर',
        'bengali': 'ক্লথ মার্কেট, সুক্কুর',
        'persian': 'بازار پارچه، سکر',
        'turkish': 'Kumaş Pazarı, Sukkur',
        'french': 'Marché aux tissus, Sukkur',
        'indonesian': 'Cloth Market, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:20 AM',
        fajrUpdated: '03 Nov 2026',
        zuhar: '01:00 PM',
        asar: '04:30 PM',
        asarUpdated: '24 Oct 2026',
        maghrib: 'Sunset',
        isha: '07:30 PM',
        ishaUpdated: '24 Oct 2026',
        jummah: '01:00 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'gol_masjid_akhuwat_nagar',
      nameKey: 'Gol Masjid',
      addressKey: 'Akhuwat Nagar Society, Sukkur',
      pin: '12366600',
      localizedNames: {
        'urdu': 'گول مسجد',
        'sindhi': 'گول مسجد',
        'arabic': 'المسجد الجول',
        'hindi': 'गोल मस्जिद',
        'bengali': 'গোল মসজিদ',
        'persian': 'گول مسجد',
        'turkish': 'Gol Mescidi',
        'french': 'Mosquée Gol',
        'indonesian': 'Masjid Gol',
      },
      localizedAddresses: {
        'urdu': 'اخوت نگر سوسائٹی، سکھر',
        'sindhi': 'اخوت نگر سوسائٽي، سکر',
        'arabic': 'جمعية اخوت نغر، سكر',
        'hindi': 'अखुवत नगर सोसाइटी, सुक्कुर',
        'bengali': 'আখুওয়াত নগর সোসাইটি, সুক্কুর',
        'persian': 'اخوت نگر سوسایتی، سکر',
        'turkish': 'Akhuwat Nagar Sitesi, Sukkur',
        'french': 'Société Akhuwat Nagar, Sukkur',
        'indonesian': 'Perumahan Akhuwat Nagar, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:10 AM',
        fajrUpdated: '28 Oct 2026',
        zuhar: '01:30 PM',
        asar: '04:30 PM',
        asarUpdated: '24 Oct 2026',
        maghrib: 'sunset',
        isha: '07:30 PM',
        ishaUpdated: '24 Oct 2026',
        jummah: '01:30 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'ghosia_masjid_cloth_market',
      nameKey: 'Ghosia Masjid',
      addressKey: 'Cloth Market, Sukkur',
      pin: '45604560',
      localizedNames: {
        'urdu': 'غوثیہ مسجد',
        'sindhi': 'غوثيه مسجد',
        'arabic': 'مسجد الغوثية',
        'hindi': 'ग़ौसिया मस्जिद',
        'bengali': 'গাউসিয়া মসজিদ',
        'persian': 'مسجد غوثیه',
        'turkish': 'Gavsiye Mescidi',
        'french': 'Mosquée Ghosia',
        'indonesian': 'Masjid Ghosia',
      },
      localizedAddresses: {
        'urdu': 'کپڑا مارکیٹ، سکھر',
        'sindhi': 'ڪپڙا مارڪيٽ، سکر',
        'arabic': 'سوق القماش، سكر',
        'hindi': 'कपड़ा मार्केट, सुक्कुर',
        'bengali': 'ক্লথ মার্কেট, সুক্কুর',
        'persian': 'بازار پارچه، سکر',
        'turkish': 'Kumaş Pazarı, Sukkur',
        'french': 'Marché aux tissus, Sukkur',
        'indonesian': 'Cloth Market, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:10 AM',
        fajrUpdated: '27 Oct 2026',
        zuhar: '01:30 PM',
        asar: '04:30 PM',
        asarUpdated: '27 Oct 2026',
        maghrib: 'Sunset',
        isha: '07:30 PM',
        ishaUpdated: '31 Oct 2026',
        jummah: '03:20 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'moti_masjid',
      nameKey: 'Moti Masjid',
      addressKey: 'Shikarpur Road, Sukkur',
      pin: '00006622',
      localizedNames: {
        'urdu': 'موتی مسجد',
        'sindhi': 'موتي مسجد',
        'arabic': 'مسجد موتي',
        'hindi': 'मोती मस्जिद',
        'bengali': 'মতি মসজিদ',
        'persian': 'مسجد موتی',
        'turkish': 'Moti Camii',
        'french': 'Mosquée Moti',
        'indonesian': 'Masjid Moti',
      },
      localizedAddresses: {
        'urdu': 'شکارپور روڈ، سکھر',
        'sindhi': 'شڪارپور روڊ، سکر',
        'arabic': 'طريق شكاربور، سكر',
        'hindi': 'शिकारपुर रोड, सक्कर',
        'bengali': 'শিকারপুর রোড, সুক্কুর',
        'persian': 'جاده شکارپور، سوکور',
        'turkish': 'Şikarpur Yolu, Sukkur',
        'french': 'Route de Shikarpur, Sukkur',
        'indonesian': 'Jalan Shikarpur, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:15 AM',
        fajrUpdated: '31 Oct 2026',
        zuhar: '02:00 PM',
        asar: '04:45 PM',
        asarUpdated: '25 Oct 2026',
        maghrib: 'Sunset',
        isha: '07:45 PM',
        ishaUpdated: '25 Oct 2026',
        jummah: '02:30 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'jamia_masjid_khatam_e_nabuwat',
      nameKey: 'Jamia Masjid Khatam e Nabuwat',
      addressKey: 'Military Road, Sukkur',
      pin: '65432111',
      localizedNames: {
        'urdu': 'جامع مسجد ختم نبوت',
        'sindhi': 'جامع مسجد ختم نبوت',
        'arabic': 'جامع مسجد خاتم النبوة',
        'hindi': 'जामिया मस्जिद ख़त्म-ए-नबुव्वत',
        'bengali': 'জামিয়া মসজিদ খাতমে নবুওয়াত',
        'persian': 'مسجد جامع خاتم نبوت',
        'turkish': 'Cami-i Kebir Hatem-i Nübüvvet',
        'french': 'Grande Mosquée Khatam e Nabuwat',
        'indonesian': 'Masjid Jami Khatam e Nabuwat',
      },
      localizedAddresses: {
        'urdu': 'ملٹری روڈ، سکھر',
        'sindhi': 'ملٽري روڊ، سکر',
        'arabic': 'طريق ميليتري، سكر',
        'hindi': 'मिलिट्री रोड, सक्कर',
        'bengali': 'মিলিটারি রোড, সুক্কুর',
        'persian': 'جاده نظامی، سوکور',
        'turkish': 'Askeri Yolu, Sukkur',
        'french': 'Route Militaire, Sukkur',
        'indonesian': 'Jalan Militer, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:15 AM',
        fajrUpdated: '29 Oct 2026',
        zuhar: '01:15 PM',
        asar: '04:30 PM',
        asarUpdated: '25 Oct 2026',
        maghrib: 'sunset',
        isha: '07:30 PM',
        ishaUpdated: '25 Oct 2026',
        jummah: '01:15 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'madni_masjid_2',
      nameKey: 'Madni Masjid',
      addressKey: 'Street Number 7, Hamdard Society, Sukkur',
      pin: '55558989',
      localizedNames: {
        'urdu': 'مدنی مسجد',
        'sindhi': 'مدني مسجد',
        'arabic': 'مسجد مدني',
        'hindi': 'मदनी मस्जिद',
        'bengali': 'মাদানী মসজিদ',
        'persian': 'مسجد مدنی',
        'turkish': 'Medeni Camii',
        'french': 'Mosquée Madni',
        'indonesian': 'Masjid Madni',
      },
      localizedAddresses: {
        'urdu': 'گلی نمبر 7، ہمدرد سوسائٹی، سکھر',
        'sindhi': 'گھٽي نمبر 7، همدرد سوسائٽي، سکر',
        'arabic': 'شارع رقم 7، جمعية همدرد، سكر',
        'hindi': 'गली नंबर 7, हमदर्द सोसाइटी, सक्कर',
        'bengali': 'রাস্তা নং ৭, হামদর্দ সোসাইটি, সুক্কুর',
        'persian': 'خیابان شماره ۷، شهرک همدرد، سوکور',
        'turkish': 'Sokak No: 7, Hamdard Topluluğu, Sukkur',
        'french': 'Rue numéro 7, Société Hamdard, Sukkur',
        'indonesian': 'Jalan Nomor 7, Hamdard Society, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:15 AM',
        fajrUpdated: '02 Nov 2026',
        zuhar: '01:30 PM',
        asar: '04:30 PM',
        asarUpdated: '26 Oct 2026',
        maghrib: 'sunset',
        isha: '07:30 PM',
        ishaUpdated: '26 Oct 2026',
        jummah: '01:30 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'elahi_masjid',
      nameKey: 'Elahi Masjid',
      addressKey: 'Makrani Muhallah, Sukkur',
      pin: '32100000',
      localizedNames: {
        'urdu': 'الہٰی مسجد',
        'sindhi': 'الهي مسجد',
        'arabic': 'مسجد إلهي',
        'hindi': 'इलाही मस्जिद',
        'bengali': 'এলাহী মসজিদ',
        'persian': 'مسجد الهی',
        'turkish': 'İlahi Camii',
        'french': 'Mosquée Elahi',
        'indonesian': 'Masjid Elahi',
      },
      localizedAddresses: {
        'urdu': 'مکرانی محلہ، سکھر',
        'sindhi': 'مڪراني محلو، سکر',
        'arabic': 'محلة مكراني، سكر',
        'hindi': 'मकरानी मोहल्ला, सक्कर',
        'bengali': 'মাকরানি মহল্লা, সুক্কুর',
        'persian': 'محله مکرانی، سوکور',
        'turkish': 'Makrani Mahallesi, Sukkur',
        'french': 'Quartier Makrani, Sukkur',
        'indonesian': 'Wilayah Makrani, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:15 AM',
        fajrUpdated: '31 Oct 2026',
        zuhar: '01:30 PM',
        asar: '04:30 PM',
        asarUpdated: '25 Oct 2026',
        maghrib: 'Sunset',
        isha: '07:15 PM',
        ishaUpdated: '02 Nov 2026',
        jummah: '01:30 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'jamia_masjid_usman',
      nameKey: 'Jamia Masjid Usman',
      addressKey: 'Sheikh Shaheen Road, Sukkur',
      pin: '88001100',
      localizedNames: {
        'urdu': 'جامع مسجد عثمان',
        'sindhi': 'جامع مسجد عثمان',
        'arabic': 'جامع مسجد عثمان',
        'hindi': 'जामिया मस्जिद उसमान',
        'bengali': 'জামিয়া মসজিদ উসমান',
        'persian': 'مسجد جامع عثمان',
        'turkish': 'Cami-i Kebir Osman',
        'french': 'Grande Mosquée Ousmane',
        'indonesian': 'Masjid Jami Utsman',
      },
      localizedAddresses: {
        'urdu': 'شیخ شہین روڈ، سکھر',
        'sindhi': 'شيخ شهين روڊ، سکر',
        'arabic': 'طريق الشيخ شهين، سكر',
        'hindi': 'शेख़ शहीन रोड, सक्कर',
        'bengali': 'শেখ শহীন রোড, সুক্কুর',
        'persian': 'جاده شیخ شهین، سوکور',
        'turkish': 'Şeyh Shaheen Yolu, Sukkur',
        'french': 'Route Cheikh Shaheen, Sukkur',
        'indonesian': 'Jalan Sheikh Shaheen, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:05 AM',
        fajrUpdated: '02 Nov 2026',
        zuhar: '01:15 PM',
        asar: '04:45 PM',
        asarUpdated: '25 Oct 2026',
        maghrib: 'Sunset',
        isha: '07:30 PM',
        ishaUpdated: '25 Oct 2026',
        jummah: '01:15 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'jamia_anwaar_masjid',
      nameKey: 'Jamia Anwaar Masjid',
      addressKey: 'Shamsabad, Sukkur',
      pin: '77700888',
      localizedNames: {
        'urdu': 'جامعہ انوار مسجد',
        'sindhi': 'جامعہ انوار مسجد',
        'arabic': 'مسجد جامع أنوار',
        'hindi': 'जामिया अनवार मस्जिद',
        'bengali': 'জামিয়া আনোয়ার মসজিদ',
        'persian': 'مسجد جامع انوار',
        'turkish': 'Envar Camii',
        'french': 'Mosquée Jamia Anwaar',
        'indonesian': 'Masjid Jamia Anwaar',
      },
      localizedAddresses: {
        'urdu': 'شمس آباد، سکھر',
        'sindhi': 'شمس آباد، سکر',
        'arabic': 'شمس آباد، سَكَر',
        'hindi': 'शम्साबाद, सुक्कुर',
        'bengali': 'শামসাবাদ, সুক্কুর',
        'persian': 'شمس‌آباد، سکر',
        'turkish': 'Şemsabad, Sukkur',
        'french': 'Shamsabad, Sukkur',
        'indonesian': 'Shamsabad, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:10 AM',
        fajrUpdated: '25 Oct 2026',
        zuhar: '02:00 PM',
        asar: '04:30 PM',
        asarUpdated: '30 Oct 2026',
        maghrib: 'Sunset',
        isha: '07:30 PM',
        ishaUpdated: '30 Oct 2026',
        jummah: '01:45 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'subhan_masjid',
      nameKey: 'Subhan Masjid',
      addressKey: 'Shikarpur Road, Sukkur',
      pin: '66770011',
      localizedNames: {
        'urdu': 'سبحان مسجد',
        'sindhi': 'سبحان مسجد',
        'arabic': 'مسجد سبحان',
        'hindi': 'सुभान मस्जिद',
        'bengali': 'সুবহান মসজিদ',
        'persian': 'مسجد سبحان',
        'turkish': 'Subhan Camii',
        'french': 'Mosquée Subhan',
        'indonesian': 'Masjid Subhan',
      },
      localizedAddresses: {
        'urdu': 'شکارپور روڈ، سکھر',
        'sindhi': 'شڪارپور روڊ، سکر',
        'arabic': 'طريق شكاربور، سكر',
        'hindi': 'शिकारपुर रोड, सुक्कुर',
        'bengali': 'শিকারপুর রোড, সুক্কুর',
        'persian': 'جاده شکارپور، سکر',
        'turkish': 'Şikarpur Yolu, Sukkur',
        'french': 'Route de Shikarpur, Sukkur',
        'indonesian': 'Jalan Shikarpur, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '05:20 AM',
        fajrUpdated: '31 Oct 2026',
        zuhar: '01:00 PM',
        asar: '04:15 PM',
        asarUpdated: '31 Oct 2026',
        maghrib: 'Sunset',
        isha: '07:10 PM',
        ishaUpdated: '31 Oct 2026',
        jummah: '02:00 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'momin_masjid',
      nameKey: 'Momin Masjid',
      addressKey: 'Bagh-e-Hayat Ali Shah, Sukkur',
      pin: '11009911',
      localizedNames: {
        'urdu': 'مومن مسجد',
        'sindhi': 'مومن مسجد',
        'arabic': 'مسجد مؤمن',
        'hindi': 'मोमिन मस्जिद',
        'bengali': 'মোমিন মসজিদ',
        'persian': 'مسجد مؤمن',
        'turkish': 'Mümin Camii',
        'french': 'Mosquée Momin',
        'indonesian': 'Masjid Momin',
      },
      localizedAddresses: {
        'urdu': 'باغ حیات علی شاہ، سکھر',
        'sindhi': 'باغ حيات علي شاهه، سکر',
        'arabic': 'حديقة حيات علي شاه، سكر',
        'hindi': 'बाग़-ए-हयात अली शाह, सुक्कुर',
        'bengali': 'বাগে হায়াত আলী শাহ, সুক্কুর',
        'persian': 'باغ حیات علی شاه، سکر',
        'turkish': 'Bağ-ı Hayat Ali Şah, Sukkur',
        'french': 'Bagh-e-Hayat Ali Shah, Sukkur',
        'indonesian': 'Bagh-e-Hayat Ali Shah, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:15 AM',
        fajrUpdated: '03 Nov 2026',
        zuhar: '01:30 PM',
        asar: '04:30 PM',
        asarUpdated: '25 Oct 2026',
        maghrib: 'Sunset',
        isha: '08:00 PM',
        ishaUpdated: '03 Nov 2026',
        jummah: '01:45 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'jama_masjid_bilal_2',
      nameKey: 'Jama Masjid Bilal',
      addressKey: 'Bihar Colony, Sukkur',
      pin: '56781234',
      localizedNames: {
        'urdu': 'جامع مسجد بلال',
        'sindhi': 'جامع مسجد بلال',
        'arabic': 'جامع مسجد بلال',
        'hindi': 'जामा मस्जिद बिलाल',
        'bengali': 'জামে মসজিদ বিলাল',
        'persian': 'مسجد جامع بلال',
        'turkish': 'Bilal Camii',
        'french': 'Grande Mosquée Bilal',
        'indonesian': 'Masjid Jami Bilal',
      },
      localizedAddresses: {
        'urdu': 'بہار کالونی، سکھر',
        'sindhi': 'بهار ڪالوني، سکر',
        'arabic': 'حي بهار، سكر',
        'hindi': 'बिहार कॉलोनी, सुक्कुर',
        'bengali': 'বিহার কলোনি, সুক্কুর',
        'persian': 'شهرک بهار، سکر',
        'turkish': 'Bihar Mahallesi, Sukkur',
        'french': 'Quartier Bihar Colony, Sukkur',
        'indonesian': 'Bihar Colony, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:10 AM',
        fajrUpdated: '26 Oct 2026',
        zuhar: '02:00 PM',
        asar: '04:30 PM',
        asarUpdated: '26 Oct 2026',
        maghrib: 'sunset',
        isha: '07:30 PM',
        ishaUpdated: '25 Oct 2026',
        jummah: '01:30 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'jama_masjid_gulzar_e_habib',
      nameKey: 'Jama Masjid Gulzar-e-Habib ﷺ',
      addressKey: 'Hamdard Society, Sukkur',
      pin: '00339966',
      localizedNames: {
        'urdu': 'جامع مسجد گلزارِ حبیب ﷺ',
        'sindhi': 'جامع مسجد گلزارِ حبيب ﷺ',
        'arabic': 'جامع مسجد گلزار حبيب ﷺ',
        'hindi': 'जामा मस्जिद गुलज़ार-ए-हबीब ﷺ',
        'bengali': 'জামে মসজিদ গুলজারে হাবিব ﷺ',
        'persian': 'مسجد جامع گلزار حبیب ﷺ',
        'turkish': 'Gülzar-ı Habib Camii ﷺ',
        'french': 'Grande Mosquée Gulzar-e-Habib ﷺ',
        'indonesian': 'Masjid Jami Gulzar-e-Habib ﷺ',
      },
      localizedAddresses: {
        'urdu': 'ہمدرد سوسائٹی، سکھر',
        'sindhi': 'همدرد سوسائٽي، سکر',
        'arabic': 'جمعية همدرد، سكر',
        'hindi': 'हमदर्द सोसाइटी, सुक्कुर',
        'bengali': 'হামদর্দ সোসাইটি, সুক্কুর',
        'persian': 'شهرک همدرد، سکر',
        'turkish': 'Hamdard Sitesi, Sukkur',
        'french': 'Hamdard Society, Sukkur',
        'indonesian': 'Hamdard Society, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:10 AM',
        fajrUpdated: '04 Nov 2026',
        zuhar: '01:30 PM',
        zuharUpdated: '26 Oct 2026',
        asar: '04:30 PM',
        asarUpdated: '26 Oct 2026',
        maghrib: 'Sunset',
        isha: '07:30 PM',
        ishaUpdated: '26 Oct 2026',
        jummah: '02:00 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'glamour_banglows_jaa_e_namaz',
      nameKey: 'Glamour Banglows (Jaa-e-Namaz)',
      addressKey: 'Glamour Banglows, Bunder Road, Sukkur',
      pin: '55599911',
      localizedNames: {
        'urdu': 'گلیمر بنگلوز (جائے نماز)',
        'sindhi': 'گليمر بنگلوز (جاءِ نماز)',
        'arabic': 'مصلى غلامور بنغلوز',
        'hindi': 'ग्लैमर बंग्लोज़ (जा-ए-नमाज़)',
        'bengali': 'গ্ল্যামার বাংলো (জায়ে নামাজ)',
        'persian': 'گلمور بنگلوز (جای نماز)',
        'turkish': 'Glamour Banglows (Namazgah)',
        'french': 'Glamour Banglows (Salle de Prière)',
        'indonesian': 'Glamour Banglows (Musholla)',
      },
      localizedAddresses: {
        'urdu': 'گلیمر بنگلوز، بندر روڈ، سکھر',
        'sindhi': 'گليمر بنگلوز، بندر روڊ، سکر',
        'arabic': 'غلامور بنغلوز، طريق بندر، سكر',
        'hindi': 'ग्लैमर बंग्लोज़, बंदर रोड, सुक्कुर',
        'bengali': 'গ্ল্যামার বাংলো, বন্দর রোড, সুক্কুর',
        'persian': 'گلمور بنگلوز، جاده بندر، سکر',
        'turkish': 'Glamour Banglows, Bunder Yolu, Sukkur',
        'french': 'Glamour Banglows, Route de Bunder, Sukkur',
        'indonesian': 'Glamour Banglows, Jalan Bunder, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:10 AM',
        fajrUpdated: '03 Nov 2026',
        zuhar: '01:00 PM',
        zuharUpdated: '26 Oct 2026',
        asar: '04:30 PM',
        asarUpdated: '04 Nov 2026',
        maghrib: 'Sunset',
        isha: '07:15 PM',
        ishaUpdated: '03 Nov 2026',
        jummah: '',
        jummahNoteUr: 'نمازِ جمعہ ادا نہیں کی جاتی۔',
      ),
    ),
    JamaatMasjidInfo(
      id: 'bab_e_rehmat',
      nameKey: 'Masjid Bab e Rehmat',
      addressKey: 'Bunder Road Sukkur',
      pin: '89892929',
      localizedNames: {
        'urdu': 'مسجد بابِ رحمت',
        'sindhi': 'مسجد باب رحمت',
        'arabic': 'مسجد باب الرحمة',
        'hindi': 'मस्जिद बाब-ए-रहमत',
        'bengali': 'মসজিদ বাব ই রহমত',
        'persian': 'مسجد باب رحمت',
        'turkish': 'Bab-ı Rahmet Camii',
        'french': 'Mosquée Bab e Rehmat',
        'indonesian': 'Masjid Bab e Rehmat',
      },
      localizedAddresses: {
        'urdu': 'بندر روڈ سکھر',
        'sindhi': 'بندر روڊ سکر',
        'arabic': 'شارع بندر سكر',
        'hindi': 'बंदर रोड सुक्कुर',
        'bengali': 'বান্দর রোড সুক্কুর',
        'persian': 'جاده بندر سوکور',
        'turkish': 'Bunder Yolu Sukkur',
        'french': 'Bunder Road Sukkur',
        'indonesian': 'Bunder Road Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:15 AM',
        fajrUpdated: '02 Nov 2026',
        zuhar: '02:15 PM',
        asar: '04:45 PM',
        asarUpdated: '26 Oct 2026',
        maghrib: 'sunset',
        isha: '09:00 PM',
        ishaUpdated: '26 Oct 2026',
        jummah: '02:45 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'memon_masjid',
      nameKey: 'Memon Masjid',
      addressKey: 'Thalla, Sukkur',
      pin: '77700111',
      localizedNames: {
        'urdu': 'میمن مسجد',
        'sindhi': 'ميمڻ مسجد',
        'arabic': 'مسجد ميمون',
        'hindi': 'मेमन मस्जिद',
        'bengali': 'মেমন মসজিদ',
        'persian': 'مسجد ممون',
        'turkish': 'Memon Camii',
        'french': 'Mosquée Memon',
        'indonesian': 'Masjid Memon',
      },
      localizedAddresses: {
        'urdu': 'تھلہ، سکھر',
        'sindhi': 'ٿلو، سکر',
        'arabic': 'تَلَّة، سكر',
        'hindi': 'थल्ला, सुक्कुर',
        'bengali': 'থাল্লা, সুক্কুর',
        'persian': 'ثلا، سوکور',
        'turkish': 'Thalla, Sukkur',
        'french': 'Thalla, Sukkur',
        'indonesian': 'Thalla, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:10 AM',
        fajrUpdated: '03 Nov 2026',
        zuhar: '01:45 PM',
        asar: '04:30 PM',
        asarUpdated: '27 Oct 2026',
        maghrib: 'Sunset',
        isha: '07:10 PM',
        ishaUpdated: '02 Nov 2026',
        jummah: '02:15 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'qadeemi_jama_masjid',
      nameKey: 'Qadeemi Jama Masjid',
      addressKey: 'Victoria Market Ghanta Ghar Sukkur',
      pin: '33300444',
      localizedNames: {
        'urdu': 'قدیمی جامع مسجد',
        'sindhi': 'قديـمي جامع مسجد',
        'arabic': 'الجامع القديم',
        'hindi': 'क़दीमी जामा मस्जिद',
        'bengali': 'কাদিমি জামে মসজিদ',
        'persian': 'مسجد جامع قدیمی',
        'turkish': 'Kadeemi Cuma Camii',
        'french': 'Mosquée Jama Qadeemi',
        'indonesian': 'Masjid Qadeemi Jama',
      },
      localizedAddresses: {
        'urdu': 'وکٹوریہ مارکیٹ گھنٹہ گھر سکھر',
        'sindhi': 'وڪٽوريا مارڪيٽ گھنٽا گھر سکر',
        'arabic': 'سوق فيكتوريا غنتا گھر سكر',
        'hindi': 'विक्टोरिया मार्केट घंटा घर सुक्कुर',
        'bengali': 'ভিক্টোরিয়া মার্কেট ঘণ্টা ঘর সুক্কুর',
        'persian': 'بازار ویکتوریا گھنتا گھر سوکور',
        'turkish': 'Victoria Market Ghanta Ghar Sukkur',
        'french': 'Victoria Market Ghanta Ghar Sukkur',
        'indonesian': 'Victoria Market Ghanta Ghar Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:20 AM',
        fajrUpdated: '04 Nov 2026',
        zuhar: '02:00 PM',
        asar: '04:30 PM',
        asarUpdated: '27 Oct 2026',
        maghrib: 'Sunset',
        isha: '07:30 PM',
        ishaUpdated: '27 Oct 2026',
        jummah: '02:00 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'hanfia_masjid',
      nameKey: 'Hanfia Masjid',
      addressKey: 'Ghareebabad, Sukkur',
      pin: '00993399',
      localizedNames: {
        'urdu': 'حنفیہ مسجد',
        'sindhi': 'حنفيہ مسجد',
        'arabic': 'مسجد الحنفية',
        'hindi': 'हनफिया मस्जिद',
        'bengali': 'হানাফিয়া মসজিদ',
        'persian': 'مسجد حنفیه',
        'turkish': 'Hanefiye Camii',
        'french': 'Mosquée Hanfia',
        'indonesian': 'Masjid Hanfia',
      },
      localizedAddresses: {
        'urdu': 'غریب آباد، سکھر',
        'sindhi': 'غريب آباد، سکر',
        'arabic': 'غريب آباد، سكر',
        'hindi': 'गरीब आबाद, सुक्कुर',
        'bengali': 'গরীবাবাদ, সুক্কুর',
        'persian': 'غریب‌آباد، سوکور',
        'turkish': 'Ghareebabad, Sukkur',
        'french': 'Ghareebabad, Sukkur',
        'indonesian': 'Ghareebabad, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:00 AM',
        fajrUpdated: '27 Oct 2026',
        zuhar: '02:00 PM',
        asar: '04:30 PM',
        asarUpdated: '04 Nov 2026',
        maghrib: 'Sunset',
        isha: '07:30 PM',
        ishaUpdated: '27 Oct 2026',
        jummah: '02:00 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'chand_masjid',
      nameKey: 'Chand Masjid',
      addressKey: 'Chimta Gali, Nishtar Road, Sukkur',
      pin: '56700567',
      localizedNames: {
        'urdu': 'چاند مسجد',
        'sindhi': 'چنڊ مسجد',
        'arabic': 'مسجد جاند',
        'hindi': 'चाँद मस्जिद',
        'bengali': 'চান্দ মসজিদ',
        'persian': 'مسجد چاند',
        'turkish': 'Chand Camii',
        'french': 'Mosquée Chand',
        'indonesian': 'Masjid Chand',
      },
      localizedAddresses: {
        'urdu': 'چمٹا گلی، نشتر روڈ، سکھر',
        'sindhi': 'چمٽا گلي، نشتر روڊ، سکر',
        'arabic': 'زقاق چمتا، شارع نشتر، سكر',
        'hindi': 'चिमटा गली, निश्तर रोड, सुक्कुर',
        'bengali': 'চিমটা গলি, নিশতার রোড, সুক্কুর',
        'persian': 'کوچه چمٹا، جاده نشتر، سوکور',
        'turkish': 'Chimta Gali, Nishtar Road, Sukkur',
        'french': 'Chimta Gali, Nishtar Road, Sukkur',
        'indonesian': 'Chimta Gali, Nishtar Road, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:15 AM',
        fajrUpdated: '04 Nov 2026',
        zuhar: '01:30 PM',
        asar: '04:45 PM',
        asarUpdated: '27 Oct 2026',
        maghrib: 'Sunset',
        isha: '08:00 PM',
        ishaUpdated: '27 Oct 2026',
        jummah: '01:00 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'makkah_masjid',
      nameKey: 'Makkah Masjid',
      addressKey: 'Dhak Road, Sukkur',
      pin: '12399123',
      localizedNames: {
        'urdu': 'مکہ مسجد',
        'sindhi': 'مڪه مسجد',
        'arabic': 'مسجد مكة',
        'hindi': 'मक्का मस्जिद',
        'bengali': 'মক্কা মসজিদ',
        'persian': 'مسجد مکه',
        'turkish': 'Mekke Camii',
        'french': 'Mosquée Makkah',
        'indonesian': 'Masjid Makkah',
      },
      localizedAddresses: {
        'urdu': 'ڈھک روڈ، سکھر',
        'sindhi': 'ڍڪ روڊ، سکر',
        'arabic': 'شارع دك، سكر',
        'hindi': 'धक रोड, सुक्कुर',
        'bengali': 'ধক রোড, সুক্কুর',
        'persian': 'جاده ڈھک، سوکور',
        'turkish': 'Dhak Yolu, Sukkur',
        'french': 'Route Dhak, Sukkur',
        'indonesian': 'Jalan Dhak, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '05:40 AM',
        fajrUpdated: '28 Oct 2026',
        zuhar: '01:00 PM',
        asar: '04:10 PM',
        asarUpdated: '05 Nov 2026',
        maghrib: 'Sunset',
        isha: '07:05 PM',
        ishaUpdated: '05 Nov 2026',
        jummah: '12:55 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'raheem_masjid',
      nameKey: 'Raheem Masjid',
      addressKey: 'New Goth, Sukkur',
      pin: '99997777',
      localizedNames: {
        'urdu': 'رحیم مسجد',
        'sindhi': 'رحيم مسجد',
        'arabic': 'مسجد رحيم',
        'hindi': 'रहीम मस्जिद',
        'bengali': 'রহিম মসজিদ',
        'persian': 'مسجد رحیم',
        'turkish': 'Rahim Camii',
        'french': 'Mosquée Raheem',
        'indonesian': 'Masjid Raheem',
      },
      localizedAddresses: {
        'urdu': 'نواں گوٹھ، سکھر',
        'sindhi': 'نئون گهوٽ، سکر',
        'arabic': 'قرية نوان، سكر',
        'hindi': 'नवां गोठ, सुक्कुर',
        'bengali': 'নওয়ান গোঠ, সুক্কুর',
        'persian': 'نوان گوت، سکر',
        'turkish': 'New Goth, Sukkur',
        'french': 'New Goth, Sukkur',
        'indonesian': 'New Goth, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:15 AM',
        fajrUpdated: '04 Nov 2026',
        zuhar: '12:50 PM',
        asar: '04:15 PM',
        asarUpdated: '04 Nov 2026',
        maghrib: 'Sunset',
        isha: '07:05 PM',
        ishaUpdated: '04 Nov 2026',
        jummah: '01:00 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'jama_masjid_siddique_akbar_ghori',
      nameKey: 'Jama Masjid Siddique Akbar Ghori',
      addressKey: 'Military Road, Sukkur',
      pin: '67678787',
      localizedNames: {
        'urdu': 'جامع مسجد صدیق اکبر غوری',
        'sindhi': 'جامع مسجد صديق اكبر غوري',
        'arabic': 'جامع الصديق أكبر غوري',
        'hindi': 'जामा मस्जिद सिद्दीक अकबर غوری',
        'bengali': 'জামে মসজিদ সিদ্দিক আকবর ঘোরী',
        'persian': 'مسجد جامع صدیق اکبر غوری',
        'turkish': 'Sıddık Akbar Ghori Cuma Camii',
        'french': 'Mosquée Jama Siddique Akbar Ghori',
        'indonesian': 'Masjid Jama Siddique Akbar Ghori',
      },
      localizedAddresses: {
        'urdu': 'ملٹری روڈ، سکھر',
        'sindhi': 'ملٽري روڊ، سکر',
        'arabic': 'شارع العسكري، سكر',
        'hindi': 'मिलिट्री रोड, सुक्कुर',
        'bengali': 'মিলিটারি রোড, সুক্কুর',
        'persian': 'جاده نظامی، سکر',
        'turkish': 'Military Road, Sukkur',
        'french': 'Military Road, Sukkur',
        'indonesian': 'Military Road, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:10 AM',
        fajrUpdated: '28 Oct 2026',
        zuhar: '01:30 PM',
        asar: '04:30 PM',
        asarUpdated: '28 Oct 2026',
        maghrib: 'sunset',
        isha: '07:30 PM',
        ishaUpdated: '28 Oct 2026',
        jummah: '01:30 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'jamia_masjid_abbas',
      nameKey: 'Jamia Masjid Abbas',
      addressKey: 'Revenue Colony, 100 Feet Road, Sukkur',
      pin: '44774477',
      localizedNames: {
        'urdu': 'جامعہ مسجد عباس',
        'sindhi': 'جامعہ مسجد عباس',
        'arabic': 'مسجد جامعة العباس',
        'hindi': 'जामिया मस्जिद अब्बास',
        'bengali': 'জামিয়া মসজিদ আব্বাস',
        'persian': 'مسجد جامعۀ عباس',
        'turkish': 'Abbas Cuma Camii',
        'french': 'Mosquée Jamia Abbas',
        'indonesian': 'Masjid Jamia Abbas',
      },
      localizedAddresses: {
        'urdu': 'ریونیو کالونی، 100 فٹ روڈ، سکھر',
        'sindhi': 'روينيو ڪالوني، 100 فوٽ روڊ، سکر',
        'arabic': 'حي الإيرادات، شارع 100 قدم، سكر',
        'hindi': 'रेवेन्यू कॉलोनी, 100 फीट रोड, सुक्कुर',
        'bengali': 'রেভিনিউ কলোনি, ১০০ ফিট রোড, সুক্কুর',
        'persian': 'شهرک ریونیو، جاده ۱۰۰ فوتی، سکر',
        'turkish': 'Revenue Colony, 100 Feet Road, Sukkur',
        'french': 'Revenue Colony, 100 Feet Road, Sukkur',
        'indonesian': 'Revenue Colony, 100 Feet Road, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:10 AM',
        fajrUpdated: '28 Oct 2026',
        zuhar: '01:15 PM',
        asar: '04:30 PM',
        asarUpdated: '31 Oct 2026',
        maghrib: 'Sunset',
        isha: '07:30 PM',
        ishaUpdated: '28 Oct 2026',
        jummah: '01:15 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'farooqi_masjid',
      nameKey: 'Farooqi Masjid',
      addressKey: 'Bhutta Gali, Sarafa Bazar, Sukkur',
      pin: '11771188',
      localizedNames: {
        'urdu': 'فاروقی مسجد',
        'sindhi': 'فاروقي مسجد',
        'arabic': 'مسجد الفاروقي',
        'hindi': 'फारूकी मस्जिद',
        'bengali': 'ফারুকী মসজিদ',
        'persian': 'مسجد فاروقی',
        'turkish': 'Farooqi Camii',
        'french': 'Mosquée Farooqi',
        'indonesian': 'Masjid Farooqi',
      },
      localizedAddresses: {
        'urdu': 'بھٹہ گلی، صرافہ بازار، سکھر',
        'sindhi': 'ڀٽا گلي، صرافہ بازار، سکر',
        'arabic': 'زقاق بوتا، سوق الصرافة، سكر',
        'hindi': 'भट्टा गली, सराफा बाजार, सुक्कुर',
        'bengali': 'ভট্টা গলি, সরাফা বাজার, সুক্কুর',
        'persian': 'کوچه بھٹا، بازار صرافان، سکر',
        'turkish': 'Bhutta Gali, Sarafa Bazar, Sukkur',
        'french': 'Bhutta Gali, Sarafa Bazar, Sukkur',
        'indonesian': 'Bhutta Gali, Sarafa Bazar, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '05:45 AM',
        fajrUpdated: '28 Oct 2026',
        zuhar: '01:15 PM',
        asar: '04:10 PM',
        asarUpdated: '02 Nov 2026',
        maghrib: 'Sunset',
        isha: '07:05 PM',
        ishaUpdated: '05 Nov 2026',
        jummah: '01:15 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'muhammadi_masjid',
      nameKey: 'Muhammadi Masjid',
      addressKey: 'Hamdard Society, Sukkur',
      pin: '45600456',
      localizedNames: {
        'urdu': 'محمدی مسجد',
        'sindhi': 'محمدي مسجد',
        'arabic': 'مسجد المحمدي',
        'hindi': 'मोहम्मदी मस्जिद',
        'bengali': 'মোহাম্মদী মসজিদ',
        'persian': 'مسجد محمدی',
        'turkish': 'Muhammadi Camii',
        'french': 'Mosquée Muhammadi',
        'indonesian': 'Masjid Muhammadi',
      },
      localizedAddresses: {
        'urdu': 'ہمدرد سوسائٹی، سکھر',
        'sindhi': 'همدرد سوسائٽي، سکر',
        'arabic': 'جمعية همدرد، سكر',
        'hindi': 'हमदर्द सोसाइटी, सुक्कुर',
        'bengali': 'হামদর্দ সোসাইটি, সুক্কুর',
        'persian': 'جامعه همدرد، سکر',
        'turkish': 'Hamdard Society, Sukkur',
        'french': 'Hamdard Society, Sukkur',
        'indonesian': 'Hamdard Society, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:05 AM',
        fajrUpdated: '03 Nov 2026',
        zuhar: '01:30 PM',
        asar: '04:30 PM',
        asarUpdated: '30 Oct 2026',
        maghrib: 'Sunset',
        isha: '07:30 PM',
        ishaUpdated: '30 Oct 2026',
        jummah: '01:30 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'yusuf_masjid',
      nameKey: 'Yusuf Masjid (Tableeghi Markaz)',
      addressKey: 'Shikarpur Road, Sukkur',
      pin: '01020304',
      localizedNames: {
        'urdu': 'یوسف مسجد (تبلیغی مرکز)',
        'sindhi': 'يوسف مسجد (تبليغي مرڪز)',
        'arabic': 'مسجد يوسف (المركز التبليغي)',
        'hindi': 'युसूफ मस्जिद (तब्लीगी मरकज़)',
        'bengali': 'ইউসুফ মসজিদ (তাবলিগী মারকাজ)',
        'persian': 'مسجد یوسف (مرکز تبلیغی)',
        'turkish': 'Yusuf Camii (Tableeghi Markaz)',
        'french': 'Mosquée Yusuf (Tableeghi Markaz)',
        'indonesian': 'Masjid Yusuf (Tableeghi Markaz)',
      },
      localizedAddresses: {
        'urdu': 'شکارپور روڈ، سکھر',
        'sindhi': 'شڪارپور روڊ، سکر',
        'arabic': 'شارع شكاربور، سكر',
        'hindi': 'शिकारपुर रोड, सुक्कुर',
        'bengali': 'শিকারপুর রোড, সুক্কুর',
        'persian': 'جاده شکارپور، سکر',
        'turkish': 'Shikarpur Road, Sukkur',
        'french': 'Shikarpur Road, Sukkur',
        'indonesian': 'Shikarpur Road, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:10 AM',
        fajrUpdated: '30 Oct 2026',
        zuhar: '02:00 PM',
        zuharUpdated: '30 Oct 2026',
        asar: '04:30 PM',
        asarUpdated: '30 Oct 2026',
        maghrib: 'sunset',
        isha: '07:30 PM',
        ishaUpdated: '30 Oct 2026',
        ishaNoteUr: 'شبِ جمعہ عشاء کی جماعت مقررہ وقت سے کچھ دیر بعد ادا کی جاتی ہے۔',
        jummah: '01:30 PM',
        jummahUpdated: '30 Oct 2026',
      ),
    ),
    JamaatMasjidInfo(
      id: 'masjid_anwar_paracha',
      nameKey: 'Masjid Anwar Paracha',
      addressKey: 'Behind Anwar Paracha Hospital, Takkar Road, Sukkur',
      pin: '10203040',
      localizedNames: {
        'urdu': 'مسجد انور پراچہ',
        'sindhi': 'مسجد انور پراچهه',
        'arabic': 'مسجد أنور باراكا',
        'hindi': 'मस्जिद अनवर पराचा',
        'bengali': 'মসজিদ আনোয়ার পারাচা',
        'persian': 'مسجد انور پراچه',
        'turkish': 'Anwar Paracha Camii',
        'french': 'Mosquée Anwar Paracha',
        'indonesian': 'Masjid Anwar Paracha',
      },
      localizedAddresses: {
        'urdu': 'انور پراچہ ہسپتال کے پیچھے، ٹکر روڈ، سکھر',
        'sindhi': 'انور پراچهه اسپتال جي پويان، ٽڪر روڊ، سکر',
        'arabic': 'خلف مستشفى أنور باراكا، شارع تكر، سكر',
        'hindi': 'अनवर पराचा अस्पताल के पीछे, टक्कर रोड, सुक्कुर',
        'bengali': 'আনোয়ার পারাচা হাসপাতালের পেছনে, টক্কর রোড, সুক্কুর',
        'persian': 'پشت بیمارستان انور پراچه، جاده تکّر، سکر',
        'turkish': 'Behind Anwar Paracha Hospital, Takkar Road, Sukkur',
        'french': 'Behind Anwar Paracha Hospital, Takkar Road, Sukkur',
        'indonesian': 'Behind Anwar Paracha Hospital, Takkar Road, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:15 AM',
        fajrUpdated: '05 Nov 2026',
        zuhar: '01:30 PM',
        asar: '04:30 PM',
        asarUpdated: '31 Oct 2026',
        maghrib: 'Sunset',
        isha: '07:30 PM',
        ishaUpdated: '31 Oct 2026',
        jummah: '01:45 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'jama_masjid_khalique_ahmed',
      nameKey: 'Jama Masjid Khalique Ahmed',
      addressKey: 'Sector 3, Arif Builder, Sukkur',
      pin: '33000033',
      localizedNames: {
        'urdu': 'جامع مسجد خلیق احمد',
        'sindhi': 'جامع مسجد خليق احمد',
        'arabic': 'مسجد جامع خليق أحمد',
        'hindi': 'जामा मस्जिद खलीक अहमद',
        'bengali': 'জামে মসজিদ খালিক আহমেদ',
        'persian': 'مسجد جامع خلیق احمد',
        'turkish': 'Khalique Ahmed Cuma Camii',
        'french': 'Mosquée Jama Masjid Khalique Ahmed',
        'indonesian': 'Masjid Jama Khalique Ahmed',
      },
      localizedAddresses: {
        'urdu': 'سیکٹر 3، عارف بلڈر، سکھر',
        'sindhi': 'سيڪٽر 3، عارف بلڊر، سکر',
        'arabic': 'القطاع 3، عارف بيلدر، سكر',
        'hindi': 'सेक्टर 3, आरिफ बिल्डर, सुक्कुर',
        'bengali': 'সেক্টর ৩, আরিফ বিল্ডার, সুক্কুর',
        'persian': 'سکتور 3، عارف بیلدر، سکر',
        'turkish': 'Sector 3, Arif Builder, Sukkur',
        'french': 'Sector 3, Arif Builder, Sukkur',
        'indonesian': 'Sector 3, Arif Builder, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:15 AM',
        fajrUpdated: '03 Nov 2026',
        zuhar: '02:15 PM',
        zuharUpdated: '03 Nov 2026',
        asar: '04:45 PM',
        asarUpdated: '03 Nov 2026',
        maghrib: 'Sunset',
        isha: '07:30 PM',
        ishaUpdated: '03 Nov 2026',
        jummah: '01:15 PM',
        jummahUpdated: '03 Nov 2026',
      ),
    ),
    JamaatMasjidInfo(
      id: 'jama_masjid_shabir',
      nameKey: 'Jama Masjid Shabir',
      addressKey: 'Infront of Indoor (wards), Civil Hospital, Sukkur',
      pin: '67111167',
      localizedNames: {
        'urdu': 'جامع مسجد شبیر',
        'sindhi': 'جامع مسجد شبير',
        'arabic': 'جامع شبير',
        'hindi': 'जामा मस्जिद शब्बीर',
        'bengali': 'জামে মসজিদ সাব্বির',
        'persian': 'مسجد جامع شبیر',
        'turkish': 'Shabir Cuma Camii',
        'french': 'Mosquée Jama Masjid Shabir',
        'indonesian': 'Masjid Jama Shabir',
      },
      localizedAddresses: {
        'urdu': 'انڈور (وارڈز) کے سامنے، سول ہسپتال، سکھر',
        'sindhi': 'انڊور (وارڊز) جي سامهون، سول اسپتال، سکر',
        'arabic': 'أمام الأقسام الداخلية، المستشفى المدني، سكر',
        'hindi': 'इनडोर (वार्ड्स) के सामने, सिविल अस्पताल, सुक्कुर',
        'bengali': 'ইনডোর (ওয়ার্ডস)-এর সামনে, সিভিল হাসপাতাল, সুক্কুর',
        'persian': 'روبروی بخش‌های داخلی، بیمارستان مدنی، سکر',
        'turkish': 'Infront of Indoor (wards), Civil Hospital, Sukkur',
        'french': 'Infront of Indoor (wards), Civil Hospital, Sukkur',
        'indonesian': 'Infront of Indoor (wards), Civil Hospital, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:10 AM',
        fajrUpdated: '31 Oct 2026',
        zuhar: '02:00 PM',
        asar: '04:30 PM',
        asarUpdated: '31 Oct 2026',
        maghrib: 'sunset',
        isha: '07:30 PM',
        ishaUpdated: '31 Oct 2026',
        jummah: '01:00 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'jama_masjid_baag_e_rasool',
      nameKey: 'Jama Masjid Baag-e-Rasool (ﷺ)',
      addressKey: 'Kumhaar Para, Sukkur',
      pin: '11771199',
      localizedNames: {
        'urdu': 'جامع مسجد باغِ رسول ﷺ',
        'sindhi': 'جامع مسجد باغِ رسول ﷺ',
        'arabic': 'جامع بستان الرسول ﷺ',
        'hindi': 'जामा मस्जिद बाग-ए-रसूल (ﷺ)',
        'bengali': 'জামে মসজিদ বাগে রাসুল (ﷺ)',
        'persian': 'مسجد جامع باغ رسول ﷺ',
        'turkish': 'Baag-e-Rasool Cuma Camii (ﷺ)',
        'french': 'Mosquée Jama Masjid Baag-e-Rasool (ﷺ)',
        'indonesian': 'Masjid Jama Baag-e-Rasool (ﷺ)',
      },
      localizedAddresses: {
        'urdu': 'کمہار محلہ، سکھر',
        'sindhi': 'ڪمھار پاڙا، سکر',
        'arabic': 'حي الخمار، سكر',
        'hindi': 'कुम्हार मोहल्ला, सुक्कुर',
        'bengali': 'কুমহার মহল্লা, সুক্কুর',
        'persian': 'محله کومہار، سکر',
        'turkish': 'Kumhaar Para, Sukkur',
        'french': 'Kumhaar Para, Sukkur',
        'indonesian': 'Kumhaar Para, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:05 AM',
        fajrUpdated: '01 Nov 2026',
        zuhar: '02:00 PM',
        asar: '04:30 PM',
        asarUpdated: '31 Oct 2026',
        maghrib: 'Sunset',
        isha: '07:30 PM',
        ishaUpdated: '31 Oct 2026',
        jummah: '01:00 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'quba_masjid',
      nameKey: 'Quba Masjid',
      addressKey: 'Nawaan Goth, Sukkur',
      pin: '44488444',
      localizedNames: {
        'urdu': 'قبا مسجد',
        'sindhi': 'قبا مسجد',
        'arabic': 'مسجد قباء',
        'hindi': 'कुबा मस्जिद',
        'bengali': 'কুবা মসজিদ',
        'persian': 'مسجد قبا',
        'turkish': 'Kuba Camii',
        'french': 'Mosquée Quba',
        'indonesian': 'Masjid Quba',
      },
      localizedAddresses: {
        'urdu': 'نواں گوٹھ، سکھر',
        'sindhi': 'نئون گوٺ، سکر',
        'arabic': 'القرية الجديدة، سكر',
        'hindi': 'नवां गोठ, सुक्कुर',
        'bengali': 'নওয়ান গোঠ, সুক্কুর',
        'persian': 'روستای جدید، سکر',
        'turkish': 'Nawaan Goth, Sukkur',
        'french': 'Nawaan Goth, Sukkur',
        'indonesian': 'Nawaan Goth, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:05 AM',
        fajrUpdated: '01 Nov 2026',
        zuhar: '02:00 PM',
        asar: '04:45 PM',
        asarUpdated: '01 Nov 2026',
        maghrib: 'sunset',
        isha: '07:30 PM',
        ishaUpdated: '01 Nov 2026',
        jummah: '02:00 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'masjid_jalal',
      nameKey: 'Masjid Jalal',
      addressKey: 'Sookha Taalaab, Sukkur',
      pin: '55550000',
      localizedNames: {
        'urdu': 'مسجد جلال',
        'sindhi': 'مسجد جلال',
        'arabic': 'مسجد جلال',
        'hindi': 'मस्जिद जलाल',
        'bengali': 'মসজিদ জালাল',
        'persian': 'مسجد جلال',
        'turkish': 'Jalal Camii',
        'french': 'Mosquée Masjid Jalal',
        'indonesian': 'Masjid Masjid Jalal',
      },
      localizedAddresses: {
        'urdu': 'سوکھا تالاب، سکھر',
        'sindhi': 'سُکّو تلاء، سکر',
        'arabic': 'بركة جافة، سكر',
        'hindi': 'सूखा तालाब, सुक्कुर',
        'bengali': 'সুখা তালাব, সুক্কুর',
        'persian': 'برکه خشک، سکر',
        'turkish': 'Sookha Taalaab, Sukkur',
        'french': 'Sookha Taalaab, Sukkur',
        'indonesian': 'Sookha Taalaab, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:10 AM',
        fajrUpdated: '01 Nov 2026',
        zuhar: '01:15 PM',
        asar: '04:30 PM',
        asarUpdated: '01 Nov 2026',
        maghrib: 'sunset',
        isha: '07:30 PM',
        ishaUpdated: '01 Nov 2026',
        jummah: '01:30 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'jama_masjid_aqsa',
      nameKey: 'Jama Masjid Aqsa',
      addressKey: 'Nawaan Goth, Sukkur',
      pin: '22255577',
      localizedNames: {
        'urdu': 'جامع مسجد اقصی',
        'sindhi': 'جامع مسجد اقصى',
        'arabic': 'مسجد جامع الأقصى',
        'hindi': 'जामा मस्जिद अक्सा',
        'bengali': 'জামে মসজিদ আকসা',
        'persian': 'مسجد جامع اقصی',
        'turkish': 'Aqsa Cuma Camii',
        'french': 'Mosquée Jama Masjid Aqsa',
        'indonesian': 'Masjid Jama Aqsa',
      },
      localizedAddresses: {
        'urdu': 'نواں گوٹھ، سکھر',
        'sindhi': 'نئون گوٺ، سکر',
        'arabic': 'القرية الجديدة، سكر',
        'hindi': 'नवां गोठ, सुक्कुर',
        'bengali': 'নওয়ান গোঠ, সুক্কুর',
        'persian': 'روستای جدید، سکر',
        'turkish': 'Nawaan Goth, Sukkur',
        'french': 'Nawaan Goth, Sukkur',
        'indonesian': 'Nawaan Goth, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '05:55 AM',
        fajrUpdated: '01 Nov 2026',
        zuhar: '01:30 PM',
        asar: '04:30 PM',
        asarUpdated: '04 Nov 2026',
        maghrib: 'Sunset',
        isha: '08:00 PM',
        ishaUpdated: '01 Nov 2026',
        jummah: '01:45 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'tooba_masjid',
      nameKey: 'Tooba Masjid',
      addressKey: 'Near ICON, Sindhi Society, Sukkur',
      pin: '09990999',
      localizedNames: {
        'urdu': 'طوبیٰ مسجد',
        'sindhi': 'طوبىٰ مسجد',
        'arabic': 'مسجد طوبى',
        'hindi': 'तुबा मस्जिद',
        'bengali': 'তুবা মসজিদ',
        'persian': 'طوبی مسجد',
        'turkish': 'Tooba Camii',
        'french': 'Mosquée Tooba',
        'indonesian': 'Masjid Tooba',
      },
      localizedAddresses: {
        'urdu': 'نزد آئیکن، سندھی سوسائٹی، سکھر',
        'sindhi': 'آئڪون جي ويجهو، سنڌي سوسائٽي، سکر',
        'arabic': 'بالقرب من أيكون، المجتمع السندي، سكر',
        'hindi': 'आइकॉन के पास, सिंधी सोसाइटी, सुक्कुर',
        'bengali': 'আইকন-এর কাছে, সিন্ধি সোসাইটি, সুক্কুর',
        'persian': 'نزد آیکون، جامعه سندی، سکر',
        'turkish': 'Near ICON, Sindhi Society, Sukkur',
        'french': 'Near ICON, Sindhi Society, Sukkur',
        'indonesian': 'Near ICON, Sindhi Society, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:10 AM',
        fajrUpdated: '02 Nov 2026',
        zuhar: '02:00 PM',
        asar: '04:30 PM',
        asarUpdated: '01 Nov 2026',
        maghrib: 'Sunset',
        isha: '07:30 PM',
        ishaUpdated: '01 Nov 2026',
        jummah: '01:30 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'masjid_ali_ul_murtaza',
      nameKey: 'Masjid Ali-ul-Murtaza (رضی الله عنه)',
      addressKey: 'Near Khursheed Shah House, 100 Feet Road, Professor Society, Sukkur',
      pin: '08880888',
      localizedNames: {
        'urdu': '‎مسجد علی المرتضیٰ رضی اللہ عنہ',
        'sindhi': 'مسجد علي المرتضىٰ رضي الله عنه',
        'arabic': 'مسجد علي المرتضى رضي الله عنه',
        'hindi': 'मस्जिद अली-उल-मुर्तज़ा (رضي الله عنه)',
        'bengali': 'মসজিদ আলী উল মুর্তজা (رضي الله عنه)',
        'persian': 'مسجد علی المرتضی رضي الله عنه',
        'turkish': 'Ali-ul-Murtaza Camii (رضي الله عنه)',
        'french': 'Mosquée Masjid Ali-ul-Murtaza (رضي الله عنه)',
        'indonesian': 'Masjid Masjid Ali-ul-Murtaza (رضي الله عنه)',
      },
      localizedAddresses: {
        'urdu': 'نزد خورشید شاہ ہاؤس، 100 فٹ روڈ، پروفیسر سوسائٹی، سکھر',
        'sindhi': 'خُرشيد شاهه هائوس جي ويجهو، 100 فوٽ روڊ، پروفيسر سوسائٽي، سکر',
        'arabic': 'بالقرب من منزل خورشيد شاه، شارع 100 قدم، مجتمع الأساتذة، سكر',
        'hindi': 'खुरशीद शाह हाउस के पास, 100 फीट रोड, प्रोफेसर सोसाइटी, सुक्कुर',
        'bengali': 'খুরশিদ শাহ হাউস-এর কাছে, ১০০ ফিট রোড, প্রফেসর সোসাইটি, সুক্কুর',
        'persian': 'نزد خانه خورشید شاه، جاده ۱۰۰ فوتی، جامعه اساتید، سکر',
        'turkish': 'Near Khursheed Shah House, 100 Feet Road, Professor Society, Sukkur',
        'french': 'Near Khursheed Shah House, 100 Feet Road, Professor Society, Sukkur',
        'indonesian': 'Near Khursheed Shah House, 100 Feet Road, Professor Society, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:05 AM',
        fajrUpdated: '01 Nov 2026',
        zuhar: '01:15 PM',
        asar: '04:30 PM',
        asarUpdated: '01 Nov 2026',
        maghrib: 'sunset',
        isha: '07:45 PM',
        ishaUpdated: '01 Nov 2026',
        jummah: '01:15 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'jama_masjid_ayesha_wa_janaza_gah',
      nameKey: 'Jama Masjid Ayesha (رضي الله عنها) wa Janaza Gah',
      addressKey: 'Near Bakra Mandi, Race Course Road, Sukkur',
      pin: '67833678',
      localizedNames: {
        'urdu': 'جامع مسجد عائشہ (رضی اللہ عنہا) و جنازہ گاہ',
        'sindhi': 'جامع مسجد عائشه (رضي الله عنها) ۽ جنازه گاهه',
        'arabic': 'جامع مسجد عائشة (رضي الله عنها) وجنازة كاه',
        'hindi': 'जामा मस्जिद आयशा (رضي الله عنها) व जनाज़ा गाह',
        'bengali': 'জামা মসজিদ আয়েশা (رضি আল্লাহু আনহা) ও জানাজা গাহ',
        'persian': 'جامع مسجد عایشه (رضی الله عنها) و جنازه‌گاه',
        'turkish': 'Jama Masjid Ayesha (رضي الله عنها) wa Janaza Gah Camii',
        'french': 'Mosquée Jama Masjid Ayesha (رضي الله عنها) wa Janaza Gah',
        'indonesian': 'Masjid Jama Masjid Ayesha (رضي الله عنها) wa Janaza Gah',
      },
      localizedAddresses: {
        'urdu': 'نزد بکرا منڈی، ریس کورس روڈ، سکھر',
        'sindhi': 'بڪرا منڊي جي ويجهو، ريس ڪورس روڊ، سکر',
        'arabic': 'بالقرب من بكرا مندي، طريق ريس كورس، سكر',
        'hindi': 'बकरा मंडी के पास, रेस कोर्स रोड, सुक्कुर',
        'bengali': 'বকরা মান্ডি-র কাছে, রেস কোর্স রোড, সুক্কুর',
        'persian': 'نزد باکره مندی، جاده ریس کورس، سکر',
        'turkish': 'Near Bakra Mandi, Race Course Road, Sukkur',
        'french': 'Near Bakra Mandi, Race Course Road, Sukkur',
        'indonesian': 'Near Bakra Mandi, Race Course Road, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '05:50 AM',
        fajrUpdated: '02 Nov 2026',
        zuhar: '12:45 PM',
        asar: '04:15 PM',
        asarUpdated: '02 Nov 2026',
        maghrib: 'sunset',
        isha: '07:10 PM',
        ishaUpdated: '02 Nov 2026',
        jummah: '12:45 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'masjid_abu_bakkar',
      nameKey: 'Masjid Abu Bakkar (رضي الله عنه)',
      addressKey: 'Nusrat Colony No. 4, Sukkur',
      pin: '44222244',
      localizedNames: {
        'urdu': 'مسجد ابوبکر (رضی اللہ عنہ)',
        'sindhi': 'مسجد ابو بڪر (رضي الله عنه)',
        'arabic': 'مسجد أبي بكر (رضي الله عنه)',
        'hindi': 'मस्जिद अबू बकर (رضي الله عنه)',
        'bengali': 'মসজিদ আবু বকর (رضি আল্লাহু আনহু)',
        'persian': 'مسجد ابوبکر (رضی الله عنه)',
        'turkish': 'Masjid Abu Bakkar Camii (رضي الله عنه)',
        'french': 'Mosquée Masjid Abu Bakkar (رضي الله عنه)',
        'indonesian': 'Masjid Masjid Abu Bakkar (رضي الله عنه)',
      },
      localizedAddresses: {
        'urdu': 'نصرت کالونی نمبر 4، سکھر',
        'sindhi': 'نصرت ڪالوني نمبر 4، سکر',
        'arabic': 'نصرت كولوني رقم 4، سكر',
        'hindi': 'नुसरत कॉलोनी नं. 4, सुक्कुर',
        'bengali': 'নুসরাত কলোনি নং ৪, সুক্কুর',
        'persian': 'نصرت کلونی شماره ۴، سکر',
        'turkish': 'Nusrat Colony No. 4, Sukkur',
        'french': 'Nusrat Colony No. 4, Sukkur',
        'indonesian': 'Nusrat Colony No. 4, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:15 AM',
        fajrUpdated: '03 Nov 2026',
        zuhar: '01:00 PM',
        asar: '04:30 PM',
        asarUpdated: '02 Nov 2026',
        maghrib: 'Sunset',
        isha: '07:30 PM',
        ishaUpdated: '02 Nov 2026',
        jummah: '01:15 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'hari_masjid',
      nameKey: 'Jama Hari Masjid',
      addressKey: 'Bandhani Muhalla, New Goth, Sukkur',
      pin: '08182838',
      localizedNames: {
        'english': 'Jama Hari Masjid',
        'urdu': 'جامع ہری مسجد',
        'sindhi': 'جامعه هري مسجد',
        'arabic': 'مسجد جامع ہري',
        'hindi': 'मस्जिद के दिन के घंटे',
        'bengali': 'মসজিদ দিবসের সময়',
        'persian': 'مسجد جامع هری',
        'turkish': 'Cami Gün Saatleri',
        'french': 'Horaires de jour de la mosquée',
        'indonesian': 'Jama Hari Masjid',
      },
      localizedAddresses: {
        'english': 'Bandhani Muhalla, New Goth, Sukkur',
        'urdu': 'بندھانی محلہ, نواں گوٹھ، سکھر',
        'sindhi': 'ٻنڌاڻي محلو، نئو ڳوٺ، سکر',
        'arabic': 'حي باندهاني، القرية الجديدة، سکر',
        'hindi': 'बंधनी मुहल्ला, न्यू गोथ, सुक्कुर',
        'bengali': 'বাঁধনি মুহল্লা, নিউ গোঠ, শুক্কুর',
        'persian': 'محله بندھانی، نواں گوٹھ، سکر',
        'turkish': 'Bandhani Muhalla, Yeni Gotik, Sukkur',
        'french': 'Bandhani Muhalla, Nouveau Goth, Sukkur',
        'indonesian': 'Bandhani Muhalla, Goth Baru, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:10 AM',
        fajrUpdated: '05 Nov 2026',
        zuhar: '01:45 PM',
        asar: '04:30 PM',
        asarUpdated: '05 Nov 2026',
        maghrib: 'Sunset',
        isha: '07:30 PM',
        ishaUpdated: '05 Nov 2026',
        jummah: '01:45 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'makrani_masjid',
      nameKey: 'Makrani Masjid',
      addressKey: 'Bunder Road Sukkur',
      isHidden: true,
      pin: '22990099',
      defaultTimings: JamaatTiming(
        fajr: '',
        fajrUpdated: '01 Nov 2026',
        zuhar: '',
        asar: '',
        maghrib: 'Sunset',
        isha: '',
        jummah: '',
      ),
    ),
    JamaatMasjidInfo(
      id: 'masjid_shuhada_shaheed_ganj_sukkur',
      nameKey: 'Masjid Shuhada',
      addressKey: 'Shaheed Ganj, Sukkur',
      pin: '71007100',
      localizedNames: {
        'english': 'Masjid Shuhada',
        'urdu': 'مسجد شہداء',
        'sindhi': 'مسجد شهدا',
        'arabic': 'مسجد الشهداء',
        'hindi': 'शहीद मस्जिद',
        'bengali': 'শহীদ মসজিদ',
        'persian': 'مسجد شهدا',
        'turkish': 'Şehit Camii',
        'french': 'Mosquée des martyrs',
        'indonesian': 'Masjid Syahid',
      },
      localizedAddresses: {
        'english': 'Shaheed Ganj, Sukkur',
        'urdu': 'شہید گنج، سکھر',
        'sindhi': 'شهيد گنج، سکر',
        'arabic': 'شهيد جانج، سکر',
        'hindi': 'शहीद गंज, सुक्कुर',
        'bengali': 'শহীদ গঞ্জ, শুক্কুর',
        'persian': 'شهید گنج، سکر',
        'turkish': 'Shaheed Ganj, Sukkur',
        'french': 'Shaheed Ganj, Sukkur',
        'indonesian': 'Shaheed Ganj, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:15 AM',
        fajrUpdated: '05 Nov 2026',
        zuhar: '01:00 PM',
        asar: '04:45 PM',
        asarUpdated: '05 Nov 2026',
        maghrib: 'Sunset',
        isha: '08:15 PM',
        ishaUpdated: '05 Nov 2026',
        jummah: '01:00 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'shan_e_khuda_masjid_railway_crossing_new_goth_sukkur',
      nameKey: 'Shan e Khuda Masjid',
      addressKey: 'Railway crossing, New Goth, Sukkur',
      pin: '89198929',
      localizedNames: {
        'english': 'Shan e Khuda Masjid',
        'urdu': 'شانِ خدا مسجد',
        'sindhi': 'شانِ خدا  مسجد',
        'arabic': 'مسجد شانِ خدا',
        'hindi': 'Shan e Khuda Masjid',
        'bengali': 'শান ই খুদা মসজিদ',
        'persian': 'شانِ خدا مسجد',
        'turkish': 'Shan e Khuda Mescidi',
        'french': 'Mosquée Shan e Khuda',
        'indonesian': 'Masjid Shan e Khuda',
      },
      localizedAddresses: {
        'english': 'Railway crossing, New Goth, Sukkur',
        'urdu': 'ریلوے پھاٹک، نواں گوٹھ، سکھر',
        'sindhi': 'ريلوي ڦاٽڪ، نئون ڳوٺ، سکر',
        'arabic': 'بوابة السكة الحديد، نيو جوث، سکر',
        'hindi': 'रेलवे क्रॉसिंग, न्यू गोथ, सुक्कुर',
        'bengali': 'রেলওয়ে ক্রসিং, নিউ গোঠ, শুক্কুর',
        'persian': 'دروازه راه آهن، گوت جدید، سکر',
        'turkish': 'Demiryolu geçişi, Yeni Gotik, Sukkur',
        'french': 'Passage à niveau, New Goth, Sukkur',
        'indonesian': 'Perlintasan kereta api, New Goth, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:15 AM',
        fajrUpdated: '05 Nov 2026',
        zuhar: '01:00 PM',
        asar: '04:30 PM',
        maghrib: 'Sunset',
        isha: '07:05 PM',
        jummah: '01:00 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'madani_jama_masjid_race_course_road_sukkur',
      nameKey: 'Madani Jama Masjid (Khadda Wali)',
      addressKey: 'Race Course Road, Sukkur',
      pin: '85058606',
      localizedNames: {
        'urdu': 'مدنی جامع مسجد (کھڈا  والی)',
        'sindhi': 'مدني جامع مسجد (کڏا  واري)',
        'arabic': 'مسجد مدني جامع (خادا  والی)',
        'hindi': 'मदनी जामा मस्जिद (खड़ा वाली)',
        'bengali': 'মাদানী জামে মসজিদ (খাড়া ওয়ালি)',
        'persian': 'مدنی جامع مسجد (خادا  والی)',
        'turkish': 'Madani Jama Mescidi (Khadda Vali)',
        'french': 'Masjid Madani Jama (Khadda Wali)',
        'indonesian': 'Madani Jama Masjid (Khadda Wali)',
        'english': 'Madani Jama Masjid (Khadda Wali)',
      },
      localizedAddresses: {
        'urdu': 'ریس کورس روڈ، سکھر',
        'sindhi': 'ريس ڪورس روڊ، سکر',
        'arabic': 'طريق مضمار السباق، سکر',
        'hindi': 'रेस कोर्स रोड, सुक्कुर',
        'bengali': 'রেসকোর্স রোড, শুক্কুর',
        'persian': 'جاده مسابقه مسابقه، سکر',
        'turkish': 'Yarış Pisti Yolu, Sukkur',
        'french': 'Route de l\'hippodrome, Sukkur',
        'indonesian': 'Jalan Arena Balap, Sukkur',
        'english': 'Race Course Road, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:20 AM',
        fajrUpdated: '05 Nov 2026',
        zuhar: '01:30 PM',
        asar: '05:00 PM',
        asarUpdated: '05 Nov 2026',
        maghrib: 'Sunset',
        isha: '07:10 PM',
        ishaUpdated: '05 Nov 2026',
        jummah: '01:45 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'zakariya_masjid_waritar_road_sukkur',
      nameKey: 'Zakariya Masjid',
      addressKey: 'Waritar Road, Sukkur',
      pin: '70707171',
      localizedNames: {
        'english': 'Zakariya Masjid',
        'urdu': 'زکریا مسجد',
        'sindhi': 'ذڪريا مسجد',
        'arabic': 'مسجد زكريا',
        'hindi': 'ज़कारिया मस्जिद',
        'bengali': 'জাকারিয়া মসজিদ',
        'persian': 'زکریا مسجد',
        'turkish': 'Zekeriya Camii',
        'french': 'Mosquée Zakariya',
        'indonesian': 'Masjid Zakaria',
      },
      localizedAddresses: {
        'english': 'Waritar Road, Sukkur',
        'urdu': 'واری تڑ روڈ، سکھر',
        'sindhi': 'واري تڙ روڊ، سکر',
        'arabic': 'طريق واري تر، سكر',
        'hindi': 'वारिटर रोड, सुक्कुर',
        'bengali': 'ওয়ারিটার রোড, শুক্কুর',
        'persian': 'جاده واری تڑ، سکھر',
        'turkish': 'Waritar Yolu, Sukkur',
        'french': 'Route Waritar, Sukkur',
        'indonesian': 'Jalan Waritar, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:15 AM',
        fajrUpdated: '05 Nov 2026',
        zuhar: '01:45 PM',
        asar: '04:30 PM',
        asarUpdated: '05 Nov 2026',
        maghrib: 'Sunset',
        isha: '07:30 PM',
        ishaUpdated: '05 Nov 2026',
        jummah: '02:00 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'al_falah_masjid_new_goth_adam_shah_colony_sukkur',
      nameKey: 'Al Falah Masjid',
      addressKey: 'New Goth, Adam Shah Colony, Sukkur',
      pin: '90001000',
      localizedNames: {
        'english': 'Al Falah Masjid',
        'urdu': 'الفلاح مسجد',
        'sindhi': 'الفلاح مسجد',
        'arabic': 'الفلاح مسجد',
        'hindi': 'अल फलाह मस्जिद',
        'bengali': 'আল ফালাহ মসজিদ',
        'persian': 'مسجد الفلاح',
        'turkish': 'El Falah Camii',
        'french': 'Mosquée Al Falah',
        'indonesian': 'Al Falah Masjid',
      },
      localizedAddresses: {
        'english': 'New Goth, Adam Shah Colony, Sukkur',
        'urdu': 'نواں گوٹھ، آدم شاہ کالونی، سکھر',
        'sindhi': 'نوان ڳوٺ، آدم شاهه ڪالوني، سکر',
        'arabic': 'نوان القوطي، مستعمرة آدم شاه، سکر',
        'hindi': 'न्यू गोथ, एडम शाह कॉलोनी, सुक्कुर',
        'bengali': 'নিউ গোথ, আদম শাহ কলোনি, শুক্কুর',
        'persian': 'ناوان گوت، مستعمره آدام شاه، سکر',
        'turkish': 'Yeni Gotik, Adam Şah Kolonisi, Sukkur',
        'french': 'Nouveau Goth, colonie Adam Shah, Sukkur',
        'indonesian': 'Goth Baru, Koloni Adam Shah, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:15 AM',
        fajrUpdated: '05 Nov 2026',
        zuhar: '02:00 PM',
        asar: '04:30 PM',
        asarUpdated: '05 Nov 2026',
        maghrib: 'Sunset',
        isha: '07:30 PM',
        ishaUpdated: '05 Nov 2026',
        jummah: '02:00 PM',
      ),
    ),
    JamaatMasjidInfo(
      id: 'jama_minara_masjid_gharibabad_sukkur',
      nameKey: 'Jama Minar Masjid',
      addressKey: 'Gharibabad, Sukkur',
      pin: '22823282',
      localizedNames: {
        'english': 'Jama Minar Masjid',
        'urdu': 'جامع مینار مسجد',
        'sindhi': 'جامع مينار مسجد',
        'arabic': 'مسجد جامع منار',
        'hindi': 'जामा मीनार मस्जिद',
        'bengali': 'জামে মিনার মসজিদ',
        'persian': 'مسجد جامع منار',
        'turkish': 'Jama Minar Camii',
        'french': 'Mosquée Jama Minar',
        'indonesian': 'Jama Minar Masjid',
      },
      localizedAddresses: {
        'english': 'Gharibabad, Sukkur',
        'urdu': 'غریب آباد، سکھر',
        'sindhi': 'غريب آباد، سکر',
        'arabic': 'غريب آباد، سکر',
        'hindi': 'गरीबाबाद, सुक्कुर',
        'bengali': 'গরিবাবাদ, শুক্কুর',
        'persian': 'غریب آباد، سکر',
        'turkish': 'Garibabad, Sukkur',
        'french': 'Gharibabad, Sukkur',
        'indonesian': 'Gharibabad, Sukkur',
      },
      defaultTimings: JamaatTiming(
        fajr: '06:10 AM',
        zuhar: '01:30 PM',
        asar: '04:45 PM',
        maghrib: 'Sunset',
        isha: '07:30 PM',
        jummah: '02:30 PM',
      ),
    ),
  ];


  final Map<String, JamaatTiming> _remoteCache = {};
  final Map<String, JamaatTiming> _gistTimings = {};
  final Map<String, JamaatTiming> _firestoreTimings = {};
  final Map<String, JamaatTiming> _pendingLocalTimings = {};
  Future<bool>? _ongoingRemoteSync;
  List<JamaatMasjidInfo> _dynamicMasjids = [];
  final Set<String> _locallyUpdatedMasjidIds = {};
  String _masterAdminPin = '25081989';
  final Map<String, String> _masjidPins = {};

  /// Returns the baseline Gist or built-in timing for a masjid (before Firestore overlay)
  JamaatTiming? getGistBaselineTimingFor(String masjidId) {
    return _gistTimings[masjidId] ?? _getDefaultTimingFor(masjidId);
  }

  void _recomputeEffectiveTiming(String masjidId) {
    JamaatTiming? effective = _gistTimings[masjidId] ?? _getDefaultTimingFor(masjidId) ?? _remoteCache[masjidId];
    if (_firestoreTimings.containsKey(masjidId)) {
      final fsTiming = _firestoreTimings[masjidId]!;
      effective = effective != null
          ? mergePrayerByPrayer(
              current: effective,
              incoming: fsTiming,
              isIncomingFirestore: true,
            )
          : fsTiming;
    }
    if (_pendingLocalTimings.containsKey(masjidId)) {
      final pending = _pendingLocalTimings[masjidId]!;
      effective = effective != null
          ? mergePrayerByPrayer(
              current: effective,
              incoming: pending,
              isIncomingFirestore: true,
            )
          : pending;
    }
    if (effective != null) {
      _remoteCache[masjidId] = effective;
      final idx = _dynamicMasjids.indexWhere((m) => m.id == masjidId);
      if (idx >= 0) {
        final m = _dynamicMasjids[idx];
        _dynamicMasjids[idx] = JamaatMasjidInfo(
          id: m.id,
          nameKey: m.nameKey,
          addressKey: m.addressKey,
          defaultTimings: effective,
          isHidden: m.isHidden,
          localizedNames: m.localizedNames,
          localizedAddresses: m.localizedAddresses,
          pin: m.pin,
        );
      }
    }
  }

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

  String? getMasjidPin(String masjidId) {
    final assigned = _masjidPins[masjidId];
    if (assigned != null && assigned.isNotEmpty) {
      return assigned;
    }
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
      return local.pin;
    }
    return null;
  }

  static Future<SharedPreferences> _getPrefs() async => await SharedPreferences.getInstance();

  /// Optional Gist URL for live updates from GitHub Gist
  String _gistRawUrl =
      'https://gist.githubusercontent.com/safikaleem/2afecaa5e4b86ab5227ee00a7416646a/raw/jamaat_times.json';

  void setGistUrl(String url) {
    _gistRawUrl = url;
  }

  /// Returns list of masjids. By default (includeHidden: false), filters out hidden masjids for regular users.
  /// When includeHidden is true (Developer/Admin mode), returns all masjids with their isHidden flag intact.
  List<JamaatMasjidInfo> getMasjidList({bool includeHidden = false}) {
    final List<JamaatMasjidInfo> list = List.from(sukkurMasjids);
    for (final remote in _dynamicMasjids) {
      final index = list.indexWhere((m) => m.id == remote.id);
      if (remote.isHidden) {
        if (includeHidden) {
          if (index >= 0) {
            final local = list[index];
            list[index] = JamaatMasjidInfo(
              id: remote.id,
              nameKey: remote.nameKey.isNotEmpty ? remote.nameKey : local.nameKey,
              addressKey: remote.addressKey.isNotEmpty ? remote.addressKey : local.addressKey,
              defaultTimings: remote.defaultTimings,
              isHidden: true,
              localizedNames: remote.localizedNames.isNotEmpty ? remote.localizedNames : local.localizedNames,
              localizedAddresses: remote.localizedAddresses.isNotEmpty ? remote.localizedAddresses : local.localizedAddresses,
              pin: remote.pin ?? _masjidPins[remote.id] ?? local.pin,
            );
          } else {
            list.add(remote);
          }
        } else {
          if (index >= 0) {
            list.removeAt(index);
          }
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
    return includeHidden ? list : list.where((m) => !m.isHidden).toList();
  }

  /// Toggles visibility of a masjid (hide/unhide from regular app users) and syncs to GitHub Gist
  Future<({bool success, String message})> toggleMasjidHidden({
    required String masjidId,
    required bool hide,
  }) async {
    // 1. Update in-memory dynamic masjids list
    final index = _dynamicMasjids.indexWhere((m) => m.id == masjidId);
    if (index >= 0) {
      final m = _dynamicMasjids[index];
      _dynamicMasjids[index] = JamaatMasjidInfo(
        id: m.id,
        nameKey: m.nameKey,
        addressKey: m.addressKey,
        defaultTimings: m.defaultTimings,
        isHidden: hide,
        localizedNames: m.localizedNames,
        localizedAddresses: m.localizedAddresses,
        pin: m.pin,
      );
    } else {
      // Find in built-in list
      final builtInList = sukkurMasjids.where((m) => m.id == masjidId).toList();
      if (builtInList.isNotEmpty) {
        final b = builtInList.first;
        _dynamicMasjids.add(JamaatMasjidInfo(
          id: b.id,
          nameKey: b.nameKey,
          addressKey: b.addressKey,
          defaultTimings: _remoteCache[masjidId] ?? b.defaultTimings,
          isHidden: hide,
          localizedNames: b.localizedNames,
          localizedAddresses: b.localizedAddresses,
          pin: _masjidPins[masjidId] ?? b.pin,
        ));
      }
    }

    // 2. Persist locally in SharedPreferences
    try {
      final prefs = await _getPrefs();
      await prefs.setBool('masjid_hidden_$masjidId', hide);
    } catch (_) {}

    // 3. Prepare payload for Gist
    final list = getMasjidList(includeHidden: true);
    final masjid = list.firstWhere(
      (m) => m.id == masjidId,
      orElse: () => sukkurMasjids.firstWhere((m) => m.id == masjidId),
    );
    final activeTiming = _remoteCache[masjidId] ?? masjid.defaultTimings;
    final jsonMap = activeTiming.toJson();
    jsonMap['id'] = masjid.id;
    jsonMap['name'] = masjid.nameKey;
    jsonMap['address'] = masjid.addressKey;
    jsonMap['hidden'] = hide;
    final pin = getMasjidPin(masjidId);
    if (pin != null && pin.isNotEmpty) {
      jsonMap['pin'] = pin;
    }
    if (masjid.localizedNames.isNotEmpty) jsonMap['names'] = masjid.localizedNames;
    if (masjid.localizedAddresses.isNotEmpty) jsonMap['addresses'] = masjid.localizedAddresses;

    final res = await DeveloperGistService.instance.saveMasjidToGist(jsonMap);
    return res;
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

  /// Returns effective timing for a masjid by its String ID
  JamaatTiming? getTimingForId(String id) {
    if (_remoteCache.containsKey(id)) return _remoteCache[id];
    final list = getMasjidList(includeHidden: true);
    for (final m in list) {
      if (m.id == id) return getTimingFor(m);
    }
    return null;
  }

  static const String prefKeyJamaatCache = 'cached_jamaat_times_json';
  static const String prefKeyFirestoreCache = 'cached_firestore_jamaat_times_json';
  static const String prefKeyPendingUpdates = 'pending_jamaat_firestore_updates_json';

  /// Loads cached timings from SharedPreferences so updated times are available
  /// immediately even if the device is offline or on slow network.
  Future<void> loadLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Restore cached Firestore live timings
      final fsCached = prefs.getString(prefKeyFirestoreCache);
      if (fsCached != null && fsCached.isNotEmpty) {
        try {
          final fsMap = json.decode(fsCached);
          if (fsMap is Map<String, dynamic>) {
            fsMap.forEach((id, val) {
              if (val is Map<String, dynamic>) {
                _firestoreTimings[id] = JamaatTiming.fromJson(val);
              }
            });
          }
        } catch (e) {
          debugPrint('Error parsing cached Firestore timings: $e');
        }
      }

      // 2. Restore any pending local Imam updates not yet synced to Firestore
      final pendingCached = prefs.getString(prefKeyPendingUpdates);
      if (pendingCached != null && pendingCached.isNotEmpty) {
        try {
          final pMap = json.decode(pendingCached);
          if (pMap is Map<String, dynamic>) {
            pMap.forEach((id, val) {
              if (val is Map<String, dynamic>) {
                final t = JamaatTiming.fromJson(val);
                _pendingLocalTimings[id] = t;
                _firestoreTimings[id] = t;
              }
            });
          }
        } catch (e) {
          debugPrint('Error parsing pending Jamaat updates: $e');
        }
      }

      // 3. Restore baseline/merged masjid list and recompute effective timings
      final cached = prefs.getString(prefKeyJamaatCache);
      if (cached != null && cached.isNotEmpty) {
        _parseAndApplyJson(cached, isFromLocalCache: true);
      } else {
        for (final id in {..._firestoreTimings.keys, ..._pendingLocalTimings.keys}) {
          _recomputeEffectiveTiming(id);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load local cached Jamaat times: $e');
    }
  }

  static Map<String, String> _extractLocalizedStrings(Map<String, dynamic> item, String baseKey) {
    final Map<String, String> result = {};

    // 1. Check flat keys (e.g. name_ur, name_urdu, name_sd, etc.) as baseline
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

    // 2. Check nested maps (e.g. item['names'] or item['addresses'])
    // Nested maps are the modern multi-language standard and take precedence over older flat keys
    final pluralKey = baseKey == 'name' ? 'names' : '${baseKey}es';
    if (item[pluralKey] is Map) {
      final map = item[pluralKey] as Map;
      map.forEach((k, v) {
        if (v != null && v.toString().trim().isNotEmpty) {
          result[k.toString().toLowerCase()] = v.toString().trim();
        }
      });
    }

    return result;
  }

  bool _parseAndApplyJson(String jsonStr, {bool isFromLocalCache = false}) {
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

            // Store Gist baseline without destroying newer Firestore or pending Imam updates
            if (!isFromLocalCache || !_gistTimings.containsKey(id)) {
              _gistTimings[id] = timing;
            }
            if (isFromLocalCache && !_remoteCache.containsKey(id)) {
              _remoteCache[id] = timing;
            }
            _recomputeEffectiveTiming(id);
            final effectiveTiming = _remoteCache[id] ?? timing;

            fetchedList.add(JamaatMasjidInfo(
              id: id,
              nameKey: name,
              addressKey: address,
              defaultTimings: effectiveTiming,
              isHidden: isHidden,
              localizedNames: localizedNames,
              localizedAddresses: localizedAddresses,
              pin: pin,
            ));
          }
        }
        if (fetchedList.isNotEmpty) {
          final Map<String, JamaatMasjidInfo> mergedMap = {};
          for (final m in fetchedList) {
            mergedMap[m.id] = m;
          }
          // Safeguard: Protect locally registered or edited masjids from being overwritten or deleted by stale CDN caches
          for (final local in _dynamicMasjids) {
            if (!mergedMap.containsKey(local.id)) {
              mergedMap[local.id] = local;
            } else if (_locallyUpdatedMasjidIds.contains(local.id)) {
              final remote = mergedMap[local.id]!;
              mergedMap[local.id] = JamaatMasjidInfo(
                id: local.id,
                nameKey: local.nameKey.isNotEmpty ? local.nameKey : remote.nameKey,
                addressKey: local.addressKey.isNotEmpty ? local.addressKey : remote.addressKey,
                defaultTimings: remote.defaultTimings,
                isHidden: local.isHidden,
                localizedNames: local.localizedNames.isNotEmpty ? local.localizedNames : remote.localizedNames,
                localizedAddresses: local.localizedAddresses.isNotEmpty ? local.localizedAddresses : remote.localizedAddresses,
                pin: local.pin ?? remote.pin,
              );
            }
          }
          _dynamicMasjids = mergedMap.values.toList();
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
    if (dateA == null && dateB != null) return isAFirestore ? 1 : -1;

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
          // Incoming is Firestore. If incUpdated is non-empty, the Imam explicitly turned off / cleared this prayer.
          if (incUpdated.isNotEmpty) {
            final currDt = _parseDate(currUpdated);
            final incDt = _parseDate(incUpdated);
            final cmp = _compareDatesWithPrecedence(
              dateA: incDt,
              dateB: currDt,
              isAFirestore: true,
            );
            if (cmp > 0) {
              return PrayerMergeResult(
                time: isMaghrib ? 'Sunset' : '',
                updated: incUpdated,
                noteUr: incNoteUr.isNotEmpty ? incNoteUr : currNoteUr,
                noteEn: incNoteEn.isNotEmpty ? incNoteEn : currNoteEn,
              );
            }
          }
          // Otherwise this prayer was not set by the committee in Firestore; preserve whatever Gist/current has.
          return PrayerMergeResult(
            time: cleanCurr,
            updated: currUpdated,
            noteUr: currNoteUr,
            noteEn: currNoteEn,
          );
        }
      }

      // If current has no time specified, take incoming unless current was explicitly cleared on a newer date
      if (cleanCurr.isEmpty || cleanCurr == '-' || cleanCurr.toLowerCase() == 'off') {
        if (currUpdated.isNotEmpty && incUpdated.isNotEmpty) {
          final currDt = _parseDate(currUpdated);
          final incDt = _parseDate(incUpdated);
          final cmp = _compareDatesWithPrecedence(
            dateA: incDt,
            dateB: currDt,
            isAFirestore: isIncomingFirestore,
          );
          if (cmp <= 0) {
            return PrayerMergeResult(
              time: isMaghrib ? 'Sunset' : '',
              updated: currUpdated,
              noteUr: currNoteUr.isNotEmpty ? currNoteUr : incNoteUr,
              noteEn: currNoteEn.isNotEmpty ? currNoteEn : incNoteEn,
            );
          }
        }
        return PrayerMergeResult(
          time: cleanInc,
          updated: incUpdated,
          noteUr: incNoteUr.isNotEmpty ? incNoteUr : currNoteUr,
          noteEn: incNoteEn.isNotEmpty ? incNoteEn : currNoteEn,
        );
      }

      // Both have a time.
      final currDt = _parseDate(currUpdated);
      final incDt = _parseDate(incUpdated);

      // Both have a time.
      // If incoming is Firestore (or pending local update), Firestore ALWAYS takes precedence over
      // the static Gist baseline. Live committee updates must never be superseded by Gist.
      if (isIncomingFirestore) {
        return PrayerMergeResult(
          time: cleanInc,
          updated: incUpdated.isNotEmpty ? incUpdated : currUpdated,
          noteUr: incNoteUr.isNotEmpty ? incNoteUr : currNoteUr,
          noteEn: incNoteEn.isNotEmpty ? incNoteEn : currNoteEn,
        );
      }

      // If incoming is Gist and current already has a valid Firestore time, current (Firestore) wins!
      if (!isIncomingFirestore && cleanCurr.isNotEmpty) {
        return PrayerMergeResult(
          time: cleanCurr,
          updated: currUpdated,
          noteUr: currNoteUr.isNotEmpty ? currNoteUr : incNoteUr,
          noteEn: currNoteEn.isNotEmpty ? currNoteEn : incNoteEn,
        );
      }

      // If prayer times match and either side is explicitly Fixed (""), Fixed wins!
      final bool currIsFixed = cleanCurr.isNotEmpty && currUpdated.trim().isEmpty;
      final bool incIsFixed = cleanInc.isNotEmpty && incUpdated.trim().isEmpty;
      if (cleanCurr == cleanInc && (currIsFixed || incIsFixed)) {
        return PrayerMergeResult(
          time: cleanInc,
          updated: (currIsFixed && incIsFixed)
              ? ''
              : (isIncomingFirestore && incUpdated.trim().isNotEmpty ? incUpdated : ''),
          noteUr: incNoteUr.isNotEmpty ? incNoteUr : currNoteUr,
          noteEn: incNoteEn.isNotEmpty ? incNoteEn : currNoteEn,
        );
      }

      final cmp = _compareDatesWithPrecedence(
        dateA: incDt,
        dateB: currDt,
        isAFirestore: isIncomingFirestore,
      );

      if (cmp > 0) {
        // Incoming wins
        return PrayerMergeResult(
          time: cleanInc,
          updated: incUpdated,
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
  static const String _firestoreBundleUrl =
      'https://firestore.googleapis.com/v1/projects/$_firestoreProjectId/databases/(default)/documents/jamaat_bundle/all_masjids';
  static final Uri _firestoreCollectionUrl = Uri.parse(
    'https://firestore.googleapis.com/v1/projects/$_firestoreProjectId/databases/(default)/documents/$_firestoreCollection?pageSize=300',
  );
  DateTime? _lastFirestoreFetchTime;
  bool _isMirroringToGist = false;

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
        fields['${key}_updated'] = {'stringValue': updated};
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
  /// persists to local cache, and awaits sync to Cloud Firestore so all users receive it immediately.
  Future<bool> updateTimingForMasjid({
    required String masjidId,
    required JamaatTiming newTiming,
  }) async {
    try {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final now = DateTime.now();
      final todayStr = '${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]} ${now.year}';
      final gistBase = _gistTimings[masjidId] ?? _getDefaultTimingFor(masjidId);

      String ensureWinsOverGist(String newTime, String newUpdated, String? gistTime, String? gistUpdated) {
        if (gistBase == null) return newUpdated;
        final cleanNew = format12HourEnglish(newTime.trim());
        final cleanGist = format12HourEnglish((gistTime ?? '').trim());
        if (cleanNew != cleanGist) {
          if (newUpdated.trim().isEmpty) return todayStr;
          final newDt = _parseDate(newUpdated);
          final gistDt = _parseDate(gistUpdated);
          if (newDt == null || (gistDt != null && _compareCalendarDays(newDt, gistDt) < 0)) {
            final todayDt = _parseDate(todayStr);
            if (gistDt != null && todayDt != null && _compareCalendarDays(todayDt, gistDt) < 0) {
              return gistUpdated ?? todayStr;
            }
            return todayStr;
          }
        }
        return newUpdated;
      }

      final stampedTiming = JamaatTiming(
        fajr: newTiming.fajr,
        fajrUpdated: ensureWinsOverGist(newTiming.fajr, newTiming.fajrUpdated, gistBase?.fajr, gistBase?.fajrUpdated),
        fajrNoteUr: newTiming.fajrNoteUr,
        fajrNoteEn: newTiming.fajrNoteEn,
        zuhar: newTiming.zuhar,
        zuharUpdated: ensureWinsOverGist(newTiming.zuhar, newTiming.zuharUpdated, gistBase?.zuhar, gistBase?.zuharUpdated),
        zuharNoteUr: newTiming.zuharNoteUr,
        zuharNoteEn: newTiming.zuharNoteEn,
        asar: newTiming.asar,
        asarUpdated: ensureWinsOverGist(newTiming.asar, newTiming.asarUpdated, gistBase?.asar, gistBase?.asarUpdated),
        asarNoteUr: newTiming.asarNoteUr,
        asarNoteEn: newTiming.asarNoteEn,
        maghrib: newTiming.maghrib,
        maghribNoteUr: newTiming.maghribNoteUr,
        maghribNoteEn: newTiming.maghribNoteEn,
        isha: newTiming.isha,
        ishaUpdated: ensureWinsOverGist(newTiming.isha, newTiming.ishaUpdated, gistBase?.isha, gistBase?.ishaUpdated),
        ishaNoteUr: newTiming.ishaNoteUr,
        ishaNoteEn: newTiming.ishaNoteEn,
        jummah: newTiming.jummah,
        jummahUpdated: ensureWinsOverGist(newTiming.jummah, newTiming.jummahUpdated, gistBase?.jummah, gistBase?.jummahUpdated),
        jummahNoteUr: newTiming.jummahNoteUr,
        jummahNoteEn: newTiming.jummahNoteEn,
      );

      // 1. Instant in-memory cache update (protected against concurrent background overwrites)
      _pendingLocalTimings[masjidId] = stampedTiming;
      _firestoreTimings[masjidId] = stampedTiming;
      _recomputeEffectiveTiming(masjidId);
      final effective = _remoteCache[masjidId] ?? stampedTiming;

      // Update in _dynamicMasjids or create entry
      final index = _dynamicMasjids.indexWhere((m) => m.id == masjidId);
      if (index >= 0) {
        final m = _dynamicMasjids[index];
        _dynamicMasjids[index] = JamaatMasjidInfo(
          id: m.id,
          nameKey: m.nameKey,
          addressKey: m.addressKey,
          defaultTimings: effective,
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
          defaultTimings: effective,
          isHidden: local.isHidden,
          localizedNames: local.localizedNames,
          localizedAddresses: local.localizedAddresses,
          pin: _masjidPins[local.id],
        ));
      }

      notifyListeners();

      // 2. Persist to local storage (including pending queue)
      _persistCacheAsync(masjidId);

      // 3. Await Google Cloud Firestore sync (with retry) so all users receive the update immediately
      final synced = await _syncTimingToFirestore(masjidId, effective);
      if (synced) {
        _pendingLocalTimings.remove(masjidId);
        _persistPendingUpdatesAsync();
      }

      // 4. Sync to GitHub Gist in background (if Developer GitHub token is configured)
      _syncTimingToGistAsync(masjidId, effective);

      return synced;
    } catch (e) {
      debugPrint('Error saving updated timing for $masjidId: $e');
      return false;
    }
  }

  /// Registers a newly added masjid dynamically in memory, local persistent cache,
  /// and syncs baseline timing to Cloud Firestore and GitHub Gist.
  Future<bool> registerDynamicMasjid(JamaatMasjidInfo newMasjid) async {
    final index = _dynamicMasjids.indexWhere((m) => m.id == newMasjid.id);
    if (index >= 0) {
      _dynamicMasjids[index] = newMasjid;
    } else {
      _dynamicMasjids.add(newMasjid);
    }
    _gistTimings[newMasjid.id] = newMasjid.defaultTimings;
    _firestoreTimings[newMasjid.id] = newMasjid.defaultTimings;
    _remoteCache[newMasjid.id] = newMasjid.defaultTimings;
    _pendingLocalTimings.remove(newMasjid.id);
    if (newMasjid.pin != null && newMasjid.pin!.isNotEmpty) {
      _masjidPins[newMasjid.id] = newMasjid.pin!;
    }
    _locallyUpdatedMasjidIds.add(newMasjid.id);
    notifyListeners();
    _persistCacheAsync(newMasjid.id);
    final fsOk = await _syncTimingToFirestore(newMasjid.id, newMasjid.defaultTimings);
    _syncTimingToGistAsync(newMasjid.id, newMasjid.defaultTimings);
    return fsOk;
  }

  /// Synchronizes a masjid's Jama'at timing to the authoritative GitHub Gist (jamaat_times.json).
  Future<({bool success, String message})> syncMasjidTimingToGist(
    String masjidId, [
    JamaatTiming? timing,
  ]) async {
    final token = await DeveloperGistService.instance.getGistToken();
    if (token == null || token.isEmpty) {
      return (
        success: false,
        message: 'No GitHub Gist Token configured. Set it in Developer settings to enable Gist sync.',
      );
    }
    try {
      final list = getMasjidList();
      final masjid = list.firstWhere(
        (m) => m.id == masjidId,
        orElse: () => sukkurMasjids.firstWhere((m) => m.id == masjidId),
      );
      final activeTiming = timing ?? (_remoteCache[masjidId] ?? masjid.defaultTimings);
      final jsonMap = activeTiming.toJson();
      jsonMap['id'] = masjid.id;
      jsonMap['name'] = masjid.nameKey;
      jsonMap['address'] = masjid.addressKey;
      final pin = _masjidPins[masjid.id] ?? masjid.pin;
      if (pin != null && pin.isNotEmpty) {
        jsonMap['pin'] = pin;
      }
      if (masjid.localizedNames.isNotEmpty) {
        jsonMap['names'] = masjid.localizedNames;
      }
      if (masjid.localizedAddresses.isNotEmpty) {
        jsonMap['addresses'] = masjid.localizedAddresses;
      }

      final result = await DeveloperGistService.instance.saveMasjidToGist(jsonMap);
      if (result.success) {
        _gistTimings[masjidId] = activeTiming;
        debugPrint('Successfully synced timing for masjid $masjidId to GitHub Gist');
      } else {
        debugPrint('Gist sync notice for $masjidId: ${result.message}');
      }
      return result;
    } catch (e) {
      debugPrint('Background Gist sync error for $masjidId: $e');
      return (success: false, message: 'Gist sync error: $e');
    }
  }

  void _syncTimingToGistAsync(String masjidId, JamaatTiming timing) {
    syncMasjidTimingToGist(masjidId, timing);
  }

  String get masterAdminPin => _masterAdminPin;

  /// Updates a masjid's committee PIN in memory, local persistent cache,
  /// and syncs to GitHub Gist (jamaat_times.json).
  Future<({bool success, String message})> updateMasjidPin({
    required String masjidId,
    required String newPin,
  }) async {
    final cleanPin = newPin.trim();
    if (cleanPin.isEmpty) {
      return (success: false, message: 'PIN cannot be empty.');
    }

    _masjidPins[masjidId] = cleanPin;
    _persistCacheAsync(masjidId);

    final token = await DeveloperGistService.instance.getGistToken();
    if (token == null || token.isEmpty) {
      return (success: true, message: 'PIN updated locally! (GitHub token not set for Gist sync).');
    }

    try {
      final list = getMasjidList();
      final masjid = list.firstWhere(
        (m) => m.id == masjidId,
        orElse: () => sukkurMasjids.firstWhere((m) => m.id == masjidId),
      );
      final activeTiming = _remoteCache[masjidId] ?? masjid.defaultTimings;
      final jsonMap = activeTiming.toJson();
      jsonMap['id'] = masjid.id;
      jsonMap['name'] = masjid.nameKey;
      jsonMap['address'] = masjid.addressKey;
      jsonMap['pin'] = cleanPin;
      if (masjid.localizedNames.isNotEmpty) jsonMap['names'] = masjid.localizedNames;
      if (masjid.localizedAddresses.isNotEmpty) jsonMap['addresses'] = masjid.localizedAddresses;

      final res = await DeveloperGistService.instance.saveMasjidToGist(jsonMap);
      if (res.success) {
        return (success: true, message: 'Masjid PIN updated and synced to GitHub Gist!');
      } else {
        return (success: true, message: 'PIN updated locally. Gist notice: ${res.message}');
      }
    } catch (e) {
      return (success: false, message: 'Failed to sync PIN to Gist: $e');
    }
  }

  /// Updates the Master Admin PIN in memory, local persistent cache,
  /// and syncs to GitHub Gist (jamaat_times.json).
  Future<({bool success, String message})> updateMasterPin(String newMasterPin) async {
    final cleanPin = newMasterPin.trim();
    if (cleanPin.isEmpty) {
      return (success: false, message: 'Master PIN cannot be empty.');
    }

    _masterAdminPin = cleanPin;
    _persistCacheAsync('master_pin');

    final token = await DeveloperGistService.instance.getGistToken();
    if (token == null || token.isEmpty) {
      return (success: true, message: 'Master PIN updated locally! (GitHub token not set for Gist sync).');
    }

    try {
      final res = await DeveloperGistService.instance.updateMasterPinOnGist(cleanPin);
      if (res.success) {
        return (success: true, message: 'Master PIN updated and synced to GitHub Gist!');
      } else {
        return (success: true, message: 'Master PIN updated locally. Gist notice: ${res.message}');
      }
    } catch (e) {
      return (success: false, message: 'Failed to sync Master PIN to Gist: $e');
    }
  }

  static String _escapeFirestoreFieldPath(String key) {
    if (RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(key)) {
      return key;
    }
    return '`${key.replaceAll('`', r'\`')}`';
  }

  Future<bool> _syncTimingToFirestore(String masjidId, JamaatTiming timing) async {
    final safeField = _escapeFirestoreFieldPath(masjidId);
    final bundlePatchUrl = Uri.parse(
      '$_firestoreBundleUrl?updateMask.fieldPaths=${Uri.encodeQueryComponent(safeField)}',
    );
    final timingMap = timing.toJson();
    final pin = _masjidPins[masjidId];
    if (pin != null && pin.isNotEmpty) {
      timingMap['pin'] = pin;
    }
    // Include full masjid metadata so new masjids and name/address changes propagate instantly in 0s
    final allMasajid = getMasjidList(includeHidden: true);
    final masjidInfo = allMasajid.firstWhere(
      (m) => m.id == masjidId,
      orElse: () => sukkurMasjids.firstWhere((m) => m.id == masjidId, orElse: () => allMasajid.first),
    );
    timingMap['id'] = masjidId;
    timingMap['name'] = masjidInfo.nameKey;
    timingMap['address'] = masjidInfo.addressKey;
    if (masjidInfo.isHidden) timingMap['hidden'] = true;
    if (masjidInfo.localizedNames.isNotEmpty) timingMap['names'] = masjidInfo.localizedNames;
    if (masjidInfo.localizedAddresses.isNotEmpty) timingMap['addresses'] = masjidInfo.localizedAddresses;

    final bundleBody = json.encode({
      'fields': {
        masjidId: {
          'stringValue': json.encode(timingMap),
        },
      },
    });

    final legacyPatchUrl = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$_firestoreProjectId/databases/(default)/documents/$_firestoreCollection/$masjidId',
    );
    final legacyBody = json.encode(_timingToFirestoreFields(timing));

    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        // Primary: write to the single aggregated bundle document (1 read for all users!)
        final bundleRes = await http
            .patch(
              bundlePatchUrl,
              headers: const {'Content-Type': 'application/json'},
              body: bundleBody,
            )
            .timeout(const Duration(seconds: 8));

        if (bundleRes.statusCode >= 200 && bundleRes.statusCode < 300) {
          // Best-effort background sync to legacy per-masjid document for older app versions
          http
              .patch(
                legacyPatchUrl,
                headers: const {'Content-Type': 'application/json'},
                body: legacyBody,
              )
              .timeout(const Duration(seconds: 6))
              .catchError((_) => http.Response('', 500));
          debugPrint('Successfully synced timing for masjid $masjidId to Firestore bundle (attempt $attempt)');
          return true;
        } else {
          debugPrint('Firestore bundle sync returned status ${bundleRes.statusCode} (attempt $attempt): ${bundleRes.body}');
        }
      } catch (e) {
        debugPrint('Firestore sync error for masjid $masjidId (attempt $attempt): $e');
      }
      if (attempt < 2) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    return false;
  }

  Future<void> _seedFirestoreBundleFromCurrentMap() async {
    if (_firestoreTimings.isEmpty) return;
    try {
      final Map<String, dynamic> fields = {};
      final allMasajid = getMasjidList(includeHidden: true);
      _firestoreTimings.forEach((masjidId, timing) {
        final map = timing.toJson();
        final pin = _masjidPins[masjidId];
        if (pin != null && pin.isNotEmpty) {
          map['pin'] = pin;
        }
        final m = allMasajid.firstWhere(
          (x) => x.id == masjidId,
          orElse: () => sukkurMasjids.firstWhere((x) => x.id == masjidId, orElse: () => allMasajid.first),
        );
        map['id'] = masjidId;
        map['name'] = m.nameKey;
        map['address'] = m.addressKey;
        if (m.isHidden) map['hidden'] = true;
        if (m.localizedNames.isNotEmpty) map['names'] = m.localizedNames;
        if (m.localizedAddresses.isNotEmpty) map['addresses'] = m.localizedAddresses;

        fields[masjidId] = {'stringValue': json.encode(map)};
      });
      await http
          .patch(
            Uri.parse(_firestoreBundleUrl),
            headers: const {'Content-Type': 'application/json'},
            body: json.encode({'fields': fields}),
          )
          .timeout(const Duration(seconds: 8));
      debugPrint('Seeded Firestore single-document bundle with ${fields.length} masjids');
    } catch (e) {
      debugPrint('Failed to seed Firestore bundle: $e');
    }
  }

  Future<void> _autoMirrorFirestoreToGistIfDeveloper() async {
    if (_isMirroringToGist || _firestoreTimings.isEmpty) return;
    final token = await DeveloperGistService.instance.getGistToken();
    if (token == null || token.isEmpty) return;

    _isMirroringToGist = true;
    try {
      final currentData = await DeveloperGistService.instance.fetchJamaatTimesJson();
      if (currentData.isEmpty || currentData['masjids'] is! List) return;

      final List<Map<String, dynamic>> masjids = [];
      for (final item in (currentData['masjids'] as List)) {
        if (item is Map) {
          masjids.add(Map<String, dynamic>.from(item));
        }
      }

      bool anyDiff = false;
      for (int i = 0; i < masjids.length; i++) {
        final id = masjids[i]['id']?.toString().trim() ?? '';
        if (id.isEmpty || !_remoteCache.containsKey(id)) continue;
        final effective = _remoteCache[id]!;
        final gistTiming = JamaatTiming.fromJson(masjids[i]);
        if (format12HourEnglish(effective.fajr) != format12HourEnglish(gistTiming.fajr) ||
            format12HourEnglish(effective.zuhar) != format12HourEnglish(gistTiming.zuhar) ||
            format12HourEnglish(effective.asar) != format12HourEnglish(gistTiming.asar) ||
            format12HourEnglish(effective.isha) != format12HourEnglish(gistTiming.isha) ||
            format12HourEnglish(effective.jummah) != format12HourEnglish(gistTiming.jummah) ||
            effective.fajrUpdated != gistTiming.fajrUpdated ||
            effective.zuharUpdated != gistTiming.zuharUpdated ||
            effective.asarUpdated != gistTiming.asarUpdated ||
            effective.ishaUpdated != gistTiming.ishaUpdated ||
            effective.jummahUpdated != gistTiming.jummahUpdated) {
          final updatedMap = Map<String, dynamic>.from(masjids[i]);
          effective.toJson().forEach((k, v) {
            updatedMap[k] = v;
          });
          masjids[i] = updatedMap;
          anyDiff = true;
        }
      }

      // Ensure any locally registered dynamic masjids are retained in Gist
      for (final dyn in _dynamicMasjids) {
        if (!masjids.any((m) => m['id']?.toString().trim() == dyn.id)) {
          final dynMap = {
            'id': dyn.id,
            'name': dyn.nameKey,
            'address': dyn.addressKey,
            'hidden': dyn.isHidden,
            'pin': dyn.pin,
            'names': dyn.localizedNames,
            'addresses': dyn.localizedAddresses,
            ...dyn.defaultTimings.toJson(),
          };
          masjids.add(dynMap);
          anyDiff = true;
        }
      }

      if (anyDiff) {
        final gistData = Map<String, dynamic>.from(currentData);
        gistData['masjids'] = masjids;
        const encoder = JsonEncoder.withIndent('  ');
        await DeveloperGistService.instance.updateGistFiles(
          jamaatTimesContent: encoder.convert(gistData),
        );
        debugPrint('Auto-mirrored Imam Firestore updates to GitHub Gist!');
      }
    } catch (e) {
      debugPrint('Auto-mirror Firestore to Gist skipped: $e');
    } finally {
      _isMirroringToGist = false;
    }
  }

  Future<void> _flushPendingUpdates() async {
    if (_pendingLocalTimings.isEmpty) return;
    final pendingEntries = Map<String, JamaatTiming>.from(_pendingLocalTimings);
    bool anySynced = false;
    for (final entry in pendingEntries.entries) {
      final ok = await _syncTimingToFirestore(entry.key, entry.value);
      if (ok) {
        _pendingLocalTimings.remove(entry.key);
        anySynced = true;
      }
    }
    if (anySynced) {
      await _persistPendingUpdatesAsync();
    }
  }

  Future<void> _persistPendingUpdatesAsync() async {
    try {
      final prefs = await _getPrefs();
      if (_pendingLocalTimings.isEmpty) {
        await prefs.remove(prefKeyPendingUpdates);
      } else {
        final map = <String, dynamic>{};
        _pendingLocalTimings.forEach((k, v) => map[k] = v.toJson());
        await prefs.setString(prefKeyPendingUpdates, json.encode(map));
      }
    } catch (e) {
      debugPrint('Error persisting pending updates: $e');
    }
  }

  void _persistCacheAsync(String masjidId) async {
    try {
      final activeList = getMasjidList(includeHidden: true);
      final Map<String, dynamic> exportData = {
        'master_pin': _masterAdminPin,
        'masjids': activeList.map((m) {
          final t = _remoteCache[m.id] ?? m.defaultTimings;
          final jsonMap = t.toJson();
          jsonMap['id'] = m.id;
          jsonMap['name'] = m.nameKey;
          jsonMap['address'] = m.addressKey;
          if (m.isHidden) {
            jsonMap['hidden'] = true;
          }
          final pin = _masjidPins[m.id] ?? m.pin;
          if (pin != null && pin.isNotEmpty) {
            jsonMap['pin'] = pin;
          }
          if (m.localizedNames.isNotEmpty) jsonMap['names'] = m.localizedNames;
          if (m.localizedAddresses.isNotEmpty) jsonMap['addresses'] = m.localizedAddresses;
          return jsonMap;
        }).toList(),
      };

      final Map<String, dynamic> fsExport = {};
      _firestoreTimings.forEach((k, v) => fsExport[k] = v.toJson());

      final prefs = await _getPrefs();
      await prefs.setString(prefKeyJamaatCache, json.encode(exportData));
      await prefs.setString(prefKeyFirestoreCache, json.encode(fsExport));
      await _persistPendingUpdatesAsync();
    } catch (e) {
      debugPrint('Error persisting cache for $masjidId: $e');
    }
  }

  /// Fetches live timings from Google Cloud Firestore using the single-document bundle
  /// (`jamaat_bundle/all_masjids` = 1 Document Read instead of 85 reads!).
  Future<bool> fetchFirestoreTimings({bool force = false}) async {
    try {
      if (_pendingLocalTimings.isNotEmpty) {
        await _flushPendingUpdates();
      }

      if (!force &&
          _lastFirestoreFetchTime != null &&
          DateTime.now().difference(_lastFirestoreFetchTime!).inSeconds < 25 &&
          _firestoreTimings.isNotEmpty) {
        return true;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final bundleUrl = '$_firestoreBundleUrl?t=$timestamp';

      final bundleResponse = await (kIsWeb
              ? http.get(Uri.parse(bundleUrl))
              : http.get(
                  Uri.parse(bundleUrl),
                  headers: const {
                    'Accept': 'application/json',
                    'Cache-Control': 'no-cache, no-store, must-revalidate',
                    'Pragma': 'no-cache',
                    'Expires': '0',
                  },
                ))
          .timeout(const Duration(seconds: 8));

      if (bundleResponse.statusCode == 200) {
        final data = json.decode(bundleResponse.body);
        if (data is Map<String, dynamic> && data['fields'] is Map<String, dynamic>) {
          final fields = data['fields'] as Map<String, dynamic>;
          bool anyApplied = false;
          for (final entry in fields.entries) {
            final masjidId = entry.key;
            final valMap = entry.value;
            if (valMap is Map && valMap['stringValue'] != null) {
              try {
                final rawMap = json.decode(valMap['stringValue'].toString());
                if (rawMap is Map<String, dynamic>) {
                  if (rawMap['pin'] != null && rawMap['pin'].toString().trim().isNotEmpty) {
                    _masjidPins[masjidId] = rawMap['pin'].toString().trim();
                  }
                  final timing = JamaatTiming.fromJson(rawMap);
                  if (!_pendingLocalTimings.containsKey(masjidId)) {
                    _firestoreTimings[masjidId] = timing;
                  }
                  _recomputeEffectiveTiming(masjidId);

                  // Ingest custom / dynamic masjid metadata from Cloud Firestore bundle immediately
                  if (rawMap.containsKey('name') || rawMap.containsKey('names')) {
                    final name = rawMap['name']?.toString() ?? masjidId;
                    final address = rawMap['address']?.toString() ?? 'Sukkur';
                    final isHidden = rawMap['hidden'] == true;
                    final localizedNames = _extractLocalizedStrings(rawMap, 'name');
                    final localizedAddresses = _extractLocalizedStrings(rawMap, 'address');

                    final dynIdx = _dynamicMasjids.indexWhere((m) => m.id == masjidId);
                    if (dynIdx >= 0) {
                      if (!_locallyUpdatedMasjidIds.contains(masjidId)) {
                        _dynamicMasjids[dynIdx] = JamaatMasjidInfo(
                          id: masjidId,
                          nameKey: name,
                          addressKey: address,
                          defaultTimings: _remoteCache[masjidId] ?? timing,
                          isHidden: isHidden,
                          localizedNames: localizedNames.isNotEmpty ? localizedNames : _dynamicMasjids[dynIdx].localizedNames,
                          localizedAddresses: localizedAddresses.isNotEmpty ? localizedAddresses : _dynamicMasjids[dynIdx].localizedAddresses,
                          pin: _masjidPins[masjidId],
                        );
                      }
                    } else if (!sukkurMasjids.any((m) => m.id == masjidId)) {
                      _dynamicMasjids.add(JamaatMasjidInfo(
                        id: masjidId,
                        nameKey: name,
                        addressKey: address,
                        defaultTimings: _remoteCache[masjidId] ?? timing,
                        isHidden: isHidden,
                        localizedNames: localizedNames,
                        localizedAddresses: localizedAddresses,
                        pin: _masjidPins[masjidId],
                      ));
                    }
                  }

                  anyApplied = true;
                }
              } catch (_) {}
            }
          }
          if (anyApplied) {
            _lastFirestoreFetchTime = DateTime.now();
            notifyListeners();
            _persistCacheAsync('firestore_sync');
            _autoMirrorFirestoreToGistIfDeveloper();
            if (!force) {
              return true;
            }
          }
        }
      }

      // Check legacy per-masjid collection if bundle failed (non-200), or when force-refresh is requested
      // (e.g. user pulled to refresh or Developer hub opened), ensuring backward compatibility with Imams on v1.4.6.
      if (bundleResponse.statusCode != 200 || force) {
        final separator = _firestoreCollectionUrl.toString().contains('?') ? '&' : '?';
        final freshUrl = '$_firestoreCollectionUrl${separator}t=$timestamp';

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
                  if (!_pendingLocalTimings.containsKey(masjidId)) {
                    final existing = _firestoreTimings[masjidId];
                    if (existing != null) {
                      _firestoreTimings[masjidId] = mergePrayerByPrayer(
                        current: existing,
                        incoming: timing,
                        isIncomingFirestore: true,
                      );
                    } else {
                      _firestoreTimings[masjidId] = timing;
                    }
                  }
                  _recomputeEffectiveTiming(masjidId);
                  anyApplied = true;
                }
              }
            }
            if (anyApplied) {
              _lastFirestoreFetchTime = DateTime.now();
              notifyListeners();
              _persistCacheAsync('firestore_sync');
              _seedFirestoreBundleFromCurrentMap();
              _autoMirrorFirestoreToGistIfDeveloper();
              return true;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Firestore fetch error: $e');
    }
    return false;
  }

  Future<bool> _fetchGistBaselineInternal() async {
    if (_gistRawUrl.isEmpty) return false;
    try {
      // In developer mode with token, fetch directly from GitHub REST API to avoid 5-minute CDN cache
      final directJson = await DeveloperGistService.instance.fetchGistFileDirect('jamaat_times.json');
      if (directJson != null && directJson.isNotEmpty) {
        final applied = _parseAndApplyJson(directJson);
        if (applied) {
          notifyListeners();
          _persistCacheAsync('gist_direct_sync');
          return true;
        }
      }

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
          notifyListeners();
          _persistCacheAsync('gist_sync');
          return true;
        }
      }
    } catch (e) {
      debugPrint('Network error fetching Jamaat times from Gist: $e');
    }
    return false;
  }

  /// Fetches updated timings from Google Cloud Firestore and GitHub Gist in parallel.
  /// Firestore holds live real-time committee updates, while Gist provides
  /// any new masjid registrations and fallback defaults without ever overwriting newer Firestore times.
  Future<bool> fetchRemoteGistTimings({bool force = false}) async {
    if (!force && _ongoingRemoteSync != null) {
      return _ongoingRemoteSync!;
    }

    final future = _performRemoteSync(force: force);
    _ongoingRemoteSync = future;
    try {
      return await future;
    } finally {
      if (_ongoingRemoteSync == future) {
        _ongoingRemoteSync = null;
      }
    }
  }

  Future<bool> _performRemoteSync({bool force = false}) async {
    final results = await Future.wait<bool>([
      fetchFirestoreTimings(force: force),
      _fetchGistBaselineInternal(),
    ]);

    final anySuccess = results[0] || results[1];
    if (!anySuccess && _remoteCache.isEmpty) {
      await loadLocalCache();
    }
    return anySuccess;
  }

  /// Exports the entire database of all registered masajid and their current active timings
  /// formatted as valid JSON matching the GitHub Gist structure.
  String exportRawGistJson() {
    final activeList = getMasjidList(includeHidden: true);
    final Map<String, dynamic> exportData = {
      'master_pin': _masterAdminPin,
      'masjids': activeList.map((m) {
        final t = _remoteCache[m.id] ?? m.defaultTimings;
        final jsonMap = t.toJson();
        jsonMap['id'] = m.id;
        jsonMap['name'] = m.nameKey;
        jsonMap['address'] = m.addressKey;
        if (m.isHidden) {
          jsonMap['hidden'] = true;
        }
        final pin = _masjidPins[m.id] ?? m.pin;
        if (pin != null && pin.isNotEmpty) {
          jsonMap['pin'] = pin;
        }
        if (m.localizedNames.isNotEmpty) jsonMap['names'] = m.localizedNames;
        if (m.localizedAddresses.isNotEmpty) jsonMap['addresses'] = m.localizedAddresses;
        return jsonMap;
      }).toList(),
    };
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(exportData);
  }

  /// Clears local cache from SharedPreferences and in-memory stores,
  /// then re-fetches fresh data from Firestore and Gist.
  Future<void> clearCacheAndReload() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(prefKeyJamaatCache);
      await prefs.remove(prefKeyFirestoreCache);
      await prefs.remove(prefKeyPendingUpdates);

      _remoteCache.clear();
      _firestoreTimings.clear();
      _pendingLocalTimings.clear();
      _gistTimings.clear();

      await loadLocalCache();
      await fetchRemoteGistTimings(force: true);
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  /// Shifts a 12-hour formatted time string (e.g. "05:00 PM") by [deltaMinutes]
  static String shiftTimeString(String timeStr, int deltaMinutes) {
    try {
      final clean = timeStr.trim();
      final isPM = clean.toUpperCase().contains('PM');
      final isAM = clean.toUpperCase().contains('AM');
      final digits = clean.replaceAll(RegExp(r'[a-zA-Z]'), '').trim();
      final parts = digits.split(':');
      if (parts.length >= 2) {
        int h = int.parse(parts[0].trim());
        int m = int.parse(parts[1].trim());
        if (isPM && h < 12) h += 12;
        if (isAM && h == 12) h = 0;
        int totalMinutes = h * 60 + m + deltaMinutes;
        totalMinutes = (totalMinutes % 1440 + 1440) % 1440;
        int newH = totalMinutes ~/ 60;
        int newM = totalMinutes % 60;
        String period = newH >= 12 ? 'PM' : 'AM';
        if (newH > 12) newH -= 12;
        if (newH == 0) newH = 12;
        return '${newH.toString().padLeft(2, '0')}:${newM.toString().padLeft(2, '0')} $period';
      }
    } catch (_) {}
    return timeStr;
  }

  /// Bulk shifts a specific prayer timing across all non-hidden masajid (or selected IDs)
  /// by [deltaMinutes] (e.g. +15 or -15), updates timestamps, and persists to local cache and Firestore.
  Future<int> bulkShiftPrayerTiming({
    required String prayerKey,
    required int deltaMinutes,
    List<String>? targetMasjidIds,
  }) async {
    final now = DateTime.now();
    final dayStr = now.day.toString().padLeft(2, '0');
    final monthKeys = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
    final monthStr = monthKeys[now.month - 1].toUpperCase();
    final todayStamp = '$dayStr $monthStr ${now.year}';

    final allMasajid = getMasjidList(includeHidden: false);
    int count = 0;

    for (final m in allMasajid) {
      if (targetMasjidIds != null && !targetMasjidIds.contains(m.id)) continue;
      final current = getTimingFor(m);
      JamaatTiming updated;

      switch (prayerKey.toLowerCase()) {
        case 'fajr':
          final newTime = shiftTimeString(current.fajr, deltaMinutes);
          updated = JamaatTiming(
            fajr: newTime,
            fajrUpdated: todayStamp,
            fajrNoteUr: current.fajrNoteUr,
            fajrNoteEn: current.fajrNoteEn,
            zuhar: current.zuhar,
            zuharUpdated: current.zuharUpdated,
            zuharNoteUr: current.zuharNoteUr,
            zuharNoteEn: current.zuharNoteEn,
            asar: current.asar,
            asarUpdated: current.asarUpdated,
            asarNoteUr: current.asarNoteUr,
            asarNoteEn: current.asarNoteEn,
            maghrib: current.maghrib,
            maghribNoteUr: current.maghribNoteUr,
            maghribNoteEn: current.maghribNoteEn,
            isha: current.isha,
            ishaUpdated: current.ishaUpdated,
            ishaNoteUr: current.ishaNoteUr,
            ishaNoteEn: current.ishaNoteEn,
            jummah: current.jummah,
            jummahUpdated: current.jummahUpdated,
            jummahNoteUr: current.jummahNoteUr,
            jummahNoteEn: current.jummahNoteEn,
          );
          break;
        case 'zuhar':
          final newTime = shiftTimeString(current.zuhar, deltaMinutes);
          updated = JamaatTiming(
            fajr: current.fajr,
            fajrUpdated: current.fajrUpdated,
            fajrNoteUr: current.fajrNoteUr,
            fajrNoteEn: current.fajrNoteEn,
            zuhar: newTime,
            zuharUpdated: todayStamp,
            zuharNoteUr: current.zuharNoteUr,
            zuharNoteEn: current.zuharNoteEn,
            asar: current.asar,
            asarUpdated: current.asarUpdated,
            asarNoteUr: current.asarNoteUr,
            asarNoteEn: current.asarNoteEn,
            maghrib: current.maghrib,
            maghribNoteUr: current.maghribNoteUr,
            maghribNoteEn: current.maghribNoteEn,
            isha: current.isha,
            ishaUpdated: current.ishaUpdated,
            ishaNoteUr: current.ishaNoteUr,
            ishaNoteEn: current.ishaNoteEn,
            jummah: current.jummah,
            jummahUpdated: current.jummahUpdated,
            jummahNoteUr: current.jummahNoteUr,
            jummahNoteEn: current.jummahNoteEn,
          );
          break;
        case 'asar':
          final newTime = shiftTimeString(current.asar, deltaMinutes);
          updated = JamaatTiming(
            fajr: current.fajr,
            fajrUpdated: current.fajrUpdated,
            fajrNoteUr: current.fajrNoteUr,
            fajrNoteEn: current.fajrNoteEn,
            zuhar: current.zuhar,
            zuharUpdated: current.zuharUpdated,
            zuharNoteUr: current.zuharNoteUr,
            zuharNoteEn: current.zuharNoteEn,
            asar: newTime,
            asarUpdated: todayStamp,
            asarNoteUr: current.asarNoteUr,
            asarNoteEn: current.asarNoteEn,
            maghrib: current.maghrib,
            maghribNoteUr: current.maghribNoteUr,
            maghribNoteEn: current.maghribNoteEn,
            isha: current.isha,
            ishaUpdated: current.ishaUpdated,
            ishaNoteUr: current.ishaNoteUr,
            ishaNoteEn: current.ishaNoteEn,
            jummah: current.jummah,
            jummahUpdated: current.jummahUpdated,
            jummahNoteUr: current.jummahNoteUr,
            jummahNoteEn: current.jummahNoteEn,
          );
          break;
        case 'isha':
          final newTime = shiftTimeString(current.isha, deltaMinutes);
          updated = JamaatTiming(
            fajr: current.fajr,
            fajrUpdated: current.fajrUpdated,
            fajrNoteUr: current.fajrNoteUr,
            fajrNoteEn: current.fajrNoteEn,
            zuhar: current.zuhar,
            zuharUpdated: current.zuharUpdated,
            zuharNoteUr: current.zuharNoteUr,
            zuharNoteEn: current.zuharNoteEn,
            asar: current.asar,
            asarUpdated: current.asarUpdated,
            asarNoteUr: current.asarNoteUr,
            asarNoteEn: current.asarNoteEn,
            maghrib: current.maghrib,
            maghribNoteUr: current.maghribNoteUr,
            maghribNoteEn: current.maghribNoteEn,
            isha: newTime,
            ishaUpdated: todayStamp,
            ishaNoteUr: current.ishaNoteUr,
            ishaNoteEn: current.ishaNoteEn,
            jummah: current.jummah,
            jummahUpdated: current.jummahUpdated,
            jummahNoteUr: current.jummahNoteUr,
            jummahNoteEn: current.jummahNoteEn,
          );
          break;
        case 'jummah':
          final newTime = shiftTimeString(current.jummah, deltaMinutes);
          updated = JamaatTiming(
            fajr: current.fajr,
            fajrUpdated: current.fajrUpdated,
            fajrNoteUr: current.fajrNoteUr,
            fajrNoteEn: current.fajrNoteEn,
            zuhar: current.zuhar,
            zuharUpdated: current.zuharUpdated,
            zuharNoteUr: current.zuharNoteUr,
            zuharNoteEn: current.zuharNoteEn,
            asar: current.asar,
            asarUpdated: current.asarUpdated,
            asarNoteUr: current.asarNoteUr,
            asarNoteEn: current.asarNoteEn,
            maghrib: current.maghrib,
            maghribNoteUr: current.maghribNoteUr,
            maghribNoteEn: current.maghribNoteEn,
            isha: current.isha,
            ishaUpdated: current.ishaUpdated,
            ishaNoteUr: current.ishaNoteUr,
            ishaNoteEn: current.ishaNoteEn,
            jummah: newTime,
            jummahUpdated: todayStamp,
            jummahNoteUr: current.jummahNoteUr,
            jummahNoteEn: current.jummahNoteEn,
          );
          break;
        default:
          continue;
      }

      _firestoreTimings[m.id] = updated;
      _gistTimings[m.id] = updated;
      _recomputeEffectiveTiming(m.id);
      count++;
    }

    if (count > 0) {
      notifyListeners();
      _persistCacheAsync('bulk_shift');
      // Instant atomic batch sync: 1 single call to Firestore bundle document (under 1s)
      await _seedFirestoreBundleFromCurrentMap();
      // Background sync to GitHub Gist
      _autoMirrorFirestoreToGistIfDeveloper();
    }

    return count;
  }
}
