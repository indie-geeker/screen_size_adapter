part of '../screen_size_adapter.dart';

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
    final helper = ScreenSizeHelper.instance;
    if (!helper.shouldApplyScale) {
      return toDouble();
    }
    final widthScale =
        helper.originMediaQueryData.size.width / helper.designSize.width;
    return this * widthScale / helper.scale;
  }

  /// 高度方向适配
  ///
  /// 横屏模式下使用屏幕高度与设计稿高度的比例，
  /// 竖屏模式下与 [vw] 使用相同的缩放比例。
  ///
  /// 适用于需要按高度方向独立缩放的场景。
  double get vh {
    final helper = ScreenSizeHelper.instance;
    if (!helper.shouldApplyScale) {
      return toDouble();
    }
    final isLandscape = helper.isLandscape;

    double heightScale;
    if (isLandscape) {
      // 横屏模式下，使用屏幕高度与设计稿高度的比例
      heightScale =
          helper.originMediaQueryData.size.height / helper.designSize.height;
    } else {
      // 竖屏模式下，保持与宽度相同的缩放比例
      heightScale =
          helper.originMediaQueryData.size.width / helper.designSize.width;
    }

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
    final helper = ScreenSizeHelper.instance;
    return switch (helper.config.textScaleMode) {
      ScreenSizeTextScaleMode.legacyScale => this * helper.scale,
      ScreenSizeTextScaleMode.design => toDouble(),
    };
  }
}
