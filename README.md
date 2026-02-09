# Screen Size Adapter

[English](README_EN.md) | 简体中文

一个轻量级、零侵入的 Flutter 屏幕适配解决方案，帮助开发者轻松实现不同屏幕尺寸下的一致性布局。通过设计稿尺寸与实际设备尺寸的比例计算，自动调整 UI 元素大小，使应用在各种设备上都能保持良好的视觉效果。

## ✨ 功能特点

- 🎯 **简单易用**：只需 2 行代码即可完成屏幕适配配置
- 📐 **设计稿适配**：基于设计稿尺寸进行等比例缩放
- 🔧 **丰富的适配方法**：提供 `.dp`、`.vw`、`.vh`、`.sp` 等多种扩展方法
- 🔄 **自动处理**：自动处理横竖屏切换和不同设备的适配
- 💡 **零侵入性**：对现有代码改动最小，无需修改现有布局代码
- 🖥️ **全平台支持**：兼容移动端和桌面平台（Windows、macOS、Linux）
- 📱 **触摸事件适配**：自动处理缩放后的触摸坐标
- 🔒 **类型安全**：完整的 Dart 类型支持和 null-safety

## 📦 安装

在 `pubspec.yaml` 文件中添加依赖：

```yaml
dependencies:
  screen_size_adapter: ^0.1.0
```

然后运行：

```bash
flutter pub get
```

## 🚀 快速开始

### 1. 初始化适配器

在应用入口处初始化适配器，设置设计稿尺寸（必须在 `runApp()` 之前调用）：

```dart
import 'package:flutter/material.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  // 初始化适配器，传入设计稿尺寸（宽度 x 高度）
  ScreenSizeWidgetsFlutterBinding.ensureInitialized(
    const Size(360, 640),
    config: const ScreenSizeAdapterConfig(
      textScaleMode: ScreenSizeTextScaleMode.legacyScale,
    ),
  );
  runApp(const MyApp());
}
```

### 2. 使用适配方法

在布局中使用扩展方法进行尺寸适配：

```dart
Container(
  width: 180.dp,     // 推荐：基础适配方法
  height: 100.dp,
  padding: EdgeInsets.all(16.dp),
  child: Text(
    '自适应容器',
    style: TextStyle(fontSize: 14.sp),  // 字体大小适配
  ),
)
```

## 📖 API 参考

### 扩展方法

所有数字类型（`num`、`int`、`double`）都可以使用以下扩展方法：

| 方法 | 说明 | 使用场景 | 示例 |
|------|------|----------|------|
| `.dp` | 基础适配（推荐） | 大多数尺寸场景 | `width: 100.dp` |
| `.vw` | 宽度方向适配 | 需要明确按宽度缩放 | `width: 180.vw` |
| `.vh` | 高度方向适配 | 横屏时需要独立高度缩放 | `height: 100.vh` |
| `.sp` | 字体大小适配 | 文字大小 | `fontSize: 14.sp` |

### 计算规则

#### 竖屏模式
```
scale = 实际屏幕宽度 / 设计稿宽度
例如：iPhone 13 (390px) 使用设计稿 360px
scale = 390 / 360 ≈ 1.083
100.dp = 100 * 1.083 = 108.3px
```

#### 横屏模式
```
scale = 实际屏幕高度 / 设计稿宽度
.vh 使用屏幕高度与设计稿高度的比例
```

### 公共 API

#### ScreenSizeHelper

```dart
// 获取单例实例
ScreenSizeHelper.instance

// 获取设计稿尺寸
Size designSize = ScreenSizeHelper.instance.designSize;

// 获取当前缩放比例
double scale = ScreenSizeHelper.instance.scale;

// 判断是否为桌面平台
bool isDesktop = ScreenSizeHelper.instance.isDesktop;

// 判断是否为横屏模式
bool isLandscape = ScreenSizeHelper.instance.isLandscape;

// 重置适配器（不常用）
ScreenSizeHelper.instance.reset();
```

#### ScreenSizeAdapter（运行时控制）

```dart
// 在 widget 树中动态更新设计稿尺寸（会触发重布局）
ScreenSizeAdapter.setDesignSize(context, const Size(375, 667));

// 重置当前适配状态
ScreenSizeAdapter.reset(context);
```

