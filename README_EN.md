# screen_size_adapter

[![pub package](https://img.shields.io/pub/v/screen_size_adapter.svg)](https://pub.dev/packages/screen_size_adapter)

[简体中文](README.md) | English

Binding-level screen-size adaptation for Flutter. Your app code writes plain numbers in design units and the custom binding adjusts the view's `devicePixelRatio`. The standard single-view `runApp` path is stable; same-engine secondary-view integration is experimental.

## Why this design

Most adapter packages add `100.dp` / `14.sp` extensions on `num` that read a global singleton. That couples every numeric literal to mutable global state, cannot be unit-tested in isolation, and cannot select a view from the caller's `BuildContext`.

`screen_size_adapter` performs scaling at the binding level by overriding `WidgetsFlutterBinding.createViewConfigurationFor` and multiplying the view's effective `devicePixelRatio` by the computed scale. The exact coordinate contract is `MediaQuery.size = originSize / scale`. Without clamping, only the axis selected by `scaleAxis` aligns with `designSize`; when `minScale` or `maxScale` applies, neither dimension may equal `designSize`. App code can still use plain design-unit values such as `Container(width: 100)` without extension methods.

## Quick start

<!-- snippet:quick-start -->
```dart
import 'package:flutter/material.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  ScreenSizeWidgetsFlutterBinding.ensureInitialized(
    const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(home: HomePage());
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Container(
        width: 200,
        height: 100,
        padding: const EdgeInsets.all(16),
        color: Colors.blue,
        child: const Text('Hello', style: TextStyle(fontSize: 14)),
      ),
    ),
  );
}
```
<!-- /snippet:quick-start -->

## Configuration

<!-- snippet:configuration -->
```dart
void configureAdapter() {
  ScreenSizeWidgetsFlutterBinding.ensureInitialized(
    const ScreenSizeAdapterConfig(
      designSize: Size(360, 690),
      scaleAxis: ScaleAxis.width,
      minScale: null,
      maxScale: null,
      enableDesktopScaling: false,
    ),
  );
}
```
<!-- /snippet:configuration -->

`scaleAxis` controls which axis derives the scale factor:

- `width` — `scale = origin.width / design.width`. Default. **Orientation behavior:** in portrait `origin.width` is the device's short side; in landscape it's the long side, so the scale grows. The benefit is `MediaQuery.width == designSize.width` in both orientations ("two 180-wide rectangles always fill the width"). The cost is that vertical content scales by the same factor in landscape, so it can overflow the now-compressed view height — see [Orientation](#orientation). If you need "long-side-to-long-side" semantics, swap the design size on rotation via `OrientationBuilder` + `ScreenSizeAdapter.setDesignSize`.
- `height` — `scale = origin.height / design.height`. Mirror of `width`: pins `MediaQuery.height` to `designSize.height` instead.
- `shorter` — uses the smaller of the two ratios. The design canvas is always fully visible (no overflow), but the width is no longer pinned, **and the scale differs across orientations**. Suitable when "design must be fully visible" trumps "width consistency" (full-screen illustrations, modal dialogs). Not suitable for the "two 180s fill the width" contract.
- `longer` — uses the larger ratio. At least one design edge fills the screen; the other overflows. Pairs with `maxScale` for crop-style layouts.

Every axis follows `MediaQuery.size = originSize / scale`. Without clamping, `width` aligns only the width, `height` aligns only the height, and `shorter` / `longer` preserve their selected ratio relationship. When `minScale` or `maxScale` clamps the result, both dimensions may differ from `designSize`.

## Experimental secondary-view integration

The standard implicit view used by `runApp` is the stable support boundary. Desktop multi-window, embedded `View` widgets, and Add-to-App scenarios with same-engine secondary `FlutterView`s require explicit registration. That path is experimental; it is not fully verified or advertised as stable multi-view support.

This package manages `FlutterView`s created by the host; it does not create desktop windows or secondary views. Validate a real same-engine secondary view in the relevant desktop or Add-to-App host using [`tool/verification/desktop_multi_view.md`](tool/verification/desktop_multi_view.md). Registry unit tests are not a substitute for that host-level check.

<!-- snippet:multi-view-registry -->
```dart
void registerSecondaryView(FlutterView secondaryView) {
  final binding = ScreenSizeWidgetsFlutterBinding.instance;
  binding.attachView(
    view: secondaryView,
    config: const ScreenSizeAdapterConfig(
      designSize: Size(800, 600),
      scaleAxis: ScaleAxis.shorter,
    ),
  );

  binding.updateView(
    view: secondaryView,
    config: const ScreenSizeAdapterConfig(
      designSize: Size(1024, 768),
      scaleAxis: ScaleAxis.shorter,
    ),
  );

  binding.detachView(secondaryView);
}
```
<!-- /snippet:multi-view-registry -->

`ensureInitialized` automatically registers only `PlatformDispatcher.implicitView`. If the host has no implicit view, the package does not guess `views.first`; every host-created view must call `attachView` explicitly. Unregistered views fall through to stock Flutter behavior — no scaling.

Non-primary views (those mounted via `runWidget` or `ViewAnchor`) do not get the auto-injected `MediaQuery` scaling. Wrap each subtree manually with `ScreenSizeAdapterScope`:

<!-- snippet:multi-view-scope -->
```dart
Widget buildSecondaryView(FlutterView secondaryView) {
  return View(
    view: secondaryView,
    child: const ScreenSizeAdapterScope(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Text('Secondary view'),
      ),
    ),
  );
}
```
<!-- /snippet:multi-view-scope -->

The implicit (primary) view used by `runApp` is wrapped automatically by the binding's `wrapWithDefaultView`, so app code needs no manual wrapping.

## Orientation

Without scale-bound clamping, the default `ScaleAxis.width` makes `MediaQuery.width` equal `designSize.width` in portrait and landscape. A `Container(width: 180)` on a 360-wide design then occupies half the width. The trade-off is a different scale across orientations and possible vertical overflow. Choose the product-appropriate mitigation:

<!-- snippet:orientation -->
```dart
Future<void> lockPortraitAndRun() async {
  ScreenSizeWidgetsFlutterBinding.ensureInitialized(
    const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
  );
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ExampleApp());
}

Widget buildScrollableContent() => const SingleChildScrollView(
  child: Column(children: [Text('Scrollable content')]),
);

Widget buildOrientationAwareHome() => OrientationBuilder(
  builder: (context, orientation) {
    final design =
        orientation == Orientation.landscape
            ? const Size(640, 360)
            : const Size(360, 640);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScreenSizeAdapter.setDesignSize(context, design);
    });
    return const ExampleHome();
  },
);
```
<!-- /snippet:orientation -->

If your goal is "the entire design canvas must be visible" (no overflow, possibly with empty space) rather than "width always matches `designSize.width`", switch to `ScaleAxis.shorter` — these are different trade-offs, choose by app type.

## Responsive breakpoints

Once adaptation is active, `MediaQuery.sizeOf(context)` reports `originSize / scale`. It describes the adapted coordinate space, not the native logical device size, so breakpoint logic should read `originSizeOf` instead:

<!-- snippet:responsive-breakpoint -->
```dart
Widget responsiveLayout(BuildContext context) {
  final origin = ScreenSizeAdapter.originSizeOf(context);
  if (origin.shortestSide >= 600) {
    return const TabletLayout();
  }
  return const PhoneLayout();
}
```
<!-- /snippet:responsive-breakpoint -->

`originSizeOf` is equivalent to `view.physicalSize / view.devicePixelRatio` and is **not** scaled by the binding.

## Runtime updates

<!-- snippet:runtime-updates -->
```dart
void updateAdapter(BuildContext context) {
  ScreenSizeAdapter.setDesignSize(context, const Size(414, 896));
  ScreenSizeAdapter.reset(context);
  final scale = ScreenSizeAdapter.scaleOf(context);
  debugPrint('Current scale: $scale');
}
```
<!-- /snippet:runtime-updates -->

`setDesignSize` and `reset` resolve the active view via `View.of(context)`, so they target the FlutterView that owns the calling widget. `reset` clears that view's `minScale` / `maxScale` and guarantees native `1.0` scaling.

## Integration limits

- `ScreenSizeWidgetsFlutterBinding.ensureInitialized(...)` must run before `runApp` and before any code that initializes `WidgetsBinding`. This package works by installing a custom binding, so it cannot replace another binding after one is already active.
- If your app or test harness already uses another custom `WidgetsBinding`, decide which binding owns `createViewConfigurationFor` and pointer-event handling. Two bindings cannot both be the global binding.
- `testWidgets` uses Flutter's test binding, so it cannot install the production binding. `ScreenSizeTestEnvironment` simulates only the adapted `MediaQuery`; use `ScreenSizeTestViewport` explicitly for layout assertions.
- Non-primary `FlutterView`s need both steps: register the view with `ScreenSizeWidgetsFlutterBinding.instance.attachView(...)`, and wrap that `View` subtree with `ScreenSizeAdapterScope`.

## Testing

`ScreenSizeTestEnvironment` is MediaQuery-only and does not replace the test binding's root constraints. `ScreenSizeTestViewport` additionally gives its wrapped subtree tight constraints equal to `MediaQuery.size`, which is useful for layout and overlay assertions. Neither helper installs a `RenderView`, creates an engine-backed `FlutterView`, proves root hit testing, or executes the production pointer converter.

<!-- snippet:widget-test-helper -->
```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  testWidgets('layout in design units', (tester) async {
    await tester.pumpWidget(
      const ScreenSizeTestViewport(
        config: ScreenSizeAdapterConfig(designSize: Size(360, 690)),
        simulatedDeviceSize: Size(720, 1380),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Text('Hello'),
        ),
      ),
    );

    expect(find.text('Hello'), findsOneWidget);
  });
}
```
<!-- /snippet:widget-test-helper -->

For pure unit tests of the math, call `ScreenSizeAdapter.computeScale(...)` directly:

<!-- snippet:compute-scale-test -->
```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  test('scale on a 2x-wide device', () {
    final scale = ScreenSizeAdapter.computeScale(
      origin: const Size(720, 1280),
      config: const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
      isDesktop: false,
    );

    expect(scale, 2.0);
  });
}
```
<!-- /snippet:compute-scale-test -->

## Requirements

- Flutter `>=3.29.2`
- Dart `^3.7.2`

## Security

This package does not process network data or secrets. For security-sensitive reports, please use the repository maintainer contact path if one is listed.

## License

See `LICENSE`.
