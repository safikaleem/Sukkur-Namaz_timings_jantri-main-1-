import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/timings_data.dart';

class JamaatTiming {
  final String fajr;
  final String fajrUpdated;
  final String zuhar;
  final String asar;
  final String asarUpdated;
  final String maghrib;
  final String isha;
  final String ishaUpdated;
  final String jummah;

  const JamaatTiming({
    required this.fajr,
    required this.fajrUpdated,
    required this.zuhar,
    required this.asar,
    required this.asarUpdated,
    required this.maghrib,
    required this.isha,
    required this.ishaUpdated,
    required this.jummah,
  });

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
      zuhar: json['zuhar'] ?? '01:15 PM',
      asar: json['asar'] ?? '04:45 PM',
      asarUpdated: json['asar_updated'] != null ? normalizeDate(json['asar_updated'].toString()) : (json['asarUpdated'] != null ? normalizeDate(json['asarUpdated'].toString()) : defaultDate),
      maghrib: json['maghrib'] ?? 'Sunset',
      isha: json['isha'] ?? '08:00 PM',
      ishaUpdated: json['isha_updated'] != null ? normalizeDate(json['isha_updated'].toString()) : (json['ishaUpdated'] != null ? normalizeDate(json['ishaUpdated'].toString()) : defaultDate),
      jummah: json['jummah'] ?? '01:15 PM',
    );
  }

  Map<String, dynamic> toJson() => {
        'fajr': fajr,
        'fajr_updated': fajrUpdated,
        'zuhar': zuhar,
        'asar': asar,
        'asar_updated': asarUpdated,
        'maghrib': maghrib,
        'isha': isha,
        'isha_updated': ishaUpdated,
        'jummah': jummah,
      };
}

class JamaatMasjidInfo {
  final String id;
  final String nameKey;
  final String addressKey;
  final JamaatTiming defaultTimings;

  const JamaatMasjidInfo({
    required this.id,
    required this.nameKey,
    required this.addressKey,
    required this.defaultTimings,
  });
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
      nameKey: 'Ahmed Thanvi Masjid',
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
  ];

  final Map<String, JamaatTiming> _remoteCache = {};
  List<JamaatMasjidInfo> _dynamicMasjids = [];

  /// Optional Gist URL for live updates from GitHub Gist
  String _gistRawUrl =
      'https://gist.githubusercontent.com/safikaleem/2afecaa5e4b86ab5227ee00a7416646a/raw/jamaat_times.json';

  void setGistUrl(String url) {
    _gistRawUrl = url;
  }

  /// Returns active list of masjids (either from remote Gist or default fallback list)
  List<JamaatMasjidInfo> getMasjidList() {
    if (_dynamicMasjids.isNotEmpty) {
      return _dynamicMasjids;
    }
    return sukkurMasjids;
  }

  /// Helper to convert time string into English 12-hour format with AM/PM & padded hours
  static String format12HourEnglish(String timeStr) {
    try {
      final clean = timeStr.trim();
      final isPM = clean.contains('PM');
      final isAM = clean.contains('AM');
      final digits = clean.replaceAll('AM', '').replaceAll('PM', '').trim();
      final parts = digits.split(':');
      if (parts.length >= 2) {
        int h = int.parse(parts[0]);
        int m = int.parse(parts[1]);
        String period = (isPM || (!isAM && h >= 12)) ? 'PM' : 'AM';
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
    // 1. Fetch today's Maghrib time dynamically from Sukkur Jantri
    final today = TimingsData.instance.timingFor(DateTime.now());
    String dynamicMaghrib = info.defaultTimings.maghrib;
    if (today != null) {
      dynamicMaghrib = format12HourEnglish(today.maghrib);
    }

    // 2. Fetch base timings from remote cache or fallback defaults
    final base = _remoteCache.containsKey(info.id)
        ? _remoteCache[info.id]!
        : info.defaultTimings;

    return JamaatTiming(
      fajr: format12HourEnglish(base.fajr),
      fajrUpdated: base.fajrUpdated,
      zuhar: format12HourEnglish(base.zuhar),
      asar: format12HourEnglish(base.asar),
      asarUpdated: base.asarUpdated,
      maghrib: dynamicMaghrib,
      isha: format12HourEnglish(base.isha),
      ishaUpdated: base.ishaUpdated,
      jummah: format12HourEnglish(base.jummah),
    );
  }

  /// Fetches updated timings from GitHub Gist if available
  Future<void> fetchRemoteGistTimings() async {
    if (_gistRawUrl.isEmpty) return;
    try {
      final response = await http.get(Uri.parse(_gistRawUrl)).timeout(
            const Duration(seconds: 8),
          );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic> && data.containsKey('masjids')) {
          final masjids = data['masjids'] as List;
          final List<JamaatMasjidInfo> fetchedList = [];
          for (final item in masjids) {
            if (item is Map<String, dynamic> && item.containsKey('id')) {
              final id = item['id'].toString();
              final name = item['name'] ?? item['nameKey'] ?? id;
              final address = item['address'] ?? item['addressKey'] ?? 'Sukkur';
              final timing = JamaatTiming.fromJson(item);
              _remoteCache[id] = timing;
              fetchedList.add(JamaatMasjidInfo(
                id: id,
                nameKey: name,
                addressKey: address,
                defaultTimings: timing,
              ));
            }
          }
          if (fetchedList.isNotEmpty) {
            _dynamicMasjids = fetchedList;
          }
        }
      }
    } catch (_) {
      // Retain fallback timings silently on network failure
    }
  }
}
