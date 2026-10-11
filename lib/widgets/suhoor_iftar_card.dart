import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';
import '../l10n/world_translations.dart';
import '../data/timings_data.dart';
import '../models/namaz_timing.dart';

class SuhoorIftarCard extends StatefulWidget {
  final VoidCallback onDismiss;

  const SuhoorIftarCard({
    super.key,
    required this.onDismiss,
  });

  @override
  State<SuhoorIftarCard> createState() => _SuhoorIftarCardState();
}

class _SuhoorIftarCardState extends State<SuhoorIftarCard> {
  Timer? _timer;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final abs = d.abs();
    final h = abs.inHours.toString().padLeft(2, '0');
    final m = (abs.inMinutes % 60).toString().padLeft(2, '0');
    final s = (abs.inSeconds % 60).toString().padLeft(2, '0');
    final sign = d.isNegative ? '-' : '+';
    return '$sign${h}h ${m}m ${s}s';
  }

  String _loc(String lang, String en, String ur, String sd, String ar, String bn, String hi, String id, String tr, String fr, String fa) {
    switch (lang) {
      case 'urdu': return ur;
      case 'sindhi': return sd;
      case 'arabic': return ar;
      case 'bengali': return bn;
      case 'hindi': return hi;
      case 'indonesian': return id;
      case 'turkish': return tr;
      case 'french': return fr;
      case 'persian': return fa;
      default: return en;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final font = AppTheme.getFontForLanguage(context, settings.language);
    final lang = settings.language;

    final now = DateTime.now();
    final todayTiming = TimingsData.instance.timingFor(now);

    // 1. Suhoor End Time (Intiha-e-Sehar in Sukkur, or Subah Sadiq / Fajr)
    final suhoorPrayer = todayTiming?.allTimings.firstWhere(
      (p) => p.name == 'Intiha e Sehar' || p.name == 'Subah Sadiq' || p.name == 'Fajar' || p.name == 'Fajr',
      orElse: () => PrayerTime(name: 'Intiha e Sehar', urduName: 'انتہائے سحر', time: todayTiming.subahSadiq, isPm: false),
    );
    final suhoorDt = suhoorPrayer?.toDateTime(date: now) ?? DateTime(now.year, now.month, now.day, 4, 45);
    final suhoorDiff = suhoorDt.difference(now);

    // 2. Iftar Time (Maghrib)
    final iftarPrayer = todayTiming?.allTimings.firstWhere(
      (p) => p.name == 'Maghrib',
      orElse: () => PrayerTime(name: 'Maghrib', urduName: 'مغرب', time: todayTiming.maghrib, isPm: true),
    );
    final iftarDt = iftarPrayer?.toDateTime(date: now) ?? DateTime(now.year, now.month, now.day, 18, 35);
    final iftarDiff = iftarDt.difference(now);

    final suhoorRaw = suhoorPrayer?.displayTime ?? '04:45 AM';
    final iftarRaw = iftarPrayer?.displayTime ?? '06:35 PM';

    // Localized Strings
    final suhoorTitle = _loc(lang, 'Suhoor / Sehri', 'سحری', 'سحري', 'السحور', 'সাহরি', 'सेहरी', 'Sahur', 'Sahur', "Suhoor / Sehri", 'سحری');
    final iftarTitle = _loc(lang, 'Iftar', 'افطار', 'افطار', 'الإفطار', 'ইফতার', 'इफ़्तार', 'Buka Puasa', 'İftar', 'Iftar', 'افطار');
    final untilSuhoorLabel = _loc(lang, 'Until Suhoor Ends', 'سحری کے اختتام تک', 'سحري جي پڄاڻي تائين', 'حتى نهاية السحور', 'সাহরির সময় শেষ পর্যন্ত', 'सेहरी के अंत तक', 'Hingga Sahur Berakhir', 'Sahur Bitişine Kadar', "Jusqu'à la fin du Suhoor", 'تا پایان سحری');
    final untilIftarLabel = _loc(lang, 'Until Iftar', 'افطار تک', 'افطار تائين', 'حتى الإفطار', 'ইফতার পর্যন্ত', 'इफ़्तार तक', 'Hingga Buka Puasa', 'İftara Kadar', "Jusqu'à l'Iftar", 'تا افطار');
    final ramzanHeader = _loc(lang, 'Ramzan Mubarak', 'رمضان المبارک', 'رمضان المبارڪ', 'رمضان مبارك', 'রমজান মোবারক', 'रमज़ान मुबारक', 'Ramadhan Mubarak', 'Ramazan Mubarak', 'Ramadan Mubarak', 'رمضان مبارک');
    final soundText = _isMuted
        ? _loc(lang, 'Mute', 'خاموش', 'خاموش', 'كتم الصوت', 'ম্যুট', 'म्यूट', 'Bisu', 'Sessiz', 'Muet', 'بی‌صدا')
        : _loc(lang, 'Azan Sound', 'اذان کی آواز', 'آذان جي آواز', 'صوت الأذان', 'আজানের শব্দ', 'अज़ान की आवाज़', 'Suara Azan', 'Ezan Sesi', "Son de l'Adhan", 'صدای اذان');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1B3B36), const Color(0xFF102723)]
              : [const Color(0xFF1E4D40), const Color(0xFF13362C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Stack(
        children: [
          // Header & Top Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: Title + Sound Toggle + Dismiss
                Row(
                  children: [
                    const Icon(Icons.nightlight_round, color: Color(0xFFF1C40F), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ramzanHeader,
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF1C40F),
                        ),
                      ),
                    ),

                    // Mute / Sound Toggle
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isMuted = !_isMuted;
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              soundText,
                              style: TextStyle(
                                fontFamily: font,
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Dismiss Button (✕)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: widget.onDismiss,
                      tooltip: translateFor(lang, 'Close', 'Close', 'بند کریں'),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Suhoor Card & Iftar Card Grid
                Row(
                  children: [
                    // Suhoor Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.wb_twilight_rounded, color: Colors.white.withValues(alpha: 0.9), size: 16),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    suhoorTitle,
                                    style: TextStyle(
                                      fontFamily: font,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              suhoorRaw,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _formatDuration(suhoorDiff),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFF1C40F),
                                ),
                              ),
                            ),
                            Text(
                              untilSuhoorLabel,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: font,
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Iftar Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.wb_sunny_rounded, color: Color(0xFFF39C12), size: 16),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    iftarTitle,
                                    style: TextStyle(
                                      fontFamily: font,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              iftarRaw,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _formatDuration(iftarDiff),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2ECC71),
                                ),
                              ),
                            ),
                            Text(
                              untilIftarLabel,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: font,
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
