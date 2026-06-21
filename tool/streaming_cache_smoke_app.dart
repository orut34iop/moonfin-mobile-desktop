import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:moonfin_design/moonfin_design.dart';
import 'package:path_provider/path_provider.dart';
import 'package:moonfin/playback/media_kit_player_backend.dart';
import 'package:moonfin/preference/preference_constants.dart';
import 'package:moonfin/preference/user_preferences.dart';

const _serverUrl = String.fromEnvironment(
  'MOONFIN_TEST_JELLYFIN_URL',
  defaultValue: 'http://127.0.0.1:8096',
);
const _username = String.fromEnvironment(
  'MOONFIN_TEST_JELLYFIN_USER',
  defaultValue: '115',
);
const _password = String.fromEnvironment(
  'MOONFIN_TEST_JELLYFIN_PASSWORD',
  defaultValue: '',
);
const _preferredEpisodeId = String.fromEnvironment(
  'MOONFIN_TEST_JELLYFIN_ITEM_ID',
  defaultValue: '',
);
const _smokeSeed = int.fromEnvironment(
  'MOONFIN_STREAMING_CACHE_SMOKE_SEED',
  defaultValue: 0,
);
const _cachedSeekAttemptCount = int.fromEnvironment(
  'MOONFIN_STREAMING_CACHE_CACHED_SEEK_ATTEMPTS',
  defaultValue: 6,
);
const _cachedSeekMaxRecoveryMs = int.fromEnvironment(
  'MOONFIN_STREAMING_CACHE_CACHED_SEEK_MAX_MS',
  defaultValue: 2500,
);
const _cachedSeekP90MaxRecoveryMs = int.fromEnvironment(
  'MOONFIN_STREAMING_CACHE_CACHED_SEEK_P90_MAX_MS',
  defaultValue: 2200,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  final store = PreferenceStore();
  await store.init();
  final prefs = UserPreferences(store);
  final backend = MediaKitPlayerBackend(prefs);
  final uiController = _SmokeUiController();

  runApp(_SmokeApp(backend: backend, uiController: uiController));

  var processExitCode = 0;
  try {
    await _runSmoke(backend: backend, prefs: prefs, uiController: uiController);
    debugPrint('STREAMING_CACHE_SMOKE_RESULT=pass');
  } catch (error, stackTrace) {
    processExitCode = 1;
    debugPrint('STREAMING_CACHE_SMOKE_RESULT=fail');
    debugPrint('$error');
    debugPrint('$stackTrace');
  } finally {
    await backend.stop();
    backend.dispose();
  }

  exit(processExitCode);
}

Future<void> _runSmoke({
  required MediaKitPlayerBackend backend,
  required UserPreferences prefs,
  required _SmokeUiController uiController,
}) async {
  final previousMode = prefs.get(UserPreferences.streamingCacheMode);
  final previousSize = prefs.get(UserPreferences.streamingCacheSizeGb);

  try {
    final jellyfin = _JellyfinSmokeClient(_serverUrl);
    if (_password.isEmpty) {
      throw StateError(
        'Set MOONFIN_TEST_JELLYFIN_PASSWORD with --dart-define before running.',
      );
    }
    debugPrint(
      'Streaming cache smoke: authenticating $_serverUrl as $_username',
    );
    final session = await jellyfin.authenticate(_username, _password);
    final episodes = await jellyfin.fetchEpisodes(session);
    if (_preferredEpisodeId.isEmpty && episodes.length < 3) {
      throw StateError(
        'The Jellyfin smoke test needs at least 3 episodes, found ${episodes.length}.',
      );
    }

    final seed = _smokeSeed == 0
        ? DateTime.now().millisecondsSinceEpoch
        : _smokeSeed;
    final selected = _selectSmokeEpisodes(
      episodes,
      seed: seed,
      preferredEpisodeId: _preferredEpisodeId,
    );
    debugPrint(
      'Streaming cache smoke seed=$seed selected=${selected.map((e) => e.name).join(' | ')}',
    );

    for (final mode in const [
      StreamingCacheMode.disabled,
      StreamingCacheMode.onlySsd,
    ]) {
      await prefs.set(UserPreferences.streamingCacheMode, mode);
      await prefs.set(UserPreferences.streamingCacheSizeGb, 8);
      debugPrint('Streaming cache smoke mode=${mode.name}');

      for (final episode in selected) {
        await _expectEpisodePlayable(
          backend: backend,
          uiController: uiController,
          episode: episode,
          url: jellyfin.streamUrl(session, episode),
          token: session.token,
          mode: mode,
        );
        await backend.stop();
      }
    }
  } finally {
    await prefs.set(UserPreferences.streamingCacheMode, previousMode);
    await prefs.set(UserPreferences.streamingCacheSizeGb, previousSize);
  }
}

