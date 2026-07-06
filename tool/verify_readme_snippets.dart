import 'dart:io';

Future<void> main() async {
  final result = await Process.start('flutter', const [
    'analyze',
    'tool/snippets',
  ], mode: ProcessStartMode.inheritStdio);

  final exitCode = await result.exitCode;
  if (exitCode != 0) {
    stderr.writeln('README snippet fixtures failed analysis.');
    exit(exitCode);
  }
}
