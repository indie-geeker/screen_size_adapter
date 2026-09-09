import 'package:flutter/material.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

import 'comparison_settings.dart';

class ComparisonSettingsSheet extends StatefulWidget {
  const ComparisonSettingsSheet({
    super.key,
    required this.settings,
    required this.adapted,
  });

  final ComparisonSettings settings;
  final bool adapted;

  @override
  State<ComparisonSettingsSheet> createState() =>
      _ComparisonSettingsSheetState();
}

class _ComparisonSettingsSheetState extends State<ComparisonSettingsSheet> {
  late ComparisonSettings _draft = widget.settings;

  @override
  Widget build(BuildContext context) {
    // Subscribe inside the route so a window resize also refreshes its preview.
    final window = ScreenSizeAdapter.originSizeOf(context);
    final scale = _draft.scaleFor(window, adapted: widget.adapted);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: FractionallySizedBox(
        heightFactor: 0.92,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('settings-scroll'),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('对照设置', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Text('调整后点击应用，取消则保留原设置。'),
                    const SizedBox(height: 24),
                    _picker<ScaleAxis>(
                      id: 'axis-picker',
                      label: '缩放基准',
                      value: _draft.axis,
                      items: [
                        for (final axis in ScaleAxis.values)
                          DropdownMenuItem(
                            value: axis,
                            child: Text(axis.label),
                          ),
                      ],
                      onChanged: (axis) {
                        if (axis != null) {
                          setState(() => _draft = _draft.copyWith(axis: axis));
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    _picker<Size>(
                      id: 'reference-picker',
                      label: '参考设计稿',
                      value: _draft.referenceSize,
                      items: [
                        for (final size in ComparisonSettings.presets)
                          DropdownMenuItem(
                            value: size,
                            child: Text(formatSize(size)),
                          ),
                      ],
                      onChanged: (size) {
                        if (size != null) {
                          setState(
                            () => _draft = _draft.copyWith(referenceSize: size),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    _picker<DesignOrientation>(
                      id: 'orientation-picker',
                      label: '设计稿方向',
                      value: _draft.orientation,
                      items: [
                        for (final orientation in DesignOrientation.values)
                          DropdownMenuItem(
                            value: orientation,
                            child: Text(orientation.label),
                          ),
                      ],
                      onChanged: (orientation) {
                        if (orientation != null) {
                          setState(
                            () =>
                                _draft = _draft.copyWith(
                                  orientation: orientation,
                                ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '仅选择设计稿宽高顺序，不改变设备方向。',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '应用后设计稿 ${formatSize(_draft.designSizeFor(window))}',
                      key: const ValueKey('draft-design'),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '预计倍率 ${scale.toStringAsFixed(3)}×',
                      key: const ValueKey('draft-scale'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.adapted
                          ? _draft.calculationFor(window)
                          : '设置将在开启适配时生效',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      key: const ValueKey('reset-settings'),
                      onPressed:
                          () => setState(
                            () => _draft = const ComparisonSettings(),
                          ),
                      child: const Text('恢复默认'),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      TextButton(
                        key: const ValueKey('cancel-settings'),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                      FilledButton(
                        key: const ValueKey('apply-settings'),
                        onPressed: () => Navigator.pop(context, _draft),
                        child: const Text('应用'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _picker<T>({
  required String id,
  required String label,
  required T value,
  required List<DropdownMenuItem<T>> items,
  required ValueChanged<T?> onChanged,
}) => InputDecorator(
  decoration: InputDecoration(labelText: label),
  child: DropdownButtonHideUnderline(
    child: DropdownButton<T>(
      key: ValueKey(id),
      value: value,
      isExpanded: true,
      isDense: false,
      itemHeight: null,
      items: items,
      onChanged: onChanged,
    ),
  ),
);
