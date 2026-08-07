import 'package:flutter_test/flutter_test.dart';
import 'package:sukkur_prayer_timings/data/quran_data.dart';
import 'package:sukkur_prayer_timings/widgets/pdf_mushaf_reader.dart';

/// The mushaf is one continuous run of 549 pages drawn from thirty separate
/// juz files. Every page the reader shows is decided by [locationForPage], so
/// if that mapping is wrong by even one page the reader silently shows the
/// wrong page of the Quran - the worst possible failure in this app, and one
/// no crash or exception would ever reveal.
///
/// Page counts per juz were read out of the PDFs themselves: juz 1 has 20
/// pages, juz 2-27 have 18, juz 28 and 29 have 20, and juz 30 has 21.
const _expectedPageCounts = <int, int>{
  1: 20,
  28: 20,
  29: 20,
  30: 21,
};

int expectedCount(int parah) => _expectedPageCounts[parah] ?? 18;

void main() {
  test('the parahs cover exactly 549 pages, with none missing or doubled', () {
    var total = 0;
    for (var parah = 1; parah <= 30; parah++) {
      total += parahPageCount(parah);
    }
    expect(total, kQuranPageCount);
  });

  test('each juz has the page count its file actually contains', () {
    for (var parah = 1; parah <= 30; parah++) {
      expect(parahPageCount(parah), expectedCount(parah),
          reason: 'parah $parah spans the wrong number of pages');
    }
  });

  test('parahs run end to end with no gap and no overlap', () {
    expect(parahFirstPage(1), 1);
    expect(parahLastPage(30), kQuranPageCount);
    for (var parah = 1; parah < 30; parah++) {
      expect(parahFirstPage(parah + 1), parahLastPage(parah) + 1,
          reason: 'gap or overlap between parah $parah and ${parah + 1}');
    }
  });

  test('every page resolves inside its own juz', () {
    for (var page = 1; page <= kQuranPageCount; page++) {
      final where = locationForPage(page);
      expect(where.parah, inInclusiveRange(1, 30), reason: 'page $page');
      expect(where.localPage, inInclusiveRange(1, expectedCount(where.parah)),
          reason: 'page $page resolved to $where, outside that juz');
    }
  });

  /// The behaviour the reader depends on: turning one page never jumps. This is
  /// what stops repeated next/previous swipes from drifting onto a wrong page,
  /// because the page number alone decides what is shown - there is no state to
  /// fall out of step.
  test('turning a page always advances exactly one page', () {
    for (var page = 1; page < kQuranPageCount; page++) {
      final here = locationForPage(page);
      final next = locationForPage(page + 1);

      if (next.parah == here.parah) {
        expect(next.localPage, here.localPage + 1,
            reason: 'page $page -> ${page + 1} skipped within a juz');
      } else {
        expect(next.parah, here.parah + 1,
            reason: 'page $page -> ${page + 1} skipped a whole juz');
        expect(here.localPage, expectedCount(here.parah),
            reason: 'left parah ${here.parah} before its last page');
        expect(next.localPage, 1,
            reason: 'entered parah ${next.parah} past its first page');
      }
    }
  });

  test('going backwards mirrors going forwards', () {
    for (var page = 2; page <= kQuranPageCount; page++) {
      expect(locationForPage(page - 1), locationForPage(page - 1),
          reason: 'mapping is not stable for page ${page - 1}');
      final back = locationForPage(page - 1);
      final here = locationForPage(page);
      if (back.parah == here.parah) {
        expect(back.localPage, here.localPage - 1);
      } else {
        expect(back.parah, here.parah - 1);
        expect(here.localPage, 1);
      }
    }
  });

  test('reading the same page twice gives the same answer', () {
    // Repeated next/previous swipes land on pages already visited; the mapping
    // must not depend on how the reader got there.
    for (final page in [1, 20, 21, 39, 56, 274, 528, 529, 549]) {
      final first = locationForPage(page);
      for (var i = 0; i < 5; i++) {
        expect(locationForPage(page), first, reason: 'page $page drifted');
      }
    }
  });

  test('pages outside the mushaf are clamped, never wrapped', () {
    expect(locationForPage(0), locationForPage(1));
    expect(locationForPage(-5), locationForPage(1));
    expect(locationForPage(kQuranPageCount + 1), locationForPage(kQuranPageCount));
    expect(locationForPage(99999), locationForPage(kQuranPageCount));
  });

  test('each parah starts on the page QuranData says it does', () {
    // Parah 1 is the documented exception: QuranData starts it at page 2 where
    // Al-Fatiha begins, but its juz file starts at page 1.
    for (var parah = 2; parah <= 30; parah++) {
      expect(parahFirstPage(parah), QuranData.parahs[parah - 1].startPage,
          reason: 'parah $parah starts on the wrong page');
      expect(locationForPage(parahFirstPage(parah)).parah, parah);
      expect(locationForPage(parahFirstPage(parah)).localPage, 1);
    }
  });
}
