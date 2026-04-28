import 'package:flutter/material.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

import 'info_row.dart';

/// 校验当前 [ScaleAxis] 对应的契约是否成立。
///
/// 各 axis 含义：
/// - `width`：MQ.width ≈ design.width
/// - `height`：MQ.height ≈ design.height
/// - `shorter`：design 完整内嵌于 MQ（mq.w ≥ design.w 且 mq.h ≥ design.h，
///   驱动轴上有一边精确等于 design）
/// - `longer`：驱动轴上至少有一边精确等于 design（非驱动轴 mq < design 是
///   预期，不算违约）
///
/// ε = 0.5px。仅在 minScale/maxScale 钳位起作用时才会判负。
@visibleForTesting
({bool matched, String message}) checkContract({
  required ScaleAxis axis,
  required Size mq,
  required Size design,
}) {
  const eps = 0.5;
  switch (axis) {
    case ScaleAxis.width:
      final diff = (mq.width - design.width).abs();
      final ok = diff < eps;
      return (
        matched: ok,
        message: ok
            ? '✅ MQ.width ≈ design.width — width 轴契约成立'
            : '⚠️ width 轴：MQ.width=${mq.width.toStringAsFixed(1)} '
                '与 design.width=${design.width.toStringAsFixed(1)} '
                '差 ${diff.toStringAsFixed(1)}px（检查 minScale/maxScale）',
      );
    case ScaleAxis.height:
      final diff = (mq.height - design.height).abs();
      final ok = diff < eps;
      return (
        matched: ok,
        message: ok
            ? '✅ MQ.height ≈ design.height — height 轴契约成立'
            : '⚠️ height 轴：MQ.height=${mq.height.toStringAsFixed(1)} '
                '与 design.height=${design.height.toStringAsFixed(1)} '
                '差 ${diff.toStringAsFixed(1)}px（检查 minScale/maxScale）',
      );
    case ScaleAxis.shorter:
      final ok = mq.width >= design.width - eps &&
          mq.height >= design.height - eps;
      return (
        matched: ok,
        message: ok
            ? '✅ design 完整内嵌于 MQ — shorter 轴契约成立（不裁切）'
            : '⚠️ shorter 轴：design '
                '${design.width.toStringAsFixed(0)}×${design.height.toStringAsFixed(0)} '
                '部分超出 MQ '
                '${mq.width.toStringAsFixed(0)}×${mq.height.toStringAsFixed(0)}'
                '（检查 minScale/maxScale）',
      );
    case ScaleAxis.longer:
      final wAligned = (mq.width - design.width).abs() < eps;
      final hAligned = (mq.height - design.height).abs() < eps;
      final ok = wAligned || hAligned;
      return (
        matched: ok,
        message: ok
            ? '✅ design 至少有一边精确等于 MQ — longer 轴契约成立（贴边）'
            : '⚠️ longer 轴：MQ '
                '${mq.width.toStringAsFixed(0)}×${mq.height.toStringAsFixed(0)} '
                '与 design '
                '${design.width.toStringAsFixed(0)}×${design.height.toStringAsFixed(0)} '
                '无对齐边（检查 minScale/maxScale）',
      );
  }
}

/// 顶部深色调试面板：实时显示当前 design / origin / MQ / scale / axis
/// 等运行时数据，并根据当前 [ScaleAxis] 校验对应的契约（见 [checkContract]）。
class DebugPanel extends StatelessWidget {
  const DebugPanel({
    super.key,
    required this.designSize,
    required this.scaleAxis,
  });

  final Size designSize;
  final ScaleAxis scaleAxis;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);
    final origin = ScreenSizeAdapter.originSizeOf(context);
    final scale = ScreenSizeAdapter.scaleOf(context);
    final isLandscape = origin.width > origin.height;

    final contract = checkContract(
      axis: scaleAxis,
      mq: mq,
      design: designSize,
    );

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
          InfoRow.dark(label: '当前 axis', value: scaleAxis.name),
          InfoRow.dark(
            label: '方向',
            value: isLandscape ? '横屏 landscape' : '竖屏 portrait',
          ),
          const SizedBox(height: 8),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 6),
          _ContractCheck(matched: contract.matched, message: contract.message),
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
        Expanded(
          child: Text(
            'screen_size_adapter · 实时调试',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _ContractCheck extends StatelessWidget {
  const _ContractCheck({required this.matched, required this.message});

  final bool matched;
  final String message;

  @override
  Widget build(BuildContext context) {
    final color = matched ? Colors.greenAccent : Colors.redAccent;
    return Text(message, style: TextStyle(color: color, fontSize: 12));
  }
}