List<_Episode> _selectSmokeEpisodes(
  List<_Episode> episodes, {
  required int seed,
  required String preferredEpisodeId,
}) {
  if (preferredEpisodeId.isNotEmpty) {
    final matches = episodes
        .where((episode) => episode.id == preferredEpisodeId)
        .toList(growable: false);
    if (matches.isEmpty) {
      throw StateError(
        'MOONFIN_TEST_JELLYFIN_ITEM_ID=$preferredEpisodeId was not found.',
      );
    }
    return matches;
  }

  final candidates = episodes
      .where(
        (episode) =>
            episode.duration == null ||
            episode.duration! >= const Duration(seconds: 45),
      )
      .toList(growable: false);
  final shuffled = List<_Episode>.from(
    candidates.length >= 3 ? candidates : episodes,
  )..shuffle(Random(seed));
  return shuffled.take(3).toList(growable: false);
}

Future<void> _expectEpisodePlayable({
  required MediaKitPlayerBackend backend,
  required _SmokeUiController uiController,
  required _Episode episode,
  required String url,
  required String token,
  required StreamingCacheMode mode,
}) async {
  debugPrint('Opening "${episode.name}" with cache mode ${mode.name}');
  await backend.play(<String, dynamic>{
    'url': url,
    'headers': {'X-Emby-Token': token},
    'mediaType': 'video',
    if (episode.container != null) 'container': episode.container,
  });
  await backend.resume();
  uiController.update(
    _SmokePlaybackSnapshot.fromBackend(
      backend,
      episodeName: episode.name,
      mode: mode,
    ),
  );

  final loaded = await _waitUntil(() {
    uiController.update(
      _SmokePlaybackSnapshot.fromBackend(
        backend,
        episodeName: episode.name,
        mode: mode,
      ),
    );
    return backend.duration > Duration.zero ||
        backend.position > Duration.zero ||
        backend.buffer > Duration.zero;
  }, timeout: const Duration(seconds: 60));

  if (!loaded) {
    throw StateError(
      'Episode "${episode.name}" did not load with cache mode ${mode.name}: '
      '${_playbackEvidence(backend)}.',
    );
  }

  final before = backend.position;
  final progressed = await _waitUntil(() {
    uiController.update(
      _SmokePlaybackSnapshot.fromBackend(
        backend,
        episodeName: episode.name,
        mode: mode,
      ),
    );
    return backend.position > before + const Duration(milliseconds: 500);
  }, timeout: const Duration(seconds: 30));
  if (!progressed) {
    throw StateError(
      'Episode "${episode.name}" did not show playback progress with cache '
      'mode ${mode.name}: ${_playbackEvidence(backend)}.',
    );
  }

  final target = _seekTarget(backend);
  debugPrint(
    'Streaming cache smoke drag/seek "${episode.name}" '
    'mode=${mode.name} targetMs=${target.inMilliseconds}',
  );
  await backend.seekTo(target);
  final seeked = await _waitUntil(() {
    uiController.update(
      _SmokePlaybackSnapshot.fromBackend(
        backend,
        episodeName: episode.name,
        mode: mode,
      ),
    );
    return backend.position >= target - const Duration(milliseconds: 750);
  }, timeout: const Duration(seconds: 20));
  if (!seeked) {
    throw StateError(
      'Episode "${episode.name}" did not reach seek target with cache mode '
      '${mode.name}: target=${target.inMilliseconds}ms, '
      '${_playbackEvidence(backend)}.',
    );
  }

  if (mode == StreamingCacheMode.onlySsd) {
    await _expectCacheHitEvidence(
      backend: backend,
      uiController: uiController,
      episode: episode,
      mode: mode,
    );
  } else {
    final cacheBytes = await _streamingCacheDirectorySizeBytes();
    debugPrint(
      'STREAMING_CACHE_SMOKE_NO_CACHE mode=${mode.name} '
      'episode="${episode.name}" cacheDirBytes=$cacheBytes '
      'bufferMs=${backend.buffer.inMilliseconds}',
    );
  }
}

