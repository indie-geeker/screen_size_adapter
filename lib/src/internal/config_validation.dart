void validateScaleBounds({double? minScale, double? maxScale}) {
  if (minScale != null && maxScale != null && minScale > maxScale) {
    throw ArgumentError.value(minScale, 'minScale', 'must be <= maxScale');
  }
}
