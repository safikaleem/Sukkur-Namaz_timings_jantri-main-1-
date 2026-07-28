import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'pin_icon.dart';

/// The city shown in the header and in the monthly month strip: just the city
/// name, or the chosen city when the app is in world-location mode.
String locationLabel(SettingsProvider settings) {
  if (settings.locationMode == LocationMode.world && settings.cityName != null) {
    return settings.cityName!;
  }
  return settings.translate('Sukkur', 'سکھر', 'سکر', 'سكر');
}

class SukkurHeader extends StatelessWidget {
  const SukkurHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isRtl = settings.isRtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (settings.locationMode == LocationMode.world)
          Icon(
            Icons.location_on,
            size: 20,
            color: isDark ? Colors.white70 : Colors.black87,
          )
        else
          const PinIcon(size: 20),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            locationLabel(settings),
            style: TextStyle(
              fontSize: isRtl ? 28 : 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
              letterSpacing: 0.3,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
