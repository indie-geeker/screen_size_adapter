import 'dart:io';

import 'src/readme_snippet_verifier.dart';

Future<void> main() async {
  try {
    final fixtureFiles = <String, String>{};
    final files =
        Directory('tool/snippets')
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      fixtureFiles[file.path] = file.readAsStringSync();
    }

    verifyReadmeSnippets(
      documents: {
        'README.md': File('README.md').readAsStringSync(),
        'README_EN.md': File('README_EN.md').readAsStringSync(),
      },
      fixtureFiles: fixtureFiles,
    );
  } on SnippetVerificationException catch (error) {
    stderr.writeln(error);
    exitCode = 1;
    return;
  }

  final result = await Process.start('flutter', const [
    'analyze',
    'tool/snippets',
  ], mode: ProcessStartMode.inheritStdio);

  final analyzeExitCode = await result.exitCode;
  if (analyzeExitCode != 0) {
    stderr.writeln('README snippet fixtures failed analysis.');
    exit(analyzeExitCode);
  }

  stdout.writeln('README snippets match analyzed canonical fixtures.');
}
