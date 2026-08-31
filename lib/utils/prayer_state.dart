import '../models/namaz_timing.dart';

class PrayerStateResult {
  final PrayerTime prayer;
  final bool isElapsed; // true = show +elapsed, false = show −remaining
  final Duration duration;

  const PrayerStateResult({
    required this.prayer,
    required this.isElapsed,
    required this.duration,
  });
}

/// State for a calculated (world city) day: count down once we are within
/// [_calculatedLead] of the next prayer, otherwise count up from the last one.
const _calculatedLead = Duration(minutes: 40);

PrayerStateResult? _calculatedState(DateTime now, DayTiming today) {
  final entries = today.allTimings
      .map((p) => MapEntry(p, p.toDateTime(date: now)))
      .toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  if (entries.isEmpty) return null;

  for (final next in entries) {
    if (!now.isBefore(next.value)) continue;

    final past = entries.where((e) => !e.value.isAfter(now));
    final untilNext = next.value.difference(now);
    // Before the first prayer of the day there is nothing to count up from.
    if (past.isEmpty) {
      return PrayerStateResult(
          prayer: next.key, isElapsed: false, duration: untilNext);
    }
    
    final last = past.last;
    
    // Special rule for Sunrise -> Dhuhr (Wait 1 hour before counting down to Dhuhr)
    if (last.key.name == 'Tulu Aftab' && next.key.name == 'Zuhar') {
      final timeSinceSunrise = now.difference(last.value);
      if (timeSinceSunrise <= const Duration(hours: 1)) {
        return PrayerStateResult(
            prayer: last.key, isElapsed: true, duration: timeSinceSunrise);
      } else {
        return PrayerStateResult(
            prayer: next.key, isElapsed: false, duration: untilNext);
      }
    }
    
    if (untilNext <= _calculatedLead) {
      return PrayerStateResult(
          prayer: next.key, isElapsed: false, duration: untilNext);
    }
    
    return PrayerStateResult(
        prayer: last.key, isElapsed: true, duration: now.difference(last.value));
  }

  // Past Isha: count up from it until midnight rolls the day over.
  final last = entries.last;
  return PrayerStateResult(
      prayer: last.key, isElapsed: true, duration: now.difference(last.value));
}

