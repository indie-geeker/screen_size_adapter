import 'package:flutter/widgets.dart';

import '../screen_size_widget.dart';

class DesignSizeInheritedWidget extends InheritedWidget {
  final ScreenSizeWidgetState data;
  final int version;

  const DesignSizeInheritedWidget({
    super.key,
    required this.data,
    required this.version,
    required super.child,
  });

  static ScreenSizeWidgetState? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<DesignSizeInheritedWidget>()
        ?.data;
  }

  static ScreenSizeWidgetState of(BuildContext context) {
    final ScreenSizeWidgetState? result = maybeOf(context);
    assert(result != null, 'No DesignSizeWidgetState found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(DesignSizeInheritedWidget oldWidget) =>
      version != oldWidget.version;
}
