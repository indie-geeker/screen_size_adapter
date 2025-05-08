# Screen Size Adapter

一个轻量级的 Flutter 屏幕适配解决方案，帮助开发者轻松实现不同屏幕尺寸下的一致性布局。通过设计稿尺寸与实际设备尺寸的比例计算，自动调整 UI 元素大小，使应用在各种设备上都能保持良好的视觉效果。

## 功能特点

- **简单易用**：只需几行代码即可完成屏幕适配配置
- **设计稿适配**：基于设计稿尺寸进行等比例缩放
- **扩展方法**：提供便捷的 `.dp` 扩展方法用于尺寸转换
- **自动处理**：自动处理横竖屏切换和不同设备的适配
- **无侵入性**：对现有代码改动最小
- **支持桌面平台**：兼容 Windows、macOS 和 Linux 平台

## 安装

在 `pubspec.yaml` 文件中添加依赖：

```yaml
dependencies:
  screen_size_adapter: ^1.0.0
```

然后运行：

```bash
flutter pub get
```

## 基本使用

### 1. 初始化

在应用入口处初始化适配器，设置设计稿尺寸：

```dart
import 'package:flutter/material.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  // 初始化适配器，传入设计稿尺寸（宽度和高度）
  ScreenSizeWidgetsFlutterBinding.ensureInitialized(Size(360, 640));
  runApp(const MyApp());
}
```

### 2. 使用 dp 扩展方法

在布局中使用 `.dp` 扩展方法进行尺寸适配：

```dart
Container(
  // 使用 dp 扩展方法，会根据屏幕宽度与设计稿宽度的比例自动计算实际尺寸
  width: 180.dp,
  height: 100.dp,
  color: Colors.blue,
  child: Text('自适应宽高'),
)
```

## 高级用法

### 横竖屏适配

库会自动处理横竖屏切换，无需额外配置。在横屏模式下，会使用屏幕高度与设计稿宽度的比例进行计算。

### 桌面平台支持

在桌面平台上，库会自动检测并应用适当的缩放比例。

```dart
// 桌面平台检测在初始化时自动完成
if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
  _isDesktop = true;
}
```

### 自定义缩放逻辑

如果需要自定义缩放逻辑，可以直接使用 `ScreenSizeHelper` 类：

```dart
// 获取当前缩放比例
double scale = ScreenSizeHelper.instance.scale;

// 获取原始的 MediaQueryData
MediaQueryData originalData = ScreenSizeHelper.instance.originMediaQueryData;

// 获取缩放后的 MediaQueryData
MediaQueryData scaledData = ScreenSizeHelper.instance.newMediaQueryData;
```

## 完整示例

```dart
import 'package:flutter/material.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  ScreenSizeWidgetsFlutterBinding.ensureInitialized(Size(360, 640));
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
      ),
      home: const MyHomePage(title: 'Screen Size Adapter Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              // 固定尺寸，不会随屏幕变化
              width: 100,
              height: 100,
              color: Colors.green,
              child: Center(child: Text('固定尺寸: 100x100')),
            ),
            SizedBox(height: 20.dp),
            Container(
              // 使用 dp 进行适配，会随屏幕大小等比例缩放
              width: 200.dp,
              height: 100.dp,
              color: Colors.blue,
              child: Center(child: Text('自适应尺寸: 200.dp x 100.dp')),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 工作原理

1. 初始化时，库会记录设计稿尺寸和当前设备的实际尺寸
2. 计算缩放比例 `scale = 实际屏幕宽度 / 设计稿宽度`
3. 当使用 `.dp` 扩展方法时，会将数值乘以缩放比例，得到适配后的实际尺寸
4. 库内部会处理 MediaQuery 的调整，确保其他使用 MediaQuery 的组件也能正确工作

## 注意事项

- 设计稿尺寸应该与实际设计稿保持一致，推荐使用标准尺寸如 360x640、375x667 等
- 在某些特殊情况下，可能需要单独处理特定设备的适配问题
- 文本大小的缩放可能需要额外考虑可读性问题

## 贡献

欢迎提交 Issue 和 Pull Request 来帮助改进这个库。

## 许可证

MIT
