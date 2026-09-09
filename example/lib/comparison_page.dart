import 'package:flutter/material.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

import 'comparison_settings.dart';
import 'comparison_settings_sheet.dart';

class ComparisonPage extends StatefulWidget {
  const ComparisonPage({
    super.key,
    required this.adapted,
    required this.settings,
    required this.onModeChanged,
    required this.onSettingsChanged,
  });

  final bool adapted;
  final ComparisonSettings settings;
  final ValueChanged<bool> onModeChanged;
  final ValueChanged<ComparisonSettings> onSettingsChanged;

  @override
  State<ComparisonPage> createState() => _ComparisonPageState();
}

class _ComparisonPageState extends State<ComparisonPage> {
  final _text = TextEditingController();
  int _clicks = 0;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _openSettings() async {
    final navigator = Navigator.of(context);
    final route = ModalBottomSheetRoute<ComparisonSettings>(
      isScrollControlled: true,
      useSafeArea: true,
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      builder:
          (context) => ComparisonSettingsSheet(
            settings: widget.settings,
            adapted: widget.adapted,
          ),
    );
    final result = await navigator.push(route);
    // Apply after the exit transition, so the sheet closes at its original scale.
    await route.completed;
    if (mounted && result != null) widget.onSettingsChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ScreenSizeAdapter.of(context);
    final scale = metrics.scale;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          key: const ValueKey('page-scroll'),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '屏幕适配对照',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    TextButton(
                      key: const ValueKey('open-settings'),
                      onPressed: _openSettings,
                      child: const Text('设置'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  for (final mode in [true, false])
                    ChoiceChip(
                      key: ValueKey(mode ? 'adapted-mode' : 'native-mode'),
                      label: Text(mode ? '适配' : '未适配'),
                      selected: widget.adapted == mode,
                      onSelected: (_) => widget.onModeChanged(mode),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${widget.settings.axis.label} · 当前设计稿 ${formatSize(widget.settings.designSizeFor(metrics.originSize))}',
                key: const ValueKey('configuration-label'),
              ),
              const SizedBox(height: 6),
              Text(
                '窗口 ${formatSize(metrics.originSize)} → 布局 ${formatSize(metrics.designSize)}',
                key: const ValueKey('window-label'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              Text(
                '倍率 ${scale.toStringAsFixed(3)}×',
                key: const ValueKey('scale-label'),
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                widget.adapted
                    ? widget.settings.calculationFor(metrics.originSize)
                    : '未适配 · 使用窗口原始逻辑像素',
                key: const ValueKey('calculation-label'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              _label(context, '01', '看尺寸'),
              const SizedBox(height: 12),
              // Fixed design numbers. Scrolling horizontally keeps the sample
              // inspectable even when the native window is narrower than 280.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      key: const ValueKey('size-block'),
                      width: 280,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '280 × 64',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          key: const ValueKey('size-circle'),
                          width: 64,
                          height: 64,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Text('64'),
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('文字也等比缩放', style: TextStyle(fontSize: 16)),
                            SizedBox(height: 4),
                            Text(
                              '字号 16 · 圆形直径 64',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '可见色块约 ${formatSize(Size(280 * scale, 64 * scale))} 逻辑像素',
                key: const ValueKey('block-size-label'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              _label(context, '02', '试交互'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton(
                    key: const ValueKey('count-button'),
                    onPressed: () => setState(() => _clicks++),
                    child: Text('点击计数 $_clicks'),
                  ),
                  OutlinedButton(
                    key: const ValueKey('dialog-button'),
                    onPressed:
                        () => showDialog<void>(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('检查弹窗位置'),
                                content: const Text('弹窗应在当前窗口内居中，按钮可以正常点击。'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('关闭'),
                                  ),
                                ],
                              ),
                        ),
                    child: const Text('打开弹窗'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('sample-input'),
                controller: _text,
                decoration: const InputDecoration(
                  labelText: '输入一段文字',
                  hintText: '切换模式后，内容仍保留',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '可检查文字选择和键盘位置；当前 Flutter SDK 的缩放选区仍有已知问题。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                '旋转设备或调整窗口，再切换查看。适配时页面使用设计单位；未适配时使用窗口原始逻辑像素。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String number, String title) => Row(
    children: [
      Text(
        number,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ],
  );
}
