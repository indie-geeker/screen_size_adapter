import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  testWidgets('example can render widget with adapter extensions', (
    WidgetTester tester,
  ) async {
    ScreenSizeHelper.initializeForTest(const Size(360, 640));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Container(
            width: 120.dp,
            height: 60.dp,
            alignment: Alignment.center,
            child: Text('demo', style: TextStyle(fontSize: 14.sp)),
          ),
        ),
      ),
    );

    expect(find.text('demo'), findsOneWidget);
  });
}
