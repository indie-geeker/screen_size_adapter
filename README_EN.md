# Screen Size Adapter

English | [简体中文](README.md)

A lightweight, zero-intrusive Flutter screen adaptation solution that helps developers easily achieve consistent layouts across different screen sizes. It automatically adjusts UI element sizes through proportional calculation between design dimensions and actual device dimensions, ensuring good visual effects on all devices.

## ✨ Features

- 🎯 **Simple to Use**: Just 2 lines of code for screen adaptation setup
- 📐 **Design-Based Adaptation**: Proportional scaling based on design dimensions
- 🔧 **Rich Adaptation Methods**: Provides `.dp`, `.vw`, `.vh`, `.sp` extension methods
- 🔄 **Auto Handling**: Automatically handles orientation changes and different devices
- 💡 **Zero Intrusive**: Minimal changes to existing code
- 🖥️ **Cross-Platform**: Supports mobile and desktop (Windows, macOS, Linux)
- 📱 **Touch Event Adaptation**: Automatically handles scaled touch coordinates
- 🔒 **Type Safe**: Complete Dart type support and null-safety

## 📦 Installation

Add dependency in `pubspec.yaml`:

```yaml
dependencies:
  screen_size_adapter: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## 🚀 Quick Start

### 1. Initialize Adapter

Initialize the adapter at app entry with design dimensions (must be called before `runApp()`):

```dart
import 'package:flutter/material.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  // Initialize adapter with design dimensions (width x height)
  ScreenSizeWidgetsFlutterBinding.ensureInitialized(
    const Size(360, 640),
    config: const ScreenSizeAdapterConfig(
      textScaleMode: ScreenSizeTextScaleMode.legacyScale,
    ),
  );
  runApp(const MyApp());
}
```

### 2. Use Adaptation Methods

Use extension methods in layouts for size adaptation:

```dart
Container(
  width: 180.dp,     // Recommended: Basic adaptation method
  height: 100.dp,
  padding: EdgeInsets.all(16.dp),
  child: Text(
    'Adaptive Container',
    style: TextStyle(fontSize: 14.sp),  // Font size adaptation
  ),
)
```

## 📖 API Reference

### Extension Methods

All numeric types (`num`, `int`, `double`) can use these extension methods:

| Method | Description | Use Case | Example |
|--------|-------------|----------|---------|
| `.dp` | Basic adaptation (Recommended) | Most size scenarios | `width: 100.dp` |
| `.vw` | Width-based adaptation | Explicit width scaling | `width: 180.vw` |
| `.vh` | Height-based adaptation | Independent height scaling in landscape | `height: 100.vh` |
| `.sp` | Font size adaptation | Text size | `fontSize: 14.sp` |

### Calculation Rules

#### Portrait Mode
```
scale = Actual screen width / Design width
Example: iPhone 13 (390px) with design 360px
scale = 390 / 360 ≈ 1.083
100.dp = 100 * 1.083 = 108.3px
```

#### Landscape Mode
```
scale = Actual screen height / Design width
.vh uses screen height to design height ratio
```

### Public API

#### ScreenSizeHelper

```dart
// Get singleton instance
ScreenSizeHelper.instance

// Get design size
Size designSize = ScreenSizeHelper.instance.designSize;

// Get current scale
double scale = ScreenSizeHelper.instance.scale;

// Check if desktop platform
bool isDesktop = ScreenSizeHelper.instance.isDesktop;

// Check if landscape mode
bool isLandscape = ScreenSizeHelper.instance.isLandscape;

// Reset adapter (rarely used)
ScreenSizeHelper.instance.reset();
```

#### ScreenSizeAdapter (Runtime Control)

```dart
// Update design size in runtime and trigger relayout
ScreenSizeAdapter.setDesignSize(context, const Size(375, 667));

