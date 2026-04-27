import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

const Size _designSize = Size(360, 640);

void main() {
  ScreenSizeWidgetsFlutterBinding.ensureInitialized(_designSize);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScreenSizeAdapter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'ScreenSizeAdapter Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // 适配后的 MediaQuery（被 binding 缩放至设计尺寸）
    final screenSize = MediaQuery.sizeOf(context);

    // 真实的物理尺寸（未被缩放）
    final view = View.of(context);
    final originDpr =
        PlatformDispatcher.instance.implicitView?.devicePixelRatio ??
            view.devicePixelRatio;
    final originSize = Size(
      view.physicalSize.width / originDpr,
      view.physicalSize.height / originDpr,
    );

    final scale = ScreenSizeAdapter.scaleOf(context);
    final designSize = _designSize;
    final isLandscape = originSize.width > originSize.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 调试信息面板
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.black87,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📊 屏幕适配调试信息',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    '设计尺寸',
                    '${designSize.width.toStringAsFixed(1)} x ${designSize.height.toStringAsFixed(1)}',
                  ),
                  _buildInfoRow(
                    '实际物理尺寸',
                    '${originSize.width.toStringAsFixed(1)} x ${originSize.height.toStringAsFixed(1)}',
                  ),
                  _buildInfoRow(
                    'MediaQuery尺寸',
                    '${screenSize.width.toStringAsFixed(1)} x ${screenSize.height.toStringAsFixed(1)}',
                  ),
                  _buildInfoRow('缩放比例 (scale)', scale.toStringAsFixed(3)),
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 4),
                  const Text(
                    '✅ 适配验证:',
                    style: TextStyle(
                      color: Colors.yellow,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildInfoRow(
                    'MediaQuery 是否被缩放',
                    (screenSize.width - originSize.width).abs() > 0.1
                        ? '✅ 是 (${(originSize.width - screenSize.width).toStringAsFixed(1)}px差异)'
                        : '❌ 否 (无缩放)',
                  ),
                  _buildInfoRow('MediaQuery.width ≈ 设计宽度', () {
                    // 0.5.0 起 maxScale 默认 null，ScaleAxis.width 在横竖屏
                    // 都让 MediaQuery.width == designSize.width。
                    final diff = (screenSize.width - designSize.width).abs();
                    if (diff < 0.1) {
                      return '✅ 是 (适配生效)${isLandscape ? " [横屏]" : ""}';
                    }
                    return '❌ 否 (差${diff.toStringAsFixed(1)}px) — 检查 maxScale 是否被显式设置';
                  }()),
                  const SizedBox(height: 8),
                  const Text(
                    '💡 重要提示：',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                  Text(
                    isLandscape
                        ? '横屏：MediaQuery.width ≈ 设计宽度（裸数字 180 = 设计 180）\n'
                            'scale 跟随当前宽度变大；高度方向需要 ScrollView 处理纵向溢出'
                        : '竖屏：MediaQuery.width ≈ 设计宽度（裸数字 180 = 设计 180）\n'
                            'binding 缩放 + ScreenSizeAdapterScope 共同作用',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 标题提示
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔬 如何验证适配生效？',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '✅ 正确验证方法：\n'
                    '• 【最佳】两个 (设计宽度/2) 的矩形能充满屏幕\n'
                    '• 查看上方调试面板的"适配验证"部分\n'
                    '• MediaQuery 宽度应该等于设计宽度\n'
                    '• 在不同设备(平板/手机)上对比视觉占比\n\n'
                    '❌ 错误验证方法：\n'
                    '• 期望物理像素 == 设计尺寸（适配只缩 MediaQuery 与布局，不动物理尺寸）\n'
                    '• 修改设计尺寸后期望界面不变',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // 对比示例 1：说明
            const Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '示例 1: 裸数字 180 即设计稿 180',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '0.4.0 起直接写裸数字，两个方块大小完全相同',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  width: 180,
                  height: 100,
                  color: Colors.green,
                  alignment: Alignment.center,
                  child: const Text(
                    '180\n(设计稿)',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  width: 180,
                  height: 100,
                  color: Colors.green,
                  alignment: Alignment.center,
                  child: const Text(
                    '180\n(裸数字)',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 对比示例 2：MediaQuery 的适配效果
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '示例 2: MediaQuery 的适配效果（真正的验证）',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'MediaQuery 被缩放：横竖屏下 width 都 ≈ 设计宽度',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                border: Border.all(color: Colors.purple, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLandscape ? '屏幕尺寸对比 (横屏模式):' : '屏幕宽度对比 (竖屏模式):',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 显示实际设备尺寸
                  Row(
                    children: [
                      Container(width: 10, height: 10, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isLandscape
                              ? '实际设备尺寸: ${originSize.width.toStringAsFixed(1)} x ${originSize.height.toStringAsFixed(1)} px (宽x高)'
                              : '实际设备宽度: ${originSize.width.toStringAsFixed(1)} px',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 显示 MediaQuery 尺寸
                  Row(
                    children: [
                      Container(width: 10, height: 10, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isLandscape
                              ? 'MediaQuery 尺寸: ${screenSize.width.toStringAsFixed(1)} x ${screenSize.height.toStringAsFixed(1)} px (被缩放)'
                              : 'MediaQuery 宽度: ${screenSize.width.toStringAsFixed(1)} px (被缩放)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 显示设计稿宽度
                  Row(
                    children: [
                      Container(width: 10, height: 10, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '设计稿宽度: ${designSize.width.toStringAsFixed(1)} px',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 验证结果
                  Text(
                    () {
                      // 横竖屏统一：ScaleAxis.width 让 MediaQuery.width 永远等于设计宽度。
                      final diff = (screenSize.width - designSize.width).abs();
                      if (diff < 0.1) {
                        return '✅ MediaQuery.width ≈ 设计宽度 → 适配生效${isLandscape ? "（横屏）" : "（竖屏）"}';
                      }
                      return '⚠️ MediaQuery.width ≠ 设计宽度（差 ${diff.toStringAsFixed(1)}px）→ 检查 maxScale 设置';
                    }(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: (screenSize.width - designSize.width).abs() < 0.1
                          ? Colors.green[800]
                          : Colors.red[800],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 对比示例 3：充满屏幕宽度验证（最佳验证方法）
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '示例 3: 充满屏幕验证（最佳方法）',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '设计宽度=${designSize.width.toInt()}，两个 ${(designSize.width / 2).toInt()} 宽度的矩形应该正好充满屏幕',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Container(
                  width: designSize.width / 2,
                  height: 60,
                  color: Colors.blue,
                  alignment: Alignment.center,
                  child: Text(
                    '${(designSize.width / 2).toInt()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  width: designSize.width / 2,
                  height: 60,
                  color: Colors.orange,
                  alignment: Alignment.center,
                  child: Text(
                    '${(designSize.width / 2).toInt()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                () {
                  // 计算两个矩形的实际总宽度
                  final totalWidth = (designSize.width / 2) * 2;
                  final isFullWidth =
                      (totalWidth - screenSize.width).abs() < 0.1;

                  if (isFullWidth) {
                    return '✅ 两个矩形正好充满屏幕 → 适配成功！';
                  } else {
                    final diff = (totalWidth - screenSize.width)
                        .abs()
                        .toStringAsFixed(0);
                    return '❌ 两个矩形${totalWidth < screenSize.width ? "未充满" : "超出"}屏幕 (差${diff}px) → 检查配置';
                  }
                }(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: () {
                    final totalWidth = (designSize.width / 2) * 2;
                    return (totalWidth - screenSize.width).abs() < 0.1
                        ? Colors.green[800]
                        : Colors.red[800];
                  }(),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 对比示例 4：不同大小
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                '示例 4: 不同尺寸对比',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildBox(100, 100, '100', Colors.blue),
                _buildBox(150, 150, '150', Colors.purple),
                _buildBox(200, 200, '200', Colors.orange),
              ],
            ),

            const SizedBox(height: 16),

            // 对比示例 5：字体大小
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                '示例 5: 字体大小适配',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[200],
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('12 适配字体', style: TextStyle(fontSize: 12)),
                  Text('14 适配字体', style: TextStyle(fontSize: 14)),
                  Text('16 适配字体', style: TextStyle(fontSize: 16)),
                  Text('18 适配字体', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text(
                    '注：所有 fontSize 都会随 MediaQuery 自动适配',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 示例 6: 运行时切换设计尺寸
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                '示例 6: 运行时切换设计尺寸',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal[50],
                border: Border.all(color: Colors.teal, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '当前设计尺寸: ${designSize.width.toInt()} x ${designSize.height.toInt()}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () => ScreenSizeAdapter.setDesignSize(
                            context, const Size(360, 640)),
                        child: const Text(
                          '360x640',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => ScreenSizeAdapter.setDesignSize(
                            context, const Size(375, 667)),
                        child: const Text(
                          '375x667',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => ScreenSizeAdapter.setDesignSize(
                            context, const Size(390, 844)),
                        child: const Text(
                          '390x844',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 示例 7: scale 信息
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                '示例 7: scale 信息',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                border: Border.all(color: Colors.amber, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '当前 scale: ${scale.toStringAsFixed(3)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '提示：0.5.0 起默认无 maxScale 上限，确保横竖屏下 MediaQuery.width '
                    '都等于设计宽度。要在大屏限制缩放，显式传 maxScale。',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBox(double width, double height, String label, Color color) {
    return Container(
      width: width,
      height: height,
      color: color,
      alignment: Alignment.center,
      child: Text(
        '$label\n${width.toStringAsFixed(0)}px',
        style: const TextStyle(color: Colors.white, fontSize: 10),
        textAlign: TextAlign.center,
      ),
    );
  }
}
