import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

// Tests that exercise ScreenSizeAdapterScope under the real
// ScreenSizeWidgetsFlutterBinding. testWidgets cannot be used here because
// it would force AutomatedTestWidgetsFlutterBinding to initialize first.
void main() {
  late ScreenSizeWidgetsFlutterBinding binding;
  setUpAll(() {
    binding =
        ScreenSizeWidgetsFlutterBinding.ensureInitialized(const Size(360, 690))
            as ScreenSizeWidgetsFlutterBinding;
  });

  tearDown(() {
    final primary = binding.platformDispatcher.views.first;
    binding.attachView(view: primary, designSize: const Size(360, 690));
  });

  test('MediaQuery.sizeOf inside the scope reports designSize', () async {
    final primary = binding.platformDispatcher.views.first;
    final originSize = Size(
      primary.physicalSize.width / primary.devicePixelRatio,
      primary.physicalSize.height / primary.devicePixelRatio,
    );

    // Pick a designSize that yields a non-trivial scale on whatever
    // logical view-size the test harness reports.
    final designSize = Size(originSize.width / 2, originSize.height / 2);
    binding.attachView(view: primary, designSize: designSize);

    MediaQueryData? captured;
    double? capturedScale;
    binding.attachRootWidget(
      View(
        view: primary,
        child: ScreenSizeAdapterScope(
          child: Builder(
            builder: (ctx) {
              captured = MediaQuery.maybeOf(ctx);
              capturedScale = ScreenSizeAdapter.scaleOf(ctx);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    binding.scheduleWarmUpFrame();
    await Future<void>.delayed(Duration.zero);

    expect(captured, isNotNull);
    expect(capturedScale, isNotNull);
    expect(
      captured!.size.width * capturedScale!,
      closeTo(originSize.width, 0.01),
    );
    expect(
      captured!.size.height * capturedScale!,
      closeTo(originSize.height, 0.01),
    );
  });

  test(
    'MediaQuery.devicePixelRatio inside the scope reflects effectiveDpr',
    () async {
      final primary = binding.platformDispatcher.views.first;
      final originDpr = primary.devicePixelRatio;
      final originSize = Size(
        primary.physicalSize.width / primary.devicePixelRatio,
        primary.physicalSize.height / primary.devicePixelRatio,
      );
      final designSize = Size(originSize.width / 2, originSize.height / 2);
      binding.attachView(view: primary, designSize: designSize);

      MediaQueryData? captured;
      double? capturedScale;
      binding.attachRootWidget(
        View(
          view: primary,
          child: ScreenSizeAdapterScope(
            child: Builder(
              builder: (ctx) {
                captured = MediaQuery.maybeOf(ctx);
                capturedScale = ScreenSizeAdapter.scaleOf(ctx);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      binding.scheduleWarmUpFrame();
      await Future<void>.delayed(Duration.zero);

      expect(
        captured!.devicePixelRatio,
        closeTo(originDpr * capturedScale!, 0.001),
      );
    },
  );

  test('scope is a no-op when the view is not registered', () async {
    final primary = binding.platformDispatcher.views.first;
    binding.detachView(primary);

    MediaQueryData? captured;
    binding.attachRootWidget(
      View(
        view: primary,
        child: ScreenSizeAdapterScope(
          child: Builder(
            builder: (ctx) {
              captured = MediaQuery.maybeOf(ctx);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    binding.scheduleWarmUpFrame();
    await Future<void>.delayed(Duration.zero);

    final unscaledSize = Size(
      primary.physicalSize.width / primary.devicePixelRatio,
      primary.physicalSize.height / primary.devicePixelRatio,
    );
    expect(captured!.size, unscaledSize);
    expect(captured!.devicePixelRatio, primary.devicePixelRatio);
  });
}
