import 'package:flutter/material.dart';

/// 标签 + 数值 的一行显示。深色背景下用 [InfoRow.dark]，
/// 浅色背景下用默认构造。
class InfoRow extends StatelessWidget {
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: TextStyle(color: labelColor, fontSize: 12)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(color: valueColor, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
