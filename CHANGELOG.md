# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `ScreenSizeWidgetsFlutterBinding.instance` typed accessor for multi-view
  integration code that needs the installed adapter binding.
- Lightweight `CONTRIBUTING.md` with local validation and release checklist.

### Changed
- README orientation-lock snippets now install
  `ScreenSizeWidgetsFlutterBinding` before setting preferred orientations, so
  copied code respects the binding initialization requirement.
- CI now checks formatting, example analysis, dartdoc, and pub publish dry-run.
- The pub package ignore list now excludes local agent/tooling files and lock
  files that are not needed by consumers.

### Fixed
- `attachView`, `updateView`, and `ensureInitialized` now reject non-positive or
  non-finite design sizes and scale bounds before they can enter view scaling.
- Dartdoc link warnings in public API comments.

## [0.5.0] - 2026-04-27

> ⚠️ **BREAKING (default behavior):** `ScreenSizeAdapterConfig.maxScale` default changed from `2.0` to `null` (no upper bound). This makes `ScaleAxis.width` produce a consistent `MediaQuery.width == designSize.width` in **both** portrait and landscape — previously the 2.0 cap silently capped large landscape devices and broke the cross-orientation width contract. Existing apps that relied on the 2.0 cap (typically to prevent oversized fonts on tablets / desktop) must restore it explicitly.

### Changed
- **BREAKING:** `ScreenSizeAdapterConfig.maxScale` default is now `null` (was `2.0`). With `ScaleAxis.width` (default), this restores the framework's stated contract: a design unit always represents `1 / designSize.width` of the current screen width, in any orientation. Apps that need the old behavior should pass `maxScale: 2.0` explicitly:
  ```dart
  ScreenSizeWidgetsFlutterBinding.ensureInitialized(
    const Size(360, 690),
    config: const ScreenSizeAdapterConfig(
      designSize: Size(360, 690),
      maxScale: 2.0, // restore pre-0.5.0 cap
    ),
  );
  ```
- `ScreenSizeWidgetsFlutterBinding.attachView`'s `maxScale` parameter no longer defaults to `2.0`; passes through to the config (so it's `null` unless specified).

### Migration
- If your app rendered correctly on phones but was visually compressed on tablets / desktops with the 0.4.x defaults, you were riding the 2.0 cap. Decide:
  - Want consistency across all screens (recommended): leave the new default; review tablet/desktop layouts since text and images will now scale by the device's full width ratio.
  - Want the old cap: set `maxScale: 2.0` explicitly.
- The example app's landscape validation message used 0.3.x's axis-swap semantics and reported false negatives even when adaptation was working. Fixed: it now checks `MediaQuery.width == designSize.width` consistently in both orientations.

### Notes on landscape with a portrait design
With `ScaleAxis.width` and no `maxScale` cap, landscape uses a larger scale than portrait (because the device width is the long side). One side effect: vertical content authored at the design's height will overflow the (now compressed) landscape height. This is the trade-off of single-scale adaptation; common mitigations:
- Lock to portrait via `SystemChrome.setPreferredOrientations` (most apps do this).
- Wrap content in `SingleChildScrollView` so vertical overflow becomes scrollable.
- Switch the design size on rotation: `ScreenSizeAdapter.setDesignSize(context, Size(640, 360))` inside an `OrientationBuilder`.

## [0.4.1] - 2026-04-27

### Fixed
- **`MediaQuery` now reports design-unit values.** In Flutter 3.27+ the `View` widget wraps its child with `MediaQuery.fromView(view: ...)`, which constructs `MediaQueryData` directly from `FlutterView.physicalSize / FlutterView.devicePixelRatio`. The binding's `createViewConfigurationFor` override could not influence that path, so `MediaQuery.sizeOf(context)` returned the unscaled native size — contradicting the README's claim that it equals `designSize`. The 0.4.0 migration guidance for `0.5.sw → MediaQuery.sizeOf(context).width * 0.5` was therefore broken in production, while `ScreenSizeTestEnvironment` masked the issue in tests.
- `SafeArea` over-padded by ~`scale` and `Scaffold.resizeToAvoidBottomInset` overshot keyboard insets by the same factor, because `MediaQuery.padding` / `viewInsets` were not divided by the per-view scale.

