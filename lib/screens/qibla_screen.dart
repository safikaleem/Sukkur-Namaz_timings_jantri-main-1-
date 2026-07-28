import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/dr_slogan_footer.dart';
import '../widgets/dr_slogan_header.dart';

// Kaaba, Mecca
const double _kaabLat = 21.4225;
const double _kaabLon = 39.8262;

/// Great-circle bearing from [userLat]/[userLon] to the Kaaba.
/// Returns degrees [0, 360) clockwise from North.
double _calcQibla(double userLat, double userLon) {
  final lat1 = userLat * math.pi / 180;
  const lat2 = _kaabLat * math.pi / 180;
  final dLon = (_kaabLon - userLon) * math.pi / 180;
  final y = math.sin(dLon) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

enum _LocState { loading, ready, denied, deniedForever, serviceOff, error }

// ── Screen ────────────────────────────────────────────────────────
class QiblaScreen extends StatefulWidget {
  /// Whether this tab is currently the visible one. Location permission is
  /// requested and the compass stream is started only while active, so a
  /// fresh install doesn't prompt for location at app launch and the sensor
  /// isn't kept running while the user is on another tab.
  final bool isActive;
  const QiblaScreen({super.key, this.isActive = true});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  // Location state
  _LocState _locState = _LocState.loading;
  double? _userLat;
  double? _userLon;
  double? _qibla; // Qibla bearing from true north (0-360)

  // Compass state
  double? _heading; // device heading from north
  bool _noSensor = false;
  StreamSubscription<QiblahDirection>? _qiblaSub;
  double _unwrapped = 0;

  @override
  void initState() {
    super.initState();
    // Only fetch when this tab is the one on screen (see [QiblaScreen.isActive]).
    if (widget.isActive) _fetchLocation();
  }

  @override
  void didUpdateWidget(QiblaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      // Tab just became visible — request location / start the compass now.
      _fetchLocation();
    } else if (!widget.isActive && oldWidget.isActive) {
      // Tab hidden — stop the sensor stream to save battery.
      _qiblaSub?.cancel();
      _qiblaSub = null;
    }
  }

  @override
  void dispose() {
    // Only cancel our subscription. FlutterQiblah is a package-level singleton;
    // calling its dispose() permanently closes the shared stream controller and
    // would break the compass if this screen is ever reopened via a route.
    _qiblaSub?.cancel();
    super.dispose();
  }

  // ── Location + Qibla ──────────────────────────────────────────
  Future<void> _fetchLocation() async {
    setState(() {
      _locState = _LocState.loading;
      _heading = null;
    });
    await _qiblaSub?.cancel();
    _qiblaSub = null;

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) setState(() => _locState = _LocState.serviceOff);
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locState = _LocState.deniedForever);
        return;
      }
      if (perm == LocationPermission.denied) {
        if (mounted) setState(() => _locState = _LocState.denied);
        return;
      }

      // Coordinates for display + static Qibla fallback
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;
      setState(() {
        _userLat = pos.latitude;
        _userLon = pos.longitude;
        _qibla = _calcQibla(pos.latitude, pos.longitude);
        _locState = _LocState.ready;
      });

      // Does this device have the magnetometer needed for a live compass?
      final hasSensor = await FlutterQiblah.androidDeviceSensorSupport();
      if (hasSensor == false) {
        if (mounted) setState(() => _noSensor = true);
        return;
      }
      _startQiblaStream();
    } catch (_) {
      if (mounted && _locState != _LocState.ready) {
        setState(() => _locState = _LocState.error);
      }
    }
  }

  // ── Live Qibla stream (flutter_qiblah) ────────────────────────
  void _startQiblaStream() {
    _qiblaSub = FlutterQiblah.qiblahStream.listen(
      (QiblahDirection q) {
        if (!mounted) return;
        final raw = q.direction;
        if (_heading == null) {
          _unwrapped = raw;
        } else {
          // Shortest-path unwrapping to avoid spin at 0°/360° boundary
          double diff = (raw - (_unwrapped % 360) + 540) % 360 - 180;
          _unwrapped += diff;
        }
        setState(() {
          _heading = _unwrapped;
          _qibla = q.offset; // live Qibla bearing for current coordinates
        });
      },
      onError: (_) {
        if (mounted) setState(() => _noSensor = true);
      },
    );
  }

  double get _qiblaOffset =>
      _qibla != null ? (_qibla! - (_heading ?? 0) + 360) % 360 : 0;

  bool get _aligned {
    if (_heading == null || _qibla == null) return false;
    final d = _qiblaOffset;
    return d < 5 || d > 355;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    final screenH = MediaQuery.of(context).size.height;
    final isSmall = screenH < 700;

    return Scaffold(
      backgroundColor: settings.displayThemeBg(isDark),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SizedBox(
                height: 36,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 42),
                    Icon(Icons.explore_rounded,
                        color: AppTheme.accent, size: 26),
                    const SizedBox(width: 12),
                    Text(
                      settings.translate('Qibla Direction', 'سمتِ قبلہ', 'قبلي جي سمت', 'اتجاه القبلة'),
                      style: TextStyle(
                        fontSize: isSmall ? 19 : 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(child: DrSloganHeader()),
            const SizedBox(height: 8),

            // ── Kaaba icon with direction arrow ──────────────────
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.navigation_rounded,
                      color: Colors.red, size: isSmall ? 16 : 20),
                  const SizedBox(height: 2),
                  Text('🕋', style: TextStyle(fontSize: isSmall ? 28 : 36)),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────
            Expanded(child: _buildBody(isDark, settings)),
            const DrSloganFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark, SettingsProvider settings) {
    final isUrdu = settings.isUrdu;
    final isSindhi = settings.isSindhi;

    switch (_locState) {
      case _LocState.loading:
        return _LoadingView(isDark: isDark, isUrdu: isUrdu, isSindhi: isSindhi);

      case _LocState.denied:
        return _StatusView(
          icon: Icons.location_off_rounded,
          isDark: isDark,
          isUrdu: isUrdu,
          isSindhi: isSindhi,
          title: settings.translate('Location Permission Needed', 'اجازت درکار ہے', 'اجازت گهربل آهي', 'مطلوب إذن الموقع'),
          body: settings.translate(
              'Your current location is needed to calculate the accurate Qibla direction.',
              'قبلہ کی سمت درست طریقے سے دکھانے کے لیے آپ کی موجودہ لوکیشن کی ضرورت ہے۔',
              'قبلي جي صحيح سمت ڏيکارڻ لاءِ توهان جي موجوده لوڪيشن جي ضرورت آهي.',
              'موقعك الحالي مطلوب لحساب اتجاه القبلة الدقيق.'),
          buttonLabel: settings.translate('Grant Permission', 'اجازت دیں', 'اجازت ڏيو', 'منح الإذن'),
          onTap: _fetchLocation,
        );

      case _LocState.deniedForever:
        return _StatusView(
          icon: Icons.location_disabled_rounded,
          isDark: isDark,
          isUrdu: isUrdu,
          isSindhi: isSindhi,
          title: settings.translate('Permission Permanently Denied', 'اجازت مستقل بند ہے', 'اجازت مستقل بند آهي', 'تم رفض الإذن نهائيًا'),
          body: settings.translate(
              'Please go to app settings and enable location permission.',
              'براہ کرم ایپ سیٹنگز میں جا کر لوکیشن کی اجازت دیں۔',
              'مهرباني ڪري ايپ سيٽنگز ۾ وڃي لوڪيشن جي اجازت ڏيو.',
              'يرجى الانتقال إلى إعدادات التطبيق وتمكين إذن الموقع.'),
          buttonLabel: settings.translate('Open Settings', 'سیٹنگز کھولیں', 'سيٽنگ کولھيو', 'فتح الضبط'),
          onTap: () => Geolocator.openAppSettings(),
        );

      case _LocState.serviceOff:
        return _StatusView(
          icon: Icons.gps_off_rounded,
          isDark: isDark,
          isUrdu: isUrdu,
          isSindhi: isSindhi,
          title: settings.translate('Location Services Off', 'GPS بند ہے', 'GPS بند آهي', 'خدمات الموقع معطلة'),
          body: settings.translate(
              'Please enable GPS / Location Services on your device.',
              'قبلہ کی سمت جاننے کے لیے GPS آن کریں۔',
              'قبلي جي سمت لاءِ پنهنجي ڊوائيس تي GPS آن ڪريو.',
              'يرجى تمكين GPS / خدمات الموقع على جهازك.'),
          buttonLabel: settings.translate('Open Location Settings', 'GPS سیٹنگز', 'GPS سيٽنگ', 'فتح إعدادات الموقع'),
          onTap: () async {
            await Geolocator.openLocationSettings();
            _fetchLocation();
          },
        );

      case _LocState.error:
        return _StatusView(
          icon: Icons.error_outline_rounded,
          isDark: isDark,
          isUrdu: isUrdu,
          isSindhi: isSindhi,
          title: settings.translate('Could Not Get Location', 'لوکیشن نہیں ملی', 'لوڪيشن نه مليو', 'تعذر الحصول على الموقع'),
          body: settings.translate(
              'Something went wrong. Please try again.',
              'کچھ مسئلہ ہوا۔ دوبارہ کوشش کریں۔',
              'ڪجهه مسئلو ٿيو. ٻيهر ڪوشش ڪريو.',
              'حدث خطأ ما. يرجى المحاولة مرة أخرى.'),
          buttonLabel: settings.translate('Retry', 'دوبارہ کوشش کریں', 'ٻيهر ڪوشش ڪريو', 'إعادة المحاولة'),
          onTap: _fetchLocation,
        );

      case _LocState.ready:
        return _noSensor
            ? _NoSensorView(
                qiblaAngle: _qibla!.round(),
                lat: _userLat!,
                lon: _userLon!,
                isDark: isDark,
                isUrdu: isUrdu,
                isSindhi: isSindhi,
                onRefresh: _fetchLocation,
              )
            : _LiveCompassView(
                heading: _heading,
                qiblaOffset: _qiblaOffset,
                qiblaAngle: _qibla!,
                aligned: _aligned,
                lat: _userLat!,
                lon: _userLon!,
                isDark: isDark,
                isUrdu: isUrdu,
                isSindhi: isSindhi,
                onRefresh: _fetchLocation,
              );
    }
  }
}

// ── Loading view ──────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  final bool isDark;
  final bool isUrdu;
  final bool isSindhi;
  const _LoadingView({required this.isDark, required this.isUrdu, required this.isSindhi});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: CircularProgressIndicator(
                color: AppTheme.accent, strokeWidth: 3),
          ),
          const SizedBox(height: 20),
          Text(
            settings.translate(
                'Detecting your location…',
                'لوکیشن معلوم ہو رہی ہے…',
                'لوڪيشن معلوم ٿي رهي آهي…',
                'جارٍ تحديد موقعك…'),
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Generic status / permission view ─────────────────────────────
class _StatusView extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final bool isUrdu;
  final bool isSindhi;
  final String title;
  final String body;
  final String buttonLabel;
  final VoidCallback onTap;

  const _StatusView({
    required this.icon,
    required this.isDark,
    required this.isUrdu,
    required this.isSindhi,
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent.withValues(alpha: 0.10),
                border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.3),
                    width: 2),
              ),
              child: Icon(icon, size: 46, color: AppTheme.accent),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.7,
                color: isDark ? Colors.white38 : Colors.black45,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.location_on_rounded, size: 18),
                label: Text(
                  buttonLabel,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Live compass view ─────────────────────────────────────────────
class _LiveCompassView extends StatelessWidget {
  final double? heading;
  final double qiblaOffset;
  final double qiblaAngle;
  final bool aligned;
  final double lat;
  final double lon;
  final bool isDark;
  final bool isUrdu;
  final bool isSindhi;
  final VoidCallback onRefresh;

  const _LiveCompassView({
    required this.heading,
    required this.qiblaOffset,
    required this.qiblaAngle,
    required this.aligned,
    required this.lat,
    required this.lon,
    required this.isDark,
    required this.isUrdu,
    required this.isSindhi,
    required this.onRefresh,
  });

  String _coordLabel() {
    final latDir = lat >= 0 ? 'N' : 'S';
    final lonDir = lon >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(4)}° $latDir,  ${lon.abs().toStringAsFixed(4)}° $lonDir';
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final h = heading ?? 0.0;
    final rawInt = h.round() % 360;
    final headingInt = rawInt < 0 ? rawInt + 360 : rawInt;
    final qiblaInt = qiblaAngle.round();
    final loading = heading == null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availH = constraints.maxHeight;
        final availW = constraints.maxWidth;
        final isSmall = availH < 420;
        final vSp = isSmall ? 5.0 : 10.0;

        // Only the compass size is adjusted (vs original) to prevent the
        // content from overflowing the Expanded area now that
        // SingleChildScrollView has been removed.
        final badgeH   = isSmall ? 32.0 : 40.0;
        const tilesH   = 58.0;
        const coordsH  = 22.0;
        final topSp    = isSmall ? 4.0 : 6.0;
        final spacingH = topSp + vSp + vSp + (isSmall ? 4.0 : 8.0) + (isSmall ? 4.0 : 8.0);
        final reserved = badgeH + tilesH + coordsH + spacingH;
        final compassSize = math.min(
          230.0,
          math.min(availW * 0.64, math.max(100.0, availH - reserved)),
        );

        return Column(
          children: [
            SizedBox(height: isSmall ? 4.0 : 6.0),

            // ── Compass ──────────────────────────────────────────
            Center(
              child: SizedBox(
                width: compassSize,
                height: compassSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow when aligned
                    if (aligned)
                      Container(
                        width: compassSize + 30,
                        height: compassSize + 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.28),
                              blurRadius: 28,
                              spreadRadius: 6,
                            )
                          ],
                        ),
                      ),

                    // Rotating compass face (N stays at true North)
                    Transform.rotate(
                      angle: -h * math.pi / 180,
                      child: CustomPaint(
                        size: Size(compassSize, compassSize),
                        painter: _CompassFacePainter(isDark: isDark),
                      ),
                    ),

                    // Qibla needle (always points toward Mecca)
                    if (!loading)
                      Transform.rotate(
                        angle: qiblaOffset * math.pi / 180,
                        child: CustomPaint(
                          size: Size(compassSize, compassSize),
                          painter: _QiblaNeedlePainter(
                              aligned: aligned, isDark: isDark),
                        ),
                      ),

                    // Centre pivot
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? Colors.white : Colors.black87,
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 1))
                        ],
                      ),
                    ),

                    if (loading)
                      CircularProgressIndicator(
                          color: AppTheme.accent, strokeWidth: 2),
                  ],
                ),
              ),
            ),

            SizedBox(height: vSp),

            // ── Alignment badge / guide ────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: aligned
                  ? Container(
                      key: const ValueKey('yes'),
                      padding: EdgeInsets.symmetric(
                          horizontal: 28, vertical: isSmall ? 7 : 10),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: Colors.green.withValues(alpha: 0.5),
                            width: 1.5),
                      ),
                      child: Text(
                        settings.translate('✓  Facing Qibla', '✓  آپ قبلہ رو ہیں', '✓  توهان قبلي رو آهيو', '✓  مواجه للقبلة'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    )
                  : SizedBox(
                      key: const ValueKey('no'),
                      height: isSmall ? 32 : 40,
                      child: Center(
                        child: Text(
                          loading
                              ? (isSindhi
                                  ? 'قطب نما لوڊ ٿي رهيو آهي…'
                                  : (isUrdu
                                      ? 'قطب نما لوڈ ہو رہا ہے…'
                                      : 'Loading compass…'))
                              : (isSindhi
                                  ? 'فون گهمايو — سائو تير مٿي ايندي قبلو آهي'
                                  : (isUrdu
                                      ? 'فون گھمائیں — تیر اوپر آنے پر قبلہ ہے'
                                      : 'Rotate phone until the green arrow points up')),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white38 : Colors.black45,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
            ),

            SizedBox(height: vSp),

            // ── Info tiles ────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _InfoTile(
                  label: settings.translate('Heading', 'آپ کا رخ', 'توهان جو رخ', 'الاتجاه'),
                  value: loading ? '—' : '$headingInt°',
                  isDark: isDark,
                ),
                const SizedBox(width: 16),
                _InfoTile(
                  label: settings.translate('Qibla', 'قبلہ', 'قبلو', 'القبلة'),
                  value: '$qiblaInt°',
                  isDark: isDark,
                  highlight: true,
                ),
              ],
            ),

            SizedBox(height: isSmall ? 4.0 : 8.0),

            // ── Coordinates + refresh ─────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.my_location_rounded,
                    size: 13,
                    color: isDark ? Colors.white38 : Colors.black38),
                const SizedBox(width: 4),
                Text(
                  _coordLabel(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black45,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onRefresh,
                  child: Icon(Icons.refresh_rounded,
                      size: 16,
                      color: AppTheme.accent.withValues(alpha: 0.8)),
                ),
              ],
            ),
            SizedBox(height: isSmall ? 4.0 : 8.0),
          ],
        );
      },
    );
  }
}

