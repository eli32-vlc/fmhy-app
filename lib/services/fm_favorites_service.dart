import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

class FavoriteEntry {
  final String name;
  final String url;
  final FMBadge badge;
  final DateTime addedAt;

  const FavoriteEntry({
    required this.name,
    required this.url,
    required this.badge,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'url': url,
    'badge': badge.name,
    'addedAt': addedAt.toIso8601String(),
  };

  factory FavoriteEntry.fromJson(Map<String, dynamic> json) => FavoriteEntry(
    name: json['name'] as String,
    url: json['url'] as String,
    badge: FMBadge.values.firstWhere(
      (b) => b.name == json['badge'],
      orElse: () => FMBadge.none,
    ),
    addedAt:
        DateTime.tryParse(json['addedAt'] as String? ?? '') ?? DateTime.now(),
  );
}

/// Starred entries, newest first, capped like the Swift original.
class FMFavoritesService extends ChangeNotifier {
  static const _key = 'fmhy_favorites';
  static const maxFavorites = 100;

  List<FavoriteEntry> _favorites = const [];
  List<FavoriteEntry> get favorites => _favorites;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final decoded = jsonDecode(raw) as List;
      _favorites = decoded
          .map((e) => FavoriteEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {
      // Ignore corrupt state.
    }
  }

  bool isFavorite(String url) => _favorites.any((f) => f.url == url);

  Future<void> toggle(FMEntry entry) async {
    if (isFavorite(entry.url)) {
      _favorites = _favorites.where((f) => f.url != entry.url).toList();
    } else {
      _favorites = [
        FavoriteEntry(
          name: entry.name,
          url: entry.url,
          badge: entry.badge,
          addedAt: DateTime.now(),
        ),
        ..._favorites,
      ];
      if (_favorites.length > maxFavorites) {
        _favorites = _favorites.take(maxFavorites).toList();
      }
    }
    notifyListeners();
    await _save();
  }

  Future<void> remove(String url) async {
    _favorites = _favorites.where((f) => f.url != url).toList();
    notifyListeners();
    await _save();
  }

  Future<void> clear() async {
    _favorites = const [];
    notifyListeners();
    await _save();
  }

  /// Merge-imports entries from an exported file, ignoring duplicates.
  Future<void> importAll(List<FavoriteEntry> incoming) async {
    final merged = [..._favorites];
    for (final entry in incoming) {
      if (!merged.any((f) => f.url == entry.url)) merged.add(entry);
    }
    _favorites = merged.take(maxFavorites).toList();
    notifyListeners();
    await _save();
  }

  String exportJson() =>
      jsonEncode(_favorites.map((f) => f.toJson()).toList());

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, exportJson());
  }
}
