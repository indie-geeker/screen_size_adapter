import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  final binding = ScreenSizeWidgetsFlutterBinding.ensureInitialized(
    const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
  );

  Future<void> frames() async {
    for (var i = 0; i < 4; i++) {
      binding.scheduleWarmUpFrame();
      await Future<void>.delayed(Duration.zero);
    }
  }

  test(
    'runtime scale dismisses stale RTL menu and reopening uses new geometry',
    () async {
      final view = binding.platformDispatcher.views.first;
      final origin = view.physicalSize / view.devicePixelRatio;
      final controller = TextEditingController(text: 'Alpha bravo delta echo');
      final focus = FocusNode();
      EditableTextState? editable;
      Offset? menuAnchor;
      final fieldKey = GlobalKey();
      addTearDown(() async {
        binding.attachRootWidget(
          View(view: view, child: const SizedBox.shrink()),
        );
        await frames();
        focus.dispose();
        controller.dispose();
      });
      void scale(double value) => binding.attachView(
        view: view,
        config: ScreenSizeAdapterConfig(
          designSize: origin / value,
          enableDesktopScaling: true,
        ),
      );
      scale(1.5);
      binding.attachRootWidget(
        View(
          view: view,
          child: ScreenSizeAdapterScope(
            child: MaterialApp(
              home: Scaffold(
                body: Directionality(
                  textDirection: TextDirection.rtl,
                  child: TextField(
                    key: fieldKey,
                    controller: controller,
                    focusNode: focus,
                    contextMenuBuilder: (context, state) {
                      editable = state;
                      menuAnchor = state.contextMenuAnchors.primaryAnchor;
                      return AdaptiveTextSelectionToolbar.editableText(
                        editableTextState: state,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await frames();
      focus.requestFocus();
      await frames();
      fieldKey.currentContext!.visitChildElements((element) {
        void find(Element child) {
          if (child is StatefulElement && child.state is EditableTextState) {
            editable = child.state as EditableTextState;
          }
          child.visitChildElements(find);
        }

        find(element);
      });
      expect(editable, isNotNull);
      editable!.userUpdateTextEditingValue(
        controller.value.copyWith(
          selection: const TextSelection(baseOffset: 0, extentOffset: 5),
        ),
        SelectionChangedCause.longPress,
      );
      await frames();
      editable!.selectionOverlay!.showHandles();
      expect(editable!.showToolbar(), isTrue);
      await frames();
      final before = menuAnchor;
      expect(before, isNotNull);

      scale(1.0);
      await frames();
      final expected = editable!.contextMenuAnchors.primaryAnchor;
      expect(expected, isNot(before));
      expect(editable!.selectionOverlay!.toolbarIsVisible, isFalse);
      expect(editable!.showToolbar(), isTrue);
      await frames();
      expect(menuAnchor, expected);
      expect(
        controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: 5),
      );
      expect(focus.hasFocus, isTrue);
      editable!.hideToolbar();
      scale(0.75);
      await frames();
      expect(editable!.selectionOverlay!.toolbarIsVisible, isFalse);
      expect(focus.hasFocus, isTrue);
      // A queued refresh must also tolerate removal of the focused subtree.
      scale(1.5);
      binding.attachRootWidget(
        View(view: view, child: const SizedBox.shrink()),
      );
      await frames();
    },
  );
}
