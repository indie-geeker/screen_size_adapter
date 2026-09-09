import 'package:flutter/widgets.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

enum DesignOrientation { portrait, landscape, followWindow }

extension ScaleAxisLabel on ScaleAxis {
  String get label => switch (this) {
    ScaleAxis.width => '按宽度',
    ScaleAxis.height => '按高度',
    ScaleAxis.shorter => '较小比例',
    ScaleAxis.longer => '较大比例',
  };
}

extension DesignOrientationLabel on DesignOrientation {
  String get label => switch (this) {
    DesignOrientation.portrait => '固定竖向',
    DesignOrientation.landscape => '固定横向',
    DesignOrientation.followWindow => '跟随窗口',
  };
}

/// Example choices only; the package remains responsible for scale calculation.
@immutable
class ComparisonSettings {
  const ComparisonSettings({
    this.axis = ScaleAxis.width,
    this.referenceSize = const Size(375, 812),
    this.orientation = DesignOrientation.portrait,
  });

  static const presets = [Size(320, 568), Size(375, 812), Size(430, 932)];

  final ScaleAxis axis;
  final Size referenceSize;
  final DesignOrientation orientation;

  ComparisonSettings copyWith({
    ScaleAxis? axis,
    Size? referenceSize,
    DesignOrientation? orientation,
  }) => ComparisonSettings(
    axis: axis ?? this.axis,
    referenceSize: referenceSize ?? this.referenceSize,
    orientation: orientation ?? this.orientation,
  );

  Size designSizeFor(Size window) {
    final landscape = switch (orientation) {
      DesignOrientation.portrait => false,
      DesignOrientation.landscape => true,
      DesignOrientation.followWindow => window.width > window.height,
    };
    return landscape ? referenceSize.flipped : referenceSize;
  }

  ScreenSizeAdapterConfig configFor(Size window) => ScreenSizeAdapterConfig(
    designSize: designSizeFor(window),
    scaleAxis: axis,
    enableDesktopScaling: true,
  );

  double scaleFor(Size window, {required bool adapted}) =>
      adapted
          ? ScreenSizeAdapter.computeScale(
            origin: window,
            config: configFor(window),
            isDesktop: false,
          )
          : 1;

  String calculationFor(Size window) {
    final design = designSizeFor(window);
    final width =
        '${formatNumber(window.width)} ÷ ${formatNumber(design.width)}';
    final height =
        '${formatNumber(window.height)} ÷ ${formatNumber(design.height)}';
    return switch (axis) {
      ScaleAxis.width => width,
      ScaleAxis.height => height,
      ScaleAxis.shorter || ScaleAxis.longer =>
        '$width = ${(window.width / design.width).toStringAsFixed(3)}；'
            '$height = ${(window.height / design.height).toStringAsFixed(3)}；'
            '${axis == ScaleAxis.shorter ? '取较小值' : '取较大值'}',
    };
  }
}

String formatSize(Size size) =>
    '${formatNumber(size.width)} × ${formatNumber(size.height)}';

String formatNumber(double number) =>
    number.toStringAsFixed(number == number.roundToDouble() ? 0 : 1);
