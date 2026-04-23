import 'package:flutter/widgets.dart';

import 'dimension_ext.dart';

/// Spacing convenience extensions.
///
/// Example:
/// ```dart
/// Column(children: [
///   Text('Hello'),
///   16.verticalSpace,
///   Text('World'),
/// ])
/// ```
extension SpacingExt on num {
  /// Returns a SizedBox with height scaled by .dp
  SizedBox get verticalSpace => SizedBox(height: dp);

  /// Returns a SizedBox with width scaled by .dp
  SizedBox get horizontalSpace => SizedBox(width: dp);
}

/// EdgeInsets scaling extensions.
///
/// Example:
/// ```dart
/// Padding(padding: EdgeInsets.all(16).w)
/// ```
extension EdgeInsetsScaleExt on EdgeInsets {
  /// Scale all edge values by .dp
  EdgeInsets get w => copyWith(
    left: left.dp,
    top: top.dp,
    right: right.dp,
    bottom: bottom.dp,
  );

  /// Scale all edge values by .r (min-dimension)
  EdgeInsets get r => copyWith(
    left: left.r,
    top: top.r,
    right: right.r,
    bottom: bottom.r,
  );
}

/// BorderRadius scaling extensions.
///
/// Example:
/// ```dart
/// Container(
///   decoration: BoxDecoration(borderRadius: BorderRadius.circular(16).w),
/// )
/// ```
extension BorderRadiusScaleExt on BorderRadius {
  /// Scale all corner radii by .dp
  BorderRadius get w => BorderRadius.only(
    topLeft: Radius.circular(topLeft.x.dp),
    topRight: Radius.circular(topRight.x.dp),
    bottomLeft: Radius.circular(bottomLeft.x.dp),
    bottomRight: Radius.circular(bottomRight.x.dp),
  );

  /// Scale all corner radii by .r (min-dimension)
  BorderRadius get r => BorderRadius.only(
    topLeft: Radius.circular(topLeft.x.r),
    topRight: Radius.circular(topRight.x.r),
    bottomLeft: Radius.circular(bottomLeft.x.r),
    bottomRight: Radius.circular(bottomRight.x.r),
  );
}
