part of '../screen_size_adapter.dart';

extension DimensionExt on num {
  
  // 专门用于宽度计算的扩展方法
  double get vw {
    final widthScale = ScreenSizeHelper.instance.originMediaQueryData.size.width / ScreenSizeHelper.instance.designSize.width;
    return this * widthScale / ScreenSizeHelper.instance.scale;
  }
  
  // 专门用于高度计算的扩展方法，横屏时使用屏幕高度与设计稿高度的比例
  double get vh {
    final isLandscape = ScreenSizeHelper.instance.originMediaQueryData.size.width > 
                       ScreenSizeHelper.instance.originMediaQueryData.size.height && 
                       !ScreenSizeHelper.instance._isDesktop;
    
    double heightScale;
    if (isLandscape) {
      // 横屏模式下，使用屏幕高度与设计稿高度的比例
      heightScale = ScreenSizeHelper.instance.originMediaQueryData.size.height / ScreenSizeHelper.instance.designSize.height;
    } else {
      // 竖屏模式下，保持与宽度相同的缩放比例
      heightScale = ScreenSizeHelper.instance.originMediaQueryData.size.width / ScreenSizeHelper.instance.designSize.width;
    }
    
    return this * heightScale / ScreenSizeHelper.instance.scale;
  }
  
  // double get sp => this * ScreenSizeHelper.instance.fontScale;
}