// Reset current adaptation state
ScreenSizeAdapter.reset(context);
```

## 💡 Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  ScreenSizeWidgetsFlutterBinding.ensureInitialized(const Size(360, 640));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Screen Size Adapter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen Adapter Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.dp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Screen Adaptation Example',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.dp),

            // Fixed size comparison
            _buildCard(
              title: 'Fixed Size (No Adaptation)',
              child: Container(
                width: 100,
                height: 100,
                color: Colors.red.shade200,
                alignment: Alignment.center,
                child: Text(
                  '100 x 100',
                  style: TextStyle(fontSize: 12.sp),
                ),
              ),
            ),
            SizedBox(height: 16.dp),

            // Using .dp adaptation
            _buildCard(
              title: 'Using .dp Adaptation (Recommended)',
              child: Container(
                width: 200.dp,
                height: 100.dp,
                color: Colors.blue.shade200,
                alignment: Alignment.center,
                child: Text(
                  '200.dp x 100.dp',
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
            ),
            SizedBox(height: 16.dp),

            // Responsive layout
            _buildCard(
              title: 'Responsive Layout',
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 80.dp,
                      color: Colors.green.shade200,
                      alignment: Alignment.center,
                      child: Text('Expanded', style: TextStyle(fontSize: 12.sp)),
                    ),
                  ),
                  SizedBox(width: 10.dp),
                  Container(
                    width: 100.dp,
                    height: 80.dp,
                    color: Colors.orange.shade200,
                    alignment: Alignment.center,
                    child: Text('100.dp', style: TextStyle(fontSize: 12.sp)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.dp),

            // Font adaptation
            _buildCard(
              title: 'Font Size Adaptation',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('12.sp Small Text', style: TextStyle(fontSize: 12.sp)),
                  SizedBox(height: 8.dp),
                  Text('14.sp Normal Text', style: TextStyle(fontSize: 14.sp)),
                  SizedBox(height: 8.dp),
                  Text('16.sp Medium Text', style: TextStyle(fontSize: 16.sp)),
                  SizedBox(height: 8.dp),
                  Text('20.sp Large Text', style: TextStyle(fontSize: 20.sp)),
                ],
              ),
            ),
            SizedBox(height: 16.dp),

            // Device info
            _buildCard(
              title: 'Device Information',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Design Size', '${ScreenSizeHelper.instance.designSize}'),
                  _buildInfoRow('Scale', '${ScreenSizeHelper.instance.scale.toStringAsFixed(3)}'),
                  _buildInfoRow('Is Desktop', '${ScreenSizeHelper.instance.isDesktop}'),
                  _buildInfoRow('Is Landscape', '${ScreenSizeHelper.instance.isLandscape}'),
                  _buildInfoRow('Screen Size', '${MediaQuery.of(context).size}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12.dp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.dp),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.dp),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }
}
```

## 🔧 Advanced Usage

### Orientation Adaptation

The library automatically handles orientation changes without extra configuration:

```dart
// In landscape mode, uses screen height to design width ratio
// In portrait mode, uses screen width to design width ratio

Container(
  width: 200.dp,   // Automatically adjusts based on orientation
  height: 100.vh,  // Uses independent height scaling in landscape
)
```

### Desktop Platform Support

Default behavior:
- Mobile: design-size scaling is enabled
- Desktop (Windows/macOS/Linux): global scaling is disabled (uses original window metrics)

If you want scaling on desktop, enable it in config:

```dart
ScreenSizeWidgetsFlutterBinding.ensureInitialized(
  const Size(360, 640),
  config: const ScreenSizeAdapterConfig(
    enableDesktopScaling: true,
  ),
);
```

### Getting Original MediaQuery Data

```dart
// Get original data before scaling
MediaQueryData originalData = ScreenSizeHelper.instance.originMediaQueryData;

// Get scaled data
MediaQueryData scaledData = ScreenSizeHelper.instance.newMediaQueryData;

// Use in widget (already scaled)
MediaQueryData data = MediaQuery.of(context);
```

### Runtime Design Size Changes

```dart
// Recommended: use runtime controller to trigger relayout
ScreenSizeAdapter.setDesignSize(context, const Size(375, 667));
```

