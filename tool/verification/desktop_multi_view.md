# Desktop multi-view verification

Use this checklist before publishing a release that claims multi-view support.
The package unit tests cover registry behavior with the real primary
`FlutterView`, but `flutter_test` does not create a second engine-backed view.
Do not treat fake `FlutterView` objects or raw view IDs as proof of desktop
multi-view behavior.

## Required host

Run a desktop or Add-to-App host that creates a second `FlutterView` in the
same Flutter engine. Examples include:

- a Windows runner that creates an additional view controller through the
  Windows embedder API;
- a Linux runner that creates a secondary `FlView` for an existing engine;
- a macOS/Add-to-App host that attaches another Flutter rendering view to the
  existing engine.

Multi-window plugins that start a separate Flutter engine are useful smoke
tests, but they do not validate this package's same-engine per-view registry.

## Dart wiring under test

When the host exposes the secondary view, the Dart side must register and mount
that specific view:

```dart
final binding = ScreenSizeWidgetsFlutterBinding.instance;
final secondaryView = PlatformDispatcher.instance.views
    .firstWhere((view) => view.viewId != binding.platformDispatcher.views.first.viewId);

binding.attachView(
  view: secondaryView,
  config: const ScreenSizeAdapterConfig(
    designSize: Size(800, 600),
    scaleAxis: ScaleAxis.shorter,
    enableDesktopScaling: true,
  ),
);

runWidget(
  View(
    view: secondaryView,
    child: const ScreenSizeAdapterScope(
      child: SecondaryViewApp(),
    ),
  ),
);
```

## Pass criteria

Record the Flutter version, operating system, and host implementation used.
The release passes this check only when all items below are true:

- `PlatformDispatcher.instance.views` reports both primary and secondary view
  IDs.
- The primary and secondary views can use different `ScreenSizeAdapterConfig`
  values without affecting each other.
- Inside the secondary view, `MediaQuery.sizeOf(context)` reflects the
  secondary design size after scaling.
- Inside the secondary view, `MediaQuery.devicePixelRatioOf(context)` equals
  `secondaryView.devicePixelRatio * ScreenSizeAdapter.scaleOf(context)`.
- Pointer input in the secondary view lands on the expected widget region after
  scaling.
- Resizing the secondary desktop window updates the secondary scale without
  changing the primary view's config.
- Closing the secondary window calls `detachView`, and subsequent registry
  inspection returns `null` for `configForView(secondaryView)`.

## Suggested evidence

Capture one short note or screenshot per release with:

- primary and secondary view IDs;
- native logical size and configured design size for both views;
- computed scale for both views;
- pointer hit-test result in the secondary view;
- detach/cleanup result after closing the secondary view.
