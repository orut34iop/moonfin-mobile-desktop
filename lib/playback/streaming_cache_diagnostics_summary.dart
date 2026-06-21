import 'dart:convert';

class StreamingCacheDiagnosticsSummary {
  const StreamingCacheDiagnosticsSummary({
    required this.sessionCount,
    required this.sessionMarker,
    required this.attempts,
    required this.statusCount,
    required this.maxForwardCacheBytes,
    required this.maxCacheDirBytes,
    required this.fileCacheBytesSampleCount,
  });

  final int sessionCount;
  final String? sessionMarker;
  final List<StreamingCacheSeekAttempt> attempts;
  final int statusCount;
  final int maxForwardCacheBytes;
  final int maxCacheDirBytes;
  final int fileCacheBytesSampleCount;

  int get pairedAttemptCount =>
      attempts.where((attempt) => attempt.hasResult).length;

  int get unpairedAttemptCount =>
      attempts.where((attempt) => !attempt.hasResult).length;

  int get cleanCachedAttemptCount =>
      attempts.where((attempt) => attempt.isCleanCachedHit).length;

  int get supersededAttemptCount =>
      attempts.where((attempt) => attempt.isSuperseded).length;

  List<StreamingCacheSeekAttempt> slowCleanCachedAttempts({
    int thresholdMs = 2500,
  }) {
    return attempts
        .where((attempt) => attempt.isSlowCleanCachedHit(thresholdMs))
        .toList(growable: false);
  }

  List<StreamingCacheSeekAttempt> unrecoveredCleanCachedAttempts() {
    return attempts
        .where(
          (attempt) =>
              attempt.isCleanCachedHit &&
              attempt.recoveredWithoutTimeout == false,
        )
        .toList(growable: false);
  }
}

class StreamingCacheSeekAttempt {
  const StreamingCacheSeekAttempt({
    required this.seekLine,
    required this.seekTimestamp,
    required this.seekSequence,
    required this.targetPositionMs,
    required this.positionMs,
    required this.bufferedPositionMs,
    required this.forwardCacheBytes,
    required this.targetWithinForwardCache,
    required this.resultLine,
    required this.resultTimestamp,
    required this.elapsedMs,
    required this.finalPositionMs,
    required this.recoveredWithoutTimeout,
    required this.sawBufferingAfterSeek,
    required this.supersededBySeek,
    required this.supersededBySeekSequence,
    required this.overlappingTargetPositionsMs,
    required this.finalPositionToleranceMs,
  });

  final int seekLine;
  final String? seekTimestamp;
  final int? seekSequence;
  final int? targetPositionMs;
  final int? positionMs;
  final int? bufferedPositionMs;
  final int? forwardCacheBytes;
  final bool targetWithinForwardCache;
  final int? resultLine;
  final String? resultTimestamp;
  final int? elapsedMs;
  final int? finalPositionMs;
  final bool? recoveredWithoutTimeout;
  final bool? sawBufferingAfterSeek;
  final bool supersededBySeek;
  final int? supersededBySeekSequence;
  final List<int> overlappingTargetPositionsMs;
  final int finalPositionToleranceMs;

  bool get hasResult => resultLine != null;

  int? get cacheMarginMs {
    final buffered = bufferedPositionMs;
    final target = targetPositionMs;
    if (buffered == null || target == null) {
      return null;
    }
    return buffered - target;
  }

  int? get jumpMs {
    final position = positionMs;
    final target = targetPositionMs;
    if (position == null || target == null) {
      return null;
    }
    return (target - position).abs();
  }

  int? get finalPositionDeltaMs {
    final finalPosition = finalPositionMs;
    final target = targetPositionMs;
    if (finalPosition == null || target == null) {
      return null;
    }
    return (finalPosition - target).abs();
  }

  bool get hasStaleFinalPosition {
    final delta = finalPositionDeltaMs;
    return delta != null && delta > finalPositionToleranceMs;
  }

  bool get isSuperseded =>
      supersededBySeek ||
      overlappingTargetPositionsMs.isNotEmpty ||
      hasStaleFinalPosition;

  bool get isCleanCachedHit =>
      hasResult && targetWithinForwardCache && !isSuperseded;

  bool isSlowCleanCachedHit(int thresholdMs) =>
      isCleanCachedHit && elapsedMs != null && elapsedMs! >= thresholdMs;

  String compactSummary() {
    return 'line=$seekLine seq=$seekSequence targetMs=$targetPositionMs '
        'positionMs=$positionMs bufferedMs=$bufferedPositionMs '
        'marginMs=$cacheMarginMs elapsedMs=$elapsedMs '
        'superseded=$isSuperseded recovered=$recoveredWithoutTimeout';
  }
}

