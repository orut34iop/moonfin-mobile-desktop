import 'dart:io';

const defaultCoverageExcludes = <String>[
  'lib/l10n/',
  '/lib/l10n/',
  '.g.dart',
  '.freezed.dart',
  '.gr.dart',
  '/generated/',
];

class CoverageRecord {
  const CoverageRecord({
    required this.file,
    required this.linesFound,
    required this.linesHit,
  });

  final String file;
  final int linesFound;
  final int linesHit;

  double get lineCoverage =>
      linesFound == 0 ? 100 : (linesHit / linesFound) * 100;
}

class CoverageBucket {
  const CoverageBucket({
    required this.fileCount,
    required this.linesFound,
    required this.linesHit,
  });

  final int fileCount;
  final int linesFound;
  final int linesHit;

  double get lineCoverage =>
      linesFound == 0 ? 100 : (linesHit / linesFound) * 100;
}

class QualityGateConfig {
  const QualityGateConfig({
    required this.minOverallPercent,
    this.minDirectoryPercent = const <String, double>{},
    this.excludePatterns = defaultCoverageExcludes,
  });

  final double minOverallPercent;
  final Map<String, double> minDirectoryPercent;
  final List<String> excludePatterns;
}

class QualityGateResult {
  const QualityGateResult({
    required this.records,
    required this.includedRecords,
    required this.overall,
    required this.directories,
    required this.failures,
  });

  final List<CoverageRecord> records;
  final List<CoverageRecord> includedRecords;
  final CoverageBucket overall;
  final Map<String, CoverageBucket> directories;
  final List<String> failures;

  bool get passed => failures.isEmpty;
}

List<CoverageRecord> parseLcov(String text) {
  final records = <CoverageRecord>[];
  String? file;
  var linesFound = 0;
  var linesHit = 0;

  void flush() {
    final currentFile = file;
    if (currentFile == null) {
      return;
    }
    records.add(
      CoverageRecord(
        file: currentFile,
        linesFound: linesFound,
        linesHit: linesHit,
      ),
    );
    file = null;
    linesFound = 0;
    linesHit = 0;
  }

  for (final rawLine in text.split('\n')) {
    final line = rawLine.trim();
    if (line.startsWith('SF:')) {
      flush();
      file = line.substring(3);
    } else if (line.startsWith('LF:')) {
      linesFound = int.tryParse(line.substring(3)) ?? 0;
    } else if (line.startsWith('LH:')) {
      linesHit = int.tryParse(line.substring(3)) ?? 0;
    } else if (line == 'end_of_record') {
      flush();
    }
  }
  flush();
  return records;
}

QualityGateResult evaluateCoverageGate(
  List<CoverageRecord> records,
  QualityGateConfig config,
) {
  final included = records
      .where((record) => !_isExcluded(record.file, config.excludePatterns))
      .toList(growable: false);
  final overall = _bucket(included);
  final directories = _bucketByDirectory(included);
  final failures = <String>[];

  if (overall.lineCoverage < config.minOverallPercent) {
    failures.add(
      'overall coverage ${formatPercent(overall.lineCoverage)} is below '
      '${formatPercent(config.minOverallPercent)}',
    );
  }

  for (final entry in config.minDirectoryPercent.entries) {
    final bucket =
        directories[entry.key] ??
        const CoverageBucket(fileCount: 0, linesFound: 0, linesHit: 0);
    if (bucket.lineCoverage < entry.value) {
      failures.add(
        '${entry.key} coverage ${formatPercent(bucket.lineCoverage)} is below '
        '${formatPercent(entry.value)}',
      );
    }
  }

  return QualityGateResult(
    records: records,
    includedRecords: included,
    overall: overall,
    directories: directories,
    failures: failures,
  );
}

String coverageDirectoryKey(String file) {
  final normalized = file.replaceAll('\\', '/');
  final libIndex = normalized.indexOf('lib/');
  if (libIndex >= 0) {
    final rest = normalized.substring(libIndex);
    final parts = rest.split('/');
    if (parts.length >= 2) {
      return '${parts[0]}/${parts[1]}';
    }
    return parts.first;
  }
  final slash = normalized.lastIndexOf('/');
  return slash < 0 ? '.' : normalized.substring(0, slash);
}

