import 'dart:math' as math;

import 'config.dart';
import 'screen_size_helper.dart';

/// 数字扩展，提供屏幕适配方法
///
/// 使用示例：
/// ```dart
/// Container(
///   width: 100.dp,   // 推荐：基础适配方法
///   height: 50.vw,   // 宽度方向适配
///   margin: EdgeInsets.only(top: 20.vh),  // 高度方向适配
/// )
/// ```
extension DimensionExt on num {
  /// 基础适配方法（推荐使用）
  ///
  /// 根据设计稿宽度等比例缩放，适用于大多数场景。
  ///
  /// 示例：
  /// ```dart
  /// Container(width: 100.dp, height: 50.dp)
  /// ```
  double get dp => vw;

  /// 宽度方向适配
  ///
  /// 根据屏幕宽度与设计稿宽度的比例进行缩放。
  /// 计算公式：this * (实际屏幕宽度 / 设计稿宽度)
  double get vw {
    final helper = ScreenSizeHelper.maybeInstance;
    if (helper == null || !helper.shouldApplyScale) {
      return toDouble();
    }
    final widthScale =
        helper.originMediaQueryData.size.width / helper.designSize.width;
    return this * widthScale / helper.scale;
  }

  /// Height-direction adaptation.
  ///
  /// Always uses the height axis independently:
  /// `this * (screenHeight / designHeight) / scale`
  ///
  /// This means on devices with non-design aspect ratios, `.vh` and `.vw`
  /// will return different values, correctly reflecting the device's shape.
  double get vh {
    final helper = ScreenSizeHelper.maybeInstance;
    if (helper == null || !helper.shouldApplyScale) {
      return toDouble();
    }
    final heightScale =
        helper.originMediaQueryData.size.height / helper.designSize.height;
    return this * heightScale / helper.scale;
  }

  /// 字体大小适配
  ///
  /// 根据屏幕缩放比例调整字体大小，确保文字在不同设备上保持相对一致的可读性。
  ///
  /// 使用示例：
  /// ```dart
  /// Text(
  ///   'Hello',
  ///   style: TextStyle(fontSize: 14.sp),
  /// )
  /// ```
  double get sp {
    final helper = ScreenSizeHelper.maybeInstance;
    if (helper == null) return toDouble();
    return switch (helper.config.textScaleMode) {
      ScreenSizeTextScaleMode.legacyScale => this * helper.scale,
      ScreenSizeTextScaleMode.design => toDouble(),
      ScreenSizeTextScaleMode.system => () {
          final fontSize = toDouble();
          if (fontSize == 0) return 0.0;
          return helper.originMediaQueryData.textScaler.scale(fontSize);
        }(),
    };
  }

  /// Min-dimension scaling for aspect-ratio-safe elements (circles, icons, avatars).
  ///
  /// Uses the smaller of width/height scale ratios to prevent distortion.
  ///
  /// Example:
  /// ```dart
  /// BorderRadius.circular(16.r)
  /// ```
  double get r {
    final helper = ScreenSizeHelper.maybeInstance;
    if (helper == null || !helper.shouldApplyScale) {
      return toDouble();
    }
    final widthScale =
        helper.originMediaQueryData.size.width / helper.designSize.width;
    final heightScale =
        helper.originMediaQueryData.size.height / helper.designSize.height;
    final minScale = math.min(widthScale, heightScale);
    return this * minScale / helper.scale;
  }

  /// Fraction of scaled screen width.
  ///
  /// Example:
  /// ```dart
  /// Container(width: 0.5.sw) // half the screen width
  /// ```
  ///
  /// If the adapter is not initialized, falls back to returning `toDouble()`
  /// (i.e. `0.5.sw == 0.5`) — the value is a fraction, not pixels.
  double get sw {
    final helper = ScreenSizeHelper.maybeInstance;
    if (helper == null) return toDouble();
    return this * helper.newMediaQueryData.size.width;
  }

  /// Fraction of scaled screen height.
  ///
  /// Example:
  /// ```dart
  /// Container(height: 0.3.sh) // 30% of screen height
  /// ```
  ///
  /// If the adapter is not initialized, falls back to returning `toDouble()`
  /// (i.e. `0.3.sh == 0.3`) — the value is a fraction, not pixels.
  double get sh {
    final helper = ScreenSizeHelper.maybeInstance;
    if (helper == null) return toDouble();
    return this * helper.newMediaQueryData.size.height;
  }
}
