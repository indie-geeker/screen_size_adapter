import 'package:example/state/adapter_settings.dart';
import 'package:example/widgets/orientation_design_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  test(
    'orientation demo repairs stale binding config when settings already match',
    () async {
      final binding = ScreenSizeWidgetsFlutterBinding.ensureInitialized(
        const ScreenSizeAdapterConfig(
          designSize: kLandscapeDesign,
          enableDesktopScaling: true,
        ),
      );
      final primary = binding.platformDispatcher.implicitView!;
      final settings = AdapterSettings(designSize: kPortraitDesign);

      try {
        expect(settings.designSize, kPortraitDesign);
        expect(binding.configForView(primary)?.designSize, kLandscapeDesign);

        binding.attachRootWidget(
          View(
            view: primary,
            child: ScreenSizeAdapterScope(
              child: MaterialApp(
                home: MediaQuery(
                  data: const MediaQueryData(size: kPortraitDesign),
                  child: Scaffold(
                    body: OrientationDesignDemo(settings: settings),
                  ),
                ),
              ),
            ),
          ),
        );
        binding.scheduleWarmUpFrame();
        await binding.endOfFrame;

        expect(binding.configForView(primary)?.designSize, kPortraitDesign);
        expect(settings.designSize, kPortraitDesign);
      } finally {
        settings.dispose();
      }
    },
  );
}
