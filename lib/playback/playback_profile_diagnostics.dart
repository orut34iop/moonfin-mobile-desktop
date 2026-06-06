import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:playback_core/playback_core.dart';

import 'audio_capability_profile.dart';

class PlaybackProfileDiagnostics {
  PlaybackProfileDiagnostics._();

  static final PlaybackProfileDiagnostics instance =
      PlaybackProfileDiagnostics._();

  static Future<void>? _initFuture;
  static Future<void> _writeChain = Future<void>.value();
  static File? _file;

  Map<String, dynamic>? _lastDecision;

  Map<String, dynamic>? get lastDecision =>
      _lastDecision == null ? null : Map<String, dynamic>.from(_lastDecision!);

  void logPlaybackDecision({
    required PlaybackDecisionContext context,
    required AudioCapabilityProfile audioCapabilityProfile,
    required Map<String, dynamic> media3Capabilities,
    required List<String> audioSpdifCodecs,
  }) {
    final resolution = context.resolution;
    final videoStream = _firstStreamOfType(resolution.mediaStreams, 'Video');
    final audioStream = _firstStreamOfType(resolution.mediaStreams, 'Audio');
    final subtitleStream = _firstStreamOfType(
      resolution.mediaStreams,
      'Subtitle',
    );

    final allowedAudioCodecs = _extractAllowedAudioCodecs(
      context.deviceProfile,
    );
    final hlsAudioTargets = _extractHlsAudioTargets(context.deviceProfile);

    final entry = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'itemId': _extractItemId(context.mediaItem),
      'itemName': _extractItemName(context.mediaItem),
      'backend': context.backend.runtimeType.toString(),
      'mediaSourceId': resolution.mediaSourceId,
      'playMethod': resolution.playMethod.name,
      'streamUrl': _describeUrl(resolution.streamUrl),
      'requestHeaderKeys': resolution.requestHeaders.keys.toList()..sort(),
      'transcodingReasons': List<String>.from(resolution.transcodingReasons),
      'sourceSupportsDirectPlay': resolution.sourceSupportsDirectPlay,
      'sourceSupportsDirectStream': resolution.sourceSupportsDirectStream,
      'sourceSupportsTranscoding': resolution.sourceSupportsTranscoding,
      'selectedAudioStreamIndex': context.audioStreamIndex,
      'selectedSubtitleStreamIndex': context.subtitleStreamIndex,
      'container': (resolution.container ?? '').toUpperCase(),
      'mediaType': resolution.mediaType,
      'videoCodec': _streamCodec(videoStream),
      'videoProfile': _streamString(videoStream, 'Profile'),
      'videoLevel': _streamLevel(videoStream),
      'videoRange': _streamVideoRange(videoStream, resolution),
      'audioCodec': _streamCodec(audioStream),
      'audioProfile': _streamString(audioStream, 'Profile'),
      'audioChannels': _streamChannels(audioStream),
      'subtitleCodec': _streamCodec(subtitleStream),
      'allowedAudioCodecs': allowedAudioCodecs,
      'hlsMpegTsAudioCodecs': hlsAudioTargets['mpegts'] ?? const <String>[],
      'hlsFmp4AudioCodecs': hlsAudioTargets['fmp4'] ?? const <String>[],
      'audioSpdifCodecs': _normalizeCodecs(audioSpdifCodecs),
      'audioCapabilities': audioCapabilityProfile.toMap(),
      'activeRouteType': audioCapabilityProfile.activeRouteType.name,
      'routeSupportsHdAudio': audioCapabilityProfile.routeSupportsHdAudio,
      'media3Capabilities': Map<String, dynamic>.from(media3Capabilities),
      'maxStreamingBitrate': context.maxStreamingBitrate,
    };

    _lastDecision = entry;

