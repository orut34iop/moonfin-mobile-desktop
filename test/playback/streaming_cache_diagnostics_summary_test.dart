import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/playback/streaming_cache_diagnostics_summary.dart';

void main() {
  group('streaming cache diagnostics summary', () {
    test('flags slow clean cached seeks and missing results', () {
      final summary = summarizeStreamingCacheDiagnosticsLog('''
--- PlaybackDiagnostics session 2026-06-21T21:52:44.380821 ---
{"event":"mediaKitStreamingCacheStatus","timestamp":"2026-06-21T21:52:49","forwardCacheBytes":756126832,"cacheDirBytes":0,"fileCacheBytes":null}
{"event":"mediaKitStreamingCacheSeek","timestamp":"2026-06-21T21:53:58","seekSequence":1,"targetPositionMs":1509538,"positionMs":1417200,"bufferedPositionMs":1569960,"forwardCacheBytes":159657824,"targetWithinForwardCache":true}
{"event":"mediaKitStreamingCacheSeekResult","timestamp":"2026-06-21T21:54:02","seekSequence":1,"targetPositionMs":1509538,"finalPositionMs":1509600,"elapsedMs":3667,"recoveredWithoutTimeout":true,"sawBufferingAfterSeek":true,"supersededBySeek":false}
{"event":"mediaKitStreamingCacheSeek","timestamp":"2026-06-21T21:55:07","seekSequence":2,"targetPositionMs":2016126,"positionMs":1972360,"bufferedPositionMs":2099960,"forwardCacheBytes":110489264,"targetWithinForwardCache":true}
''');

      expect(summary.sessionCount, equals(1));
      expect(summary.statusCount, equals(1));
      expect(summary.maxForwardCacheBytes, equals(756126832));
      expect(summary.maxCacheDirBytes, equals(0));
      expect(summary.fileCacheBytesSampleCount, equals(0));
      expect(summary.attempts, hasLength(2));
      expect(summary.pairedAttemptCount, equals(1));
      expect(summary.unpairedAttemptCount, equals(1));
      expect(summary.cleanCachedAttemptCount, equals(1));

      final slow = summary.slowCleanCachedAttempts();
      expect(slow, hasLength(1));
      expect(slow.single.targetPositionMs, equals(1509538));
      expect(slow.single.cacheMarginMs, equals(60422));
      expect(slow.single.elapsedMs, equals(3667));
    });

    test('does not count superseded seek results as clean cache hits', () {
      final summary = summarizeStreamingCacheDiagnosticsLog('''
--- PlaybackDiagnostics session 2026-06-21T21:54:27.994386 ---
{"event":"mediaKitStreamingCacheSeek","timestamp":"2026-06-21T21:54:27","seekSequence":10,"targetPositionMs":1847255,"positionMs":1829160,"bufferedPositionMs":1859960,"targetWithinForwardCache":true}
{"event":"mediaKitStreamingCacheSeek","timestamp":"2026-06-21T21:54:29","seekSequence":11,"targetPositionMs":1822767,"positionMs":1847255,"bufferedPositionMs":1859960,"targetWithinForwardCache":false}
{"event":"mediaKitStreamingCacheSeekResult","timestamp":"2026-06-21T21:54:29","seekSequence":10,"targetPositionMs":1847255,"finalPositionMs":1847255,"elapsedMs":300,"recoveredWithoutTimeout":false,"sawBufferingAfterSeek":true,"supersededBySeek":true,"supersededBySeekSequence":11}
{"event":"mediaKitStreamingCacheSeekResult","timestamp":"2026-06-21T21:54:31","seekSequence":11,"targetPositionMs":1822767,"finalPositionMs":1822880,"elapsedMs":1388,"recoveredWithoutTimeout":true,"sawBufferingAfterSeek":true,"supersededBySeek":false}
''');

      expect(summary.attempts, hasLength(2));
      expect(summary.supersededAttemptCount, equals(1));
      expect(summary.cleanCachedAttemptCount, equals(0));
      expect(summary.slowCleanCachedAttempts(), isEmpty);
      expect(summary.attempts.first.isSuperseded, isTrue);
      expect(summary.attempts.first.supersededBySeekSequence, equals(11));
    });

    test('falls back to overlap and final-position checks for legacy logs', () {
      final summary = summarizeStreamingCacheDiagnosticsLog('''
--- PlaybackDiagnostics session 2026-06-21T21:54:27.994386 ---
{"event":"mediaKitStreamingCacheSeek","timestamp":"2026-06-21T21:54:27","targetPositionMs":1847255,"positionMs":1829160,"bufferedPositionMs":1859960,"targetWithinForwardCache":true}
{"event":"mediaKitStreamingCacheSeek","timestamp":"2026-06-21T21:54:34","targetPositionMs":1897789,"positionMs":1826320,"bufferedPositionMs":1939960,"targetWithinForwardCache":true}
{"event":"mediaKitStreamingCacheSeekResult","timestamp":"2026-06-21T21:54:36","targetPositionMs":1847255,"finalPositionMs":1897789,"elapsedMs":8097,"recoveredWithoutTimeout":false,"sawBufferingAfterSeek":true}
{"event":"mediaKitStreamingCacheSeekResult","timestamp":"2026-06-21T21:54:37","targetPositionMs":1897789,"finalPositionMs":1897840,"elapsedMs":2763,"recoveredWithoutTimeout":true,"sawBufferingAfterSeek":true}
''');

      expect(summary.attempts, hasLength(2));
      expect(summary.attempts.first.isSuperseded, isTrue);
      expect(
        summary.attempts.first.overlappingTargetPositionsMs,
        equals(<int>[1897789]),
      );

      final slow = summary.slowCleanCachedAttempts();
      expect(slow, hasLength(1));
      expect(slow.single.targetPositionMs, equals(1897789));
      expect(slow.single.elapsedMs, equals(2763));
    });
  });
}
