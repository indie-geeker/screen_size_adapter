# screen_size_adapter

English | [简体中文](README_ZH.md)

Author Flutter pages in design units and scale the complete viewport uniformly for mobile windows.

**2.0 is a development release with breaking API changes.** It uses a root rendering transform and the standard Flutter binding, native DPR and pointer dispatcher. Native text geometry and wheel-distance compatibility remain limited by the Flutter SDK; this refactor does not claim to fix them.

For prerelease testing, explicitly select the version you intend to evaluate. Once `2.0.0-dev.1` is available on pub.dev, add:

```yaml
dependencies:
  screen_size_adapter: 2.0.0-dev.1
```

Before publication, use a local source checkout. The repository example uses a local path dependency. Version 1.0.0 uses the previous binding API; its setup differs from the 2.0 examples below.

## Quick start

Requires **Flutter 3.29.2+ / Dart 3.7.2+**. Add `screen_size_adapter` as a dependency, then wrap the complete MaterialApp or CupertinoApp once per FlutterView. Do not mount it inside MaterialApp.builder, a page, SafeArea or a partial container.

<!-- snippet:quick-start -->
```dart
import 'package:flutter/material.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  runApp(
    const ScreenSizeAdapter(
      config: ScreenSizeAdapterConfig(designSize: Size(375, 812)),
      child: MaterialApp(
        home: Scaffold(body: Center(child: SizedBox(width: 280, height: 64))),
      ),
    ),
  );
}
```
<!-- /snippet:quick-start -->

Use ordinary `WidgetsFlutterBinding.ensureInitialized()` if startup plugins need it. No custom binding is required.

Width scaling is the default: a 430-wide native logical window with a 375-wide design uses scale 430 / 375. A 280-unit box displays at about 321.1 native logical pixels. Both axes use the same scale. The reference design size does **not** force a page aspect ratio: layout size is native window size divided by scale.

## Configuration and updates

| Option | Behavior |
| --- | --- |
| `designSize` | Positive finite reference width and height |
| `ScaleAxis.width` (default) | Native width / design width, including after rotation |
| `ScaleAxis.height` | Native height / design height |
| `ScaleAxis.shorter` | Smaller ratio; fits the entire reference canvas |
| `ScaleAxis.longer` | Larger ratio; layout still uses the available viewport |
| `minScale` / `maxScale` | Optional positive lower / upper bounds |
| `enableDesktopScaling` | Defaults to false on Windows/macOS/Linux; enabled explicitly in the example |
| Widget `enabled` | false restores native layout at scale 1, bypassing scale bounds |

Own configuration in parent state and rebuild the same adapter. Its child topology stays mounted when crossing scale 1, retaining navigation, text and focus. Do not replace its Key or conditionally remove the adapter when toggling modes.

<!-- snippet:runtime-updates -->
```dart
class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool adapted = true;

  @override
  Widget build(BuildContext context) => ScreenSizeAdapter(
    enabled: adapted,
    config: const ScreenSizeAdapterConfig(designSize: Size(375, 812)),
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: Switch(
            value: adapted,
            onChanged: (value) => setState(() => adapted = value),
          ),
        ),
      ),
    ),
  );
}
```
<!-- /snippet:runtime-updates -->

Use `ScreenSizeAdapterConfig.copyWith` to update fields, with `clearMinScale` / `clearMaxScale` to remove bounds. `ScreenSizeAdapter.computeScale` is available as a pure calculation.

## Metrics and coordinates

<!-- snippet:read-metrics -->
```dart
class MetricsLabel extends StatelessWidget {
  const MetricsLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final metrics = ScreenSizeAdapter.of(context);
    return Text(
      'Window: ${metrics.originSize}, '
      'layout: ${metrics.designSize}, scale: ${metrics.scale}',
    );
  }
}
```
<!-- /snippet:read-metrics -->

