import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:playback_core/playback_core.dart';

void main() {
  test(
    'stopInBackground starts backend stop without blocking caller',
    () async {
      final manager = PlaybackManager();
      final backend = _ControllableBackend(isPlaying: true);
      manager.setBackend(backend);

      final stopwatch = Stopwatch()..start();
      manager.stopInBackground(userInitiated: false);
      stopwatch.stop();

      expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 100)));
      expect(backend.stopStarted, isTrue);
      expect(backend.stopCompleted, isFalse);

      backend.completeStop();
      await Future<void>.delayed(Duration.zero);

      expect(backend.stopCompleted, isTrue);
      manager.dispose();
    },
  );

  test(
    'backend open timeout retries startup with transcode fallback',
    () async {
      final manager = PlaybackManager();
      final backend = _StartupRetryBackend(hangStops: true);
      final resolver = _StartupRetryResolver();
      manager
        ..setBackend(backend)
        ..setResolver(resolver)
        ..setBackendOpenTimeout(const Duration(milliseconds: 10))
        ..setBackendStopTimeout(const Duration(milliseconds: 10))
        ..setStartupRecoveryDecider(
          (_) async => PlaybackStartupRecoveryDecision.retryWithTranscode,
        );

      await manager.playItems([
        {'Id': 'item-1', 'Name': 'Test Movie'},
      ]);

      expect(backend.playCallCount, 2);
      expect(backend.stopCallCount, greaterThanOrEqualTo(1));
      expect(resolver.playMethods, [
        StreamPlayMethod.directPlay,
        StreamPlayMethod.transcode,
      ]);
      expect(manager.currentResolution?.playMethod, StreamPlayMethod.transcode);
      expect(manager.bringupState.phase, PlaybackBringupPhase.ready);

      manager.dispose();
    },
  );

  test(
    'playing while still buffering is not treated as startup ready',
    () async {
      final manager = PlaybackManager();
      final backend = _BufferingStartupBackend();
      final resolver = _StartupRetryResolver();
      manager
        ..setBackend(backend)
        ..setResolver(resolver)
        ..setStartupReadyTimeout(const Duration(milliseconds: 10))
        ..setStartupRecoveryDecider(
          (_) async => PlaybackStartupRecoveryDecision.retryWithTranscode,
        );

      await manager.playItems([
        {'Id': 'item-1', 'Name': 'Test Movie'},
      ]);

      expect(backend.playCallCount, 2);
      expect(backend.stopCallCount, 1);
      expect(resolver.playMethods, [
        StreamPlayMethod.directPlay,
        StreamPlayMethod.transcode,
      ]);
      expect(manager.currentResolution?.playMethod, StreamPlayMethod.transcode);
      expect(manager.bringupState.phase, PlaybackBringupPhase.ready);

      manager.dispose();
    },
  );

  test(
    'startup recovery does not transcode without explicit approval',
    () async {
      final manager = PlaybackManager();
      final backend = _BufferingStartupBackend();
      final resolver = _StartupRetryResolver();
      manager
        ..setBackend(backend)
        ..setResolver(resolver)
        ..setStartupReadyTimeout(const Duration(milliseconds: 10));

      await expectLater(
        manager.playItems([
          {'Id': 'item-1', 'Name': 'Test Movie'},
        ]),
        throwsA(isA<PlaybackStartupNotReadyException>()),
      );

      expect(backend.playCallCount, 1);
      expect(backend.stopCallCount, 1);
      expect(resolver.playMethods, [StreamPlayMethod.directPlay]);
      expect(manager.bringupState.phase, PlaybackBringupPhase.failed);

      manager.dispose();
    },
  );

  test(
    'direct play reporting playing without progress is not startup ready',
    () async {
      final manager = PlaybackManager();
      final backend = _StalledPlayingStartupBackend();
      final resolver = _StartupRetryResolver();
      manager
        ..setBackend(backend)
        ..setResolver(resolver)
        ..setStartupReadyTimeout(const Duration(milliseconds: 10))
        ..setStartupRecoveryDecider(
          (_) async => PlaybackStartupRecoveryDecision.retryWithTranscode,
        );

      await manager.playItems([
        {'Id': 'item-1', 'Name': 'Test Movie'},
      ]);

      expect(backend.playCallCount, 2);
      expect(backend.stopCallCount, 1);
      expect(resolver.playMethods, [
        StreamPlayMethod.directPlay,
        StreamPlayMethod.transcode,
      ]);
      expect(manager.currentResolution?.playMethod, StreamPlayMethod.transcode);
      expect(manager.bringupState.phase, PlaybackBringupPhase.ready);

      manager.dispose();
    },
  );

  test(
    'final media readiness failure after approved transcode recovery throws',
    () async {
      final manager = PlaybackManager();
      final backend = _AlwaysBufferingStartupBackend();
      final resolver = _StartupRetryResolver();
      manager
        ..setBackend(backend)
        ..setResolver(resolver)
        ..setStartupReadyTimeout(const Duration(milliseconds: 10))
        ..setStartupRecoveryDecider(
          (_) async => PlaybackStartupRecoveryDecision.retryWithTranscode,
        );

      await expectLater(
        manager.playItems([
          {'Id': 'item-1', 'Name': 'Test Movie'},
        ]),
        throwsA(isA<PlaybackStartupNotReadyException>()),
      );

      expect(backend.playCallCount, 2);
      expect(resolver.playMethods, [
        StreamPlayMethod.directPlay,
        StreamPlayMethod.transcode,
      ]);
      expect(manager.bringupState.phase, PlaybackBringupPhase.failed);

      manager.dispose();
    },
  );
}

