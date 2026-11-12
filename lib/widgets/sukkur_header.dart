import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'pin_icon.dart';

/// The city shown in the header and in the monthly month strip: just the city
/// name, or the chosen city when the app is in world-location mode.
String locationLabel(SettingsProvider settings) {
  if (settings.usesCalculatedTimings && settings.cityName != null) {
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
    final label = locationLabel(settings);
    final isLong = label.length > 20;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 56),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: settings.usesCalculatedTimings
                ? Icon(
                    Icons.location_on,
                    size: isLong ? 18 : 20,
                    color: isDark ? Colors.white70 : Colors.black87,
                  )
                : PinIcon(size: isLong ? 18 : 20),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isLong
                    ? (isRtl ? 20 : 17)
                    : (isRtl ? 28 : 24),
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: 0.3,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
