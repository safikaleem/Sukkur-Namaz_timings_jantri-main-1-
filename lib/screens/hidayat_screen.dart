import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/settings_provider.dart';
import '../widgets/dr_slogan_footer.dart';
import '../widgets/dr_slogan_header.dart';

class HidayatScreen extends StatelessWidget {
  const HidayatScreen({super.key});

  Future<void> _shareImage(BuildContext context) async {
    try {
      final bytes = await rootBundle.load('assets/images/hidayat.jpeg');
      final tmp = await getTemporaryDirectory();
      final file = File('${tmp.path}/hidayat.jpeg');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not share image')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: settings.displayThemeBg(isDark),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SizedBox(
                height: 36,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 42),
                    Text(
                      settings.translate('Instructions', 'ہدایت', 'هدايت', 'إرشادات'),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.share_rounded,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      tooltip: settings.translate('Share', 'شیئر کریں', 'شيئر ڪريو', 'مشاركة'),
                      onPressed: () => _shareImage(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),
            const Center(
              child: DrSloganHeader(),
            ),

            // ── Image ────────────────────────────────────────────────
            Expanded(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Image.asset(
                  'assets/images/hidayat.jpeg',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.contain,
                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                    if (wasSynchronouslyLoaded) return child;
                    return frame != null
                        ? child
                        : const Center(
                            child: CircularProgressIndicator(),
                          );
                  },
                ),
              ),
            ),

            const DrSloganFooter(),
          ],
        ),
      ),
    );
  }
}
