# screen_size_adapter

[English](README.md) | 简体中文

以设计稿尺寸编写 Flutter 页面，通过根视口等比缩放，让尺寸、文字和布局一起适应移动端窗口。

**2.0 开发版采用根视口方案，包含破坏性 API 变更。** 使用标准 Flutter binding，不修改原生 DPR、不替换指针分发。当前官方 SDK 在原生输入选区和滚轮距离上仍有兼容问题，见下方限制；本分支不是原生输入已经修复的发布承诺。

当前分支尚未发布；example 已使用本地 path 依赖，外部试用也需指向这份源码。

## 快速开始

Flutter 最低版本为 **3.29.2**，Dart 最低为 **3.7.2**。在应用依赖中添加 `screen_size_adapter`，再将完整 `MaterialApp` / `CupertinoApp` 放在适配器内部。每个 `FlutterView` 只放一个适配器；不要放在 `MaterialApp.builder`、页面、SafeArea 或局部容器内。

<!-- snippet:quick-start -->
```dart
import 'package:flutter/material.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  runApp(
    const ScreenSizeAdapter(
      config: ScreenSizeAdapterConfig(designSize: Size(375, 812)),
      child: MaterialApp(
        home: Scaffold(body: Center(child: SizedBox(width: 280, height: 64))),
      ),
    ),
  );
}
```
<!-- /snippet:quick-start -->

不需要自定义 binding。需要启动前初始化插件时，照常调用 `WidgetsFlutterBinding.ensureInitialized()`。

默认按宽度缩放。原始窗口宽 430，设计宽度 375 时，倍率为 430 / 375；代码中的宽 280 显示为约 321.1 个原生逻辑像素。X/Y 使用相同倍率，圆形保持圆形。设计尺寸用于计算倍率，**不会强制页面具有设计稿的宽高比**；可用布局尺寸始终为窗口原始逻辑尺寸除以倍率。

## 配置与动态切换

| 配置 | 行为 |
| --- | --- |
| `designSize` | 有限且大于零的设计参考宽高 |
| `ScaleAxis.width`（默认） | 窗口宽 / 设计宽；旋转后仍然按宽计算 |
| `ScaleAxis.height` | 窗口高 / 设计高 |
| `ScaleAxis.shorter` | 两个比值取较小值，完整设计画布可以放下 |
| `ScaleAxis.longer` | 两个比值取较大值；页面仍使用实际可用布局尺寸 |
| `minScale` / `maxScale` | 正数倍率下限 / 上限，可留空 |
| `enableDesktopScaling` | 默认 false，Windows/macOS/Linux 保持原生尺寸；example 显式开启用于对照 |
| `enabled`（Widget 参数） | false 时恢复原生布局，倍率恒为 1，不受倍率上下限影响 |

父组件持有配置状态，通过重建同一个 `ScreenSizeAdapter` 修改配置或 `enabled`。子树结构在倍率跨越 1 时保持一致，导航、文本和焦点能够保留。不要通过更换 Key 或条件移除适配器来切换模式。

<!-- snippet:runtime-updates -->
```dart
class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool adapted = true;

  @override
  Widget build(BuildContext context) => ScreenSizeAdapter(
    enabled: adapted,
    config: const ScreenSizeAdapterConfig(designSize: Size(375, 812)),
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: Switch(
            value: adapted,
            onChanged: (value) => setState(() => adapted = value),
          ),
        ),
      ),
    ),
  );
}
```
<!-- /snippet:runtime-updates -->

`ScreenSizeAdapterConfig.copyWith` 可更新设计尺寸等字段；`clearMinScale` / `clearMaxScale` 用于清除上下限。也可通过纯函数 `ScreenSizeAdapter.computeScale` 独立计算倍率。

## 尺寸与坐标

<!-- snippet:read-metrics -->
```dart
class MetricsLabel extends StatelessWidget {
  const MetricsLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final metrics = ScreenSizeAdapter.of(context);
    return Text(
      'Window: ${metrics.originSize}, '
      'layout: ${metrics.designSize}, scale: ${metrics.scale}',
    );
  }
}
```
<!-- /snippet:read-metrics -->

