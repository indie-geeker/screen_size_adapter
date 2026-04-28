import 'dart:math' as math;
import 'dart:ui';

import 'package:example/widgets/adapter_compare_demo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeBezels', () {
    test('portrait phone: total width fits, max bezel height capped at 200', () {
      final r = computeBezels(
        mqSize: const Size(309.2, 690),
        rawSize: const Size(426.7, 952),
        maxWidth: 360,
      );
      expect(r.left.width + 16 + r.right.width, lessThanOrEqualTo(360 + 0.5));
      expect(
        math.max(r.left.height, r.right.height),
        lessThanOrEqualTo(200 + 0.5),
      );
      expect(r.left.width / r.right.width, closeTo(309.2 / 426.7, 0.01));
    });

    test('scale=1 degenerate: left == right exactly', () {
      final r = computeBezels(
        mqSize: const Size(400, 600),
        rawSize: const Size(400, 600),
        maxWidth: 400,
      );
      expect(r.left, equals(r.right));
    });

    test('landscape: height-limited, both bezels <= 200 tall', () {
      final r = computeBezels(
        mqSize: const Size(640, 360),
        rawSize: const Size(952, 426.7),
        maxWidth: 600,
      );
      expect(r.left.height, lessThanOrEqualTo(200 + 0.5));
      expect(r.right.height, lessThanOrEqualTo(200 + 0.5));
    });

    test('narrow maxWidth: width-bound, total fits, ratios preserved', () {
      final r = computeBezels(
        mqSize: const Size(309.2, 690),
        rawSize: const Size(426.7, 952),
        maxWidth: 200,
      );
      expect(r.left.width + 16 + r.right.width, lessThanOrEqualTo(200 + 0.5));
      expect(r.left.width / r.right.width, closeTo(309.2 / 426.7, 0.01));
    });

    test('zero / negative inputs degenerate gracefully', () {
      final r1 = computeBezels(
        mqSize: Size.zero,
        rawSize: const Size(100, 100),
        maxWidth: 200,
      );
      expect(r1.scale, 0.0);
      final r2 = computeBezels(
        mqSize: const Size(100, 100),
        rawSize: const Size(100, 100),
        maxWidth: 4, // less than gap=16, leaves negative widthEach
      );
      expect(r2.scale, 0.0);
    });
  });
}