### Text Scale Strategy

```dart
ScreenSizeWidgetsFlutterBinding.ensureInitialized(
  const Size(360, 640),
  config: const ScreenSizeAdapterConfig(
    // Desktop scaling is off by default; enable when needed.
    // enableDesktopScaling: true,

    // Compatibility mode: sp = value * scale
    textScaleMode: ScreenSizeTextScaleMode.legacyScale,
    // Design mode: sp = value
    // textScaleMode: ScreenSizeTextScaleMode.design,
  ),
);
```

## 📚 How It Works

By default, scaling is mainly applied on mobile; desktop keeps `scale = 1` unless `enableDesktopScaling` is enabled.

1. **Initialization Phase**
   - Records design dimensions (e.g., 360x640)
   - Gets actual device dimensions (e.g., 390x844)
   - Calculates scale: `scale = 390 / 360 = 1.083`

2. **Rendering Phase**
   - Intercepts rendering pipeline via custom `WidgetsFlutterBinding`
   - Adjusts `MediaQueryData`'s `devicePixelRatio`
   - Injects scaled `MediaQuery` into widget tree

3. **Layout Phase**
   - `.dp` / `.vw` / `.vh` methods calculate actual sizes based on scale
   - Example: `100.dp = 100 * 1.083 = 108.3px`

4. **Touch Handling**
   - Automatically handles touch event coordinate scaling
   - Ensures touch position matches visual display

## ⚠️ Notes

### Recommended Design Sizes

Use common design dimensions that match your actual designs:

```dart
// iOS Designs
Size(375, 667)   // iPhone SE/8
Size(390, 844)   // iPhone 14/15
Size(414, 896)   // iPhone 14 Plus

// Android Designs
Size(360, 640)   // Common baseline
Size(360, 780)   // Modern Android devices
Size(412, 915)   // Pixel devices
```

### Best Practices

✅ **Recommended**
```dart
// 1. Use .dp for most scenarios
width: 100.dp
height: 50.dp
padding: EdgeInsets.all(16.dp)

// 2. Use .sp for text
fontSize: 14.sp

// 3. Combine with responsive layouts
Row(
  children: [
    Container(width: 100.dp),
    Expanded(child: ...),  // Adaptive
  ],
)
```

❌ **Avoid**
```dart
// 1. Don't adapt all sizes (loses responsive capability)
Container(
  width: MediaQuery.of(context).size.width,  // Should stay full width
  height: 100.dp,  // This is fine
)

// 2. Don't double-adapt MediaQuery sizes
double screenWidth = MediaQuery.of(context).size.width.dp;  // ❌ Double adaptation
```

### FAQ

**Q: Why must initialization be before `runApp()`?**

A: Because we need to inject custom `WidgetsFlutterBinding` during Flutter engine initialization. If too late, we can't intercept the rendering pipeline.

**Q: How to handle unit tests?**

A: Call `ScreenSizeHelper.initializeForTest()` in tests. Example:
```dart
ScreenSizeHelper.initializeForTest(const Size(360, 640));
```

**Q: What's the difference between `.dp` and `.vw`?**

A: `.dp` is an alias of `.vw`. We recommend `.dp` as it's more intuitive. They are identical.

**Q: Will fonts be too large or small?**

A: Configure `ScreenSizeAdapterConfig.textScaleMode`:
- `legacyScale`: keeps old behavior (`sp = value * scale`)
- `design`: keeps design font size (`sp = value`)

**Q: Does it support iPad and large screens?**

A: Yes. The library automatically calculates scale based on actual screen size. However, large screens may benefit from responsive layouts rather than simple scaling.

## 🤝 Contributing

Issues and Pull Requests are welcome to help improve this library!

## 📄 License

MIT License

Copyright (c) 2025

---

**Related Documentation**
- [Chinese README](README.md)
- [CHANGELOG](CHANGELOG.md)
- [API Documentation](https://pub.dev/documentation/screen_size_adapter/latest/)
