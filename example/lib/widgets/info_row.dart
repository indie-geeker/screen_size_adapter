import 'package:flutter/material.dart';

/// 标签 + 数值 的一行显示。深色背景下用 [InfoRow.dark]，
/// 浅色背景下用默认构造。
class InfoRow extends StatelessWidget {
  static const double _stackBreakpoint = 240;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.labelColor = Colors.black54,
    this.valueColor = Colors.black87,
  });

  const InfoRow.dark({super.key, required this.label, required this.value})
    : labelColor = Colors.white70,
      valueColor = Colors.greenAccent;

  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final labelText = Text(
            '$label:',
            textAlign: TextAlign.left,
            style: TextStyle(color: labelColor, fontSize: 12),
          );
          final valueText = Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(color: valueColor, fontSize: 12),
          );

          // Below 240 logical units, the 8-unit gap leaves less than 116 units
          // per side, so stacking preserves more readable wrapping widths.
          if (constraints.maxWidth < _stackBreakpoint) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [labelText, const SizedBox(height: 2), valueText],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: labelText),
              const SizedBox(width: 8),
              Expanded(child: valueText),
            ],
          );
        },
      ),
    );
  }
}
