import 'dart:ui' show FlutterView;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

// Tests that exercise ScreenSizeAdapterScope under the real
// ScreenSizeWidgetsFlutterBinding. testWidgets cannot be used here because
// it would force AutomatedTestWidgetsFlutterBinding to initialize first.
void main() {
  late ScreenSizeWidgetsFlutterBinding binding;
  setUpAll(() {
    binding = ScreenSizeWidgetsFlutterBinding.ensureInitialized(
      const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
    );
  });

  tearDown(() {
    final primary = binding.platformDispatcher.views.first;
    binding.attachView(
      view: primary,
      config: const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
    );
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
    binding.attachView(
      view: primary,
      config: ScreenSizeAdapterConfig(designSize: designSize),
    );

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
      binding.attachView(
        view: primary,
        config: ScreenSizeAdapterConfig(designSize: designSize),
      );

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

  test(
    'root constraints use origin size divided by aspect-mismatch scale',
    () async {
      final primary = binding.platformDispatcher.views.first;
      final originSize = Size(
        primary.physicalSize.width / primary.devicePixelRatio,
        primary.physicalSize.height / primary.devicePixelRatio,
      );
      final config = ScreenSizeAdapterConfig(
        designSize: Size(originSize.width / 2, originSize.height / 3),
        scaleAxis: ScaleAxis.width,
        enableDesktopScaling: true,
      );

      final constraints = await captureRootConstraints(
        binding,
        primary,
        config,
      );

      expect(constraints.maxWidth, closeTo(originSize.width / 2, 0.01));
      expect(constraints.maxHeight, closeTo(originSize.height / 2, 0.01));
      expect(
        constraints.maxHeight,
        isNot(closeTo(config.designSize.height, 0.01)),
      );
    },
  );

  test('root constraints use origin size divided by bounded scale', () async {
    final primary = binding.platformDispatcher.views.first;
    final originSize = Size(
      primary.physicalSize.width / primary.devicePixelRatio,
      primary.physicalSize.height / primary.devicePixelRatio,
    );
    final config = ScreenSizeAdapterConfig(
      designSize: Size(originSize.width / 4, originSize.height / 4),
      enableDesktopScaling: true,
      maxScale: 1.5,
    );

    final constraints = await captureRootConstraints(binding, primary, config);

    expect(constraints.maxWidth, closeTo(originSize.width / 1.5, 0.01));
    expect(constraints.maxHeight, closeTo(originSize.height / 1.5, 0.01));
    expect(constraints.biggest, isNot(config.designSize));
  });

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

  test('transitioning to scale 1 preserves the child state', () async {
    final primary = binding.platformDispatcher.views.first;
    final originSize = Size(
      primary.physicalSize.width / primary.devicePixelRatio,
      primary.physicalSize.height / primary.devicePixelRatio,
    );
    binding.attachView(
      view: primary,
      config: ScreenSizeAdapterConfig(
        designSize: originSize / 2,
        enableDesktopScaling: true,
      ),
    );
    final creations = _CreationCounter();

    binding.attachRootWidget(
      View(
        view: primary,
        child: ScreenSizeAdapterScope(child: _StateProbe(creations: creations)),
      ),
    );
    binding.scheduleWarmUpFrame();
    await Future<void>.delayed(Duration.zero);
    expect(creations.value, 1);

    binding.resetView(view: primary);
    binding.scheduleWarmUpFrame();
    await Future<void>.delayed(Duration.zero);

    expect(creations.value, 1);
  });
}

class _CreationCounter {
  int value = 0;
}

class _StateProbe extends StatefulWidget {
  const _StateProbe({required this.creations});

  final _CreationCounter creations;

  @override
  State<_StateProbe> createState() => _StateProbeState();
}

class _StateProbeState extends State<_StateProbe> {
  @override
  void initState() {
    super.initState();
    widget.creations.value++;
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

Future<BoxConstraints> captureRootConstraints(
  ScreenSizeWidgetsFlutterBinding binding,
  FlutterView view,
  ScreenSizeAdapterConfig config,
) async {
  binding.attachView(view: view, config: config);
  BoxConstraints? captured;
  binding.attachRootWidget(
    View(
      view: view,
      child: LayoutBuilder(
        builder: (context, constraints) {
          captured = constraints;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  binding.scheduleWarmUpFrame();
  await Future<void>.delayed(Duration.zero);
  return captured!;
}
