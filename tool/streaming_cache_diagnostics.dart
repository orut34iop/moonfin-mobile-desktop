import 'dart:io';

import 'package:moonfin/playback/streaming_cache_diagnostics_summary.dart';

String get _defaultLogPath {
  final home = Platform.environment['HOME'] ?? '/Users/wiz';
  return '$home/Library/Containers/org.moonfin.app/Data/Documents/'
      'Moonfin/logs/playback_diagnostics.log';
}

Future<void> main(List<String> args) async {
  var logPath = _defaultLogPath;
  var thresholdMs = 2500;
  var failOnProblems = true;

  for (final arg in args) {
    if (arg == '--no-fail') {
      failOnProblems = false;
    } else if (arg.startsWith('--threshold-ms=')) {
      thresholdMs =
          int.tryParse(arg.substring('--threshold-ms='.length)) ?? thresholdMs;
    } else if (!arg.startsWith('--')) {
      logPath = arg;
    }
  }

  final file = File(logPath);
  if (!await file.exists()) {
    stderr.writeln('Streaming cache diagnostics log not found: $logPath');
    exitCode = 2;
    return;
  }

  final summary = summarizeStreamingCacheDiagnosticsLog(
    await file.readAsString(),
  );
  final slowCached = summary.slowCleanCachedAttempts(thresholdMs: thresholdMs);
  final unrecoveredCached = summary.unrecoveredCleanCachedAttempts();

  stdout.writeln('STREAMING_CACHE_DIAGNOSTICS');
  stdout.writeln('log=$logPath');
  stdout.writeln('session=${summary.sessionMarker ?? 'all'}');
  stdout.writeln(
    'attempts=${summary.attempts.length} paired=${summary.pairedAttemptCount} '
    'unpaired=${summary.unpairedAttemptCount} '
    'cleanCached=${summary.cleanCachedAttemptCount} '
    'superseded=${summary.supersededAttemptCount}',
  );
  stdout.writeln(
    'statusSamples=${summary.statusCount} '
    'maxForwardCacheBytes=${summary.maxForwardCacheBytes} '
    'maxCacheDirBytes=${summary.maxCacheDirBytes} '
    'fileCacheBytesSamples=${summary.fileCacheBytesSampleCount}',
  );
  stdout.writeln(
    'slowCleanCachedThresholdMs=$thresholdMs '
    'slowCleanCached=${slowCached.length} '
    'unrecoveredCleanCached=${unrecoveredCached.length}',
  );

  if (slowCached.isNotEmpty) {
    stdout.writeln('SLOW_CLEAN_CACHED_SEEKS');
    for (final attempt in slowCached) {
      stdout.writeln('  ${attempt.compactSummary()}');
    }
  }

  if (unrecoveredCached.isNotEmpty) {
    stdout.writeln('UNRECOVERED_CLEAN_CACHED_SEEKS');
    for (final attempt in unrecoveredCached) {
      stdout.writeln('  ${attempt.compactSummary()}');
    }
  }

  final hasProblems =
      slowCached.isNotEmpty ||
      unrecoveredCached.isNotEmpty ||
      summary.unpairedAttemptCount > 0;
  if (failOnProblems && hasProblems) {
    exitCode = 1;
  }
}
