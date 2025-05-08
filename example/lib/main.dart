import 'package:flutter/material.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  ScreenSizeWidgetsFlutterBinding.ensureInitialized(Size(360, 640));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: 360,
              height: 100,
              color: Colors.green,
              child: Text('宽度：360\n高度：100'),
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              height: 100,
              color: Colors.yellow,
              child: Text('宽度：MediaQuery.of(context).size.width\n高度：100'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 120,
                  height: 100,
                  color: Colors.pink[200],
                  child: Text('宽度：120 \n高度：100'),
                ),
                Expanded(
                  child: Container(
                    height: 100,
                    color: Colors.deepOrange[200],
                    child: Text('宽度：Expanded \n高度：100'),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 180.vw,
                  height: 100,
                  color: Colors.lightGreen,
                  child: Text('宽度：180 vw\n高度：100'),
                ),
                Container(
                  width: 180.vw,
                  height: 100,
                  color: Colors.pink,
                  child: Text('宽度：180 vw\n高度：100'),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 180.vw,
                  height: 100.vh,
                  color: Colors.grey,
                  child: Text('宽度：180 vw\n高度：100 vh'),
                ),
                Container(
                  width: 180.vw,
                  height: 100.vh,
                  color: Colors.lightBlueAccent,
                  child: Text('宽度：180 vw\n高度：100 vh'),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 180.vw,
                  height: 180.vw,
                  color: Colors.blue,
                  child: Text('宽度：180 vw\n高度：180 vw'),
                ),
                Container(
                  width: 180.vw,
                  height: 180.vw,
                  color: Colors.grey,
                  child: Text('宽度：180 vw\n高度：180 vw'),
                ),
              ],
            ),

            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              color: Colors.cyan,
              child: Text(
                '宽度：MediaQuery.of(context).size.width\n高度：MediaQuery.of(context).size.height',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
