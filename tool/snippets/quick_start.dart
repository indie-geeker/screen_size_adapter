// snippet:quick-start:start
import 'package:flutter/material.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  ScreenSizeWidgetsFlutterBinding.ensureInitialized(
    const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(home: HomePage());
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Container(
        width: 200,
        height: 100,
        padding: const EdgeInsets.all(16),
        color: Colors.blue,
        child: const Text('Hello', style: TextStyle(fontSize: 14)),
      ),
    ),
  );
}

// snippet:quick-start:end
