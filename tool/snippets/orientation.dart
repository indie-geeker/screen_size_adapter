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

Widget buildOrientationAwareHome() => const OrientationAwareHome();

class OrientationAwareHome extends StatelessWidget {
  const OrientationAwareHome({super.key});

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.orientationOf(context);
    final design =
        orientation == Orientation.landscape
            ? const Size(640, 360)
            : const Size(360, 640);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final liveOrientation = MediaQuery.orientationOf(context);
      if (liveOrientation != orientation) return;

      final binding = ScreenSizeWidgetsFlutterBinding.instance;
      final view = View.of(context);
      if (binding.configForView(view)?.designSize == design) return;
      ScreenSizeAdapter.setDesignSize(context, design);
    });

    return const ExampleHome();
  }
}
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
