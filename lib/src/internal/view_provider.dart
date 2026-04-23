part of '../../screen_size_adapter.dart';

/// Returns the primary [FlutterView], preferring the modern multi-view API.
/// Falls back to the deprecated `implicitView` for older Flutter versions.
///
/// Internal helper — not exported from the public API. Call sites:
/// [ScreenSizeHelper] (for sizing) and [ScreenSizeWidgetsFlutterBinding]
/// (for the root View wrapper).
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
