import 'package:flutter/material.dart';

/// 通用区块卡：一个浅色边框 + 标题 + 子内容。
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.accent = Colors.indigo,
    this.background,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Color accent;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background ?? accent.withValues(alpha: 0.06),
        border: Border.all(color: accent, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: accent.shade700OrBlack,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

extension on Color {
  /// `MaterialColor.shade700` 兜底为黑：传 `Colors.indigo` 取深色版，
  /// 传普通 `Color` 直接返回黑色避免空指针。
  Color get shade700OrBlack {
    final self = this;
    if (self is MaterialColor) return self.shade700;
    return Colors.black87;
  }
}
