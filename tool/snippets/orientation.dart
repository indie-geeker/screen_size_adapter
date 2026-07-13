import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_size_adapter/screen_size_adapter.dart';

// snippet:orientation:start
Future<void> lockPortraitAndRun() async {
  ScreenSizeWidgetsFlutterBinding.ensureInitialized(
    const ScreenSizeAdapterConfig(designSize: Size(360, 690)),
  );
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ExampleApp());
}

Widget buildScrollableContent() => const SingleChildScrollView(
  child: Column(children: [Text('Scrollable content')]),
);

Widget buildOrientationAwareHome() => OrientationBuilder(
  builder: (context, orientation) {
    final design =
        orientation == Orientation.landscape
            ? const Size(640, 360)
            : const Size(360, 640);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScreenSizeAdapter.setDesignSize(context, design);
    });
    return const ExampleHome();
  },
);
// snippet:orientation:end

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(home: ExampleHome());
}

class ExampleHome extends StatelessWidget {
  const ExampleHome({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold();
}