class _StartupRetryResolver implements MediaStreamResolver {
  final playMethods = <StreamPlayMethod>[];

  @override
  Future<StreamResolutionResult> resolve(
    dynamic mediaItem, {
    Map<String, dynamic>? deviceProfile,
    int? maxStreamingBitrate,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    int? startTimeTicks,
    String? mediaSourceId,
    bool enableDirectPlay = true,
    bool enableDirectStream = true,
  }) async {
    final forcedTranscode = !enableDirectPlay && !enableDirectStream;
    final playMethod = forcedTranscode
        ? StreamPlayMethod.transcode
        : StreamPlayMethod.directPlay;
    playMethods.add(playMethod);
    return StreamResolutionResult(
      streamUrl: forcedTranscode
          ? 'https://example.test/videos/item-1/transcode.m3u8'
          : 'https://example.test/videos/item-1/stream.mkv',
      mediaSourceId: forcedTranscode ? 'transcode-source' : 'direct-source',
      playMethod: playMethod,
      mediaStreams: const [
        {'Type': 'Video'},
        {'Type': 'Audio'},
      ],
    );
  }
}

class _StartupRetryBackend extends _ControllableBackend {
  final bool hangStops;
  int playCallCount = 0;
  int stopCallCount = 0;
  Duration _duration = Duration.zero;

  _StartupRetryBackend({this.hangStops = false});

  @override
  Future<void> play(
    dynamic mediaItem, {
    Duration startPosition = Duration.zero,
  }) async {
    playCallCount++;
    if (playCallCount == 1) {
      return Completer<void>().future;
    }
    _duration = const Duration(minutes: 5);
  }

  @override
  Future<void> stop() async {
    stopCallCount++;
    if (hangStops) {
      return Completer<void>().future;
    }
  }

  @override
  Duration get duration => _duration;
}

class _BufferingStartupBackend extends _ControllableBackend {
  int playCallCount = 0;
  int stopCallCount = 0;
  bool _playing = false;
  bool _buffering = false;
  Duration _duration = Duration.zero;

  @override
  Future<void> play(
    dynamic mediaItem, {
    Duration startPosition = Duration.zero,
  }) async {
    playCallCount++;
    if (playCallCount == 1) {
      _playing = true;
      _buffering = true;
      _duration = Duration.zero;
      return;
    }
    _playing = true;
    _buffering = false;
    _duration = const Duration(minutes: 5);
  }

  @override
  Future<void> stop() async {
    stopCallCount++;
    _playing = false;
    _buffering = false;
    _duration = Duration.zero;
  }

  @override
  bool get isPlaying => _playing;

  @override
  bool get isBuffering => _buffering;

  @override
  Duration get duration => _duration;
}

class _StalledPlayingStartupBackend extends _ControllableBackend {
  int playCallCount = 0;
  int stopCallCount = 0;
  bool _playing = false;
  Duration _duration = Duration.zero;

