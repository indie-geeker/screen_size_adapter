import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

import 'info_row.dart';
import 'section_card.dart';

/// 列出 [PlatformDispatcher.views] 中所有 [FlutterView] 及其在
/// binding registry 中的状态：每个 view 的 viewId、physicalSize、
/// devicePixelRatio、当前 scale、registered designSize。
///
/// 移动端通常只有一个 implicit view；桌面多窗 / `runWidget` + `View`
/// 嵌入 / Add-to-App 会出现多条记录。这里如实显示——不伪造。
class MultiViewPanel extends StatefulWidget {
  const MultiViewPanel({super.key});

  @override
  State<MultiViewPanel> createState() => _MultiViewPanelState();
}

class _MultiViewPanelState extends State<MultiViewPanel>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final binding = WidgetsBinding.instance;
    final adapterBinding =
        binding is ScreenSizeWidgetsFlutterBinding ? binding : null;
    final views = PlatformDispatcher.instance.views.toList();

    return SectionCard(
      title: '多视图（per-view registry）',
      subtitle: '当前进程内的所有 FlutterView 及其在 binding 中的注册状态',
      accent: Colors.blueGrey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '共 ${views.length} 个 FlutterView'
            '${views.length == 1 ? "（移动端默认值；桌面多窗会出现多个）" : ""}',
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          for (final v in views)
            _ViewRow(view: v, binding: adapterBinding),
          const SizedBox(height: 8),
          const _MultiViewHint(),
        ],
      ),
    );
  }
}

class _ViewRow extends StatelessWidget {
  const _ViewRow({required this.view, required this.binding});

  final FlutterView view;
  final ScreenSizeWidgetsFlutterBinding? binding;

  @override
  Widget build(BuildContext context) {
    final config = binding?.configForViewId(view.viewId);
    final scale = binding?.scaleForViewId(view.viewId);
    final phys = view.physicalSize;
    final dpr = view.devicePixelRatio;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blueGrey.shade200),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'viewId = ${view.viewId}'
            '${config == null ? "（未注册 — 走 Flutter 原生行为）" : "（已注册）"}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          InfoRow(
            label: 'physicalSize',
            value: '${phys.width.toInt()} × ${phys.height.toInt()}',
          ),
          InfoRow(label: 'devicePixelRatio', value: dpr.toStringAsFixed(2)),
          InfoRow(
            label: '注册的 designSize',
            value: config == null
                ? '—'
                : '${config.designSize.width.toInt()}×'
                    '${config.designSize.height.toInt()}',
          ),
          InfoRow(label: '当前 scale', value: scale?.toStringAsFixed(3) ?? '—'),
          InfoRow(
            label: 'scaleAxis',
            value: config?.scaleAxis.name ?? '—',
          ),
        ],
      ),
    );
  }
}

class _MultiViewHint extends StatelessWidget {
  const _MultiViewHint();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '在桌面多窗、runWidget + View、ViewAnchor、Add-to-App 等场景，'
      '为每个非主 view 调 binding.attachView(view: ..., designSize: ...) '
      '即可让它们各自独立适配；同时记得在 View 子树外手包 ScreenSizeAdapterScope，'
      '保证 MediaQuery 也按对应的 scale 报告尺寸。',
      style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.5),
    );
  }
}
