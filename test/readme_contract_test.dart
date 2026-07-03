import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('README integration snippets', () {
    for (final filename in ['README.md', 'README_EN.md']) {
      test(
        '$filename does not show binding initialization before adapter setup',
        () {
          final readme = File(filename).readAsStringSync();

          expect(
            readme,
            isNot(contains('WidgetsFlutterBinding.ensureInitialized();')),
          );
        },
      );

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
