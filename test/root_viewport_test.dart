import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

const _config = ScreenSizeAdapterConfig(
  designSize: Size(400, 300),
  enableDesktopScaling: true,
);

void nativeView(WidgetTester tester, {Size size = const Size(800, 600)}) {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = size * 2;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('native root with design layout and native global transform', (
    tester,
  ) async {
    nativeView(tester);
    final key = GlobalKey();
    Size? layout;
    MediaQueryData? media;
    await tester.pumpWidget(
      ScreenSizeAdapter(
        config: _config,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              media = MediaQuery.of(context);
              return LayoutBuilder(
                builder: (context, constraints) {
                  layout = constraints.biggest;
                  return Stack(
                    children: [
                      Positioned(
                        left: 40,
                        top: 60,
                        child: SizedBox(key: key, width: 100, height: 50),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
    final box = key.currentContext!.findRenderObject()! as RenderBox;
    expect(tester.binding.renderViews.single.configuration.devicePixelRatio, 2);
    expect(layout, const Size(400, 300));
    expect(media!.size, const Size(400, 300));
    expect(media!.devicePixelRatio, 4);
    expect(box.localToGlobal(Offset.zero), const Offset(80, 120));
    expect(box.globalToLocal(const Offset(180, 170)), const Offset(50, 25));
  });

  testWidgets(
    'text input transform maps design coordinates to native coordinates',
    (tester) async {
      nativeView(tester);
      final controller = TextEditingController(text: '中文 input');
      final focus = FocusNode();
      final key = GlobalKey<EditableTextState>();
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        ScreenSizeAdapter(
          config: _config,
          child: MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.only(left: 40, top: 60),
                child: SizedBox(
                  width: 120,
                  height: 40,
                  child: EditableText(
                    key: key,
                    controller: controller,
                    focusNode: focus,
                    style: const TextStyle(fontSize: 16),
                    cursorColor: Colors.black,
                    backgroundCursorColor: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      final messages =
          tester.testTextInput.log
              .where(
                (call) =>
                    call.method == 'TextInput.setEditableSizeAndTransform',
              )
              .toList();
      expect(messages, isNotEmpty);
      final args = messages.last.arguments as Map;
      final transform = Matrix4.fromList(
        List<double>.from(args['transform'] as List),
      );
      expect(
        MatrixUtils.transformPoint(transform, Offset.zero),
        const Offset(80, 120),
      );
      expect(
        MatrixUtils.transformRect(
          transform,
          Rect.fromLTWH(
            0,
            0,
            args['width'] as double,
            args['height'] as double,
          ),
        ),
        const Rect.fromLTWH(80, 120, 240, 80),
      );
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '中文输入',
          selection: TextSelection.collapsed(offset: 4),
          composing: TextRange(start: 2, end: 4),
        ),
      );
      await tester.pump();
      expect(controller.value.composing, const TextRange(start: 2, end: 4));
      expect(tester.takeException(), isNull);
    },
  );
}
