import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'section_card.dart';

/// 把 [mqSize]（经 adapter 缩放后的设计单位视口）与 [rawSize]
/// （绕过 adapter 的 raw 逻辑像素视口）按同一 thumbnail 比例缩进
/// `maxWidth` 宽 × `maxThumbHeight` 高的容器内。
///
/// 两 bezel 共享同一个 `scale`，保证比例公平。总宽 ≤ `maxWidth`，
/// 最高 ≤ `maxThumbHeight`。
///
/// 退化输入（任一边为 0 或负 / `maxWidth - gap` ≤ 0）返回零尺寸 +
/// `scale: 0.0`，调用方据此跳过渲染。
@visibleForTesting
({Size left, Size right, double scale}) computeBezels({
  required Size mqSize,
  required Size rawSize,
  required double maxWidth,
  double maxThumbHeight = 200,
  double gap = 16,
}) {
  final maxThumbWidthEach = (maxWidth - gap) / 2;
  final smallerVisualW = math.min(mqSize.width, rawSize.width);
  final smallerVisualH = math.min(mqSize.height, rawSize.height);
  final biggerVisualW = math.max(mqSize.width, rawSize.width);
  final biggerVisualH = math.max(mqSize.height, rawSize.height);
  if (smallerVisualW <= 0 ||
      smallerVisualH <= 0 ||
      maxThumbWidthEach <= 0) {
    return (left: Size.zero, right: Size.zero, scale: 0.0);
  }
  final thumbScale = math.min(
    maxThumbHeight / biggerVisualH,
    maxThumbWidthEach / biggerVisualW,
  );
  return (
    left: Size(mqSize.width * thumbScale, mqSize.height * thumbScale),
    right: Size(rawSize.width * thumbScale, rawSize.height * thumbScale),
    scale: thumbScale,
  );
}

/// "Adapter 开/关 孪生"对照实验区块。
///
/// 左 bezel 按 [MediaQuery.sizeOf]（adapter 注入的 scaled 视口）
/// 等比缩略；右 bezel 按 [FlutterView.physicalSize] / dpr（绕过
/// adapter 的 raw 逻辑像素视口）等比缩略。两 bezel 内画**字面
/// 相同的 mini-UI**——切 axis 时左侧变形、右侧不动，可视化
/// adapter 在做什么。
class AdapterCompareDemo extends StatefulWidget {
  const AdapterCompareDemo({super.key, required this.designSize});

  final Size designSize;

  @override
  State<AdapterCompareDemo> createState() => _AdapterCompareDemoState();
}

class _AdapterCompareDemoState extends State<AdapterCompareDemo>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final mqSize = MediaQuery.sizeOf(context);
    final view = View.of(context);
    final rawSize = Size(
      view.physicalSize.width / view.devicePixelRatio,
      view.physicalSize.height / view.devicePixelRatio,
    );
    final isDegenerate =
        (mqSize.width - rawSize.width).abs() < 0.5 &&
            (mqSize.height - rawSize.height).abs() < 0.5;

    return SectionCard(
      title: 'Adapter 开/关 孪生（同代码、对照实验）',
      subtitle: '左：adapter 接管缩放。右：模拟没装 adapter，按设备 raw px 渲染。',
      accent: Colors.indigo,
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final geom = computeBezels(
            mqSize: mqSize,
            rawSize: rawSize,
            maxWidth: constraints.maxWidth,
          );
          if (geom.scale <= 0) {
            return const Text(
              '⚠ 视口尺寸异常，无法渲染对照',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BezelTile(
                    label: 'adapter on · viewport '
                        '${mqSize.width.toStringAsFixed(0)}×'
                        '${mqSize.height.toStringAsFixed(0)} 设计单位',
                    bezelSize: geom.left,
                    canvasSize: mqSize,
                    accent: Colors.indigo,
                  ),
                  const SizedBox(width: 16),
                  _BezelTile(
                    label: 'adapter off · viewport '
                        '${rawSize.width.toStringAsFixed(0)}×'
                        '${rawSize.height.toStringAsFixed(0)} raw px',
                    bezelSize: geom.right,
                    canvasSize: rawSize,
                    accent: Colors.orange,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '设计稿 ${widget.designSize.width.toInt()}×${widget.designSize.height.toInt()}'
                  ' — Picker 改这个值会让左 bezel 变形（mq 跟着变），右 bezel 不变。',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '同一份代码 width: 280, height: 56——'
                '左侧（adapter 接管缩放）保持作者预期占比；'
                '右侧（无 adapter 模拟）按设备真实像素渲染。'
                '切换 ScaleAxis / 旋转设备时，左侧随之变形、右侧纹丝不动，'
                '这就是 adapter 的全部工作。',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              if (isDegenerate)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'ℹ 当前 scale=1.0（adapter 未在该 view 缩放），'
                    '两侧本就一致是预期。',
                    style: TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                ),
              if (geom.scale > 0 && geom.scale < 0.15)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'ℹ 窗口/视口太大，缩略图细节弱化。',
                    style: TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// 单个 bezel：固定外壳尺寸 [bezelSize]，内部按 [canvasSize] 的
/// "logical canvas" 解读 mini-UI 数字。两个 tile 用同一组 design-unit
/// 数字（顶栏 width=canvas.width / height=44，按钮 280×56 居中，
/// 头像 60 直径）——但 canvasSize 不同（左 = mq, 右 = raw），所以
/// 占比天差地别。
class _BezelTile extends StatelessWidget {
  const _BezelTile({
    required this.label,
    required this.bezelSize,
    required this.canvasSize,
    required this.accent,
  });

  final String label;
  final Size bezelSize;
  final Size canvasSize;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final s = bezelSize.width / canvasSize.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: bezelSize.width,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.black87),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: bezelSize.width,
          height: bezelSize.height,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: accent, width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRect(
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // 顶栏：满宽 × 44 design 单位
                Positioned(
                  left: 0,
                  top: 0,
                  width: bezelSize.width,
                  height: 44 * s,
                  child: Container(
                    color: accent.withValues(alpha: 0.85),
                  ),
                ),
                // 按钮卡：280×56，居中横向，距顶栏 16
                Positioned(
                  left: ((canvasSize.width - 280) / 2) * s,
                  top: (44 + 16) * s,
                  width: 280 * s,
                  height: 56 * s,
                  child: Container(
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.4),
                      borderRadius:
                          BorderRadius.circular(6 * s.clamp(0.0, 1.0)),
                    ),
                  ),
                ),
                // 头像圆：60 直径，offset (16, 顶栏+16+按钮高+16)
                Positioned(
                  left: 16 * s,
                  top: (44 + 16 + 56 + 16) * s,
                  width: 60 * s,
                  height: 60 * s,
                  child: Container(
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
