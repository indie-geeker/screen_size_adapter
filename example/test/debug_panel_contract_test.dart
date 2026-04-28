import 'dart:ui';

import 'package:example/widgets/debug_panel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  group('checkContract', () {
    test('width axis matched when mq.width ≈ design.width', () {
      final r = checkContract(
        axis: ScaleAxis.width,
        mq: const Size(360, 690),
        design: const Size(360, 690),
      );
      expect(r.matched, isTrue);
      expect(r.message, contains('width'));
    });

    test('width axis violated when mq.width differs from design.width', () {
      final r = checkContract(
        axis: ScaleAxis.width,
        mq: const Size(309.2, 690),
        design: const Size(360, 690),
      );
      expect(r.matched, isFalse);
      expect(r.message, contains('width'));
    });

    test('height axis matched when mq.height ≈ design.height', () {
      final r = checkContract(
        axis: ScaleAxis.height,
        mq: const Size(309.2, 690),
        design: const Size(360, 690),
      );
      expect(r.matched, isTrue);
      expect(r.message, contains('height'));
    });

    test('height axis violated when mq.height differs from design.height', () {
      final r = checkContract(
        axis: ScaleAxis.height,
        mq: const Size(360, 600),
        design: const Size(360, 690),
      );
      expect(r.matched, isFalse);
      expect(r.message, contains('height'));
    });

    test('shorter axis matched when design fully inside mq', () {
      final r = checkContract(
        axis: ScaleAxis.shorter,
        mq: const Size(360, 800),
        design: const Size(360, 690),
      );
      expect(r.matched, isTrue);
      expect(r.message, contains('shorter'));
    });

    test('shorter axis violated when design exceeds mq on some axis', () {
      final r = checkContract(
        axis: ScaleAxis.shorter,
        mq: const Size(309, 690),
        design: const Size(360, 690),
      );
      expect(r.matched, isFalse);
      expect(r.message, contains('shorter'));
    });

    test('longer axis matched when at least one side ≈ design', () {
      final r = checkContract(
        axis: ScaleAxis.longer,
        mq: const Size(360, 600),
        design: const Size(360, 690),
      );
      expect(r.matched, isTrue);
      expect(r.message, contains('longer'));
    });

    test('longer axis violated when no axis aligns', () {
      final r = checkContract(
        axis: ScaleAxis.longer,
        mq: const Size(300, 600),
        design: const Size(360, 690),
      );
      expect(r.matched, isFalse);
      expect(r.message, contains('longer'));
    });
  });
}
