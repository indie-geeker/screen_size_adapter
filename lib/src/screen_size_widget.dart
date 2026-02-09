part of '../screen_size_adapter.dart';

class ScreenSizeWidget extends StatefulWidget {
  final Widget child;
  const ScreenSizeWidget({super.key, required this.child});

  @override
  State<StatefulWidget> createState() => ScreenSizeWidgetState();
}

class ScreenSizeWidgetState extends State<ScreenSizeWidget> {
  int _version = 0;

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context).copyWithScale();
    return MediaQuery(
      data: mediaQueryData,
      child: DesignSizeInheritedWidget(
        data: this,
        version: _version,
        child: KeyedSubtree(key: ValueKey<int>(_version), child: widget.child),
      ),
    );
  }

  void setDesignSize(Size size) {
    if (ScreenSizeHelper.instance.designSize == size) {
      return;
    }
    ScreenSizeHelper.instance.setDesignSize(size);
    WidgetsBinding.instance.handleMetricsChanged();
    setState(() {
      _version++;
    });
  }

  void reset() {
    ScreenSizeHelper.instance.reset();
    WidgetsBinding.instance.handleMetricsChanged();
    setState(() {
      _version++;
    });
  }
}

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
