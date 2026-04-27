import 'package:flutter/material.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

import '../state/adapter_settings.dart';
import 'section_card.dart';

const List<Size> _presets = <Size>[
  Size(360, 690),
  Size(375, 667),
  Size(390, 844),
  Size(640, 360),
];

/// 一组按钮，运行时调 [ScreenSizeAdapter.setDesignSize] 切设计稿。
/// 仅在 `autoSwapByOrientation == false` 时显示，避免和方向自动切换打架。
class DesignSizeButtons extends StatelessWidget {
  const DesignSizeButtons({super.key, required this.settings});

  final AdapterSettings settings;

  @override
  Widget build(BuildContext context) {
    if (settings.autoSwapByOrientation) {
      return const SizedBox.shrink();
    }
    return SectionCard(
      title: '运行时切换设计稿',
      subtitle: '当前：${_fmt(settings.designSize)} — 切换后立即重算 scale',
      accent: Colors.amber,
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final preset in _presets)
            _PresetButton(
              size: preset,
              selected: preset == settings.designSize,
              onTap: () {
                ScreenSizeAdapter.setDesignSize(context, preset);
                settings.setDesignSize(preset);
              },
            ),
        ],
      ),
    );
  }

  static String _fmt(Size s) => '${s.width.toInt()}×${s.height.toInt()}';
}

class _PresetButton extends StatelessWidget {
  const _PresetButton({
    required this.size,
    required this.selected,
    required this.onTap,
  });

  final Size size;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = '${size.width.toInt()}×${size.height.toInt()}';
    if (selected) {
      return FilledButton(onPressed: onTap, child: Text(label));
    }
    return OutlinedButton(onPressed: onTap, child: Text(label));
  }
}
