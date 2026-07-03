import 'package:flutter/material.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

import '../state/adapter_settings.dart';
import 'section_card.dart';

/// 4 选 1 的 [ScaleAxis] 切换器：改值时调用 binding 的
/// `updateView` 重算当前 view 的 scale，并把状态写回 [AdapterSettings]
/// 让其它 widget 一起 rebuild。
class ScaleAxisPicker extends StatelessWidget {
  const ScaleAxisPicker({super.key, required this.settings});

  final AdapterSettings settings;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'ScaleAxis（横竖屏的核心选择）',
      subtitle: '不同 axis 在横竖屏下的 trade-off 不同 — 见下面充满宽度验证',
      accent: Colors.deepPurple,
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final axis in ScaleAxis.values)
            _AxisChip(
              axis: axis,
              selected: settings.scaleAxis == axis,
              onSelected: () => _select(context, axis),
            ),
        ],
      ),
    );
  }

  void _select(BuildContext context, ScaleAxis axis) {
    final binding = WidgetsBinding.instance;
    if (binding is ScreenSizeWidgetsFlutterBinding) {
      binding.updateView(view: View.of(context), scaleAxis: axis);
    }
    settings.setScaleAxis(axis);
  }
}

class _AxisChip extends StatelessWidget {
  const _AxisChip({
    required this.axis,
    required this.selected,
    required this.onSelected,
  });

  final ScaleAxis axis;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(_label(axis)),
      selected: selected,
      onSelected: (_) => onSelected(),
      labelStyle: const TextStyle(fontSize: 12),
      tooltip: _tooltip(axis),
    );
  }

  static String _label(ScaleAxis axis) => switch (axis) {
    ScaleAxis.width => 'width（默认）',
    ScaleAxis.height => 'height',
    ScaleAxis.shorter => 'shorter（画布完整）',
    ScaleAxis.longer => 'longer（贴边裁切）',
  };

  static String _tooltip(ScaleAxis axis) => switch (axis) {
    ScaleAxis.width => 'scale = origin.w / design.w；MQ.width 永远等于设计宽度',
    ScaleAxis.height => 'scale = origin.h / design.h；MQ.height 永远等于设计高度',
    ScaleAxis.shorter => '取较小比；圆永远是圆，但宽度不再固定',
    ScaleAxis.longer => '取较大比；至少一边贴满，另一边可能溢出',
  };
}
