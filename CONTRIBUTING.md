# Contributing

Use the standard Flutter binding and keep the root adapter scoped to its FlutterView. Do not reintroduce a global view registry, wire-protocol rewriting or hidden per-field compensation.

## Package and example checks

Run on Flutter 3.29.2 and the current stable SDK. Record the exact version used. When switching SDKs, run pub get again so package resolution matches the executable.

```sh
flutter pub get
dart format --output=none --set-exit-if-changed lib test tool example/lib example/test
flutter analyze
dart run tool/verify_readme_snippets.dart
flutter test tool/snippets/widget_test.dart
flutter test --coverage
dart run tool/check_coverage.dart --minimum=85
(cd example && flutter pub get && flutter analyze && flutter test)
dart doc --dry-run
flutter pub publish --dry-run
```

README Dart snippets have canonical analyzed fixtures in `tool/snippets`. Update both languages and the fixture together. Tests should verify visible geometry and real behavior, including input state through scale changes, rather than literal implementation text.

## Native and release acceptance

Run the [SDK acceptance checks](tool/verification/README.md), then verify the example on actual target devices. Package CI is a regression gate, not proof of UIKit, Android IME, Windows multi-window or accessibility correctness.

```sh
(cd example && flutter build ios --simulator)
dart run tool/verify_example_startup.dart
```

The startup command builds and launches macOS profile and release executables. Neither this smoke test nor a simulator build proves physical-device behavior. The separate SDK acceptance workflow is manually runnable and deliberately fails while correct SDK behavior is absent; it must pass before claiming those capabilities in a stable release. Native acceptance is additionally required, because framework-only tests cannot prove engine input geometry.

Current 2.0 is a development version. Do not publish a stable release claiming complete native input until the known gates and target-device matrix pass. Record SDK revision, platform, observed result and evidence; never weaken the expected geometry merely to make CI green.

## Pull requests

Describe the behavior change and validation, update public API/migration docs, and preserve unrelated work. Keep local experiments and evidence in ignored `docs/local/`; do not include them in the pub package.
