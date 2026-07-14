import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/src/lcov_coverage.dart';

Matcher _throwsFormatContaining(String text) => throwsA(
  isA<FormatException>().having(
    (error) => error.toString(),
    'message',
    contains(text),
  ),
);

Future<ProcessResult> _runCoverageGate({
  String? lcov,
  List<String> arguments = const ['--minimum=85'],
}) async {
  final temp = await Directory.systemTemp.createTemp('coverage-gate-');
  try {
    if (lcov != null) {
      final coverageDirectory = Directory('${temp.path}/coverage');
      await coverageDirectory.create();
      await File('${coverageDirectory.path}/lcov.info').writeAsString(lcov);
    }

    return await Process.run('dart', [
      'run',
      File('tool/check_coverage.dart').absolute.path,
      ...arguments,
    ], workingDirectory: temp.path);
  } finally {
    await temp.delete(recursive: true);
  }
}

String _combinedOutput(ProcessResult result) =>
    '${result.stdout}\n${result.stderr}';

void main() {
  group('parseLcovLineCoverage', () {
    test('parses one source record', () {
      final coverage = parseLcovLineCoverage('''
SF:lib/a.dart
DA:1,1
LF:10
LH:8
end_of_record
''');

      expect(coverage.hit, 8);
      expect(coverage.found, 10);
      expect(coverage.percent, 80);
    });

    test('sums multiple source records', () {
      final coverage = parseLcovLineCoverage('''
SF:lib/a.dart
LF:10
LH:8
end_of_record
SF:lib/b.dart
LF:5
LH:4
end_of_record
''');

      expect(coverage.hit, 12);
      expect(coverage.found, 15);
    });

    test('ignores blank and unrelated LCOV lines', () {
      final coverage = parseLcovLineCoverage('''

TN:
SF:lib/a.dart
FN:1,main
DA:1,1
LF:3
LH:2
end_of_record

''');

      expect(coverage.hit, 2);
      expect(coverage.found, 3);
    });

    test('rejects malformed and negative counters', () {
      expect(
        () => parseLcovLineCoverage('''
SF:lib/a.dart
LF:nope
LH:1
end_of_record
'''),
        _throwsFormatContaining('LF:nope'),
      );
      expect(
        () => parseLcovLineCoverage('''
SF:lib/a.dart
LF:2
LH:-1
end_of_record
'''),
        _throwsFormatContaining('LH:-1'),
      );
    });

    test('rejects missing and duplicate counters', () {
      expect(
        () => parseLcovLineCoverage('''
SF:lib/a.dart
LH:1
end_of_record
'''),
        _throwsFormatContaining('missing LF'),
      );
      expect(
        () => parseLcovLineCoverage('''
SF:lib/a.dart
LF:2
end_of_record
'''),
        _throwsFormatContaining('missing LH'),
      );
      expect(
        () => parseLcovLineCoverage('''
SF:lib/a.dart
LF:2
LF:2
LH:1
end_of_record
'''),
        _throwsFormatContaining('duplicate LF'),
      );
      expect(
        () => parseLcovLineCoverage('''
SF:lib/a.dart
LF:2
LH:1
LH:1
end_of_record
'''),
        _throwsFormatContaining('duplicate LH'),
      );
    });

    test('rejects impossible and unterminated records', () {
      expect(
        () => parseLcovLineCoverage('''
SF:lib/a.dart
LF:2
LH:3
end_of_record
'''),
        _throwsFormatContaining('LH (3) exceeds LF (2)'),
      );
      expect(
        () => parseLcovLineCoverage('''
SF:lib/a.dart
LF:2
LH:1
'''),
        _throwsFormatContaining('unterminated'),
      );
    });

    test('does not let a valid record mask an earlier invalid record', () {
      expect(
        () => parseLcovLineCoverage('''
SF:lib/bad.dart
LF:1
LH:2
end_of_record
SF:lib/good.dart
LF:10
LH:10
end_of_record
'''),
        _throwsFormatContaining('record 1'),
      );
    });

    test('rejects input without a complete line record', () {
      expect(
        () => parseLcovLineCoverage('\n'),
        _throwsFormatContaining('no complete'),
      );
    });

    test('reports exact and below-threshold percentages', () {
      const exact = LineCoverage(hit: 85, found: 100);
      const below = LineCoverage(hit: 84, found: 100);

      expect(exact.percent, 85);
      expect(below.percent, 84);
      expect(exact.percent >= 85, isTrue);
      expect(below.percent >= 85, isFalse);
    });
  });

  group('coverage gate CLI', () {
    test('passes valid coverage above the minimum', () async {
      final result = await _runCoverageGate(
        lcov: 'SF:lib/a.dart\nLF:100\nLH:90\nend_of_record\n',
      );

      expect(result.exitCode, 0, reason: _combinedOutput(result));
      expect(
        result.stdout,
        contains('Line coverage: 90/100 (90.0%), minimum 85.0%'),
      );
    });

    test('fails parsed coverage below the minimum', () async {
      final result = await _runCoverageGate(
        lcov: 'SF:lib/a.dart\nLF:100\nLH:84\nend_of_record\n',
      );

      expect(result.exitCode, isNot(0));
      expect(
        result.stdout,
        contains('Line coverage: 84/100 (84.0%), minimum 85.0%'),
        reason: _combinedOutput(result),
      );
      expect(result.stderr, contains('below minimum'));
    });

    test('reports missing and malformed coverage files', () async {
      final missing = await _runCoverageGate();
      expect(missing.exitCode, isNot(0));
      expect(_combinedOutput(missing), contains('Coverage file not found'));

      final malformed = await _runCoverageGate(
        lcov: 'SF:lib/a.dart\nLF:nope\nLH:1\nend_of_record\n',
      );
      expect(malformed.exitCode, isNot(0));
      expect(_combinedOutput(malformed), contains('Invalid LCOV'));
    });

    for (final threshold in ['NaN', 'Infinity', '-1', '101']) {
      test('rejects invalid threshold $threshold', () async {
        final result = await _runCoverageGate(
          lcov: 'SF:lib/a.dart\nLF:1\nLH:1\nend_of_record\n',
          arguments: ['--minimum=$threshold'],
        );

        expect(result.exitCode, isNot(0));
        expect(_combinedOutput(result), contains('Invalid minimum coverage'));
      });
    }
  });
}
