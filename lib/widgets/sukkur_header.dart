import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SukkurHeader extends StatelessWidget {
  const SukkurHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isRtl = settings.isRtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    String title = settings.translate(
      'Sukkur, Sindh, Pakistan', 
      'سکھر، سندھ، پاکستان', 
      'سکر، سنڌ، پاڪستان', 
      'سكر، السند، باكستان'
    );
    if (settings.locationMode == LocationMode.world && settings.cityName != null) {
      title = settings.cityName!;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          settings.locationMode == LocationMode.world ? Icons.location_on : Icons.push_pin,
          size: 20,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            title,
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
