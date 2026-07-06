import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('README integration snippets', () {
    for (final filename in ['README.md', 'README_EN.md']) {
      test('$filename does not show stale compatibility APIs', () {
        final readme = File(filename).readAsStringSync();

        expect(
          readme,
          isNot(contains('WidgetsFlutterBinding.ensureInitialized();')),
        );
        expect(readme, isNot(contains('ensureInitialized(\n  const Size')));
        expect(readme, isNot(contains('ensureInitialized(const Size')));
        expect(readme, isNot(contains('configForViewId')));
        expect(readme, isNot(contains('scaleForViewId')));
        expect(readme, isNot(contains('copyWithMaxScale')));
        expect(readme, isNot(contains('copyWithMinScale')));
        expect(readme, contains('config: const ScreenSizeAdapterConfig'));
      });

      test(
        '$filename uses a typed adapter binding accessor in multi-view docs',
        () {
          final readme = File(filename).readAsStringSync();

          expect(readme, contains('ScreenSizeWidgetsFlutterBinding.instance'));
        },
      );
    }
  });
}
