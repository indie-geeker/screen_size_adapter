import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

// Passthrough behavior under AutomatedTestWidgetsFlutterBinding (testWidgets).
// Production-binding behavior is covered in
// screen_size_adapter_scope_binding_test.dart, which cannot coexist with
// testWidgets in the same file.
void main() {
  testWidgets('preserves the parent MediaQuery unchanged', (tester) async {
    const parent = MediaQueryData(
      size: Size(411, 891),
      devicePixelRatio: 2.625,
      padding: EdgeInsets.only(top: 48, bottom: 24),
    );
    MediaQueryData? observed;
    await tester.pumpWidget(
      MediaQuery(
        data: parent,
        child: ScreenSizeAdapterScope(
          child: Builder(
            builder: (ctx) {
              observed = MediaQuery.of(ctx);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    expect(observed, isNotNull);
    expect(observed!.size, parent.size);
    expect(observed!.devicePixelRatio, parent.devicePixelRatio);
    expect(observed!.padding, parent.padding);
  });

  testWidgets('passes through when no parent MediaQuery exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ScreenSizeAdapterScope(child: SizedBox.shrink()),
    );
    expect(tester.takeException(), isNull);
  });
}
