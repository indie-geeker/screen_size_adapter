import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';
import '../../test/root_viewport_test.dart' show nativeView;
import '../../test/root_viewport_contract_test.dart' show configAt;

void main() {
  for (final scale in [0.75, 1.25, 2.0]) {
    testWidgets('default NestedScrollView wheel stays native at scale=$scale', (
      tester,
    ) async {
      nativeView(tester);
      final key = GlobalKey<NestedScrollViewState>();
      final outer = ScrollController();
      addTearDown(outer.dispose);
      await tester.pumpWidget(
        ScreenSizeAdapter(
          config: configAt(scale),
          child: MaterialApp(
            home: NestedScrollView(
              key: key,
              controller: outer,
              headerSliverBuilder:
                  (_, _) => [
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
              body: ListView.builder(
                itemExtent: 30,
                itemCount: 100,
                itemBuilder: (_, i) => Text('row $i'),
              ),
            ),
          ),
        ),
      );
      await tester.sendEventToBinding(
        const PointerScrollEvent(
          position: Offset(100, 500),
          scrollDelta: Offset(0, 60),
          kind: PointerDeviceKind.mouse,
        ),
      );
      await tester.pumpAndSettle();
      final actual =
          (outer.offset + key.currentState!.innerController.offset) * scale;
      debugPrint('DEFAULT_NESTED scale=$scale visible=$actual native=60');
      expect(actual, closeTo(60, .001));
    });
    for (final direction in TextDirection.values) {
      testWidgets(
        'toolbar and system menu glyph geometry $direction scale=$scale',
        (tester) async {
          nativeView(tester);
          final controller = TextEditingController.fromValue(
            TextEditingValue(
              text: direction == TextDirection.rtl ? 'اختبار' : 'hello',
              selection: const TextSelection(baseOffset: 1, extentOffset: 4),
            ),
          );
          final focus = FocusNode();
          final key = GlobalKey<EditableTextState>();
          addTearDown(controller.dispose);
          addTearDown(focus.dispose);
          await tester.pumpWidget(
            ScreenSizeAdapter(
              config: configAt(scale),
              child: MaterialApp(
                home: Scaffold(
                  body: Padding(
                    padding: const EdgeInsets.only(left: 30, top: 40),
                    child: SizedBox(
                      width: 180,
                      height: 40,
                      child: EditableText(
                        key: key,
                        controller: controller,
                        focusNode: focus,
                        textDirection: direction,
                        style: const TextStyle(fontSize: 16),
                        cursorColor: Colors.blue,
                        backgroundCursorColor: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          final render = key.currentState!.renderEditable;
          final local = render
              .getBoxesForSelection(controller.selection)
              .map((box) => box.toRect())
              .reduce((a, b) => a.expandToInclude(b));
          final expected = MatrixUtils.transformRect(
            render.getTransformTo(null),
            local,
          );
          final actual =
              SystemContextMenu.editableText(
                editableTextState: key.currentState!,
              ).anchor;
          debugPrint(
            'DEFAULT_MENU $direction scale=$scale actual=$actual expected=$expected',
          );
          expect(
            {
              'systemMenu': actual,
              'toolbarPrimary':
                  key.currentState!.contextMenuAnchors.primaryAnchor,
            },
            {'systemMenu': expected, 'toolbarPrimary': expected.topCenter},
          );
        },
      );
    }
  }
}
