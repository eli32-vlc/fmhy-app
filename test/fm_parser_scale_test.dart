import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fmhy_app/services/fm_parser.dart';

/// Scale and robustness checks for the parser.
///
/// The real feed is ~1.9MB / ~22k lines, so the generator below mirrors that
/// shape. A tiny synthetic sample hides problems that only appear at size.
void main() {
  test('parses a large document without stalling', () {
    // ~1.9MB of realistic FMHY-shaped markdown, built without the network.
    final buffer = StringBuffer();
    var n = 0;
    while (buffer.length < 1900000) {
      buffer.write('# ► Category $n\n\n');
      buffer.write('* **Note** - Read this.\n\n***\n\n');
      buffer.write('## ▷ Subcategory $n\n\n');
      for (var i = 0; i < 12; i++) {
        final id = '$n-$i';
        buffer.write(
          '* ⭐ **[Service$id](https://example.com/$id)** - Useful tool / '
          '[Mirror](https://mirror.example.com/$id) / [Note](https://fmhy.net/n)\n',
        );
      }
      buffer.write('***\n\n');
      n++;
    }

    final markdown = buffer.toString();
    expect(markdown.length, greaterThan(1800000));

    final sw = Stopwatch()..start();
    final categories = FMParser().parse(markdown);
    sw.stop();

    debugPrint(
      'parsed ${markdown.length} chars in ${sw.elapsedMilliseconds}ms '
      '-> ${categories.length} categories',
    );

    expect(categories, isNotEmpty);
    expect(sw.elapsed, lessThan(const Duration(seconds: 30)));

    final total = categories.fold<int>(
      0,
      (sum, c) =>
          sum +
          c.entries.length +
          c.sections.fold<int>(0, (m, s) => m + s.entries.length),
    );
    debugPrint('total entries: $total');
    expect(total, greaterThan(1000));
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('malformed unclosed link does not blow up the parser', () {
    // Guards against catastrophic regex backtracking on broken input.
    final md = '# ► Broken\n\n* [Name](${'a' * 400}\n';
    final sw = Stopwatch()..start();
    final cats = FMParser().parse(md);
    sw.stop();
    debugPrint('malformed line parsed in ${sw.elapsedMilliseconds}ms');
    expect(sw.elapsed, lessThan(const Duration(seconds: 5)));
    expect(cats.first.entries, isEmpty);
  }, timeout: const Timeout(Duration(seconds: 20)));
}
