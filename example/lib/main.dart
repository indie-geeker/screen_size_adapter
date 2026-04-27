import 'package:flutter/material.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

import 'pages/home_page.dart';
import 'state/adapter_settings.dart';

void main() {
  ScreenSizeWidgetsFlutterBinding.ensureInitialized(kPortraitDesign);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AdapterSettings _settings = AdapterSettings();

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'screen_size_adapter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomePage(settings: _settings),
    );
  }
}
