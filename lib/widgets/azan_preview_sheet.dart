import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/azan_data.dart';
import '../utils/app_theme.dart';

class AzanPreviewSheet extends StatefulWidget {
  final bool isUrdu;
  const AzanPreviewSheet({super.key, required this.isUrdu});

  @override
  State<AzanPreviewSheet> createState() => _AzanPreviewSheetState();
}

class _AzanPreviewSheetState extends State<AzanPreviewSheet> {
  final AudioPlayer _player = AudioPlayer();
  int? _playingIndex;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingIndex = null);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle(int index) async {
    try {
      if (_playingIndex == index) {
        await _player.stop();
        if (!mounted) return;
        setState(() => _playingIndex = null);
      } else {
        await _player.stop();
        await _player.play(AssetSource(azanTracks[index].assetPath));
        if (!mounted) return;
        setState(() => _playingIndex = index);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _playingIndex = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<SettingsProvider>().translate(
              'Could not play audio',
              'آواز نہیں چل سکی',
              'آواز نه هلي سگهيو',
              'تعذر تشغيل الصوت')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            settings.translate('Azan Sounds', 'اذان کی آوازیں', 'اذان جا آواز', 'أصوات الأذان'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            settings.translate('Select Azan Sound', 'اذان کی آواز منتخب کریں', 'اذان جو آواز چونڊيو', 'اختر صوت الأذان'),
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(azanTracks.length, (i) {
            final track = azanTracks[i];
            final isPlaying = _playingIndex == i;
            final isSelected = settings.selectedAzanIndex == i;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.accent
                        .withValues(alpha: isDark ? 0.18 : 0.08)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade50),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.accent.withValues(alpha: 0.4)
                      : (isDark
                          ? Colors.white12
                          : Colors.black.withValues(alpha: 0.06)),
                ),
              ),
              child: ListTile(
                onTap: () => settings.setSelectedAzanIndex(i),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accent.withValues(alpha: 0.12)
                        : (isDark ? Colors.white10 : Colors.black12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.music_note_rounded,
                    color: isSelected
                        ? AppTheme.accent
                        : (isDark ? Colors.white54 : Colors.black54),
                    size: 18,
                  ),
                ),
                title: Text(
                  track.name == 'Makkah Azan'
                      ? settings.translate('Makkah Azan', 'مکہ اذان', 'مکہ اذان', 'أذان مكة')
                      : (track.name == 'Allah o Akbar Allah o Akbar'
                          ? settings.translate('Allah o Akbar Allah o Akbar', 'اللہ اکبر، اللہ اکبر', 'اللہ اکبر، اللہ اکبر', 'الله أكبر، الله أكبر')
                          : (track.name == 'Allah o Akbar Allah o Akbar 2'
                              ? settings.translate('Allah o Akbar Allah o Akbar 2', 'اللہ اکبر، اللہ اکبر ۲', 'اللہ اکبر، اللہ اکبر ۲', 'الله أكبر، الله أكبر ٢')
                              : settings.translate('Hayya Alas Salah', 'حَيَّ عَلَى الصَّلَاةِ', 'حَيَّ عَلَى الصَّلَاةِ', 'حَيَّ عَلَى الصَّلَاةِ'))),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(
                    isPlaying
                        ? Icons.stop_circle_rounded
                        : Icons.play_circle_rounded,
                    color: isPlaying ? Colors.redAccent : AppTheme.accent,
                    size: 34,
                  ),
                  onPressed: () => _toggle(i),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
