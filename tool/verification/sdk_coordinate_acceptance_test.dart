// These acceptance tests intentionally expose incompatibilities in a bare
// root viewport. Keep them in the acceptance gate: release is blocked until fixed.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';
import '../../test/root_viewport_test.dart' show nativeView;
import '../../test/root_viewport_contract_test.dart' show configAt;

void main() {
  testWidgets(
    'system context menu anchor must use entirely native coordinates',
    (tester) async {
      nativeView(tester);
      final controller = TextEditingController.fromValue(
        const TextEditingValue(
          text: 'hello world',
          selection: TextSelection(baseOffset: 2, extentOffset: 7),
        ),
      );
      final focus = FocusNode();
      final key = GlobalKey<EditableTextState>();
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        ScreenSizeAdapter(
          config: configAt(2),
          child: MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.only(left: 40, top: 60),
                child: SizedBox(
                  width: 200,
                  height: 40,
                  child: EditableText(
                    key: key,
                    controller: controller,
                    focusNode: focus,
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
      final state = key.currentState!;
      final render = state.renderEditable;
      final endpoints = render.getEndpointsForSelection(controller.selection);
      final heights = state.getGlyphHeights();
      final local = Rect.fromLTRB(
        endpoints.first.point.dx,
        endpoints.first.point.dy - heights.startGlyphHeight,
        endpoints.last.point.dx,
        endpoints.last.point.dy,
      );
      final expected = MatrixUtils.transformRect(
        render.getTransformTo(null),
        local,
      );
      final actual =
          SystemContextMenu.editableText(editableTextState: state).anchor;
      debugPrint('SYSTEM_MENU actual=$actual expectedNative=$expected');
      expect(actual, expected);
    },
  );

  testWidgets(
    'wheel visible distance must remain native distance under scaling',
    (tester) async {
      nativeView(tester);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        ScreenSizeAdapter(
          config: configAt(2),
          child: MaterialApp(
            home: ListView.builder(
              controller: scroll,
              itemExtent: 40,
              itemCount: 200,
              itemBuilder: (_, i) => Text('row $i'),
            ),
          ),
        ),
      );
      await tester.sendEventToBinding(
        const PointerScrollEvent(
          position: Offset(200, 300),
          scrollDelta: Offset(0, 60),
          kind: PointerDeviceKind.mouse,
        ),
      );
      await tester.pumpAndSettle();
      debugPrint(
        'WHEEL actualDesignDelta=${scroll.offset} actualVisibleDelta=${scroll.offset * 2} nativeDelta=60',
      );
      expect(scroll.offset * 2, 60);
    },
  );
}
