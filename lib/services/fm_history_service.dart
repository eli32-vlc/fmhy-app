import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryEntry {
  final String name;
  final String url;
  final DateTime viewedAt;

  const HistoryEntry({
    required this.name,
    required this.url,
    required this.viewedAt,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'url': url,
    'viewedAt': viewedAt.toIso8601String(),
  };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
    name: json['name'] as String,
    url: json['url'] as String,
    viewedAt:
        DateTime.tryParse(json['viewedAt'] as String? ?? '') ?? DateTime.now(),
  );
}

/// Recently opened entries, most recent first, capped at 20 like the original.
class FMHistoryService extends ChangeNotifier {
  static const _key = 'fmhy_history';
  static const maxEntries = 20;

  List<HistoryEntry> _entries = const [];
  List<HistoryEntry> get entries => _entries;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final decoded = jsonDecode(raw) as List;
      _entries = decoded
          .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {
      // Ignore corrupt state.
    }
  }

  Future<void> recordView(String name, String url) async {
    final updated = [
      HistoryEntry(name: name, url: url, viewedAt: DateTime.now()),
      ..._entries.where((e) => e.url != url),
    ];
    _entries = updated.take(maxEntries).toList();
    notifyListeners();
    await _save();
  }

  Future<void> remove(String url) async {
    _entries = _entries.where((e) => e.url != url).toList();
    notifyListeners();
    await _save();
  }

  Future<void> clear() async {
    _entries = const [];
    notifyListeners();
    await _save();
  }

  Future<void> importAll(List<HistoryEntry> incoming) async {
    final merged = [..._entries];
    for (final entry in incoming) {
      if (!merged.any((e) => e.url == entry.url)) merged.add(entry);
    }
    merged.sort((a, b) => b.viewedAt.compareTo(a.viewedAt));
    _entries = merged.take(maxEntries).toList();
    notifyListeners();
    await _save();
  }

  String exportJson() => jsonEncode(_entries.map((e) => e.toJson()).toList());

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, exportJson());
  }
}
