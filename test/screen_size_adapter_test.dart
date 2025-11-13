import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  // 基础功能测试
  group('DimensionExt Basic Tests', () {
    testWidgets('Extension methods should work', (WidgetTester tester) async {
      // 初始化适配器
      ScreenSizeHelper.instance.setDesignSize(const Size(360, 640));

      // 构建测试组件
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Test')),
          ),
        ),
      );

      // 测试扩展方法可以调用
      expect(() => 100.dp, returnsNormally);
      expect(() => 100.vw, returnsNormally);
      expect(() => 100.vh, returnsNormally);
      expect(() => 14.sp, returnsNormally);

      // 验证返回值是数字
      expect(100.dp, isA<double>());
      expect(100.vw, isA<double>());
      expect(100.vh, isA<double>());
      expect(14.sp, isA<double>());
    });
  });

  group('ScreenSizeHelper Tests', () {
    testWidgets('setDesignSize should work', (WidgetTester tester) async {
      const designSize = Size(375, 667);
      ScreenSizeHelper.instance.setDesignSize(designSize);

      expect(ScreenSizeHelper.instance.designSize, equals(designSize));
      expect(ScreenSizeHelper.instance.scale, greaterThan(0));
    });

    testWidgets('isDesktop getter should work', (WidgetTester tester) async {
      ScreenSizeHelper.instance.setDesignSize(const Size(360, 640));
      expect(ScreenSizeHelper.instance.isDesktop, isA<bool>());
    });

    testWidgets('isLandscape getter should work', (WidgetTester tester) async {
      ScreenSizeHelper.instance.setDesignSize(const Size(360, 640));
      expect(ScreenSizeHelper.instance.isLandscape, isA<bool>());
    });
  });

  group('Integration Tests', () {
    testWidgets('Widget with dp sizing should render', (WidgetTester tester) async {
      ScreenSizeHelper.instance.setDesignSize(const Size(360, 640));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              width: 100.dp,
              height: 50.dp,
              color: Colors.blue,
              child: const Text('Test'),
            ),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('Text with sp font size should render', (WidgetTester tester) async {
      ScreenSizeHelper.instance.setDesignSize(const Size(360, 640));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Text(
              'Hello World',
              style: TextStyle(fontSize: 16.sp),
            ),
          ),
        ),
      );

      expect(find.text('Hello World'), findsOneWidget);
    });
  });
}
