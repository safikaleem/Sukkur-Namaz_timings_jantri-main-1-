import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/settings_provider.dart';
import '../services/jamaat_times_service.dart';
import '../services/developer_gist_service.dart';
import 'developer_gist_manager_screen.dart';
import 'developer_add_masjid_screen.dart';

/// Private Developer / Admin Log Screen for tracking Jama'at timing changes across all Masajid.
/// Accessible exclusively with Master PIN: 25081989.
class DeveloperTimingsLogScreen extends StatefulWidget {
  const DeveloperTimingsLogScreen({super.key});

  @override
  State<DeveloperTimingsLogScreen> createState() => _DeveloperTimingsLogScreenState();
}

class _DeveloperTimingsLogScreenState extends State<DeveloperTimingsLogScreen> {
  String _searchQuery = '';
  String _filter = 'all'; // 'all', 'updated', 'default'
  bool _isRefreshing = false;

  final Map<String, int> _monthMap = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

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

  List<String> _getUpdatedPrayersList(JamaatTiming timing) {
    final list = <String>[];
    if (timing.fajrUpdated.isNotEmpty) list.add('Fajr (${timing.fajrUpdated})');
    if (timing.zuharUpdated.isNotEmpty) list.add('Zuhar (${timing.zuharUpdated})');
    if (timing.asarUpdated.isNotEmpty) list.add('Asar (${timing.asarUpdated})');
    if (timing.ishaUpdated.isNotEmpty) list.add('Isha (${timing.ishaUpdated})');
    if (timing.jummahUpdated.isNotEmpty) list.add('Jummah (${timing.jummahUpdated})');
    return list;
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    final success = await JamaatTimesService.instance.fetchRemoteGistTimings(force: true);
    if (mounted) {
      setState(() => _isRefreshing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Synced live timings from Cloud Firestore & Gist!'
                : 'Could not reach server. Showing local cache.',
          ),
          backgroundColor: success
              ? const Color(0xFF1B4332)
              : const Color(0xFFB00020),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _shareReport(
    List<({JamaatMasjidInfo masjid, JamaatTiming timing, DateTime? latestDate, List<String> updatedPrayers})> items,
  ) async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No masajid found in current filter to share.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final dayStr = now.day.toString().padLeft(2, '0');
    final monthKeys = _monthMap.keys.toList();
    final monthStr = monthKeys.firstWhere((k) => _monthMap[k] == now.month).toUpperCase();
    final dateFormatted = '$dayStr $monthStr ${now.year}';

    final filterLabel = switch (_filter) {
      'week' => 'This Week (Last 7 Days)',
      'month' => 'This Month (Last 30 Days)',
      'default' => 'Unchanged (Default)',
      _ => 'All Masajid',
    };

    final buffer = StringBuffer();
    buffer.writeln('🕌 *Sukkur Salah - Masajid Timings Update Report*');
    buffer.writeln('📅 Date: $dateFormatted');
    buffer.writeln('📊 Category: $filterLabel (${items.length} Masajid)');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━');

    int counter = 1;
    for (final item in items) {
      buffer.writeln('$counter. *${item.masjid.nameKey}* (${item.masjid.addressKey})');
      if (item.updatedPrayers.isNotEmpty) {
        for (final p in item.updatedPrayers) {
          buffer.writeln('   • $p');
        }
      } else {
        buffer.writeln('   • Timings: Default (Base)');
      }
      buffer.writeln();
      counter++;
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('Generated by Sukkur Namaz Timings App');

    final text = buffer.toString();
    try {
      await Share.share(
        text,
        subject: 'Sukkur Salah - Masajid Timings Report ($dateFormatted)',
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report copied to clipboard!'),
            backgroundColor: Color(0xFF1B4332),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allMasajid = JamaatTimesService.instance.getMasjidList(includeHidden: true);

    // Collect info with calculated latest update dates
    final records = allMasajid.map((m) {
      final timing = JamaatTimesService.instance.getTimingFor(m);
      final latestDate = _getLatestUpdateDate(timing);
      final updatedPrayers = _getUpdatedPrayersList(timing);
      return (
        masjid: m,
        timing: timing,
        latestDate: latestDate,
        updatedPrayers: updatedPrayers,
      );
    }).toList();

    // Sort by latest update date first (newest to oldest), then by original order
    records.sort((a, b) {
      if (a.latestDate != null && b.latestDate != null) {
        return b.latestDate!.compareTo(a.latestDate!);
      } else if (a.latestDate != null) {
        return -1;
      } else if (b.latestDate != null) {
        return 1;
      }
      return 0;
    });

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = today.subtract(const Duration(days: 7));
    final thirtyDaysAgo = today.subtract(const Duration(days: 30));

    final updatedThisWeek = records.where((r) => r.latestDate != null && !r.latestDate!.isBefore(sevenDaysAgo)).length;
    final updatedThisMonth = records.where((r) => r.latestDate != null && !r.latestDate!.isBefore(thirtyDaysAgo)).length;
    final totalDefault = records.where((r) => r.latestDate == null).length;
    final totalHidden = records.where((r) => r.masjid.isHidden).length;

    // Filtering
    final filtered = records.where((r) {
      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = r.masjid.nameKey.toLowerCase();
        final addr = r.masjid.addressKey.toLowerCase();
        if (!name.contains(q) && !addr.contains(q)) return false;
      }
      // Timeframe & status filter
      if (_filter == 'week') {
        if (r.latestDate == null || r.latestDate!.isBefore(sevenDaysAgo)) return false;
      } else if (_filter == 'month') {
        if (r.latestDate == null || r.latestDate!.isBefore(thirtyDaysAgo)) return false;
      } else if (_filter == 'default') {
        if (r.latestDate != null) return false;
      } else if (_filter == 'hidden') {
        if (!r.masjid.isHidden) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF12181A) : const Color(0xFFF4F6F6),
      appBar: AppBar(
        title: const Text(
          'Admin Change Log',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: isDark ? const Color(0xFF1A2426) : const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_rounded),
            tooltip: 'Add New Masjid (All 10 Languages)',
            onPressed: () async {
              final added = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const DeveloperAddMasjidScreen()),
              );
              if (added == true) {
                _refreshData();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.cloud_upload_rounded),
            tooltip: 'Gist Manager (Hijri & Popups)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeveloperGistManagerScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.password_rounded),
            tooltip: 'Change Master PIN',
            onPressed: _showChangeMasterPinDialog,
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share / Export Timings Report',
            onPressed: () => _shareReport(filtered),
          ),
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.sync_rounded),
            tooltip: 'Sync with Cloud Firestore & Gist',
            onPressed: _isRefreshing ? null : _refreshData,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Stat Summary Cards ──────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2426) : const Color(0xFF1B4332),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                _buildStatCard(
                  title: 'Total Masajid',
                  value: '${allMasajid.length}',
                  icon: Icons.mosque_rounded,
                  color: const Color(0xFF81C784),
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildStatCard(
                  title: 'This Week',
                  value: '$updatedThisWeek',
                  icon: Icons.flash_on_rounded,
                  color: const Color(0xFFFFD54F),
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildStatCard(
                  title: 'This Month',
                  value: '$updatedThisMonth',
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF64B5F6),
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // ── Master PIN Status Banner ────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E282A) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? const Color(0xFFD97706).withValues(alpha: 0.35)
                    : const Color(0xFFD97706).withValues(alpha: 0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, size: 16, color: Color(0xFFD97706)),
                ),
                const SizedBox(width: 8),
                Text(
                  'Master PIN: ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                Text(
                  JamaatTimesService.instance.masterAdminPin,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 1.2,
                    color: Color(0xFFD97706),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _showChangeMasterPinDialog,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_rounded,
                          size: 13,
                          color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B4332),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B4332),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Search Bar & Filter Chips ───────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search masjid name or area...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E282A) : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All (${allMasajid.length})', isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('week', 'This Week ($updatedThisWeek)', isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('month', 'This Month ($updatedThisMonth)', isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('default', 'Unchanged ($totalDefault)', isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('hidden', 'Hidden ($totalHidden)', isDark, isAlert: totalHidden > 0),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── List of Masajid with Update Timestamps ──────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No matching masajid found',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _buildMasjidLogCard(
                        context: context,
                        settings: settings,
                        masjid: item.masjid,
                        timing: item.timing,
                        latestDate: item.latestDate,
                        updatedPrayers: item.updatedPrayers,
                        isDark: isDark,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const Spacer(),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10.5,
                color: Colors.white70,
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

  Widget _buildFilterChip(String key, String label, bool isDark, {bool isAlert = false}) {
    final selected = _filter == key;
    final activeBg = isAlert
        ? const Color(0xFFC62828)
        : (isDark ? const Color(0xFF2E7D32) : const Color(0xFF1B4332));
    final inactiveBorder = isAlert
        ? const Color(0xFFEF4444).withValues(alpha: 0.5)
        : (isDark ? Colors.white12 : Colors.black12);
    final inactiveText = isAlert
        ? const Color(0xFFEF4444)
        : (isDark ? Colors.white70 : Colors.black87);

    return GestureDetector(
      onTap: () => setState(() => _filter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? activeBg
              : (isDark ? const Color(0xFF1E282A) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : inactiveBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? Colors.white : inactiveText,
          ),
        ),
      ),
    );
  }

  Widget _buildMasjidLogCard({
    required BuildContext context,
    required SettingsProvider settings,
    required JamaatMasjidInfo masjid,
    required JamaatTiming timing,
    required DateTime? latestDate,
    required List<String> updatedPrayers,
    required bool isDark,
  }) {
    final hasUpdates = latestDate != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: masjid.isHidden
            ? (isDark ? const Color(0xFF221A1B) : const Color(0xFFFFF5F5))
            : (isDark ? const Color(0xFF1E282A) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: masjid.isHidden
              ? (isDark ? const Color(0xFFF87171).withValues(alpha: 0.6) : const Color(0xFFEF4444).withValues(alpha: 0.4))
              : (hasUpdates
                  ? (isDark
                      ? const Color(0xFF81C784).withValues(alpha: 0.5)
                      : const Color(0xFF2E7D32).withValues(alpha: 0.35))
                  : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06))),
          width: (hasUpdates || masjid.isHidden) ? 1.4 : 1.0,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Name & Update Badge ──────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            masjid.nameKey,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            final updated = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DeveloperAddMasjidScreen(initialMasjid: masjid),
                              ),
                            );
                            if (updated == true) {
                              _refreshData();
                            }
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.edit_note_rounded,
                                  size: 16,
                                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Edit Info',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      masjid.addressKey,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white54 : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Committee PIN display, 1-tap copy & edit
                        Builder(
                          builder: (ctx) {
                            final pin = JamaatTimesService.instance.getMasjidPin(masjid.id);
                            final hasPin = pin != null && pin.isNotEmpty;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E2D33) : const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF38BDF8).withValues(alpha: 0.3)
                                      : const Color(0xFF0284C7).withValues(alpha: 0.3),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.key_rounded, size: 12, color: Color(0xFF0284C7)),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: hasPin
                                        ? () {
                                            Clipboard.setData(ClipboardData(text: pin));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Copied PIN for ${masjid.nameKey}: $pin'),
                                                backgroundColor: const Color(0xFF1B4332),
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        : () => _showChangeMasjidPinDialog(masjid, ''),
                                    child: Text(
                                      hasPin ? 'PIN: $pin' : '+ Set PIN',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: hasPin ? 'monospace' : null,
                                        color: isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0369A1),
                                      ),
                                    ),
                                  ),
                                  if (hasPin) ...[
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: pin));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Copied PIN for ${masjid.nameKey}: $pin'),
                                            backgroundColor: const Color(0xFF1B4332),
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      child: Icon(
                                        Icons.copy_rounded,
                                        size: 11,
                                        color: isDark ? Colors.white60 : Colors.black45,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 5),
                                  GestureDetector(
                                    onTap: () => _showChangeMasjidPinDialog(masjid, pin ?? ''),
                                    child: Icon(
                                      Icons.edit_rounded,
                                      size: 12,
                                      color: isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0284C7),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        // Edit & Sync to Gist button
                        GestureDetector(
                          onTap: () => _showEditTimingsSheet(masjid, timing),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2E7D32).withValues(alpha: 0.25)
                                  : const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF2E7D32).withValues(alpha: 0.4),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.edit_calendar_rounded,
                                  size: 12,
                                  color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B4332),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Edit & Sync Gist',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B4332),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Edit Mosque Info (Name, Address, 10 Languages) button
                        GestureDetector(
                          onTap: () async {
                            final updated = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DeveloperAddMasjidScreen(initialMasjid: masjid),
                              ),
                            );
                            if (updated == true) {
                              _refreshData();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E2838)
                                  : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.edit_note_rounded,
                                  size: 13,
                                  color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Edit Info (10 Langs)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Hide / Unhide toggle button
                        GestureDetector(
                          onTap: () => _confirmToggleHidden(masjid, hide: !masjid.isHidden),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: masjid.isHidden
                                  ? (isDark
                                      ? const Color(0xFF1E2D24)
                                      : const Color(0xFFDCFCE7))
                                  : (isDark
                                      ? const Color(0xFF332022)
                                      : const Color(0xFFFEE2E2)),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: masjid.isHidden
                                    ? (isDark
                                        ? const Color(0xFF4ADE80).withValues(alpha: 0.4)
                                        : const Color(0xFF16A34A).withValues(alpha: 0.4))
                                    : (isDark
                                        ? const Color(0xFFF87171).withValues(alpha: 0.4)
                                        : const Color(0xFFEF4444).withValues(alpha: 0.4)),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  masjid.isHidden ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                  size: 12,
                                  color: masjid.isHidden
                                      ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D))
                                      : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626)),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  masjid.isHidden ? 'Unhide' : 'Hide',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: masjid.isHidden
                                        ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D))
                                        : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (masjid.isHidden)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_off_rounded,
                        size: 11,
                        color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'HIDDEN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hasUpdates
                      ? (isDark
                          ? const Color(0xFF2E7D32).withValues(alpha: 0.25)
                          : const Color(0xFFE8F5E9))
                      : (isDark ? Colors.white10 : Colors.grey[200]),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasUpdates
                        ? const Color(0xFF2E7D32).withValues(alpha: 0.5)
                        : Colors.transparent,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasUpdates ? Icons.verified_rounded : Icons.schedule_rounded,
                      size: 13,
                      color: hasUpdates ? const Color(0xFF2E7D32) : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasUpdates
                          ? '${latestDate.day.toString().padLeft(2, '0')} ${_monthMap.keys.firstWhere((k) => _monthMap[k] == latestDate.month).toUpperCase()} ${latestDate.year}'
                          : 'Default',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: hasUpdates
                            ? (isDark ? const Color(0xFF81C784) : const Color(0xFF1B4332))
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // ── Prayer Timings Grid ──────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPrayerPill('Fajr', timing.fajr, timing.fajrUpdated, isDark),
              _buildPrayerPill('Zuhar', timing.zuhar, timing.zuharUpdated, isDark),
              _buildPrayerPill('Asar', timing.asar, timing.asarUpdated, isDark),
              _buildPrayerPill('Maghrib', timing.maghrib, timing.maghribNoteEn, isDark),
              _buildPrayerPill('Isha', timing.isha, timing.ishaUpdated, isDark),
              _buildPrayerPill('Jummah', timing.jummah, timing.jummahUpdated, isDark),
            ],
          ),

          // ── Specific Changed Prayers List (if any) ────────────
          if (updatedPrayers.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFFFFD54F).withValues(alpha: 0.12)
                    : const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.4),
                  width: 0.8,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1.5),
                    child: Icon(
                      Icons.history_rounded,
                      size: 14,
                      color: isDark ? const Color(0xFFFFD54F) : const Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Updated: ${updatedPrayers.join(', ')}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        color: isDark ? const Color(0xFFFFD54F) : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrayerPill(String name, String time, String updatedDate, bool isDark) {
    final isUpdated = updatedDate.isNotEmpty;
    return Expanded(
      child: Column(
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isUpdated
                  ? (isDark
                      ? const Color(0xFF2E7D32).withValues(alpha: 0.3)
                      : const Color(0xFFE8F5E9))
                  : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F5)),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isUpdated
                    ? const Color(0xFF2E7D32).withValues(alpha: 0.4)
                    : Colors.transparent,
                width: 0.6,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              time,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isUpdated ? FontWeight.bold : FontWeight.w500,
                color: isUpdated
                    ? (isDark ? const Color(0xFF81C784) : const Color(0xFF1B4332))
                    : (isDark ? Colors.white : Colors.black87),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  TimeOfDay _parseTimeOfDay(String timeStr, {required TimeOfDay fallback}) {
    try {
      final clean = timeStr.trim().toUpperCase();
      if (clean == 'SUNSET' || clean.isEmpty) return fallback;
      final parts = clean.split(' ');
      final timeParts = parts[0].split(':');
      int h = int.parse(timeParts[0]);
      int m = int.parse(timeParts[1]);
      if (parts.length > 1) {
        if (parts[1] == 'PM' && h < 12) h += 12;
        if (parts[1] == 'AM' && h == 12) h = 0;
      }
      return TimeOfDay(hour: h, minute: m);
    } catch (_) {
      return fallback;
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minute = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  /// Confirmation dialog and execution to Hide or Unhide a mosque in the app
  Future<void> _confirmToggleHidden(JamaatMasjidInfo masjid, {required bool hide}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E282A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (hide ? Colors.red : const Color(0xFF1B4332)).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  hide ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: hide ? Colors.red : const Color(0xFF1B4332),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hide ? 'Hide Mosque?' : 'Unhide Mosque?',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            hide
                ? 'Are you sure you want to hide "${masjid.nameKey}" from regular users?\n\nIt will be hidden from the app prayer list and Gist, but will remain visible in this Developer screen so you can unhide it at any time.'
                : 'Make "${masjid.nameKey}" visible again to all users in the app and sync to Gist?',
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: hide ? const Color(0xFFC62828) : const Color(0xFF1B4332),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(hide ? 'Hide Mosque' : 'Unhide Mosque'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(hide ? 'Hiding mosque and syncing to Gist...' : 'Unhiding mosque and syncing to Gist...'),
          duration: const Duration(seconds: 2),
        ),
      );

      final res = await JamaatTimesService.instance.toggleMasjidHidden(
        masjidId: masjid.id,
        hide: hide,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res.success
                  ? (hide ? 'Mosque hidden & synced to Gist!' : 'Mosque unhidden & synced to Gist!')
                  : 'Local status updated. Gist sync: ${res.message}',
            ),
            backgroundColor: res.success ? const Color(0xFF1B4332) : const Color(0xFFE65100),
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {});
      }
    }
  }

  /// Dialog to view, change, or assign a committee PIN for a specific Mosque
  Future<void> _showChangeMasjidPinDialog(JamaatMasjidInfo masjid, String currentPin) async {
    final pinController = TextEditingController(text: currentPin);
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
                      color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.pin_rounded, color: Color(0xFF0284C7), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Masjid Committee PIN',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          masjid.nameKey,
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This committee PIN allows the mosque imam / committee to update prayer times from their phone.',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Committee PIN',
                      hintText: 'e.g. 1234 or 2026',
                      prefixIcon: const Icon(Icons.key_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  if (currentPin.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Current PIN: $currentPin',
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black45),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4332),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(isSaving ? 'Saving to Gist...' : 'Save & Sync Gist'),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newPin = pinController.text.trim();
                          if (newPin.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('PIN cannot be empty.')),
                            );
                            return;
                          }
                          if (newPin.length < 4) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('PIN must be at least 4 digits.')),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          final result = await JamaatTimesService.instance.updateMasjidPin(
                            masjidId: masjid.id,
                            newPin: newPin,
                          );

                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result.success
                                      ? 'PIN updated & synced to Gist for ${masjid.nameKey}: $newPin'
                                      : 'Saved locally. Gist update: ${result.message}',
                                ),
                                backgroundColor: result.success
                                    ? const Color(0xFF1B4332)
                                    : const Color(0xFFE65100),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                            setState(() {});
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Dialog to view, change, and sync Master Admin PIN across the entire app
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFD97706), size: 22),
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
                      'The Master PIN grants developer/admin access to all masajid, logs, settings, and Gist management across the entire app.',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF12181A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Current Master PIN: ',
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54),
                          ),
                          Text(
                            currentMaster,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: pinController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 2,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        labelText: 'New Master PIN',
                        prefixIcon: const Icon(Icons.password_rounded, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 2,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Confirm New Master PIN',
                        prefixIcon: const Icon(Icons.check_circle_outline_rounded, size: 20),
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
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4332),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(isSaving ? 'Updating...' : 'Update & Sync Gist'),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newPin = pinController.text.trim();
                          final confirmPin = confirmController.text.trim();

                          if (newPin.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Master PIN cannot be empty.')),
                            );
                            return;
                          }
                          if (newPin.length < 4) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Master PIN must be at least 4 digits.')),
                            );
                            return;
                          }
                          if (newPin != confirmPin) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('PINs do not match. Please re-enter.')),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          final result = await JamaatTimesService.instance.updateMasterPin(newPin);

                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result.success
                                      ? 'Master PIN successfully updated to: $newPin & synced to Gist!'
                                      : 'Saved locally. Gist sync: ${result.message}',
                                ),
                                backgroundColor: result.success
                                    ? const Color(0xFF1B4332)
                                    : const Color(0xFFE65100),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                            setState(() {});
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditTimingsSheet(
    JamaatMasjidInfo masjid,
    JamaatTiming currentTiming,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final token = await DeveloperGistService.instance.getGistToken();
    final hasToken = token != null && token.isNotEmpty;

    String fajr = currentTiming.fajr;
    String zuhar = currentTiming.zuhar;
    String asar = currentTiming.asar;
    String maghrib = currentTiming.maghrib.isNotEmpty ? currentTiming.maghrib : 'Sunset';
    String isha = currentTiming.isha;
    String jummah = currentTiming.jummah;
    final Set<String> modifiedPrayers = {};
    bool isSaving = false;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sCtx, setSheetState) {
            Future<void> pickTimeFor(String currentVal, Function(String) onPicked, {TimeOfDay? fallback}) async {
              final initial = _parseTimeOfDay(currentVal, fallback: fallback ?? const TimeOfDay(hour: 12, minute: 0));
              final picked = await showTimePicker(
                context: sCtx,
                initialTime: initial,
                builder: (pickerCtx, child) {
                  return Theme(
                    data: Theme.of(pickerCtx).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: const Color(0xFF1B4332),
                        onPrimary: Colors.white,
                        onSurface: isDark ? Colors.white : Colors.black87,
                        surface: isDark ? const Color(0xFF222C2E) : Colors.white,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setSheetState(() {
                  onPicked(_formatTimeOfDay(picked));
                });
              }
            }

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sCtx).viewInsets.bottom + 20,
                top: 16,
                left: 18,
                right: 18,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1D2628) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black26,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Title Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B4332).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.edit_calendar_rounded,
                            color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B4332),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit Jama\'at Timings',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${masjid.nameKey} • ${masjid.addressKey}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Gist & Cloud Sync Info Banner
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: hasToken
                            ? (isDark
                                ? const Color(0xFF1B4332).withValues(alpha: 0.3)
                                : const Color(0xFFE8F5E9))
                            : (isDark
                                ? const Color(0xFFD97706).withValues(alpha: 0.15)
                                : const Color(0xFFFFF8E1)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: hasToken
                              ? const Color(0xFF2E7D32).withValues(alpha: 0.4)
                              : const Color(0xFFD97706).withValues(alpha: 0.4),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            hasToken ? Icons.cloud_done_rounded : Icons.warning_amber_rounded,
                            size: 16,
                            color: hasToken
                                ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
                                : (isDark ? const Color(0xFFFFD54F) : const Color(0xFFD97706)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: hasToken
                                ? Text(
                                    'Live Gist Sync Enabled: Saving here updates Firestore and pushes directly to GitHub Gist (jamaat_times.json).',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark ? const Color(0xFFA5D6A7) : const Color(0xFF1B4332),
                                      height: 1.35,
                                    ),
                                  )
                                : GestureDetector(
                                    onTap: () {
                                      Navigator.of(sCtx).pop();
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const DeveloperGistManagerScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'GitHub Token not set: Updates will sync to Firestore only. Tap here to set Gist Token in Developer settings.',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? const Color(0xFFFFD54F) : const Color(0xFFB45309),
                                        decoration: TextDecoration.underline,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Fajr
                    _buildEditPrayerTile(
                      isDark: isDark,
                      name: 'Fajr',
                      time: fajr,
                      icon: Icons.wb_twilight_rounded,
                      onTap: () => pickTimeFor(fajr, (v) {
                        fajr = v;
                        modifiedPrayers.add('fajr');
                      }, fallback: const TimeOfDay(hour: 5, minute: 30)),
                      onClear: () => setSheetState(() {
                        fajr = '';
                        modifiedPrayers.add('fajr');
                      }),
                    ),
                    const SizedBox(height: 8),

                    // Zuhar
                    _buildEditPrayerTile(
                      isDark: isDark,
                      name: 'Zuhar',
                      time: zuhar,
                      icon: Icons.wb_sunny_rounded,
                      onTap: () => pickTimeFor(zuhar, (v) {
                        zuhar = v;
                        modifiedPrayers.add('zuhar');
                      }, fallback: const TimeOfDay(hour: 13, minute: 30)),
                      onClear: () => setSheetState(() {
                        zuhar = '';
                        modifiedPrayers.add('zuhar');
                      }),
                    ),
                    const SizedBox(height: 8),

                    // Asar
                    _buildEditPrayerTile(
                      isDark: isDark,
                      name: 'Asar',
                      time: asar,
                      icon: Icons.wb_sunny_outlined,
                      onTap: () => pickTimeFor(asar, (v) {
                        asar = v;
                        modifiedPrayers.add('asar');
                      }, fallback: const TimeOfDay(hour: 17, minute: 0)),
                      onClear: () => setSheetState(() {
                        asar = '';
                        modifiedPrayers.add('asar');
                      }),
                    ),
                    const SizedBox(height: 8),

                    // Maghrib (Sunset fixed note)
                    _buildEditPrayerTile(
                      isDark: isDark,
                      name: 'Maghrib',
                      time: maghrib,
                      icon: Icons.nights_stay_outlined,
                      subtitle: 'Auto Sunset (Sukkur Jantri)',
                      isLocked: true,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Maghrib time is calculated daily based on Sukkur Jantri Sunset time.'),
                            backgroundColor: Color(0xFF1B4332),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),

                    // Isha
                    _buildEditPrayerTile(
                      isDark: isDark,
                      name: 'Isha',
                      time: isha,
                      icon: Icons.bedtime_rounded,
                      onTap: () => pickTimeFor(isha, (v) {
                        isha = v;
                        modifiedPrayers.add('isha');
                      }, fallback: const TimeOfDay(hour: 20, minute: 0)),
                      onClear: () => setSheetState(() {
                        isha = '';
                        modifiedPrayers.add('isha');
                      }),
                    ),
                    const SizedBox(height: 8),

                    // Jummah
                    _buildEditPrayerTile(
                      isDark: isDark,
                      name: 'Jummah',
                      time: jummah,
                      icon: Icons.star_rounded,
                      onTap: () => pickTimeFor(jummah, (v) {
                        jummah = v;
                        modifiedPrayers.add('jummah');
                      }, fallback: const TimeOfDay(hour: 13, minute: 15)),
                      onClear: () => setSheetState(() {
                        jummah = '';
                        modifiedPrayers.add('jummah');
                      }),
                    ),

                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(
                                color: isDark ? Colors.white24 : Colors.black12,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: isSaving ? null : () => Navigator.of(sCtx).pop(),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: const Color(0xFF1B4332),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.cloud_upload_rounded, size: 20),
                            label: Text(
                              isSaving ? 'Saving...' : 'Save & Sync Gist',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            onPressed: isSaving
                                ? null
                                : () async {
                                    setSheetState(() => isSaving = true);
                                    const months = [
                                      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
                                    ];
                                    final now = DateTime.now();
                                    final todayStr = '${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]} ${now.year}';
                                    final forceStampAll = modifiedPrayers.isEmpty &&
                                        fajr == currentTiming.fajr &&
                                        zuhar == currentTiming.zuhar &&
                                        asar == currentTiming.asar &&
                                        isha == currentTiming.isha &&
                                        jummah == currentTiming.jummah;

                                    final updatedTiming = JamaatTiming(
                                      fajr: fajr,
                                      fajrUpdated: (fajr != currentTiming.fajr || modifiedPrayers.contains('fajr') || forceStampAll)
                                          ? todayStr
                                          : currentTiming.fajrUpdated,
                                      fajrNoteUr: currentTiming.fajrNoteUr,
                                      fajrNoteEn: currentTiming.fajrNoteEn,
                                      zuhar: zuhar,
                                      zuharUpdated: (zuhar != currentTiming.zuhar || modifiedPrayers.contains('zuhar') || forceStampAll)
                                          ? todayStr
                                          : currentTiming.zuharUpdated,
                                      zuharNoteUr: currentTiming.zuharNoteUr,
                                      zuharNoteEn: currentTiming.zuharNoteEn,
                                      asar: asar,
                                      asarUpdated: (asar != currentTiming.asar || modifiedPrayers.contains('asar') || forceStampAll)
                                          ? todayStr
                                          : currentTiming.asarUpdated,
                                      asarNoteUr: currentTiming.asarNoteUr,
                                      asarNoteEn: currentTiming.asarNoteEn,
                                      maghrib: 'Sunset',
                                      maghribNoteUr: currentTiming.maghribNoteUr,
                                      maghribNoteEn: currentTiming.maghribNoteEn,
                                      isha: isha,
                                      ishaUpdated: (isha != currentTiming.isha || modifiedPrayers.contains('isha') || forceStampAll)
                                          ? todayStr
                                          : currentTiming.ishaUpdated,
                                      ishaNoteUr: currentTiming.ishaNoteUr,
                                      ishaNoteEn: currentTiming.ishaNoteEn,
                                      jummah: jummah,
                                      jummahUpdated: (jummah != currentTiming.jummah || modifiedPrayers.contains('jummah') || forceStampAll)
                                          ? todayStr
                                          : currentTiming.jummahUpdated,
                                      jummahNoteUr: currentTiming.jummahNoteUr,
                                      jummahNoteEn: currentTiming.jummahNoteEn,
                                    );

                                    // 1. Update local cache and Firestore
                                    await JamaatTimesService.instance.updateTimingForMasjid(
                                      masjidId: masjid.id,
                                      newTiming: updatedTiming,
                                    );

                                    // 2. Sync to GitHub Gist
                                    final gistRes = await JamaatTimesService.instance.syncMasjidTimingToGist(
                                      masjid.id,
                                      updatedTiming,
                                    );

                                    if (sCtx.mounted) {
                                      Navigator.of(sCtx).pop();
                                    }

                                    if (mounted) {
                                      setState(() {});
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              Icon(
                                                gistRes.success ? Icons.cloud_done_rounded : Icons.info_outline_rounded,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  gistRes.success
                                                      ? 'Updated ${masjid.nameKey} timings & successfully pushed to GitHub Gist!'
                                                      : 'Saved locally & Firestore. (${gistRes.message})',
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: gistRes.success
                                              ? const Color(0xFF1B4332)
                                              : const Color(0xFFD97706),
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEditPrayerTile({
    required bool isDark,
    required String name,
    required String time,
    required IconData icon,
    String? subtitle,
    bool isLocked = false,
    VoidCallback? onTap,
    VoidCallback? onClear,
  }) {
    final hasValidTime = time.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF222C2E) : const Color(0xFFF7F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF2D6A4F)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isLocked
                    ? (isDark ? Colors.white10 : Colors.grey[200])
                    : (hasValidTime
                        ? (isDark ? const Color(0xFF1B4332).withValues(alpha: 0.3) : const Color(0xFFE8F5E9))
                        : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100])),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isLocked
                      ? Colors.transparent
                      : (hasValidTime
                          ? const Color(0xFF2D6A4F).withValues(alpha: 0.3)
                          : (isDark ? Colors.white12 : Colors.black12)),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hasValidTime ? time : '--:--',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isLocked
                          ? (isDark ? Colors.white70 : Colors.black87)
                          : (hasValidTime
                              ? (isDark ? const Color(0xFF81C784) : const Color(0xFF1B4332))
                              : (isDark ? Colors.white38 : Colors.black45)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isLocked ? Icons.lock_outline_rounded : Icons.edit_rounded,
                    size: 14,
                    color: isLocked
                        ? (isDark ? Colors.white60 : Colors.black54)
                        : (isDark ? const Color(0xFF81C784) : const Color(0xFF1B4332)),
                  ),
                ],
              ),
            ),
            if (!isLocked && onClear != null && hasValidTime) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: onClear,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.red.withValues(alpha: 0.25) : const Color(0xFFFFEBEE),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: isDark ? Colors.redAccent[100] : const Color(0xFFC62828),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
