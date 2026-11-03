import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/developer_gist_service.dart';
import '../utils/hijri_converter.dart';

/// Screen for managing GitHub Gist: Hijri Calendar & Popup Announcements
/// Protected under Developer / Master Admin access.
class DeveloperGistManagerScreen extends StatefulWidget {
  final int initialTabIndex;
  const DeveloperGistManagerScreen({super.key, this.initialTabIndex = 0});

  @override
  State<DeveloperGistManagerScreen> createState() => _DeveloperGistManagerScreenState();
}

class _DeveloperGistManagerScreenState extends State<DeveloperGistManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _token;

  // Hijri Calendar state
  Map<String, String> _hijriMonthStarts = {};

  // Announcements state
  Map<String, dynamic> _rawAnnouncementData = {};
  List<Map<String, dynamic>> _announcementsList = [];

  static const List<String> _islamicMonthNames = [
    '',
    'Muharram',
    'Safar',
    'Rabi al-Awwal',
    'Rabi al-Thani',
    'Jumada al-Awwal',
    'Jumada al-Thani',
    'Rajab',
    "Sha'ban",
    'Ramadan',
    'Shawwal',
    "Dhu al-Qi'dah",
    'Dhu al-Hijjah',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    _token = await DeveloperGistService.instance.getGistToken();

    try {
      final hijri = await DeveloperGistService.instance.fetchHijriCalendar();
      final ann = await DeveloperGistService.instance.fetchAnnouncements();

      _hijriMonthStarts = Map<String, String>.from(hijri);
      _rawAnnouncementData = Map<String, dynamic>.from(ann);

      // Extract announcements array or top-level item
      final list = <Map<String, dynamic>>[];
      if (ann['announcements'] is List) {
        for (final item in ann['announcements'] as List) {
          if (item is Map) list.add(Map<String, dynamic>.from(item));
        }
      } else if (ann.isNotEmpty && ann['id'] != null) {
        list.add(Map<String, dynamic>.from(ann));
      }
      _announcementsList = list;
    } catch (e) {
      debugPrint('Error loading Gist data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showTokenDialog() {
    final controller = TextEditingController(text: _token ?? '');
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
              Text('GitHub Access Token', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter a GitHub Personal Access Token with "gist" permission to allow direct updates from your phone.',
                style: TextStyle(fontSize: 12.5, height: 1.4, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                obscureText: obscure,
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: 'ghp_...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                setState(() => _token = val.isEmpty ? null : val);
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

  Future<void> _saveHijriCalendar() async {
    if (_token == null || _token!.isEmpty) {
      _showTokenDialog();
      return;
    }

    setState(() => _isSaving = true);
    final sortedKeys = _hijriMonthStarts.keys.toList()..sort();
    final sortedMap = <String, String>{};
    for (final k in sortedKeys) {
      sortedMap[k] = _hijriMonthStarts[k]!;
    }

    final content = const JsonEncoder.withIndent('  ').convert({
      'month_starts': sortedMap,
    });

    final res = await DeveloperGistService.instance.updateGistFiles(
      hijriCalendarContent: content,
    );

    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: res.success ? const Color(0xFF1B4332) : const Color(0xFFB00020),
          duration: const Duration(seconds: 3),
        ),
      );
      if (res.success) {
        // Also update local memory so app reflects new month dates immediately
        HijriConverter.applyMonthStarts(sortedMap);
      }
    }
  }

  Future<void> _saveAnnouncements() async {
    if (_token == null || _token!.isEmpty) {
      _showTokenDialog();
      return;
    }

    setState(() => _isSaving = true);

    // Keep top-level structure intact while updating the announcements array
    final payload = Map<String, dynamic>.from(_rawAnnouncementData);
    payload['announcements'] = _announcementsList;

    // If there's at least one active announcement, synchronize top-level fields for backwards compatibility
    final firstActive = _announcementsList.firstWhere(
      (a) => a['enabled'] == true,
      orElse: () => _announcementsList.isNotEmpty ? _announcementsList.first : {},
    );
    if (firstActive.isNotEmpty) {
      payload['enabled'] = firstActive['enabled'] ?? false;
      payload['id'] = firstActive['id'] ?? 'popup-${DateTime.now().toIso8601String().substring(0, 10)}';
      payload['title'] = firstActive['title'] ?? '';
      payload['description'] = firstActive['description'] ?? '';
      payload['imageUrl'] = firstActive['imageUrl'] ?? '';
      payload['actionUrl'] = firstActive['actionUrl'] ?? '';
    }

    final content = const JsonEncoder.withIndent('  ').convert(payload);

    final res = await DeveloperGistService.instance.updateGistFiles(
      announcementContent: content,
    );

    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: res.success ? const Color(0xFF1B4332) : const Color(0xFFB00020),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF12181A) : const Color(0xFFF4F6F6),
      appBar: AppBar(
        title: const Text(
          'Gist Cloud Manager',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: isDark ? const Color(0xFF1A2426) : const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload from Gist',
            onPressed: _isLoading ? null : _loadInitialData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFD54F),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          tabs: const [
            Tab(icon: Icon(Icons.nightlight_round, size: 18), text: 'Hijri Months'),
            Tab(icon: Icon(Icons.campaign_rounded, size: 18), text: 'Popup Announcements'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Token status header
                _buildTokenBar(isDark),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildHijriTab(isDark),
                      _buildAnnouncementsTab(isDark),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTokenBar(bool isDark) {
    final hasToken = _token != null && _token!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? const Color(0xFF1E282A) : Colors.white,
      child: Row(
        children: [
          Icon(
            hasToken ? Icons.check_circle_rounded : Icons.warning_rounded,
            size: 16,
            color: hasToken ? const Color(0xFF2E7D32) : const Color(0xFFD97706),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasToken ? 'GitHub Token Active' : 'GitHub Token Required for publishing',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.settings, size: 14),
            label: Text(hasToken ? 'Edit Token' : 'Set Token', style: const TextStyle(fontSize: 12)),
            onPressed: _showTokenDialog,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 1: HIJRI CALENDAR
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHijriTab(bool isDark) {
    final entries = _hijriMonthStarts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (ctx, i) {
              final item = entries[i];
              final parts = item.key.split('-');
              final year = parts[0];
              final monthIdx = int.tryParse(parts.length > 1 ? parts[1] : '1') ?? 1;
              final monthName = (monthIdx >= 1 && monthIdx <= 12)
                  ? _islamicMonthNames[monthIdx]
                  : 'Month $monthIdx';

              DateTime? parsedDate;
              try {
                parsedDate = DateTime.parse(item.value);
              } catch (_) {}

              final dateStr = parsedDate != null
                  ? '${parsedDate.day.toString().padLeft(2, '0')}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.year}'
                  : item.value;

              return Card(
                elevation: 0,
                color: isDark ? const Color(0xFF1E282A) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
                ),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B4332).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.nightlight_round, size: 18, color: Color(0xFF1B4332)),
                  ),
                  title: Text(
                    '$monthName $year',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    '1st of month: $dateStr',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  trailing: TextButton.icon(
                    icon: const Icon(Icons.calendar_today_rounded, size: 14),
                    label: const Text('Change', style: TextStyle(fontSize: 12)),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: parsedDate ?? DateTime.now(),
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                        helpText: 'Select 1st of $monthName $year',
                      );
                      if (picked != null) {
                        final formatted =
                            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                        setState(() {
                          _hijriMonthStarts[item.key] = formatted;
                        });
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),

        // Bottom Save Button
        Container(
          padding: const EdgeInsets.all(16),
          color: isDark ? const Color(0xFF1E282A) : Colors.white,
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4332),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cloud_upload_rounded),
              label: Text(_isSaving ? 'Saving to GitHub...' : 'Save Hijri Dates to Gist'),
              onPressed: _isSaving ? null : _saveHijriCalendar,
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 2: POPUP ANNOUNCEMENTS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildAnnouncementsTab(bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text(
                'Announcements (${_announcementsList.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('New Popup', style: TextStyle(fontSize: 12)),
                onPressed: _addNewAnnouncement,
              ),
            ],
          ),
        ),
        Expanded(
          child: _announcementsList.isEmpty
              ? Center(
                  child: Text(
                    'No announcements configured.\nTap "New Popup" to add one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _announcementsList.length,
                  itemBuilder: (ctx, idx) => _buildAnnouncementCard(idx, isDark),
                ),
        ),

        // Bottom Save Button
        Container(
          padding: const EdgeInsets.all(16),
          color: isDark ? const Color(0xFF1E282A) : Colors.white,
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4332),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cloud_upload_rounded),
              label: Text(_isSaving ? 'Publishing to GitHub...' : 'Publish Announcements to Gist'),
              onPressed: _isSaving ? null : _saveAnnouncements,
            ),
          ),
        ),
      ],
    );
  }

  void _addNewAnnouncement() {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    setState(() {
      _announcementsList.insert(0, {
        'enabled': true,
        'id': 'popup-$todayStr-${DateTime.now().millisecondsSinceEpoch % 1000}',
        'cities': ['all'],
        'title': '',
        'description': '',
        'imageUrl': '',
        'actionUrl': '',
        'max_version': '',
        'target_version': '',
      });
    });
  }

  Widget _buildAnnouncementCard(int index, bool isDark) {
    final item = _announcementsList[index];
    final bool isEnabled = item['enabled'] as bool? ?? false;
    final String imageUrl = item['imageUrl'] as String? ?? '';
    final String citiesStr = (item['cities'] is List)
        ? (item['cities'] as List).join(', ')
        : (item['cities']?.toString() ?? 'all');
    final String maxVersion = item['max_version']?.toString() ?? '';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: isDark ? const Color(0xFF1E282A) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isEnabled
              ? const Color(0xFF2E7D32).withValues(alpha: 0.5)
              : (isDark ? Colors.white12 : Colors.black12),
          width: isEnabled ? 1.4 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Toggle and Delete
            Row(
              children: [
                Switch(
                  value: isEnabled,
                  activeColor: const Color(0xFF2E7D32),
                  activeTrackColor: const Color(0xFF2E7D32).withValues(alpha: 0.4),
                  onChanged: (val) {
                    setState(() => item['enabled'] = val);
                  },
                ),
                Text(
                  isEnabled ? 'ACTIVE POPUP' : 'DISABLED',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isEnabled ? const Color(0xFF2E7D32) : Colors.grey,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                  tooltip: 'Delete Announcement',
                  onPressed: () {
                    setState(() => _announcementsList.removeAt(index));
                  },
                ),
              ],
            ),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Image Preview (if URL provided)
            if (imageUrl.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (ctx, url) => Container(
                    height: 140,
                    color: isDark ? Colors.white10 : Colors.black12,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (ctx, url, err) => Container(
                    height: 140,
                    color: isDark ? Colors.white10 : Colors.black12,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image_rounded, color: Colors.grey, size: 30),
                        SizedBox(height: 4),
                        Text('Invalid image URL', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Image URL Field
            TextFormField(
              initialValue: imageUrl,
              decoration: const InputDecoration(
                labelText: 'Image URL (Direct link to JPG/PNG)',
                prefixIcon: Icon(Icons.image_outlined, size: 18),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => item['imageUrl'] = val.trim()),
            ),
            const SizedBox(height: 10),

            // Title Field
            TextFormField(
              initialValue: item['title']?.toString() ?? '',
              decoration: const InputDecoration(
                labelText: 'Title (Optional)',
                prefixIcon: Icon(Icons.title_rounded, size: 18),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => item['title'] = val.trim(),
            ),
            const SizedBox(height: 10),

            // Description Field
            TextFormField(
              initialValue: item['description']?.toString() ?? '',
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description / Message (Optional)',
                prefixIcon: Icon(Icons.description_outlined, size: 18),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => item['description'] = val.trim(),
            ),
            const SizedBox(height: 10),

            // Action URL Field
            TextFormField(
              initialValue: item['actionUrl']?.toString() ?? '',
              decoration: const InputDecoration(
                labelText: 'Button Action URL (Play Store, YouTube, WhatsApp)',
                prefixIcon: Icon(Icons.link_rounded, size: 18),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => item['actionUrl'] = val.trim(),
            ),
            const SizedBox(height: 12),

            // Target Cities Field
            TextFormField(
              initialValue: citiesStr,
              decoration: const InputDecoration(
                labelText: 'Target Cities ("all" or "sukkur, karachi")',
                prefixIcon: Icon(Icons.location_city_rounded, size: 18),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                item['cities'] = val.split(',').map((e) => e.trim().toLowerCase()).toList();
              },
            ),
            const SizedBox(height: 10),

            // Target Version & Max Version Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item['target_version']?.toString() ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Target Version (Only this, e.g. 1.4.1)',
                      prefixIcon: Icon(Icons.gps_fixed_rounded, size: 16),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => item['target_version'] = val.trim(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: maxVersion,
                    decoration: const InputDecoration(
                      labelText: 'Max Version (<= version, e.g. 1.4.6)',
                      prefixIcon: Icon(Icons.history_rounded, size: 16),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => item['max_version'] = val.trim(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
