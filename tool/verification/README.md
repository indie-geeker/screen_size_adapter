# SDK acceptance

These tests express the behavior needed for a fully compatible release. They run separately from package regression tests so a package refactor can be reviewed without pretending that known SDK failures have been fixed.

Run them from a source checkout; the SDK acceptance Dart fixtures are excluded from the published package. Record the package commit and the actual Flutter SDK revision alongside the result.

```sh
flutter test tool/verification/sdk_coordinate_acceptance_test.dart tool/verification/sdk_framework_acceptance_test.dart
```

The command must return zero to pass. There is no expected-failure wrapper, skip or inverted assertion. On the official Flutter 3.47.2 SDK, the retained system-menu and wheel-distance checks fail. Run the `SDK acceptance` workflow manually against a candidate SDK when evaluating a fix. Its failure is meaningful; normal package CI does not supersede it.

## Framework checks

- A mouse wheel delta of 60 native logical units must move ListView and default NestedScrollView content by 60 visible native logical units at non-identity scales.
- Both Flutter toolbar anchors and explicit SystemContextMenu anchors must match the selected glyph bounds transformed to native logical coordinates, for LTR and RTL.
- The package ordinarily disables system context menus at non-identity scales. Explicitly constructing one exercises that underlying SDK path. The shared toolbar anchor is also checked because using a Flutter menu does not correct the coordinate calculation.

On the verified 3.47.2 candidate, the 11 failing framework cases cover seven menu-anchor cases and four wheel-distance cases. They are not 11 independent SDK defects. Raw pointer deltas remaining native is the Flutter event contract; the wheel checks require default scrolling widgets to convert those deltas for the scaled viewport. Local menu/scroll replacements do not establish transparent compatibility for every default widget.

Tests use the public production adapter. Expected coordinates come from the selected glyphs / native wheel input, not the incorrect result under investigation. These are framework checks only; a fixed system-menu anchor does not imply fixed UIKit caret or selection rectangles.

## Native input acceptance

Run a normal app with the standard binding and the production adapter on the candidate SDK. Do not use flutter_test input mocks as engine evidence. Record SDK revision, engine identity, OS, device and build mode.

Check scales 1, 2, 0.75 and 1.25, then return to 1. Include translation, internal field scrolling, blur/refocus, switching fields, Latin, Arabic/RTL, Chinese and multi-codepoint emoji. Compare native caret, selection and composing rectangles against visible glyph geometry converted through the actual RenderView into native coordinates. Check writing direction independently. Missing samples or incomplete suites must fail, not count as a pass.

Additionally exercise real IME composition/candidates, drag handles, context menus, autofill, keyboard insets, accessibility, Android devices and iOS physical-device release builds. Programmatically setting composing text is insufficient evidence for IME acceptance. Retain raw observations locally under `docs/local/` and summarize limitations in the release decision.

The previously observed iOS failures are not repaired in this refactor. Development-branch completion and stable native release acceptance are separate decisions.
