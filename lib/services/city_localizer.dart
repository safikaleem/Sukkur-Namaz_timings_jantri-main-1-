import 'multilingual_city_aliases.dart';

/// Provides dynamic localization for world cities across 10 supported languages:
/// English, Urdu, Sindhi, Arabic, Persian, Hindi, Bengali, Turkish, French, Indonesian.
class CityLocalizer {
  CityLocalizer._();

  /// Localizes [rawCityName] into [targetLang].
  static String localize(String rawCityName, String targetLang) {
    if (rawCityName.trim().isEmpty) return '';

    // Clean up city string (e.g. "Karachi, Pakistan" -> "Karachi")
    var city = rawCityName.split(',').first.trim();
    if (city.isEmpty) return rawCityName;

    // If already in Arabic/Perso-Arabic script, resolve canonical English name if needed
    if (RegExp(r'[\u0600-\u06FF]').hasMatch(city)) {
      final matches = MultilingualCityAliases.getMatchingEnglishCities(city);
      if (matches.isNotEmpty) {
        city = matches.first;
      }
    } else if (RegExp(r'[\u0900-\u097F]').hasMatch(city)) {
      // Hindi Devanagari script
      final matches = MultilingualCityAliases.getMatchingEnglishCities(city);
      if (matches.isNotEmpty) {
        city = matches.first;
      }
    } else if (RegExp(r'[\u0980-\u09FF]').hasMatch(city)) {
      // Bengali script
      final matches = MultilingualCityAliases.getMatchingEnglishCities(city);
      if (matches.isNotEmpty) {
        city = matches.first;
      }
    }

    final lower = city.toLowerCase();

    // 1. Direct dictionary match for well-known and Subcontinent / World cities
    final translation = _findTranslation(lower, targetLang);
    if (translation != null && translation.isNotEmpty) {
      return translation;
    }

    // 2. Language-specific transliteration fallback for any of the 235k world cities
    switch (targetLang.toLowerCase()) {
      case 'urdu':
        return _transliterateUrdu(city);
      case 'sindhi':
        return _transliterateSindhi(city);
      case 'arabic':
        return _transliterateArabic(city);
      case 'persian':
        return _transliteratePersian(city);
      case 'hindi':
        return _transliterateHindi(city);
      case 'bengali':
        return _transliterateBengali(city);
      case 'turkish':
        return _formatTurkish(city);
      case 'french':
      case 'indonesian':
      case 'english':
      default:
        return _formatTitleCase(city);
    }
  }

  static String? _findTranslation(String cityLower, String lang) {
    final entry = _cityTranslations[cityLower];
    if (entry != null) {
      final val = entry[lang];
      if (val != null && val.isNotEmpty) return val;
      // Fallbacks within script family
      if (lang == 'sindhi' && entry['urdu'] != null) {
        return _adaptUrduToSindhi(entry['urdu']!);
      }
      if (lang == 'persian' && entry['urdu'] != null) {
        return entry['urdu'];
      }
      if (lang == 'arabic' && entry['urdu'] != null) {
        return _adaptUrduToArabic(entry['urdu']!);
      }
      if (entry['english'] != null) {
        return entry['english'];
      }
    }
    return null;
  }

