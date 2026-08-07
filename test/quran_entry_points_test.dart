import 'package:flutter_test/flutter_test.dart';
import 'package:sukkur_prayer_timings/data/quran_data.dart';
import 'package:sukkur_prayer_timings/widgets/pdf_mushaf_reader.dart';

/// Every way into the mushaf hands the reader one mushaf page number, and the
/// reader opens exactly that page. These check that each entry point produces a
/// page that is inside the mushaf and inside the thing the reader tapped - so
/// opening Parah 3, Al-Kahf, or a quarter marker lands where it says.
void main() {
  test('every parah opens inside that parah', () {
    for (final parah in QuranData.parahs) {
      final page = parah.startPage;
      expect(page, inInclusiveRange(1, kQuranPageCount),
          reason: 'parah ${parah.number} starts outside the mushaf');

      final where = locationForPage(page);
      expect(where.parah, parah.number,
          reason: 'parah ${parah.number} would open in parah ${where.parah}');
    }
  });

  test('parahs 2-30 open on their own first page', () {
    // Parah 1 is the documented exception: it starts at page 2, where
    // Al-Fatiha begins, because page 1 of its juz file precedes the text.
    for (var i = 1; i < QuranData.parahs.length; i++) {
      final parah = QuranData.parahs[i];
      expect(locationForPage(parah.startPage).localPage, 1,
          reason: 'parah ${parah.number} does not open on its first page');
    }
    expect(locationForPage(QuranData.parahs.first.startPage).parah, 1);
  });

  test('every surah opens inside the mushaf', () {
    for (final surah in QuranData.surahs) {
      final page = QuranData.surahStartPages[surah.number];
      expect(page, isNotNull, reason: 'surah ${surah.number} has no start page');
      expect(page!, inInclusiveRange(1, kQuranPageCount),
          reason: '${surah.english} starts outside the mushaf');

      // Clamping must never move it - that would silently open a different page.
      expect(locationForPage(page), locationForPage(page.clamp(1, kQuranPageCount)),
          reason: '${surah.english} was clamped');
    }
  });

  test('Al-Kahf opens on its own page, not the start of its parah', () {
    final page = QuranData.surahStartPages[18]!;
    final where = locationForPage(page);
    expect(where.parah, QuranData.getParahForPage(page));
    // Al-Kahf begins partway into its parah, so this must not be page 1 of it -
    // that would mean the reader had fallen back to the parah's start.
    expect(where.localPage, greaterThan(1),
        reason: 'Al-Kahf would open at the top of parah ${where.parah}');
  });

  test('surahs are ordered by page, so none points at the wrong place', () {
    var previous = 0;
    for (final surah in QuranData.surahs) {
      final page = QuranData.surahStartPages[surah.number]!;
      expect(page, greaterThanOrEqualTo(previous),
          reason: '${surah.english} starts before the surah preceding it');
      previous = page;
    }
  });

  test('every quarter marker falls inside its own parah', () {
    for (final parah in QuranData.parahs) {
      final quarters = {
        'arba': parah.arba,
        'nisf': parah.nisf,
        'salasa': parah.salasa,
      };
      quarters.forEach((name, quarter) {
        expect(quarter.page, inInclusiveRange(1, kQuranPageCount),
            reason: 'parah ${parah.number} $name is outside the mushaf');

        final where = locationForPage(quarter.page);
        expect(where.parah, parah.number,
            reason: 'parah ${parah.number} $name (page ${quarter.page}) '
                'would open in parah ${where.parah}');
      });
    }
  });

  test('quarter markers run in order within each parah', () {
    for (final parah in QuranData.parahs) {
      expect(parah.arba.page, greaterThanOrEqualTo(parahFirstPage(parah.number)),
          reason: 'parah ${parah.number} arba precedes the parah');
      expect(parah.arba.page, lessThanOrEqualTo(parah.nisf.page),
          reason: 'parah ${parah.number} arba is after nisf');
      expect(parah.nisf.page, lessThanOrEqualTo(parah.salasa.page),
          reason: 'parah ${parah.number} nisf is after salasa');
      expect(parah.salasa.page, lessThanOrEqualTo(parahLastPage(parah.number)),
          reason: 'parah ${parah.number} salasa runs past the parah');
    }
  });
}
