import 'package:flutter/material.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

import '../state/adapter_settings.dart';
import 'section_card.dart';

/// 横竖屏自动切换设计稿的 demo：开启 `autoSwapByOrientation` 后，
/// 用 [OrientationBuilder] 监听方向，每次方向变化在
/// `addPostFrameCallback` 里调 [ScreenSizeAdapter.setDesignSize]。
/// 不在 build 中同步调用，避免 build-during-build 异常。
class OrientationDesignDemo extends StatelessWidget {
  const OrientationDesignDemo({super.key, required this.settings});

  final AdapterSettings settings;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '横竖屏自动切换设计稿',
      subtitle: '竖屏 → ${_fmt(kPortraitDesign)}；横屏 → ${_fmt(kLandscapeDesign)}',
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
              '随方向切换 designSize',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              '关闭时由 "运行时切换设计稿" 区块手动控制',
              style: TextStyle(fontSize: 11),
            ),
          ),
          if (settings.autoSwapByOrientation)
            _AutoSwapBody(settings: settings),
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
    return OrientationBuilder(
      builder: (ctx, orientation) {
        final isLandscape = orientation == Orientation.landscape;
        final target = isLandscape ? kLandscapeDesign : kPortraitDesign;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!ctx.mounted) return;
          if (settings.designSize == target) return;
          ScreenSizeAdapter.setDesignSize(ctx, target);
          settings.setDesignSize(target);
        });
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '当前 OrientationBuilder 报告：'
            '${isLandscape ? "landscape" : "portrait"} → 目标设计稿 '
            '${target.width.toInt()}×${target.height.toInt()}',
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        );
      },
    );
  }
}
