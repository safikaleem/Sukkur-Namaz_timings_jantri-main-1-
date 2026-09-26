import 'quran_data.dart';

/// 15-Line Saudi/Madani Mushaf Page Constants & Mapping
/// PDF has 3 index pages + 614 content pages = 617 total.
/// Printed page 1 = PDF page 4 (offset +3).
/// Quran text runs printed pages 2-605; pages 606-614 are back matter.
const int kQuran15LinePageCount = 611;

class Quran15LineData {
  /// Start page for each Parah in the 15-Line Mushaf layout.
  /// Start page for each Parah in the 15-Line Mushaf layout.
  static const Map<int, int> parahStartPages = {
    1: 3,
    2: 23,
    3: 43,
    4: 63,
    5: 83,
    6: 103,
    7: 123,
    8: 143,
    9: 163,
    10: 183,
    11: 203,
    12: 223,
    13: 243,
    14: 263,
    15: 283,
    16: 303,
    17: 323,
    18: 343,
    19: 363,
    20: 383,
    21: 403,
    22: 423,
    23: 443,
    24: 463,
    25: 483,
    26: 503,
    27: 523,
    28: 543,
    29: 563,
    30: 587,
  };

  /// Start page for each Surah in the 15-Line Mushaf layout.
  static const Map<int, int> surahStartPages = {
    1: 2,     // Al-Fatihah
    2: 3,     // Al-Baqarah
    3: 51,    // Ali 'Imran
    4: 78,    // An-Nisa
    5: 107,   // Al-Ma'idah
    6: 129,   // Al-An'am
    7: 152,   // Al-A'raf
    8: 178,   // Al-Anfal
    9: 188,   // At-Tawbah
    10: 209,  // Yunus
    11: 222,  // Hud
    12: 236,  // Yusuf
    13: 250,  // Ar-Ra'd
    14: 256,  // Ibrahim
    15: 262,  // Al-Hijr
    16: 268,  // An-Nahl
    17: 283,  // Al-Isra
    18: 294,  // Al-Kahf
    19: 306,  // Maryam
    20: 313,  // Taha
    21: 323,  // Al-Anbiya
    22: 332,  // Al-Hajj
    23: 343,  // Al-Mu'minun
    24: 351,  // An-Nur
    25: 360,  // Al-Furqan
    26: 367,  // Ash-Shu'ara
    27: 377,  // An-Naml
    28: 386,  // Al-Qasas
    29: 397,  // Al-'Ankabut
    30: 405,  // Ar-Rum
    31: 412,  // Luqman
    32: 416,  // As-Sajdah
    33: 419,  // Al-Ahzab
    34: 429,  // Saba
    35: 435,  // Fatir
    36: 441,  // Ya-Sin
    37: 446,  // As-Saffat
    38: 453,  // Sad
    39: 459,  // Az-Zumar
    40: 468,  // Ghafir
    41: 478,  // Fussilat
    42: 484,  // Ash-Shura
    43: 490,  // Az-Zukhruf
    44: 496,  // Ad-Dukhan
    45: 499,  // Al-Jathiyah
    46: 503,  // Al-Ahqaf
    47: 507,  // Muhammad
    48: 512,  // Al-Fath
    49: 516,  // Al-Hujurat
    50: 519,  // Qaf
    51: 521,  // Adh-Dhariyat
    52: 524,  // At-Tur
    53: 527,  // An-Najm
    54: 529,  // Al-Qamar
    55: 532,  // Ar-Rahman
    56: 535,  // Al-Waqi'ah
    57: 538,  // Al-Hadid
    58: 543,  // Al-Mujadila
    59: 546,  // Al-Hashr
    60: 550,  // Al-Mumtahanah
    61: 552,  // As-Saff
    62: 554,  // Al-Jumu'ah
    63: 555,  // Al-Munafiqun
    64: 557,  // At-Taghabun
    65: 559,  // At-Talaq
    66: 561,  // At-Tahrim
    67: 563,  // Al-Mulk
    68: 565,  // Al-Qalam
    69: 568,  // Al-Haqqah
    70: 570,  // Al-Ma'arij
    71: 572,  // Nuh
    72: 574,  // Al-Jinn
    73: 577,  // Al-Muzzammil
    74: 579,  // Al-Muddaththir
    75: 581,  // Al-Qiyamah
    76: 583,  // Al-Insan
    77: 585,  // Al-Mursalat
    78: 587,  // An-Naba
    79: 588,  // An-Nazi'at
    80: 590,  // 'Abasa
    81: 591,  // At-Takwir
    82: 592,  // Al-Infitar
    83: 593,  // Al-Mutaffifin
    84: 595,  // Al-Inshiqaq
    85: 596,  // Al-Buruj
    86: 597,  // At-Tariq
    87: 598,  // Al-A'la
    88: 598,  // Al-Ghashiyah
    89: 599,  // Al-Fajr
    90: 601,  // Al-Balad
    91: 601,  // Ash-Shams
    92: 602,  // Al-Layl
    93: 603,  // Ad-Duha
    94: 603,  // Ash-Sharh
    95: 604,  // At-Tin
    96: 604,  // Al-'Alaq
    97: 605,  // Al-Qadr
    98: 605,  // Al-Bayyinah
    99: 606,  // Az-Zalzalah
    100: 606, // Al-'Adiyat
    101: 607, // Al-Qari'ah
    102: 607, // At-Takathur
    103: 608, // Al-'Asr
    104: 608, // Al-Humazah
    105: 608, // Al-Fil
    106: 609, // Quraysh
    107: 609, // Al-Ma'un
    108: 609, // Al-Kawthar
    109: 609, // Al-Kafirun
    110: 610, // An-Nasr
    111: 610, // Al-Masad
    112: 610, // Al-Ikhlas
    113: 611, // Al-Falaq
    114: 611, // An-Nas
  };

