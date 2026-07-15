import 'package:flutter/material.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

import '../state/adapter_settings.dart';
import 'section_card.dart';

/// 横竖屏自动切换设计稿的 demo：开启 `autoSwapByOrientation` 后，
/// 用 [MediaQuery.orientationOf] 读取视口方向，每次方向变化在
/// `addPostFrameCallback` 里调 [ScreenSizeAdapter.setDesignSize]。
/// 不能依赖纵向滚动容器里的 [OrientationBuilder]，因为它拿到的高度
/// 约束是无限的。配置更新不在 build 中同步调用，避免
/// build-during-build 异常。
class OrientationDesignDemo extends StatelessWidget {
  const OrientationDesignDemo({super.key, required this.settings});

  final AdapterSettings settings;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Auto-swap Design Size by Orientation',
      subtitle:
          'Portrait → ${_fmt(kPortraitDesign)}; Landscape → ${_fmt(kLandscapeDesign)}',
      accent: Colors.teal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            value: settings.autoSwapByOrientation,
            onChanged: settings.setAutoSwap,
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text(
              'Auto-swap designSize',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'When disabled, manually control via the "Runtime Design Size Preset" section',
              style: TextStyle(fontSize: 11),
            ),
          ),
          if (settings.autoSwapByOrientation) _AutoSwapBody(settings: settings),
        ],
      ),
    );
  }

  static String _fmt(Size s) => '${s.width.toInt()}×${s.height.toInt()}';
}

class _AutoSwapBody extends StatelessWidget {
  const _AutoSwapBody({required this.settings});

  final AdapterSettings settings;

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.orientationOf(context);
    final isLandscape = orientation == Orientation.landscape;
    final target = isLandscape ? kLandscapeDesign : kPortraitDesign;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      if (!settings.autoSwapByOrientation) return;
      if (MediaQuery.orientationOf(context) != orientation) return;
      final binding = WidgetsBinding.instance;
      if (binding is ScreenSizeWidgetsFlutterBinding) {
        final view = View.of(context);
        if (binding.configForView(view)?.designSize != target) {
          ScreenSizeAdapter.setDesignSize(context, target);
        }
      }
      if (settings.designSize != target) {
        settings.setDesignSize(target);
      }
    });
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'Current MediaQuery reports: '
        '${isLandscape ? "landscape" : "portrait"} → Target design size '
        '${target.width.toInt()}×${target.height.toInt()}',
        style: const TextStyle(fontSize: 12, color: Colors.black87),
      ),
    );
  }
}
