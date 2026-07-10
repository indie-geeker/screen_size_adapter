# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2026-07-09

> **BREAKING:** This is the single public upgrade from pub.dev `0.2.0` to the
> config-first, binding-level API. All unreleased work since `0.2.0` is
> consolidated into this one public version.

### Added
- `ScreenSizeAdapterConfig` is the complete, per-view configuration object for
  design size, scale axis, desktop behavior, and scale bounds.
- Per-view registry APIs for host-created views: `attachView`, `updateView`,
  `detachView`, `resetView`, `scaleForView`, and `configForView` operate on
  `FlutterView` instances.
- `ScaleAxis` (`width`, `height`, `shorter`, `longer`) selects the scale
  calculation strategy.
- `ScreenSizeAdapterScope` supplies corrected `MediaQuery` data for explicit
  non-primary `View` subtrees. The default `runApp` view is wrapped
  automatically.
- `ScreenSizeAdapter.originSizeOf(context)` exposes the unscaled native logical
  size for responsive breakpoints.
- `ScreenSizeAdapter.setDesignSize`, `reset`, `scaleOf`, and `computeScale`
  provide context-based runtime controls and testable scale math.
- `ScreenSizeTestEnvironment` supports widget tests that cannot install the
  production binding.
- `ScreenSizeWidgetsFlutterBinding.instance` is the typed binding accessor for
  integration code.

### Changed
- **BREAKING:** `ScreenSizeWidgetsFlutterBinding.ensureInitialized` now takes
  one `ScreenSizeAdapterConfig` instead of a design size plus compatibility
  parameters.
- **BREAKING:** `attachView` and `updateView` now take a complete
  `ScreenSizeAdapterConfig`; public view inspection uses `FlutterView` rather
  than raw view IDs.
- **BREAKING:** Adaptation is performed through each view's
  `ViewConfiguration.devicePixelRatio`, so widgets use plain design-unit
  numbers.
- **BREAKING:** Removed the old widget-wrapper/singleton model, including
  `ScreenSizeWidget`, `ScreenSizeHelper`, `DesignSizeInheritedWidget`,
  `ScreenSizeTextScaleMode`, and `ScreenSizeAdapter.of` / `maybeOf`.
- **BREAKING:** Removed bare-number and geometry extensions such as `.dp`,
  `.sp`, `.sw`, `.w`, `.r`, `verticalSpace`, and `horizontalSpace`.
- `ScreenSizeAdapterConfig.maxScale` now defaults to `null`; pass an explicit
  cap when an application needs one. `copyWith` can clear nullable scale bounds
  with `clearMinScale` and `clearMaxScale`.
- `ScaleAxis.width` no longer swaps axes implicitly in landscape; choose
  `ScaleAxis.shorter` when aspect-safe scaling is required.
- Minimum supported Flutter is now `3.29.0`.

### Fixed
- `MediaQuery` now consistently reports design-unit size, device pixel ratio,
  padding, view padding, view insets, and system gesture insets.
- Pointer packets use the registered view's effective device pixel ratio.
- Gesture touch slop and display-feature bounds use the same design-unit
  coordinate system as pointer events and layout.
- `ScreenSizeAdapter.reset` clears scale bounds so it always restores native
  `1.0` scaling.
- Invalid design sizes and scale bounds, including non-finite values and a
  `minScale` greater than `maxScale`, fail fast before registry updates.
- README initialization order and API documentation now match the runtime
  contract.

### Migration
- Replace `ensureInitialized(size, config: ...)` with
  `ensureInitialized(ScreenSizeAdapterConfig(...))`.
- Replace `attachView` and `updateView` parameter lists with
  `config: ScreenSizeAdapterConfig(...)`; use `current.copyWith(...)` for a
  replacement configuration.
- Replace `scaleForViewId(viewId)` and `configForViewId(viewId)` with
  `scaleForView(view)` and `configForView(view)`.
- Replace extension-based sizing with plain values or standard Flutter APIs:
  `100.dp` becomes `100`, `14.sp` becomes `14`, and `0.5.sw` becomes
  `MediaQuery.sizeOf(context).width * 0.5`.
- Use `ScreenSizeAdapter.scaleOf(context)` for scale reads. Use
  `ScreenSizeAdapterScope` around manually mounted non-primary views.
- In `testWidgets`, wrap content with `ScreenSizeTestEnvironment` instead of
  installing the production binding.

## [0.2.0] - 2026-04-15

### Changed
- Improved the example app with runtime design-size controls and scale-bound
  information.
- Raised the minimum Flutter requirement to `3.16.0` for `textScaler` support.

## [0.1.0] - 2026-02-09

### Added
- Added `ScreenSizeAdapterConfig` and `ScreenSizeTextScaleMode` for `.sp`
  behavior control.
- Added `ScreenSizeAdapter.setDesignSize(context, size)` and
  `ScreenSizeAdapter.reset(context)` for runtime relayout-safe updates.
- Added `ScreenSizeHelper.initializeForTest(...)` for deterministic test setup.
- Added package and example smoke tests for adapter behavior.
- Added a CI workflow for static analysis and tests.

### Changed
- `ScreenSizeWidgetsFlutterBinding.ensureInitialized` supports optional config.
- Replaced `dart:io` platform detection with Flutter platform APIs.
- Updated Chinese and English README usage and FAQ sections.
- Mobile scaling remains enabled by default; desktop scaling is disabled by
  default.

### Fixed
- Fixed desktop scale recalculation after metrics changes.
- Fixed test documentation that recommended an initialization path which throws
  at runtime.

## [0.0.1] - 2025-11-13

### Added
- Initial release with design-size screen adaptation, responsive extension
  methods, cross-platform support, and Chinese and English documentation.

[0.3.0]: https://github.com/indie-geeker/screen_size_adapter/releases/tag/v0.3.0
[0.2.0]: https://github.com/indie-geeker/screen_size_adapter/releases/tag/v0.2.0
[0.1.0]: https://github.com/indie-geeker/screen_size_adapter/releases/tag/v0.1.0
[0.0.1]: https://github.com/indie-geeker/screen_size_adapter/releases/tag/v0.0.1
