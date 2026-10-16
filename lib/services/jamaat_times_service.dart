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
    required this.fajrUpdated,
    this.fajrNoteUr = '',
    this.fajrNoteEn = '',
    required this.zuhar,
    this.zuharUpdated = '',
    this.zuharNoteUr = '',
    this.zuharNoteEn = '',
    required this.asar,
    required this.asarUpdated,
    this.asarNoteUr = '',
    this.asarNoteEn = '',
    required this.maghrib,
    this.maghribNoteUr = '',
    this.maghribNoteEn = '',
    required this.isha,
    required this.ishaUpdated,
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

  factory JamaatTiming.fromJson(Map<String, dynamic> json) {
    final rawDefault = json['last_updated'] ?? json['lastUpdated'] ?? '04 Oct 2026';
    final defaultDate = normalizeDate(rawDefault.toString());
    return JamaatTiming(
      fajr: json['fajr'] ?? '05:15 AM',
      fajrUpdated: json['fajr_updated'] != null ? normalizeDate(json['fajr_updated'].toString()) : (json['fajrUpdated'] != null ? normalizeDate(json['fajrUpdated'].toString()) : defaultDate),
      fajrNoteUr: json['fajr_note_ur']?.toString() ?? json['fajrNoteUr']?.toString() ?? json['fajr_note']?.toString() ?? '',
      fajrNoteEn: json['fajr_note_en']?.toString() ?? json['fajrNoteEn']?.toString() ?? '',
      zuhar: json['zuhar'] ?? '01:15 PM',
      zuharUpdated: json['zuhar_updated'] != null
          ? normalizeDate(json['zuhar_updated'].toString())
          : (json['zuharUpdated'] != null ? normalizeDate(json['zuharUpdated'].toString()) : ''),
      zuharNoteUr: json['zuhar_note_ur']?.toString() ?? json['zuharNoteUr']?.toString() ?? json['zuhar_note']?.toString() ?? '',
      zuharNoteEn: json['zuhar_note_en']?.toString() ?? json['zuharNoteEn']?.toString() ?? '',
      asar: json['asar'] ?? '04:45 PM',
      asarUpdated: json['asar_updated'] != null ? normalizeDate(json['asar_updated'].toString()) : (json['asarUpdated'] != null ? normalizeDate(json['asarUpdated'].toString()) : defaultDate),
      asarNoteUr: json['asar_note_ur']?.toString() ?? json['asarNoteUr']?.toString() ?? json['asar_note']?.toString() ?? '',
      asarNoteEn: json['asar_note_en']?.toString() ?? json['asarNoteEn']?.toString() ?? '',
      maghrib: json['maghrib'] ?? 'Sunset',
      maghribNoteUr: json['maghrib_note_ur']?.toString() ?? json['maghribNoteUr']?.toString() ?? json['maghrib_note']?.toString() ?? '',
      maghribNoteEn: json['maghrib_note_en']?.toString() ?? json['maghribNoteEn']?.toString() ?? '',
      isha: json['isha'] ?? '08:00 PM',
      ishaUpdated: json['isha_updated'] != null ? normalizeDate(json['isha_updated'].toString()) : (json['ishaUpdated'] != null ? normalizeDate(json['ishaUpdated'].toString()) : defaultDate),
      ishaNoteUr: json['isha_note_ur']?.toString() ?? json['ishaNoteUr']?.toString() ?? json['isha_note']?.toString() ?? '',
      ishaNoteEn: json['isha_note_en']?.toString() ?? json['ishaNoteEn']?.toString() ?? '',
      jummah: json['jummah'] ?? '01:15 PM',
      jummahUpdated: json['jummah_updated'] != null
          ? normalizeDate(json['jummah_updated'].toString())
          : (json['jummahUpdated'] != null ? normalizeDate(json['jummahUpdated'].toString()) : ''),
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

class JamaatMasjidInfo {
  final String id;
  final String nameKey;
  final String addressKey;
  final JamaatTiming defaultTimings;
  final bool isHidden;
  final Map<String, String> localizedNames;
  final Map<String, String> localizedAddresses;

  const JamaatMasjidInfo({
    required this.id,
    required this.nameKey,
    required this.addressKey,
    required this.defaultTimings,
    this.isHidden = false,
    this.localizedNames = const {},
    this.localizedAddresses = const {},
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
  ];

  final Map<String, JamaatTiming> _remoteCache = {};
  List<JamaatMasjidInfo> _dynamicMasjids = [];

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
            defaultTimings: local.defaultTimings,
            isHidden: false,
            localizedNames: remote.localizedNames.isNotEmpty ? remote.localizedNames : local.localizedNames,
            localizedAddresses: remote.localizedAddresses.isNotEmpty ? remote.localizedAddresses : local.localizedAddresses,
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
        final masjids = data['masjids'] as List;
        final List<JamaatMasjidInfo> fetchedList = [];
        for (final item in masjids) {
          if (item is Map<String, dynamic> && item.containsKey('id')) {
            final id = item['id'].toString();
            final name = item['name'] ?? item['nameKey'] ?? id;
            final address = item['address'] ?? item['addressKey'] ?? 'Sukkur';
            final isHidden = item['hidden'] == true || item['enabled'] == false || item['removed'] == true;
            final timing = JamaatTiming.fromJson(item);
            final localizedNames = _extractLocalizedStrings(item, 'name');
            final localizedAddresses = _extractLocalizedStrings(item, 'address');
            _remoteCache[id] = timing;
            fetchedList.add(JamaatMasjidInfo(
              id: id,
              nameKey: name,
              addressKey: address,
              defaultTimings: timing,
              isHidden: isHidden,
              localizedNames: localizedNames,
              localizedAddresses: localizedAddresses,
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
  Future<bool> fetchRemoteGistTimings() async {
    if (_gistRawUrl.isEmpty) return false;
    try {
      final separator = _gistRawUrl.contains('?') ? '&' : '?';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final freshUrl = '$_gistRawUrl${separator}t=$timestamp';

      // On Web (Chrome), do NOT pass custom headers (Cache-Control, Pragma, User-Agent)
      // because GitHub Gist rejects CORS preflight OPTIONS requests with 403.
      // A clean GET with ?t=timestamp bypasses Fastly CDN cache (X-Cache: MISS)
      // and satisfies browser CORS with Access-Control-Allow-Origin: *.
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
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(prefKeyJamaatCache, response.body);
          } catch (_) {}
          return true;
        }
      }
    } catch (e) {
      debugPrint('Network error fetching Jamaat times: $e');
      if (_remoteCache.isEmpty) {
        await loadLocalCache();
      }
    }
    return false;
  }
}
