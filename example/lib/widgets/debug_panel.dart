import 'package:flutter/material.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

import 'info_row.dart';

/// 顶部深色调试面板：实时显示当前 design / origin / MQ 尺寸、
/// scale，以及"MediaQuery.width 是否等于设计宽度"的契约校验。
class DebugPanel extends StatelessWidget {
  const DebugPanel({super.key, required this.designSize});

  final Size designSize;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);
    final origin = ScreenSizeAdapter.originSizeOf(context);
    final scale = ScreenSizeAdapter.scaleOf(context);
    final isLandscape = origin.width > origin.height;

    final widthDiff = (mq.width - designSize.width).abs();
    final widthMatches = widthDiff < 0.5;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      color: Colors.black87,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(),
          const SizedBox(height: 8),
          InfoRow.dark(label: '设计稿尺寸', value: _fmt(designSize)),
          InfoRow.dark(label: '物理逻辑尺寸（origin）', value: _fmt(origin)),
          InfoRow.dark(label: 'MediaQuery 尺寸', value: _fmt(mq)),
          InfoRow.dark(label: '当前 scale', value: scale.toStringAsFixed(3)),
          InfoRow.dark(
            label: '方向',
            value: isLandscape ? '横屏 landscape' : '竖屏 portrait',
          ),
          const SizedBox(height: 8),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 6),
          _ContractCheck(matched: widthMatches, diff: widthDiff),
        ],
      ),
    );
  }

  static String _fmt(Size s) =>
      '${s.width.toStringAsFixed(1)} × ${s.height.toStringAsFixed(1)}';
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.bug_report, color: Colors.amberAccent, size: 18),
        SizedBox(width: 6),
        Text(
          'screen_size_adapter · 实时调试',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ContractCheck extends StatelessWidget {
  const _ContractCheck({required this.matched, required this.diff});

  final bool matched;
  final double diff;

  @override
  Widget build(BuildContext context) {
    final color = matched ? Colors.greenAccent : Colors.redAccent;
    final text = matched
        ? '✅ MediaQuery.width ≈ designSize.width — 横竖屏宽度契约成立'
        : '⚠️ 差 ${diff.toStringAsFixed(1)}px — 检查 maxScale 是否被显式设置';
    return Text(text, style: TextStyle(color: color, fontSize: 12));
  }
}
