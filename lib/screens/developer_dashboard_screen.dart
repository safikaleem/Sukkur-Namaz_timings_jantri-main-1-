import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../services/developer_gist_service.dart';
import '../services/jamaat_times_service.dart';
import 'developer_add_masjid_screen.dart';
import 'developer_gist_manager_screen.dart';
import 'developer_timings_log_screen.dart';

/// Unified Developer & Master Admin Dashboard (Control Center)
/// Accessible exclusively with Master PIN: 25081989.
class DeveloperDashboardScreen extends StatefulWidget {
  const DeveloperDashboardScreen({super.key});

  @override
  State<DeveloperDashboardScreen> createState() => _DeveloperDashboardScreenState();
}

class _DeveloperDashboardScreenState extends State<DeveloperDashboardScreen> {
  bool _isSyncing = false;
  String? _gistToken;
  bool _obscureMasterPin = true;

  final Map<String, int> _monthMap = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  @override
  void initState() {
    super.initState();
    _loadDeveloperStatus();
  }

  Future<void> _loadDeveloperStatus() async {
    final token = await DeveloperGistService.instance.getGistToken();
    if (mounted) {
      setState(() {
        _gistToken = token;
      });
    }
  }

  DateTime? _parseDate(String dateStr) {
    try {
      final clean = dateStr.trim();
      if (clean.isEmpty) return null;
      final parts = clean.split(RegExp(r'\s+'));
      if (parts.length >= 3) {
        final day = int.tryParse(parts[0]);
        final monthStr = parts[1].toLowerCase().substring(0, 3);
        final month = _monthMap[monthStr];
        final year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          return DateTime(year, month, day);
        }
      }
    } catch (_) {}
    return null;
  }

  DateTime? _getLatestUpdateDate(JamaatTiming timing) {
    DateTime? latest;
    final dates = [
      _parseDate(timing.fajrUpdated),
      _parseDate(timing.zuharUpdated),
      _parseDate(timing.asarUpdated),
      _parseDate(timing.ishaUpdated),
      _parseDate(timing.jummahUpdated),
    ];
    for (final d in dates) {
      if (d != null) {
        if (latest == null || d.isAfter(latest)) {
          latest = d;
        }
      }
    }
    return latest;
  }

  Future<void> _triggerCloudSync() async {
    setState(() => _isSyncing = true);
    final success = await JamaatTimesService.instance.fetchRemoteGistTimings(force: true);
    await _loadDeveloperStatus();
    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Cloud Firestore & GitHub Gist synced successfully!'
                : 'Could not reach server. Showing local database cache.',
          ),
          backgroundColor: success ? const Color(0xFF1B4332) : const Color(0xFFB00020),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showGistTokenDialog() {
    final controller = TextEditingController(text: _gistToken ?? '');
    bool obscure = true;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.key_rounded, color: Color(0xFF1B4332)),
              SizedBox(width: 8),
              Text('GitHub PAT Token', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Personal Access Token (classic) with "gist" scope to authorize remote sync:',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                obscureText: obscure,
                decoration: InputDecoration(
                  hintText: 'ghp_xxxxxxxxxxxx',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 20),
                    onPressed: () => setDialogState(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4332),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final val = controller.text.trim();
                await DeveloperGistService.instance.saveGistToken(val);
                if (!dialogCtx.mounted) return;
                Navigator.pop(dialogCtx);
                if (!mounted) return;
                setState(() => _gistToken = val.isEmpty ? null : val);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('GitHub token saved successfully!'),
                    backgroundColor: Color(0xFF1B4332),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Save Token'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangeMasterPinDialog() async {
    final currentMaster = JamaatTimesService.instance.masterAdminPin;
    final pinController = TextEditingController(text: currentMaster);
    final confirmController = TextEditingController();
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E282A) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.password_rounded, color: Color(0xFFD97706), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Change Master PIN',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set a new master PIN to protect developer settings and unlock any masjid:',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: pinController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'New Master PIN',
                        hintText: 'e.g. 25081989',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Master PIN',
                        hintText: 'Re-enter PIN',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4332),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newPin = pinController.text.trim();
                          final confirmPin = confirmController.text.trim();

                          if (newPin.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('PIN cannot be empty.')),
                            );
                            return;
                          }
                          if (newPin != confirmPin) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('PINs do not match.')),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          final res = await JamaatTimesService.instance.updateMasterPin(newPin);
                          setDialogState(() => isSaving = false);

                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);

                          if (!mounted) return;
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res.message),
                              backgroundColor: res.success ? const Color(0xFF1B4332) : const Color(0xFFB00020),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save PIN'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _exportNetworkReport() async {
    final allMasajid = JamaatTimesService.instance.getMasjidList(includeHidden: true);
    final now = DateTime.now();
    final dayStr = now.day.toString().padLeft(2, '0');
    final monthKeys = _monthMap.keys.toList();
    final monthStr = monthKeys.firstWhere((k) => _monthMap[k] == now.month).toUpperCase();
    final dateFormatted = '$dayStr $monthStr ${now.year}';

    final buffer = StringBuffer();
    buffer.writeln('🕌 *Sukkur Salah - Complete Masajid Timings Report*');
    buffer.writeln('📅 Generated: $dateFormatted');
    buffer.writeln('📊 Total Network Mosques: ${allMasajid.length}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━');

    int counter = 1;
    for (final m in allMasajid) {
      final timing = JamaatTimesService.instance.getTimingFor(m);
      buffer.writeln('$counter. *${m.nameKey}* (${m.addressKey})');
      buffer.writeln('   • Fajr: ${timing.fajr}');
      buffer.writeln('   • Zuhar: ${timing.zuhar}');
      buffer.writeln('   • Asar: ${timing.asar}');
      buffer.writeln('   • Isha: ${timing.isha}');
      buffer.writeln('   • Jummah: ${timing.jummah}');
      if (m.isHidden) {
        buffer.writeln('   ⚠️ Status: Hidden in User App');
      }
      buffer.writeln();
      counter++;
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('Generated via Sukkur Salah Developer Control Center');

    final text = buffer.toString();
    try {
      await Share.share(text, subject: 'Sukkur Salah - Masajid Timings Report ($dateFormatted)');
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Full network report copied to clipboard!'),
            backgroundColor: Color(0xFF1B4332),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allMasajid = JamaatTimesService.instance.getMasjidList(includeHidden: true);

    // Compute live stats
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = today.subtract(const Duration(days: 7));
    final thirtyDaysAgo = today.subtract(const Duration(days: 30));

    int updatedThisWeek = 0;
    int updatedThisMonth = 0;
    int totalDefault = 0;
    int totalHidden = 0;

    for (final m in allMasajid) {
      if (m.isHidden) totalHidden++;
      final timing = JamaatTimesService.instance.getTimingFor(m);
      final latest = _getLatestUpdateDate(timing);
      if (latest == null) {
        totalDefault++;
      } else {
        if (!latest.isBefore(sevenDaysAgo)) updatedThisWeek++;
        if (!latest.isBefore(thirtyDaysAgo)) updatedThisMonth++;
      }
    }

    final currentMasterPin = JamaatTimesService.instance.masterAdminPin;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101719) : const Color(0xFFF4F6F6),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF182325) : const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.terminal_rounded, size: 20, color: Color(0xFF81C784)),
            SizedBox(width: 8),
            Text(
              'Developer Hub',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sync Cloud & Gist',
            icon: _isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.sync_rounded),
            onPressed: _isSyncing ? null : _triggerCloudSync,
          ),
          IconButton(
            tooltip: 'Lock & Exit Developer Mode',
            icon: const Icon(Icons.lock_outline_rounded),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Developer session locked.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _triggerCloudSync();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // ── Top Executive Banner ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1C2B2A), const Color(0xFF131D1E)]
                      : [const Color(0xFF1B4332), const Color(0xFF0F291E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF81C784).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF81C784).withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_rounded, size: 13, color: Color(0xFF81C784)),
                            SizedBox(width: 4),
                            Text(
                              'DEVELOPER ACTIVE',
                              style: TextStyle(
                                color: Color(0xFF81C784),
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'v1.4.7 • Production',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11.5,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Sukkur Salah Control Center',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Unified management for Live Timings, Remote GitHub Gist, Hijri Offsets & App Security.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Connectivity Pills
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPill(
                        icon: Icons.cloud_done_rounded,
                        label: 'Firestore: Live',
                        color: const Color(0xFF81C784),
                        isDark: isDark,
                      ),
                      _buildPill(
                        icon: _gistToken != null ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                        label: _gistToken != null ? 'Gist: Configured' : 'Gist: Token Missing',
                        color: _gistToken != null ? const Color(0xFF81C784) : const Color(0xFFFFB74D),
                        isDark: isDark,
                        onTap: _showGistTokenDialog,
                      ),
                      _buildPill(
                        icon: Icons.mosque_rounded,
                        label: '${allMasajid.length} Masajid Registered',
                        color: const Color(0xFF64B5F6),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Live Network Overview Grid ────────────────────────
            Row(
              children: [
                _buildMetricCard(
                  title: 'Total Masajid',
                  value: '${allMasajid.length}',
                  icon: Icons.mosque_rounded,
                  color: const Color(0xFF81C784),
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildMetricCard(
                  title: 'This Week',
                  value: '$updatedThisWeek',
                  icon: Icons.flash_on_rounded,
                  color: const Color(0xFFFFD54F),
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildMetricCard(
                  title: 'This Month',
                  value: '$updatedThisMonth',
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF64B5F6),
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildMetricCard(
                  title: totalHidden > 0 ? 'Hidden' : 'Default/Base',
                  value: totalHidden > 0 ? '$totalHidden' : '$totalDefault',
                  icon: totalHidden > 0 ? Icons.visibility_off_rounded : Icons.history_rounded,
                  color: totalHidden > 0 ? const Color(0xFFE57373) : const Color(0xFFE0E0E0),
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── SECTION 1: CORE MODULES ────────────────────────────
            _buildSectionHeader('CORE MODULES', isDark),
            const SizedBox(height: 10),

            // Module 1: Masjid Timings & Change Log
            _buildActionCard(
              context: context,
              icon: Icons.calendar_month_rounded,
              iconBgColor: const Color(0xFF2E7D32),
              title: 'Masjid Timings & Change Log',
              subtitle: 'Live audit of all masajid, edit prayer times, toggle visibility & manage committee PINs',
              badgeText: '$updatedThisWeek updated recently',
              badgeColor: const Color(0xFF2E7D32),
              isDark: isDark,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DeveloperTimingsLogScreen()),
                );
                if (mounted) setState(() {});
              },
            ),

            const SizedBox(height: 10),

            // Module 2: Add New Masjid
            _buildActionCard(
              context: context,
              icon: Icons.add_business_rounded,
              iconBgColor: const Color(0xFF00796B),
              title: 'Register New Masjid',
              subtitle: 'Add new mosque across all 10 languages with GPS coordinates, sector & committee PIN',
              badgeText: '10 Languages',
              badgeColor: const Color(0xFF00796B),
              isDark: isDark,
              onTap: () async {
                final added = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const DeveloperAddMasjidScreen()),
                );
                if (added == true && mounted) {
                  _triggerCloudSync();
                }
              },
            ),

            const SizedBox(height: 10),

            // Module 3: Hijri Calendar & Moon Sighting
            _buildActionCard(
              context: context,
              icon: Icons.nightlight_round,
              iconBgColor: const Color(0xFF3949AB),
              title: 'Hijri Calendar & Moon Sighting',
              subtitle: 'Adjust Islamic month start dates dynamically on GitHub Gist without releasing an app store update',
              badgeText: 'Live Gist',
              badgeColor: const Color(0xFF3949AB),
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DeveloperGistManagerScreen(initialTabIndex: 0),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            // Module 4: In-App Announcements & Popups
            _buildActionCard(
              context: context,
              icon: Icons.campaign_rounded,
              iconBgColor: const Color(0xFFD81B60),
              title: 'Announcements & Popups',
              subtitle: 'Configure Ramadan/Eid alert popups, persistent banners & urgent notices for all users',
              badgeText: 'In-App Alerts',
              badgeColor: const Color(0xFFD81B60),
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DeveloperGistManagerScreen(initialTabIndex: 1),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // ── SECTION 2: SECURITY & CLOUD ENGINE ────────────────
            _buildSectionHeader('SECURITY & CLOUD ENGINE', isDark),
            const SizedBox(height: 10),

            // Master PIN Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF182325) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFFD97706).withValues(alpha: 0.3) : const Color(0xFFD97706).withValues(alpha: 0.25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.security_rounded, color: Color(0xFFD97706), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Master Developer PIN',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              _obscureMasterPin ? '••••••••' : currentMasterPin,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                letterSpacing: 1.5,
                                color: Color(0xFFD97706),
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => setState(() => _obscureMasterPin = !_obscureMasterPin),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Icon(
                                  _obscureMasterPin ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  size: 16,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4332),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.edit_rounded, size: 14),
                    label: const Text('Change', style: TextStyle(fontSize: 12)),
                    onPressed: _showChangeMasterPinDialog,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Cloud Sync & Token Engine
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF182325) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1976D2).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.cloud_sync_rounded, color: Color(0xFF1976D2), size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GitHub Personal Access Token',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _gistToken != null
                                  ? 'Token: ${_gistToken!.substring(0, 6)}••••••••'
                                  : 'Not set (Required to write changes to Gist)',
                              style: TextStyle(
                                fontSize: 12,
                                color: _gistToken != null
                                    ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
                                    : const Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        onPressed: _showGistTokenDialog,
                        child: Text(
                          _gistToken != null ? 'Edit Token' : 'Set Token',
                          style: const TextStyle(fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: _isSyncing
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Force Cloud Sync', style: TextStyle(fontSize: 12)),
                          onPressed: _isSyncing ? null : _triggerCloudSync,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B4332),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.share_rounded, size: 16),
                          label: const Text('Export Report', style: TextStyle(fontSize: 12)),
                          onPressed: _exportNetworkReport,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: isDark ? Colors.white38 : Colors.black45,
        ),
      ),
    );
  }

  Widget _buildPill({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.white,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: content,
      );
    }
    return content;
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF182325) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black12,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: color),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 9.5,
                color: isDark ? Colors.white60 : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF182325) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconBgColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? Colors.white30 : Colors.black26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
