final class LineCoverage {
  const LineCoverage({required this.hit, required this.found});

  final int hit;
  final int found;

  double get percent => found == 0 ? 0 : hit * 100 / found;
}

LineCoverage parseLcovLineCoverage(String source) {
  var totalHit = 0;
  var totalFound = 0;
  var completeRecords = 0;
  var recordNumber = 1;
  int? recordHit;
  int? recordFound;
  var recordHasContent = false;

  for (final rawLine in source.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;

    if (line == 'end_of_record') {
      final found = recordFound;
      final hit = recordHit;
      if (found == null || hit == null) {
        final missing = [if (found == null) 'LF', if (hit == null) 'LH'];
        throw FormatException(
          'LCOV record $recordNumber is missing ${missing.join(' and ')}',
        );
      }
      if (hit > found) {
        throw FormatException(
          'LCOV record $recordNumber: '
          'LH ($hit) exceeds LF ($found)',
        );
      }

      totalHit += hit;
      totalFound += found;
      completeRecords++;
      recordNumber++;
      recordHit = null;
      recordFound = null;
      recordHasContent = false;
      continue;
    }

    recordHasContent = true;
    if (line.startsWith('LF:')) {
      if (recordFound != null) {
        throw FormatException(
          'LCOV record $recordNumber has duplicate LF: $line',
        );
      }
      recordFound = _parseCounter(line, 'LF', recordNumber);
    } else if (line.startsWith('LH:')) {
      if (recordHit != null) {
        throw FormatException(
          'LCOV record $recordNumber has duplicate LH: $line',
        );
      }
      recordHit = _parseCounter(line, 'LH', recordNumber);
    }
  }

  if (recordHasContent || recordHit != null || recordFound != null) {
    throw FormatException('LCOV record $recordNumber is unterminated');
  }
  if (completeRecords == 0) {
    throw const FormatException(
      'LCOV input contains no complete line-coverage records',
    );
  }

  return LineCoverage(hit: totalHit, found: totalFound);
}

int _parseCounter(String line, String label, int recordNumber) {
  final value = int.tryParse(line.substring(3).trim());
  if (value == null || value < 0) {
    throw FormatException(
      'LCOV record $recordNumber has invalid $label counter: $line',
    );
  }
  return value;
}
