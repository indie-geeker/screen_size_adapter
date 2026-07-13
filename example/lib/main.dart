import 'dart:async' show Timer;
import 'dart:io' show exit, stdout;

import 'package:flutter/material.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

import 'pages/home_page.dart';
import 'state/adapter_settings.dart';

const _startupSmoke = bool.fromEnvironment('SCREEN_SIZE_ADAPTER_STARTUP_SMOKE');

void main() {
  final binding = ScreenSizeWidgetsFlutterBinding.ensureInitialized(
    const ScreenSizeAdapterConfig(
      designSize: kPortraitDesign,
      enableDesktopScaling: true,
    ),
  );

  if (_startupSmoke) {
    binding.addPostFrameCallback((_) {
      stdout.writeln('SCREEN_SIZE_ADAPTER_STARTUP_READY');
      Timer(const Duration(seconds: 1), () => exit(0));
    });
  }

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
