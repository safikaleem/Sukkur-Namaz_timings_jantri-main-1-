import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';

class WidgetSelectionSheet extends StatefulWidget {
  final SettingsProvider settings;
  final bool isDark;
  final bool isRtl;

  const WidgetSelectionSheet({
    Key? key,
    required this.settings,
    required this.isDark,
    required this.isRtl,
  }) : super(key: key);

  @override
  State<WidgetSelectionSheet> createState() => _WidgetSelectionSheetState();
}

class _WidgetSelectionSheetState extends State<WidgetSelectionSheet> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;

  /// Real screenshots of each widget, not drawings, so what the sheet promises
  /// is what lands on the home screen.
  ///
  /// [ratio] is the shot's own width/height and [scale] how much of the card it
  /// may fill. Together they keep a 1x1 visibly smaller than a 3x3 - sizing
  /// every preview to the same box was what made Tiny and Large look alike.
  ///
  /// [radius] is each widget's own corner rounding, measured off the shot as a
  /// fraction of its width. It has to be per widget: the shots were trimmed to
  /// the card edge, so anything short of the real corner leaves the launcher
  /// wallpaper showing in the arc, and anything over it clips the card.
  /// The size word is translated; the cell count stays in digits, like every
  /// other number the widgets show.
  static const _previews = <_WidgetPreview>[
    _WidgetPreview(
      name: 'Small',
      nameUr: 'چھوٹا',
      nameSd: 'ننڍو',
      nameAr: 'صغير',
      cells: '2x2',
      provider: 'PrayerWidgetSmallProvider',
      asset: 'assets/images/widget_small.jpg',
      ratio: 288 / 343,
      radius: 0.053,
      scale: 0.62,
    ),
    _WidgetPreview(
      name: 'Medium',
      nameUr: 'درمیانہ',
      nameSd: 'وچولو',
      nameAr: 'متوسط',
      cells: '3x2',
      provider: 'PrayerWidgetMediumProvider',
      asset: 'assets/images/widget_medium.jpg',
      ratio: 617 / 346,
      radius: 0.016,
      scale: 0.88,
    ),
    _WidgetPreview(
      name: 'Large',
      nameUr: 'بڑا',
      nameSd: 'وڏو',
      nameAr: 'كبير',
      cells: '3x3',
      provider: 'PrayerWidgetLargeProvider',
      asset: 'assets/images/widget_large.jpg',
      ratio: 623 / 555,
      radius: 0.036,
      scale: 1.0,
    ),
    _WidgetPreview(
      name: 'Tiny',
      nameUr: 'بہت چھوٹا',
      nameSd: 'تمام ننڍو',
      nameAr: 'صغير جدا',
      cells: '1x1',
      provider: 'PrayerWidgetTinyProvider',
      asset: 'assets/images/widget_tiny.jpg',
      ratio: 287 / 157,
      radius: 0.096,
      scale: 0.5,
    ),
    _WidgetPreview(
      name: 'Slim',
      nameUr: 'پتلا',
      nameSd: 'پتلو',
      nameAr: 'نحيف',
      cells: '2x1',
      provider: 'PrayerWidgetSlimProvider',
      asset: 'assets/images/widget_slim.jpg',
      ratio: 450 / 156,
      radius: 0.053,
      scale: 0.74,
    ),
    _WidgetPreview(
      name: 'Circle Clock',
      nameUr: 'گول گھڑی',
      nameSd: 'گول گھڙي',
      nameAr: 'ساعة دائرية',
      provider: 'PrayerWidgetCircleProvider',
      // Picked by the Digital/Analog toggle below the card.
      asset: 'assets/images/widget_circle_digital.jpg',
      analogAsset: 'assets/images/widget_circle_analog.jpg',
      ratio: 652 / 582,
      // Ignored: the oval is clipped to an ellipse, not a rounded rectangle.
      radius: 0,
      // Near full, unlike the others: this is the only card carrying the
      // Digital/Analog toggle, so it has the least height to work with.
      scale: 0.98,
    ),
  ];

  bool? _canPin;

  @override
  void initState() {
    super.initState();
    _checkPinSupport();
  }

  Future<void> _checkPinSupport() async {
    bool supported;
    try {
      supported = await HomeWidget.isRequestPinWidgetSupported() ?? false;
    } catch (_) {
      supported = false;
    }
    if (mounted) setState(() => _canPin = supported);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _pinWidget(String androidName) async {
    if (_canPin == false) {
      _showManualSteps();
      return;
    }
    try {
      await HomeWidget.requestPinWidget(androidName: androidName);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) _showManualSteps();
    }
  }

  void _showManualSteps() {
    final s = widget.settings;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.translate(
          'Add it from the home screen',
          'ہوم اسکرین سے شامل کریں',
          'هوم اسڪرين مان شامل ڪريو',
          'أضفه من الشاشة الرئيسية',
        )),
        content: Text(s.translate(
          'This phone cannot add widgets from inside an app.\n\n'
              'Press and hold an empty spot on your home screen, tap Widgets, '
              'find Sukkur Salah, then pick the size you want.',
          'یہ فون ایپ کے اندر سے ویجیٹ شامل نہیں کر سکتا۔\n\n'
              'ہوم اسکرین پر خالی جگہ دبا کر رکھیں، ویجیٹس پر ٹیپ کریں، '
              'سکھر صلاۃ تلاش کریں، پھر اپنی پسند کا سائز منتخب کریں۔',
          'هي فون ايپ اندران ويجيٽ شامل نٿو ڪري سگهي.\n\n'
              'هوم اسڪرين تي خالي جاءِ دٻائي رکو، ويجيٽس تي ٽيپ ڪريو، '
              'سکر صلاۃ ڳوليو، پوءِ پنهنجي پسند جو سائز چونڊيو.',
          'لا يمكن لهذا الهاتف إضافة الودجات من داخل التطبيق.\n\n'
              'اضغط مطولاً على مكان فارغ في الشاشة الرئيسية، اضغط على الودجات، '
              'ابحث عن صلاة سكر، ثم اختر الحجم الذي تريده.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.translate('OK', 'ٹھیک ہے', 'ٺيڪ آهي', 'حسناً')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.settings.translate('Prayer Widgets', 'نماز ویجیٹس', 'نماز ويجيٽس', 'ودجت الصلاة'),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: widget.isDark ? Colors.white : Colors.black87,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: widget.isDark ? Colors.white54 : Colors.black54),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              widget.settings.translate(
                'Swipe to preview and add a widget to your home screen',
                'ہوم اسکرین پر ویجیٹ کا پیش نظارہ کرنے اور شامل کرنے کے لیے سوائپ کریں',
                'هوم اسڪرين تي ويجيٽ ڏسڻ ۽ شامل ڪرڻ لاءِ سوائپ ڪريو',
                'اسحب لمعاينة وإضافة عنصر واجهة مستخدم إلى شاشتك الرئيسية'
              ),
              style: TextStyle(
                fontSize: 14,
                color: widget.isDark ? Colors.white70 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 330,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _previews.length,
              itemBuilder: (context, index) =>
                  _buildWidgetCard(index, _previews[index]),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _previews.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: _currentPage == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? AppTheme.accent
                      : (widget.isDark ? Colors.white24 : Colors.black12),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildWidgetCard(int index, _WidgetPreview preview) {
    final isSelected = _currentPage == index;
    final isCircle = preview.isCircle;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? AppTheme.accent.withValues(alpha: 0.5)
              : Colors.transparent,
          width: 2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Center(child: _buildPreviewImage(preview)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            preview.label(widget.settings),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: widget.isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          if (isCircle) _buildCircleWidgetOptions(),
          ElevatedButton.icon(
            onPressed: () => _pinWidget(preview.provider),
            icon: Icon(_canPin == false
                ? Icons.help_outline
                : Icons.add_to_home_screen),
            label: Text(_canPin == false
                ? widget.settings.translate('How to add this', 'کیسے شامل کریں',
                    'ڪيئن شامل ڪجي', 'كيفية الإضافة')
                : widget.settings.translate(
                    'Add to Home Screen',
                    'ہوم اسکرین پر شامل کریں',
                    'هوم اسڪرين تي شامل ڪريو',
                    'أضف إلى الشاشة الرئيسية')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// The screenshot itself, scaled to the widget's real footprint and clipped
  /// to the widget's own outline, so the launcher wallpaper behind it - a thin
  /// margin on every shot, and the whole background of the oval one - never
  /// makes it into the card.
  Widget _buildPreviewImage(_WidgetPreview preview) {
    final asset =
        preview.isCircle && widget.settings.circleWidgetStyle == 'analog'
            ? preview.analogAsset!
            : preview.asset;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Fit the shot's own aspect ratio inside the share of the card this
        // widget is entitled to, so nothing stretches and nothing overflows.
        final boxW = constraints.maxWidth * preview.scale;
        final boxH = constraints.maxHeight * preview.scale;
        double w = boxW;
        double h = boxW / preview.ratio;
        if (h > boxH) {
          h = boxH;
          w = boxH * preview.ratio;
        }

        // An ellipse inscribed in the box for the oval widget, rounded corners
        // for the rest. Elliptical rather than BoxShape.circle because the shot
        // is not square, and a circle would crop the oval's date and countdown.
        final radius = preview.isCircle
            ? BorderRadius.all(Radius.elliptical(w / 2, h / 2))
            : BorderRadius.circular(w * preview.radius);

        final image = Image.asset(
          asset,
          width: w,
          height: h,
          // cover, not contain: the clip is what trims the wallpaper margin, and
          // contain would letterbox it back in.
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, _, __) => _missingPreview(w, h),
        );

        // One path for both shapes: the ellipse is expressed as a border radius
        // rather than BoxShape.circle, which cannot carry a radius at all and
        // would size itself off the shorter side.
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 14,
                spreadRadius: 1,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(borderRadius: radius, child: image),
        );
      },
    );
  }

  /// Only reachable if a screenshot is missing from the bundle. Says so rather
  /// than leaving the card empty, because a blank preview reads as a broken
  /// widget instead of a broken asset.
  Widget _missingPreview(double w, double h) => Container(
        width: w,
        height: h,
        alignment: Alignment.center,
        color: widget.isDark ? Colors.white10 : Colors.black12,
        child: Icon(Icons.broken_image_outlined,
            color: widget.isDark ? Colors.white38 : Colors.black38),
      );

  Widget _buildCircleWidgetOptions() {
    final currentStyle = widget.settings.circleWidgetStyle;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _OptionBtn(
            label: widget.settings.translate('Digital', 'ڈیجیٹل', 'ڊجيٽل', 'رقمي'),
            selected: currentStyle == 'digital',
            isDark: widget.isDark,
            isRtl: widget.isRtl,
            onTap: () {
              widget.settings.setCircleWidgetStyle('digital');
              setState(() {}); // refresh UI to show selected state
            },
          ),
          const SizedBox(width: 8),
          _OptionBtn(
            label: widget.settings.translate('Analog', 'اینالاگ', 'اينالاگ', 'تناظري'),
            selected: currentStyle == 'analog',
            isDark: widget.isDark,
            isRtl: widget.isRtl,
            onTap: () {
              widget.settings.setCircleWidgetStyle('analog');
              setState(() {}); // refresh UI to show selected state
            },
          ),
        ],
      ),
    );
  }
}

