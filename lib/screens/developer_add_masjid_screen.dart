import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../services/developer_gist_service.dart';
import '../services/jamaat_times_service.dart';
import '../utils/app_theme.dart';
import '../l10n/world_translations.dart';

/// Screen for adding a new Masjid dynamically across all 10 languages,
/// saving to GitHub Gist & Google Cloud Firestore directly from Developer Mode.
class DeveloperAddMasjidScreen extends StatefulWidget {
  final JamaatMasjidInfo? initialMasjid;
  const DeveloperAddMasjidScreen({super.key, this.initialMasjid});

  @override
  State<DeveloperAddMasjidScreen> createState() => _DeveloperAddMasjidScreenState();
}

class _DeveloperAddMasjidScreenState extends State<DeveloperAddMasjidScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Primary Name & Address Controllers ────────────────────────────────
  final _nameEnController = TextEditingController();
  final _nameUrController = TextEditingController();
  final _addressEnController = TextEditingController(text: 'Sukkur');
  final _addressUrController = TextEditingController(text: 'سکھر');

  // ── 10 Languages Controllers ──────────────────────────────────────────
  final Map<String, TextEditingController> _langNameControllers = {
    'sindhi': TextEditingController(),
    'arabic': TextEditingController(),
    'hindi': TextEditingController(),
    'bengali': TextEditingController(),
    'persian': TextEditingController(),
    'turkish': TextEditingController(),
    'french': TextEditingController(),
    'indonesian': TextEditingController(),
  };

  final Map<String, TextEditingController> _langAddressControllers = {
    'sindhi': TextEditingController(),
    'arabic': TextEditingController(),
    'hindi': TextEditingController(),
    'bengali': TextEditingController(),
    'persian': TextEditingController(),
    'turkish': TextEditingController(),
    'french': TextEditingController(),
    'indonesian': TextEditingController(),
  };

  // Track which language fields were manually edited by the user so
  // auto-populate / save never overwrites user's manual corrections
  final Set<String> _manuallyEditedNames = {};
  final Set<String> _manuallyEditedAddresses = {};

  // ── Metadata Controllers ──────────────────────────────────────────────
  final _idController = TextEditingController();
  final _pinController = TextEditingController();
  bool _idManuallyEdited = false;
  bool _isSaving = false;
  bool _isTranslatingNames = false;
  bool _isTranslatingAddresses = false;
  bool _is10LanguagesExpanded = false;
  bool _is10AddressesExpanded = false;

  // ── Prayer Timings ────────────────────────────────────────────────────
  String _fajr = '06:00 AM';
  String _zuhar = '01:30 PM';
  String _asar = '04:45 PM';
  final String _maghrib = 'Sunset';
  String _isha = '08:00 PM';
  String _jummah = '01:45 PM';

  // ── Prayer Notes Controllers ──────────────────────────────────────────
  final _fajrNoteController = TextEditingController();
  final _zuharNoteController = TextEditingController();
  final _asarNoteController = TextEditingController();
  final _maghribNoteController = TextEditingController();
  final _ishaNoteController = TextEditingController();
  final _jummahNoteController = TextEditingController(text: '');

  @override
  void initState() {
    super.initState();
    if (widget.initialMasjid != null) {
      final m = widget.initialMasjid!;
      _idController.text = m.id;
      _idManuallyEdited = true;

      _nameEnController.text = m.localizedNames['english'] ?? m.nameKey;
      _nameUrController.text = m.localizedNames['urdu'] ?? '';
      _addressEnController.text = m.localizedAddresses['english'] ?? m.addressKey;
      _addressUrController.text = m.localizedAddresses['urdu'] ?? '';

      m.localizedNames.forEach((lang, text) {
        if (_langNameControllers.containsKey(lang)) {
          _langNameControllers[lang]!.text = text;
        }
      });

      m.localizedAddresses.forEach((lang, text) {
        if (_langAddressControllers.containsKey(lang)) {
          _langAddressControllers[lang]!.text = text;
        }
      });

      _is10LanguagesExpanded = m.localizedNames.isNotEmpty;
      _is10AddressesExpanded = m.localizedAddresses.isNotEmpty;

      final currentPin = m.pin ?? JamaatTimesService.instance.getMasjidPin(m.id);
      _pinController.text = currentPin ?? '';

      final timing = JamaatTimesService.instance.getTimingFor(m);
      _fajr = timing.fajr;
      _zuhar = timing.zuhar;
      _asar = timing.asar;
      _isha = timing.isha;
      _jummah = timing.jummah;
      _fajrNoteController.text = timing.fajrNoteUr;
      _zuharNoteController.text = timing.zuharNoteUr;
      _asarNoteController.text = timing.asarNoteUr;
      _maghribNoteController.text = timing.maghribNoteUr;
      _ishaNoteController.text = timing.ishaNoteUr;
      _jummahNoteController.text = timing.jummahNoteUr;
    } else {
      _generateRandomPin();
      _nameEnController.addListener(_onEnglishNameChanged);
      _addressEnController.addListener(_onAddressChanged);
    }
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameUrController.dispose();
    _addressEnController.dispose();
    _addressUrController.dispose();
    _idController.dispose();
    _pinController.dispose();
    for (final c in _langNameControllers.values) {
      c.dispose();
    }
    for (final c in _langAddressControllers.values) {
      c.dispose();
    }
    _fajrNoteController.dispose();
    _zuharNoteController.dispose();
    _asarNoteController.dispose();
    _maghribNoteController.dispose();
    _ishaNoteController.dispose();
    _jummahNoteController.dispose();
    super.dispose();
  }

  void _onEnglishNameChanged() {
    if (!_idManuallyEdited) {
      final nameSlug = _slugify(_nameEnController.text);
      final addrSlug = _slugify(_addressEnController.text);
      if (nameSlug.isNotEmpty) {
        _idController.text = addrSlug.isNotEmpty && addrSlug != 'sukkur'
            ? '${nameSlug}_$addrSlug'
            : nameSlug;
      }
    }
  }

  void _onAddressChanged() {
    if (!_idManuallyEdited && _nameEnController.text.isNotEmpty) {
      _onEnglishNameChanged();
    }
  }

  String _slugify(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
  }

  void _generateRandomPin() {
    final rand = Random();
    final pin = (1000 + rand.nextInt(9000)).toString();
    setState(() {
      _pinController.text = pin;
    });
  }

  static const Map<String, String> _langIsoCodes = {
    'english': 'en',
    'urdu': 'ur',
    'sindhi': 'sd',
    'arabic': 'ar',
    'persian': 'fa',
    'hindi': 'hi',
    'bengali': 'bn',
    'turkish': 'tr',
    'french': 'fr',
    'indonesian': 'id',
  };

  /// Live Google Translate helper with offline fallback
  Future<String> _translateText(
    String sourceText,
    String targetLangKey, {
    required String fallbackRtl,
    required String fallbackLtr,
    bool isAddress = false,
  }) async {
    final clean = sourceText.trim();
    if (clean.isEmpty) return '';

    final tl = _langIsoCodes[targetLangKey] ?? 'en';
    try {
      final url = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=$tl&dt=t&q=${Uri.encodeComponent(clean)}',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List && decoded.isNotEmpty && decoded[0] is List) {
          final buffer = StringBuffer();
          for (final seg in decoded[0] as List) {
            if (seg is List && seg.isNotEmpty && seg[0] != null) {
              buffer.write(seg[0].toString());
            }
          }
          String translated = buffer.toString().trim();
          if (translated.isNotEmpty) {
            if (targetLangKey == 'sindhi') {
              translated = translated.replaceAll('سکھر', 'سکر').replaceAll('مسجد', 'مسجد');
            }
            return translated;
          }
        }
      }
    } catch (_) {
      // Fallback below if offline
    }

    // Offline smart fallback
    switch (targetLangKey) {
      case 'sindhi':
        return fallbackRtl.replaceAll('سکھر', 'سکر').replaceAll('روڈ', 'روڊ');
      case 'arabic':
      case 'persian':
        return fallbackRtl;
      case 'turkish':
        return isAddress
            ? fallbackLtr
            : fallbackLtr.replaceAll(RegExp(r'\bMasjid\b', caseSensitive: false), 'Camii');
      case 'french':
        return isAddress
            ? fallbackLtr
            : fallbackLtr.replaceAll(RegExp(r'\bMasjid\b', caseSensitive: false), 'Mosquée');
      case 'hindi':
        return fallbackLtr
            .replaceAll(RegExp(r'\bJamia\b', caseSensitive: false), 'जामिया')
            .replaceAll(RegExp(r'\bMasjid\b', caseSensitive: false), 'मस्जिद')
            .replaceAll(RegExp(r'\bRoad\b', caseSensitive: false), 'रोड')
            .replaceAll(RegExp(r'\bBazar\b', caseSensitive: false), 'बाज़ार')
            .replaceAll(RegExp(r'\bColony\b', caseSensitive: false), 'कॉलोनी')
            .replaceAll(RegExp(r'\bSukkur\b', caseSensitive: false), 'सक्खर');
      case 'bengali':
        return fallbackLtr
            .replaceAll(RegExp(r'\bJamia\b', caseSensitive: false), 'জামিয়া')
            .replaceAll(RegExp(r'\bMasjid\b', caseSensitive: false), 'মসজিদ')
            .replaceAll(RegExp(r'\bRoad\b', caseSensitive: false), 'রোড')
            .replaceAll(RegExp(r'\bBazar\b', caseSensitive: false), 'বাজার')
            .replaceAll(RegExp(r'\bColony\b', caseSensitive: false), 'কলোনি')
            .replaceAll(RegExp(r'\bSukkur\b', caseSensitive: false), 'সুক্কুর');
      case 'indonesian':
      default:
        return fallbackLtr;
    }
  }

  Future<void> _autoPopulateNames({bool silent = false}) async {
    String enName = _nameEnController.text.trim();
    String urName = _nameUrController.text.trim();

    if (enName.isEmpty && urName.isEmpty) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter English or Urdu Mosque Name first!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() => _isTranslatingNames = true);
    }

    try {
      // Auto-fill English or Urdu if one of them was left blank
      if (urName.isEmpty && enName.isNotEmpty) {
        urName = await _translateText(
          enName,
          'urdu',
          fallbackRtl: enName,
          fallbackLtr: enName,
        );
        if (mounted && _nameUrController.text.trim().isEmpty) {
          _nameUrController.text = urName;
        }
      } else if (enName.isEmpty && urName.isNotEmpty) {
        enName = await _translateText(
          urName,
          'english',
          fallbackRtl: urName,
          fallbackLtr: urName,
        );
        if (mounted && _nameEnController.text.trim().isEmpty) {
          _nameEnController.text = enName;
        }
      }

      final primaryRtl = urName.isNotEmpty ? urName : enName;
      final primaryLtr = enName.isNotEmpty ? enName : urName;

      final futures = <String, Future<String>>{};
      for (final langKey in _langNameControllers.keys) {
        if (silent && _langNameControllers[langKey]!.text.trim().isNotEmpty) {
          continue;
        }
        if (!silent &&
            _manuallyEditedNames.contains(langKey) &&
            _langNameControllers[langKey]!.text.trim().isNotEmpty) {
          continue;
        }
        final src = (langKey == 'sindhi' || langKey == 'arabic' || langKey == 'persian')
            ? primaryRtl
            : primaryLtr;
        futures[langKey] = _translateText(
          src,
          langKey,
          fallbackRtl: primaryRtl,
          fallbackLtr: primaryLtr,
        );
      }

      final entries = futures.entries.toList();
      final results = await Future.wait(entries.map((e) => e.value));

      if (mounted) {
        setState(() {
          for (var i = 0; i < entries.length; i++) {
            final langKey = entries[i].key;
            final translated = results[i];
            if (translated.isNotEmpty) {
              _langNameControllers[langKey]!.text = translated;
            }
          }
          if (!silent) {
            _is10LanguagesExpanded = true;
          }
        });
      }

      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mosque Name auto-translated into all 10 languages! You can review or edit below.'),
            backgroundColor: Color(0xFF1B4332),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTranslatingNames = false);
      }
    }
  }

  Future<void> _autoPopulateAddresses({bool silent = false}) async {
    String enAddr = _addressEnController.text.trim();
    String urAddr = _addressUrController.text.trim();

    if (enAddr.isEmpty && urAddr.isEmpty) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter English or Urdu Address first!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() => _isTranslatingAddresses = true);
    }

    try {
      // Auto-fill English or Urdu address if one was left blank or still default 'Sukkur'/'سکھر'
      if ((urAddr.isEmpty || (urAddr == 'سکھر' && enAddr.toLowerCase() != 'sukkur')) &&
          enAddr.isNotEmpty) {
        urAddr = await _translateText(
          enAddr,
          'urdu',
          fallbackRtl: enAddr,
          fallbackLtr: enAddr,
          isAddress: true,
        );
        if (mounted) {
          _addressUrController.text = urAddr;
        }
      } else if ((enAddr.isEmpty || (enAddr.toLowerCase() == 'sukkur' && urAddr != 'سکھر')) &&
          urAddr.isNotEmpty) {
        enAddr = await _translateText(
          urAddr,
          'english',
          fallbackRtl: urAddr,
          fallbackLtr: urAddr,
          isAddress: true,
        );
        if (mounted) {
          _addressEnController.text = enAddr;
        }
      }

      final primaryRtl = urAddr.isNotEmpty ? urAddr : enAddr;
      final primaryLtr = enAddr.isNotEmpty ? enAddr : urAddr;

      final futures = <String, Future<String>>{};
      for (final langKey in _langAddressControllers.keys) {
        if (silent && _langAddressControllers[langKey]!.text.trim().isNotEmpty) {
          continue;
        }
        if (!silent &&
            _manuallyEditedAddresses.contains(langKey) &&
            _langAddressControllers[langKey]!.text.trim().isNotEmpty) {
          continue;
        }
        final src = (langKey == 'sindhi' || langKey == 'arabic' || langKey == 'persian')
            ? primaryRtl
            : primaryLtr;
        futures[langKey] = _translateText(
          src,
          langKey,
          fallbackRtl: primaryRtl,
          fallbackLtr: primaryLtr,
          isAddress: true,
        );
      }

      final entries = futures.entries.toList();
      final results = await Future.wait(entries.map((e) => e.value));

      if (mounted) {
        setState(() {
          for (var i = 0; i < entries.length; i++) {
            final langKey = entries[i].key;
            final translated = results[i];
            if (translated.isNotEmpty) {
              _langAddressControllers[langKey]!.text = translated;
            }
          }
          if (!silent) {
            _is10AddressesExpanded = true;
          }
        });
      }

      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mosque Address auto-translated into all 10 languages! You can review or edit below.'),
            backgroundColor: Color(0xFF1B4332),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTranslatingAddresses = false);
      }
    }
  }

  Future<void> _pickTime(String current, ValueChanged<String> onSelected, {TimeOfDay? fallback}) async {
    final initial = _parseTimeOfDay(current, fallback: fallback ?? const TimeOfDay(hour: 12, minute: 0));
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      onSelected('${hour.toString().padLeft(2, '0')}:$minute $period');
    }
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

  Future<void> _saveAndPublish() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final id = _idController.text.trim();
    final nameEn = _nameEnController.text.trim();
    final nameUr = _nameUrController.text.trim();
    final pin = _pinController.text.trim();

    if (id.isEmpty || (nameEn.isEmpty && nameUr.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least Name and unique Masjid ID.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Check token
    final token = await DeveloperGistService.instance.getGistToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      _showTokenPrompt();
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Ensure any remaining blank language fields are auto-translated before saving
      await Future.wait([
        _autoPopulateNames(silent: true),
        _autoPopulateAddresses(silent: true),
      ]);

      final finalNameEn = _nameEnController.text.trim();
      final finalNameUr = _nameUrController.text.trim();
      final finalAddrEn = _addressEnController.text.trim();
      final finalAddrUr = _addressUrController.text.trim();

      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final now = DateTime.now();
      final todayStr = '${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]} ${now.year}';

      // ── Assemble 10 Languages Dictionaries ──────────────────────────
      final Map<String, String> namesMap = {
        'english': finalNameEn.isNotEmpty ? finalNameEn : finalNameUr,
        'urdu': finalNameUr.isNotEmpty ? finalNameUr : finalNameEn,
      };
      _langNameControllers.forEach((lang, c) {
        final val = c.text.trim();
        if (val.isNotEmpty) namesMap[lang] = val;
      });

      final Map<String, String> addressesMap = {
        'english': finalAddrEn.isNotEmpty ? finalAddrEn : 'Sukkur',
        'urdu': finalAddrUr.isNotEmpty ? finalAddrUr : 'سکھر',
      };
      _langAddressControllers.forEach((lang, c) {
        final val = c.text.trim();
        if (val.isNotEmpty) addressesMap[lang] = val;
      });

      // ── Build Timing Object ────────────────────────────────────────
      final timing = JamaatTiming(
        fajr: _fajr,
        fajrUpdated: todayStr,
        fajrNoteUr: _fajrNoteController.text.trim(),
        zuhar: _zuhar,
        zuharUpdated: todayStr,
        zuharNoteUr: _zuharNoteController.text.trim(),
        asar: _asar,
        asarUpdated: todayStr,
        asarNoteUr: _asarNoteController.text.trim(),
        maghrib: 'Sunset',
        maghribNoteUr: _maghribNoteController.text.trim(),
        isha: _isha,
        ishaUpdated: todayStr,
        ishaNoteUr: _ishaNoteController.text.trim(),
        jummah: _jummah,
        jummahUpdated: todayStr,
        jummahNoteUr: _jummahNoteController.text.trim(),
      );

      // ── Gist Payload Map ───────────────────────────────────────────
      final bool isHidden = widget.initialMasjid?.isHidden ?? false;
      final Map<String, dynamic> masjidGistMap = {
        'id': id,
        'pin': pin,
        'name': finalNameEn.isNotEmpty ? finalNameEn : finalNameUr,
        'address': finalAddrEn.isNotEmpty ? finalAddrEn : finalAddrUr,
        'hidden': isHidden,
        'names': namesMap,
        'addresses': addressesMap,
        ...timing.toJson(),
      };

      // 1. Publish directly to GitHub Gist
      final gistResult = await DeveloperGistService.instance.saveMasjidToGist(masjidGistMap);

      if (!gistResult.success) {
        if (mounted) {
          setState(() => _isSaving = false);
          _showErrorDialog(gistResult.message);
        }
        return;
      }

      // 2. Register runtime dynamic masjid in app & sync to Firestore
      final newMasjidInfo = JamaatMasjidInfo(
        id: id,
        nameKey: finalNameEn.isNotEmpty ? finalNameEn : finalNameUr,
        addressKey: finalAddrEn.isNotEmpty ? finalAddrEn : 'Sukkur',
        defaultTimings: timing,
        isHidden: isHidden,
        localizedNames: namesMap,
        localizedAddresses: addressesMap,
        pin: pin,
      );

      JamaatTimesService.instance.registerDynamicMasjid(newMasjidInfo);

      if (mounted) {
        setState(() => _isSaving = false);
        final displayName = namesMap['english'] ?? finalNameEn;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1B4332),
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.initialMasjid != null
                        ? '$displayName updated successfully on Gist & Firestore!'
                        : '$displayName successfully published to Gist & Firestore!',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showErrorDialog('Failed to save masjid: $e');
      }
    }
  }

  void _showTokenPrompt() {
    final tokenController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('GitHub Token Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A GitHub Personal Access Token with "gist" permission is required to save changes to the cloud.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tokenController,
              decoration: const InputDecoration(
                labelText: 'Personal Access Token (ghp_...)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B4332)),
            onPressed: () async {
              final t = tokenController.text.trim();
              if (t.isNotEmpty) {
                await DeveloperGistService.instance.saveGistToken(t);
                if (ctx.mounted) Navigator.pop(ctx);
                _saveAndPublish();
              }
            },
            child: const Text('Save Token & Continue', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publish Error'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _t(SettingsProvider settings, String en, [String? ur, String? sd, String? ar]) {
    final lang = settings.language;
    final map = worldTranslations[lang];
    if (map != null && map.containsKey(en)) {
      return map[en]!;
    }
    return settings.translate(en, ur ?? en, sd ?? ur ?? en, ar);
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = settings.language;
    final isRtl = settings.isRtl;

    final isEditMode = widget.initialMasjid != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditMode
              ? _t(settings, 'Edit Masjid Details', 'مسجد کی معلومات میں ترمیم', 'مسجد جي معلومات ۾ ترميم', 'تعديل بيانات المسجد')
              : _t(settings, 'Add New Masjid', 'نئی مسجد شامل کریں', 'نئين مسجد شامل ڪريو', 'إضافة مسجد جديد'),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: AppTheme.getFontForLanguage(context, lang),
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1A2426) : const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // ── Header Card ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E282A), const Color(0xFF151C1E)]
                        : [const Color(0xFF1B4332), const Color(0xFF2D6A4F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isEditMode ? Icons.edit_note_rounded : Icons.add_business_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditMode
                                ? _t(settings, 'Edit Mosque Info (10 Languages)', 'مسجد کا نام اور پتہ اپڈیٹ کریں (10 زبانیں)', 'مسجد جو نالو ۽ پتو اپڊيٽ ڪريو (۱۰ ٻوليون)', 'تحديث بيانات المسجد (١٠ لغات)')
                                : _t(settings, 'Register Masjid Across 10 Languages', 'تمام 10 زبانوں کے ساتھ نئی مسجد شامل کریں', 'سڀ ۱۰ ٻولين سان نئين مسجد شامل ڪريو', 'تسجيل مسجد جديد بكل اللغات العشر'),
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: AppTheme.getFontForLanguage(context, lang),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isEditMode
                                ? _t(settings, 'Updates name, translations & address on Gist & Firestore', 'گٹ ہب جسٹ اور فائر اسٹور پر نام اور پتے کی معلومات اپڈیٹ کریں', 'گٽ هب جسٽ ۽ فائر اسٽور تي نالو ۽ پتو اپڊيٽ ڪريو', 'تحديث الاسم والعنوان على السحابة')
                                : _t(settings, 'Saves to GitHub Gist & Google Cloud Firestore', 'گٹ ہب جسٹ اور گوگل فائر اسٹور پر لائیو محفوظ ہوتا ہے', 'گٽ هب جسٽ ۽ گوگل فائر اسٽور تي لائيو محفوظ ٿيندو', 'يتم الحفظ في السحابة لجميع المستخدمين فوراً'),
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── Step 1: Mosque Names ──────────────────────────────
              _buildSectionHeader(
                context,
                title: _t(settings, 'Mosque Names', 'مسجد کا نام', 'مسجد جو نالو', 'اسم المسجد'),
                icon: Icons.title_rounded,
                isDark: isDark,
              ),
              const SizedBox(height: 10),

              // English Name
              TextFormField(
                controller: _nameEnController,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: 'English Name *',
                  hintText: 'e.g. Jamia Masjid Al-Farooq',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.language_rounded),
                ),
                validator: (val) {
                  if ((val == null || val.trim().isEmpty) && _nameUrController.text.trim().isEmpty) {
                    return 'Please enter English or Urdu name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Urdu Name
              TextFormField(
                controller: _nameUrController,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  labelText: 'اردو نام * (Urdu Name)',
                  hintText: 'مثلاً: جامع مسجد الفاروق',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                ),
                validator: (val) {
                  if ((val == null || val.trim().isEmpty) && _nameEnController.text.trim().isEmpty) {
                    return 'براہ کرم اردو یا انگلش نام درج کریں';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Auto-Populate Button (Names)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isTranslatingNames
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF2E7D32),
                        ),
                      )
                    : const Icon(Icons.auto_awesome_rounded, color: Color(0xFF2E7D32)),
                label: Text(
                  _isTranslatingNames
                      ? _t(settings, 'Auto-Translating Name...', 'نام ترجمہ ہو رہا ہے...', 'نالو ترجمو ٿي رهيو آهي...', 'جاري ترجمة الاسم...')
                      : _t(settings, 'Auto-Populate Remaining 8 Languages', 'باقی تمام ۸ زبانوں کے نام خودکار تیار کریں', 'باقي سڀني ۸ ٻولين جا نالا خودڪار ٺاهيو', 'توليد تلقائي لبقية اللغات الثمانية'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.getFontForLanguage(context, lang),
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                onPressed: _isTranslatingNames ? null : () => _autoPopulateNames(),
              ),

              const SizedBox(height: 14),

              // Expandable 10 Languages Accordion (Names)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E282A) : const Color(0xFFF7F9FA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                ),
                child: ExpansionTile(
                  key: ValueKey('names_expansion_$_is10LanguagesExpanded'),
                  initiallyExpanded: _is10LanguagesExpanded,
                  onExpansionChanged: (exp) => setState(() => _is10LanguagesExpanded = exp),
                  leading: const Icon(Icons.translate_rounded, color: Color(0xFF1B4332)),
                  title: Text(
                    _t(settings, 'View / Edit All 10 Languages', 'تمام 10 زبانیں دیکھیں اور تبدیل کریں', 'سڀ ۱۰ ٻوليون ڏسو ۽ تبديل ڪريو', 'عرض وتعديل كل اللغات العشر'),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTheme.getFontForLanguage(context, lang),
                    ),
                  ),
                  subtitle: Text(
                    'Sindhi, Arabic, Persian, Turkish, French, Hindi, Bengali, Indonesian',
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Column(
                        children: [
                          _buildLangRow('سنڌي (Sindhi)', _langNameControllers['sindhi']!, TextDirection.rtl, onManualChanged: () => _manuallyEditedNames.add('sindhi')),
                          _buildLangRow('العربية (Arabic)', _langNameControllers['arabic']!, TextDirection.rtl, onManualChanged: () => _manuallyEditedNames.add('arabic')),
                          _buildLangRow('فارسی (Persian)', _langNameControllers['persian']!, TextDirection.rtl, onManualChanged: () => _manuallyEditedNames.add('persian')),
                          _buildLangRow('हिन्दी (Hindi)', _langNameControllers['hindi']!, TextDirection.ltr, onManualChanged: () => _manuallyEditedNames.add('hindi')),
                          _buildLangRow('বাংলা (Bengali)', _langNameControllers['bengali']!, TextDirection.ltr, onManualChanged: () => _manuallyEditedNames.add('bengali')),
                          _buildLangRow('Türkçe (Turkish)', _langNameControllers['turkish']!, TextDirection.ltr, onManualChanged: () => _manuallyEditedNames.add('turkish')),
                          _buildLangRow('Français (French)', _langNameControllers['french']!, TextDirection.ltr, onManualChanged: () => _manuallyEditedNames.add('french')),
                          _buildLangRow('Bahasa Indonesia', _langNameControllers['indonesian']!, TextDirection.ltr, onManualChanged: () => _manuallyEditedNames.add('indonesian')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── Step 2: Mosque Address ────────────────────────────
              _buildSectionHeader(
                context,
                title: _t(settings, 'Mosque Address', 'مسجد کا پتہ / علاقہ', 'مسجد جو پتو / علائقو', 'عنوان المسجد / المنطقة'),
                icon: Icons.location_on_rounded,
                isDark: isDark,
              ),
              const SizedBox(height: 10),

              // English Address
              TextFormField(
                controller: _addressEnController,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: 'English Address',
                  hintText: 'e.g. Military Road, Sukkur',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.place_rounded),
                ),
              ),
              const SizedBox(height: 10),

              // Urdu Address
              TextFormField(
                controller: _addressUrController,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  labelText: 'اردو پتہ (Urdu Address)',
                  hintText: 'مثلاً: ملٹری روڈ، سکھر',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.pin_drop_rounded),
                ),
              ),
              const SizedBox(height: 12),

              // Auto-Populate Button (Addresses)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isTranslatingAddresses
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF2E7D32),
                        ),
                      )
                    : const Icon(Icons.auto_awesome_rounded, color: Color(0xFF2E7D32)),
                label: Text(
                  _isTranslatingAddresses
                      ? _t(settings, 'Auto-Translating Address...', 'پتہ ترجمہ ہو رہا ہے...', 'پتو ترجمو ٿي رهيو آهي...', 'جاري ترجمة العنوان...')
                      : _t(settings, 'Auto-Populate Remaining 8 Languages', 'باقی تمام ۸ زبانوں کا پتہ خودکار تیار کریں', 'باقي سڀني ۸ ٻولين جو پتو خودڪار ٺاهيو', 'توليد تلقائي لبقية اللغات الثمانية'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.getFontForLanguage(context, lang),
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                onPressed: _isTranslatingAddresses ? null : () => _autoPopulateAddresses(),
              ),

              const SizedBox(height: 14),

              // Expandable 10 Languages Accordion (Addresses)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E282A) : const Color(0xFFF7F9FA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                ),
                child: ExpansionTile(
                  key: ValueKey('addresses_expansion_$_is10AddressesExpanded'),
                  initiallyExpanded: _is10AddressesExpanded,
                  onExpansionChanged: (exp) => setState(() => _is10AddressesExpanded = exp),
                  leading: const Icon(Icons.translate_rounded, color: Color(0xFF1B4332)),
                  title: Text(
                    _t(settings, 'View / Edit All 10 Languages', 'تمام 10 زبانیں دیکھیں اور تبدیل کریں', 'سڀ ۱۰ ٻوليون ڏسو ۽ تبديل ڪريو', 'عرض وتعديل كل اللغات العشر'),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTheme.getFontForLanguage(context, lang),
                    ),
                  ),
                  subtitle: Text(
                    'Sindhi, Arabic, Persian, Turkish, French, Hindi, Bengali, Indonesian',
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Column(
                        children: [
                          _buildLangRow('سنڌي (Sindhi)', _langAddressControllers['sindhi']!, TextDirection.rtl, onManualChanged: () => _manuallyEditedAddresses.add('sindhi')),
                          _buildLangRow('العربية (Arabic)', _langAddressControllers['arabic']!, TextDirection.rtl, onManualChanged: () => _manuallyEditedAddresses.add('arabic')),
                          _buildLangRow('فارسی (Persian)', _langAddressControllers['persian']!, TextDirection.rtl, onManualChanged: () => _manuallyEditedAddresses.add('persian')),
                          _buildLangRow('हिन्दी (Hindi)', _langAddressControllers['hindi']!, TextDirection.ltr, onManualChanged: () => _manuallyEditedAddresses.add('hindi')),
                          _buildLangRow('বাংলা (Bengali)', _langAddressControllers['bengali']!, TextDirection.ltr, onManualChanged: () => _manuallyEditedAddresses.add('bengali')),
                          _buildLangRow('Türkçe (Turkish)', _langAddressControllers['turkish']!, TextDirection.ltr, onManualChanged: () => _manuallyEditedAddresses.add('turkish')),
                          _buildLangRow('Français (French)', _langAddressControllers['french']!, TextDirection.ltr, onManualChanged: () => _manuallyEditedAddresses.add('french')),
                          _buildLangRow('Bahasa Indonesia', _langAddressControllers['indonesian']!, TextDirection.ltr, onManualChanged: () => _manuallyEditedAddresses.add('indonesian')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── Step 3: ID & Committee PIN ────────────────────────
              _buildSectionHeader(
                context,
                title: _t(settings, 'Masjid ID & Committee PIN', 'مسجد شناختی کوڈ اور کمیٹی پن', 'مسجد آءِ ڊي ۽ ڪميٽي پن', 'معرف المسجد والرقم السري'),
                icon: Icons.key_rounded,
                isDark: isDark,
              ),
              const SizedBox(height: 10),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _idController,
                      textDirection: TextDirection.ltr,
                      readOnly: isEditMode,
                      enabled: !isEditMode,
                      decoration: InputDecoration(
                        labelText: 'Unique ID *',
                        hintText: 'masjid_slug',
                        helperText: isEditMode ? 'Fixed ID (Permanent)' : 'Auto-generated or custom slug',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: Icon(isEditMode ? Icons.lock_outline_rounded : Icons.tag_rounded),
                      ),
                      onChanged: (_) => _idManuallyEdited = true,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'ID is required';
                        if (!RegExp(r'^[a-z0-9_]+$').hasMatch(val.trim())) {
                          return 'Only lowercase a-z, 0-9, and _';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _pinController,
                      textDirection: TextDirection.ltr,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Committee PIN *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.refresh_rounded),
                          tooltip: 'Generate Random PIN',
                          onPressed: _generateRandomPin,
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().length < 4) return 'Min 4 digits';
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ── Step 4: Prayer Timings & Notes ────────────────────
              _buildSectionHeader(
                context,
                title: _t(settings, 'Prayer Timings & Notes', 'اوقاتِ باجماعت اور نوٹس', 'باجماعت جا وقت ۽ نوٽ', 'مواقيت الصلاة والملاحظات'),
                icon: Icons.access_time_filled_rounded,
                isDark: isDark,
              ),
              const SizedBox(height: 10),

              _buildPrayerTimingCard(
                context,
                settings: settings,
                isDark: isDark,
                nameKey: 'Fajr',
                timeValue: _fajr,
                onPickTime: () => _pickTime(_fajr, (v) => setState(() => _fajr = v), fallback: const TimeOfDay(hour: 6, minute: 0)),
                noteController: _fajrNoteController,
                noteHint: 'e.g. 15 mins after Azan',
              ),
              const SizedBox(height: 8),

              _buildPrayerTimingCard(
                context,
                settings: settings,
                isDark: isDark,
                nameKey: 'Zuhar',
                timeValue: _zuhar,
                onPickTime: () => _pickTime(_zuhar, (v) => setState(() => _zuhar = v), fallback: const TimeOfDay(hour: 13, minute: 30)),
                noteController: _zuharNoteController,
                noteHint: 'e.g. Fixed time',
              ),
              const SizedBox(height: 8),

              _buildPrayerTimingCard(
                context,
                settings: settings,
                isDark: isDark,
                nameKey: 'Asar',
                timeValue: _asar,
                onPickTime: () => _pickTime(_asar, (v) => setState(() => _asar = v), fallback: const TimeOfDay(hour: 16, minute: 45)),
                noteController: _asarNoteController,
                noteHint: 'e.g. In Winter: 04:30 PM',
              ),
              const SizedBox(height: 8),

              _buildPrayerTimingCard(
                context,
                settings: settings,
                isDark: isDark,
                nameKey: 'Maghrib',
                timeValue: _maghrib,
                isLocked: true,
                onPickTime: () {},
                noteController: _maghribNoteController,
                noteHint: 'Fixed at Sunset according to Jantri',
              ),
              const SizedBox(height: 8),

              _buildPrayerTimingCard(
                context,
                settings: settings,
                isDark: isDark,
                nameKey: 'Isha',
                timeValue: _isha,
                onPickTime: () => _pickTime(_isha, (v) => setState(() => _isha = v), fallback: const TimeOfDay(hour: 20, minute: 0)),
                noteController: _ishaNoteController,
                noteHint: 'e.g. Taraweeh begins 08:30 PM',
              ),
              const SizedBox(height: 8),

              _buildPrayerTimingCard(
                context,
                settings: settings,
                isDark: isDark,
                nameKey: 'Jummah',
                timeValue: _jummah,
                onPickTime: () => _pickTime(_jummah, (v) => setState(() => _jummah = v), fallback: const TimeOfDay(hour: 13, minute: 45)),
                noteController: _jummahNoteController,
                noteHint: 'e.g. 1st: 01:30 PM, 2nd: 02:15 PM',
              ),

              const SizedBox(height: 24),

              // ── Submit Button ─────────────────────────────────────
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4332),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 3,
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(isEditMode ? Icons.save_rounded : Icons.cloud_upload_rounded, size: 24),
                  label: Text(
                    _isSaving
                        ? _t(settings, 'Saving Changes to Cloud...', 'کلاؤڈ پر محفوظ ہو رہا ہے...', 'ڪلائوڊ تي محفوظ ٿي رهيو آهي...', 'جاري حفظ التغييرات...')
                        : (isEditMode
                            ? _t(settings, 'Update Masjid Details & Sync', 'مسجد کی تفصیلات محفوظ کریں', 'مسجد جي تفصيل محفوظ ڪريو', 'حفظ بيانات المسجد ومزامنتها')
                            : _t(settings, 'Save & Publish Masjid to Cloud', 'نئی مسجد کلاؤڈ پر شائع اور محفوظ کریں', 'نئين مسجد ڪلائوڊ تي شايع ۽ محفوظ ڪريو', 'حفظ ونشر المسجد في السحابة')),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTheme.getFontForLanguage(context, lang),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveAndPublish,
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B4332)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFF81C784) : const Color(0xFF1B4332),
          ),
        ),
      ],
    );
  }

  Widget _buildLangRow(
    String label,
    TextEditingController controller,
    TextDirection dir, {
    VoidCallback? onManualChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: controller,
        textDirection: dir,
        onChanged: (_) => onManualChanged?.call(),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildPrayerTimingCard(
    BuildContext context, {
    required SettingsProvider settings,
    required bool isDark,
    required String nameKey,
    required String timeValue,
    required VoidCallback onPickTime,
    required TextEditingController noteController,
    required String noteHint,
    bool isLocked = false,
  }) {
    final lang = settings.language;
    String getDisplayName() {
      switch (nameKey) {
        case 'Fajr': return settings.translate('Fajr', 'فجر', 'فجر', 'الفجر');
        case 'Zuhar': return settings.translate('Zuhar', 'ظہر', 'ظهر', 'الظهر');
        case 'Asar': return settings.translate('Asar', 'عصر', 'عصر', 'العصر');
        case 'Maghrib': return settings.translate('Maghrib', 'مغرب', 'مغرب', 'المغرب');
        case 'Isha': return settings.translate('Isha', 'عشاء', 'عشاء', 'العشاء');
        case 'Jummah': return settings.translate('Jummah', 'جمعہ', 'جمعو', 'الجمعة');
        default: return nameKey;
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222C2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  getDisplayName(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.getFontForLanguage(context, lang),
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              InkWell(
                onTap: isLocked ? null : onPickTime,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isLocked
                        ? (isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.15))
                        : const Color(0xFF1B4332).withValues(alpha: isDark ? 0.35 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isLocked
                          ? (isDark ? Colors.white24 : Colors.grey.withValues(alpha: 0.3))
                          : const Color(0xFF1B4332).withValues(alpha: isDark ? 0.45 : 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          timeValue,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isLocked
                                ? (isDark ? Colors.white60 : Colors.black54)
                                : (isDark ? const Color(0xFF81C784) : const Color(0xFF1B4332)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        isLocked ? Icons.lock_outline_rounded : Icons.edit_rounded,
                        size: 15,
                        color: isLocked
                            ? (isDark ? Colors.white54 : Colors.black45)
                            : (isDark ? const Color(0xFF81C784) : const Color(0xFF1B4332)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: noteController,
            style: const TextStyle(fontSize: 12.5),
            decoration: InputDecoration(
              isDense: true,
              labelText: _t(settings, '$nameKey Note (Optional)', '$nameKey کا اضافی نوٹ (اختیاری)', '$nameKey جو اضافي نوٽ (اختياري)', 'ملاحظة $nameKey (اختياري)'),
              hintText: noteHint,
              prefixIcon: const Icon(Icons.sticky_note_2_outlined, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}
