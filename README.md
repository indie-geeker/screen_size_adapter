# screen_size_adapter

[![pub package](https://img.shields.io/pub/v/screen_size_adapter.svg)](https://pub.dev/packages/screen_size_adapter)

简体中文 | [English](README_EN.md)

Flutter 屏幕适配方案，在 binding 层完成缩放工作。你的应用代码直接使用设计稿单位的纯数字；自定义 binding 会调整每个视图的 `devicePixelRatio`，让 Flutter 把视图当作设计稿尺寸来对待。原生支持多视图。

## 为什么要这样设计

大部分适配方案在 `num` 上添加 `100.dp` / `14.sp` 类的扩展方法，读取全局单例。这让代码中每个数字字面量都耦合到全局可变状态，无法独立做单元测试，也根本无法支持多视图应用（`num` 上的扩展拿不到 `BuildContext`）。

`screen_size_adapter` 把缩放放到 binding 层。它通过重写 `WidgetsFlutterBinding.createViewConfigurationFor`，按 view 把 `devicePixelRatio` 乘以计算后的 scale，使 Flutter 框架把每个视图视为设计稿尺寸。代码里读 `MediaQuery.sizeOf(context)` 拿到的就是 `designSize`；写 `Container(width: 100)` 就代表 100 个设计稿单位。完全不需要扩展方法。

## 快速开始

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

## 配置

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

`scaleAxis` 决定按哪个轴计算缩放系数：

- `width` — `scale = origin.width / design.width`。默认值，与历史行为一致。
- `height` — `scale = origin.height / design.height`。
- `shorter` — 取两个比值中的较小者。需要保持纵横比安全（无论设备纵横比如何，圆形依然是圆形）时使用。
- `longer` — 取较大者。配合 `maxScale` 用来限制过宽设备的过度缩放。

## 多视图

对于包含多个 `FlutterView` 的 Flutter 应用（桌面多窗口、通过 `View` widget 嵌入的视图、Add-to-App 等场景），需要为每个非主视图显式注册：

```dart
final binding = ScreenSizeWidgetsFlutterBinding.instance;
binding.attachView(
  view: secondaryView,
  designSize: const Size(800, 600),
  scaleAxis: ScaleAxis.shorter,
);

// 运行时更新：
binding.updateView(view: secondaryView, designSize: const Size(1024, 768));

// 视图销毁时清理：
binding.detachView(secondaryView);
```

主视图由 `ensureInitialized` 自动注册。未注册的视图保持 Flutter 的原生行为，不做任何缩放。

## 运行时更新

```dart
// 修改当前视图的设计稿尺寸：
ScreenSizeAdapter.setDesignSize(context, const Size(414, 896));

// 重置为视图当前的逻辑尺寸：
ScreenSizeAdapter.reset(context);

// 读取当前缩放系数（未启用缩放时返回 1.0）：
final scale = ScreenSizeAdapter.scaleOf(context);
```

`setDesignSize` 和 `reset` 通过 `View.of(context)` 解析当前激活的视图，因此能精确作用于调用方所在的 FlutterView——天然支持多视图正确性。

## 测试

在 widget 测试中无法使用生产环境的 binding（它与 `testWidgets` 所要求的 `AutomatedTestWidgetsFlutterBinding` 冲突）。请使用 `ScreenSizeTestEnvironment` 在 MediaQuery 层模拟 binding 的效果：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

testWidgets('layout in design units', (tester) async {
  await tester.pumpWidget(
    ScreenSizeTestEnvironment(
      config: const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
      simulatedDeviceSize: const Size(720, 1380),  // 模拟 2x 设备
      child: const MyApp(),
    ),
  );
  // 此时断言会基于已缩放到设计稿尺寸的 MediaQuery 运行。
});
```

如需对缩放计算做纯单元测试，可直接调用 `ScreenSizeAdapter.computeScale(...)`：

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

## 从 0.3.x 迁移

之前所有使用尺寸扩展的数字字面量，现在都直接写成纯数字。缩放工作完全交给 binding。

| 0.3.x | 0.4.0 |
|---|---|
| `100.dp`, `100.vw`, `100.vh`, `100.r` | `100` |
| `14.sp` | `14` |
| `0.5.sw`, `0.5.sh` | `MediaQuery.sizeOf(context).width * 0.5`（或 `.height`） |
| `EdgeInsets.all(16).w` | `const EdgeInsets.all(16)` |
| `BorderRadius.circular(16).w` | `BorderRadius.circular(16)` |
| `16.verticalSpace` | `const SizedBox(height: 16)` |
| `ScreenSizeAdapter.of(context).setDesignSize(s)` | `ScreenSizeAdapter.setDesignSize(context, s)` |
| `ScreenSizeHelper.instance.scale` | `ScreenSizeAdapter.scaleOf(context)` |
| `ScreenSizeHelper.instance.designSize` | `MediaQuery.sizeOf(context)` |

如果之前使用 `100.r` 来保持圆形不变形，请在初始化时配置 `scaleAxis: ScaleAxis.shorter`。如果之前使用了 `ScreenSizeTextScaleMode.legacyScale`，在 0.4.0 中字体会显得更小——legacy 模式实际上在 binding 缩放之上又叠加了一层，属于重复缩放。完整的破坏性变更清单见 `CHANGELOG.md`。

## 环境要求

- Flutter `>=3.27.0`
- Dart `^3.7.2`

## License

参见 `LICENSE`。
