import 'package:flutter/material.dart';

import '../state/adapter_settings.dart';
import '../widgets/adapter_compare_demo.dart';
import '../widgets/debug_panel.dart';
import '../widgets/design_size_buttons.dart';
import '../widgets/multi_view_panel.dart';
import '../widgets/orientation_design_demo.dart';
import '../widgets/scale_axis_picker.dart';

/// 主页：无 AppBar，纵向滚动展示所有 demo 区块。
/// 共享的可观察状态从外部以 [AdapterSettings] 注入，避免子 widget
/// 之间通过 setState 嵌套传递。
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.settings});

  final AdapterSettings settings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: ListenableBuilder(
        listenable: settings,
        builder: (ctx, _) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DebugPanel(
                  designSize: settings.designSize,
                  scaleAxis: settings.scaleAxis,
                ),
                const SizedBox(height: 8),
                ScaleAxisPicker(settings: settings),
                AdapterCompareDemo(designSize: settings.designSize),
                OrientationDesignDemo(settings: settings),
                DesignSizeButtons(settings: settings),
                const MultiViewPanel(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
