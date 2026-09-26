/// Data models for FMHY entries, sections, and categories.
library;

/// Badge markers that appear at the start of an entry line in the source markdown.
enum FMBadge {
  star,
  globe,
  arrow,
  none;

  static FMBadge parse(String raw) {
    if (raw.startsWith('⭐') || raw.startsWith('★')) return FMBadge.star;
    if (raw.startsWith('🌐')) return FMBadge.globe;
    if (raw.startsWith('↪')) return FMBadge.arrow;
    return FMBadge.none;
  }
}

/// A secondary link extracted from the same entry line, e.g. "/ [Mirror](url)".
class FMLink {
  final String name;
  final String url;

  const FMLink({required this.name, required this.url});

  Map<String, dynamic> toJson() => {'name': name, 'url': url};

  factory FMLink.fromJson(Map<String, dynamic> json) =>
      FMLink(name: json['name'] as String, url: json['url'] as String);

  @override
  bool operator ==(Object other) => other is FMLink && other.url == url;

  @override
  int get hashCode => url.hashCode;
}

/// A single link entry.
class FMEntry {
  final String name;
  final String url;
  final String? description;
  final FMBadge badge;
  final List<FMLink> relatedLinks;

  const FMEntry({
    required this.name,
    required this.url,
    this.description,
    this.badge = FMBadge.none,
    this.relatedLinks = const [],
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'url': url,
    'description': description,
    'badge': badge.name,
    'relatedLinks': relatedLinks.map((l) => l.toJson()).toList(),
  };

  factory FMEntry.fromJson(Map<String, dynamic> json) => FMEntry(
    name: json['name'] as String,
    url: json['url'] as String,
    description: json['description'] as String?,
    badge: FMBadge.values.firstWhere(
      (b) => b.name == json['badge'],
      orElse: () => FMBadge.none,
    ),
    relatedLinks: ((json['relatedLinks'] as List?) ?? const [])
        .map((e) => FMLink.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

/// A "## ▷" subsection inside a category.
class FMSection {
  final String title;
  final String? note;
  final List<FMEntry> entries;

  const FMSection({required this.title, this.note, this.entries = const []});

  Map<String, dynamic> toJson() => {
    'title': title,
    'note': note,
    'entries': entries.map((e) => e.toJson()).toList(),
  };

  factory FMSection.fromJson(Map<String, dynamic> json) => FMSection(
    title: json['title'] as String,
    note: json['note'] as String?,
    entries: ((json['entries'] as List?) ?? const [])
        .map((e) => FMEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

/// A top level "# ►" category, optionally itself a link (index entries).
class FMCategory {
  final String title;
  final String? url;
  final String? note;
  final List<FMEntry> entries;
  final List<FMSection> sections;

  const FMCategory({
    required this.title,
    this.url,
    this.note,
    this.entries = const [],
    this.sections = const [],
  });

  int get totalEntries =>
      entries.length + sections.fold(0, (sum, s) => sum + s.entries.length);

  /// Categories that are pure links are shown in a separate "Links" section.
  bool get isLink => url != null;

  FMCategory filter(String query) {
    final q = query.toLowerCase();
    final matchingSections = sections
        .map(
          (s) => FMSection(
            title: s.title,
            note: s.note,
            entries: s.entries.where((e) => _matches(e, q)).toList(),
          ),
        )
        .where((s) => s.entries.isNotEmpty)
        .toList();
    final matchingEntries =
        entries.where((e) => _matches(e, q)).toList();
    if (matchingSections.isEmpty && matchingEntries.isEmpty) {
      throw StateError('No matches');
    }
    return FMCategory(
      title: title,
      url: url,
      note: note,
      entries: matchingEntries,
      sections: matchingSections,
    );
  }

  static bool _matches(FMEntry e, String q) =>
      e.name.toLowerCase().contains(q) ||
      (e.description?.toLowerCase().contains(q) ?? false) ||
      e.url.toLowerCase().contains(q);

  Map<String, dynamic> toJson() => {
    'title': title,
    'url': url,
    'note': note,
    'entries': entries.map((e) => e.toJson()).toList(),
    'sections': sections.map((s) => s.toJson()).toList(),
  };

  factory FMCategory.fromJson(Map<String, dynamic> json) => FMCategory(
    title: json['title'] as String,
    url: json['url'] as String?,
    note: json['note'] as String?,
    entries: ((json['entries'] as List?) ?? const [])
        .map((e) => FMEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
    sections: ((json['sections'] as List?) ?? const [])
        .map((s) => FMSection.fromJson(s as Map<String, dynamic>))
        .toList(),
  );
}
