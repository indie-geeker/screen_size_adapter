import 'package:flutter/material.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

import 'comparison_page.dart';
import 'comparison_settings.dart';

/// The same page and state in both modes; no simulated device or second backend.
class ComparisonApp extends StatefulWidget {
  const ComparisonApp({super.key});

  @override
  State<ComparisonApp> createState() => _ComparisonAppState();
}

class _ComparisonAppState extends State<ComparisonApp> {
  bool _adapted = true;
  ComparisonSettings _settings = const ComparisonSettings();

  @override
  Widget build(BuildContext context) => ScreenSizeAdapter(
    enabled: _adapted,
    // This context is above the adapter: orientation uses the native window.
    config: _settings.configFor(MediaQuery.sizeOf(context)),
    child: MaterialApp(
      title: '屏幕适配对照',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF245FE5)),
        scaffoldBackgroundColor: const Color(0xFFF4F6FA),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: ComparisonPage(
        adapted: _adapted,
        settings: _settings,
        onModeChanged: (value) => setState(() => _adapted = value),
        onSettingsChanged: (value) => setState(() => _settings = value),
      ),
    ),
  );
}
