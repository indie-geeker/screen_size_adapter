# Windows multi-view verification

The adapter owns only a widget subtree. The host owns windows and FlutterViews. Each view mounts one `ScreenSizeAdapter` above its complete MaterialApp; configurations and inherited metrics remain local. There are no attach/update/detach registry calls.

## Host setup

For a host that exposes multiple views in one engine, use ordinary `runWidget`, a ViewCollection and one `View(view: hostView, child: ScreenSizeAdapter(...))` per live host view. Explicit View mounting supplies native MediaQuery data. Rebuild the host collection when a view is added or removed, using stable view keys. Do not infer that `views.first` is an implicit primary view.

A plugin that starts a separate engine per window should initialize a standard binding and run an independently configured app in each engine. This is a different host model; evidence from it does not certify same-engine views. This package creates neither type of native window.

## Required checks

Use a real Windows host and record its implementation, Flutter SDK, OS and build mode. Widget tests or fake view IDs do not constitute acceptance.

- Open two windows with different configurations and log their actual view IDs, native DPR, native logical size, scale and design layout size.
- Resize one window. Its metrics and content must update without changing the other window's configuration or metrics.
- Move windows between monitors with different DPI; verify native RenderView DPR and layout update together without double scaling.
- Check pointer hit positions, drag gestures, wheel distance, hover, menus, dialog placement and actual IME candidates in both windows.
- Close/reopen a secondary window while an editor or popup is active. The host removes the View subtree; stale focus, overlays and rendering must not survive it.
- Exercise disabled desktop scaling, enabled scaling and live configuration changes independently in both windows.

The current example intentionally stays a small single-window comparison. It is useful for resizing and input inspection, but it does not certify multi-window support. No Windows host validation has been completed for this refactor.
