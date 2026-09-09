// snippet:quick-start:start
import 'package:flutter/material.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

void main() {
  runApp(
    const ScreenSizeAdapter(
      config: ScreenSizeAdapterConfig(designSize: Size(375, 812)),
      child: MaterialApp(
        home: Scaffold(body: Center(child: SizedBox(width: 280, height: 64))),
      ),
    ),
  );
}
// snippet:quick-start:end
