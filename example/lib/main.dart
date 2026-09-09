import 'dart:async' show Timer;
import 'dart:io' show exit, stdout;

import 'package:flutter/material.dart';

import 'comparison_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (const bool.fromEnvironment('SCREEN_SIZE_ADAPTER_STARTUP_SMOKE')) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      stdout.writeln('SCREEN_SIZE_ADAPTER_STARTUP_READY');
      Timer(const Duration(seconds: 1), () => exit(0));
    });
  }
  runApp(const ComparisonApp());
}
