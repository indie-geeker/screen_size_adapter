import 'dart:ui' show FlutterView;

import 'package:flutter/widgets.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void registerSecondaryView(FlutterView secondaryView) {
  final binding = ScreenSizeWidgetsFlutterBinding.instance;
  binding.attachView(
    view: secondaryView,
    config: const ScreenSizeAdapterConfig(
      designSize: Size(800, 600),
      scaleAxis: ScaleAxis.shorter,
    ),
  );

  binding.updateView(
    view: secondaryView,
    config: const ScreenSizeAdapterConfig(
      designSize: Size(1024, 768),
      scaleAxis: ScaleAxis.shorter,
    ),
  );
}

Widget buildSecondaryView(FlutterView secondaryView) => View(
  view: secondaryView,
  child: const ScreenSizeAdapterScope(
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Text('Secondary view'),
    ),
  ),
);
