import '../models/models.dart';

/// Parses the FMHY single-page markdown into categories.
///
/// Grammar handled (FMHY single-page markdown):
///   `# ► Category`        -> category heading (may be `[Title](url)`)
///   `## ▷ Section`        -> subsection heading
///   `* **Note** - text`   -> note attached to the next separator
///   `***` / `---` / `___` -> commits the pending note
///   `* [Name](url) - desc` -> entry, with `/ [Other](url)` as related links
class FMParser {
  // The URL part is a single character class rather than a nested alternation.
  // `(?:[^()]*|\([^()]*\))*` backtracks catastrophically on a malformed link
  // (e.g. "[Name](" + "a"*30), stalling the whole parse.
  static final _linkRe = RegExp(r'\[([^\]]+)\]\(([^()]*(?:\([^()]*\)[^()]*)*)\)');
  static final _simpleLinkRe = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');

  List<FMCategory> parse(String markdown) {
    final categories = <FMCategory>[];

    String? catTitle, catUrl, catNote;
    var catEntries = <FMEntry>[];
    var sections = <FMSection>[];

    String? secTitle, secNote;
    var secEntries = <FMEntry>[];

    String? pendingNote;
    var foundFirstCategory = false;

    void flushSection() {
      if (secTitle == null) return;
      sections.add(
        FMSection(title: secTitle!, note: secNote, entries: secEntries),
      );
      secTitle = null;
      secNote = null;
      secEntries = <FMEntry>[];
    }

    void flushCategory() {
      if (catTitle == null) return;
      categories.add(
        FMCategory(
          title: catTitle!,
          url: catUrl,
          note: catNote,
          entries: catEntries,
          sections: sections,
        ),
      );
      catTitle = null;
      catUrl = null;
      catNote = null;
      catEntries = <FMEntry>[];
      sections = <FMSection>[];
    }

    for (final rawLine in markdown.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      // Skip comment / navigation chrome lines.
      if (line.startsWith('<!--') ||
          line.startsWith('[◄◄') ||
          line.startsWith('[►►')) {
        continue;
      }

      // Category heading: `# ► Title` (not `##`)
      if (line.startsWith('#') &&
          !line.startsWith('##') &&
          line.contains('►')) {
        final afterArrow = line.substring(line.indexOf('►') + 1).trim();
        final parsed = _parseHeadingLink(afterArrow);
        if (parsed == null) continue;

        if (foundFirstCategory) {
          flushSection();
          flushCategory();
        }
        foundFirstCategory = true;
        catTitle = parsed.name;
        catUrl = parsed.url;
        catNote = null;
        catEntries = <FMEntry>[];
        sections = <FMSection>[];
        secTitle = null;
        secNote = null;
        secEntries = <FMEntry>[];
        pendingNote = null;
        continue;
      }

      if (!foundFirstCategory) continue;

      // Section heading: `## ▷ Title`
      if (line.startsWith('##') && line.contains('▷')) {
        flushSection();
        secTitle = line.substring(line.indexOf('▷') + 1).trim();
        secNote = null;
        secEntries = <FMEntry>[];
        pendingNote = null;
        continue;
      }

      // Note line, committed on the following separator.
      if ((line.startsWith('* ') && line.contains('**Note**')) ||
          line.contains('**Warning**')) {
        final note = _extractNote(line);
        if (note != null) pendingNote = note;
        continue;
      }

      if (line == '***' || line == '---' || line == '___') {
        final note = pendingNote;
        if (note != null) {
          if (secTitle != null) {
            secNote = note;
          } else if (catTitle != null) {
            catNote = note;
          }
          pendingNote = null;
        }
        continue;
      }

      // Entry line.
      if (line.startsWith('* ') || line.startsWith('- ')) {
        final entry = _parseEntry(line.substring(2));
        if (entry == null) continue;
        if (secTitle != null) {
          secEntries.add(entry);
        } else if (catTitle != null) {
          catEntries.add(entry);
        }
      }
    }

    flushSection();
    flushCategory();
    return categories;
  }

  /// Handles both `Title` and `[Title](url)` heading forms.
  ({String name, String? url})? _parseHeadingLink(String text) {
    final m = _linkRe.firstMatch(text);
    if (m != null && m.start == 0) {
      return (name: m.group(1)!, url: m.group(2));
    }
    if (text.isEmpty) return null;
    return (name: text, url: null);
  }

  String? _extractNote(String line) {
    final dash = line.indexOf('** - ');
    if (dash != -1) return line.substring(dash + 5).trim();
    final bold = line.indexOf('**');
    if (bold != -1) {
      final after = line.substring(bold + 2).trim();
      if (after.startsWith('- ')) return after.substring(2).trim();
    }
    return null;
  }

  FMEntry? _parseEntry(String text) {
    var body = text;
    final badge = FMBadge.parse(body);
    if (badge != FMBadge.none) {
      // Strip the leading emoji marker (plus any variation selector) and spacing.
      final space = body.indexOf(' ');
      if (space == -1) return null; // marker only, no entry text
      body = body.substring(space).trimLeft();
    }

    final matches = _linkRe.allMatches(body).toList();
    if (matches.isEmpty) return null;

    final primary = matches.first;
    final primaryUrl = primary.group(2);
    if (primaryUrl == null || primaryUrl.isEmpty) return null;

    final related = <FMLink>[];
    for (final m in matches.skip(1)) {
      final u = m.group(2);
      if (u != null && u.isNotEmpty) {
        related.add(FMLink(name: m.group(1)!, url: u));
      }
    }

    String? description;
    final sep = body.indexOf(' - ');
    if (sep != -1) {
      var desc = body.substring(sep + 3).trim();
      // Strip inline markdown links from the description text.
      desc = desc.replaceAllMapped(_simpleLinkRe, (m) => m.group(1) ?? '');
      desc = desc
          .replaceAll(RegExp(r'(?:\s*[/,]\s*)+$'), '')
          .replaceAll(RegExp(r'^(?:\s*[/,]\s*)+'), '')
          .replaceAll(RegExp(r'(?:\s*[/,]\s+){2,}'), ' ')
          .replaceAll(RegExp(r'\s+or\s*$'), '')
          .replaceAll(RegExp(r'\s{2,}'), ' ')
          .trim();
      description = desc.isEmpty ? null : desc;
    }

    return FMEntry(
      name: primary.group(1) ?? '',
      url: primaryUrl,
      description: description,
      badge: badge,
      relatedLinks: related,
    );
  }
}