- `ScreenSizeAdapter.of` / `ScreenSizeMetrics.of` subscribe to this View's metrics and throw outside an adapter; `ScreenSizeMetrics.maybeOf` returns null there.
- `config.designSize` is the reference design. `metrics.designSize` is the available layout size (`originSize / scale`), which can differ from that reference.
- `scaleOf` and `originSizeOf` subscribe to changes; outside an adapter they return 1 and the native logical View size.
- Layout constraints, MediaQuery size, safe areas, keyboard insets and display features use design units. Asset DPR is native DPR × scale. User text scaling and accessibility preferences are preserved.
- View and RenderView DPR remain native. `localToGlobal` returns native logical coordinates. Verify each plugin / platform-view coordinate contract independently.
- Flutter's render transform handles ordinary touch coordinates. Gesture thresholds remain in native logical units; do not divide them by the adapter scale again.

## Review the example

```sh
cd example
flutter pub get
flutter run
```

Toggle adapted / native mode on the same page. Open Settings to choose width, height, smaller-ratio or larger-ratio scaling; select a reference design and fixed portrait, fixed landscape or follow-window orientation. Changes apply together after confirmation. Compare a fixed box, circle and text; exercise the counter, input, dropdown and dialog. Rotate a device or resize the actual desktop window and repeat. See the [review checklist](example/README.md).

## SDK limitations and evidence boundaries

| Area | Current boundary |
| --- | --- |
| iOS native caret / selection | Official Flutter 3.47.2 still has incomplete local-glyph transforms under ancestor scaling, plus an engine direction issue affecting RTL |
| System text menu | Non-identity scaling retains the Flutter-menu policy. Shared selection anchors affect Flutter toolbars and forced native menus; this policy fixes neither those anchors nor UIKit geometry |
| Mouse wheel | Stock ListView / NestedScrollView scroll, but their visible distance varies with scale and fails native-distance acceptance |
| Windows multi-window | Configure one adapter per host-created View, with no global registry. Actual windows, cross-monitor DPI and IME still require host testing |
| Other native behavior | Device IME, autofill, accessibility, platform views, performance and release builds need device acceptance; widget tests are insufficient |
| Extreme scale bounds | Finite positive bounds can still overflow the derived layout or asset DPR. Use practical bounds; this prerelease does not yet reject every unrepresentable result |

The wheel behavior is a compatibility gap in default scrolling widgets: raw pointer deltas do not automatically follow rendering transforms. Explicit menu builders and custom scroll positions can address some local cases, but this package does not provide a complete replacement for default text or scrolling widgets.

Run the following commands from a source checkout. Package regression checks and SDK acceptance checks are separate; SDK test fixtures are excluded from the published package. Acceptance retains the correct expected behavior rather than treating a reproduced failure as a pass:

```sh
flutter test
flutter test tool/verification/sdk_coordinate_acceptance_test.dart tool/verification/sdk_framework_acceptance_test.dart
```

The second command still fails on the verified official 3.47.2 SDK. Green package CI alone is **not native release certification**. See [SDK acceptance](tool/verification/README.md) and [Windows multi-view verification](tool/verification/desktop_multi_view.md).

## Migrate from 1.0.0

| Previous usage | 2.0 replacement |
| --- | --- |
| `ScreenSizeWidgetsFlutterBinding.ensureInitialized(config)` | Standard binding, with ScreenSizeAdapter outside the entire app |
| `ScreenSizeAdapterScope` | Remove; the root adapter owns metrics; same-View nesting is rejected |
| `setDesignSize` / `reset` | Rebuild parent-owned config / enabled state |
| `attachView` / `updateView` / `detachView` and registry APIs | Host owns View lifecycle; each View mounts its own configured adapter |
| `ScreenSizeTestEnvironment` / `ScreenSizeTestViewport` | Standard testWidgets with the production adapter |
| Treating global positions as design units | Use native logical coordinates and RenderBox conversion where needed |

The production widget works directly with standard widget tests:

<!-- snippet:widget-test -->
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  testWidgets('design layout uses the real test view', (tester) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(1500, 1624);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ScreenSizeAdapter(
        config: const ScreenSizeAdapterConfig(
          designSize: Size(375, 812),
          enableDesktopScaling: true,
        ),
        child: Builder(
          builder: (context) {
            expect(ScreenSizeAdapter.scaleOf(context), 2);
            expect(MediaQuery.sizeOf(context), const Size(375, 406));
            return const SizedBox();
          },
        ),
      ),
    );
  });
}
```
<!-- /snippet:widget-test -->

[Contributing and verification](CONTRIBUTING.md) · [Changelog](CHANGELOG.md) · [MIT License](LICENSE)