## 💡 完整示例

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
            // 标题
            Text(
              '屏幕适配示例',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.dp),

            // 固定尺寸对比
            _buildCard(
              title: '固定尺寸（不适配）',
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

            // 使用 .dp 适配
            _buildCard(
              title: '使用 .dp 适配（推荐）',
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

            // 响应式布局
            _buildCard(
              title: '响应式布局',
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

            // 文字适配
            _buildCard(
              title: '字体大小适配',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('12.sp 小号文字', style: TextStyle(fontSize: 12.sp)),
                  SizedBox(height: 8.dp),
                  Text('14.sp 正常文字', style: TextStyle(fontSize: 14.sp)),
                  SizedBox(height: 8.dp),
                  Text('16.sp 中号文字', style: TextStyle(fontSize: 16.sp)),
                  SizedBox(height: 8.dp),
                  Text('20.sp 大号文字', style: TextStyle(fontSize: 20.sp)),
                ],
              ),
            ),
            SizedBox(height: 16.dp),

            // 设备信息
            _buildCard(
              title: '设备信息',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('设计稿尺寸', '${ScreenSizeHelper.instance.designSize}'),
                  _buildInfoRow('缩放比例', '${ScreenSizeHelper.instance.scale.toStringAsFixed(3)}'),
                  _buildInfoRow('是否桌面端', '${ScreenSizeHelper.instance.isDesktop}'),
                  _buildInfoRow('是否横屏', '${ScreenSizeHelper.instance.isLandscape}'),
                  _buildInfoRow('屏幕尺寸', '${MediaQuery.of(context).size}'),
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

## 🔧 高级用法

### 横竖屏适配

库会自动处理横竖屏切换，无需额外配置：

```dart
// 在横屏模式下，使用屏幕高度与设计稿宽度的比例
// 竖屏模式下，使用屏幕宽度与设计稿宽度的比例

Container(
  width: 200.dp,   // 自动根据屏幕方向调整
  height: 100.vh,  // 横屏时使用独立的高度缩放
)
```

### 桌面平台支持

默认行为：
- 移动端：启用设计稿适配
- 桌面端（Windows/macOS/Linux）：关闭全局缩放（保留原始窗口尺寸）

如需开启桌面端缩放，可通过配置打开：

```dart
ScreenSizeWidgetsFlutterBinding.ensureInitialized(
  const Size(360, 640),
  config: const ScreenSizeAdapterConfig(
    enableDesktopScaling: true,
  ),
);
```

### 获取原始 MediaQuery 数据

```dart
// 获取缩放前的原始数据
MediaQueryData originalData = ScreenSizeHelper.instance.originMediaQueryData;

// 获取缩放后的数据
MediaQueryData scaledData = ScreenSizeHelper.instance.newMediaQueryData;

// 在 widget 中使用（已自动缩放）
MediaQueryData data = MediaQuery.of(context);
```

### 运行时更改设计稿尺寸

```dart
// 推荐：通过 ScreenSizeAdapter 触发重布局
ScreenSizeAdapter.setDesignSize(context, const Size(375, 667));
```

### 文字缩放策略

```dart
ScreenSizeWidgetsFlutterBinding.ensureInitialized(
  const Size(360, 640),
  config: const ScreenSizeAdapterConfig(
    // 桌面端默认不缩放，按需开启
    // enableDesktopScaling: true,

    // 兼容模式：sp = value * scale
    textScaleMode: ScreenSizeTextScaleMode.legacyScale,
    // 设计稿模式：sp = value
    // textScaleMode: ScreenSizeTextScaleMode.design,
  ),
);
```

## 📚 工作原理

默认情况下，缩放计算主要作用于移动端；桌面端默认 `scale = 1`（除非开启 `enableDesktopScaling`）。

1. **初始化阶段**
   - 记录设计稿尺寸（如 360x640）
   - 获取设备实际尺寸（如 390x844）
   - 计算缩放比例：`scale = 390 / 360 = 1.083`

2. **渲染阶段**
   - 通过自定义 `WidgetsFlutterBinding` 拦截渲染管道
   - 调整 `MediaQueryData` 的 `devicePixelRatio`
   - 注入缩放后的 `MediaQuery` 到 widget 树

3. **布局阶段**
   - `.dp` / `.vw` / `.vh` 方法根据缩放比例计算实际尺寸
   - 例如：`100.dp = 100 * 1.083 = 108.3px`

4. **触摸处理**
   - 自动处理触摸事件坐标的缩放
   - 确保触摸位置与视觉显示一致

## ⚠️ 注意事项

### 设计稿尺寸建议

推荐使用常见的设计稿尺寸，确保与实际设计稿保持一致：

```dart
// iOS 设计稿
Size(375, 667)   // iPhone SE/8
Size(390, 844)   // iPhone 14/15
Size(414, 896)   // iPhone 14 Plus

// Android 设计稿
Size(360, 640)   // 常用基准尺寸
Size(360, 780)   // 现代 Android 设备
Size(412, 915)   // Pixel 设备
```

### 使用最佳实践

✅ **推荐做法**
```dart
// 1. 大部分场景使用 .dp
width: 100.dp
height: 50.dp
padding: EdgeInsets.all(16.dp)

// 2. 文字使用 .sp
fontSize: 14.sp

// 3. 响应式布局结合使用
Row(
  children: [
    Container(width: 100.dp),
    Expanded(child: ...),  // 自适应
  ],
)
```

❌ **避免的做法**
```dart
// 1. 避免所有尺寸都适配（失去响应式能力）
Container(
  width: MediaQuery.of(context).size.width,  // 应该保持全宽
  height: 100.dp,  // 这里适配是合理的
)

// 2. 避免在 MediaQuery 尺寸上再次适配
double screenWidth = MediaQuery.of(context).size.width.dp;  // ❌ 重复适配
```

### 常见问题

**Q: 为什么初始化必须在 `runApp()` 之前？**

A: 因为需要在 Flutter 引擎初始化时注入自定义的 `WidgetsFlutterBinding`，晚了就无法拦截渲染管道。

**Q: 单位测试如何处理？**

A: 在测试中调用 `ScreenSizeHelper.initializeForTest()`。例如：
```dart
ScreenSizeHelper.initializeForTest(const Size(360, 640));
```

**Q: `.dp` 和 `.vw` 有什么区别？**

A: `.dp` 是 `.vw` 的别名，推荐使用 `.dp` 因为更直观。两者完全相同。

**Q: 字体会不会太大或太小？**

A: 可通过 `ScreenSizeAdapterConfig.textScaleMode` 选择策略：
- `legacyScale`：保持旧行为（`sp = value * scale`）
- `design`：保持设计稿字号（`sp = value`）

**Q: 是否支持 iPad 等大屏设备？**

A: 支持。库会根据实际屏幕尺寸自动计算缩放比例。但大屏设备可能需要考虑使用响应式布局而不是简单缩放。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来帮助改进这个库！

## 📄 许可证

MIT License

Copyright (c) 2025

---

**相关文档**
- [English README](README_EN.md)
- [CHANGELOG](CHANGELOG.md)
- [API Documentation](https://pub.dev/documentation/screen_size_adapter/latest/)
