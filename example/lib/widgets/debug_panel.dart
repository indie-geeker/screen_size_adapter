import 'package:flutter/material.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

import 'info_row.dart';

/// 校验 adapter 的核心坐标契约：`MediaQuery.size * scale ≈ originSize`。
///
/// [ScaleAxis] 只决定未钳位时哪一轴与设计稿对齐，不是坐标契约本身。
/// 当 [minScale] 或 [maxScale] 生效时，两轴都可以不与设计稿对齐。
@visibleForTesting
({bool matched, String message, String fitMessage}) checkContract({
  required ScaleAxis axis,
  required Size mq,
  required Size origin,
  required double scale,
  required Size design,
  required double? minScale,
  required double? maxScale,
}) {
  const eps = 0.5;
  final reconstructed = Size(mq.width * scale, mq.height * scale);
  final delta = Size(
    (reconstructed.width - origin.width).abs(),
    (reconstructed.height - origin.height).abs(),
  );
  final matched = delta.width < eps && delta.height < eps;
  final message =
      matched
          ? '✅ MQ × scale ≈ origin — Core coordinate contract holds'
          : '⚠️ MQ × scale = ${_fmt(reconstructed)}; '
              'origin = ${_fmt(origin)}; delta = ${_fmt(delta)}';

  final widthScale = origin.width / design.width;
  final heightScale = origin.height / design.height;
  final rawScale = switch (axis) {
    ScaleAxis.width => widthScale,
    ScaleAxis.height => heightScale,
    ScaleAxis.shorter => widthScale < heightScale ? widthScale : heightScale,
    ScaleAxis.longer => widthScale > heightScale ? widthScale : heightScale,
  };
  final boundActive =
      (minScale != null && rawScale < minScale) ||
      (maxScale != null && rawScale > maxScale);
  final fitMessage =
      boundActive
          ? 'ℹ scale limit active (raw ${rawScale.toStringAsFixed(3)} → '
              '${scale.toStringAsFixed(3)}), MQ axes not required to align with design size.'
          : switch (axis) {
              ScaleAxis.width => 'ℹ width axis fits design size; height not required to align.',
              ScaleAxis.height => 'ℹ height axis fits design size; width not required to align.',
              ScaleAxis.shorter => 'ℹ shorter selects min scale; entire design fits viewport.',
              ScaleAxis.longer => 'ℹ longer selects max scale; at least one axis fits.',
            };

  return (matched: matched, message: message, fitMessage: fitMessage);
}

String _fmt(Size size) =>
    '${size.width.toStringAsFixed(1)} × ${size.height.toStringAsFixed(1)}';

/// 顶部深色调试面板：实时显示当前 design / origin / MQ / scale / axis
/// 等运行时数据，并根据当前 [ScaleAxis] 校验对应的契约（见 [checkContract]）。
class DebugPanel extends StatelessWidget {
  const DebugPanel({
    super.key,
    required this.designSize,
    required this.scaleAxis,
    required this.minScale,
    required this.maxScale,
  });

  final Size designSize;
  final ScaleAxis scaleAxis;
  final double? minScale;
  final double? maxScale;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);
    final origin = ScreenSizeAdapter.originSizeOf(context);
    final scale = ScreenSizeAdapter.scaleOf(context);
    final isLandscape = origin.width > origin.height;

    final contract = checkContract(
      axis: scaleAxis,
      mq: mq,
      origin: origin,
      scale: scale,
      design: designSize,
      minScale: minScale,
      maxScale: maxScale,
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
          InfoRow.dark(label: 'Design size', value: _fmt(designSize)),
          InfoRow.dark(label: 'Physical size (origin)', value: _fmt(origin)),
          InfoRow.dark(label: 'MediaQuery size', value: _fmt(mq)),
          InfoRow.dark(label: 'Current scale', value: scale.toStringAsFixed(3)),
          InfoRow.dark(label: 'Current axis', value: scaleAxis.name),
          InfoRow.dark(
            label: 'scale bounds',
            value: '${_bound(minScale)} – ${_bound(maxScale)}',
          ),
          InfoRow.dark(
            label: 'Orientation',
            value: isLandscape ? 'landscape' : 'portrait',
          ),
          const SizedBox(height: 8),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 6),
          _ContractCheck(matched: contract.matched, message: contract.message),
          const SizedBox(height: 4),
          Text(
            contract.fitMessage,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  static String _bound(double? value) => value?.toStringAsFixed(2) ?? 'Unlimited';
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
            'screen_size_adapter · Live Debugging',
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