  static String _formatTitleCase(String text) {
    if (text.isEmpty) return '';
    return text
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + (w.length > 1 ? w.substring(1).toLowerCase() : ''))
        .join(' ');
  }

  static String _formatTurkish(String text) {
    final title = _formatTitleCase(text);
    return title.replaceAll('I', 'İ');
  }

  static String _adaptUrduToSindhi(String urdu) {
    return urdu
        .replaceAll('ک', 'ڪ')
        .replaceAll('گ', 'ڳ')
        .replaceAll('ٹ', 'ٽ')
        .replaceAll('ڈ', 'ڊ')
        .replaceAll('ڑ', 'ڙ')
        .replaceAll('ب', 'ٻ');
  }

  static String _adaptUrduToArabic(String urdu) {
    return urdu
        .replaceAll('پ', 'ب')
        .replaceAll('چ', 'تش')
        .replaceAll('ٹ', 'ت')
        .replaceAll('ڈ', 'د')
        .replaceAll('ڑ', 'ر')
        .replaceAll('گ', 'غ')
        .replaceAll('ژ', 'ز');
  }

  // ── Transliteration: English -> Urdu / Arabic script ───────────────────────
  static String _transliterateUrdu(String input) {
    if (input.isEmpty) return '';
    final words = input.split(' ');
    final resultWords = <String>[];

    for (final word in words) {
      if (word.isEmpty) continue;
      final w = word.toLowerCase();
      final sb = StringBuffer();
      int i = 0;

      while (i < w.length) {
        if (i + 3 <= w.length) {
          final three = w.substring(i, i + 3);
          if (three == 'bad') { sb.write('آباد'); i += 3; continue; }
          if (three == 'pur') { sb.write('پور'); i += 3; continue; }
          if (three == 'kot') { sb.write('کوٹ'); i += 3; continue; }
        }
        if (i + 2 <= w.length) {
          final two = w.substring(i, i + 2);
          if (two == 'kh') { sb.write('خ'); i += 2; continue; }
          if (two == 'gh') { sb.write('غ'); i += 2; continue; }
          if (two == 'ch') { sb.write('چ'); i += 2; continue; }
          if (two == 'sh') { sb.write('ش'); i += 2; continue; }
          if (two == 'th') { sb.write('تھ'); i += 2; continue; }
          if (two == 'ph') { sb.write('ف'); i += 2; continue; }
          if (two == 'dh') { sb.write('دھ'); i += 2; continue; }
          if (two == 'bh') { sb.write('بھ'); i += 2; continue; }
          if (two == 'jh') { sb.write('جھ'); i += 2; continue; }
          if (two == 'ee') { sb.write('ی'); i += 2; continue; }
          if (two == 'oo') { sb.write('و'); i += 2; continue; }
          if (two == 'ou') { sb.write('و'); i += 2; continue; }
          if (two == 'ai') { sb.write('ائی'); i += 2; continue; }
          if (two == 'ei') { sb.write('ئی'); i += 2; continue; }
          if (two == 'ng') { sb.write('نگ'); i += 2; continue; }
        }

        final c = w[i];
        switch (c) {
          case 'a':
            sb.write(i == 0 ? 'ا' : (i == w.length - 1 ? 'ہ' : 'ا'));
            break;
          case 'e':
            sb.write(i == 0 ? 'ای' : 'ے');
            break;
          case 'i':
            sb.write(i == 0 ? 'اِ' : 'ی');
            break;
          case 'o':
            sb.write(i == 0 ? 'او' : 'و');
            break;
          case 'u':
            sb.write(i == 0 ? 'اُ' : 'و');
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
          case 'v':
          case 'w': sb.write('و'); break;
          case 'x': sb.write('کس'); break;
          case 'y': sb.write('ی'); break;
          case 'z': sb.write('ز'); break;
          default:
            if (c != "'" && c != "-") {
              sb.write(c);
            }
        }
        i++;
      }
      resultWords.add(sb.toString());
    }

    return resultWords.join(' ');
  }

  static String _transliterateSindhi(String input) {
    return _adaptUrduToSindhi(_transliterateUrdu(input));
  }

  static String _transliterateArabic(String input) {
    return _adaptUrduToArabic(_transliterateUrdu(input));
  }

  static String _transliteratePersian(String input) {
    return _transliterateUrdu(input).replaceAll('ك', 'ک').replaceAll('ي', 'ی');
  }

  // ── Transliteration: English -> Hindi (Devanagari) ─────────────────────────
  static String _transliterateHindi(String input) {
    if (input.isEmpty) return '';
    final words = input.split(' ');
    final resultWords = <String>[];

    for (final word in words) {
      if (word.isEmpty) continue;
      final w = word.toLowerCase();
      final sb = StringBuffer();
      int i = 0;
      bool lastWasConsonant = false;

      while (i < w.length) {
        if (i + 3 <= w.length) {
          final three = w.substring(i, i + 3);
          if (three == 'chh') { sb.write('छ'); lastWasConsonant = true; i += 3; continue; }
          if (three == 'bad') {
            sb.write(lastWasConsonant ? 'ाबाद' : 'आबाद');
            lastWasConsonant = true;
            i += 3;
            continue;
          }
          if (three == 'pur') {
            sb.write('पुर');
            lastWasConsonant = true;
            i += 3;
            continue;
          }
        }
        if (i + 2 <= w.length) {
          final two = w.substring(i, i + 2);
          if (two == 'kh') { sb.write('ख'); lastWasConsonant = true; i += 2; continue; }
          if (two == 'gh') { sb.write('घ'); lastWasConsonant = true; i += 2; continue; }
          if (two == 'ch') { sb.write('च'); lastWasConsonant = true; i += 2; continue; }
          if (two == 'jh') { sb.write('झ'); lastWasConsonant = true; i += 2; continue; }
          if (two == 'th') { sb.write('थ'); lastWasConsonant = true; i += 2; continue; }
          if (two == 'dh') { sb.write('ध'); lastWasConsonant = true; i += 2; continue; }
          if (two == 'ph') { sb.write('फ'); lastWasConsonant = true; i += 2; continue; }
          if (two == 'bh') { sb.write('भ'); lastWasConsonant = true; i += 2; continue; }
          if (two == 'sh') { sb.write('श'); lastWasConsonant = true; i += 2; continue; }
          if (two == 'ng') {
            sb.write('ंग');
            lastWasConsonant = true;
            i += 2;
            continue;
          }
          if (two == 'aa') {
            sb.write(lastWasConsonant ? 'ा' : 'आ');
            lastWasConsonant = false;
            i += 2;
            continue;
          }
          if (two == 'ee') {
            sb.write(lastWasConsonant ? 'ी' : 'ई');
            lastWasConsonant = false;
            i += 2;
            continue;
          }
          if (two == 'oo') {
            sb.write(lastWasConsonant ? 'ू' : 'ऊ');
            lastWasConsonant = false;
            i += 2;
            continue;
          }
          if (two == 'ai') {
            sb.write(lastWasConsonant ? 'ै' : 'ऐ');
            lastWasConsonant = false;
            i += 2;
            continue;
          }
          if (two == 'au') {
            sb.write(lastWasConsonant ? 'ौ' : 'औ');
            lastWasConsonant = false;
            i += 2;
            continue;
          }
        }

        final c = w[i];
        switch (c) {
          case 'a':
            if (lastWasConsonant) {
              if (i == w.length - 1) sb.write('ा');
            } else {
              sb.write('अ');
            }
            lastWasConsonant = false;
            break;
          case 'e':
            sb.write(lastWasConsonant ? 'े' : 'ए');
            lastWasConsonant = false;
            break;
          case 'i':
            sb.write(lastWasConsonant ? 'ि' : 'इ');
            lastWasConsonant = false;
            break;
          case 'o':
            sb.write(lastWasConsonant ? 'ो' : 'ओ');
            lastWasConsonant = false;
            break;
          case 'u':
            sb.write(lastWasConsonant ? 'ु' : 'उ');
            lastWasConsonant = false;
            break;
          case 'b': sb.write('ब'); lastWasConsonant = true; break;
          case 'c':
            if (i + 1 < w.length && (w[i+1] == 'e' || w[i+1] == 'i' || w[i+1] == 'y')) {
              sb.write('स');
            } else {
              sb.write('क');
            }
            lastWasConsonant = true;
            break;
          case 'd': sb.write('ड'); lastWasConsonant = true; break;
          case 'f': sb.write('फ़'); lastWasConsonant = true; break;
          case 'g': sb.write('ग'); lastWasConsonant = true; break;
          case 'h': sb.write('ह'); lastWasConsonant = true; break;
          case 'j': sb.write('ज'); lastWasConsonant = true; break;
          case 'k': sb.write('क'); lastWasConsonant = true; break;
          case 'l': sb.write('ल'); lastWasConsonant = true; break;
          case 'm': sb.write('म'); lastWasConsonant = true; break;
          case 'n': sb.write('न'); lastWasConsonant = true; break;
          case 'p': sb.write('प'); lastWasConsonant = true; break;
          case 'q': sb.write('क़'); lastWasConsonant = true; break;
          case 'r': sb.write('र'); lastWasConsonant = true; break;
          case 's': sb.write('स'); lastWasConsonant = true; break;
          case 't': sb.write('ट'); lastWasConsonant = true; break;
          case 'v':
          case 'w': sb.write('व'); lastWasConsonant = true; break;
          case 'x': sb.write('क्स'); lastWasConsonant = true; break;
          case 'y': sb.write(lastWasConsonant ? 'ी' : 'य'); lastWasConsonant = true; break;
          case 'z': sb.write('ज़'); lastWasConsonant = true; break;
          default:
            if (c != "'" && c != "-") {
              sb.write(c);
            }
        }
        i++;
      }
      resultWords.add(sb.toString());
    }

    return resultWords.join(' ');
  }

  // ── Transliteration: English -> Bengali ────────────────────────────────────
  static String _transliterateBengali(String input) {
    if (input.isEmpty) return '';
    final words = input.split(' ');
    final resultWords = <String>[];

    for (final word in words) {
      if (word.isEmpty) continue;
      final w = word.toLowerCase();
      final sb = StringBuffer();
      int i = 0;
      bool lastWasConsonant = false;

      while (i < w.length) {
        if (i + 3 <= w.length) {
          final three = w.substring(i, i + 3);
          if (three == 'chh') { sb.write('ছ'); lastWasConsonant = true; i += 3; continue; }
          if (three == 'bad') {
            sb.write(lastWasConsonant ? 'াবাদ' : 'আবাদ');
            lastWasConsonant = true;
            i += 3;
            continue;
          }
          if (three == 'pur') {
            sb.write('পুর');
            lastWasConsonant = true;
            i += 3;
            continue;
          }
        }
        if (i + 2 <= w.length) {
          final two = w.substring(i, i + 2);
          if (two == 'kh') { sb.write('খ'); lastWasConsonant = true; i += 2; continue; }
          if (two == 'gh') { sb.write('ঘ'); lastWasConsonant = true; i += 2; continue; }
          if (two == 'ch') { sb.write('চ'); lastWasConsonant = true; i += 2; continue; }
          if (two == 'jh') { sb.write('ঝ'); lastWasConsonant = true; i += 2; continue; }
          if (two == 'th') { sb.write('থ'); lastWasConsonant = true; i += 2; continue; }
          if (two == 'dh') { sb.write('ধ'); lastWasConsonant = true; i += 2; continue; }
          if (two == 'ph') { sb.write('ফ'); lastWasConsonant = true; i += 2; continue; }
          if (two == 'bh') { sb.write('ভ'); lastWasConsonant = true; i += 2; continue; }
          if (two == 'sh') { sb.write('শ'); lastWasConsonant = true; i += 2; continue; }
          if (two == 'ng') {
            sb.write('ং');
            lastWasConsonant = true;
            i += 2;
            continue;
          }
          if (two == 'aa') {
            sb.write(lastWasConsonant ? 'া' : 'আ');
            lastWasConsonant = false;
            i += 2;
            continue;
          }
          if (two == 'ee') {
            sb.write(lastWasConsonant ? 'ী' : 'ঈ');
            lastWasConsonant = false;
            i += 2;
            continue;
          }
          if (two == 'oo') {
            sb.write(lastWasConsonant ? 'ূ' : 'ঊ');
            lastWasConsonant = false;
            i += 2;
            continue;
          }
          if (two == 'ai') {
            sb.write(lastWasConsonant ? 'ৈ' : 'ঐ');
            lastWasConsonant = false;
            i += 2;
            continue;
          }
          if (two == 'au') {
            sb.write(lastWasConsonant ? 'ৌ' : 'ঔ');
            lastWasConsonant = false;
            i += 2;
            continue;
          }
        }

        final c = w[i];
        switch (c) {
          case 'a':
            if (lastWasConsonant) {
              if (i == w.length - 1) sb.write('া');
            } else {
              sb.write('অ');
            }
            lastWasConsonant = false;
            break;
          case 'e':
            sb.write(lastWasConsonant ? 'ে' : 'এ');
            lastWasConsonant = false;
            break;
          case 'i':
            sb.write(lastWasConsonant ? 'ি' : 'ই');
            lastWasConsonant = false;
            break;
          case 'o':
            sb.write(lastWasConsonant ? 'ো' : 'ও');
            lastWasConsonant = false;
            break;
          case 'u':
            sb.write(lastWasConsonant ? 'ু' : 'উ');
            lastWasConsonant = false;
            break;
          case 'b': sb.write('ব'); lastWasConsonant = true; break;
          case 'c':
            if (i + 1 < w.length && (w[i+1] == 'e' || w[i+1] == 'i' || w[i+1] == 'y')) {
              sb.write('স');
            } else {
              sb.write('ক');
            }
            lastWasConsonant = true;
            break;
          case 'd': sb.write('ড'); lastWasConsonant = true; break;
          case 'f': sb.write('ফ'); lastWasConsonant = true; break;
          case 'g': sb.write('গ'); lastWasConsonant = true; break;
          case 'h': sb.write('হ'); lastWasConsonant = true; break;
          case 'j': sb.write('জ'); lastWasConsonant = true; break;
          case 'k': sb.write('ক'); lastWasConsonant = true; break;
          case 'l': sb.write('ল'); lastWasConsonant = true; break;
          case 'm': sb.write('ম'); lastWasConsonant = true; break;
          case 'n': sb.write('ন'); lastWasConsonant = true; break;
          case 'p': sb.write('প'); lastWasConsonant = true; break;
          case 'q': sb.write('ক'); lastWasConsonant = true; break;
          case 'r': sb.write('র'); lastWasConsonant = true; break;
          case 's': sb.write('স'); lastWasConsonant = true; break;
          case 't': sb.write('ট'); lastWasConsonant = true; break;
          case 'v':
          case 'w': sb.write('ভ'); lastWasConsonant = true; break;
          case 'x': sb.write('ক্স'); lastWasConsonant = true; break;
          case 'y': sb.write(lastWasConsonant ? 'ি' : 'য়'); lastWasConsonant = true; break;
          case 'z': sb.write('জ'); lastWasConsonant = true; break;
          default:
            if (c != "'" && c != "-") {
              sb.write(c);
            }
        }
        i++;
      }
      resultWords.add(sb.toString());
    }

    return resultWords.join(' ');
  }

  // ── Predefined Multilingual City Mappings ─────────────────────────────────
  static final Map<String, Map<String, String>> _cityTranslations = {
    // ── Pakistan ─────────────────────────────────────────────────────────────
    'karachi': {
      'urdu': 'کراچی',
      'sindhi': 'ڪراچي',
      'arabic': 'كراتشي',
      'persian': 'کراچی',
      'hindi': 'कराची',
      'bengali': 'করাচি',
      'turkish': 'Karaçi',
      'french': 'Karachi',
      'indonesian': 'Karachi',
      'english': 'Karachi',
    },
    'lahore': {
      'urdu': 'لاہور',
      'sindhi': 'لاهور',
      'arabic': 'لاهور',
      'persian': 'لاهور',
      'hindi': 'लाहौर',
      'bengali': 'লাহোর',
      'turkish': 'Lahor',
      'french': 'Lahore',
      'indonesian': 'Lahore',
      'english': 'Lahore',
    },
    'islamabad': {
      'urdu': 'اسلام آباد',
      'sindhi': 'اسلام آباد',
      'arabic': 'إسلام آباد',
      'persian': 'اسلام‌آباد',
      'hindi': 'इस्लामाबाद',
      'bengali': 'ইসলামাবাদ',
      'turkish': 'İslamabad',
      'french': 'Islamabad',
      'indonesian': 'Islamabad',
      'english': 'Islamabad',
    },
    'rawalpindi': {
      'urdu': 'راولپنڈی',
      'sindhi': 'راولپنڊي',
      'arabic': 'راولبندي',
      'persian': 'راولپندی',
      'hindi': 'रावलपिंडी',
      'bengali': 'রাওয়ালপিন্ডি',
      'turkish': 'Ravalpindi',
      'french': 'Rawalpindi',
      'indonesian': 'Rawalpindi',
      'english': 'Rawalpindi',
    },
    'faisalabad': {
      'urdu': 'فیصل آباد',
      'sindhi': 'فيصل آباد',
      'arabic': 'فيصل آباد',
      'persian': 'فیصل‌آباد',
      'hindi': 'फैसलाबाद',
      'bengali': 'ফয়সালাবাদ',
      'turkish': 'Faysalabad',
      'french': 'Faisalabad',
      'indonesian': 'Faisalabad',
      'english': 'Faisalabad',
    },
    'multan': {
      'urdu': 'ملتان',
      'sindhi': 'ملتان',
      'arabic': 'مولتان',
      'persian': 'ملتان',
      'hindi': 'मुल्तान',
      'bengali': 'মুলতান',
      'turkish': 'Multan',
      'french': 'Multan',
      'indonesian': 'Multan',
      'english': 'Multan',
    },
    'peshawar': {
      'urdu': 'پشاور',
      'sindhi': 'پشاور',
      'arabic': 'بيشاور',
      'persian': 'پیشاور',
      'hindi': 'पेशावर',
      'bengali': 'পেশোয়ার',
      'turkish': 'Peşaver',
      'french': 'Peshawar',
      'indonesian': 'Peshawar',
      'english': 'Peshawar',
    },
    'quetta': {
      'urdu': 'کوئٹہ',
      'sindhi': 'ڪوئٽا',
      'arabic': 'كويتا',
      'persian': 'کویته',
      'hindi': 'क्वेटा',
      'bengali': 'কোয়েটা',
      'turkish': 'Ketta',
      'french': 'Quetta',
      'indonesian': 'Quetta',
      'english': 'Quetta',
    },
    'sialkot': {
      'urdu': 'سیالکوٹ',
      'sindhi': 'سيالڪوٽ',
      'arabic': 'سيالكوت',
      'persian': 'سیالکوت',
      'hindi': 'सियालकोट',
      'bengali': 'শিয়ালকোট',
      'turkish': 'Siyalkot',
      'french': 'Sialkot',
      'indonesian': 'Sialkot',
      'english': 'Sialkot',
    },
    'gujranwala': {
      'urdu': 'گوجرانوالہ',
      'sindhi': 'گوجرانوالا',
      'arabic': 'غوجرانوالا',
      'persian': 'گوجرانوالا',
      'hindi': 'गुजरांवाला',
      'bengali': 'গুজরানওয়ালা',
      'turkish': 'Gucranvala',
      'french': 'Gujranwala',
      'indonesian': 'Gujranwala',
      'english': 'Gujranwala',
    },
    'gujrat': {
      'urdu': 'گجرات',
      'sindhi': 'گجرات',
      'arabic': 'غوجرات',
      'persian': 'گجرات',
      'hindi': 'गुजरात',
      'bengali': 'গুজরাট',
      'turkish': 'Gucrat',
      'french': 'Gujrat',
      'indonesian': 'Gujrat',
      'english': 'Gujrat',
    },
    'hyderabad': {
      'urdu': 'حیدرآباد',
      'sindhi': 'حيدرآباد',
      'arabic': 'حيدر آباد',
      'persian': 'حیدرآباد',
      'hindi': 'हैदराबाद',
      'bengali': 'হায়দরাবাদ',
      'turkish': 'Haydarabad',
      'french': 'Hyderabad',
      'indonesian': 'Hyderabad',
      'english': 'Hyderabad',
    },
    'larkana': {
      'urdu': 'لاڑکانہ',
      'sindhi': 'لاڙڪاڻو',
      'arabic': 'لاركانا',
      'persian': 'لارکانه',
      'hindi': 'लारकाना',
      'bengali': 'লারকানা',
      'turkish': 'Larkana',
      'french': 'Larkana',
      'indonesian': 'Larkana',
      'english': 'Larkana',
    },
    'nawabshah': {
      'urdu': 'نواب شاہ',
      'sindhi': 'نواب شاهه',
      'arabic': 'نواب شاه',
      'persian': 'نواب‌شاه',
      'hindi': 'नवाबशाह',
      'bengali': 'নওয়াবশাহ',
      'turkish': 'Nevabşah',
      'french': 'Nawabshah',
      'indonesian': 'Nawabshah',
      'english': 'Nawabshah',
    },
    'mirpur khas': {
      'urdu': 'میرپور خاص',
      'sindhi': 'ميرپور خاص',
      'arabic': 'ميربور خاص',
      'persian': 'میرپور خاص',
      'hindi': 'मीरपुर ख़ास',
      'bengali': 'মীরপুর খাস',
      'turkish': 'Mirpur Has',
      'french': 'Mirpur Khas',
      'indonesian': 'Mirpur Khas',
      'english': 'Mirpur Khas',
    },
    'mirpurkhas': {
      'urdu': 'میرپور خاص',
      'sindhi': 'ميرپور خاص',
      'arabic': 'ميربور خاص',
      'persian': 'میرپور خاص',
      'hindi': 'मीरपुर ख़ास',
      'bengali': 'মীরপুর খাস',
      'turkish': 'Mirpur Has',
      'french': 'Mirpur Khas',
      'indonesian': 'Mirpur Khas',
      'english': 'Mirpur Khas',
    },
    'jhang': {
      'urdu': 'جھنگ',
      'sindhi': 'جهنگ',
      'arabic': 'جهانغ',
      'persian': 'جهنگ',
      'hindi': 'झंग',
      'bengali': 'ঝং',
      'turkish': 'Jhang',
      'french': 'Jhang',
      'indonesian': 'Jhang',
      'english': 'Jhang',
    },
    'jhang sadr': {
      'urdu': 'جھنگ صدر',
      'sindhi': 'جهنگ صدر',
      'arabic': 'جهانغ صدر',
      'persian': 'جهنگ صدر',
      'hindi': 'झंग सदर',
      'bengali': 'ঝং সদর',
      'turkish': 'Jhang Sadr',
      'french': 'Jhang Sadr',
      'indonesian': 'Jhang Sadr',
      'english': 'Jhang Sadr',
    },
    'sargodha': {
      'urdu': 'سرگودھا',
      'sindhi': 'سرگوڌا',
      'arabic': 'سرغودها',
      'persian': 'سرگودها',
      'hindi': 'सरगोधा',
      'bengali': 'সারগোধা',
      'turkish': 'Sargodha',
      'french': 'Sargodha',
      'indonesian': 'Sargodha',
      'english': 'Sargodha',
    },
    'bahawalpur': {
      'urdu': 'بہاولپور',
      'sindhi': 'بهاولپور',
      'arabic': 'بهاولبور',
      'persian': 'بهاولپور',
      'hindi': 'बहावलपुर',
      'bengali': 'বাহাওয়ালপুর',
      'turkish': 'Bahavalpur',
      'french': 'Bahawalpur',
      'indonesian': 'Bahawalpur',
      'english': 'Bahawalpur',
    },
    'sheikhupura': {
      'urdu': 'شیخوپورہ',
      'sindhi': 'شيخوپورا',
      'arabic': 'شيخوبورة',
      'persian': 'شیخوپوره',
      'hindi': 'शेखूपुरा',
      'bengali': 'শেখুপুরা',
      'turkish': 'Şeyhupura',
      'french': 'Sheikhupura',
      'indonesian': 'Sheikhupura',
      'english': 'Sheikhupura',
    },
    'abbottabad': {
      'urdu': 'ایبٹ آباد',
      'sindhi': 'ايبٽ آباد',
      'arabic': 'أبوت آباد',
      'persian': 'ایبت‌آباد',
      'hindi': 'ऐबटाबाद',
      'bengali': 'অ্যাবোটাবাদ',
      'turkish': 'Abbottabad',
      'french': 'Abbottabad',
      'indonesian': 'Abbottabad',
      'english': 'Abbottabad',
    },
    'shikarpur': {
      'urdu': 'شکارپور',
      'sindhi': 'شڪارپور',
      'arabic': 'شيكاربور',
      'persian': 'شکارپور',
      'hindi': 'शिकारपुर',
      'bengali': 'শিকারপুর',
      'turkish': 'Şikarpur',
      'french': 'Shikarpur',
      'indonesian': 'Shikarpur',
      'english': 'Shikarpur',
    },
    'khairpur': {
      'urdu': 'خیرپور',
      'sindhi': 'خيرپور',
      'arabic': 'خيربور',
      'persian': 'خیرپور',
      'hindi': 'खैरपुर',
      'bengali': 'খাইরপুর',
      'turkish': 'Hayrpur',
      'french': 'Khairpur',
      'indonesian': 'Khairpur',
      'english': 'Khairpur',
    },
    'jacobabad': {
      'urdu': 'جیکب آباد',
      'sindhi': 'جيڪب آباد',
      'arabic': 'يعقوب آباد',
      'persian': 'جیکب‌آباد',
      'hindi': 'जैकोबाबाद',
      'bengali': 'জ্যাকোবাবাদ',
      'turkish': 'Jakobabad',
      'french': 'Jacobabad',
      'indonesian': 'Jacobabad',
      'english': 'Jacobabad',
    },
    'ghotki': {
      'urdu': 'گھوٹکی',
      'sindhi': 'گهوٽڪي',
      'arabic': 'غوتكي',
      'persian': 'گوتکی',
      'hindi': 'घोटकी',
      'bengali': 'ঘোটকি',
      'turkish': 'Ghotki',
      'french': 'Ghotki',
      'indonesian': 'Ghotki',
      'english': 'Ghotki',
    },
    'badin': {
      'urdu': 'بدین',
      'sindhi': 'بدين',
      'arabic': 'بدين',
      'persian': 'بدین',
      'hindi': 'बदीन',
      'bengali': 'বদিন',
      'turkish': 'Badin',
      'french': 'Badin',
      'indonesian': 'Badin',
      'english': 'Badin',
    },
    'thatta': {
      'urdu': 'ٹھٹھہ',
      'sindhi': 'ٺٽو',
      'arabic': 'تتا',
      'persian': 'تته',
      'hindi': 'ठट्ठा',
      'bengali': 'ঠাট্টা',
      'turkish': 'Thatta',
      'french': 'Thatta',
      'indonesian': 'Thatta',
      'english': 'Thatta',
    },
    'dadu': {
      'urdu': 'دادو',
      'sindhi': 'دادو',
      'arabic': 'دادو',
      'persian': 'دادو',
      'hindi': 'दादू',
      'bengali': 'দাদু',
      'turkish': 'Dadu',
      'french': 'Dadu',
      'indonesian': 'Dadu',
      'english': 'Dadu',
    },
    'rohri': {
      'urdu': 'روہڑی',
      'sindhi': 'روهڙي',
      'arabic': 'روهري',
      'persian': 'روهری',
      'hindi': 'रोहड़ी',
      'bengali': 'রোহরি',
      'turkish': 'Rohri',
      'french': 'Rohri',
      'indonesian': 'Rohri',
      'english': 'Rohri',
    },
    'kotri': {
      'urdu': 'کوٹری',
      'sindhi': 'ڪوٽڙي',
      'arabic': 'كوتري',
      'persian': 'کوتری',
      'hindi': 'कोटड़ी',
      'bengali': 'কোটরি',
      'turkish': 'Kotri',
      'french': 'Kotri',
      'indonesian': 'Kotri',
      'english': 'Kotri',
    },
    'pano aqil': {
      'urdu': 'پنوعاقل',
      'sindhi': 'پنو عاقل',
      'arabic': 'بنو عاقل',
      'persian': 'پنو عاقل',
      'hindi': 'पन्नू आकिल',
      'bengali': 'পানো আকিল',
      'turkish': 'Pano Aqil',
      'french': 'Pano Aqil',
      'indonesian': 'Pano Aqil',
      'english': 'Pano Aqil',
    },
    'muzaffarabad': {
      'urdu': 'مظفر آباد',
      'sindhi': 'مظفر آباد',
      'arabic': 'مظفر آباد',
      'persian': 'مظفرآباد',
      'hindi': 'मुज़फ़्फ़राबाद',
      'bengali': 'মুজাফফরাবাদ',
      'turkish': 'Muzafferabad',
      'french': 'Muzaffarabad',
      'indonesian': 'Muzaffarabad',
      'english': 'Muzaffarabad',
    },
    'gilgit': {
      'urdu': 'گلگت',
      'sindhi': 'گلگت',
      'arabic': 'جلجت',
      'persian': 'گلگت',
      'hindi': 'गिलगित',
      'bengali': 'গিলগিট',
      'turkish': 'Gilgit',
      'french': 'Gilgit',
      'indonesian': 'Gilgit',
      'english': 'Gilgit',
    },
    'skardu': {
      'urdu': 'سکردو',
      'sindhi': 'سڪردو',
      'arabic': 'سكاردو',
      'persian': 'اسکردو',
      'hindi': 'स्कर्दू',
      'bengali': 'স্কার্দু',
      'turkish': 'Skardu',
      'french': 'Skardu',
      'indonesian': 'Skardu',
      'english': 'Skardu',
    },
    'gwadar': {
      'urdu': 'گوادر',
      'sindhi': 'گوادر',
      'arabic': 'غوادر',
      'persian': 'گوادر',
      'hindi': 'ग्वादर',
      'bengali': 'গওয়াদর',
      'turkish': 'Gvadar',
      'french': 'Gwadar',
      'indonesian': 'Gwadar',
      'english': 'Gwadar',
    },
    'kasur': {
      'urdu': 'قصور',
      'sindhi': 'قصور',
      'arabic': 'قصور',
      'persian': 'قصور',
      'hindi': 'कसूर',
      'bengali': 'কসুর',
      'turkish': 'Kasur',
      'french': 'Kasur',
      'indonesian': 'Kasur',
      'english': 'Kasur',
    },
    'okara': {
      'urdu': 'اوکاڑہ',
      'sindhi': 'اوڪاڙا',
      'arabic': 'أوكارا',
      'persian': 'اوکارا',
      'hindi': 'ओकारा',
      'bengali': 'ওকারা',
      'turkish': 'Okara',
      'french': 'Okara',
      'indonesian': 'Okara',
      'english': 'Okara',
    },
    'sahiwal': {
      'urdu': 'ساہیوال',
      'sindhi': 'ساهيوال',
      'arabic': 'ساهيوال',
      'persian': 'ساهیوال',
      'hindi': 'साहीवाल',
      'bengali': 'সাহিওয়াল',
      'turkish': 'Sahiwal',
      'french': 'Sahiwal',
      'indonesian': 'Sahiwal',
      'english': 'Sahiwal',
    },
    'rahim yar khan': {
      'urdu': 'رحیم یار خان',
      'sindhi': 'رحيم يار خان',
      'arabic': 'رحيم يار خان',
      'persian': 'رحیم‌یارخان',
      'hindi': 'रहीम यार ख़ान',
      'bengali': 'রহিম ইয়ার খান',
      'turkish': 'Rahim Yar Han',
      'french': 'Rahim Yar Khan',
      'indonesian': 'Rahim Yar Khan',
      'english': 'Rahim Yar Khan',
    },

    // ── Middle East & Islamic Holy Cities ─────────────────────────────────────
    'makkah': {
      'urdu': 'مکہ مکرمہ',
      'sindhi': 'مڪه مڪرمه',
      'arabic': 'مكة المكرمة',
      'persian': 'مکه مکرمه',
      'hindi': 'मक्का',
      'bengali': 'মক্কা',
      'turkish': 'Mekke',
      'french': 'La Mecque',
      'indonesian': 'Mekkah',
      'english': 'Makkah',
    },
    'mecca': {
      'urdu': 'مکہ مکرمہ',
      'sindhi': 'مڪه مڪرمه',
      'arabic': 'مكة المكرمة',
      'persian': 'مکه مکرمه',
      'hindi': 'मक्का',
      'bengali': 'মক্কা',
      'turkish': 'Mekke',
      'french': 'La Mecque',
      'indonesian': 'Mekkah',
      'english': 'Mecca',
    },
    'madinah': {
      'urdu': 'مدینہ منورہ',
      'sindhi': 'مدينو منورو',
      'arabic': 'المدينة المنورة',
      'persian': 'مدینه منوره',
      'hindi': 'मदीना',
      'bengali': 'মদিনা',
      'turkish': 'Medine',
      'french': 'Médine',
      'indonesian': 'Madinah',
      'english': 'Madinah',
    },
    'medina': {
      'urdu': 'مدینہ منورہ',
      'sindhi': 'مدينو منورو',
      'arabic': 'المدينة المنورة',
      'persian': 'مدینه منوره',
      'hindi': 'मदीना',
      'bengali': 'মদিনা',
      'turkish': 'Medine',
      'french': 'Médine',
      'indonesian': 'Madinah',
      'english': 'Medina',
    },
    'jerusalem': {
      'urdu': 'القدس',
      'sindhi': 'بيت المقدس',
      'arabic': 'القدس',
      'persian': 'قدس',
      'hindi': 'यरूशलम',
      'bengali': 'জেরুজালেম',
      'turkish': 'Kudüs',
      'french': 'Jérusalem',
      'indonesian': 'Yerusalem',
      'english': 'Jerusalem',
    },
    'dubai': {
      'urdu': 'دبئی',
      'sindhi': 'دبئي',
      'arabic': 'دبي',
      'persian': 'دبی',
      'hindi': 'दुबई',
      'bengali': 'দুবাই',
      'turkish': 'Dubai',
      'french': 'Dubaï',
      'indonesian': 'Dubai',
      'english': 'Dubai',
    },
    'abu dhabi': {
      'urdu': 'ابوظہبی',
      'sindhi': 'ابو ظهبي',
      'arabic': 'أبو ظبي',
      'persian': 'ابوظبی',
      'hindi': 'अबू धाबी',
      'bengali': 'আবুধাবি',
      'turkish': 'Abu Dabi',
      'french': 'Abou Dabi',
      'indonesian': 'Abu Dhabi',
      'english': 'Abu Dhabi',
    },
    'sharjah': {
      'urdu': 'شارجہ',
      'sindhi': 'شارجه',
      'arabic': 'الشارقة',
      'persian': 'شارجه',
      'hindi': 'शारजाह',
      'bengali': 'শারজাহ',
      'turkish': 'Şarika',
      'french': 'Charjah',
      'indonesian': 'Sharjah',
      'english': 'Sharjah',
    },
    'riyadh': {
      'urdu': 'ریاض',
      'sindhi': 'رياض',
      'arabic': 'الرياض',
      'persian': 'ریاض',
      'hindi': 'रियाद',
      'bengali': 'রিয়াদ',
      'turkish': 'Riyad',
      'french': 'Riyad',
      'indonesian': 'Riyadh',
      'english': 'Riyadh',
    },
    'jeddah': {
      'urdu': 'جدہ',
      'sindhi': 'جده',
      'arabic': 'جدة',
      'persian': 'جده',
      'hindi': 'जेद्दा',
      'bengali': 'জেদ্দা',
      'turkish': 'Cidde',
      'french': 'Djeddah',
      'indonesian': 'Jeddah',
      'english': 'Jeddah',
    },
    'doha': {
      'urdu': 'دوحہ',
      'sindhi': 'دوحه',
      'arabic': 'الدوحة',
      'persian': 'دوحه',
      'hindi': 'दोहा',
      'bengali': 'দোহা',
      'turkish': 'Doha',
      'french': 'Doha',
      'indonesian': 'Doha',
      'english': 'Doha',
    },
    'cairo': {
      'urdu': 'قاہرہ',
      'sindhi': 'قاهره',
      'arabic': 'القاهرة',
      'persian': 'قاهره',
      'hindi': 'काहिरा',
      'bengali': 'কায়রো',
      'turkish': 'Kahire',
      'french': 'Le Caire',
      'indonesian': 'Kairo',
      'english': 'Cairo',
    },
    'damascus': {
      'urdu': 'دمشق',
      'sindhi': 'دمشق',
      'arabic': 'دمشق',
      'persian': 'دمشق',
      'hindi': 'दमिश्क',
      'bengali': 'দামেস্ক',
      'turkish': 'Şam',
      'french': 'Damas',
      'indonesian': 'Damaskus',
      'english': 'Damascus',
    },
    'baghdad': {
      'urdu': 'بغداد',
      'sindhi': 'بغداد',
      'arabic': 'بغداد',
      'persian': 'بغداد',
      'hindi': 'बगदाद',
      'bengali': 'বাগদাদ',
      'turkish': 'Bağdat',
      'french': 'Bagdad',
      'indonesian': 'Bagdad',
      'english': 'Baghdad',
    },
    'tehran': {
      'urdu': 'تہران',
      'sindhi': 'تهران',
      'arabic': 'طهران',
      'persian': 'تهران',
      'hindi': 'तेहरान',
      'bengali': 'তেহরান',
      'turkish': 'Tahran',
      'french': 'Téhéran',
      'indonesian': 'Teheran',
      'english': 'Tehran',
    },
    'istanbul': {
      'urdu': 'استنبول',
      'sindhi': 'استنبول',
      'arabic': 'إسطنبول',
      'persian': 'استانبول',
      'hindi': 'इस्तांबुल',
      'bengali': 'ইস্তাম্বুল',
      'turkish': 'İstanbul',
      'french': 'Istanbul',
      'indonesian': 'Istanbul',
      'english': 'Istanbul',
    },
    'ankara': {
      'urdu': 'انقرہ',
      'sindhi': 'انقره',
      'arabic': 'أنقرة',
      'persian': 'آنکارا',
      'hindi': 'अंकारा',
      'bengali': 'আঙ্কারা',
      'turkish': 'Ankara',
      'french': 'Ankara',
      'indonesian': 'Ankara',
      'english': 'Ankara',
    },

    // ── South Asia ────────────────────────────────────────────────────────────
    'delhi': {
      'urdu': 'دہلی',
      'sindhi': 'دھلي',
      'arabic': 'دلهي',
      'persian': 'دهلی',
      'hindi': 'दिल्ली',
      'bengali': 'দিল্লি',
      'turkish': 'Delhi',
      'french': 'Delhi',
      'indonesian': 'Delhi',
      'english': 'Delhi',
    },
    'new delhi': {
      'urdu': 'نئی دہلی',
      'sindhi': 'نئين دھلي',
      'arabic': 'نيودلهي',
      'persian': 'دهلی نو',
      'hindi': 'नई दिल्ली',
      'bengali': 'নতুন দিল্লি',
      'turkish': 'Yeni Delhi',
      'french': 'New Delhi',
      'indonesian': 'New Delhi',
      'english': 'New Delhi',
    },
    'mumbai': {
      'urdu': 'ممبئی',
      'sindhi': 'ممبئي',
      'arabic': 'مومباي',
      'persian': 'بمبئی',
      'hindi': 'मुंबई',
      'bengali': 'মুম্বই',
      'turkish': 'Mumbai',
      'french': 'Bombay',
      'indonesian': 'Mumbai',
      'english': 'Mumbai',
    },
    'kolkata': {
      'urdu': 'کولکتہ',
      'sindhi': 'ڪولڪتا',
      'arabic': 'كولكاتا',
      'persian': 'کلکته',
      'hindi': 'कोलकाता',
      'bengali': 'কলকাতা',
      'turkish': 'Kalküta',
      'french': 'Calcutta',
      'indonesian': 'Kolkata',
      'english': 'Kolkata',
    },
    'dhaka': {
      'urdu': 'ڈھاکہ',
      'sindhi': 'ڍاڪا',
      'arabic': 'دكا',
      'persian': 'داکا',
      'hindi': 'ढाका',
      'bengali': 'ঢাকা',
      'turkish': 'Dakka',
      'french': 'Dacca',
      'indonesian': 'Dhaka',
      'english': 'Dhaka',
    },
    'chittagong': {
      'urdu': 'چٹاگانگ',
      'sindhi': 'چٽاگانگ',
      'arabic': 'شيتاغونغ',
      'persian': 'چیتاگونگ',
      'hindi': 'चटगाँव',
      'bengali': 'চট্টগ্রাম',
      'turkish': 'Çittagong',
      'french': 'Chittagong',
      'indonesian': 'Chittagong',
      'english': 'Chittagong',
    },
    'kabul': {
      'urdu': 'کابل',
      'sindhi': 'ڪابل',
      'arabic': 'كابول',
      'persian': 'کابل',
      'hindi': 'काबुल',
      'bengali': 'কাবুল',
      'turkish': 'Kabil',
      'french': 'Kaboul',
      'indonesian': 'Kabul',
      'english': 'Kabul',
    },

    // ── Global Capitals & Major World Cities ──────────────────────────────────
    'london': {
      'urdu': 'لندن',
      'sindhi': 'لنڊن',
      'arabic': 'لندن',
      'persian': 'لندن',
      'hindi': 'लंदन',
      'bengali': 'লন্ডন',
      'turkish': 'Londra',
      'french': 'Londres',
      'indonesian': 'London',
      'english': 'London',
    },
    'paris': {
      'urdu': 'پیرس',
      'sindhi': 'پيرس',
      'arabic': 'باريس',
      'persian': 'پاریس',
      'hindi': 'पेरिस',
      'bengali': 'প্যারিস',
      'turkish': 'Paris',
      'french': 'Paris',
      'indonesian': 'Paris',
      'english': 'Paris',
    },
    'new york': {
      'urdu': 'نیویارک',
      'sindhi': 'نيويارڪ',
      'arabic': 'نيويورك',
      'persian': 'نیویورک',
      'hindi': 'न्यूयॉर्क',
      'bengali': 'নিউ ইয়র্ক',
      'turkish': 'New York',
      'french': 'New York',
      'indonesian': 'New York',
      'english': 'New York',
    },
    'tokyo': {
      'urdu': 'ٹوکیو',
      'sindhi': 'ٽوڪيو',
      'arabic': 'طوكيو',
      'persian': 'توکیو',
      'hindi': 'टोक्यो',
      'bengali': 'টোকিও',
      'turkish': 'Tokyo',
      'french': 'Tokyo',
      'indonesian': 'Tokyo',
      'english': 'Tokyo',
    },
    'beijing': {
      'urdu': 'بیجنگ',
      'sindhi': 'بيجنگ',
      'arabic': 'بكين',
      'persian': 'پکن',
      'hindi': 'बीजिंग',
      'bengali': 'বেইজিং',
      'turkish': 'Pekin',
      'french': 'Pékin',
      'indonesian': 'Beijing',
      'english': 'Beijing',
    },
    'moscow': {
      'urdu': 'ماسکو',
      'sindhi': 'ماسڪو',
      'arabic': 'موسكو',
      'persian': 'مسکو',
      'hindi': 'मास्को',
      'bengali': 'মস্কো',
      'turkish': 'Moskova',
      'french': 'Moscou',
      'indonesian': 'Moskwa',
      'english': 'Moscow',
    },
    'rome': {
      'urdu': 'روم',
      'sindhi': 'روم',
      'arabic': 'روما',
      'persian': 'رم',
      'hindi': 'रोम',
      'bengali': 'রোম',
      'turkish': 'Roma',
      'french': 'Rome',
      'indonesian': 'Roma',
      'english': 'Rome',
    },
    'berlin': {
      'urdu': 'برلن',
      'sindhi': 'برلن',
      'arabic': 'برلين',
      'persian': 'برلین',
      'hindi': 'बर्लिन',
      'bengali': 'বার্লিন',
      'turkish': 'Berlin',
      'french': 'Berlin',
      'indonesian': 'Berlin',
      'english': 'Berlin',
    },
  };
}
