import 'dart:ui' as ui;

import 'package:flutter/gestures.dart' show DeviceGestureSettings;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/src/internal/scale_media_query.dart';

void main() {
  group('scaleMediaQueryData', () {
    const baseData = MediaQueryData(
      size: Size(720, 1380),
      devicePixelRatio: 2.0,
      padding: EdgeInsets.only(top: 48, bottom: 24),
      viewPadding: EdgeInsets.only(top: 48, bottom: 24),
      viewInsets: EdgeInsets.only(bottom: 320),
      systemGestureInsets: EdgeInsets.only(left: 16, right: 16),
    );

    test('returns the same instance when scale is 1.0', () {
      expect(identical(scaleMediaQueryData(baseData, 1.0), baseData), isTrue);
    });

    test('native context menus are only supported at identity scale', () {
      final native = baseData.copyWith(supportsShowingSystemContextMenu: true);
      for (final scale in [0.75, 1.5]) {
        expect(
          scaleMediaQueryData(native, scale).supportsShowingSystemContextMenu,
          isFalse,
        );
      }
      expect(scaleMediaQueryData(native, 1.0), same(native));
      expect(native.supportsShowingSystemContextMenu, isTrue);
    });

    test('size is divided by scale', () {
      final scaled = scaleMediaQueryData(baseData, 2.0);
      expect(scaled.size, const Size(360, 690));
    });

    test('devicePixelRatio is multiplied by scale', () {
      final scaled = scaleMediaQueryData(baseData, 2.0);
      expect(scaled.devicePixelRatio, 4.0);
    });

    test('padding is divided by scale', () {
      final scaled = scaleMediaQueryData(baseData, 2.0);
      expect(scaled.padding.top, 24);
      expect(scaled.padding.bottom, 12);
    });

    test('viewPadding is divided by scale', () {
      final scaled = scaleMediaQueryData(baseData, 2.0);
      expect(scaled.viewPadding.top, 24);
      expect(scaled.viewPadding.bottom, 12);
    });

    test('viewInsets is divided by scale', () {
      final scaled = scaleMediaQueryData(baseData, 2.0);
      expect(scaled.viewInsets.bottom, 160);
    });

    test('systemGestureInsets is divided by scale', () {
      final scaled = scaleMediaQueryData(baseData, 2.0);
      expect(scaled.systemGestureInsets.left, 8);
      expect(scaled.systemGestureInsets.right, 8);
    });

    test('gesture touch slop stays in native global units', () {
      final data = baseData.copyWith(
        gestureSettings: const DeviceGestureSettings(touchSlop: 18),
      );

      final scaled = scaleMediaQueryData(data, 2.0);

      expect(scaled.gestureSettings, same(data.gestureSettings));
    });

    test('display feature bounds are divided by scale', () {
      const feature = ui.DisplayFeature(
        bounds: ui.Rect.fromLTRB(300, 0, 340, 1380),
        type: ui.DisplayFeatureType.hinge,
        state: ui.DisplayFeatureState.postureFlat,
      );
      final data = baseData.copyWith(displayFeatures: const [feature]);

      final scaled = scaleMediaQueryData(data, 2.0);

      expect(
        scaled.displayFeatures.single.bounds,
        const ui.Rect.fromLTRB(150, 0, 170, 690),
      );
      expect(scaled.displayFeatures.single.type, feature.type);
      expect(scaled.displayFeatures.single.state, feature.state);
    });

    test('non-scaled fields are preserved (textScaler)', () {
      final data = baseData.copyWith(textScaler: const TextScaler.linear(1.5));
      final scaled = scaleMediaQueryData(data, 2.0);
      expect(scaled.textScaler, const TextScaler.linear(1.5));
    });

    test('fractional scale also applies', () {
      final scaled = scaleMediaQueryData(baseData, 1.185);
      expect(scaled.size.width, closeTo(607.59, 0.01));
      expect(scaled.devicePixelRatio, closeTo(2.37, 0.001));
      expect(scaled.padding.top, closeTo(40.51, 0.01));
    });
  });
}
