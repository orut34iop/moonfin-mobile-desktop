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
