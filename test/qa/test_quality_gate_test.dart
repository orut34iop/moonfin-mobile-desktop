import 'package:flutter_test/flutter_test.dart';

import '../../tool/test_quality_gate.dart';

void main() {
  group('test quality gate', () {
    test('parses lcov records and excludes generated sources', () {
      final records = parseLcov('''
SF:lib/playback/player.dart
LF:10
LH:7
end_of_record
SF:lib/l10n/app_localizations_en.dart
LF:100
LH:0
end_of_record
SF:lib/data/model.g.dart
LF:50
LH:0
end_of_record
''');

      final result = evaluateCoverageGate(
        records,
        const QualityGateConfig(minOverallPercent: 60),
      );

      expect(records, hasLength(3));
      expect(result.includedRecords.map((record) => record.file), [
        'lib/playback/player.dart',
      ]);
      expect(result.overall.lineCoverage, equals(70));
      expect(result.passed, isTrue);
    });

    test('fails when overall coverage falls below baseline', () {
      final result = evaluateCoverageGate(
        parseLcov('''
SF:lib/playback/player.dart
LF:10
LH:3
end_of_record
'''),
        const QualityGateConfig(minOverallPercent: 40),
      );

      expect(result.passed, isFalse);
      expect(result.failures.single, contains('overall coverage 30.00%'));
    });

    test('applies directory-specific thresholds', () {
      final result = evaluateCoverageGate(
        parseLcov('''
SF:/repo/lib/playback/player.dart
LF:10
LH:8
end_of_record
SF:/repo/lib/ui/screen.dart
LF:100
LH:1
end_of_record
'''),
        const QualityGateConfig(
          minOverallPercent: 1,
          minDirectoryPercent: {'lib/playback': 70, 'lib/ui': 5},
        ),
      );

      expect(result.directories['lib/playback']?.lineCoverage, equals(80));
      expect(result.directories['lib/ui']?.lineCoverage, equals(1));
      expect(result.passed, isFalse);
      expect(result.failures, contains(contains('lib/ui coverage 1.00%')));
    });
  });
}
