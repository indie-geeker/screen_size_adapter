import 'package:flutter/material.dart';

/// 两个 designW/2 的矩形并排：在 [ScaleAxis.width] 下应该正好充满
/// 整个屏幕宽度。其它 axis 下会有余白或溢出，刚好可视化 trade-off。
///
/// 这个 demo 不能塞进有横向 padding 的卡片里——契约是"两矩形宽度
/// 之和 == MQ.width"，必须 flush 到屏幕边缘才能可视化生效与否。
class FillWidthDemo extends StatelessWidget {
  const FillWidthDemo({super.key, required this.designSize});

  final Size designSize;

  @override
  Widget build(BuildContext context) {
    final half = designSize.width / 2;
    final mqWidth = MediaQuery.sizeOf(context).width;
    final totalWidth = half * 2;
    final delta = totalWidth - mqWidth;
    final filled = delta.abs() < 0.5;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: _Header(half: half, mqWidth: mqWidth),
          ),
          Row(
            children: [
              _Box(width: half, color: Colors.indigo, label: '${half.toInt()}'),
              _Box(width: half, color: Colors.orange, label: '${half.toInt()}'),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              _verdict(filled: filled, delta: delta),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: filled ? Colors.green.shade800 : Colors.red.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _verdict({required bool filled, required double delta}) {
    if (filled) return '✅ 两个矩形正好充满 → ScaleAxis.width 契约生效';
    final dir = delta > 0 ? '溢出' : '未充满';
    return '$dir ${delta.abs().toStringAsFixed(1)}px '
        '— 当前 axis 下设计稿不再"宽度对齐"，属于其它 axis 的预期 trade-off';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.half, required this.mqWidth});

  final double half;
  final double mqWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '充满宽度验证（最佳验证方法）',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.indigo.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '两个宽 ${half.toInt()} 的矩形 → 期望刚好等于 MediaQuery.width '
          '(${mqWidth.toStringAsFixed(1)})',
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.width, required this.color, required this.label});

  final double width;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 60,
      color: color,
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
