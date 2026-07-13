import 'package:flutter/widgets.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

// snippet:responsive-breakpoint:start
Widget responsiveLayout(BuildContext context) {
  final origin = ScreenSizeAdapter.originSizeOf(context);
  if (origin.shortestSide >= 600) {
    return const TabletLayout();
  }
  return const PhoneLayout();
}
// snippet:responsive-breakpoint:end

class TabletLayout extends SizedBox {
  const TabletLayout({super.key});
}

class PhoneLayout extends SizedBox {
  const PhoneLayout({super.key});
}