String _playbackEvidence(MediaKitPlayerBackend backend) {
  return 'position=${backend.position.inMilliseconds}ms, '
      'duration=${backend.duration.inMilliseconds}ms, '
      'buffer=${backend.buffer.inMilliseconds}ms, '
      'isPlaying=${backend.isPlaying}';
}

Future<void> _expectCacheHitEvidence({
  required MediaKitPlayerBackend backend,
  required _SmokeUiController uiController,
  required _Episode episode,
  required StreamingCacheMode mode,
}) async {
  Duration requiredAhead() => _visibleCacheAheadThreshold(backend.duration);
  final bufferedAhead = await _waitUntil(() {
    uiController.update(
      _SmokePlaybackSnapshot.fromBackend(
        backend,
        episodeName: episode.name,
        mode: mode,
      ),
    );
    return backend.buffer >= backend.position + requiredAhead();
  }, timeout: const Duration(seconds: 90));
  if (!bufferedAhead) {
    throw StateError(
      'Episode "${episode.name}" never exposed bufferedPosition > position '
      'by at least ${requiredAhead().inMilliseconds}ms with cache mode '
      '${mode.name}: ${_playbackEvidence(backend)}.',
    );
  }
  final mpvProperties = await _readNativeMpvProperties(backend);

  uiController.update(
    _SmokePlaybackSnapshot.fromBackend(
      backend,
      episodeName: episode.name,
      mode: mode,
    ),
  );
  final visual = await uiController.captureSeekbarEvidence(
    label: '${mode.name}-${_safeFilePart(episode.name)}',
  );
  if (!visual.hasBufferedSegment) {
    throw StateError(
      'Seekbar screenshot did not contain the buffered progress segment for '
      '"${episode.name}": ${visual.summary}.',
    );
  }

  final seekResults = <_CachedSeekSmokeResult>[];
  final attemptCount = max(1, _cachedSeekAttemptCount);
  for (var attempt = 0; attempt < attemptCount; attempt++) {
    final ready = await _waitUntil(() {
      uiController.update(
        _SmokePlaybackSnapshot.fromBackend(
          backend,
          episodeName: episode.name,
          mode: mode,
        ),
      );
      return backend.buffer >= backend.position + requiredAhead();
    }, timeout: const Duration(seconds: 90));
    if (!ready) {
      throw StateError(
        'Episode "${episode.name}" did not rebuild enough forward cache before '
        'cached seek attempt ${attempt + 1}/$attemptCount: '
        '${_playbackEvidence(backend)}.',
      );
    }

    final position = backend.position;
    final bufferedPosition = backend.buffer;
    final target = _cachedSeekTarget(
      position: position,
      bufferedPosition: bufferedPosition,
      duration: backend.duration,
    );
    final targetWithinForwardCache =
        target > position && target <= bufferedPosition;
    if (!targetWithinForwardCache) {
      throw StateError(
        'Unable to choose a seek target inside the forward cache for '
        '"${episode.name}" on cached seek attempt ${attempt + 1}/$attemptCount: '
        'target=${target.inMilliseconds}ms, ${_playbackEvidence(backend)}.',
      );
    }

    debugPrint(
      'Streaming cache smoke cached drag/seek "${episode.name}" '
      'mode=${mode.name} attempt=${attempt + 1}/$attemptCount '
      'targetMs=${target.inMilliseconds} '
      'positionMs=${position.inMilliseconds} '
      'bufferedPositionMs=${bufferedPosition.inMilliseconds}',
    );
    final seekStartedAt = DateTime.now();
    await backend.seekTo(target);
    final seeked = await _waitUntil(() {
      uiController.update(
        _SmokePlaybackSnapshot.fromBackend(
          backend,
          episodeName: episode.name,
          mode: mode,
        ),
      );
      return backend.position >= target - const Duration(milliseconds: 750) &&
          !backend.isBuffering &&
          backend.isPlaying;
    }, timeout: const Duration(seconds: 20));
    final seekRecoveryMs = DateTime.now()
        .difference(seekStartedAt)
        .inMilliseconds;
    final result = _CachedSeekSmokeResult(
      attempt: attempt + 1,
      position: position,
      bufferedPosition: bufferedPosition,
      target: target,
      seekRecoveryMs: seekRecoveryMs,
    );
    seekResults.add(result);
    if (!seeked) {
      throw StateError(
        'Episode "${episode.name}" did not reach cached seek target with cache '
        'mode ${mode.name}: ${result.summary}, ${_playbackEvidence(backend)}.',
      );
    }
  }

  final slowResults = seekResults
      .where((result) => result.seekRecoveryMs > _cachedSeekMaxRecoveryMs)
      .toList(growable: false);
  final p90RecoveryMs = _percentileNearest(
    seekResults.map((result) => result.seekRecoveryMs).toList(growable: false),
    0.90,
  );
  if (slowResults.isNotEmpty || p90RecoveryMs > _cachedSeekP90MaxRecoveryMs) {
    throw StateError(
      'Episode "${episode.name}" recovered too slowly after repeated cached '
      'seeks: p90Ms=$p90RecoveryMs, '
      'maxAllowedMs=$_cachedSeekMaxRecoveryMs, '
      'p90AllowedMs=$_cachedSeekP90MaxRecoveryMs, '
      'slow=${slowResults.map((result) => result.summary).toList()}, '
      'all=${seekResults.map((result) => result.summary).toList()}.',
    );
  }

  final diskEvidence = await _streamingCacheDiskEvidence();
  if (!_cacheOnDiskEnabled(mpvProperties)) {
    throw StateError(
      'Episode "${episode.name}" did not enable mpv cache-on-disk '
      'with cache mode ${mode.name}: ${diskEvidence.summary}, '
      'mpvProperties=$mpvProperties, ${_playbackEvidence(backend)}.',
    );
  }
  if (!diskEvidence.hasEvidence) {
    throw StateError(
      'Episode "${episode.name}" did not expose disk cache evidence with cache '
      'mode ${mode.name}: ${diskEvidence.summary}, '
      'mpvProperties=$mpvProperties, ${_playbackEvidence(backend)}.',
    );
  }

  debugPrint(
    'STREAMING_CACHE_SMOKE_CACHE_HIT mode=${mode.name} '
    'episode="${episode.name}" attempts=${seekResults.length} '
    'seekRecoveryP90Ms=$p90RecoveryMs '
    'seekRecoveryMaxMs=${seekResults.map((r) => r.seekRecoveryMs).reduce(max)} '
    'seekResults=${seekResults.map((result) => result.summary).toList()} '
    'cacheDirBytes=${diskEvidence.visibleBytes} '
    'cacheDir="${diskEvidence.cacheDir}" '
    'openCacheFileCount=${diskEvidence.openCacheFileCount} '
    'hasVisibleDiskEvidence=${diskEvidence.hasEvidence} '
    'mpvProperties=$mpvProperties '
    'seekbarBufferedPixels=${visual.bufferedPixelCount} '
    'seekbarScreenshot="${visual.path}"',
  );
}

