import 'package:example/pages/home_page.dart';
import 'package:example/state/adapter_settings.dart';
import 'package:example/widgets/info_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

const _portraitOrigin = Size(390, 844);
const _landscapeOrigin = Size(844, 390);

void main() {
  testWidgets('ordinary-width InfoRow anchors content to opposite edges', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 320,
            child: InfoRow(label: 'Label', value: 'Value'),
          ),
        ),
      ),
    );

    final infoRow = find.byType(InfoRow);
    final row = find.descendant(of: infoRow, matching: find.byType(Row));
    final rowRect = tester.getRect(row);
    final labelRect = tester.getRect(find.text('Label:'));
    final valueRect = tester.getRect(find.text('Value'));

    expect(tester.takeException(), isNull);
    expect(labelRect.left, closeTo(rowRect.left, 0.001));
    expect(valueRect.right, closeTo(rowRect.right, 0.001));
  });

  for (final axis in ScaleAxis.values) {
    testWidgets('${axis.name} stays layout-safe through orientation changes', (
      tester,
    ) async {
      final settings = AdapterSettings(
        scaleAxis: axis,
        autoSwapByOrientation: false,
      );
      final nativeViewport = ValueNotifier<Size>(_portraitOrigin);
      addTearDown(settings.dispose);
      addTearDown(nativeViewport.dispose);

      await tester.pumpWidget(
        _OrientationHarness(settings: settings, nativeViewport: nativeViewport),
      );

      Future<void> expectState({
        required String description,
        required Size designSize,
        required Size origin,
      }) async {
        settings.setDesignSize(designSize);
        nativeViewport.value = origin;
        await tester.pump();

        final config = ScreenSizeAdapterConfig(
          designSize: designSize,
          scaleAxis: axis,
        );
        final scale = ScreenSizeAdapter.computeScale(
          origin: origin,
          config: config,
          isDesktop: false,
        );
        final expectedSize = origin / scale;
        final homeContext = tester.element(find.byType(HomePage));
        final actualSize = MediaQuery.sizeOf(homeContext);

        expect(
          actualSize.width,
          closeTo(expectedSize.width, 0.001),
          reason: '$description width',
        );
        expect(
          actualSize.height,
          closeTo(expectedSize.height, 0.001),
          reason: '$description height',
        );
        expect(
          MediaQuery.of(homeContext).textScaler,
          const TextScaler.linear(2.0),
          reason: '$description text scaling',
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '$description layout exception',
        );
      }

      await expectState(
        description: 'portrait design + portrait origin',
        designSize: kPortraitDesign,
        origin: _portraitOrigin,
      );
      await expectState(
        description: 'portrait design + landscape origin (transient)',
        designSize: kPortraitDesign,
        origin: _landscapeOrigin,
      );
      await expectState(
        description: 'landscape design + landscape origin (settled)',
        designSize: kLandscapeDesign,
        origin: _landscapeOrigin,
      );
      await expectState(
        description: 'landscape design + portrait origin (transient)',
        designSize: kLandscapeDesign,
        origin: _portraitOrigin,
      );
      await expectState(
        description: 'portrait design + portrait origin (settled)',
        designSize: kPortraitDesign,
        origin: _portraitOrigin,
      );
    });
  }
}

class _OrientationHarness extends StatelessWidget {
  const _OrientationHarness({
    required this.settings,
    required this.nativeViewport,
  });

  final AdapterSettings settings;
  final ValueNotifier<Size> nativeViewport;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2.0)),
          child: child!,
        );
      },
      home: ValueListenableBuilder<Size>(
        valueListenable: nativeViewport,
        builder: (context, origin, _) {
          return ListenableBuilder(
            listenable: settings,
            builder: (context, _) {
              return ScreenSizeTestViewport(
                config: ScreenSizeAdapterConfig(
                  designSize: settings.designSize,
                  scaleAxis: settings.scaleAxis,
                  minScale: settings.minScale,
                  maxScale: settings.maxScale,
                ),
                simulatedDeviceSize: origin,
                child: HomePage(settings: settings),
              );
            },
          );
        },
      ),
    );
  }
}
