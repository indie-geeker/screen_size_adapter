import 'dart:math' as math;
import 'dart:ui' show Size;

import 'package:flutter/foundation.dart';

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
