# screen_size_adapter

[![pub package](https://img.shields.io/pub/v/screen_size_adapter.svg)](https://pub.dev/packages/screen_size_adapter)

[简体中文](README.md) | English

Binding-level screen-size adaptation for Flutter. Your app code writes plain numbers in design units and the custom binding adjusts the view's `devicePixelRatio`. The standard single-view `runApp` path is stable; same-engine secondary-view integration is experimental.

## Why this design

Most adapter packages add `100.dp` / `14.sp` extensions on `num` that read a global singleton. That couples every numeric literal in your codebase to mutable global state, can't be unit-tested in isolation, and fundamentally cannot support multi-view apps (extensions on `num` have no `BuildContext`).

`screen_size_adapter` does the scaling at the binding level instead. It overrides `WidgetsFlutterBinding.createViewConfigurationFor` per view, multiplying the view's `devicePixelRatio` by a computed scale so Flutter's framework treats every view as if it were the design size. Your code reads `MediaQuery.sizeOf(context)` and gets `designSize`; you write `Container(width: 100)` and that means 100 design units. No extension methods needed.

## Quick start

```dart
import 'package:flutter/material.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  ScreenSizeWidgetsFlutterBinding.ensureInitialized(
    const ScreenSizeAdapterConfig(
      designSize: Size(360, 690),
    ),
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

## Configuration

```dart
ScreenSizeWidgetsFlutterBinding.ensureInitialized(
  const ScreenSizeAdapterConfig(
    designSize: Size(360, 690),
    scaleAxis: ScaleAxis.width,        // .width | .height | .shorter | .longer
    minScale: null,
    maxScale: null,                    // no upper bound
    enableDesktopScaling: false,
  ),
);
```

`scaleAxis` controls which axis derives the scale factor:

- `width` — `scale = origin.width / design.width`. Default. **Orientation behavior:** in portrait `origin.width` is the device's short side; in landscape it's the long side, so the scale grows. The benefit is `MediaQuery.width == designSize.width` in both orientations ("two 180-wide rectangles always fill the width"). The cost is that vertical content scales by the same factor in landscape, so it can overflow the now-compressed view height — see [Orientation](#orientation). If you need "long-side-to-long-side" semantics, swap the design size on rotation via `OrientationBuilder` + `ScreenSizeAdapter.setDesignSize`.
- `height` — `scale = origin.height / design.height`. Mirror of `width`: pins `MediaQuery.height` to `designSize.height` instead.
- `shorter` — uses the smaller of the two ratios. The design canvas is always fully visible (no overflow), but the width is no longer pinned, **and the scale differs across orientations**. Suitable when "design must be fully visible" trumps "width consistency" (full-screen illustrations, modal dialogs). Not suitable for the "two 180s fill the width" contract.
- `longer` — uses the larger ratio. At least one design edge fills the screen; the other overflows. Pairs with `maxScale` for crop-style layouts.

## Experimental secondary-view integration

The standard implicit view used by `runApp` is the stable support boundary. Desktop multi-window, embedded `View` widgets, and Add-to-App scenarios with same-engine secondary `FlutterView`s require explicit registration. That path is experimental; it is not fully verified or advertised as stable multi-view support.

This package manages `FlutterView`s created by the host; it does not create desktop windows or secondary views. Validate a real same-engine secondary view in the relevant desktop or Add-to-App host using [`tool/verification/desktop_multi_view.md`](tool/verification/desktop_multi_view.md). Registry unit tests are not a substitute for that host-level check.

```dart
final binding = ScreenSizeWidgetsFlutterBinding.instance;
binding.attachView(
  view: secondaryView,
  config: const ScreenSizeAdapterConfig(
    designSize: Size(800, 600),
    scaleAxis: ScaleAxis.shorter,
  ),
);

// Update at runtime:
binding.updateView(
  view: secondaryView,
  config: const ScreenSizeAdapterConfig(
    designSize: Size(1024, 768),
    scaleAxis: ScaleAxis.shorter,
  ),
);

// Clean up when the view goes away:
binding.detachView(secondaryView);
```

`ensureInitialized` automatically registers only `PlatformDispatcher.implicitView`. If the host has no implicit view, the package does not guess `views.first`; every host-created view must call `attachView` explicitly. Unregistered views fall through to stock Flutter behavior — no scaling.

Non-primary views (those mounted via `runWidget` or `ViewAnchor`) do not get the auto-injected `MediaQuery` scaling. Wrap each subtree manually with `ScreenSizeAdapterScope`:

```dart
View(
  view: secondaryView,
  child: ScreenSizeAdapterScope(
    child: MyApp(),
  ),
)
```

The implicit (primary) view used by `runApp` is wrapped automatically by the binding's `wrapWithDefaultView`, so app code needs no manual wrapping.

## Orientation

The default `ScaleAxis.width` makes `MediaQuery.width` equal `designSize.width` in both portrait and landscape. So a `Container(width: 180)` written against a 360-design always covers half the screen width. The **trade-off** is an inconsistent scale across orientations — landscape uses a much larger scale (the device width is now the long side), and vertical content authored at the design's height will overflow the compressed landscape height. Pick one of the standard mitigations:

```dart
// 1) Simplest: lock to portrait (what 90%+ of apps in the ecosystem do)
void main() async {
  ScreenSizeWidgetsFlutterBinding.ensureInitialized(
    const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
  );
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

// 2) Make the vertical content scrollable
Scaffold(
  body: SingleChildScrollView(
    child: Column(children: [...]),
  ),
)

// 3) Swap the design size on rotation (recommended when you genuinely build for landscape)
OrientationBuilder(
  builder: (ctx, orientation) {
    final design = orientation == Orientation.landscape
        ? const Size(640, 360)
        : const Size(360, 640);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScreenSizeAdapter.setDesignSize(ctx, design);
    });
    return MyHomePage();
  },
)
```

If your goal is "the entire design canvas must be visible" (no overflow, possibly with empty space) rather than "width always matches `designSize.width`", switch to `ScaleAxis.shorter` — these are different trade-offs, choose by app type.

## Responsive breakpoints

Once the adapter is active, `MediaQuery.sizeOf(context)` reports the design size on every device — it can no longer distinguish a phone from a tablet. For breakpoint logic, read `originSizeOf` instead:

```dart
final origin = ScreenSizeAdapter.originSizeOf(context);  // native logical size
if (origin.shortestSide >= 600) {
  return TabletLayout();
} else {
  return PhoneLayout();
}
```

`originSizeOf` is equivalent to `view.physicalSize / view.devicePixelRatio` and is **not** scaled by the binding.

## Runtime updates

```dart
// Change the design size for the current view:
ScreenSizeAdapter.setDesignSize(context, const Size(414, 896));

// Reset to the view's current logical size, clear bounds, and restore scale=1:
ScreenSizeAdapter.reset(context);

// Read the current scale (returns 1.0 when no scaling is active):
final scale = ScreenSizeAdapter.scaleOf(context);
```

`setDesignSize` and `reset` resolve the active view via `View.of(context)`, so they target the FlutterView that owns the calling widget. `reset` clears that view's `minScale` / `maxScale` and guarantees native `1.0` scaling.

## Integration limits

- `ScreenSizeWidgetsFlutterBinding.ensureInitialized(...)` must run before `runApp` and before any code that initializes `WidgetsBinding`. This package works by installing a custom binding, so it cannot replace another binding after one is already active.
- If your app or test harness already uses another custom `WidgetsBinding`, decide which binding owns `createViewConfigurationFor` and pointer-event handling. Two bindings cannot both be the global binding.
- `testWidgets` uses Flutter's test binding, so it cannot install the production binding. Use `ScreenSizeTestEnvironment` to simulate the scaled `MediaQuery`.
- Non-primary `FlutterView`s need both steps: register the view with `ScreenSizeWidgetsFlutterBinding.instance.attachView(...)`, and wrap that `View` subtree with `ScreenSizeAdapterScope`.

## Testing

For widget tests, the production binding cannot be used (it conflicts with `AutomatedTestWidgetsFlutterBinding` that `testWidgets` requires). Use `ScreenSizeTestEnvironment` to simulate the binding's effect at the MediaQuery layer:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

testWidgets('layout in design units', (tester) async {
  await tester.pumpWidget(
    ScreenSizeTestEnvironment(
      config: const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
      simulatedDeviceSize: const Size(720, 1380),  // simulate a 2x device
      child: const MyApp(),
    ),
  );
  // Assertions run with MediaQuery scaled to the design size.
});
```

For pure unit tests of the math, call `ScreenSizeAdapter.computeScale(...)` directly:

```dart
test('scale on a 2x device', () {
  final s = ScreenSizeAdapter.computeScale(
    origin: const Size(720, 1280),
    config: const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
    isDesktop: false,
  );
  expect(s, 2.0);
});
```

## Requirements

- Flutter `>=3.29.2`
- Dart `^3.7.2`

## Security

This package does not process network data or secrets. For security-sensitive reports, please use the repository maintainer contact path if one is listed.

## License

See `LICENSE`.
