import 'package:flutter/material.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

// snippet:runtime-updates:start
class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool adapted = true;

  @override
  Widget build(BuildContext context) => ScreenSizeAdapter(
    enabled: adapted,
    config: const ScreenSizeAdapterConfig(designSize: Size(375, 812)),
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: Switch(
            value: adapted,
            onChanged: (value) => setState(() => adapted = value),
          ),
        ),
      ),
    ),
  );
}
// snippet:runtime-updates:end
