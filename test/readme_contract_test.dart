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

  group('release metadata', () {
    test('minimum Flutter and Dart versions agree across public surfaces', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final examplePubspec = File('example/pubspec.yaml').readAsStringSync();
      final workflow = File('.github/workflows/ci.yml').readAsStringSync();

      expect(pubspec, contains('sdk: ^3.7.2'));
      expect(pubspec, contains('flutter: ">=3.29.2"'));
      expect(examplePubspec, contains('sdk: ^3.7.2'));
      expect(examplePubspec, contains('flutter: ">=3.29.2"'));
      expect(workflow, contains("flutter-version: '3.29.2'"));
      expect(workflow, isNot(contains("flutter-version: '3.29.0'")));

      for (final filename in ['README.md', 'README_EN.md']) {
        final readme = File(filename).readAsStringSync();
        expect(readme, contains('Flutter `>=3.29.2`'));
        expect(readme, contains('Dart `^3.7.2`'));
        expect(readme, isNot(contains('Flutter `>=3.29.0`')));
      }
    });

    test('unpublished 0.3.0 changelog is not pre-dated', () {
      final changelog = File('CHANGELOG.md').readAsStringSync();

      expect(changelog, contains('## [0.3.0] - Unreleased'));
      expect(changelog, isNot(contains('## [0.3.0] - 2026-07-09')));
    });
  });
}
