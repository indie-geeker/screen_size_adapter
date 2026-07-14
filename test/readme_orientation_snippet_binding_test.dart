import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

import '../tool/snippets/orientation.dart';

class _MetricsCounter with WidgetsBindingObserver {
  int count = 0;

  @override
  void didChangeMetrics() {
    count++;
  }
}

void main() {
  test(
    'orientation snippet updates once per target and ignores rebuilds',
    () async {
      final binding = ScreenSizeWidgetsFlutterBinding.ensureInitialized(
        const ScreenSizeAdapterConfig(
          designSize: Size(111, 222),
          enableDesktopScaling: true,
        ),
      );
      final primary = binding.platformDispatcher.implicitView!;
      final orientation = ValueNotifier<Orientation>(Orientation.portrait);
      final revision = ValueNotifier<int>(0);
      final counter = _MetricsCounter();
      binding.addObserver(counter);

      try {
        binding.attachRootWidget(
          View(
            view: primary,
            child: ScreenSizeAdapterScope(
              child: MaterialApp(
                home: ValueListenableBuilder<Orientation>(
                  valueListenable: orientation,
                  builder: (context, value, _) {
                    final size =
                        value == Orientation.landscape
                            ? const Size(640, 360)
                            : const Size(360, 640);
                    return MediaQuery(
                      data: MediaQuery.of(context).copyWith(size: size),
                      child: ValueListenableBuilder<int>(
                        valueListenable: revision,
                        builder:
                            (context, value, _) => KeyedSubtree(
                              key: ValueKey(value),
                              child: buildOrientationAwareHome(),
                            ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        final beforePortrait = counter.count;
        binding.scheduleWarmUpFrame();
        await binding.endOfFrame;
        expect(
          binding.configForView(primary)?.designSize,
          const Size(360, 640),
        );
        expect(counter.count, beforePortrait + 1);

        await binding.endOfFrame;
        expect(counter.count, beforePortrait + 1);

        revision.value++;
        await binding.endOfFrame;
        expect(counter.count, beforePortrait + 1);

        orientation.value = Orientation.landscape;
        await binding.endOfFrame;
        expect(
          binding.configForView(primary)?.designSize,
          const Size(640, 360),
        );
        expect(counter.count, beforePortrait + 2);

        await binding.endOfFrame;
        expect(counter.count, beforePortrait + 2);
      } finally {
        binding.removeObserver(counter);
        orientation.dispose();
        revision.dispose();
      }
    },
  );
}
