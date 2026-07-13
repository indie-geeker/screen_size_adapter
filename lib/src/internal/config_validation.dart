import 'dart:ui' show Size;

void validateConfigValues({
  required Size designSize,
  double? minScale,
  double? maxScale,
}) {
  if (!designSize.width.isFinite ||
      !designSize.height.isFinite ||
      designSize.width <= 0 ||
      designSize.height <= 0) {
    throw ArgumentError.value(
      designSize,
      'designSize',
      'must have finite positive width and height',
    );
  }

  if (minScale != null && (!minScale.isFinite || minScale <= 0)) {
    throw ArgumentError.value(
      minScale,
      'minScale',
      'must be finite and greater than zero',
    );
  }

  if (maxScale != null && (!maxScale.isFinite || maxScale <= 0)) {
    throw ArgumentError.value(
      maxScale,
      'maxScale',
      'must be finite and greater than zero',
    );
  }

  validateScaleBounds(minScale: minScale, maxScale: maxScale);
}

void validateScaleBounds({double? minScale, double? maxScale}) {
  if (minScale != null && maxScale != null && minScale > maxScale) {
    throw ArgumentError.value(minScale, 'minScale', 'must be <= maxScale');
  }
}
