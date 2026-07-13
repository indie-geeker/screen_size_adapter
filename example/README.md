# screen_size_adapter example

This example app demonstrates the package's production integration path:

- installing `ScreenSizeWidgetsFlutterBinding` before `runApp`;
- reading scaled design-unit values from `MediaQuery`;
- switching `ScaleAxis` at runtime;
- swapping portrait and landscape design sizes;
- comparing adapter-on and adapter-off layout behavior;
- inspecting the experimental registry used for host-created views;
- applying/removing scale bounds and resetting the active view to native scale.

## Run

```bash
cd example
flutter run
```

The example enables desktop scaling so the behavior is visible on macOS,
Windows, and Linux windows as well as on mobile devices.

## Test

```bash
cd example
flutter analyze
flutter test
```

The widget test uses `ScreenSizeTestEnvironment`, because Flutter's
`testWidgets` binding cannot install the production binding.

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