StreamingCacheDiagnosticsSummary summarizeStreamingCacheDiagnosticsLog(
  String logText, {
  bool latestSessionOnly = true,
  int finalPositionToleranceMs = 1500,
}) {
  final lines = logText.split('\n');
  final markers = <_SessionMarker>[];
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    if (line.startsWith('--- PlaybackDiagnostics session ')) {
      markers.add(_SessionMarker(index: index, text: line));
    }
  }

  final start = latestSessionOnly && markers.isNotEmpty
      ? markers.last.index
      : 0;
  final sessionMarker = latestSessionOnly && markers.isNotEmpty
      ? markers.last.text
      : null;
  final events = <_LogEvent>[];
  for (var index = start; index < lines.length; index++) {
    final line = lines[index].trim();
    if (line.isEmpty || line.startsWith('---')) {
      continue;
    }
    try {
      final decoded = jsonDecode(line);
      if (decoded is Map<String, dynamic>) {
        events.add(_LogEvent(decoded, lineNumber: index + 1));
      }
    } catch (_) {}
  }

  final seeks = events
      .where((event) => event.name == 'mediaKitStreamingCacheSeek')
      .toList(growable: false);
  final results = events
      .where((event) => event.name == 'mediaKitStreamingCacheSeekResult')
      .toList(growable: false);
  final statuses = events
      .where((event) => event.name == 'mediaKitStreamingCacheStatus')
      .toList(growable: false);

  final pairings = _pairSeekEvents(seeks: seeks, results: results);
  final attempts = <StreamingCacheSeekAttempt>[];
  for (final seek in seeks) {
    final result = pairings[seek];
    final overlappingTargets = result == null
        ? const <int>[]
        : seeks
              .where(
                (other) =>
                    other.lineNumber > seek.lineNumber &&
                    other.lineNumber < result.lineNumber,
              )
              .map((event) => event.intValue('targetPositionMs'))
              .whereType<int>()
              .toList(growable: false);

    attempts.add(
      StreamingCacheSeekAttempt(
        seekLine: seek.lineNumber,
        seekTimestamp: seek.stringValue('timestamp'),
        seekSequence: seek.intValue('seekSequence'),
        targetPositionMs: seek.intValue('targetPositionMs'),
        positionMs: seek.intValue('positionMs'),
        bufferedPositionMs: seek.intValue('bufferedPositionMs'),
        forwardCacheBytes: seek.intValue('forwardCacheBytes'),
        targetWithinForwardCache:
            seek.boolValue('targetWithinForwardCache') ?? false,
        resultLine: result?.lineNumber,
        resultTimestamp: result?.stringValue('timestamp'),
        elapsedMs: result?.intValue('elapsedMs'),
        finalPositionMs: result?.intValue('finalPositionMs'),
        recoveredWithoutTimeout: result?.boolValue('recoveredWithoutTimeout'),
        sawBufferingAfterSeek: result?.boolValue('sawBufferingAfterSeek'),
        supersededBySeek: result?.boolValue('supersededBySeek') ?? false,
        supersededBySeekSequence: result?.intValue('supersededBySeekSequence'),
        overlappingTargetPositionsMs: overlappingTargets,
        finalPositionToleranceMs: finalPositionToleranceMs,
      ),
    );
  }

  return StreamingCacheDiagnosticsSummary(
    sessionCount: markers.length,
    sessionMarker: sessionMarker,
    attempts: attempts,
    statusCount: statuses.length,
    maxForwardCacheBytes: _maxIntValue(statuses, 'forwardCacheBytes'),
    maxCacheDirBytes: _maxIntValue(statuses, 'cacheDirBytes'),
    fileCacheBytesSampleCount: statuses
        .where((event) => event.intValue('fileCacheBytes') != null)
        .length,
  );
}

Map<_LogEvent, _LogEvent> _pairSeekEvents({
  required List<_LogEvent> seeks,
  required List<_LogEvent> results,
}) {
  final pairings = <_LogEvent, _LogEvent>{};
  final unmatchedSeeks = Set<int>.from(Iterable<int>.generate(seeks.length));
  final hasSequences =
      seeks.any((event) => event.intValue('seekSequence') != null) ||
      results.any((event) => event.intValue('seekSequence') != null);

  for (final result in results) {
    int? matchedIndex;
    if (hasSequences) {
      final resultSequence = result.intValue('seekSequence');
      if (resultSequence != null) {
        for (final index in unmatchedSeeks) {
          if (seeks[index].intValue('seekSequence') == resultSequence) {
            matchedIndex = index;
            break;
          }
        }
      }
    }

    matchedIndex ??= _legacyPairingIndex(
      seeks: seeks,
      unmatchedSeeks: unmatchedSeeks,
      result: result,
    );

    if (matchedIndex == null) {
      continue;
    }
    unmatchedSeeks.remove(matchedIndex);
    pairings[seeks[matchedIndex]] = result;
  }
  return pairings;
}

int? _legacyPairingIndex({
  required List<_LogEvent> seeks,
  required Set<int> unmatchedSeeks,
  required _LogEvent result,
}) {
  final prior = unmatchedSeeks
      .where((index) => seeks[index].lineNumber < result.lineNumber)
      .toList(growable: false);
  if (prior.isEmpty) {
    return null;
  }

  final target = result.intValue('targetPositionMs');
  final sameTarget = prior
      .where((index) => seeks[index].intValue('targetPositionMs') == target)
      .toList(growable: false);
  final candidates = sameTarget.isNotEmpty ? sameTarget : prior;
  candidates.sort((a, b) => seeks[a].lineNumber.compareTo(seeks[b].lineNumber));
  return candidates.last;
}

int _maxIntValue(List<_LogEvent> events, String key) {
  var maxValue = 0;
  for (final event in events) {
    final value = event.intValue(key);
    if (value != null && value > maxValue) {
      maxValue = value;
    }
  }
  return maxValue;
}

class _SessionMarker {
  const _SessionMarker({required this.index, required this.text});

  final int index;
  final String text;
}

class _LogEvent {
  const _LogEvent(this.data, {required this.lineNumber});

  final Map<String, dynamic> data;
  final int lineNumber;

  String get name => data['event']?.toString() ?? '';

  String? stringValue(String key) {
    return data[key]?.toString();
  }

  int? intValue(String key) {
    final value = data[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  bool? boolValue(String key) {
    final value = data[key];
    return value is bool ? value : null;
  }
}
