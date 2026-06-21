import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  final store = PreferenceStore();
  await store.init();
  final prefs = UserPreferences(store);
  final backend = MediaKitPlayerBackend(prefs);

  runApp(_SmokeApp(backend: backend));

  var processExitCode = 0;
  try {
    await _runSmoke(backend: backend, prefs: prefs);
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
    if (episodes.length < 3) {
      throw StateError(
        'The Jellyfin smoke test needs at least 3 episodes, found ${episodes.length}.',
      );
    }

    final seed = DateTime.now().millisecondsSinceEpoch;
    final selected = _pickRandomEpisodes(episodes, seed: seed);
    debugPrint(
      'Streaming cache smoke seed=$seed selected=${selected.map((e) => e.name).join(' | ')}',
    );

    for (final mode in const [
      StreamingCacheMode.disabled,
      StreamingCacheMode.auto,
    ]) {
      await prefs.set(UserPreferences.streamingCacheMode, mode);
      await prefs.set(UserPreferences.streamingCacheSizeGb, 8);
      debugPrint('Streaming cache smoke mode=${mode.name}');

      for (final episode in selected) {
        await _expectEpisodePlayable(
          backend: backend,
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

List<_Episode> _pickRandomEpisodes(
  List<_Episode> episodes, {
  required int seed,
}) {
  final shuffled = List<_Episode>.from(episodes)..shuffle(Random(seed));
  return shuffled.take(3).toList(growable: false);
}

Future<void> _expectEpisodePlayable({
  required MediaKitPlayerBackend backend,
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

  final loaded = await _waitUntil(() {
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
  final progressed = await _waitUntil(
    () => backend.position > before + const Duration(milliseconds: 500),
    timeout: const Duration(seconds: 30),
  );
  if (!progressed) {
    throw StateError(
      'Episode "${episode.name}" did not show playback progress with cache '
      'mode ${mode.name}: ${_playbackEvidence(backend)}.',
    );
  }
}

String _playbackEvidence(MediaKitPlayerBackend backend) {
  return 'position=${backend.position.inMilliseconds}ms, '
      'duration=${backend.duration.inMilliseconds}ms, '
      'buffer=${backend.buffer.inMilliseconds}ms, '
      'isPlaying=${backend.isPlaying}';
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
  const _SmokeApp({required this.backend});

  final MediaKitPlayerBackend backend;

  @override
  Widget build(BuildContext context) {
    final controller = backend.videoController;
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: controller == null
              ? const SizedBox.shrink()
              : Video(controller: controller),
        ),
      ),
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
        'Fields': 'MediaSources',
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
  });

  final String id;
  final String name;
  final String? mediaSourceId;
  final String? container;

  factory _Episode.fromJson(Map<String, dynamic> json) {
    final mediaSources = json['MediaSources'];
    final firstSource = mediaSources is List && mediaSources.isNotEmpty
        ? mediaSources.first
        : null;
    final source = firstSource is Map
        ? firstSource.cast<String, dynamic>()
        : const <String, dynamic>{};

    return _Episode(
      id: json['Id']?.toString() ?? '',
      name: json['Name']?.toString() ?? 'Untitled episode',
      mediaSourceId: source['Id']?.toString(),
      container: source['Container']?.toString(),
    );
  }
}
