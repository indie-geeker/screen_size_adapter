// snippet:widget-test:start
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  testWidgets('design layout uses the real test view', (tester) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(1500, 1624);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ScreenSizeAdapter(
        config: const ScreenSizeAdapterConfig(
          designSize: Size(375, 812),
          enableDesktopScaling: true,
        ),
        child: Builder(
          builder: (context) {
            expect(ScreenSizeAdapter.scaleOf(context), 2);
            expect(MediaQuery.sizeOf(context), const Size(375, 406));
            return const SizedBox();
          },
        ),
      ),
    );
  });
}
// snippet:widget-test:end
