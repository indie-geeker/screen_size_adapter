import 'package:flutter/widgets.dart';

import 'internal/scale_media_query.dart';
import 'screen_size_widget_flutter_binding.dart';

/// Wraps [child] with a [MediaQuery] that reflects the binding's per-view
/// scale, so `MediaQuery.sizeOf(context)`, `paddingOf`, `viewInsetsOf`,
/// `devicePixelRatioOf`, etc., are reported in **design units** rather than
/// the underlying [FlutterView]'s native logical pixels.
///
/// Why this exists: the binding only modifies `RenderView.configuration` via
/// `createViewConfigurationFor` — that drives layout, but
/// Flutter's `MediaQuery.fromView` (the one wired up by the [View] widget)
/// reads `view.physicalSize / view.devicePixelRatio` straight from
/// [FlutterView], which we cannot override. Without this scope, layout in
/// the widget tree is correctly scaled but `MediaQuery` reports the raw
/// device size, breaking percentage layout, `SafeArea` insets, and
/// asset-resolution DPR.
///
/// Auto-injection: [ScreenSizeWidgetsFlutterBinding.wrapWithDefaultView]
/// inserts this scope automatically for the implicit (primary) view, so
/// apps started via `runApp` need no manual wrapping. For multi-view apps
/// that mount additional [View] widgets via `runWidget` or nested
/// `ViewAnchor`s, wrap each `View`'s child manually:
///
/// ```dart
/// View(
///   view: secondaryView,
///   child: ScreenSizeAdapterScope(
///     child: ...,
///   ),
/// )
/// ```
///
/// Pass-through behavior (no wrapping applied to [MediaQuery]) when:
/// - the active [WidgetsBinding] is not [ScreenSizeWidgetsFlutterBinding]
///   (e.g. inside `testWidgets`, which uses
///   `AutomatedTestWidgetsFlutterBinding` — use [ScreenSizeTestEnvironment]
///   in that case);
/// - no enclosing [View] resolves via `View.maybeOf(context)`;
/// - the resolved view has no registration in the binding's per-view
///   registry, or its computed scale is `1.0`;
/// - no [MediaQuery] ancestor exists (the scope can't scale what isn't
///   there — typically a wiring error).
class ScreenSizeAdapterScope extends StatefulWidget {
  /// Subtree to which the scaled [MediaQuery] applies.
  final Widget child;

  const ScreenSizeAdapterScope({super.key, required this.child});

  @override
  State<ScreenSizeAdapterScope> createState() => _ScreenSizeAdapterScopeState();
}

class _ScreenSizeAdapterScopeState extends State<ScreenSizeAdapterScope>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // The parent MediaQuery only rebuilds when FlutterView-level metrics
    // change. Scale changes triggered by setDesignSize/attachView don't
    // change FlutterView metrics, so we force a rebuild here on every
    // didChangeMetrics callback (which the binding also fires for those
    // registry mutations via handleMetricsChanged).
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final parent = MediaQuery.maybeOf(context);
    if (parent == null) return widget.child;

    final binding = WidgetsBinding.instance;
    if (binding is! ScreenSizeWidgetsFlutterBinding) return widget.child;

    final view = View.maybeOf(context);
    if (view == null) return widget.child;

    final scale = binding.scaleForView(view) ?? 1.0;
    if (scale == 1.0) return widget.child;

    return MediaQuery(
      data: scaleMediaQueryData(parent, scale),
      child: widget.child,
    );
  }
}
