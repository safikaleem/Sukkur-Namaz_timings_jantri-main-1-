import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/settings_provider.dart';
import '../widgets/dr_slogan_header.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  Future<void> _shareCurrentImage(BuildContext context) async {
    const assetPath = 'assets/images/about.jpeg';
    const fileName = 'about.jpeg';
    try {
      final bytes = await rootBundle.load(assetPath);
      final tmp = await getTemporaryDirectory();
      final file = File('${tmp.path}/$fileName');
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
    final isRtl = settings.isRtl;

    return Scaffold(
      backgroundColor: settings.displayThemeBg(isDark),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 20, 0),
              child: SizedBox(
                height: 36,
                child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_rounded,
                      size: 20,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      settings.translate('About', 'ہمارے بارے میں', 'اسان بابت', 'عن التطبيق'),
                      style: TextStyle(
                        fontSize: isRtl ? 28 : 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.share_rounded,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    tooltip: settings.translate('Share', 'شیئر کریں', 'شيئر ڪريو', 'مشاركة'),
                    onPressed: () => _shareCurrentImage(context),
                  ),
                ],
              ),
            ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: DrSloganHeader(),
            ),
            const SizedBox(height: 8),

            // ── Image Card Container ───────────────────────────────────────────────────
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                decoration: BoxDecoration(
                  color: settings.displayThemeCard(isDark),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: settings.displayThemeCardBorder(isDark),
                    width: 1,
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Image.asset(
                      'assets/images/about.jpeg',
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
              ),
            ),

            // ── Pinch to Zoom Hint ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.zoom_in_rounded,
                    size: 16,
                    color: isDark ? Colors.white30 : Colors.black38,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    settings.translate(
                      'Pinch to zoom',
                      'زوم کرنے کے لیے پنچ کریں',
                      'زوم ڪرڻ لاءِ پنچ ڪريو',
                      'قرّب إصبعيك للتكبير',
                    ),
                    style: TextStyle(
                      fontSize: settings.isRtl ? 13 : 11,
                      color: isDark ? Colors.white30 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
