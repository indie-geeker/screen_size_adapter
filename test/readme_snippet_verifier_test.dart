import 'package:flutter_test/flutter_test.dart';

import '../tool/src/readme_snippet_verifier.dart';

void main() {
  const fixture = '''
// snippet:quick-start:start
void main() {}
// snippet:quick-start:end
''';
  const readme = '''
<!-- snippet:quick-start -->
```dart
void main() {}
```
<!-- /snippet:quick-start -->
''';

  test('marked README fence exactly matches its fixture region', () {
    expect(
      () => verifyReadmeSnippets(
        documents: const {'README.md': readme},
        fixtureFiles: const {'quick_start.dart': fixture},
      ),
      returnsNormally,
    );
  });

  test('one-character drift reports the snippet ID and document', () {
    const drifted = '''
<!-- snippet:quick-start -->
```dart
void main() { }
```
<!-- /snippet:quick-start -->
''';

    expect(
      () => verifyReadmeSnippets(
        documents: const {'README_EN.md': drifted},
        fixtureFiles: const {'quick_start.dart': fixture},
      ),
      throwsA(
        predicate(
          (error) =>
              '$error'.contains('quick-start') &&
              '$error'.contains('README_EN.md'),
        ),
      ),
    );
  });

  test('unmarked Dart fence is rejected', () {
    const unmarked = '''
```dart
void main() {}
```
''';

    expect(
      () => verifyReadmeSnippets(
        documents: const {'README.md': unmarked},
        fixtureFiles: const {'quick_start.dart': fixture},
      ),
      throwsA(
        predicate(
          (error) =>
              '$error'.contains('unmarked') && '$error'.contains('README.md'),
        ),
      ),
    );
  });

  test('duplicate README snippet IDs are rejected', () {
    final duplicated = '$readme\n$readme';

    expect(
      () => verifyReadmeSnippets(
        documents: {'README.md': duplicated},
        fixtureFiles: const {'quick_start.dart': fixture},
      ),
      throwsA(
        predicate(
          (error) =>
              '$error'.contains('duplicate') &&
              '$error'.contains('quick-start'),
        ),
      ),
    );
  });

  test('duplicate fixture snippet IDs are rejected across files', () {
    expect(
      () => verifyReadmeSnippets(
        documents: const {'README.md': readme},
        fixtureFiles: const {'one.dart': fixture, 'two.dart': fixture},
      ),
      throwsA(
        predicate(
          (error) =>
              '$error'.contains('duplicate') &&
              '$error'.contains('quick-start'),
        ),
      ),
    );
  });

  test('missing IDs between documents are rejected', () {
    expect(
      () => verifyReadmeSnippets(
        documents: const {'README.md': readme, 'README_EN.md': ''},
        fixtureFiles: const {'quick_start.dart': fixture},
      ),
      throwsA(
        predicate(
          (error) =>
              '$error'.contains('quick-start') &&
              '$error'.contains('README_EN.md'),
        ),
      ),
    );
  });

  test('CRLF and one trailing newline normalize narrowly', () {
    expect(normalizeSnippetText('line\r\n'), 'line');
    expect(normalizeSnippetText('line\n'), 'line');
    expect(normalizeSnippetText('line\n\n'), 'line\n');
    expect(normalizeSnippetText(' line \n'), ' line ');
  });

  test('other whitespace differences still fail', () {
    const indentedReadme = '''
<!-- snippet:quick-start -->
```dart
 void main() {}
```
<!-- /snippet:quick-start -->
''';

    expect(
      () => verifyReadmeSnippets(
        documents: const {'README.md': indentedReadme},
        fixtureFiles: const {'quick_start.dart': fixture},
      ),
      throwsA(isA<SnippetVerificationException>()),
    );
  });

  test('fixture markers may be indented inside analyzable Dart code', () {
    const indentedFixture = '''
void example() {
  // snippet:quick-start:start
  void main() {}
  // snippet:quick-start:end
}
''';
    const indentedReadme = '''
<!-- snippet:quick-start -->
```dart
  void main() {}
```
<!-- /snippet:quick-start -->
''';

    expect(
      () => verifyReadmeSnippets(
        documents: const {'README.md': indentedReadme},
        fixtureFiles: const {'quick_start.dart': indentedFixture},
      ),
      returnsNormally,
    );
  });
}
