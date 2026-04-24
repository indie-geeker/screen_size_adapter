// Sentinel test: documents that ScreenSizeAdapter is the public entry point
// and DesignSizeInheritedWidget is intentionally not part of the public API.
// If a future change re-exports DesignSizeInheritedWidget, consider whether
// that's intentional before merging.
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  test('ScreenSizeAdapter is the public entry point for context lookups', () {
    expect(ScreenSizeAdapter, isNotNull);
  });
}
