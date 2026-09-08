import 'package:flutter/widgets.dart';

import 'internal/adapter_metrics.dart';
import 'internal/scale_media_query.dart';
import 'screen_size_widget_flutter_binding.dart';

/// Wraps [child] with a [MediaQuery] that reflects the binding's per-view
/// scale, so `MediaQuery.sizeOf(context)`, `paddingOf`, `viewInsetsOf`,
/// `devicePixelRatioOf`, gesture settings, and display-feature bounds are
/// reported in **design units** rather than the underlying [FlutterView]'s
/// native logical pixels.
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
/// This same-engine secondary-view path is experimental; validate it with
/// `tool/verification/desktop_multi_view.md` in the real host.
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
/// - no [MediaQuery] ancestor exists (the scope can't scale what isn't
///   there — typically a wiring error).
///
/// Under the production binding, a resolved view and parent [MediaQuery]
/// always keep the same wrapper topology. Unregistered views and an effective
/// scale of `1.0` receive the parent data unchanged; retaining the wrapper
/// prevents application state from being recreated when runtime updates cross
/// the identity-scale boundary.
/// Repeating this scope inside the same view is idempotent. A nested scope
/// preserves intervening MediaQuery overrides instead of scaling them again.
/// A different FlutterView still owns its own independent adaptation.
class ScreenSizeAdapterScope extends StatefulWidget {
  /// Subtree to which the scaled [MediaQuery] applies.
  final Widget child;

  const ScreenSizeAdapterScope({super.key, required this.child});

  @override
  State<ScreenSizeAdapterScope> createState() => _ScreenSizeAdapterScopeState();
}

class _ScreenSizeAdapterScopeState extends State<ScreenSizeAdapterScope>
    with WidgetsBindingObserver {
  (int, Size, double)? _lastMetrics;
  bool _selectionRefreshScheduled = false;

  void _refreshSelectionAfterLayout() {
    if (_selectionRefreshScheduled) return;
    _selectionRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectionRefreshScheduled = false;
      if (!mounted) return;
      final focusContext = FocusManager.instance.primaryFocus?.context;
      if (focusContext == null || !focusContext.mounted) return;

      // The binding can serve several views. Only touch a focused editor
      // owned by this scope; nested same-view scopes remain pass-through.
      if (View.maybeOf(focusContext) != View.maybeOf(context)) return;
      var ownsFocus = false;
      focusContext.visitAncestorElements((element) {
        ownsFocus = identical(element, context);
        return !ownsFocus;
      });
      if (!ownsFocus) return;
      final editable =
          focusContext.findAncestorStateOfType<EditableTextState>();
      // Flutter can retain stale toolbar anchors when TextEditingValue stays
      // unchanged. Its geometry refresh is only exposed through a testing
      // getter, so dismiss the stale toolbar through the supported API.
      // Keep the handles, selection and focus; reopening computes new anchors.
      editable?.hideToolbar(false);
    });
  }

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

    if (AdapterMetrics.maybeOf(context, view.viewId) != null) {
      return widget.child;
    }

    final scale = binding.scaleForView(view) ?? 1.0;
    final originSize = view.physicalSize / view.devicePixelRatio;
    final metrics = (view.viewId, originSize, scale);
    if (_lastMetrics != metrics) {
      if (_lastMetrics != null) _refreshSelectionAfterLayout();
      _lastMetrics = metrics;
    }
    return AdapterMetrics(
      viewId: view.viewId,
      originSize: originSize,
      scale: scale,
      child: MediaQuery(
        data: scaleMediaQueryData(parent, scale),
        child: widget.child,
      ),
    );
  }
}
