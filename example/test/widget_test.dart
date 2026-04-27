import 'package:example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MyApp can be instantiated', () {
    // The example's runtime path (MyHomePage.build calls
    // ScreenSizeAdapter.scaleOf, which casts WidgetsBinding.instance to
    // ScreenSizeWidgetsFlutterBinding) is not reachable from
    // AutomatedTestWidgetsFlutterBinding used by testWidgets. This smoke
    // test stays on the constructor surface — enough to catch import or
    // class-shape regressions in main.dart.
    const app = MyApp();
    expect(app, isNotNull);
  });
}