class _OptionBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final bool isRtl;
  final VoidCallback onTap;

  const _OptionBtn({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.isRtl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accent.withValues(alpha: 0.15)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppTheme.accent.withValues(alpha: 0.6)
                : (isDark ? Colors.white12 : Colors.black12),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isRtl ? 14 : 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? AppTheme.accent
                : (isDark ? Colors.white54 : Colors.black54),
          ),
        ),
      ),
    );
  }
}

/// One entry in the widget carousel: what to pin, and the screenshot that shows
/// what will land on the home screen.
class _WidgetPreview {
  /// Size word, translated. English doubles as the fallback for the languages
  /// [SettingsProvider.translate] does not carry.
  final String name;
  final String nameUr;
  final String nameSd;
  final String nameAr;

  /// Home-screen footprint, e.g. '2x2'. Left null for the oval, which has no
  /// meaningful cell count. Never translated - it is digits.
  final String? cells;

  final String provider;

  /// Path to the screenshot. For the circle widget this is the digital face;
  /// [analogAsset] holds the other one.
  final String asset;
  final String? analogAsset;

  /// The screenshot's own width / height. Kept alongside the asset so the card
  /// can lay the image out before it has decoded.
  final double ratio;

  /// The widget's corner rounding as a fraction of its width, measured off the
  /// shot. Unused for the oval, which is clipped as an ellipse instead.
  final double radius;

  /// Share of the card this widget may fill, standing in for its footprint on
  /// the home screen: a 1x1 has to look smaller than a 3x3.
  final double scale;

  const _WidgetPreview({
    required this.name,
    required this.nameUr,
    required this.nameSd,
    required this.nameAr,
    required this.provider,
    required this.asset,
    required this.ratio,
    required this.radius,
    required this.scale,
    this.cells,
    this.analogAsset,
  });

  bool get isCircle => analogAsset != null;

  /// 'Small (2x2)' in English, 'چھوٹا (2x2)' in Urdu - the word follows the app
  /// language, the cell count does not.
  String label(SettingsProvider settings) {
    final word = settings.translate(name, nameUr, nameSd, nameAr);
    return cells == null ? word : '$word ($cells)';
  }
}
