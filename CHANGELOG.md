# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.5.0

### Added
- Config-first binding initialization with `ScreenSizeAdapterConfig`.
- Per-view registry APIs for apps with multiple `FlutterView` instances.
- Binding-level view scaling through `ViewConfiguration.devicePixelRatio`.
- `ScreenSizeAdapterScope` for corrected `MediaQuery` values in explicit `View`
  subtrees.
- Context-based runtime helpers for design-size updates, reset, origin-size
  reads, and scale reads.
- `ScreenSizeTestEnvironment` for widget tests that cannot install the
  production binding.
- Example app, package validation workflow, and release-readiness checklist.

### Changed
- Public initialization and per-view registration APIs use a complete
  `ScreenSizeAdapterConfig` instead of scattered compatibility parameters.
- Public view inspection accepts `FlutterView` rather than raw view IDs.
- `ScreenSizeAdapterConfig.copyWith` can explicitly clear nullable scale bounds.

### Fixed
- Design-size and scale-bound validation rejects non-finite or non-positive
  values before they enter the view registry.
- Scaled `MediaQuery` values now include size, device pixel ratio, padding,
  view padding, view insets, and system gesture insets.
