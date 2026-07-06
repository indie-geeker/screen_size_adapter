# screen_size_adapter example

This example app demonstrates the package's production integration path:

- installing `ScreenSizeWidgetsFlutterBinding` before `runApp`;
- reading scaled design-unit values from `MediaQuery`;
- switching `ScaleAxis` at runtime;
- swapping portrait and landscape design sizes;
- comparing adapter-on and adapter-off layout behavior;
- inspecting the per-view registry used for multi-view apps.

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

## Multi-view check

The package tests cover per-view registry isolation with the real primary
`FlutterView`. Flutter's test binding does not create a second engine-backed
view, so fake view objects would not prove framework or engine behavior.

For release validation, run the example on a desktop target or an Add-to-App
host that creates a real secondary `FlutterView`, then confirm:

- the secondary view is registered with `attachView(view: ..., config: ...)`;
- `ScreenSizeAdapterScope` wraps the secondary `View` subtree;
- the panel shows the expected config and scale for that view;
- closing the secondary view calls `detachView`.

Use the full checklist in
[`tool/verification/desktop_multi_view.md`](../tool/verification/desktop_multi_view.md)
before publishing a release that claims desktop multi-view support.
