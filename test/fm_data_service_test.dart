import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fmhy_app/services/fm_data_service.dart';
import 'package:fmhy_app/services/fm_parser.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression tests for the stuck-spinner bug: `init()` used to set
/// `_isLoading = true` and then call `refresh()`, which returned early
/// because of its own `if (_isLoading) return;` guard.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sample = '''
# ► Tools

* [One](https://one.com) - First
''';

  http.Client mockClient(String body) => MockClient(
    (request) async => http.Response.bytes(
      utf8.encode(body),
      200,
      headers: {'content-type': 'text/plain; charset=utf-8'},
    ),
  );

  http.Client failingClient() => MockClient((_) async => http.Response('', 500));

  /// Waits for a fire-and-forget `refresh()` to settle.
  Future<void> settle(FMDataService data) async {
    for (var i = 0; i < 100 && data.isLoading; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  group('FMDataService', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('init() fetches content and clears isLoading', () async {
      final data = FMDataService(client: mockClient(sample));
      await data.init();

      expect(data.isLoading, isFalse, reason: 'spinner must be cleared');
      expect(data.error, isNull);
      expect(data.categories, hasLength(1));
      expect(data.categories.first.title, 'Tools');
    });

    test('init() stops loading and reports error when network fails', () async {
      final data = FMDataService(client: failingClient());
      await data.init();

      expect(data.isLoading, isFalse, reason: 'must not spin forever on failure');
      expect(data.error, isNotNull);
      expect(data.categories, isEmpty);
    });

    test('cache is served first, then refreshed in the background', () async {
      // Seed a cache entry.
      final seed = FMDataService(client: mockClient(sample));
      await seed.init();
      expect(seed.categories, isNotEmpty);

      // A fresh service over the same prefs should read cache, then refresh.
      final data = FMDataService(client: mockClient(sample));
      await data.init();

      // Content is available immediately from cache...
      expect(data.categories, isNotEmpty);
      // ...and the background refresh finishes, clearing the spinner.
      await settle(data);
      expect(data.isLoading, isFalse);
      expect(data.error, isNull);
    });

    test('parse of a full-size document yields categories', () {
      // Guards the isolate entry point used by refresh().
      final markdown = sample * 500;
      final parsed = FMParser().parse(markdown);
      expect(parsed, isNotEmpty);
      expect(FMParser().parse(markdown).first.title, 'Tools');
    });
  });
}
