import 'package:example/comparison_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder keyed(String key) => find.byKey(ValueKey(key));

Rect visibleRect(WidgetTester tester, String key) {
  final box = tester.renderObject<RenderBox>(keyed(key));
  return MatrixUtils.transformRect(
    box.getTransformTo(null),
    Offset.zero & box.size,
  );
}

void setWindow(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = size * 2;
  addTearDown(tester.view.reset);
}

Future<void> resize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size * 2;
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(keyed(key));
  await tester.tap(keyed(key));
  await tester.pumpAndSettle();
}

Future<void> select(WidgetTester tester, String picker, String label) async {
  await tap(tester, picker);
  final option = find.text(label).last;
  await tester.ensureVisible(option);
  await tester.tap(option);
  await tester.pumpAndSettle();
}

Future<void> configure(
  WidgetTester tester, {
  String? axis,
  String? reference,
  String? orientation,
}) async {
  await tap(tester, 'open-settings');
  if (axis != null) await select(tester, 'axis-picker', axis);
  if (reference != null) await select(tester, 'reference-picker', reference);
  if (orientation != null) {
    await select(tester, 'orientation-picker', orientation);
  }
  await tap(tester, 'apply-settings');
}

String textAt(WidgetTester tester, String key) =>
    tester.widget<Text>(keyed(key)).data!;

void expectScale(WidgetTester tester, double scale) {
  expect(visibleRect(tester, 'size-block').width, closeTo(280 * scale, 0.001));
  expect(visibleRect(tester, 'size-block').height, closeTo(64 * scale, 0.001));
  final circle = visibleRect(tester, 'size-circle');
  expect(circle.width, closeTo(64 * scale, 0.001));
  expect(circle.height, closeTo(circle.width, 0.001));
  expect(textAt(tester, 'scale-label'), '倍率 ${scale.toStringAsFixed(3)}×');
  expect(tester.binding.renderViews.single.configuration.devicePixelRatio, 2);
  expect(tester.takeException(), isNull);
}

