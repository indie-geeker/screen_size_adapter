part of '../screen_size_adapter.dart';

class ScreenSizeWidget extends StatefulWidget {
  final Widget child;
  const ScreenSizeWidget({super.key, required this.child});

  @override
  State<StatefulWidget> createState() => ScreenSizeWidgetState();
}

class ScreenSizeWidgetState extends State<ScreenSizeWidget> {
  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context).copyWithScale();
    return MediaQuery(
      data: mediaQueryData,
      child: DesignSizeInheritedWidget(
        data: this,
        child: widget.child,
      ),
    );
  }

  void setDesignSize(Size size) {
    ScreenSizeHelper.instance.setDesignSize(size);
    WidgetsBinding.instance.handleMetricsChanged();
    setState(() {});
  }

  void reset() {
    ScreenSizeHelper.instance.reset();
    WidgetsBinding.instance.handleMetricsChanged();
    setState(() {});
  }
}



class DesignSizeInheritedWidget extends InheritedWidget {
  final ScreenSizeWidgetState data;

  const DesignSizeInheritedWidget({super.key, required this.data, required super.child});

  static ScreenSizeWidgetState? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DesignSizeInheritedWidget>()?.data;
  }

  static ScreenSizeWidgetState of(BuildContext context) {
    final ScreenSizeWidgetState? result = maybeOf(context);
    assert(result != null, 'No DesignSizeWidgetState found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(DesignSizeInheritedWidget oldWidget) => data != oldWidget.data;
}