  /// Returns the Parah number (1-30) for a given page (1-605) in 15-Line layout.
  static int getParahForPage(int page) {
    int clamped = page.clamp(1, kQuran15LinePageCount);
    for (int p = 30; p >= 1; p--) {
      if (clamped >= (parahStartPages[p] ?? 1)) return p;
    }
    return 1;
  }

  /// First page of a Parah in 15-Line layout.
  static int parahFirstPage(int parah) => parahStartPages[parah] ?? 2;

  /// Last page of a Parah in 15-Line layout.
  static int parahLastPage(int parah) => parah >= 30
      ? kQuran15LinePageCount
      : (parahStartPages[parah + 1] ?? (parah * 20 + 2)) - 1;

  /// Exact quarter pages for 15-Line layout (Arba/Ruba, Nisf, Salasa)
  static const Map<int, Map<String, int>> parahQuarters = {
    1: {'arba': 8, 'nisf': 13, 'salasa': 18},
    2: {'arba': 27, 'nisf': 33, 'salasa': 38},
    3: {'arba': 47, 'nisf': 53, 'salasa': 58},
    4: {'arba': 67, 'nisf': 73, 'salasa': 77},
    5: {'arba': 88, 'nisf': 92, 'salasa': 98},
    6: {'arba': 108, 'nisf': 114, 'salasa': 118},
    7: {'arba': 128, 'nisf': 133, 'salasa': 139},
    8: {'arba': 147, 'nisf': 151, 'salasa': 157},
    9: {'arba': 168, 'nisf': 174, 'salasa': 177},
    10: {'arba': 187, 'nisf': 194, 'salasa': 198},
    11: {'arba': 208, 'nisf': 213, 'salasa': 217},
    12: {'arba': 228, 'nisf': 232, 'salasa': 238},
    13: {'arba': 249, 'nisf': 253, 'salasa': 258},
    14: {'arba': 268, 'nisf': 273, 'salasa': 278},
    15: {'arba': 288, 'nisf': 292, 'salasa': 298},
    16: {'arba': 309, 'nisf': 313, 'salasa': 317},
    17: {'arba': 327, 'nisf': 332, 'salasa': 338},
    18: {'arba': 348, 'nisf': 353, 'salasa': 357},
    19: {'arba': 367, 'nisf': 373, 'salasa': 378},
    20: {'arba': 387, 'nisf': 394, 'salasa': 397},
    21: {'arba': 408, 'nisf': 414, 'salasa': 418},
    22: {'arba': 428, 'nisf': 432, 'salasa': 437},
    23: {'arba': 449, 'nisf': 453, 'salasa': 458},
    24: {'arba': 468, 'nisf': 474, 'salasa': 478},
    25: {'arba': 487, 'nisf': 492, 'salasa': 498},
    26: {'arba': 507, 'nisf': 514, 'salasa': 517},
    27: {'arba': 528, 'nisf': 533, 'salasa': 537},
    28: {'arba': 548, 'nisf': 552, 'salasa': 558},
    29: {'arba': 568, 'nisf': 574, 'salasa': 581},
    30: {'arba': 593, 'nisf': 599, 'salasa': 605},
  };

  /// Quarters for 15-Line layout (Ruba, Nisf, Salasa).
  static Map<String, int> getQuartersForParah(int parah) {
    final start = parahFirstPage(parah);
    final q = parahQuarters[parah];
    if (q != null) {
      return {
        'Ruba': q['arba'] ?? start,
        'Nisf': q['nisf'] ?? start,
        'Salasa': q['salasa'] ?? start,
      };
    }
    final end = parahLastPage(parah);
    final totalPages = end - start + 1;
    final step = totalPages / 4;

    return {
      'Ruba': (start + step * 0.25).round(),
      'Nisf': (start + step * 0.50).round(),
      'Salasa': (start + step * 0.75).round(),
    };
  }
}
