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
    maxScale: null,                    // 0.5.0 起默认无上限
    enableDesktopScaling: false,
  ),
);
```

`scaleAxis` 决定按哪个轴计算缩放系数：

- `width` — `scale = origin.width / design.width`。默认值。**横竖屏行为**：竖屏时 origin.width 是设备短边，横屏时是长边，scale 跟着变大；好处是 `MediaQuery.width` 在两个方向都等于 `designSize.width`（"两个 180 的矩形永远充满宽度"）。代价是横屏下纵向内容会按同一 scale 放大，超出屏幕高度的部分需要靠 `SingleChildScrollView` 等手段处理 —— 见 [横竖屏](#横竖屏) 章节。0.3.x 的移动端在横屏时会隐式改用高度推导（`origin.height / design.width`），0.4.0 起去除了这一行为；如果你需要"长边对长边"的旧语义，监听 `OrientationBuilder` 调用 `ScreenSizeAdapter.setDesignSize` 显式切换设计稿即可。
- `height` — `scale = origin.height / design.height`。镜像 `width`：让 `MediaQuery.height == designSize.height`，但 `width` 方向不再固定。
- `shorter` — 取两个比值中的较小者。设计画布永远完整地塞进屏幕（不会有内容因 scale 过大而溢出），代价是宽度不再固定，**横竖屏下的 scale 不一致**。适合"必须保证设计稿全部可见"的场景（弹窗、全屏插画）。不适合"两个 180 永远充满宽度"。
- `longer` — 取较大者。设计画布至少有一条边贴满屏幕，另一条边会溢出。配合 `maxScale` 用于裁切式布局。

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

非主视图（`runWidget` 或 `ViewAnchor` 自行挂载的 `View(...)`）不会自动得到正确的 `MediaQuery` 缩放，需要手动包一层 `ScreenSizeAdapterScope`：

```dart
View(
  view: secondaryView,
  child: ScreenSizeAdapterScope(
    child: MyApp(),
  ),
)
```

`runApp` 链路下的主视图由 binding 的 `wrapWithDefaultView` 自动注入，应用代码无需任何包装。

## 横竖屏

默认 `ScaleAxis.width` 让 `MediaQuery.width` 在横竖屏下都等于 `designSize.width`。也就是说设计稿写的 `Container(width: 180)`，在 360 设计宽度下永远占满半屏。**代价**是 scale 在两个方向不一致 —— 横屏 scale 远大于竖屏（因为设备宽度变成了长边），纵向内容会按同一 scale 放大，超出屏幕高度的部分要靠下面的手段之一处理：

```dart
// 1) 最简单：锁定竖屏（生态里 90%+ 应用的选择）
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  ScreenSizeWidgetsFlutterBinding.ensureInitialized(const Size(360, 690));
  runApp(const MyApp());
}

// 2) 让纵向内容可滚动
Scaffold(
  body: SingleChildScrollView(
    child: Column(children: [...]),
  ),
)

// 3) 横屏时切换设计稿（真要做横屏 UI 时推荐）
OrientationBuilder(
  builder: (ctx, orientation) {
    final design = orientation == Orientation.landscape
        ? const Size(640, 360)
        : const Size(360, 640);
    // 第一帧之后再切换，避免竖屏初始化抖动
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScreenSizeAdapter.setDesignSize(ctx, design);
    });
    return MyHomePage();
  },
)
```

如果你想要"设计画布永远完整可见"（不溢出，但宽度可能不到屏宽）而非"宽度永远等于 designSize.width"，改用 `ScaleAxis.shorter` —— 这两种是不同的 trade-off，根据应用类型选。

## 响应式断点

适配生效后，`MediaQuery.sizeOf(context)` 在所有设备上都返回设计尺寸 —— 你不能再用它来区分手机和平板。需要响应式判断时改读 `originSizeOf`：

```dart
final origin = ScreenSizeAdapter.originSizeOf(context);  // 设备原生逻辑尺寸
if (origin.shortestSide >= 600) {
  return TabletLayout();
} else {
  return PhoneLayout();
}
```

`originSizeOf` 等价于 `view.physicalSize / view.devicePixelRatio`，**不**经过 binding 缩放。

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
