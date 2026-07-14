import 'dart:io';

import 'src/lcov_coverage.dart';

void main(List<String> arguments) {
  final double minimum;
  try {
    minimum = _parseMinimum(arguments);
  } on FormatException catch (error) {
    stderr.writeln('Invalid minimum coverage: ${error.message}');
    exitCode = 64;
    return;
  }

  final coverageFile = File('coverage/lcov.info');
  if (!coverageFile.existsSync()) {
    stderr.writeln('Coverage file not found: ${coverageFile.path}');
    exitCode = 66;
    return;
  }

  final LineCoverage coverage;
  try {
    coverage = parseLcovLineCoverage(coverageFile.readAsStringSync());
  } on FormatException catch (error) {
    stderr.writeln('Invalid LCOV: ${error.message}');
    exitCode = 65;
    return;
  } on FileSystemException catch (error) {
    stderr.writeln('Unable to read coverage file: $error');
    exitCode = 66;
    return;
  }

  stdout.writeln(
    'Line coverage: ${coverage.hit}/${coverage.found} '
    '(${coverage.percent.toStringAsFixed(1)}%), '
    'minimum ${minimum.toStringAsFixed(1)}%',
  );

  if (coverage.percent < minimum) {
    stderr.writeln('Line coverage is below minimum.');
    exitCode = 1;
  }
}

double _parseMinimum(List<String> arguments) {
  if (arguments.length > 1 ||
      (arguments.isNotEmpty && !arguments.single.startsWith('--minimum='))) {
    throw const FormatException('expected --minimum=<percent>');
  }

  if (arguments.isEmpty) return 85;

  final source = arguments.single.substring('--minimum='.length);
  final minimum = double.tryParse(source);
  if (minimum == null || !minimum.isFinite || minimum < 0 || minimum > 100) {
    throw FormatException('expected a finite value in 0..100, got "$source"');
  }
  return minimum;
}
