import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'fm_parser.dart';

/// Fetches the FMHY single-page markdown, parses it, and caches the result.
class FMDataService extends ChangeNotifier {
  FMDataService({http.Client? client}) : _client = client ?? http.Client();

  static const primaryUrl = 'https://api.fmhy.net/single-page';
  static const backupUrl = 'https://fmhy.net/single-page.md';
  static const _cacheKey = 'fmhy_categories';
  static const _cacheStampKey = 'fmhy_categories_at';

  final http.Client _client;

  List<FMCategory> _categories = const [];
  List<FMCategory> get categories => _categories;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  DateTime? _lastUpdated;
  DateTime? get lastUpdated => _lastUpdated;

  Future<void> init() async {
    // Show cached content immediately, then refresh in the background.
    if (await _loadCache()) {
      notifyListeners();
      unawaited(refresh());
    } else {
      await refresh();
    }
  }

  Future<void> refresh() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _refreshImpl();
    } catch (e) {
      // Any failure must surface as an error state, not a silent empty screen.
      if (_categories.isEmpty) _error = 'Could not load content';
      debugPrint('FMDataService.refresh failed: $e');
    } finally {
      // Never leave the spinner running, whatever happens above.
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _refreshImpl() async {
    // Network first, then the mirror; cache covers offline launches.
    final markdown = await _fetch(primaryUrl) ?? await _fetch(backupUrl);
    if (markdown == null) {
      if (_categories.isEmpty) _error = 'Could not refresh';
      return;
    }

    // Parse on the main isolate: FMCategory is a plain Dart object and cannot
    // be sent back across an isolate port, so compute() cannot be used here.
    final parsed = await _parseAsync(markdown);
    if (parsed.isEmpty) {
      if (_categories.isEmpty) _error = 'Could not refresh';
      return;
    }

    _categories = parsed;
    _lastUpdated = DateTime.now();
    _error = null;
    unawaited(_saveCache(parsed));
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheStampKey);
  }

  Future<String?> _fetch(String url) async {
    try {
      final res = await _client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      final body = utf8.decode(res.bodyBytes);
      return body.isEmpty ? null : body;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return false;
      final decoded = jsonDecode(raw) as List;
      final cats = decoded
          .map((e) => FMCategory.fromJson(e as Map<String, dynamic>))
          .toList();
      if (cats.isEmpty) return false;
      _categories = cats;
      final stamp = prefs.getInt(_cacheStampKey);
      _lastUpdated = stamp == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(stamp);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveCache(List<FMCategory> cats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        jsonEncode(cats.map((c) => c.toJson()).toList()),
      );
      await prefs.setInt(
        _cacheStampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {
      // Cache writes are best effort.
    }
  }

  /// Yields between chunks so the spinner can paint while parsing.
  static Future<List<FMCategory>> _parseAsync(String markdown) async {
    await Future<void>.delayed(Duration.zero);
    return FMParser().parse(markdown);
  }
}
