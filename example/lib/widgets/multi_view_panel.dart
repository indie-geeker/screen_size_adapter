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
/// 嵌入 / Add-to-App 会出现多条记录。这里如实显示，不创建二级 view，也不
/// 把 registry 观测结果当作真实宿主验证。
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
      title: 'Experimental View Registry Checker',
      subtitle: 'Checks registry only; secondary view integration must be verified on a real host',
      accent: Colors.blueGrey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total ${views.length} FlutterView(s)'
            '${views.length == 1 ? " (default on mobile; multiple on desktop multi-window)" : ""}',
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          for (final v in views) _ViewRow(view: v, binding: adapterBinding),
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
    final config = binding?.configForView(view);
    final scale = binding?.scaleForView(view);
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
            '${config == null ? " (unregistered — native Flutter behavior)" : " (registered)"}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          InfoRow(
            label: 'physicalSize',
            value: '${phys.width.toInt()} × ${phys.height.toInt()}',
          ),
          InfoRow(label: 'devicePixelRatio', value: dpr.toStringAsFixed(2)),
          InfoRow(
            label: 'Registered designSize',
            value:
                config == null
                    ? '—'
                    : '${config.designSize.width.toInt()}×'
                        '${config.designSize.height.toInt()}',
          ),
          InfoRow(label: 'Current scale', value: scale?.toStringAsFixed(3) ?? '—'),
          InfoRow(label: 'scaleAxis', value: config?.scaleAxis.name ?? '—'),
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
      'This panel only checks the experimental registry, does not create secondary FlutterViews, and is not a substitute for real host verification. '
      'In scenarios like desktop multi-window, runWidget + View, ViewAnchor, Add-to-App, etc., '
      'calling binding.attachView(view: ..., config: ...) for each non-primary view '
      'can experimentally configure independent scaling; also remember to wrap a ScreenSizeAdapterScope outside the View subtree '
      'to ensure MediaQuery reports dimensions using the corresponding scale. Full host verification checklist: '
      'tool/verification/desktop_multi_view.md.',
      style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.5),
    );
  }
}
