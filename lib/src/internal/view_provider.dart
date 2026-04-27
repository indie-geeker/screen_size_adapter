import 'dart:ui';

import 'package:flutter/widgets.dart';

/// Returns the primary [FlutterView], preferring the modern multi-view API.
/// Falls back to the deprecated `implicitView` for older Flutter versions.
///
/// Internal helper — not exported from the public API. Used by
/// `ScreenSizeWidgetsFlutterBinding` to register the primary view.
///
/// Safe to call before `WidgetsBinding` initializes — returns `null` only if
/// neither the multi-view API nor `implicitView` is available.
FlutterView? primaryView() {
  try {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isNotEmpty) return views.first;
  } catch (_) {
    // Binding not yet initialized — fall through to legacy API.
  }
  // ignore: deprecated_member_use
  return PlatformDispatcher.instance.implicitView;
}