Duration _seekTarget(MediaKitPlayerBackend backend) {
  final duration = backend.duration;
  if (duration > const Duration(seconds: 30)) {
    return duration ~/ 3;
  }
  return backend.position + const Duration(seconds: 5);
}

Duration _cachedSeekTarget({
  required Duration position,
  required Duration bufferedPosition,
  required Duration duration,
}) {
  final ahead = bufferedPosition - position;
  final jump = ahead > const Duration(seconds: 12)
      ? Duration(microseconds: (ahead.inMicroseconds * 0.75).round())
      : ahead ~/ 2;
  var target = position + jump;
  if (duration > Duration.zero &&
      target > duration - const Duration(seconds: 1)) {
    target = duration - const Duration(seconds: 1);
  }
  return target;
}

int _percentileNearest(List<int> values, double percentile) {
  if (values.isEmpty) {
    return 0;
  }
  final sorted = List<int>.from(values)..sort();
  final index = ((sorted.length - 1) * percentile).round();
  final clampedIndex = index < 0
      ? 0
      : index >= sorted.length
      ? sorted.length - 1
      : index;
  return sorted[clampedIndex];
}

Duration _visibleCacheAheadThreshold(Duration duration) {
  if (duration <= Duration.zero) {
    return const Duration(seconds: 20);
  }
  final scaled = duration ~/ 80;
  if (scaled < const Duration(seconds: 20)) {
    return const Duration(seconds: 20);
  }
  if (scaled > const Duration(seconds: 90)) {
    return const Duration(seconds: 90);
  }
  return scaled;
}

