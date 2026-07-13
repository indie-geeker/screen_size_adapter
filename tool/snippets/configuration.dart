import 'package:flutter/widgets.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

// snippet:configuration:start
void configureAdapter() {
  ScreenSizeWidgetsFlutterBinding.ensureInitialized(
    const ScreenSizeAdapterConfig(
      designSize: Size(360, 690),
      scaleAxis: ScaleAxis.width,
      minScale: null,
      maxScale: null,
      enableDesktopScaling: false,
    ),
  );
}

// snippet:configuration:end
