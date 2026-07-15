import 'package:example/main.dart';
import 'package:example/state/adapter_settings.dart';
import 'package:example/widgets/orientation_design_demo.dart';
import 'package:flutter/material.dart';
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
    expect(find.text('screen_size_adapter · Live Debugging'), findsOneWidget);
    expect(find.text('Limit to 0.8–1.2'), findsOneWidget);
    expect(find.text('Clear scale limits'), findsOneWidget);
    expect(find.text('Reset to native (scale=1)'), findsOneWidget);
    expect(
      find.byTooltip('Without min/max limits: MQ.width = design.width'),
      findsOneWidget,
    );
    expect(
      find.byTooltip('Without min/max limits: MQ.height = design.height'),
      findsOneWidget,
    );
    expect(find.textContaining('native logic px'), findsWidgets);
    expect(find.textContaining('raw px'), findsNothing);
    expect(find.textContaining('设备真实像素'), findsNothing);
    expect(find.textContaining('rotating or resizing affects both'), findsOneWidget);
  });

  testWidgets('native reset disables orientation auto swap', (tester) async {
    await tester.pumpWidget(
      const ScreenSizeTestEnvironment(
        config: ScreenSizeAdapterConfig(designSize: Size(360, 690)),
        simulatedDeviceSize: Size(720, 1380),
        child: MyApp(),
      ),
    );
    await tester.pump();

    final reset = find.text('Reset to native (scale=1)');
    await tester.ensureVisible(reset);
    await tester.tap(reset);
    await tester.pumpAndSettle();

    final orientationToggle = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Auto-swap designSize'),
    );
    expect(orientationToggle.value, isFalse);
  });

  testWidgets('orientation auto swap follows MediaQuery inside a scroller', (
    tester,
  ) async {
    final settings = AdapterSettings();
    addTearDown(settings.dispose);

    await tester.pumpWidget(
      ScreenSizeTestEnvironment(
        config: const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
        simulatedDeviceSize: const Size(1280, 720),
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OrientationDesignDemo(settings: settings),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.textContaining('Current MediaQuery reports: landscape → Target design size 640×360'),
      findsOneWidget,
    );
    expect(settings.designSize, kLandscapeDesign);
    expect(tester.takeException(), isNull);
  });
}
