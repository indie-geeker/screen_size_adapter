import 'dart:ui';

import 'package:example/widgets/debug_panel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  group('checkContract', () {
    test('same-aspect width scaling satisfies the coordinate formula', () {
      final result = checkContract(
        axis: ScaleAxis.width,
        mq: const Size(360, 690),
        origin: const Size(720, 1380),
        scale: 2,
        design: const Size(360, 690),
        minScale: null,
        maxScale: null,
      );

      expect(result.matched, isTrue);
      expect(result.message, contains('MQ × scale ≈ origin'));
      expect(result.fitMessage, contains('width'));
    });

    test('aspect mismatch keeps the formula while only width aligns', () {
      final result = checkContract(
        axis: ScaleAxis.width,
        mq: const Size(360, 576),
        origin: const Size(800, 1280),
        scale: 800 / 360,
        design: const Size(360, 690),
        minScale: null,
        maxScale: null,
      );

      expect(result.matched, isTrue);
      expect(result.fitMessage, contains('width 轴'));
      expect(result.fitMessage, contains('height 不要求'));
    });

    test(
      'a scale bound may disable both alignments without breaking formula',
      () {
        final result = checkContract(
          axis: ScaleAxis.width,
          mq: const Size(540, 960),
          origin: const Size(1080, 1920),
          scale: 2,
          design: const Size(360, 690),
          minScale: null,
          maxScale: 2,
        );

        expect(result.matched, isTrue);
        expect(result.fitMessage, contains('scale 限制生效'));
        expect(result.fitMessage, contains('不要求与设计稿对齐'));
      },
    );

    test('a broken formula reports reconstructed origin and delta', () {
      final result = checkContract(
        axis: ScaleAxis.height,
        mq: const Size(540, 950),
        origin: const Size(1080, 1920),
        scale: 2,
        design: const Size(360, 690),
        minScale: null,
        maxScale: null,
      );

      expect(result.matched, isFalse);
      expect(result.message, contains('MQ × scale = 1080.0 × 1900.0'));
      expect(result.message, contains('偏差 0.0 × 20.0'));
    });
  });
}
