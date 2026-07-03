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
