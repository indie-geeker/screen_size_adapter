import 'package:flutter/material.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

// snippet:read-metrics:start
class MetricsLabel extends StatelessWidget {
  const MetricsLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final metrics = ScreenSizeAdapter.of(context);
    return Text(
      'Window: ${metrics.originSize}, '
      'layout: ${metrics.designSize}, scale: ${metrics.scale}',
    );
  }
}
// snippet:read-metrics:end
