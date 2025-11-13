import 'package:flutter/material.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  ScreenSizeWidgetsFlutterBinding.ensureInitialized(Size(360, 640));
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
    // 获取适配信息用于调试
    final helper = ScreenSizeHelper.instance;
    final screenSize = MediaQuery.of(context).size;
    final originSize = helper.originMediaQueryData.size;
    final scale = helper.scale;

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
              padding: EdgeInsets.all(16.dp),
              color: Colors.black87,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📊 屏幕适配调试信息',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.dp),
                  _buildInfoRow('设计尺寸', '${helper.designSize.width.toStringAsFixed(1)} x ${helper.designSize.height.toStringAsFixed(1)}'),
                  _buildInfoRow('实际物理尺寸', '${originSize.width.toStringAsFixed(1)} x ${originSize.height.toStringAsFixed(1)}'),
                  _buildInfoRow('MediaQuery尺寸', '${screenSize.width.toStringAsFixed(1)} x ${screenSize.height.toStringAsFixed(1)}'),
                  _buildInfoRow('缩放比例 (scale)', '${scale.toStringAsFixed(3)}'),
                  SizedBox(height: 8.dp),
                  Divider(color: Colors.white24),
                  SizedBox(height: 4.dp),
                  Text(
                    '✅ 适配验证:',
                    style: TextStyle(color: Colors.yellow, fontSize: 14.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4.dp),
                  _buildInfoRow(
                    'MediaQuery 是否被缩放',
                    (screenSize.width - originSize.width).abs() > 0.1
                        ? '✅ 是 (${(originSize.width - screenSize.width).toStringAsFixed(1)}px差异)'
                        : '❌ 否 (无缩放)',
                  ),
                  _buildInfoRow(
                    'MediaQuery ≈ 设计宽度',
                    () {
                      // 横屏模式下检查 height，竖屏模式下检查 width
                      final isLandscape = helper.isLandscape;
                      final targetSize = isLandscape ? screenSize.height : screenSize.width;
                      final diff = (targetSize - helper.designSize.width).abs();

                      if (diff < 0.1) {
                        return '✅ 是 (适配生效)${isLandscape ? " [横屏]" : ""}';
                      } else {
                        return '❌ 否 (差${diff.toStringAsFixed(1)}px)';
                      }
                    }(),
                  ),
                  SizedBox(height: 8.dp),
                  Text(
                    '💡 重要提示：',
                    style: TextStyle(color: Colors.orange, fontSize: 12.sp),
                  ),
                  Text(
                    helper.isLandscape
                        ? '横屏模式：MediaQuery.height ≈ 设计宽度\n'
                          '适配基于高度，两个 180.dp 仍会充满屏幕宽度'
                        : '竖屏模式：180.dp = 180 (数学必然)\n'
                          '适配通过 MediaQuery 实现，而非 .dp 扩展',
                    style: TextStyle(color: Colors.white70, fontSize: 11.sp),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.dp),

            // 标题提示
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(16.dp),
              padding: EdgeInsets.all(12.dp),
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
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  SizedBox(height: 8.dp),
                  Text(
                    '✅ 正确验证方法：\n'
                    '• 【最佳】两个(设计宽度/2).dp矩形能充满屏幕\n'
                    '• 查看上方调试面板的"适配验证"部分\n'
                    '• MediaQuery 宽度应该等于设计宽度\n'
                    '• 在不同设备(平板/手机)上对比视觉占比\n\n'
                    '❌ 错误验证方法：\n'
                    '• 对比 180.dp 和 180 的差异(竖屏下永远为0)\n'
                    '• 修改设计尺寸后期望界面不变',
                    style: TextStyle(fontSize: 12.sp, color: Colors.black87, height: 1.5),
                  ),
                ],
              ),
            ),

            // 对比示例 1：说明
            Padding(
              padding: EdgeInsets.all(8.dp),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '示例 1: 180.vw = 180 的证明',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                  ),
                  SizedBox(height: 4.dp),
                  Text(
                    '在竖屏模式下，这两个方块始终相同大小（数学必然）',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  width: 180.vw,
                  height: 100.vw,
                  color: Colors.green,
                  alignment: Alignment.center,
                  child: Text(
                    '180.vw\n${180.vw.toStringAsFixed(1)}px',
                    style: TextStyle(color: Colors.white, fontSize: 12.sp),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  width: 180,
                  height: 100,
                  color: Colors.green, // 改为相同颜色表示它们相等
                  alignment: Alignment.center,
                  child: Text(
                    '180\n${180.toStringAsFixed(1)}px',
                    style: TextStyle(color: Colors.white, fontSize: 12.sp),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.dp),

            // 对比示例 2：MediaQuery 的适配效果
            Padding(
              padding: EdgeInsets.all(8.dp),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '示例 2: MediaQuery 的适配效果（真正的验证）',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                  ),
                  SizedBox(height: 4.dp),
                  Text(
                    helper.isLandscape
                        ? 'MediaQuery 被缩放：横屏下 height ≈ 设计宽度'
                        : 'MediaQuery 被缩放：竖屏下 width ≈ 设计宽度',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 8.dp),
              padding: EdgeInsets.all(12.dp),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                border: Border.all(color: Colors.purple, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    helper.isLandscape ? '屏幕尺寸对比 (横屏模式):' : '屏幕宽度对比 (竖屏模式):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
                  ),
                  SizedBox(height: 8.dp),
                  // 显示实际设备尺寸
                  Row(
                    children: [
                      Container(width: 10, height: 10, color: Colors.orange),
                      SizedBox(width: 8.dp),
                      Expanded(
                        child: Text(
                          helper.isLandscape
                              ? '实际设备尺寸: ${originSize.width.toStringAsFixed(1)} x ${originSize.height.toStringAsFixed(1)} px (宽x高)'
                              : '实际设备宽度: ${originSize.width.toStringAsFixed(1)} px',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.dp),
                  // 显示 MediaQuery 尺寸
                  Row(
                    children: [
                      Container(width: 10, height: 10, color: Colors.green),
                      SizedBox(width: 8.dp),
                      Expanded(
                        child: Text(
                          helper.isLandscape
                              ? 'MediaQuery 尺寸: ${screenSize.width.toStringAsFixed(1)} x ${screenSize.height.toStringAsFixed(1)} px (被缩放)'
                              : 'MediaQuery 宽度: ${screenSize.width.toStringAsFixed(1)} px (被缩放)',
                          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.dp),
                  // 显示设计稿宽度
                  Row(
                    children: [
                      Container(width: 10, height: 10, color: Colors.blue),
                      SizedBox(width: 8.dp),
                      Expanded(
                        child: Text(
                          '设计稿宽度: ${helper.designSize.width.toStringAsFixed(1)} px',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.dp),
                  // 验证结果
                  Text(
                    () {
                      // 横屏检查 height，竖屏检查 width
                      final targetSize = helper.isLandscape ? screenSize.height : screenSize.width;
                      final diff = (targetSize - helper.designSize.width).abs();

                      if (diff < 0.1) {
                        return helper.isLandscape
                            ? '✅ MediaQuery.height ≈ 设计宽度 → 适配生效！[横屏]'
                            : '✅ MediaQuery.width ≈ 设计宽度 → 适配生效！';
                      } else {
                        return '⚠️ MediaQuery ${helper.isLandscape ? "height" : "width"} ≠ 设计宽度 → 检查配置';
                      }
                    }(),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: () {
                        final targetSize = helper.isLandscape ? screenSize.height : screenSize.width;
                        final diff = (targetSize - helper.designSize.width).abs();
                        return diff < 0.1 ? Colors.green[800] : Colors.red[800];
                      }(),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.dp),

            // 对比示例 3：充满屏幕宽度验证（最佳验证方法）
            Padding(
              padding: EdgeInsets.all(8.dp),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '示例 3: 充满屏幕验证（最佳方法）',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                  ),
                  SizedBox(height: 4.dp),
                  Text(
                    helper.isLandscape
                        ? '设计宽度=${helper.designSize.width.toInt()}，横屏下${(helper.designSize.width/2).toInt()}.dp ≠ ${(helper.designSize.width/2).toInt()}，但两个仍应充满屏幕'
                        : '设计宽度=${helper.designSize.width.toInt()}，两个${(helper.designSize.width/2).toInt()}.dp矩形应该正好充满屏幕',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Container(
                  width: (helper.designSize.width / 2).dp,
                  height: 60.dp,
                  color: Colors.blue,
                  alignment: Alignment.center,
                  child: Text(
                    '${(helper.designSize.width / 2).toInt()}.dp',
                    style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  width: (helper.designSize.width / 2).dp,
                  height: 60.dp,
                  color: Colors.orange,
                  alignment: Alignment.center,
                  child: Text(
                    '${(helper.designSize.width / 2).toInt()}.dp',
                    style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(8.dp),
              child: Text(
                () {
                  // 计算两个矩形的实际总宽度
                  final totalWidth = (helper.designSize.width / 2).dp * 2;
                  final isFullWidth = (totalWidth - screenSize.width).abs() < 0.1;

                  if (isFullWidth) {
                    return '✅ 两个矩形正好充满屏幕 → 适配成功！';
                  } else {
                    final diff = (totalWidth - screenSize.width).abs().toStringAsFixed(0);
                    return '❌ 两个矩形${totalWidth < screenSize.width ? "未充满" : "超出"}屏幕 (差${diff}px) → 检查配置';
                  }
                }(),
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: () {
                    final totalWidth = (helper.designSize.width / 2).dp * 2;
                    return (totalWidth - screenSize.width).abs() < 0.1
                        ? Colors.green[800]
                        : Colors.red[800];
                  }(),
                ),
              ),
            ),

            SizedBox(height: 16.dp),

            // 对比示例 4：不同大小
            Padding(
              padding: EdgeInsets.all(8.dp),
              child: Text(
                '示例 4: 不同尺寸对比',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.dp),
              ),
            ),
            Wrap(
              spacing: 8.dp,
              runSpacing: 8.dp,
              children: [
                _buildBox(100.dp, 100.dp, '100.dp', Colors.blue),
                _buildBox(150.dp, 150.dp, '150.dp', Colors.purple),
                _buildBox(200.dp, 200.dp, '200.dp', Colors.orange),
              ],
            ),

            SizedBox(height: 16.dp),

            // 对比示例 4：字体大小
            Padding(
              padding: EdgeInsets.all(8.dp),
              child: Text(
                '示例 4: 字体大小适配',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
              ),
            ),
            Container(
              padding: EdgeInsets.all(16.dp),
              color: Colors.grey[200],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('12.sp 适配字体', style: TextStyle(fontSize: 12.sp)),
                  Text('14.sp 适配字体', style: TextStyle(fontSize: 14.sp)),
                  Text('16.sp 适配字体', style: TextStyle(fontSize: 16.sp)),
                  Text('18.sp 适配字体', style: TextStyle(fontSize: 18.sp)),
                  SizedBox(height: 8.dp),
                  Text('14 固定字体 (无适配)', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),

            SizedBox(height: 100.dp),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
          Text(value, style: TextStyle(color: Colors.greenAccent, fontSize: 12.sp)),
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
        style: TextStyle(color: Colors.white, fontSize: 10.sp),
        textAlign: TextAlign.center,
      ),
    );
  }
}