    _writeEntry('decision', entry);
  }

  void logPlayerBackendEvent(String event, Map<String, dynamic> payload) {
    _writeEntry(event, {
      'timestamp': DateTime.now().toIso8601String(),
      ...payload,
    });
  }

  Future<String> getLogPath() async {
    final file = await _ensureFile();
    return file.path;
  }

  void _writeEntry(String event, Map<String, dynamic> payload) {
    final entry = <String, dynamic>{'event': event, ...payload};
    final line = _safeJson(entry);
    developer.log(line, name: 'PlaybackProfileDiagnostics');
    _writeChain = _writeChain
        .catchError((_) {})
        .then((_) => _append(line))
        .catchError((error, stackTrace) {
          developer.log(
            'Failed to write playback diagnostics log',
            name: 'PlaybackProfileDiagnostics',
            error: error,
            stackTrace: stackTrace,
          );
        });
  }

  Future<void> _append(String line) async {
    final file = await _ensureFile();
    await file.writeAsString('$line\n', mode: FileMode.append);
  }

  Future<File> _ensureFile() async {
    final existing = _file;
    if (existing != null) return existing;

    await (_initFuture ??= _init());
    return _file!;
  }

  Future<void> _init() async {
    Directory docs;
    try {
      docs = await getApplicationDocumentsDirectory();
    } catch (_) {
      docs = Directory.systemTemp;
    }
    final dir = Directory('${docs.path}/Moonfin/logs');
    await dir.create(recursive: true);
    final file = File('${dir.path}/playback_diagnostics.log');
    _file = file;
    await file.writeAsString(
      '\n--- PlaybackDiagnostics session ${DateTime.now().toIso8601String()} ---\n',
      mode: FileMode.append,
    );
  }

  String _safeJson(Map<String, dynamic> payload) {
    try {
      return jsonEncode(payload);
    } catch (_) {
      return payload.toString();
    }
  }

  Map<String, dynamic> _describeUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return const <String, dynamic>{'parseable': false};
    }
    final queryKeys = uri.queryParametersAll.keys.toList()..sort();
    final path = uri.path;
    final dot = path.lastIndexOf('.');
    final extension = dot >= 0 && dot < path.length - 1
        ? path.substring(dot + 1).toLowerCase()
        : '';
    return <String, dynamic>{
      'parseable': true,
      'scheme': uri.scheme,
      'host': uri.host,
      'port': uri.hasPort ? uri.port : null,
      'path': path,
      'extension': extension,
      'queryKeys': queryKeys,
      'hasApiKey': queryKeys.any((key) => key.toLowerCase() == 'api_key'),
      'hasToken': queryKeys.any((key) => key.toLowerCase().contains('token')),
    };
  }

  String? _extractItemId(dynamic item) {
    try {
      final dynamic dyn = item;
      final raw = dyn.id;
      if (raw != null) {
        final id = raw.toString().trim();
        if (id.isNotEmpty) {
          return id;
        }
      }
    } catch (_) {}

    if (item is Map) {
      final raw = item['Id'] ?? item['id'];
      if (raw != null) {
        final id = raw.toString().trim();
        if (id.isNotEmpty) {
          return id;
        }
      }
    }

    return null;
  }

  String? _extractItemName(dynamic item) {
    try {
      final dynamic dyn = item;
      final raw = dyn.name;
      if (raw != null) {
        final name = raw.toString().trim();
        if (name.isNotEmpty) {
          return name;
        }
      }
    } catch (_) {}

    if (item is Map) {
      final raw = item['Name'] ?? item['name'];
      if (raw != null) {
        final name = raw.toString().trim();
        if (name.isNotEmpty) {
          return name;
        }
      }
    }

    return null;
  }

  Map<String, dynamic>? _firstStreamOfType(
    List<Map<String, dynamic>> streams,
    String type,
  ) {
    final expected = type.toLowerCase();
    for (final stream in streams) {
      final actual = (stream['Type'] as String?)?.toLowerCase();
      if (actual == expected) {
        return stream;
      }
    }
    return null;
  }

  String _streamCodec(Map<String, dynamic>? stream) {
    if (stream == null) {
      return '';
    }
    final codec = (stream['Codec'] as String?)?.trim();
    if (codec == null || codec.isEmpty) {
      return '';
    }
    return codec.toUpperCase();
  }

  String _streamString(Map<String, dynamic>? stream, String key) {
    if (stream == null) {
      return '';
    }
    final value = stream[key]?.toString().trim() ?? '';
    return value;
  }

  String _streamLevel(Map<String, dynamic>? stream) {
    if (stream == null) {
      return '';
    }
    final level = stream['Level'];
    if (level is num) {
      return level.toString();
    }
    return (level?.toString().trim() ?? '');
  }

  String _streamVideoRange(
    Map<String, dynamic>? stream,
    StreamResolutionResult resolution,
  ) {
    final rangeType = _streamString(stream, 'VideoRangeType');
    if (rangeType.isNotEmpty) {
      return rangeType;
    }
    final fallbackRange = _streamString(stream, 'VideoRange');
    if (fallbackRange.isNotEmpty) {
      return fallbackRange;
    }
    return (resolution.videoRangeType ?? '').trim();
  }

  String _streamChannels(Map<String, dynamic>? stream) {
    if (stream == null) {
      return '';
    }

    final raw = stream['Channels'];
    if (raw is int) {
      return raw.toString();
    }
    if (raw is num) {
      return raw.toInt().toString();
    }
    return (raw?.toString().trim() ?? '');
  }

  List<String> _extractAllowedAudioCodecs(Map<String, dynamic> profile) {
    final codecs = <String>{};
    for (final entry in _readMaps(profile['DirectPlayProfiles'])) {
      final type = (entry['Type'] as String?)?.toLowerCase();
      if (type != 'video' && type != 'audio') {
        continue;
      }
      final audioCodec = entry['AudioCodec']?.toString();
      if (audioCodec == null || audioCodec.isEmpty) {
        continue;
      }
      for (final codec in audioCodec.split(',')) {
        final normalized = codec.trim();
        if (normalized.isNotEmpty) {
          codecs.add(normalized.toUpperCase());
        }
      }
    }

    final sorted = codecs.toList();
    sorted.sort();
    return sorted;
  }

  Map<String, List<String>> _extractHlsAudioTargets(
    Map<String, dynamic> profile,
  ) {
    final mpegTs = <String>{};
    final fmp4 = <String>{};

    for (final entry in _readMaps(profile['TranscodingProfiles'])) {
      final protocol = (entry['Protocol'] as String?)?.toLowerCase();
      if (protocol != 'hls') {
        continue;
      }

      final container = (entry['Container'] as String?)?.toLowerCase() ?? '';
      final audioCodec = entry['AudioCodec']?.toString();
      if (audioCodec == null || audioCodec.isEmpty) {
        continue;
      }

      Set<String>? target;
      if (container.contains('ts')) {
        target = mpegTs;
      } else if (container.contains('mp4')) {
        target = fmp4;
      }
      if (target == null) {
        continue;
      }

      for (final codec in audioCodec.split(',')) {
        final normalized = codec.trim();
        if (normalized.isNotEmpty) {
          target.add(normalized.toUpperCase());
        }
      }
    }

    final mpegTsList = mpegTs.toList()..sort();
    final fmp4List = fmp4.toList()..sort();
    return <String, List<String>>{'mpegts': mpegTsList, 'fmp4': fmp4List};
  }

  List<Map<String, dynamic>> _readMaps(dynamic value) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }

    final rows = <Map<String, dynamic>>[];
    for (final entry in value) {
      if (entry is Map<String, dynamic>) {
        rows.add(entry);
      } else if (entry is Map) {
        rows.add(entry.map((key, value) => MapEntry(key.toString(), value)));
      }
    }
    return rows;
  }

  List<String> _normalizeCodecs(List<String> codecs) {
    final normalized = codecs
        .map((codec) => codec.trim())
        .where((codec) => codec.isNotEmpty)
        .map((codec) => codec.toUpperCase())
        .toSet()
        .toList();
    normalized.sort();
    return normalized;
  }
}
