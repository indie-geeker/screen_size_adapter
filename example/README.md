# screen_size_adapter example

This example app demonstrates the package's production integration path:

- installing `ScreenSizeWidgetsFlutterBinding` before `runApp`;
- inspecting the core `MediaQuery.size * scale ~= originSize` invariant;
- reading adapted design-unit values from `MediaQuery` while keeping the
  unscaled origin size available for device classification;
- switching `ScaleAxis` at runtime;
- swapping portrait and landscape design sizes;
- comparing adapter-on and adapter-off layout behavior;
- inspecting the experimental registry used for host-created views;
- applying/removing scale bounds and resetting the active view to native scale.

The debug panel shows the design size, origin size, adapted `MediaQuery` size,
effective scale, selected axis, and scale bounds together. Axis alignment is a
fit-mode consequence, not the core invariant: when a min/max bound is active,
neither adapted dimension has to equal the design size as long as
`MediaQuery.size * scale ~= originSize` remains true.

## Run

```bash
cd example
flutter run
```

This checkout includes Android, iOS, and macOS runners. Desktop scaling is
enabled so the behavior is visible in the checked-in macOS runner as well as on
mobile devices. Windows and Linux runners are not included, so this example is
not directly runnable on those platforms from this checkout. The package API
itself remains platform-neutral.

## Test

```bash
cd example
flutter analyze
flutter test
```

The widget test uses the MediaQuery-only `ScreenSizeTestEnvironment`, because
Flutter's `testWidgets` binding cannot install the production binding. Package
tests separately use `ScreenSizeTestViewport` when tight adapted layout
constraints are required; neither helper proves engine pointer conversion.

## Experimental secondary-view check

The on-screen panel is an experimental registry inspector, not a second-view
demo. Package
tests cover per-view registry behavior with the real primary `FlutterView`, but
Flutter's test binding does not create a second engine-backed view. Fake view
objects would not prove framework or engine behavior.

For release validation, run the example on a desktop target or an Add-to-App
host that creates a real secondary `FlutterView`, then confirm:

- the secondary view is registered with `attachView(view: ..., config: ...)`;
- `ScreenSizeAdapterScope` wraps the secondary `View` subtree;
- the panel shows the expected config and scale for that view;
- closing the secondary view calls `detachView`.

Use the full checklist in
[`tool/verification/desktop_multi_view.md`](../tool/verification/desktop_multi_view.md)
before making any experimental same-engine secondary-view claim.
