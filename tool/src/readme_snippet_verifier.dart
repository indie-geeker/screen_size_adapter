final _readmeStart = RegExp(r'^<!-- snippet:([a-z0-9][a-z0-9-]*) -->$');
final _fixtureStart = RegExp(r'^// snippet:([a-z0-9][a-z0-9-]*):start$');

/// Failure raised when executable README snippets violate their contract.
class SnippetVerificationException implements Exception {
  final String message;

  const SnippetVerificationException(this.message);

  @override
  String toString() => 'SnippetVerificationException: $message';
}

/// Normalizes only cross-platform line endings and one trailing newline.
///
/// Spaces, indentation, additional blank lines, and all other content remain
/// significant so documentation drift cannot be hidden by the verifier.
String normalizeSnippetText(String value) {
  var normalized = value.replaceAll('\r\n', '\n');
  if (normalized.endsWith('\n')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  return normalized;
}

/// Extracts marked Dart fences from a README-style document.
Map<String, String> extractReadmeSnippets(
  String contents, {
  required String documentName,
}) {
  final lines = contents.replaceAll('\r\n', '\n').split('\n');
  final snippets = <String, String>{};

  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    final start = _readmeStart.firstMatch(line);
    if (start == null) {
      if (line.trim() == '```dart') {
        throw SnippetVerificationException(
          'unmarked Dart fence in $documentName at line ${index + 1}',
        );
      }
      continue;
    }

    final id = start.group(1)!;
    if (snippets.containsKey(id)) {
      throw SnippetVerificationException(
        'duplicate snippet ID "$id" in $documentName',
      );
    }
    if (index + 1 >= lines.length || lines[index + 1] != '```dart') {
      throw SnippetVerificationException(
        'snippet "$id" in $documentName must be followed by ```dart',
      );
    }

    final code = <String>[];
    index += 2;
    while (index < lines.length && lines[index] != '```') {
      code.add(lines[index]);
      index++;
    }
    if (index >= lines.length) {
      throw SnippetVerificationException(
        'snippet "$id" in $documentName has no closing Dart fence',
      );
    }

    final closingMarker = '<!-- /snippet:$id -->';
    if (index + 1 >= lines.length || lines[index + 1] != closingMarker) {
      throw SnippetVerificationException(
        'snippet "$id" in $documentName must end with $closingMarker',
      );
    }

    snippets[id] = normalizeSnippetText(code.join('\n'));
    index++;
  }

  return snippets;
}

/// Extracts canonical snippet regions from one analyzable Dart fixture.
Map<String, String> extractFixtureSnippets(
  String contents, {
  required String fixtureName,
}) {
  final lines = contents.replaceAll('\r\n', '\n').split('\n');
  final snippets = <String, String>{};

  for (var index = 0; index < lines.length; index++) {
    final start = _fixtureStart.firstMatch(lines[index].trim());
    if (start == null) continue;

    final id = start.group(1)!;
    if (snippets.containsKey(id)) {
      throw SnippetVerificationException(
        'duplicate snippet ID "$id" in $fixtureName',
      );
    }

    final closingMarker = '// snippet:$id:end';
    final code = <String>[];
    index++;
    while (index < lines.length && lines[index].trim() != closingMarker) {
      if (_fixtureStart.hasMatch(lines[index].trim())) {
        throw SnippetVerificationException(
          'nested snippet region inside "$id" in $fixtureName',
        );
      }
      code.add(lines[index]);
      index++;
    }
    if (index >= lines.length) {
      throw SnippetVerificationException(
        'snippet "$id" in $fixtureName has no $closingMarker',
      );
    }

    snippets[id] = normalizeSnippetText(code.join('\n'));
  }

  return snippets;
}

/// Verifies every document against the complete canonical fixture set.
void verifyReadmeSnippets({
  required Map<String, String> documents,
  required Map<String, String> fixtureFiles,
}) {
  final fixtures = <String, String>{};
  final fixtureOwners = <String, String>{};

  for (final entry in fixtureFiles.entries) {
    final extracted = extractFixtureSnippets(
      entry.value,
      fixtureName: entry.key,
    );
    for (final snippet in extracted.entries) {
      final previousOwner = fixtureOwners[snippet.key];
      if (previousOwner != null) {
        throw SnippetVerificationException(
          'duplicate fixture snippet ID "${snippet.key}" in '
          '$previousOwner and ${entry.key}',
        );
      }
      fixtureOwners[snippet.key] = entry.key;
      fixtures[snippet.key] = snippet.value;
    }
  }

  for (final document in documents.entries) {
    final snippets = extractReadmeSnippets(
      document.value,
      documentName: document.key,
    );
    final missing = fixtures.keys.where((id) => !snippets.containsKey(id));
    final extra = snippets.keys.where((id) => !fixtures.containsKey(id));

    if (missing.isNotEmpty) {
      throw SnippetVerificationException(
        '${document.key} is missing snippet IDs: ${missing.join(', ')}',
      );
    }
    if (extra.isNotEmpty) {
      throw SnippetVerificationException(
        '${document.key} has snippet IDs without fixtures: '
        '${extra.join(', ')}',
      );
    }

    for (final id in fixtures.keys) {
      if (snippets[id] != fixtures[id]) {
        throw SnippetVerificationException(
          'snippet "$id" in ${document.key} differs from its fixture',
        );
      }
    }
  }
}
