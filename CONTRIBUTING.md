# Contributing

`screen_size_adapter` is a Flutter screen-size adaptation library. Keep changes
small, tested, and focused on making app integration simpler and more stable.

## Local Checks

Run these before opening a PR:

```bash
flutter pub get
flutter analyze
flutter test --coverage
dart run tool/check_coverage.dart --minimum=85
(cd example && flutter analyze)
(cd example && flutter test)
dart doc --dry-run
flutter pub publish --dry-run
```

## Pull Requests

- Explain the user-visible behavior change.
- Add or update tests for behavior changes.
- Update `README.md`, `README_ZH.md`, or `CHANGELOG.md` when public APIs,
  integration steps, defaults, or migration notes change.
- Keep generated or local-tooling files out of the pub package.

## Release Checklist

- `flutter analyze` reports no issues.
- `flutter test --coverage` passes and package line coverage remains at least
  85% according to `tool/check_coverage.dart`.
- Example analyze and tests pass.
- `dart doc --dry-run` reports no warnings.
- `flutter pub publish --dry-run` reports no warnings and the package contents
  do not include local agent/tooling files.
