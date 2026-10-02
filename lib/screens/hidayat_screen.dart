import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/settings_provider.dart';
import '../widgets/dr_slogan_footer.dart';
import '../widgets/dr_slogan_header.dart';

import 'package:flutter/foundation.dart';

class HidayatScreen extends StatelessWidget {
  const HidayatScreen({super.key});

  Future<void> _shareImage(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    try {
      if (kIsWeb) {
        final shareText = settings.translate(
          'Sukkur Salah – Namaz timings for Sukkur and all cities worldwide. Download now:\nhttps://play.google.com/store/apps/details?id=pk.sukkur.salah',
          'سکھر صلاۃ – سکھر اور دنیا بھر کے تمام شہروں کے لیے نماز کے اوقات۔ ابھی ڈاؤن لوڈ کریں:\nhttps://play.google.com/store/apps/details?id=pk.sukkur.salah',
          'سکر صلاۃ – سکر ۽ سڄي دنيا جي سڀني شهرن لاءِ نماز جا وقت. هاڻي ڊائون لوڊ ڪريو:\nhttps://play.google.com/store/apps/details?id=pk.sukkur.salah',
          'سكر صلاة - مواقيت الصلاة لسكر وجميع مدن العالم. حمّل الآن:\nhttps://play.google.com/store/apps/details?id=pk.sukkur.salah',
        );
        await Share.share(shareText);
        return;
      }
      final bytes = await rootBundle.load('assets/images/hidayat.jpeg');
      final tmp = await getTemporaryDirectory();
      final file = File('${tmp.path}/hidayat.jpeg');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: settings.translate(
          'Sukkur Salah Instructions',
          'سکھر صلاۃ ہدایات',
          'سکر صلاۃ هدايتون',
          'إرشادات سكر صلاة',
        ),
      );
    } catch (_) {
      try {
        final shareText = settings.translate(
          'Sukkur Salah – Namaz timings for Sukkur and all cities worldwide. Download now:\nhttps://play.google.com/store/apps/details?id=pk.sukkur.salah',
          'سکھر صلاۃ – سکھر اور دنیا بھر کے تمام شہروں کے لیے نماز کے اوقات۔ ابھی ڈاؤن لوڈ کریں:\nhttps://play.google.com/store/apps/details?id=pk.sukkur.salah',
          'سکر صلاۃ – سکر ۽ سڄي دنيا جي سڀني شهرن لاءِ نماز جا وقت. هاڻي ڊائون لوڊ ڪريو:\nhttps://play.google.com/store/apps/details?id=pk.sukkur.salah',
          'سكر صلاة - مواقيت الصلاة لسكر وجميع مدن العالم. حمّل الآن:\nhttps://play.google.com/store/apps/details?id=pk.sukkur.salah',
        );
        await Share.share(shareText);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                settings.translate(
                  'Could not share image',
                  'تصویر شیئر نہیں ہو سکی',
                  'تصوير شيئر نه ٿي سگهي',
                  'تعذر مشاركة الصورة',
                ),
              ),
            ),
          );
        }
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
