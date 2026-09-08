import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/src/internal/scale_media_query.dart';

void main() {
  testWidgets(
    'scaled iOS field uses Flutter menu and copy preserves text',
    (tester) async {
      final controller = TextEditingController(text: 'Alpha bravo');
      addTearDown(controller.dispose);
      final platformCalls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          platformCalls.add(call);
          if (call.method == 'Clipboard.hasStrings') return {'value': false};
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: scaleMediaQueryData(
              const MediaQueryData(
                size: Size(800, 600),
                supportsShowingSystemContextMenu: true,
              ),
              1.5,
            ),
            child: Scaffold(body: TextField(controller: controller)),
          ),
        ),
      );
      await tester.tap(find.byType(TextField));
      await tester.pump();
      final editable = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      editable.userUpdateTextEditingValue(
        controller.value.copyWith(
          selection: const TextSelection(baseOffset: 0, extentOffset: 5),
        ),
        SelectionChangedCause.longPress,
      );
      editable.showToolbar();
      await tester.pumpAndSettle();
      expect(find.byType(SystemContextMenu), findsNothing);
      expect(find.text('Copy'), findsOneWidget);
      expect(
        platformCalls.where(
          (call) => call.method == 'ContextMenu.showSystemContextMenu',
        ),
        isEmpty,
      );
      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();
      expect(
        platformCalls
            .where((call) => call.method == 'Clipboard.setData')
            .last
            .arguments,
        {'text': 'Alpha'},
      );
      expect(controller.text, 'Alpha bravo');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
