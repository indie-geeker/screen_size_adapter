import 'package:flutter/widgets.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

// snippet:runtime-updates:start
void updateAdapter(BuildContext context) {
  ScreenSizeAdapter.setDesignSize(context, const Size(414, 896));
  ScreenSizeAdapter.reset(context);
  final scale = ScreenSizeAdapter.scaleOf(context);
  debugPrint('Current scale: $scale');
}

// snippet:runtime-updates:end
