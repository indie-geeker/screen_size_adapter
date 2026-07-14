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

      test('$filename marks secondary-view support experimental', () {
        final readme = File(filename).readAsStringSync();
        final normalized = readme.toLowerCase();

        expect(normalized, contains('experimental'));
        expect(
          normalized,
          isNot(contains('provides stable multi-view support')),
        );
        expect(normalized, isNot(contains('multi-view support is stable')));
        expect(normalized, isNot(contains('is fully verified')));
        expect(readme, isNot(contains('多视图能力稳定可用')));
        expect(readme, isNot(contains('已经完整验证全部多视图场景')));
      });

      test('$filename states the exact coordinate and helper contracts', () {
        final readme = File(filename).readAsStringSync();

        expect(readme, contains('MediaQuery.size = originSize / scale'));
        expect(readme, contains('minScale'));
        expect(readme, contains('maxScale'));
        expect(readme, contains('MediaQuery-only'));
        expect(readme, contains('ScreenSizeTestViewport'));
        expect(readme, contains('RenderView'));
        expect(readme, contains('pointer converter'));
        expect(readme, isNot(contains('在所有设备上都返回设计尺寸')));
        expect(
          readme,
          isNot(
            contains(
              'MediaQuery.sizeOf(context) reports the design size on every device',
            ),
          ),
        );
      });
    }

    test('orientation snippet guards queued and equivalent updates', () {
      final orientationFixture =
          File('tool/snippets/orientation.dart').readAsStringSync();

      expect(orientationFixture, contains('MediaQuery.orientationOf(context)'));
      expect(orientationFixture, contains('if (!context.mounted) return;'));
      expect(
        orientationFixture,
        contains('if (liveOrientation != orientation)'),
      );
      expect(orientationFixture, contains('configForView(view)?.designSize'));
      expect(orientationFixture, isNot(contains('OrientationBuilder(')));

      final readme = File('README.md').readAsStringSync();
      final readmeEn = File('README_EN.md').readAsStringSync();
      expect(readme, isNot(contains('监听 `OrientationBuilder`')));
      expect(readmeEn, isNot(contains('via `OrientationBuilder`')));
    });
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

    test('pubspec does not advertise stable multi-view support', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();

      expect(pubspec, isNot(contains('  - multi-view')));
    });

    test('controller docs and changelog use the exact coordinate formula', () {
      final controller =
          File(
            'lib/src/screen_size_adapter_controller.dart',
          ).readAsStringSync();
      final changelog = File('CHANGELOG.md').readAsStringSync();

      expect(controller, contains('MediaQuery.size = originSize / scale'));
      expect(changelog, contains('MediaQuery.size = originSize / scale'));
      expect(
        controller,
        isNot(contains('always\n  /// reports the design size')),
      );
    });

    test('CI gates both SDK lanes and all checked-in example runners', () {
      final workflow = File('.github/workflows/ci.yml').readAsStringSync();

      expect(workflow, contains("flutter-version: '3.29.2'"));
      expect(workflow, contains('flutter-version: latest-stable'));
      expect(
        workflow,
        contains('dart format --output=none --set-exit-if-changed .'),
      );
      expect(workflow, contains('dart run tool/verify_readme_snippets.dart'));
      expect(workflow, contains('flutter build apk --debug'));
      expect(workflow, contains('runs-on: macos-latest'));
      expect(workflow, contains('flutter build ios --simulator'));
      expect(
        workflow,
        contains('git diff --exit-code -- example/ios example/.metadata'),
      );
      expect(workflow, contains('dart run tool/verify_example_startup.dart'));
    });

    test('secondary-view public surfaces point to the host checklist', () {
      const checklist = 'tool/verification/desktop_multi_view.md';
      for (final filename in [
        'README.md',
        'README_EN.md',
        'CHANGELOG.md',
        'lib/src/screen_size_adapter_controller.dart',
        'lib/src/screen_size_adapter_scope.dart',
        'lib/src/screen_size_widget_flutter_binding.dart',
        'example/README.md',
        'example/lib/widgets/multi_view_panel.dart',
      ]) {
        final surface = File(filename).readAsStringSync();
        final normalized = surface.toLowerCase();

        expect(
          normalized.contains('experimental') || surface.contains('实验性'),
          isTrue,
          reason: '$filename must mark secondary-view support experimental',
        );
        expect(
          surface,
          contains(checklist),
          reason: '$filename must point to $checklist',
        );
      }
    });
  });
}
