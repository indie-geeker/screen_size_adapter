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
    expect(find.text('screen_size_adapter · 实时调试'), findsOneWidget);
    expect(find.text('限制为 0.8–1.2'), findsOneWidget);
    expect(find.text('移除 scale 限制'), findsOneWidget);
    expect(find.text('重置为原生 scale=1'), findsOneWidget);
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

    final reset = find.text('重置为原生 scale=1');
    await tester.ensureVisible(reset);
    await tester.tap(reset);
    await tester.pumpAndSettle();

    final orientationToggle = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, '随方向切换 designSize'),
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
      find.textContaining('当前 MediaQuery 报告：landscape → 目标设计稿 640×360'),
      findsOneWidget,
    );
    expect(settings.designSize, kLandscapeDesign);
    expect(tester.takeException(), isNull);
  });
}
