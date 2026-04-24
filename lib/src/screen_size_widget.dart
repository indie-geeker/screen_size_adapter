import 'package:flutter/widgets.dart';

import 'internal/design_size_inherited.dart';
import 'media_query_ext.dart';
import 'screen_size_helper.dart';

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
    final mediaQueryData = MediaQuery.of(context).copyWithScale(ScreenSizeHelper.instance.scale);
    return MediaQuery(
      data: mediaQueryData,
      child: DesignSizeInheritedWidget(
        data: this,
        version: _version,
        child: widget.child,
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
