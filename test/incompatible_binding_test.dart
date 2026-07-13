import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  test(
    'ensureInitialized rejects an already-installed incompatible binding',
    () {
      final existing = WidgetsFlutterBinding.ensureInitialized();

      expect(
        () => ScreenSizeWidgetsFlutterBinding.ensureInitialized(
          const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains(existing.runtimeType.toString()),
          ),
        ),
      );
    },
  );
}
