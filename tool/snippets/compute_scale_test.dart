// snippet:compute-scale-test:start
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  test('scale on a 2x-wide device', () {
    final scale = ScreenSizeAdapter.computeScale(
      origin: const Size(720, 1280),
      config: const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
      isDesktop: false,
    );

    expect(scale, 2.0);
  });
}

// snippet:compute-scale-test:end