Future<int> _streamingCacheDirectorySizeBytes() async {
  final dir = Directory(await _streamingCacheDirectoryPath());
  if (!await dir.exists()) {
    return 0;
  }

  var total = 0;
  await for (final entity in dir.list(recursive: true, followLinks: false)) {
    if (entity is! File) {
      continue;
    }
    try {
      total += await entity.length();
    } catch (_) {}
  }
  return total;
}

Future<String> _streamingCacheDirectoryPath() async {
  final base = await getTemporaryDirectory();
  return '${base.path}/moonfin-streaming-cache';
}

Future<Map<String, String>> _readNativeMpvProperties(
  MediaKitPlayerBackend backend,
) async {
  final native = backend.player.platform;
  final dynamic dyn = native;
  final result = <String, String>{};
  for (final key in const [
    'cache',
    'cache-on-disk',
    'cache-secs',
    'demuxer-cache-dir',
    'demuxer-cache-state',
    'demuxer-cache-time',
    'demuxer-cache-unlink-files',
    'demuxer-max-back-bytes',
    'demuxer-max-bytes',
    'demuxer-seekable-cache',
    'options/cache',
    'options/cache-on-disk',
    'options/cache-secs',
    'options/demuxer-cache-dir',
    'options/demuxer-cache-unlink-files',
    'options/demuxer-max-back-bytes',
    'options/demuxer-max-bytes',
    'options/demuxer-seekable-cache',
  ]) {
    try {
      result[key] = (await Future<String>.value(dyn.getProperty(key))).trim();
    } catch (error) {
      result[key] = 'ERROR:$error';
    }
  }
  return result;
}

bool _cacheOnDiskEnabled(Map<String, String> mpvProperties) {
  return mpvProperties['cache-on-disk'] == 'yes' ||
      mpvProperties['options/cache-on-disk'] == 'yes';
}

Future<_StreamingCacheDiskEvidence> _streamingCacheDiskEvidence() async {
  final cacheDir = await _streamingCacheDirectoryPath();
  final visibleBytes = await _streamingCacheDirectorySizeBytes();
  final openCacheFiles = <String>[];

  try {
    final result = await Process.run('/usr/sbin/lsof', ['-p', pid.toString()]);
    final output = '${result.stdout}\n${result.stderr}';
    for (final line in output.split('\n')) {
      if (line.contains('moonfin-streaming-cache') ||
          line.contains('/mpv') ||
          line.contains('cache-on-disk')) {
        openCacheFiles.add(line.trim());
      }
      if (openCacheFiles.length >= 10) {
        break;
      }
    }
  } catch (_) {}

  return _StreamingCacheDiskEvidence(
    cacheDir: cacheDir,
    visibleBytes: visibleBytes,
    openCacheFiles: openCacheFiles,
  );
}

String _safeFilePart(String value) {
  return value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_');
}

