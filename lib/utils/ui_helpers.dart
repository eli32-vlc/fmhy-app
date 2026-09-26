import 'package:flutter/material.dart';

/// Removes inline markdown so raw note text can render as plain prose.
String stripMarkdown(String text) {
  var result = text.replaceAllMapped(
    RegExp(r'\[([^\]]+)\]\([^)]+\)'),
    (m) => m.group(1) ?? '',
  );
  result = result
      .replaceAll(RegExp(r'\*\*'), '')
      .replaceAll(RegExp(r'\*'), '');
  return result.trim();
}

/// Compact "3d ago" style timestamps used in the history list.
String relativeTime(DateTime date) {
  final interval = DateTime.now().difference(date);
  if (interval.inSeconds < 60) return 'Just now';
  if (interval.inMinutes < 60) return '${interval.inMinutes}m ago';
  if (interval.inHours < 24) return '${interval.inHours}h ago';
  if (interval.inDays < 7) return '${interval.inDays}d ago';
  return '${date.month}/${date.day}';
}

IconData categoryIcon(String title) {
  final l = title.toLowerCase();
  if (_any(l, ['stream', 'video', 'movie', 'film'])) return Icons.play_circle_fill;
  if (_any(l, ['music', 'audio'])) return Icons.music_note;
  if (_any(l, ['book', 'read', 'novel'])) return Icons.menu_book;
  if (_any(l, ['game', 'gaming'])) return Icons.sports_esports;
  if (_any(l, ['anime', 'animation', 'cartoon'])) return Icons.brush;
  if (_any(l, ['tool', 'soft', 'util'])) return Icons.build;
  if (_any(l, ['edu', 'learn', 'course'])) return Icons.school;
  if (_any(l, ['social', 'chat', 'communic'])) return Icons.chat_bubble;
  if (_any(l, ['download', 'piracy'])) return Icons.download;
  if (_any(l, ['search', 'engine'])) return Icons.search;
  if (_any(l, ['android', 'ios', 'mobile'])) return Icons.smartphone;
  if (_any(l, ['windows', 'mac', 'linux'])) return Icons.desktop_windows;
  if (_any(l, ['emulat', 'rom'])) return Icons.videogame_asset;
  return Icons.folder;
}

Color categoryColor(String title) {
  final l = title.toLowerCase();
  if (_any(l, ['stream', 'video', 'movie', 'film'])) return Colors.red;
  if (_any(l, ['music', 'audio'])) return Colors.pink;
  if (_any(l, ['book', 'read', 'novel'])) return Colors.green;
  if (_any(l, ['game', 'gaming'])) return Colors.purple;
  if (_any(l, ['anime', 'animation', 'cartoon'])) return Colors.orange;
  if (_any(l, ['tool', 'soft', 'util'])) return Colors.blue;
  if (_any(l, ['edu', 'learn', 'course'])) return Colors.cyan;
  if (_any(l, ['social', 'chat', 'communic'])) return Colors.teal;
  if (_any(l, ['download', 'piracy'])) return Colors.indigo;
  if (_any(l, ['search', 'engine'])) return Colors.greenAccent;
  return Colors.blueGrey;
}

Color badgeColor(String badge) => switch (badge) {
  'star' => Colors.orange,
  'globe' => Colors.blue,
  'arrow' => Colors.grey,
  _ => Colors.transparent,
};

IconData badgeIcon(String badge) => switch (badge) {
  'star' => Icons.star,
  'globe' => Icons.public,
  'arrow' => Icons.arrow_outward,
  _ => Icons.circle,
};

bool _any(String haystack, List<String> needles) =>
    needles.any(haystack.contains);
