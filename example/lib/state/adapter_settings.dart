import 'package:flutter/widgets.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

const Size kPortraitDesign = Size(360, 690);
const Size kLandscapeDesign = Size(640, 360);

/// 全局可观察的适配设置：当前 [ScaleAxis]、当前 designSize、
/// 是否随方向自动切换设计稿。Picker 改一处，所有依赖该状态的
/// widget 通过 [ListenableBuilder] 感知更新。
class AdapterSettings extends ChangeNotifier {
  AdapterSettings({
    Size designSize = kPortraitDesign,
    ScaleAxis scaleAxis = ScaleAxis.width,
    bool autoSwapByOrientation = true,
    double? minScale,
    double? maxScale,
  }) : _designSize = designSize,
       _scaleAxis = scaleAxis,
       _autoSwapByOrientation = autoSwapByOrientation,
       _minScale = minScale,
       _maxScale = maxScale;

  Size _designSize;
  ScaleAxis _scaleAxis;
  bool _autoSwapByOrientation;
  double? _minScale;
  double? _maxScale;

  Size get designSize => _designSize;
  ScaleAxis get scaleAxis => _scaleAxis;
  bool get autoSwapByOrientation => _autoSwapByOrientation;
  double? get minScale => _minScale;
  double? get maxScale => _maxScale;

  void setDesignSize(Size value) {
    if (value == _designSize) return;
    _designSize = value;
    notifyListeners();
  }

  void setScaleAxis(ScaleAxis value) {
    if (value == _scaleAxis) return;
    _scaleAxis = value;
    notifyListeners();
  }

  void setAutoSwap(bool value) {
    if (value == _autoSwapByOrientation) return;
    _autoSwapByOrientation = value;
    notifyListeners();
  }

  void setScaleBounds({required double? minScale, required double? maxScale}) {
    if (minScale == _minScale && maxScale == _maxScale) return;
    _minScale = minScale;
    _maxScale = maxScale;
    notifyListeners();
  }
}