Future<bool> _waitUntil(
  bool Function() condition, {
  required Duration timeout,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (condition()) {
      return true;
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  return condition();
}

class _SmokeApp extends StatelessWidget {
  const _SmokeApp({required this.backend, required this.uiController});

  final MediaKitPlayerBackend backend;
  final _SmokeUiController uiController;

  @override
  Widget build(BuildContext context) {
    final controller = backend.videoController;
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: controller == null
                  ? const SizedBox.shrink()
                  : Video(controller: controller),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _SmokeSeekbarPanel(controller: uiController),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmokeUiController {
  final GlobalKey repaintKey = GlobalKey();
  final ValueNotifier<_SmokePlaybackSnapshot> snapshot = ValueNotifier(
    const _SmokePlaybackSnapshot(),
  );

  void update(_SmokePlaybackSnapshot value) {
    snapshot.value = value;
  }

  Future<_SeekbarVisualEvidence> captureSeekbarEvidence({
    required String label,
  }) async {
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('Seekbar evidence boundary is not mounted.');
    }

    final image = await boundary.toImage(pixelRatio: 2);
    final pngData = await image.toByteData(format: ui.ImageByteFormat.png);
    final rawData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (pngData == null || rawData == null) {
      throw StateError('Unable to capture seekbar evidence image.');
    }

    final dir = Directory(
      '${(await getTemporaryDirectory()).path}/moonfin-streaming-cache-smoke',
    );
    await dir.create(recursive: true);
    final path =
        '${dir.path}/seekbar-$label-${DateTime.now().millisecondsSinceEpoch}.png';
    await File(path).writeAsBytes(pngData.buffer.asUint8List());

    final bufferedPixels = _countBufferedPixels(
      rawData.buffer.asUint8List(),
      width: image.width,
      height: image.height,
    );
    return _SeekbarVisualEvidence(
      path: path,
      bufferedPixelCount: bufferedPixels,
      hasBufferedSegment: bufferedPixels > 80,
    );
  }

  int _countBufferedPixels(
    List<int> rgba, {
    required int width,
    required int height,
  }) {
    var count = 0;
    final startY = (height * 0.35).round();
    final endY = (height * 0.72).round();
    for (var y = startY; y < endY; y++) {
      for (var x = 0; x < width; x++) {
        final offset = (y * width + x) * 4;
        final r = rgba[offset];
        final g = rgba[offset + 1];
        final b = rgba[offset + 2];
        final a = rgba[offset + 3];
        final grayish =
            (r - g).abs() < 24 && (r - b).abs() < 24 && (g - b).abs() < 24;
        if (a > 220 && grayish && r >= 90 && r <= 220) {
          count++;
        }
      }
    }
    return count;
  }
}

class _SmokePlaybackSnapshot {
  const _SmokePlaybackSnapshot({
    this.episodeName = '',
    this.mode = StreamingCacheMode.disabled,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.buffer = Duration.zero,
  });

  final String episodeName;
  final StreamingCacheMode mode;
  final Duration position;
  final Duration duration;
  final Duration buffer;

  factory _SmokePlaybackSnapshot.fromBackend(
    MediaKitPlayerBackend backend, {
    required String episodeName,
    required StreamingCacheMode mode,
  }) {
    return _SmokePlaybackSnapshot(
      episodeName: episodeName,
      mode: mode,
      position: backend.position,
      duration: backend.duration,
      buffer: backend.buffer,
    );
  }
}

class _SeekbarVisualEvidence {
  const _SeekbarVisualEvidence({
    required this.path,
    required this.bufferedPixelCount,
    required this.hasBufferedSegment,
  });

  final String path;
  final int bufferedPixelCount;
  final bool hasBufferedSegment;

  String get summary =>
      'path="$path", bufferedPixelCount=$bufferedPixelCount, '
      'hasBufferedSegment=$hasBufferedSegment';
}

class _CachedSeekSmokeResult {
  const _CachedSeekSmokeResult({
    required this.attempt,
    required this.position,
    required this.bufferedPosition,
    required this.target,
    required this.seekRecoveryMs,
  });

  final int attempt;
  final Duration position;
  final Duration bufferedPosition;
  final Duration target;
  final int seekRecoveryMs;

  String get summary =>
      'attempt=$attempt positionMs=${position.inMilliseconds} '
      'targetMs=${target.inMilliseconds} '
      'bufferedPositionMs=${bufferedPosition.inMilliseconds} '
      'cacheMarginMs=${(bufferedPosition - target).inMilliseconds} '
      'seekRecoveryMs=$seekRecoveryMs';
}

class _StreamingCacheDiskEvidence {
  const _StreamingCacheDiskEvidence({
    required this.cacheDir,
    required this.visibleBytes,
    required this.openCacheFiles,
  });

  final String cacheDir;
  final int visibleBytes;
  final List<String> openCacheFiles;

  int get openCacheFileCount => openCacheFiles.length;
  bool get hasEvidence => visibleBytes > 0 || openCacheFiles.isNotEmpty;

  String get summary =>
      'cacheDir="$cacheDir", visibleBytes=$visibleBytes, '
      'openCacheFileCount=$openCacheFileCount, '
      'openCacheFiles=${openCacheFiles.take(3).toList()}';
}

class _SmokeSeekbarPanel extends StatelessWidget {
  const _SmokeSeekbarPanel({required this.controller});

  final _SmokeUiController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<_SmokePlaybackSnapshot>(
      valueListenable: controller.snapshot,
      builder: (context, snapshot, _) {
        final durationMs = max(snapshot.duration.inMilliseconds, 1).toDouble();
        final positionMs = snapshot.position.inMilliseconds
            .clamp(0, snapshot.duration.inMilliseconds)
            .toDouble();
        final bufferMs = snapshot.buffer.inMilliseconds
            .clamp(0, snapshot.duration.inMilliseconds)
            .toDouble();
        final hasVisibleBuffer =
            snapshot.buffer > snapshot.position + const Duration(seconds: 1);
        final visibleBufferMs = hasVisibleBuffer ? bufferMs : positionMs;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${snapshot.mode.name}  ${snapshot.episodeName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                RepaintBoundary(
                  key: controller.repaintKey,
                  child: ColoredBox(
                    color: Colors.black,
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 7,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 14,
                        ),
                        activeTrackColor: AppColorScheme.rangeProgress,
                        secondaryActiveTrackColor:
                            AppColorScheme.seekbarBuffered,
                        inactiveTrackColor: AppColorScheme.rangeTrack,
                        thumbColor: AppColorScheme.rangeThumb,
                        overlayColor: AppColorScheme.rangeThumb.withValues(
                          alpha: 0.2,
                        ),
                      ),
                      child: Slider(
                        value: positionMs.clamp(0.0, durationMs),
                        secondaryTrackValue: visibleBufferMs.clamp(
                          0.0,
                          durationMs,
                        ),
                        min: 0,
                        max: durationMs,
                        onChanged: (_) {},
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _JellyfinSmokeClient {
  _JellyfinSmokeClient(String baseUrl)
    : baseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), ''),
      _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl.replaceFirst(RegExp(r'/+$'), ''),
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          headers: {
            'X-Emby-Authorization':
                'MediaBrowser Client="MoonfinPlaybackSmoke", '
                'Device="Codex", '
                'DeviceId="moonfin-streaming-cache-smoke", '
                'Version="1.0.0"',
          },
        ),
      );

  final String baseUrl;
  final Dio _dio;

  Future<_Session> authenticate(String username, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/Users/AuthenticateByName',
      data: {'Username': username, 'Pw': password},
    );
    final data = response.data ?? const <String, dynamic>{};
    final token = data['AccessToken']?.toString();
    final user = data['User'];
    final userId = user is Map ? user['Id']?.toString() : null;

    if (token == null || token.isEmpty || userId == null || userId.isEmpty) {
      throw StateError(
        'Jellyfin authentication did not return a token/user id.',
      );
    }
    return _Session(token: token, userId: userId);
  }

  Future<List<_Episode>> fetchEpisodes(_Session session) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/Users/${session.userId}/Items',
      queryParameters: {
        'Recursive': true,
        'IncludeItemTypes': 'Episode',
        'Fields': 'MediaSources,RunTimeTicks',
        'Limit': 300,
      },
      options: Options(headers: {'X-Emby-Token': session.token}),
    );
    final items = response.data?['Items'];
    if (items is! List) {
      return const <_Episode>[];
    }
    return items
        .whereType<Map>()
        .map((item) => _Episode.fromJson(item.cast<String, dynamic>()))
        .where((episode) => episode.id.isNotEmpty)
        .toList(growable: false);
  }

  String streamUrl(_Session session, _Episode episode) {
    final uri = Uri.parse('$baseUrl/Videos/${episode.id}/stream').replace(
      queryParameters: {
        'static': 'true',
        if (episode.mediaSourceId != null)
          'mediaSourceId': episode.mediaSourceId!,
        'api_key': session.token,
      },
    );
    return uri.toString();
  }
}

class _Session {
  const _Session({required this.token, required this.userId});

  final String token;
  final String userId;
}

class _Episode {
  const _Episode({
    required this.id,
    required this.name,
    this.mediaSourceId,
    this.container,
    this.duration,
  });

  final String id;
  final String name;
  final String? mediaSourceId;
  final String? container;
  final Duration? duration;

  factory _Episode.fromJson(Map<String, dynamic> json) {
    final mediaSources = json['MediaSources'];
    final firstSource = mediaSources is List && mediaSources.isNotEmpty
        ? mediaSources.first
        : null;
    final source = firstSource is Map
        ? firstSource.cast<String, dynamic>()
        : const <String, dynamic>{};
    final runtimeTicks = json['RunTimeTicks'] ?? source['RunTimeTicks'];
    final duration = runtimeTicks is num && runtimeTicks > 0
        ? Duration(microseconds: runtimeTicks.toInt() ~/ 10)
        : null;

    return _Episode(
      id: json['Id']?.toString() ?? '',
      name: json['Name']?.toString() ?? 'Untitled episode',
      mediaSourceId: source['Id']?.toString(),
      container: source['Container']?.toString(),
      duration: duration,
    );
  }
}