// ── No-sensor fallback ────────────────────────────────────────────
class _NoSensorView extends StatelessWidget {
  final int qiblaAngle;
  final double lat;
  final double lon;
  final bool isDark;
  final bool isUrdu;
  final bool isSindhi;
  final VoidCallback onRefresh;

  const _NoSensorView({
    required this.qiblaAngle,
    required this.lat,
    required this.lon,
    required this.isDark,
    required this.isUrdu,
    required this.isSindhi,
    required this.onRefresh,
  });

  String _coordLabel() {
    final latDir = lat >= 0 ? 'N' : 'S';
    final lonDir = lon >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(4)}° $latDir,  ${lon.abs().toStringAsFixed(4)}° $lonDir';
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent.withValues(alpha: 0.10),
                border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.3),
                    width: 2),
              ),
              child: Icon(Icons.explore_off_rounded,
                  size: 56, color: AppTheme.accent),
            ),
            const SizedBox(height: 24),
            Text(
              '$qiblaAngle°',
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w800,
                color: AppTheme.accent,
              ),
            ),
            Text(
              settings.translate('Qibla from North', 'شمال سے قبلہ کی سمت', 'اتر کان قبلي جي سمت', 'القبلة من الشمال'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.my_location_rounded,
                    size: 13,
                    color: isDark ? Colors.white38 : Colors.black45),
                const SizedBox(width: 4),
                Text(
                  _coordLabel(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black45,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onRefresh,
                  child: Icon(Icons.refresh_rounded,
                      size: 16,
                      color: AppTheme.accent.withValues(alpha: 0.8)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12),
              ),
              child: Text(
                isSindhi
                    ? 'هن ڊوائيس تي قطب نما سينسر نه آهي. لائيو قطب نما لاءِ ميگنيٽوميٽر سان فون استعمال ڪريو.'
                    : (isUrdu
                        ? 'اس ڈیوائس پر قطب نما سینسر نہیں ہے۔ لائیو کمپاس کے لیے میگنیٹومیٹر والا فون استعمال کریں۔'
                        : 'No compass sensor found on this device. '
                            'Use a device with a hardware magnetometer for the live compass.'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.7,
                  color: isDark ? Colors.white38 : Colors.black45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Info tile ─────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool highlight;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.isDark,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: highlight
            ? AppTheme.accent.withValues(alpha: 0.12)
            : (isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight
              ? AppTheme.accent.withValues(alpha: 0.4)
              : (isDark ? Colors.white12 : Colors.black12),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 0.4,
              color: isDark ? Colors.white38 : Colors.black45,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: highlight
                  ? AppTheme.accent
                  : (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Compass face painter ──────────────────────────────────────────
class _CompassFacePainter extends CustomPainter {
  final bool isDark;
  const _CompassFacePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy);

    // Background
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()
          ..color =
              isDark ? const Color(0xFF14142B) : const Color(0xFFF4F4F8));

    // Outer border
    canvas.drawCircle(
        Offset(cx, cy),
        r - 1,
        Paint()
          ..color = isDark
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.black.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // Inner decorative ring
    canvas.drawCircle(
        Offset(cx, cy),
        r - 52,
        Paint()
          ..color = isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);

    // Tick marks
    for (int deg = 0; deg < 360; deg += 5) {
      final rad = deg * math.pi / 180;
      final isCard = deg % 90 == 0;
      final isInter = deg % 45 == 0 && !isCard;
      final isMaj = deg % 30 == 0;
      final len = isCard ? 20.0 : isInter ? 14.0 : isMaj ? 10.0 : 6.0;
      final sw = isCard ? 3.0 : isInter ? 1.8 : 1.0;

      final sinA = math.sin(rad);
      final cosA = math.cos(rad);

      canvas.drawLine(
        Offset(cx + (r - 5) * sinA, cy - (r - 5) * cosA),
        Offset(cx + (r - 5 - len) * sinA, cy - (r - 5 - len) * cosA),
        Paint()
          ..color = deg == 0
              ? const Color(0xFFE53935)
              : isCard
                  ? (isDark ? Colors.white70 : Colors.black87)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.28)
                      : Colors.black.withValues(alpha: 0.28))
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.round,
      );
    }

    // Cardinal labels
    _label(canvas, size, r, 'N', 0, const Color(0xFFE53935), 18, bold: true);
    _label(canvas, size, r, 'E', 90, isDark ? Colors.white70 : Colors.black87, 15);
    _label(canvas, size, r, 'S', 180, isDark ? Colors.white70 : Colors.black87, 15);
    _label(canvas, size, r, 'W', 270, isDark ? Colors.white70 : Colors.black87, 15);

    final sub = isDark
        ? Colors.white.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.35);
    _label(canvas, size, r, 'NE', 45, sub, 10);
    _label(canvas, size, r, 'SE', 135, sub, 10);
    _label(canvas, size, r, 'SW', 225, sub, 10);
    _label(canvas, size, r, 'NW', 315, sub, 10);
  }

  void _label(Canvas canvas, Size size, double r, String text, double deg,
      Color color, double fs, {bool bold = false}) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rad = deg * math.pi / 180;
    final dist = r - (text.length > 1 ? 40.0 : 34.0);
    final x = cx + dist * math.sin(rad);
    final y = cy - dist * math.cos(rad);
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fs,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(_CompassFacePainter old) => old.isDark != isDark;
}

// ── Qibla needle painter ──────────────────────────────────────────
class _QiblaNeedlePainter extends CustomPainter {
  final bool aligned;
  final bool isDark;
  const _QiblaNeedlePainter({required this.aligned, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy);

    final green = aligned ? const Color(0xFF00C853) : const Color(0xFF43A047);

    canvas.save();
    canvas.translate(cx, cy);

    final tipY = -(r - 28);
    final tailY = r * 0.38;

    // Faded tail
    final tailPath = Path()
      ..moveTo(0, tailY)
      ..lineTo(-7, tailY - 20)
      ..lineTo(7, tailY - 20)
      ..close();
    canvas.drawPath(tailPath,
        Paint()..color = green.withValues(alpha: 0.35)..style = PaintingStyle.fill);

    // Shaft
    canvas.drawLine(
      Offset(0, tipY + 28),
      Offset(0, tailY - 18),
      Paint()
        ..color = green
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round,
    );

    // Arrowhead
    final arrow = Path()
      ..moveTo(0, tipY)
      ..lineTo(-12, tipY + 30)
      ..lineTo(12, tipY + 30)
      ..close();
    canvas.drawPath(
        arrow, Paint()..color = green..style = PaintingStyle.fill);

    // ★ Star at tip (Mecca marker)
    _drawStar(canvas, Offset(0, tipY - 11), 8, green);

    canvas.restore();
  }

  void _drawStar(Canvas canvas, Offset c, double r, Color color) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final oa = (i * 72 - 90) * math.pi / 180;
      final ia = oa + 36 * math.pi / 180;
      final outer = Offset(c.dx + r * math.cos(oa), c.dy + r * math.sin(oa));
      final inner = Offset(
          c.dx + r * 0.38 * math.cos(ia), c.dy + r * 0.38 * math.sin(ia));
      if (i == 0) {
        path.moveTo(outer.dx, outer.dy);
      } else {
        path.lineTo(outer.dx, outer.dy);
      }
      path.lineTo(inner.dx, inner.dy);
    }
    path.close();
    canvas.drawPath(
        path, Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_QiblaNeedlePainter old) =>
      old.aligned != aligned || old.isDark != isDark;
}
