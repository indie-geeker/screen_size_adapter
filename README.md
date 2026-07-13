# screen_size_adapter

[![pub package](https://img.shields.io/pub/v/screen_size_adapter.svg)](https://pub.dev/packages/screen_size_adapter)

简体中文 | [English](README_EN.md)

Flutter 屏幕适配方案，在 binding 层完成缩放工作。你的应用代码直接使用设计稿单位的纯数字；自定义 binding 会调整视图的 `devicePixelRatio`。标准 `runApp` 单视图链路稳定可用；宿主创建的同 engine 二级视图接入属于实验性（experimental）能力。

## 为什么要这样设计

大部分适配方案在 `num` 上添加 `100.dp` / `14.sp` 类的扩展方法，读取全局单例。这让代码中每个数字字面量都耦合到全局可变状态，无法独立做单元测试，也无法根据调用方所在的 `BuildContext` 选择 view。

`screen_size_adapter` 把缩放放到 binding 层。它通过重写 `WidgetsFlutterBinding.createViewConfigurationFor`，把 view 的有效 `devicePixelRatio` 乘以计算后的 scale。适配后的精确坐标契约是 `MediaQuery.size = originSize / scale`。未触发 clamp 时只有 `scaleAxis` 选中的轴与 `designSize` 对齐；`minScale` / `maxScale` 生效后，两个维度都可能不等于 `designSize`。代码仍可直接写 `Container(width: 100)` 这样的设计单位纯数字，无需扩展方法。

## 快速开始

<!-- snippet:quick-start -->
```dart
import 'package:flutter/material.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  ScreenSizeWidgetsFlutterBinding.ensureInitialized(
    const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
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
<!-- /snippet:quick-start -->

## 配置

<!-- snippet:configuration -->
```dart
void configureAdapter() {
  ScreenSizeWidgetsFlutterBinding.ensureInitialized(
    const ScreenSizeAdapterConfig(
      designSize: Size(360, 690),
      scaleAxis: ScaleAxis.width,
      minScale: null,
      maxScale: null,
      enableDesktopScaling: false,
    ),
  );
}
```
<!-- /snippet:configuration -->

`scaleAxis` 决定按哪个轴计算缩放系数：

- `width` — `scale = origin.width / design.width`。默认值。**横竖屏行为**：竖屏时 origin.width 是设备短边，横屏时是长边，scale 跟着变大；好处是 `MediaQuery.width` 在两个方向都等于 `designSize.width`（"两个 180 的矩形永远充满宽度"）。代价是横屏下纵向内容会按同一 scale 放大，超出屏幕高度的部分需要靠 `SingleChildScrollView` 等手段处理 —— 见 [横竖屏](#横竖屏) 章节。如果你需要"长边对长边"的语义，监听 `OrientationBuilder` 调用 `ScreenSizeAdapter.setDesignSize` 显式切换设计稿即可。
- `height` — `scale = origin.height / design.height`。镜像 `width`：让 `MediaQuery.height == designSize.height`，但 `width` 方向不再固定。
- `shorter` — 取两个比值中的较小者。设计画布永远完整地塞进屏幕（不会有内容因 scale 过大而溢出），代价是宽度不再固定，**横竖屏下的 scale 不一致**。适合"必须保证设计稿全部可见"的场景（弹窗、全屏插画）。不适合"两个 180 永远充满宽度"。
- `longer` — 取较大者。设计画布至少有一条边贴满屏幕，另一条边会溢出。配合 `maxScale` 用于裁切式布局。

无论选择哪个轴，最终都遵循 `MediaQuery.size = originSize / scale`。未 clamp 时，`width` 只保证宽度对齐，`height` 只保证高度对齐，`shorter` / `longer` 只保证各自选中的比例关系。设置 `minScale` 或 `maxScale` 后，最终 scale 可能被截断，因此宽高都可能不等于 `designSize`。

## 实验性二级视图接入（experimental）

标准 `runApp` 的 implicit view 属于稳定支持范围。对于桌面多窗口、通过 `View` widget 嵌入的视图、Add-to-App 等同 engine 二级 `FlutterView` 场景，需要为每个宿主视图显式注册；这条接入路径目前是 experimental，不代表已完整验证或稳定支持多视图。

本包管理宿主已经创建的 `FlutterView`，不会自行创建桌面窗口或二级 view。同一 engine 下的真实二级 view 行为必须在对应桌面/Add-to-App 宿主中按 [`tool/verification/desktop_multi_view.md`](tool/verification/desktop_multi_view.md) 验证；registry 单元测试不能替代该验证。

<!-- snippet:multi-view-registry -->
```dart
void registerSecondaryView(FlutterView secondaryView) {
  final binding = ScreenSizeWidgetsFlutterBinding.instance;
  binding.attachView(
    view: secondaryView,
    config: const ScreenSizeAdapterConfig(
      designSize: Size(800, 600),
      scaleAxis: ScaleAxis.shorter,
    ),
  );

  binding.updateView(
    view: secondaryView,
    config: const ScreenSizeAdapterConfig(
      designSize: Size(1024, 768),
      scaleAxis: ScaleAxis.shorter,
    ),
  );

  binding.detachView(secondaryView);
}
```
<!-- /snippet:multi-view-registry -->

`ensureInitialized` 只自动注册 `PlatformDispatcher.implicitView`。如果宿主没有 implicit view，则不会猜测 `views.first`，每个宿主视图都必须显式调用 `attachView`。未注册的视图保持 Flutter 的原生行为，不做任何缩放。

非主视图（`runWidget` 或 `ViewAnchor` 自行挂载的 `View(...)`）不会自动得到正确的 `MediaQuery` 缩放，需要手动包一层 `ScreenSizeAdapterScope`：

<!-- snippet:multi-view-scope -->
```dart
Widget buildSecondaryView(FlutterView secondaryView) {
  return View(
    view: secondaryView,
    child: const ScreenSizeAdapterScope(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Text('Secondary view'),
      ),
    ),
  );
}
```
<!-- /snippet:multi-view-scope -->

`runApp` 链路下的主视图由 binding 的 `wrapWithDefaultView` 自动注入，应用代码无需任何包装。

## 横竖屏

未触发 scale bounds 时，默认 `ScaleAxis.width` 让 `MediaQuery.width` 在横竖屏下都等于 `designSize.width`。设计稿写的 `Container(width: 180)` 在 360 设计宽度下占半屏。**代价**是横竖屏 scale 不一致，纵向内容可能溢出；可按产品需求选择以下方式：

<!-- snippet:orientation -->
```dart
Future<void> lockPortraitAndRun() async {
  ScreenSizeWidgetsFlutterBinding.ensureInitialized(
    const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
  );
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ExampleApp());
}

