import 'package:example/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  testWidgets('example app pumps under ScreenSizeTestEnvironment',
      (tester) async {
    // testWidgets uses AutomatedTestWidgetsFlutterBinding, not the
    // production ScreenSizeWidgetsFlutterBinding — so we use the
    // MediaQuery-layer simulator.
    await tester.pumpWidget(
      const ScreenSizeTestEnvironment(
        config: ScreenSizeAdapterConfig(designSize: Size(360, 640)),
        simulatedDeviceSize: Size(720, 1280),
        child: MyApp(),
      ),
    );
    expect(find.byType(MyApp), findsOneWidget);
  });
}
