import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  // This file holds binding-lifecycle tests that run under
  // AutomatedTestWidgetsFlutterBinding (the default for testWidgets).
  // It must NOT call ScreenSizeWidgetsFlutterBinding.ensureInitialized in
  // setUpAll — the type-mismatch StateError is the property under test.
  testWidgets(
    'ensureInitialized throws when AutomatedTestWidgetsFlutterBinding is active',
    (tester) async {
      expect(
        () => ScreenSizeWidgetsFlutterBinding.ensureInitialized(
          const Size(360, 640),
        ),
        throwsA(isA<StateError>()),
      );
    },
  );
}
