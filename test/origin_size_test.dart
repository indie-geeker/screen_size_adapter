import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  testWidgets(
    'originSizeOf returns the unscaled FlutterView logical size',
    (tester) async {
      // tester.view exposes a TestFlutterView whose physicalSize/dpr we can set.
      // 1440x2760 / 2.0 = 720x1380 unscaled logical — twice the designSize
      // (360x690), so the scaling layer would compress MediaQuery to 360 but
      // originSizeOf must still report 720.
      tester.view.physicalSize = const Size(1440, 2760);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      Size? originObserved;
      Size? mediaQueryObserved;
      await tester.pumpWidget(
        ScreenSizeTestEnvironment(
          config: const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
          child: Builder(builder: (ctx) {
            originObserved = ScreenSizeAdapter.originSizeOf(ctx);
            mediaQueryObserved = MediaQuery.sizeOf(ctx);
            return const SizedBox.shrink();
          }),
        ),
      );

      // Native logical size — usable for breakpoints.
      expect(originObserved, const Size(720, 1380));
      // Design size — what MediaQuery returns under the scope.
      expect(mediaQueryObserved, const Size(360, 690));
    },
  );
}
