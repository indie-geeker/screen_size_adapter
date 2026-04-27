import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  testWidgets('SizedBox renders at design size on a 2x device', (tester) async {
    await tester.pumpWidget(
      ScreenSizeTestEnvironment(
        config: const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
        simulatedDeviceSize: const Size(720, 1380),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: SizedBox(width: 100, height: 50)),
        ),
      ),
    );
    expect(tester.getSize(find.byType(SizedBox)), const Size(100, 50));
  });

  testWidgets('with maxScale clamp, SizedBox still measures at design size',
      (tester) async {
    await tester.pumpWidget(
      ScreenSizeTestEnvironment(
        config: const ScreenSizeAdapterConfig(
          designSize: Size(360, 690),
          maxScale: 1.5,
        ),
        simulatedDeviceSize: const Size(1440, 2760),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: SizedBox(width: 100, height: 50)),
        ),
      ),
    );
    expect(tester.getSize(find.byType(SizedBox)), const Size(100, 50));
  });

  testWidgets(
      'isDesktop=true with enableDesktopScaling=false leaves layout raw',
      (tester) async {
    await tester.pumpWidget(
      ScreenSizeTestEnvironment(
        config: const ScreenSizeAdapterConfig(
          designSize: Size(360, 690),
          enableDesktopScaling: false,
        ),
        isDesktop: true,
        simulatedDeviceSize: const Size(1920, 1080),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: SizedBox(width: 100, height: 50)),
        ),
      ),
    );
    expect(tester.getSize(find.byType(SizedBox)), const Size(100, 50));
  });
}
