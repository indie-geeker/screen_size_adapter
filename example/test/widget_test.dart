import 'package:example/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  testWidgets('example app pumps under ScreenSizeTestEnvironment', (
    tester,
  ) async {
    // testWidgets uses AutomatedTestWidgetsFlutterBinding, not the
    // production ScreenSizeWidgetsFlutterBinding — so we use the
    // MediaQuery-layer simulator.
    await tester.pumpWidget(
      const ScreenSizeTestEnvironment(
        config: ScreenSizeAdapterConfig(designSize: Size(360, 690)),
        simulatedDeviceSize: Size(720, 1380),
        child: MyApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(MyApp), findsOneWidget);
    expect(find.text('screen_size_adapter · 实时调试'), findsOneWidget);
  });
}
