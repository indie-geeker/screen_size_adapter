part of '../screen_size_adapter.dart';

/// Public runtime control APIs for screen adaptation.
class ScreenSizeAdapter {
  const ScreenSizeAdapter._();

  static ScreenSizeWidgetState of(BuildContext context) {
    return DesignSizeInheritedWidget.of(context);
  }

  static ScreenSizeWidgetState? maybeOf(BuildContext context) {
    return DesignSizeInheritedWidget.maybeOf(context);
  }

  /// Updates design size and triggers relayout for the current widget tree.
  static void setDesignSize(BuildContext context, Size size) {
    final state = maybeOf(context);
    if (state == null) {
      throw StateError(
        'No ScreenSizeWidget found in context. Make sure the app is initialized '
        'with ScreenSizeWidgetsFlutterBinding.ensureInitialized(...) before runApp().',
      );
    }
    state.setDesignSize(size);
  }

  /// Resets adapter state to current screen metrics and triggers relayout.
  static void reset(BuildContext context) {
    final state = maybeOf(context);
    if (state == null) {
      throw StateError(
        'No ScreenSizeWidget found in context. Make sure the app is initialized '
        'with ScreenSizeWidgetsFlutterBinding.ensureInitialized(...) before runApp().',
      );
    }
    state.reset();
  }
}