/// Returns which prayer is currently active/highlighted and whether to show
/// elapsed (+) or remaining (−) time, based on the precise per-prayer rules.
PrayerStateResult? computePrayerState(DateTime now, DayTiming today) {
  // A calculated world city has only the six standard prayers, so the jantri
  // rules below (which pivot on Intiha e Sehar, Ishraq, Zawal and Misl Awwal)
  // cannot be applied - they would leave most of the day unmatched.
  if (today.isCalculated) return _calculatedState(now, today);

  final all = today.allTimings;

  PrayerTime? _find(String name) {
    try {
      return all.firstWhere((p) => p.name == name);
    } catch (_) {
      return null;
    }
  }

  DateTime _dt(PrayerTime p) => p.toDateTime(date: now);

  final subah   = _find('Intiha e Sehar');
  final fajar   = _find('Fajar');
  final tulu    = _find('Tulu Aftab');
  final ishraq  = _find('Ishraq');
  final zawal   = _find('Zawal');
  final zuhar   = _find('Zuhar');
  final misl    = _find('Misl Awwal');
  final asr     = _find('Asr Hanafi');
  final maghrib = _find('Maghrib');
  final isha    = _find('Isha');

  if (subah == null) return null;

  final midnight     = DateTime(now.year, now.month, now.day, 0, 0, 0);
  final nextMidnight = midnight.add(const Duration(days: 1));
  final elevenAm     = DateTime(now.year, now.month, now.day, 11, 0, 0);

  final subahDt   = _dt(subah);
  final fajarDt   = fajar   != null ? _dt(fajar)   : null;
  final tuluDt    = tulu    != null ? _dt(tulu)    : null;
  final ishraqDt  = ishraq  != null ? _dt(ishraq)  : null;
  final zawalDt   = zawal   != null ? _dt(zawal)   : null;
  final zuharDt   = zuhar   != null ? _dt(zuhar)   : null;
  final mislDt    = misl    != null ? _dt(misl)    : null;
  final asrDt     = asr     != null ? _dt(asr)     : null;
  final maghribDt = maghrib != null ? _dt(maghrib) : null;
  final ishaDt    = isha    != null ? _dt(isha)    : null;

  final subahPlus3   = subahDt.add(const Duration(minutes: 3));
  final tuluMinus40  = tuluDt?.subtract(const Duration(minutes: 40));
  final tuluPlus7    = tuluDt?.add(const Duration(minutes: 7));
  final zawalPlus3   = zawalDt?.add(const Duration(minutes: 3));
  final mislMinus30  = mislDt?.subtract(const Duration(minutes: 30));
  final asrMinus30   = asrDt?.subtract(const Duration(minutes: 30));
  final maghribMinus40 = maghribDt?.subtract(const Duration(minutes: 40));
  final ishaMinus40  = ishaDt?.subtract(const Duration(minutes: 40));

  PrayerStateResult _remaining(PrayerTime p, DateTime target) =>
      PrayerStateResult(prayer: p, isElapsed: false, duration: target.difference(now));

  PrayerStateResult _elapsed(PrayerTime p, DateTime start) =>
      PrayerStateResult(prayer: p, isElapsed: true, duration: now.difference(start));

  // ── 00:00 → Subah Sadiq: countdown to Subah Sadiq ──────────────────────
  if (now.isAfter(midnight) && now.isBefore(subahDt)) {
    return _remaining(subah, subahDt);
  }

  // ── Subah Sadiq → Subah Sadiq + 3 min: elapsed from Subah Sadiq ──────────
  if (!now.isBefore(subahDt) && now.isBefore(subahPlus3)) {
    return _elapsed(subah, subahDt);
  }

  // ── Subah Sadiq + 3 min → Fajar: countdown to Fajar ─────────────────────
  if (fajar != null && fajarDt != null &&
      !now.isBefore(subahPlus3) && now.isBefore(fajarDt)) {
    return _remaining(fajar, fajarDt);
  }

  // ── Fajar → Tulu−40min: elapsed from Fajar ──────────────────────────────
  if (fajar != null && fajarDt != null && tuluMinus40 != null &&
      !now.isBefore(fajarDt) && now.isBefore(tuluMinus40)) {
    return _elapsed(fajar, fajarDt);
  }

  // ── (no Fajar) Subah Sadiq + 3 min → Tulu−40min: elapsed from Subah ──────
  if (fajar == null && tuluMinus40 != null &&
      !now.isBefore(subahPlus3) && now.isBefore(tuluMinus40)) {
    return _elapsed(subah, subahDt);
  }

  // ── Tulu−40min → Tulu: countdown to Tulu ───────────────────────────────
  if (tulu != null && tuluDt != null && tuluMinus40 != null &&
      !now.isBefore(tuluMinus40) && now.isBefore(tuluDt)) {
    return _remaining(tulu, tuluDt);
  }

  // ── Tulu → Tulu+7min: elapsed from Tulu ────────────────────────────────
  if (tulu != null && tuluDt != null && tuluPlus7 != null &&
      !now.isBefore(tuluDt) && now.isBefore(tuluPlus7)) {
    return _elapsed(tulu, tuluDt);
  }

  // ── Tulu+7min → Ishraq: countdown to Ishraq ────────────────────────────
  if (ishraq != null && ishraqDt != null && tuluPlus7 != null &&
      !now.isBefore(tuluPlus7) && now.isBefore(ishraqDt)) {
    return _remaining(ishraq, ishraqDt);
  }

  // ── Ishraq → Ishraq + 1 Hour: elapsed from Ishraq ─────────────────────────────
  final ishraqPlus1Hour = ishraqDt?.add(const Duration(hours: 1));
  if (ishraq != null && ishraqDt != null && ishraqPlus1Hour != null &&
      !now.isBefore(ishraqDt) && now.isBefore(ishraqPlus1Hour)) {
    return _elapsed(ishraq, ishraqDt);
  }

  // ── Ishraq + 1 Hour → Zawal: countdown to Zawal ───────────────────────────────
  if (zawal != null && zawalDt != null && ishraqPlus1Hour != null &&
      !now.isBefore(ishraqPlus1Hour) && now.isBefore(zawalDt)) {
    return _remaining(zawal, zawalDt);
  }

  // ── Zawal → Zawal + 3 min: elapsed from Zawal ──────────────────────────
  if (zawal != null && zawalDt != null && zawalPlus3 != null &&
      !now.isBefore(zawalDt) && now.isBefore(zawalPlus3)) {
    return _elapsed(zawal, zawalDt);
  }

  // ── Zawal + 3 min → Zuhar: countdown to Zuhar ──────────────────────────
  if (zuhar != null && zuharDt != null && zawalPlus3 != null &&
      !now.isBefore(zawalPlus3) && now.isBefore(zuharDt)) {
    return _remaining(zuhar, zuharDt);
  }

  // ── Zuhar → Misl−30min: elapsed from Zuhar ──────────────────────────────
  if (zuhar != null && zuharDt != null && mislMinus30 != null &&
      !now.isBefore(zuharDt) && now.isBefore(mislMinus30)) {
    return _elapsed(zuhar, zuharDt);
  }

  // ── (no Zuhar) Zawal + 3 min → Misl−30min: elapsed from Zawal ──────────
  if (zuhar == null && zawal != null && zawalDt != null && mislMinus30 != null &&
      !now.isBefore(zawalPlus3!) && now.isBefore(mislMinus30)) {
    return _elapsed(zawal, zawalDt);
  }

  // ── Misl−30min → Misl: countdown to Misl ──────────────────────────────
  if (misl != null && mislDt != null && mislMinus30 != null &&
      !now.isBefore(mislMinus30) && now.isBefore(mislDt)) {
    return _remaining(misl, mislDt);
  }

  // ── Misl → Asr−30min: elapsed from Misl ───────────────────────────────
  if (misl != null && mislDt != null && asrMinus30 != null &&
      !now.isBefore(mislDt) && now.isBefore(asrMinus30)) {
    return _elapsed(misl, mislDt);
  }

  // ── Asr−30min → Asr: countdown to Asr ─────────────────────────────────
  if (asr != null && asrDt != null && asrMinus30 != null &&
      !now.isBefore(asrMinus30) && now.isBefore(asrDt)) {
    return _remaining(asr, asrDt);
  }

  // ── Asr → Maghrib−40min: elapsed from Asr ─────────────────────────────
  if (asr != null && asrDt != null && maghribMinus40 != null &&
      !now.isBefore(asrDt) && now.isBefore(maghribMinus40)) {
    return _elapsed(asr, asrDt);
  }

  // ── Maghrib−40min → Maghrib: countdown to Maghrib ─────────────────────
  if (maghrib != null && maghribDt != null && maghribMinus40 != null &&
      !now.isBefore(maghribMinus40) && now.isBefore(maghribDt)) {
    return _remaining(maghrib, maghribDt);
  }

  // ── Maghrib → Isha−40min: elapsed from Maghrib ────────────────────────
  if (maghrib != null && maghribDt != null && ishaMinus40 != null &&
      !now.isBefore(maghribDt) && now.isBefore(ishaMinus40)) {
    return _elapsed(maghrib, maghribDt);
  }

  // ── Isha−40min → Isha: countdown to Isha ──────────────────────────────
  if (isha != null && ishaDt != null && ishaMinus40 != null &&
      !now.isBefore(ishaMinus40) && now.isBefore(ishaDt)) {
    return _remaining(isha, ishaDt);
  }

  // ── Isha → 00:00: elapsed from Isha ───────────────────────────────────
  if (isha != null && ishaDt != null &&
      !now.isBefore(ishaDt) && now.isBefore(nextMidnight)) {
    return _elapsed(isha, ishaDt);
  }

  return null;
}
