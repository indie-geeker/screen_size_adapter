import 'dart:async';
import 'dart:convert';
import 'dart:io';

const _launchTimeout = Duration(seconds: 45);
const _shutdownTimeout = Duration(seconds: 5);
const _fatalPatterns = <String>[
  'Unhandled Exception',
  '[ERROR:flutter/runtime',
];

Future<void> main(List<String> arguments) async {
  try {
    final modes = _parseModes(arguments);
    for (final mode in modes) {
      await _verifyMode(mode);
    }
  } on Object catch (error, stackTrace) {
    stderr
      ..writeln(error)
      ..writeln(stackTrace);
    exitCode = 1;
  }
}

List<String> _parseModes(List<String> arguments) {
  if (arguments.isEmpty) return const ['profile', 'release'];
  if (arguments.length != 1 || !arguments.single.startsWith('--mode=')) {
    throw const FormatException(
      'Usage: dart run tool/verify_example_startup.dart '
      '[--mode=profile|--mode=release]',
    );
  }

  final mode = arguments.single.substring('--mode='.length);
  if (mode != 'profile' && mode != 'release') {
    throw FormatException('Unsupported startup smoke mode: $mode');
  }
  return [mode];
}

Future<void> _verifyMode(String mode) async {
  stdout.writeln('Cleaning cached example build before macOS $mode smoke...');
  final clean = await Process.start(
    'flutter',
    const ['clean'],
    workingDirectory: 'example',
    mode: ProcessStartMode.inheritStdio,
  );
  final cleanExitCode = await clean.exitCode;
  if (cleanExitCode != 0) {
    throw ProcessException(
      'flutter',
      const ['clean'],
      'Example clean failed before macOS $mode startup smoke',
      cleanExitCode,
    );
  }

  stdout.writeln('Building macOS $mode startup smoke...');
  final build = await Process.start(
    'flutter',
    [
      'build',
      'macos',
      '--$mode',
      '--dart-define=SCREEN_SIZE_ADAPTER_STARTUP_SMOKE=true',
    ],
    workingDirectory: 'example',
    mode: ProcessStartMode.inheritStdio,
  );
  final buildExitCode = await build.exitCode;
  if (buildExitCode != 0) {
    throw ProcessException(
      'flutter',
      ['build', 'macos', '--$mode'],
      'macOS $mode build failed',
      buildExitCode,
    );
  }

  final productDirectory = mode == 'profile' ? 'Profile' : 'Release';
  final executable = File(
    'example/build/macos/Build/Products/$productDirectory/'
    'example.app/Contents/MacOS/example',
  );
  if (!executable.existsSync()) {
    throw StateError('Built executable not found: ${executable.path}');
  }

  final logs = <String>[];
  final failure = Completer<String>();
  var exited = false;

  // Native macOS GUI logging is not guaranteed to flow through Process.start
  // pipes. Logs remain useful when available, while the smoke contract itself
  // is the app's deliberate zero exit one second after its first frame.
  final process = await Process.start(executable.absolute.path, const []);

  void capture(String source, String line) {
    logs.add('[$source] $line');
    if (_fatalPatterns.any(line.contains) && !failure.isCompleted) {
      failure.complete('Fatal runtime log before smoke completion: $line');
    }
  }

  final stdoutDone = process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .forEach((line) => capture('stdout', line));
  final stderrDone = process.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .forEach((line) => capture('stderr', line));
  final processExit = process.exitCode.then((code) {
    exited = true;
    return code;
  });

  Future<Never> failWhenReported() async {
    throw StateError(await failure.future);
  }

  final timeout = Completer<Object>();
  final timeoutTimer = Timer(_launchTimeout, () {
    timeout.completeError(
      TimeoutException(
        'The packaged app did not complete its first-frame smoke after '
        '${_launchTimeout.inSeconds} seconds',
      ),
    );
  });

  try {
    final result = await Future.any<Object>([
      processExit,
      failWhenReported(),
      timeout.future,
    ]);

    final appExitCode = result as int;
    await Future.wait([stdoutDone, stderrDone]);
    if (appExitCode != 0) {
      throw StateError(
        'Process exited before smoke completion with code $appExitCode',
      );
    }
    if (failure.isCompleted) {
      throw StateError(await failure.future);
    }

    stdout.writeln('macOS $mode startup smoke passed.');
  } on Object {
    stderr.writeln('Captured macOS $mode startup logs:');
    if (logs.isEmpty) {
      stderr.writeln('(no output captured)');
    } else {
      stderr.writeln(logs.join('\n'));
    }
    rethrow;
  } finally {
    timeoutTimer.cancel();
    if (!exited) {
      process.kill(ProcessSignal.sigterm);
      try {
        await processExit.timeout(_shutdownTimeout);
      } on TimeoutException {
        process.kill(ProcessSignal.sigkill);
        await processExit;
      }
    }
  }
}
