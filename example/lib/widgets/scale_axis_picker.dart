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
      title: 'ScaleAxis (Core choice)',
      subtitle: 'Different axes have different trade-offs — see width validation below',
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
      final view = View.of(context);
      final current = binding.configForView(view);
      if (current != null) {
        binding.updateView(
          view: view,
          config: current.copyWith(scaleAxis: axis),
        );
      }
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
    ScaleAxis.width => 'width (default)',
    ScaleAxis.height => 'height',
    ScaleAxis.shorter => 'shorter (entire design fits)',
    ScaleAxis.longer => 'longer (cropped to edges)',
  };

  static String _tooltip(ScaleAxis axis) => switch (axis) {
    ScaleAxis.width => 'Without min/max limits: MQ.width = design.width',
    ScaleAxis.height => 'Without min/max limits: MQ.height = design.height',
    ScaleAxis.shorter => 'Takes min scale; design always fits, but dimensions vary',
    ScaleAxis.longer => 'Takes max scale; fills viewport, but edges may crop',
  };
}
