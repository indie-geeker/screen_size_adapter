import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/src/internal/view_provider.dart';

void main() {
  test('primaryView resolves exactly the dispatcher implicitView', () {
    // ignore: deprecated_member_use
    final implicitView = PlatformDispatcher.instance.implicitView;

    expect(primaryView(), same(implicitView));
  });
}
