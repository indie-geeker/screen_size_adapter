import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  testWidgets('layout in design units', (tester) async {
    await tester.pumpWidget(
      const ScreenSizeTestEnvironment(
        config: ScreenSizeAdapterConfig(designSize: Size(360, 690)),
        simulatedDeviceSize: Size(720, 1380),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Text('Hello'),
        ),
      ),
    );

    expect(find.text('Hello'), findsOneWidget);
  });
}