- `ScreenSizeAdapter.of` / `ScreenSizeMetrics.of` 订阅本 View 的指标；适配器外调用会报错，`maybeOf` 则返回 null。
- `scaleOf`、`originSizeOf` 也会响应变化；适配器外分别返回 1 和原始 View 逻辑尺寸。
- 子树的约束、`MediaQuery.size`、安全区、键盘 inset 和折叠屏区域使用设计单位；图片资源 DPR 为原生 DPR × 倍率，用户文字缩放和无障碍偏好保留。
- `View.of(context).devicePixelRatio` 和 RenderView 保持原生值。`localToGlobal` 使用原生逻辑坐标，不再与设计单位混用。插件和 platform view 自有的坐标协议需要单独验证。
- 普通触摸坐标由 Flutter 的渲染变换处理，手势阈值保持原生逻辑单位。不要再手动除以倍率。

## 审查 example

```sh
cd example
flutter pub get
flutter run
```

同一页面切换“适配 / 未适配”，设置面板可选择按宽度、按高度、较小或较大比例，搭配三组参考设计稿与固定竖向、固定横向或跟随窗口；修改草稿后点击应用统一生效。固定色块、圆形和文字便于观察比例；计数、输入框、下拉菜单和弹窗用于检查交互。旋转设备或调整桌面窗口后重复切换；没有用两个模拟手机容器代替真实窗口。完整操作见 [example/README.md](example/README.md)。

## SDK 限制与验证边界

| 项目 | 当前边界 |
| --- | --- |
| iOS 原生 caret / selection | 官方 Flutter 3.47.2 的祖先缩放路径仍存在局部字形几何未完整变换的问题，RTL 还涉及引擎方向丢失；不是切换架构后就自动修复 |
| 系统文字菜单 | 非 1 倍时沿用 Flutter 菜单策略；Flutter 工具栏与强制系统菜单共用的选区锚点也有坐标问题。该策略不能修复选区锚点或 UIKit 几何 |
| 鼠标滚轮 | 标准 ListView / NestedScrollView 在缩放后可滚动，但可见距离会随倍率变化，未满足原生距离一致性验收 |
| Windows 多窗口 | 每个宿主创建的 View 挂独立适配器；没有全局注册或共享配置。实际多窗口、跨屏 DPI、输入法仍需 Windows 宿主验收 |
| 其他原生能力 | Android/iOS 真机输入法、自动填充、辅助功能、platform view、性能和发行构建需设备验收；Widget 测试不能替代它们 |

纯 Flutter 控件、布局和包自身的回归测试与 SDK 兼容验收分开运行。兼容门禁保留正确期望，不将“成功复现错误”当通过：

```sh
flutter test
flutter test tool/verification/sdk_coordinate_acceptance_test.dart tool/verification/sdk_framework_acceptance_test.dart
```

第二条在已验证的官方 3.47.2 上仍会失败，因此**不能仅凭常规 CI 通过宣称所有原生能力可发布**。详见 [SDK 验收说明](tool/verification/README.md) 和 [Windows 多窗口清单](tool/verification/desktop_multi_view.md)。

## 从 binding 版本迁移

| 旧 API / 用法 | 2.0 用法 |
| --- | --- |
| `ScreenSizeWidgetsFlutterBinding.ensureInitialized(config: ...)` | 删除，改为普通 binding；完整 App 外包 `ScreenSizeAdapter` |
| `ScreenSizeAdapterScope` | 删除；指标由根适配器提供，不允许在同一 View 嵌套适配器 |
| `setDesignSize` / `reset` | 父状态更新 `config` / `enabled` 后重建 |
| `attachView` / `updateView` / `detachView` 等注册表 API | 由宿主管理 View 生命周期；每个 View 内独立配置适配器 |
| `ScreenSizeTestEnvironment` / `ScreenSizeTestViewport` | 使用标准 `testWidgets` 和实际适配器 |
| 将 global 坐标当作设计坐标 | 按原生逻辑坐标处理，必要时通过目标 RenderBox 转换 |

新 Widget 可以直接用于标准 Widget 测试：

<!-- snippet:widget-test -->
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  testWidgets('design layout uses the real test view', (tester) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(1500, 1624);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ScreenSizeAdapter(
        config: const ScreenSizeAdapterConfig(
          designSize: Size(375, 812),
          enableDesktopScaling: true,
        ),
        child: Builder(
          builder: (context) {
            expect(ScreenSizeAdapter.scaleOf(context), 2);
            expect(MediaQuery.sizeOf(context), const Size(375, 406));
            return const SizedBox();
          },
        ),
      ),
    );
  });
}
```
<!-- /snippet:widget-test -->

[贡献与验证流程](CONTRIBUTING.md) · [变更记录](CHANGELOG.md) · [MIT License](LICENSE)