void main() {
  for (final width in [320.0, 430.0, 960.0]) {
    testWidgets('fixed samples compare both modes at native width $width', (
      tester,
    ) async {
      setWindow(tester, Size(width, 1200));
      await tester.pumpWidget(const ComparisonApp());
      expectScale(tester, width / 375);
      await tap(tester, 'native-mode');
      expectScale(tester, 1);
      expect(textAt(tester, 'configuration-label'), '按宽度 · 当前设计稿 375 × 812');
    });
  }

  testWidgets('width basis ignores height; height basis ignores width', (
    tester,
  ) async {
    setWindow(tester, const Size(430, 860));
    await tester.pumpWidget(const ComparisonApp());
    expectScale(tester, 430 / 375);
    expect(textAt(tester, 'window-label'), '窗口 430 × 860 → 布局 375 × 750');
    await resize(tester, const Size(430, 1000));
    expectScale(tester, 430 / 375);
    await configure(tester, axis: '按高度');
    expectScale(tester, 1000 / 812);
    await resize(tester, const Size(360, 1000));
    expectScale(tester, 1000 / 812);
  });

  for (final smaller in [true, false]) {
    testWidgets(
      '${smaller ? 'smaller' : 'larger'} ratio handles both orderings',
      (tester) async {
        setWindow(tester, const Size(430, 860));
        await tester.pumpWidget(const ComparisonApp());
        await configure(tester, axis: smaller ? '较小比例' : '较大比例');
        expectScale(tester, smaller ? 860 / 812 : 430 / 375);
        expect(
          textAt(tester, 'calculation-label'),
          contains('430 ÷ 375 = 1.147；860 ÷ 812 = 1.059'),
        );
        await resize(tester, const Size(320, 1000));
        expectScale(tester, smaller ? 320 / 375 : 1000 / 812);
        expect(
          textAt(tester, 'calculation-label'),
          contains('320 ÷ 375 = 0.853；1000 ÷ 812 = 1.232'),
        );
      },
    );
  }

  for (final landscape in [false, true]) {
    testWidgets(
      'fixed ${landscape ? 'landscape' : 'portrait'} survives rotation',
      (tester) async {
        setWindow(tester, const Size(430, 860));
        await tester.pumpWidget(const ComparisonApp());
        await configure(tester, orientation: landscape ? '固定横向' : '固定竖向');
        final reference = landscape ? '812 × 375' : '375 × 812';
        expect(textAt(tester, 'configuration-label'), endsWith(reference));
        expectScale(tester, 430 / (landscape ? 812 : 375));
        await resize(tester, const Size(860, 430));
        expect(textAt(tester, 'configuration-label'), endsWith(reference));
        expectScale(tester, 860 / (landscape ? 812 : 375));
      },
    );
  }

  testWidgets('follow window uses native size and treats square as portrait', (
    tester,
  ) async {
    setWindow(tester, const Size(430, 860));
    await tester.pumpWidget(const ComparisonApp());
    await configure(tester, orientation: '跟随窗口');
    await resize(tester, const Size(860, 430));
    expect(textAt(tester, 'configuration-label'), endsWith('812 × 375'));
    expectScale(tester, 860 / 812);
    await resize(tester, const Size(430, 430));
    expect(textAt(tester, 'configuration-label'), endsWith('375 × 812'));
    expectScale(tester, 430 / 375);
    await tap(tester, 'open-settings');
    expect(textAt(tester, 'draft-design'), '应用后设计稿 375 × 812');
    await tap(tester, 'cancel-settings');
  });

  testWidgets('draft, cancel, dismiss, apply and reset preserve saved state', (
    tester,
  ) async {
    setWindow(tester, const Size(430, 1100));
    await tester.pumpWidget(const ComparisonApp());
    await tap(tester, 'open-settings');
    await select(tester, 'axis-picker', '按高度');
    await select(tester, 'reference-picker', '320 × 568');
    expectScale(tester, 430 / 375);
    expect(textAt(tester, 'draft-scale'), '预计倍率 1.937×');
    await tap(tester, 'cancel-settings');
    expect(textAt(tester, 'configuration-label'), '按宽度 · 当前设计稿 375 × 812');
    await tap(tester, 'open-settings');
    await select(tester, 'reference-picker', '430 × 932');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(textAt(tester, 'configuration-label'), endsWith('375 × 812'));
    await configure(
      tester,
      axis: '按高度',
      reference: '320 × 568',
      orientation: '固定横向',
    );
    expect(textAt(tester, 'configuration-label'), '按高度 · 当前设计稿 568 × 320');
    expectScale(tester, 1100 / 320);
    await tap(tester, 'open-settings');
    await tap(tester, 'reset-settings');
    expect(textAt(tester, 'draft-design'), '应用后设计稿 375 × 812');
    expectScale(tester, 1100 / 320);
    await tap(tester, 'cancel-settings');
    expect(textAt(tester, 'configuration-label'), endsWith('568 × 320'));
    await tap(tester, 'open-settings');
    await tap(tester, 'reset-settings');
    await tap(tester, 'apply-settings');
    expect(textAt(tester, 'configuration-label'), '按宽度 · 当前设计稿 375 × 812');
    expectScale(tester, 430 / 375);
    await tap(tester, 'open-settings');
    await tap(tester, 'cancel-settings');
    expect(tester.takeException(), isNull);
  });

  testWidgets('native mode saves configuration but stays at identity scale', (
    tester,
  ) async {
    setWindow(tester, const Size(430, 860));
    await tester.pumpWidget(const ComparisonApp());
    await tap(tester, 'native-mode');
    await tap(tester, 'open-settings');
    await select(tester, 'reference-picker', '430 × 932');
    await select(tester, 'axis-picker', '按高度');
    expect(textAt(tester, 'draft-scale'), '预计倍率 1.000×');
    expect(find.text('设置将在开启适配时生效'), findsOneWidget);
    await tap(tester, 'apply-settings');
    expectScale(tester, 1);
    expect(textAt(tester, 'window-label'), '窗口 430 × 860 → 布局 430 × 860');
    await tap(tester, 'adapted-mode');
    expectScale(tester, 860 / 932);
  });

  testWidgets('open draft refreshes preview during rotation without applying', (
    tester,
  ) async {
    setWindow(tester, const Size(430, 860));
    await tester.pumpWidget(const ComparisonApp());
    await tap(tester, 'open-settings');
    await select(tester, 'orientation-picker', '跟随窗口');
    await resize(tester, const Size(860, 430));
    expect(textAt(tester, 'draft-design'), '应用后设计稿 812 × 375');
    expect(textAt(tester, 'draft-scale'), '预计倍率 1.059×');
    expect(textAt(tester, 'configuration-label'), endsWith('375 × 812'));
    expectScale(tester, 860 / 375);
    await tap(tester, 'apply-settings');
    expect(textAt(tester, 'configuration-label'), endsWith('812 × 375'));
    expectScale(tester, 860 / 812);
  });

  testWidgets('counter, input and dialog survive settings and mode changes', (
    tester,
  ) async {
    setWindow(tester, const Size(430, 1100));
    await tester.pumpWidget(const ComparisonApp());
    await tap(tester, 'count-button');
    await tester.enterText(keyed('sample-input'), '中文 Hello 123');
    await tap(tester, 'native-mode');
    await tap(tester, 'adapted-mode');
    await configure(tester, reference: '320 × 568', axis: '按高度');
    await tap(tester, 'open-settings');
    await tap(tester, 'reset-settings');
    await tap(tester, 'apply-settings');
    expect(find.text('点击计数 1'), findsOneWidget);
    expect(find.text('中文 Hello 123'), findsOneWidget);
    await tap(tester, 'dialog-button');
    final navigator = Navigator.of(tester.element(find.byType(AlertDialog)));
    await resize(tester, const Size(500, 1000));
    expect(find.byType(AlertDialog), findsOneWidget);
    final box = tester.renderObject<RenderBox>(find.byType(AlertDialog));
    final rect = MatrixUtils.transformRect(
      box.getTransformTo(null),
      Offset.zero & box.size,
    );
    expect(rect.center.dx, closeTo(250, 0.001));
    expect(rect.center.dy, closeTo(500, 0.001));
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    expect(navigator.canPop(), isFalse);
    expect(find.text('中文 Hello 123'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'narrow viewport and large text keep controls and samples reachable',
    (tester) async {
      setWindow(tester, const Size(320, 1000));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(const ComparisonApp());
      await configure(tester, axis: '按高度');
      expectScale(tester, 1000 / 812);
      expect(
        MediaQuery.textScalerOf(
          tester.element(keyed('sample-input')),
        ).scale(16),
        32,
      );
      await tap(tester, 'count-button');
      await tester.ensureVisible(keyed('sample-input'));
      await tester.enterText(keyed('sample-input'), '放大文字');
      tester.view.viewInsets = const FakeViewPadding(bottom: 500);
      await tester.pumpAndSettle();
      await tester.ensureVisible(keyed('sample-input'));
      expect(keyed('sample-input').hitTestable(), findsOneWidget);
      await tap(tester, 'open-settings');
      await tap(tester, 'reset-settings');
      expect(keyed('apply-settings').hitTestable(), findsOneWidget);
      expect(keyed('cancel-settings').hitTestable(), findsOneWidget);
      await tap(tester, 'apply-settings');
      expectScale(tester, 320 / 375);
      expect(find.text('点击计数 1'), findsOneWidget);
      expect(find.text('放大文字'), findsOneWidget);
    },
  );
}