### Added
- `ScreenSizeAdapterScope` — `StatefulWidget` that wraps its subtree in a corrected `MediaQuery` (size, devicePixelRatio, padding, viewPadding, viewInsets, systemGestureInsets all consistent with the binding's per-view scale). Listens to `didChangeMetrics` so runtime changes via `setDesignSize` / `attachView` propagate immediately.
- Auto-injection via `ScreenSizeWidgetsFlutterBinding.wrapWithDefaultView` — apps started by `runApp` get the scope at the implicit view's root with no code change. Multi-view apps that mount additional `View` widgets (`runWidget` / `ViewAnchor`) should wrap each subtree manually with `ScreenSizeAdapterScope`.
- `ScreenSizeAdapter.originSizeOf(context)` — returns the unscaled native logical size (`view.physicalSize / view.devicePixelRatio`). Use this for responsive breakpoints (phone vs. tablet), since `MediaQuery.sizeOf` now always reports the design size and can't distinguish device classes.

### Changed
- `ScreenSizeTestEnvironment` now scales `padding`, `viewPadding`, `viewInsets`, and `systemGestureInsets` in addition to `size` / `devicePixelRatio`, so test behavior matches production.

## [0.4.0] - 2026-04-27

### Added
- `ScaleAxis` enum (`width`, `height`, `shorter`, `longer`) — selects which axis the binding uses to compute scale.
- `ScreenSizeWidgetsFlutterBinding.attachView` / `updateView` / `detachView` / `resetView` — explicit per-view registry for multi-view apps (desktop multi-window, embedded views, Add-to-App).
- `ScreenSizeWidgetsFlutterBinding.scaleForViewId` / `configForViewId` — per-view inspection (configForViewId is test-only).
- `ScreenSizeAdapter.setDesignSize(context, size)` / `reset(context)` / `scaleOf(context)` — context-resolving facade methods that operate on the FlutterView owning the calling widget.
- `ScreenSizeAdapter.computeScale(origin, config, isDesktop)` — public pure function for unit tests and preview math.
- `ScreenSizeTestEnvironment` widget — mimics the binding's scaling at the MediaQuery layer for widget tests under `AutomatedTestWidgetsFlutterBinding`.
- `ScreenSizeAdapterConfig.designSize` field — was a separate `ensureInitialized` argument in 0.3.x; now the canonical home.
- `ScreenSizeAdapterConfig.scaleAxis` field — defaults to `ScaleAxis.width`.

### Changed
- **BREAKING (architecture):** Per-view scale state lives in the binding's registry, keyed by `FlutterView.viewId`. Each view can have its own `ScreenSizeAdapterConfig`. The previous `ScreenSizeHelper` singleton is gone.
- **BREAKING (architecture):** `ScreenSizeWidgetsFlutterBinding.wrapWithDefaultView` no longer wraps with `ScreenSizeWidget` — the binding scales views via `ViewConfiguration.devicePixelRatio` directly. No widget-tree wrap is needed.
- `ScreenSizeAdapter.scaleOf(context)` is defensive — returns `1.0` when the active binding is not `ScreenSizeWidgetsFlutterBinding` (e.g. inside `testWidgets`). `setDesignSize` / `reset` throw a clear `StateError` in the same situation, directing callers to `ScreenSizeTestEnvironment`.
- **BREAKING (behavior):** Removed the implicit landscape axis-swap that 0.3.x's mobile path performed (it silently used `origin.height / design.width` in landscape under the default scale formula). 0.4.0's `ScaleAxis.width` is unconditional. Apps that depended on the old aspect-safe behavior should configure `scaleAxis: ScaleAxis.shorter` at `ensureInitialized` time.
- Added explicit minimum Flutter `>=3.27.0` constraint to `pubspec.yaml` (for stable multi-view APIs).

### Removed
- **BREAKING (API surface):** All bare-num extensions: `100.dp`, `100.vw`, `100.vh`, `100.r`, `14.sp`, `0.5.sw`, `0.5.sh`. The binding scales the view's `devicePixelRatio` directly; user code writes plain numbers in design units.
- **BREAKING (API surface):** `EdgeInsetsScaleExt` (`.w`, `.r`), `BorderRadiusScaleExt` (`.w`, `.r`), `SpacingExt` (`verticalSpace`, `horizontalSpace`). Use `const EdgeInsets.all(16)`, `BorderRadius.circular(16)`, `const SizedBox(height: 16)` directly.
- **BREAKING (API surface):** `MediaQueryDataExt.copyWithScale` — implementation detail.
- **BREAKING (API surface):** `ScreenSizeHelper` class (singleton) — replaced by per-view binding registry. Reads of `ScreenSizeHelper.instance.scale` become `ScreenSizeAdapter.scaleOf(context)`.
- **BREAKING (API surface):** `ScreenSizeWidget`, `ScreenSizeWidgetState`, `DesignSizeInheritedWidget` — no widget wrap needed; binding handles scaling at the framework level.
- **BREAKING (API surface):** `ScreenSizeTextScaleMode` enum and the `textScaleMode` config field — Flutter's native `MediaQuery.textScaler` propagates accessibility text scaling automatically.
- **BREAKING (API surface):** `ScreenSizeAdapter.of(context)` / `.maybeOf(context)` — no `State` to expose.

### Migration
- Every `100.dp` / `.vw` / `.vh` / `.r` becomes `100`. Every `14.sp` becomes `14`.
- Every `EdgeInsets.all(16).w` becomes `const EdgeInsets.all(16)`. Every `BorderRadius.circular(16).w` becomes `BorderRadius.circular(16)`.
- Every `0.5.sw` becomes `MediaQuery.sizeOf(context).width * 0.5`.
- Every `16.verticalSpace` becomes `const SizedBox(height: 16)`.
- `ScreenSizeAdapter.of(context).setDesignSize(s)` becomes `ScreenSizeAdapter.setDesignSize(context, s)`.
- Reads of `ScreenSizeHelper.instance.scale` become `ScreenSizeAdapter.scaleOf(context)`.
- Reads of `ScreenSizeHelper.instance.designSize` become `MediaQuery.sizeOf(context)` (post-binding it equals the design size).
- If you previously used `100.r` for aspect-safe circles, configure `scaleAxis: ScaleAxis.shorter` at `ensureInitialized` time.
- If you used `legacyScale` text mode, expect smaller fonts in 0.4.0 — the new behavior is correct (legacy mode double-scaled fonts on top of the binding's view scaling).
- For widget tests, wrap your `tester.pumpWidget` content in `ScreenSizeTestEnvironment(config: ..., simulatedDeviceSize: ..., child: ...)` — the production binding can't be installed under `testWidgets`.

## [0.3.0] - 2026-04-23

### Added
- `ScreenSizeAdapterConfig.minScale` — lower bound for the scale factor, symmetric with `maxScale`. Defaults to `null` to preserve prior behavior.
- `ScreenSizeAdapterConfig.copyWithMinScale(double?)` — escape hatch to set `minScale` back to `null`.
- `ScreenSizeHelper.maybeInstance` — non-throwing accessor, returns `null` when the adapter has not been initialized.
- `ScreenSizeHelper.isReady` — convenience boolean equivalent to `maybeInstance != null`.
- `ScreenSizeHelper.resetForTest()` — test-only reset of the singleton. No-op in release builds.
- `ScreenSizeHelper.computeScale(...)` — pure static function for computing the scale factor from inputs, shared by production and test paths.

### Changed
- `DimensionExt` getters (`dp`, `vw`, `vh`, `sp`, `r`, `sw`, `sh`) no longer throw `LateInitializationError` when called before `ensureInitialized`; they now return the raw value via `toDouble()` (or the passed-through fraction for `sw`/`sh`).
- **BREAKING (library layout):** The package now uses a modern `library + export` layout instead of `part of`. Consumers importing from `package:screen_size_adapter/src/...` must switch to `package:screen_size_adapter/screen_size_adapter.dart`.
- **BREAKING (API signature):** `MediaQueryDataExt.copyWithScale()` now requires a `double scale` argument. Previously it was parameterless and read `ScreenSizeHelper.instance.scale` internally. Callers must pass the scale explicitly: `mediaQueryData.copyWithScale(ScreenSizeHelper.instance.scale)`.

### Fixed
- `ScreenSizeAdapter.setDesignSize(context, ...)` no longer destroys descendant `State` objects. The previous implementation wrapped the subtree in a `KeyedSubtree` with a version-keyed `ValueKey`, which unmounted the entire subtree on every design-size change — losing form inputs, scroll positions, animation controllers, and `StreamSubscription`s. `InheritedWidget.updateShouldNotify` now drives dependent rebuilds without force-unmounting.
- `setup()` and `initializeForTest()` no longer duplicate the scale-math logic. Both delegate to the new pure `ScreenSizeHelper.computeScale`, eliminating drift between production and test paths.

### Removed
- **BREAKING (internal):** `DesignSizeInheritedWidget` is no longer part of the public API. It has moved to `lib/src/internal/` and is no longer exported. Callers must use `ScreenSizeAdapter.of(context)` or `ScreenSizeAdapter.maybeOf(context)` — both return the same `ScreenSizeWidgetState`.

### Migration notes
- Any caller that relied on `setDesignSize` triggering `dispose`/`initState` on descendants must now wrap the subtree in its own `KeyedSubtree` or swap keys explicitly.
- Replace `import 'package:screen_size_adapter/src/...';` with `import 'package:screen_size_adapter/screen_size_adapter.dart';`.
- Replace direct `DesignSizeInheritedWidget.of(context)` / `.maybeOf(context)` calls with `ScreenSizeAdapter.of(context)` / `.maybeOf(context)` — return type is unchanged.
- Update all `copyWithScale()` call sites to pass an explicit scale: `mediaQueryData.copyWithScale(ScreenSizeHelper.instance.scale)`.

## [0.1.0] - 2026-02-09

### Added

- Added `ScreenSizeAdapterConfig` and `ScreenSizeTextScaleMode` for `.sp` behavior control.
- Added `ScreenSizeAdapter.setDesignSize(context, size)` and `ScreenSizeAdapter.reset(context)` for runtime relayout-safe updates.
- Added `ScreenSizeHelper.initializeForTest(...)` for deterministic test setup.
- Added package and example smoke tests for adapter behavior.
- Added CI workflow to run static analysis and tests.

### Changed

- `ScreenSizeWidgetsFlutterBinding.ensureInitialized` now supports optional `config`.
- `ScreenSizeWidgetsFlutterBinding.ensureInitialized` now provides clearer error when another binding is already initialized.
- Replaced `dart:io Platform` detection with Flutter platform APIs for safer multi-platform behavior.
- Updated Chinese and English README usage and FAQ sections to match real runtime/test APIs.
- Mobile scaling remains enabled by default, while desktop scaling is disabled by default (`enableDesktopScaling = false`).

### Fixed

- Fixed desktop scale recalculation path so metrics changes no longer reuse stale scale.
- Fixed test documentation mismatch that previously recommended an initialization path that throws at runtime.

## [0.0.1] - 2025-11-13

### Added

#### Core Features
- ✨ Lightweight screen adaptation solution based on design dimensions
- 📐 Automatic proportional scaling for consistent UI across devices
- 🔄 Auto-detection and handling of orientation changes (portrait/landscape)
- 🖥️ Cross-platform support for mobile and desktop (Windows, macOS, Linux)

#### Extension Methods
- `.dp` - Basic adaptation method (recommended for most use cases)
- `.vw` - Width-based adaptation
- `.vh` - Height-based adaptation (independent scaling in landscape)
- `.sp` - Font size adaptation

#### Public API
- `ScreenSizeWidgetsFlutterBinding.ensureInitialized()` - Initialize adapter with design size
- `ScreenSizeHelper.instance` - Access singleton instance
- `ScreenSizeHelper.designSize` - Get design dimensions
- `ScreenSizeHelper.scale` - Get current scale ratio
- `ScreenSizeHelper.isDesktop` - Check if running on desktop platform
- `ScreenSizeHelper.isLandscape` - Check if in landscape mode
- `ScreenSizeHelper.originMediaQueryData` - Get original MediaQuery data
- `ScreenSizeHelper.newMediaQueryData` - Get scaled MediaQuery data

#### Developer Experience
- 📝 Complete dartdoc documentation for all public APIs
- 🔒 Full type safety with null-safety support
- ⚡ Zero-intrusive design requiring minimal code changes
- 📱 Automatic touch event coordinate scaling
- ❌ Friendly error messages when not properly initialized

#### Documentation
- 📖 Comprehensive README with examples and best practices
- 🌐 English and Chinese documentation
- 💡 Complete example application demonstrating all features
- 🎯 API reference with usage scenarios

### Technical Details

#### Architecture
- Custom `WidgetsFlutterBinding` to intercept Flutter rendering pipeline
- MediaQuery injection for automatic size adaptation
- Efficient scale calculation: `scale = actualWidth / designWidth`
- Smart orientation detection for mobile devices

#### Quality
- ✅ Zero Flutter analyze warnings
- 🧹 Clean codebase with no dead code
- 📊 ~90% documentation coverage
- 🔐 Runtime initialization checks with helpful error messages

### Notes

This is the initial release of Screen Size Adapter. The library provides a simple yet powerful way to adapt Flutter UIs across different screen sizes while maintaining design consistency.

**Minimum Requirements:**
- Flutter: >=1.17.0
- Dart SDK: ^3.7.2

**Recommended Usage:**
```dart
void main() {
  ScreenSizeWidgetsFlutterBinding.ensureInitialized(const Size(360, 640));
  runApp(const MyApp());
}

// In your widgets
Container(
  width: 100.dp,
  height: 50.dp,
  padding: EdgeInsets.all(16.dp),
  child: Text(
    'Hello',
    style: TextStyle(fontSize: 14.sp),
  ),
)
```

### Known Limitations

- Unit testing requires special configuration due to custom binding
- Runtime design size changes not recommended (use for special cases only)
- Large screens (tablets) may benefit more from responsive layouts than simple scaling

---

[0.4.0]: https://github.com/indie-geeker/screen_size_adapter/releases/tag/v0.4.0
[0.3.0]: https://github.com/indie-geeker/screen_size_adapter/releases/tag/v0.3.0
[0.1.0]: https://github.com/indie-geeker/screen_size_adapter/releases/tag/v0.1.0
[0.0.1]: https://github.com/indie-geeker/screen_size_adapter/releases/tag/v0.0.1
