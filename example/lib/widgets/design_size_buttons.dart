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

/// Demonstrates a representative scale clamp, removing the clamp, and the
/// native-scale reset contract on the active FlutterView.
class ScaleBoundsControls extends StatelessWidget {
  const ScaleBoundsControls({super.key, required this.settings});

  final AdapterSettings settings;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '缩放边界与重置',
      subtitle:
          '当前：${_bound(settings.minScale)} – ${_bound(settings.maxScale)}',
      accent: Colors.indigo,
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          OutlinedButton(
            onPressed: () => _setBounds(context, minScale: 0.8, maxScale: 1.2),
            child: const Text('限制为 0.8–1.2'),
          ),
          OutlinedButton(
            onPressed: () => _setBounds(context),
            child: const Text('移除 scale 限制'),
          ),
          FilledButton.tonal(
            onPressed: () => _reset(context),
            child: const Text('重置为原生 scale=1'),
          ),
        ],
      ),
    );
  }

  void _setBounds(BuildContext context, {double? minScale, double? maxScale}) {
    final binding = WidgetsBinding.instance;
    if (binding is ScreenSizeWidgetsFlutterBinding) {
      final view = View.of(context);
      final current = binding.configForView(view);
      if (current != null) {
        binding.updateView(
          view: view,
          config:
              minScale == null && maxScale == null
                  ? current.copyWith(clearMinScale: true, clearMaxScale: true)
                  : current.copyWith(minScale: minScale, maxScale: maxScale),
        );
      }
    }
    settings.setScaleBounds(minScale: minScale, maxScale: maxScale);
  }

  void _reset(BuildContext context) {
    final nativeSize = ScreenSizeAdapter.originSizeOf(context);
    if (WidgetsBinding.instance is ScreenSizeWidgetsFlutterBinding) {
      ScreenSizeAdapter.reset(context);
    }
    settings.setAutoSwap(false);
    settings.setDesignSize(nativeSize);
    settings.setScaleBounds(minScale: null, maxScale: null);
  }

  static String _bound(double? value) => value?.toStringAsFixed(2) ?? '无限制';
}

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
