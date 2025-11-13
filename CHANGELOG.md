# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[0.0.1]: https://github.com/yourusername/screen_size_adapter/releases/tag/v0.0.1