Widget buildScrollableContent() => const SingleChildScrollView(
  child: Column(children: [Text('Scrollable content')]),
);

Widget buildOrientationAwareHome() => OrientationBuilder(
  builder: (context, orientation) {
    final design =
        orientation == Orientation.landscape
            ? const Size(640, 360)
            : const Size(360, 640);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScreenSizeAdapter.setDesignSize(context, design);
    });
    return const ExampleHome();
  },
);
```
<!-- /snippet:orientation -->

如果你想要"设计画布永远完整可见"（不溢出，但宽度可能不到屏宽）而非"宽度永远等于 designSize.width"，改用 `ScaleAxis.shorter` —— 这两种是不同的 trade-off，根据应用类型选。

## 响应式断点

适配生效后，`MediaQuery.sizeOf(context)` 返回 `originSize / scale`，它描述的是适配坐标而不是设备原生逻辑尺寸，因此不能作为手机/平板断点。响应式判断请读取 `originSizeOf`：

<!-- snippet:responsive-breakpoint -->
```dart
Widget responsiveLayout(BuildContext context) {
  final origin = ScreenSizeAdapter.originSizeOf(context);
  if (origin.shortestSide >= 600) {
    return const TabletLayout();
  }
  return const PhoneLayout();
}
```
<!-- /snippet:responsive-breakpoint -->

`originSizeOf` 等价于 `view.physicalSize / view.devicePixelRatio`，**不**经过 binding 缩放。

## 运行时更新

<!-- snippet:runtime-updates -->
```dart
void updateAdapter(BuildContext context) {
  ScreenSizeAdapter.setDesignSize(context, const Size(414, 896));
  ScreenSizeAdapter.reset(context);
  final scale = ScreenSizeAdapter.scaleOf(context);
  debugPrint('Current scale: $scale');
}
```
<!-- /snippet:runtime-updates -->

`setDesignSize` 和 `reset` 通过 `View.of(context)` 解析当前激活的视图，因此能精确作用于调用方所在的 FlutterView。`reset` 会清空该视图的 `minScale` / `maxScale`，保证回到原生 `1.0` 比例。

## 集成限制

- `ScreenSizeWidgetsFlutterBinding.ensureInitialized(...)` 必须在 `runApp` 前调用，并且要早于其它会初始化 `WidgetsBinding` 的代码。这个包通过自定义 binding 接管视图配置，不能在另一个 binding 已安装后再切换。
- 如果你的应用或测试框架已经使用其它自定义 `WidgetsBinding`，需要先评估谁负责 `createViewConfigurationFor` 和 pointer event 的处理；两个 binding 不能同时成为全局 binding。
- `testWidgets` 使用 Flutter 自带测试 binding，不能安装生产 binding。`ScreenSizeTestEnvironment` 只模拟适配后的 `MediaQuery`；布局断言请显式使用 `ScreenSizeTestViewport`。
- 非主 `FlutterView` 需要同时做两件事：调用 `ScreenSizeWidgetsFlutterBinding.instance.attachView(...)` 注册视图，并在该 `View` 子树外包 `ScreenSizeAdapterScope`。

## 测试

`ScreenSizeTestEnvironment` 是 MediaQuery-only 模拟，不会替换测试 binding 的根约束。`ScreenSizeTestViewport` 在其基础上为被包装子树提供与 `MediaQuery.size` 相同的紧约束，适合布局和 overlay 断言。两者都不会安装 `RenderView`、创建 engine-backed `FlutterView`、证明根 hit testing，也不会执行生产 pointer converter。

<!-- snippet:widget-test-helper -->
```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  testWidgets('layout in design units', (tester) async {
    await tester.pumpWidget(
      const ScreenSizeTestViewport(
        config: ScreenSizeAdapterConfig(designSize: Size(360, 690)),
        simulatedDeviceSize: Size(720, 1380),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Text('Hello'),
        ),
      ),
    );

    expect(find.text('Hello'), findsOneWidget);
  });
}
```
<!-- /snippet:widget-test-helper -->

如需对缩放计算做纯单元测试，可直接调用 `ScreenSizeAdapter.computeScale(...)`：

<!-- snippet:compute-scale-test -->
```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  test('scale on a 2x-wide device', () {
    final scale = ScreenSizeAdapter.computeScale(
      origin: const Size(720, 1280),
      config: const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
      isDesktop: false,
    );

    expect(scale, 2.0);
  });
}
```
<!-- /snippet:compute-scale-test -->

## 环境要求

- Flutter `>=3.29.2`
- Dart `^3.7.2`

## Security

This package does not process network data or secrets. For security-sensitive reports, please use the repository maintainer contact path if one is listed.

## License

参见 `LICENSE`。
