import 'package:playback_core/playback_core.dart';
import 'package:server_core/server_core.dart';

class EmbyMediaStreamResolver implements MediaStreamResolver {
  final MediaServerClient _client;
  Future<UserPolicy?>? _policyFuture;

  EmbyMediaStreamResolver(this._client);

  Map<String, String> _buildRequestHeaders() {
    final token = _client.accessToken;
    final headers = <String, String>{
      'Authorization': buildServerAuthorizationHeader(
        scheme: 'MediaBrowser',
        deviceInfo: _client.deviceInfo,
        accessToken: token,
      ),
    };
    if (token != null && token.isNotEmpty) {
      headers['X-Emby-Token'] = token;
    }
    return headers;
  }

  bool _isAudioMediaItem(dynamic mediaItem) {
    bool isAudioType(String? rawType) {
      final type = rawType?.trim().toLowerCase();
      return type == 'audio';
    }

    try {
      final dynamic dyn = mediaItem;
      if (isAudioType(dyn.type?.toString())) {
        return true;
      }
    } catch (_) {}

    if (mediaItem is Map && isAudioType(mediaItem['Type']?.toString())) {
      return true;
    }

    return false;
  }

  Future<UserPolicy?> _currentUserPolicy() async {
    try {
      final user = await (_policyFuture ??= _client.usersApi
          .getCurrentUser()
          .then((user) => user.policy));
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _allowsTranscoding(dynamic mediaItem) async {
    final policy = await _currentUserPolicy();
    if (policy == null) {
      return true;
    }
    return _isAudioMediaItem(mediaItem)
        ? policy.enableAudioPlaybackTranscoding
        : policy.enableVideoPlaybackTranscoding;
  }

  Map<String, dynamic>? _deviceProfileForTranscodingPolicy(
    Map<String, dynamic>? deviceProfile, {
    required bool allowTranscoding,
  }) {
    if (deviceProfile == null || allowTranscoding) {
      return deviceProfile;
    }

    final profile = Map<String, dynamic>.from(deviceProfile);
    profile
      ..remove('MaxStreamingBitrate')
      ..remove('MaxStaticBitrate')
      ..remove('MusicStreamingTranscodingBitrate')
      ..remove('TranscodingProfiles');
    return profile;
  }

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
    final itemId = MediaStreamResolver.extractItemId(mediaItem);
    final allowTranscoding = await _allowsTranscoding(mediaItem);
    final effectiveDeviceProfile = _deviceProfileForTranscodingPolicy(
      deviceProfile,
      allowTranscoding: allowTranscoding,
    );

    final request = PlaybackInfoRequest(
      itemId: itemId,
      mediaSourceId: mediaSourceId,
      deviceProfile: effectiveDeviceProfile,
      maxStreamingBitrate: allowTranscoding ? maxStreamingBitrate : null,
      audioStreamIndex: audioStreamIndex,
      subtitleStreamIndex: subtitleStreamIndex,
      startTimeTicks: startTimeTicks,
      enableDirectPlay: enableDirectPlay,
      enableDirectStream: enableDirectStream,
      enableTranscoding: allowTranscoding,
    );

    final rawInfo = await _client.playbackApi.getPlaybackInfo(
      itemId,
      requestBody: request.toJson(),
      userId: _client.userId,
    );
    final info = PlaybackInfoResult.fromJson(rawInfo);

    if (info.errorCode != null) {
      throw Exception('Playback error: ${info.errorCode}');
    }
    if (info.mediaSources.isEmpty) {
      throw Exception('No media sources available for item $itemId');
    }

    final source = _selectBestSource(
      info.mediaSources,
      preferredId: mediaSourceId,
      allowTranscoding: allowTranscoding,
    );
    final hasKnownMediaStreams = source.mediaStreams.isNotEmpty;
    final hasVideoStream = source.mediaStreams.any(
      (stream) => stream['Type'] == 'Video',
    );
    final isAudioByStreams = hasKnownMediaStreams && !hasVideoStream;
    final isAudio = isAudioByStreams || _isAudioMediaItem(mediaItem);
    var (url, playMethod) = _resolveStreamUrl(itemId, source, isAudio: isAudio);

    if (playMethod == StreamPlayMethod.transcode) {
      url = MediaStreamResolver.applyStreamIndices(
        url,
        audioStreamIndex,
        subtitleStreamIndex,
      );
    }

    url = _appendAuth(url);

    final externalSubs = MediaStreamResolver.extractExternalSubtitles(
      source.mediaStreams,
      _client.baseUrl,
    );
    final authedSubs = externalSubs
        .map(
          (s) => ExternalSubtitle(
            deliveryUrl: _appendAuth(s.deliveryUrl),
            title: s.title,
            language: s.language,
            codec: s.codec,
            isDefault: s.isDefault,
            isForced: s.isForced,
            streamIndex: s.streamIndex,
          ),
        )
        .toList();

    final mediaType = MediaStreamResolver.detectMediaType(
      source.mediaStreams,
      fallbackUrl: url,
    );
    final videoRangeType = source.mediaStreams
        .where((stream) => stream['Type'] == 'Video')
        .map((stream) => stream['VideoRangeType']?.toString())
        .firstWhere(
          (value) => value != null && value.isNotEmpty,
          orElse: () => null,
        );
    final normalizationGainDb = MediaStreamResolver.extractNormalizationGainDb(
      source.mediaStreams,
    );

    return StreamResolutionResult(
      streamUrl: url,
      mediaSourceId: source.id,
      liveStreamId: source.liveStreamId,
      playSessionId: info.playSessionId,
      requestHeaders: _buildRequestHeaders(),
      playMethod: playMethod,
      container: source.container,
      videoRangeType: videoRangeType,
      mediaType: mediaType,
      normalizationGainDb: normalizationGainDb,
      externalSubtitles: authedSubs,
      mediaStreams: source.mediaStreams,
      transcodingReasons: source.transcodingReasons,
      sourceSupportsDirectPlay: source.supportsDirectPlay,
      sourceSupportsDirectStream: source.supportsDirectStream,
      sourceSupportsTranscoding: source.supportsTranscoding,
    );
  }

  String _appendAuth(String url) {
    final token = _client.accessToken;
    if (token == null || token.isEmpty) {
      return url;
    }
    final lower = url.toLowerCase();
    if (lower.contains('api_key=') || lower.contains('x-emby-token=')) {
      return url;
    }
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}api_key=${Uri.encodeComponent(token)}';
  }

