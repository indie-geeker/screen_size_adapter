import 'package:flutter/widgets.dart';
import '../config.dart';
import 'config_validation.dart';

double computeScale({
  required Size origin,
  required ScreenSizeAdapterConfig config,
  required bool isDesktop,
}) {
  validateConfigValues(
    designSize: config.designSize,
    minScale: config.minScale,
    maxScale: config.maxScale,
  );

  final shouldApply = !isDesktop || config.enableDesktopScaling;
  if (!shouldApply) return 1.0;

  final widthScale = origin.width / config.designSize.width;
  final heightScale = origin.height / config.designSize.height;

  final raw = switch (config.scaleAxis) {
    ScaleAxis.width => widthScale,
    ScaleAxis.height => heightScale,
    ScaleAxis.shorter => widthScale < heightScale ? widthScale : heightScale,
    ScaleAxis.longer => widthScale > heightScale ? widthScale : heightScale,
  };

  if (raw.isNaN || raw.isInfinite || raw <= 0) return 1.0;

  var s = raw;
  if (config.minScale != null && s < config.minScale!) s = config.minScale!;
  if (config.maxScale != null && s > config.maxScale!) s = config.maxScale!;
  return s;
}