String formatPercent(double value) => '${value.toStringAsFixed(2)}%';

bool _isExcluded(String file, List<String> patterns) {
  return patterns.any(file.contains);
}

CoverageBucket _bucket(List<CoverageRecord> records) {
  return CoverageBucket(
    fileCount: records.length,
    linesFound: records.fold<int>(
      0,
      (total, record) => total + record.linesFound,
    ),
    linesHit: records.fold<int>(0, (total, record) => total + record.linesHit),
  );
}

Map<String, CoverageBucket> _bucketByDirectory(List<CoverageRecord> records) {
  final grouped = <String, List<CoverageRecord>>{};
  for (final record in records) {
    grouped
        .putIfAbsent(coverageDirectoryKey(record.file), () => [])
        .add(record);
  }
  return {for (final entry in grouped.entries) entry.key: _bucket(entry.value)};
}

Future<void> main(List<String> args) async {
  var lcovPath = 'coverage/lcov.info';
  var minOverall = 4.0;
  final minDirectories = <String, double>{};
  final excludes = List<String>.from(defaultCoverageExcludes);

  for (final arg in args) {
    if (arg == '--help' || arg == '-h') {
      _printUsage();
      return;
    } else if (arg.startsWith('--min-overall=')) {
      minOverall =
          double.tryParse(arg.substring('--min-overall='.length)) ?? minOverall;
    } else if (arg.startsWith('--min-dir=')) {
      final raw = arg.substring('--min-dir='.length);
      final separator = raw.lastIndexOf(':');
      if (separator <= 0 || separator == raw.length - 1) {
        stderr.writeln('Invalid --min-dir value: $raw');
        exitCode = 2;
        return;
      }
      final key = raw.substring(0, separator);
      final value = double.tryParse(raw.substring(separator + 1));
      if (value == null) {
        stderr.writeln('Invalid --min-dir percentage: $raw');
        exitCode = 2;
        return;
      }
      minDirectories[key] = value;
    } else if (arg.startsWith('--exclude=')) {
      excludes.add(arg.substring('--exclude='.length));
    } else if (!arg.startsWith('--')) {
      lcovPath = arg;
    } else {
      stderr.writeln('Unknown argument: $arg');
      exitCode = 2;
      return;
    }
  }

  final lcovFile = File(lcovPath);
  if (!await lcovFile.exists()) {
    stderr.writeln('LCOV file not found: $lcovPath');
    exitCode = 2;
    return;
  }

  final result = evaluateCoverageGate(
    parseLcov(await lcovFile.readAsString()),
    QualityGateConfig(
      minOverallPercent: minOverall,
      minDirectoryPercent: minDirectories,
      excludePatterns: excludes,
    ),
  );

  stdout.writeln('TEST_QUALITY_GATE');
  stdout.writeln('lcov=$lcovPath');
  stdout.writeln(
    'records=${result.records.length} included=${result.includedRecords.length}',
  );
  stdout.writeln(
    'overall files=${result.overall.fileCount} '
    'lines=${result.overall.linesFound} hit=${result.overall.linesHit} '
    'coverage=${formatPercent(result.overall.lineCoverage)} '
    'min=${formatPercent(minOverall)}',
  );
  for (final entry in minDirectories.entries) {
    final bucket =
        result.directories[entry.key] ??
        const CoverageBucket(fileCount: 0, linesFound: 0, linesHit: 0);
    stdout.writeln(
      'dir ${entry.key} files=${bucket.fileCount} '
      'lines=${bucket.linesFound} hit=${bucket.linesHit} '
      'coverage=${formatPercent(bucket.lineCoverage)} '
      'min=${formatPercent(entry.value)}',
    );
  }

  if (result.failures.isEmpty) {
    stdout.writeln('QUALITY_GATE_RESULT=pass');
    return;
  }

  stdout.writeln('QUALITY_GATE_RESULT=fail');
  for (final failure in result.failures) {
    stdout.writeln('  - $failure');
  }
  exitCode = 1;
}

void _printUsage() {
  stdout.writeln('''
Usage:
  dart run tool/test_quality_gate.dart [coverage/lcov.info]
      [--min-overall=4.0]
      [--min-dir=lib/playback:15.0]
      [--exclude=pattern]
''');
}