  PlaybackMediaSource _selectBestSource(
    List<PlaybackMediaSource> sources, {
    String? preferredId,
    bool allowTranscoding = true,
  }) {
    if (preferredId != null) {
      final preferred = sources.where((s) => s.id == preferredId).firstOrNull;
      if (preferred != null) {
        if (allowTranscoding ||
            preferred.supportsDirectPlay ||
            preferred.supportsDirectStream ||
            _canAttemptStaticDirectVideo(preferred)) {
          return preferred;
        }
      }
    }
    PlaybackMediaSource? directStream;
    PlaybackMediaSource? staticDirect;
    PlaybackMediaSource? transcode;
    for (final s in sources) {
      if (s.supportsDirectPlay) return s;
      directStream ??= s.supportsDirectStream ? s : null;
      staticDirect ??= _canAttemptStaticDirectVideo(s) ? s : null;
      transcode ??= s.supportsTranscoding ? s : null;
    }
    final direct = directStream;
    if (direct != null) {
      return direct;
    }
    if (staticDirect != null) {
      return staticDirect;
    }
    if (allowTranscoding && transcode != null) {
      return transcode;
    }
    throw Exception('No direct playable media source available');
  }

  String _buildDirectPlayAudioUrl(String itemId, PlaybackMediaSource source) {
    final params = <String, String>{
      if (source.id.isNotEmpty) 'MediaSourceId': source.id,
      if (source.container != null && source.container!.isNotEmpty)
        'Container': source.container!,
      if (source.eTag != null && source.eTag!.isNotEmpty) 'Tag': source.eTag!,
      if (source.liveStreamId != null && source.liveStreamId!.isNotEmpty)
        'LiveStreamId': source.liveStreamId!,
      'Static': 'true',
    };
    final uri = Uri.parse(
      '${_client.baseUrl}/Audio/$itemId/stream',
    ).replace(queryParameters: params);
    return uri.toString();
  }

  String _buildDirectPlayVideoUrl(String itemId, PlaybackMediaSource source) {
    final extension = _streamExtension(source.container);
    final params = <String, String>{
      if (source.id.isNotEmpty) 'MediaSourceId': source.id,
      if (source.container != null && source.container!.isNotEmpty)
        'Container': source.container!,
      if (source.eTag != null && source.eTag!.isNotEmpty) 'Tag': source.eTag!,
      if (source.liveStreamId != null && source.liveStreamId!.isNotEmpty)
        'LiveStreamId': source.liveStreamId!,
      'Static': 'true',
    };
    final suffix = extension.isEmpty ? '' : '.$extension';
    final uri = Uri.parse(
      '${_client.baseUrl}/Videos/$itemId/stream$suffix',
    ).replace(queryParameters: params);
    return uri.toString();
  }

  String _streamExtension(String? container) {
    final firstContainer = container
        ?.split(',')
        .map((value) => value.trim().toLowerCase())
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    if (firstContainer == null || firstContainer.isEmpty) {
      return '';
    }

    return firstContainer.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  bool _canAttemptStaticDirectVideo(PlaybackMediaSource source) =>
      source.id.isNotEmpty;

  (String, StreamPlayMethod) _resolveStreamUrl(
    String itemId,
    PlaybackMediaSource source, {
    bool isAudio = false,
  }) {
    if (source.supportsDirectPlay && isAudio) {
      return (
        _buildDirectPlayAudioUrl(itemId, source),
        StreamPlayMethod.directPlay,
      );
    }

    if (source.supportsDirectPlay) {
      return (
        _buildDirectPlayVideoUrl(itemId, source),
        StreamPlayMethod.directPlay,
      );
    }
    if (source.supportsDirectStream && source.directStreamUrl != null) {
      return (
        '${_client.baseUrl}${source.directStreamUrl}',
        StreamPlayMethod.directStream,
      );
    }
    if (source.supportsDirectStream && !isAudio) {
      return (
        _buildDirectPlayVideoUrl(itemId, source),
        StreamPlayMethod.directStream,
      );
    }
    if (!isAudio && _canAttemptStaticDirectVideo(source)) {
      return (
        _buildDirectPlayVideoUrl(itemId, source),
        StreamPlayMethod.directPlay,
      );
    }
    if (source.supportsTranscoding && source.transcodingUrl != null) {
      return (
        '${_client.baseUrl}${source.transcodingUrl}',
        StreamPlayMethod.transcode,
      );
    }
    return (
      isAudio
          ? _buildDirectPlayAudioUrl(itemId, source)
          : _buildDirectPlayVideoUrl(itemId, source),
      StreamPlayMethod.directPlay,
    );
  }
}
