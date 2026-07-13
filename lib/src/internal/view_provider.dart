import 'dart:ui';

/// Returns the dispatcher [FlutterView] used by the standard `runApp` path.
///
/// Internal helper — not exported from the public API. Used by
/// `ScreenSizeWidgetsFlutterBinding` to register only the implicit view.
///
/// Returns `null` when the embedder has no implicit view. Host-created views
/// are never guessed from [PlatformDispatcher.views]; they must be registered
/// explicitly with `attachView`.
FlutterView? primaryView() {
  // ignore: deprecated_member_use
  return PlatformDispatcher.instance.implicitView;
}
