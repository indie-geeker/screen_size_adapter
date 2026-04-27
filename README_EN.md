# screen_size_adapter

[![pub package](https://img.shields.io/pub/v/screen_size_adapter.svg)](https://pub.dev/packages/screen_size_adapter)

[简体中文](README.md) | English

Binding-level screen-size adaptation for Flutter. Your app code writes plain numbers in design units; the custom binding scales each view's `devicePixelRatio` so Flutter treats it as the design size. Multi-view aware.

## Why this design

Most adapter packages add `100.dp` / `14.sp` extensions on `num` that read a global singleton. That couples every numeric literal in your codebase to mutable global state, can't be unit-tested in isolation, and fundamentally cannot support multi-view apps (extensions on `num` have no `BuildContext`).

`screen_size_adapter` does the scaling at the binding level instead. It overrides `WidgetsFlutterBinding.createViewConfigurationFor` per view, multiplying the view's `devicePixelRatio` by a computed scale so Flutter's framework treats every view as if it were the design size. Your code reads `MediaQuery.sizeOf(context)` and gets `designSize`; you write `Container(width: 100)` and that means 100 design units. No extension methods needed.

## Quick start

```dart
import 'package:flutter/material.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  ScreenSizeWidgetsFlutterBinding.ensureInitialized(
    const Size(360, 690),
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
  const Size(360, 690),
  config: const ScreenSizeAdapterConfig(
    designSize: Size(360, 690),
    scaleAxis: ScaleAxis.width,        // .width | .height | .shorter | .longer
    minScale: null,
    maxScale: 2.0,
    enableDesktopScaling: false,
  ),
);
```

`scaleAxis` controls which axis derives the scale factor:

- `width` — `scale = origin.width / design.width`. Default. **Note:** 0.3.x's mobile path silently switched to height-derived scaling in landscape; 0.4.0 does not. Use `shorter` if you want aspect-safe sizing across orientations.
- `height` — `scale = origin.height / design.height`.
- `shorter` — uses the smaller of the two ratios. Use this when you want aspect-safe sizing (circles stay circular regardless of device aspect ratio).
- `longer` — uses the larger ratio. Pairs with `maxScale` to clamp aggressively-wide devices.

## Multi-view

For Flutter apps with multiple `FlutterView`s (desktop multi-window, embedded views via `View` widgets, Add-to-App scenarios), register each non-primary view explicitly:

```dart
final binding = ScreenSizeWidgetsFlutterBinding.instance;
binding.attachView(
  view: secondaryView,
  designSize: const Size(800, 600),
  scaleAxis: ScaleAxis.shorter,
);

// Update at runtime:
binding.updateView(view: secondaryView, designSize: const Size(1024, 768));

// Clean up when the view goes away:
binding.detachView(secondaryView);
```

The primary view is registered automatically by `ensureInitialized`. Unregistered views fall through to stock Flutter behavior — no scaling.

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

// Reset to the view's current logical size:
ScreenSizeAdapter.reset(context);

// Read the current scale (returns 1.0 when no scaling is active):
final scale = ScreenSizeAdapter.scaleOf(context);
```

`setDesignSize` and `reset` resolve the active view via `View.of(context)`, so they correctly target the FlutterView that owns the calling widget — multi-view-correct by construction.

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

## Migration from 0.3.x

Every numeric literal that previously used a sizing extension becomes a plain number. The binding does the scaling.

| 0.3.x | 0.4.0 |
|---|---|
| `100.dp`, `100.vw`, `100.vh`, `100.r` | `100` |
| `14.sp` | `14` |
| `0.5.sw`, `0.5.sh` | `MediaQuery.sizeOf(context).width * 0.5` (or `.height`) |
| `EdgeInsets.all(16).w` | `const EdgeInsets.all(16)` |
| `BorderRadius.circular(16).w` | `BorderRadius.circular(16)` |
| `16.verticalSpace` | `const SizedBox(height: 16)` |
| `ScreenSizeAdapter.of(context).setDesignSize(s)` | `ScreenSizeAdapter.setDesignSize(context, s)` |
| `ScreenSizeHelper.instance.scale` | `ScreenSizeAdapter.scaleOf(context)` |
| `ScreenSizeHelper.instance.designSize` | `MediaQuery.sizeOf(context)` |

If you used `100.r` for aspect-safe circles, configure `scaleAxis: ScaleAxis.shorter`. If you used `ScreenSizeTextScaleMode.legacyScale`, fonts will appear smaller in 0.4.0 — the legacy mode was double-scaling. See `CHANGELOG.md` for the full breaking-change list.

## Requirements

- Flutter `>=3.27.0`
- Dart `^3.7.2`

## License

See `LICENSE`.