  @override
  Future<void> play(
    dynamic mediaItem, {
    Duration startPosition = Duration.zero,
  }) async {
    playCallCount++;
    _playing = true;
    _duration = playCallCount == 1 ? Duration.zero : const Duration(minutes: 5);
  }

  @override
  Future<void> stop() async {
    stopCallCount++;
    _playing = false;
    _duration = Duration.zero;
  }

  @override
  bool get isPlaying => _playing;

  @override
  Duration get duration => _duration;
}

class _AlwaysBufferingStartupBackend extends _ControllableBackend {
  int playCallCount = 0;
  bool _playing = false;
  bool _buffering = false;

  @override
  Future<void> play(
    dynamic mediaItem, {
    Duration startPosition = Duration.zero,
  }) async {
    playCallCount++;
    _playing = true;
    _buffering = true;
  }

  @override
  Future<void> stop() async {
    _playing = false;
    _buffering = false;
  }

  @override
  bool get isPlaying => _playing;

  @override
  bool get isBuffering => _buffering;
}

class _ControllableBackend implements PlayerBackend {
  final bool _initiallyPlaying;
  final Completer<void> _stopCompleter = Completer<void>();

  bool stopStarted = false;
  bool stopCompleted = false;

  _ControllableBackend({bool isPlaying = false})
    : _initiallyPlaying = isPlaying;

  void completeStop() {
    if (!_stopCompleter.isCompleted) {
      _stopCompleter.complete();
    }
  }

  @override
  Future<void> stop() async {
    stopStarted = true;
    await _stopCompleter.future;
    stopCompleted = true;
  }

  @override
  bool get isPlaying => stopStarted ? !stopCompleted : _initiallyPlaying;

  @override
  bool get isBuffering => false;

  @override
  Duration get position => Duration.zero;

  @override
  Duration get duration => Duration.zero;

  @override
  Duration get buffer => Duration.zero;

  @override
  double get playbackSpeed => 1;

  @override
  bool get canRenderBitmapSubtitles => false;

  @override
  bool get supportsRuntimeTrackSelection => true;

  @override
  bool get requiresStartupMediaReadyCheck => true;

  @override
  bool get nativelyHandlesStartPosition => false;

  @override
  Stream<Map<String, dynamic>>? get errorStream => null;

  @override
  Stream<bool> get playingStream => const Stream<bool>.empty();

  @override
  Stream<bool> get bufferingStream => const Stream<bool>.empty();

  @override
  Stream<bool> get completedStream => const Stream<bool>.empty();

  @override
  Stream<Duration> get positionStream => const Stream<Duration>.empty();

  @override
  Stream<Duration> get durationStream => const Stream<Duration>.empty();

  @override
  Stream<Duration> get bufferStream => const Stream<Duration>.empty();

  @override
  Future<void> play(
    dynamic mediaItem, {
    Duration startPosition = Duration.zero,
  }) async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> seekTo(Duration position) async {}

  @override
  Future<void> setPlaybackSpeed(double speed) async {}

  @override
  Future<void> setAudioTrack(int index) async {}

  @override
  Future<void> setSubtitleTrack(
    int index, {
    bool isBitmapSubtitle = false,
    String? subtitleCodec,
    bool isExternalSubtitle = false,
    String? externalSubtitleUrl,
  }) async {}

  @override
  Future<void> disableSubtitleTrack() async {}

  @override
  Future<void> waitForTracksReady() async {}

  @override
  Future<void> waitForEmbeddedSubtitleCount(int count) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> setAudioDelay(double seconds) async {}

  @override
  Future<void> setSubtitleDelay(double seconds) async {}

  @override
  Future<void> addExternalSubtitle(
    String url, {
    String? title,
    String? language,
    String? codec,
  }) async {}

  @override
  Future<void> configureSubtitleStyle({
    int? textColor,
    int? backgroundColor,
    int? strokeColor,
    double? fontSize,
    int? fontWeight,
    double? verticalOffset,
  }) async {}

  @override
  Future<void> setSubtitleRendererMode(SubtitleRendererMode mode) async {}

  @override
  Map<String, dynamic> getDeviceProfile({
    bool useProgressiveTranscode = false,
  }) => const {};

  @override
  void dispose() {}
}
