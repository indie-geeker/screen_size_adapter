import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  late ScreenSizeWidgetsFlutterBinding binding;

  setUpAll(() {
    binding = ScreenSizeWidgetsFlutterBinding.ensureInitialized(
      const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
    );
  });

  tearDown(() {
    final primary = binding.platformDispatcher.views.first;
    binding.attachView(
      view: primary,
      config: const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
    );
  });

  test(
    'pointer packets are converted with the registered view effective DPR',
    () async {
      final primary = binding.platformDispatcher.views.first;
      final originSize = Size(
        primary.physicalSize.width / primary.devicePixelRatio,
        primary.physicalSize.height / primary.devicePixelRatio,
      );
      final designSize = Size(originSize.width / 2, originSize.height / 2);
      binding.attachView(
        view: primary,
        config: ScreenSizeAdapterConfig(
          designSize: designSize,
          enableDesktopScaling: true,
        ),
      );

      Offset? leftDown;
      Offset? rightDown;
      binding.attachRootWidget(
        View(
          view: primary,
          child: ScreenSizeAdapterScope(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: SizedBox(
                width: designSize.width,
                height: designSize.height,
                child: Row(
                  children: [
                    Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (event) => leftDown = event.position,
                      child: SizedBox(
                        width: designSize.width / 2,
                        height: designSize.height,
                      ),
                    ),
                    Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (event) => rightDown = event.position,
                      child: SizedBox(
                        width: designSize.width / 2,
                        height: designSize.height,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      binding.scheduleWarmUpFrame();
      await Future<void>.delayed(Duration.zero);

      final scale = binding.scaleForView(primary);
      expect(scale, closeTo(2.0, 0.001));
      final effectiveDpr = primary.devicePixelRatio * scale!;
      final designTarget = Offset(
        designSize.width * 0.75,
        designSize.height / 2,
      );
      final physicalTarget = Offset(
        designTarget.dx * effectiveDpr,
        designTarget.dy * effectiveDpr,
      );

      final handler = ui.PlatformDispatcher.instance.onPointerDataPacket;
      expect(handler, isNotNull);
      handler!(
        ui.PointerDataPacket(
          data: [
            ui.PointerData(
              viewId: primary.viewId,
              change: ui.PointerChange.down,
              kind: ui.PointerDeviceKind.touch,
              device: 1,
              pointerIdentifier: 1,
              physicalX: physicalTarget.dx,
              physicalY: physicalTarget.dy,
              buttons: kPrimaryButton,
              pressure: 1,
              pressureMax: 1,
            ),
            ui.PointerData(
              viewId: primary.viewId,
              change: ui.PointerChange.up,
              kind: ui.PointerDeviceKind.touch,
              device: 1,
              pointerIdentifier: 1,
              physicalX: physicalTarget.dx,
              physicalY: physicalTarget.dy,
              pressureMax: 1,
            ),
          ],
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(leftDown, isNull);
      expect(rightDown, closeToOffset(designTarget));
    },
  );
}

Matcher closeToOffset(Offset expected) => _CloseToOffset(expected);

class _CloseToOffset extends Matcher {
  _CloseToOffset(this.expected);

  final Offset expected;

  @override
  Description describe(Description description) {
    return description.add('an offset close to $expected');
  }

  @override
  bool matches(Object? item, Map<Object?, Object?> matchState) {
    if (item case final Offset actual) {
      return (actual.dx - expected.dx).abs() < 0.01 &&
          (actual.dy - expected.dy).abs() < 0.01;
    }
    return false;
  }
}
