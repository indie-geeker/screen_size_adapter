# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[0.1.0]: https://github.com/yourusername/screen_size_adapter/releases/tag/v0.1.0
[0.0.1]: https://github.com/yourusername/screen_size_adapter/releases/tag/v0.0.1
