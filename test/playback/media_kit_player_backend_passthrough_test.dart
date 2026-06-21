import 'package:flutter_test/flutter_test.dart';
import 'package:moonfin/playback/media_kit_player_backend.dart';
import 'package:moonfin/preference/preference_constants.dart';

void main() {
  group('MediaKitPlayerBackend passthrough codec synthesis', () {
    test('returns empty codecs for force stereo mode', () {
      final codecs = MediaKitPlayerBackend.passthroughCodecsFromPreferences(
        audioOutputMode: AudioOutputMode.forceStereo,
        ac3PassthroughEnabled: true,
        eac3PassthroughEnabled: true,
        eac3JocPassthroughEnabled: true,
        dtsCorePassthroughEnabled: true,
        dtsHdPassthroughEnabled: true,
        trueHdPassthroughEnabled: true,
        trueHdAtmosPassthroughEnabled: true,
      );

      expect(codecs, isEmpty);
    });

    test('maps enabled codec toggles to mpv passthrough codec names', () {
      final codecs = MediaKitPlayerBackend.passthroughCodecsFromPreferences(
        audioOutputMode: AudioOutputMode.avrPassthrough,
        ac3PassthroughEnabled: true,
        eac3PassthroughEnabled: true,
        eac3JocPassthroughEnabled: false,
        dtsCorePassthroughEnabled: false,
        dtsHdPassthroughEnabled: true,
        trueHdPassthroughEnabled: true,
        trueHdAtmosPassthroughEnabled: false,
      );

      expect(codecs, equals(<String>['ac3', 'eac3', 'dts-hd', 'truehd']));
    });

    test('emits DTS core only when DTS-HD is disabled', () {
      final codecs = MediaKitPlayerBackend.passthroughCodecsFromPreferences(
        audioOutputMode: AudioOutputMode.auto,
        ac3PassthroughEnabled: false,
        eac3PassthroughEnabled: false,
        eac3JocPassthroughEnabled: false,
        dtsCorePassthroughEnabled: true,
        dtsHdPassthroughEnabled: false,
        trueHdPassthroughEnabled: false,
        trueHdAtmosPassthroughEnabled: false,
      );

      expect(codecs, equals(<String>['dts']));
    });

    test('prefers DTS-HD over DTS core when both toggles are enabled', () {
      final codecs = MediaKitPlayerBackend.passthroughCodecsFromPreferences(
        audioOutputMode: AudioOutputMode.auto,
        ac3PassthroughEnabled: false,
        eac3PassthroughEnabled: false,
        eac3JocPassthroughEnabled: false,
        dtsCorePassthroughEnabled: true,
        dtsHdPassthroughEnabled: true,
        trueHdPassthroughEnabled: false,
        trueHdAtmosPassthroughEnabled: false,
      );

      expect(codecs, equals(<String>['dts-hd']));
    });

    test('maps eac3-joc and truehd-atmos toggles to codec families', () {
      final codecs = MediaKitPlayerBackend.passthroughCodecsFromPreferences(
        audioOutputMode: AudioOutputMode.auto,
        ac3PassthroughEnabled: false,
        eac3PassthroughEnabled: false,
        eac3JocPassthroughEnabled: true,
        dtsCorePassthroughEnabled: false,
        dtsHdPassthroughEnabled: false,
        trueHdPassthroughEnabled: false,
        trueHdAtmosPassthroughEnabled: true,
      );

      expect(codecs, equals(<String>['eac3', 'truehd']));
    });
  });

  group('MediaKitPlayerBackend passthrough property synthesis', () {
    test('builds audio-spdif and audio-exclusive on desktop path', () {
      final props = MediaKitPlayerBackend
          .passthroughMpvPropertiesFromPreferences(
            audioOutputMode: AudioOutputMode.auto,
            ac3PassthroughEnabled: true,
            eac3PassthroughEnabled: true,
            eac3JocPassthroughEnabled: false,
            dtsCorePassthroughEnabled: false,
            dtsHdPassthroughEnabled: false,
            trueHdPassthroughEnabled: true,
            trueHdAtmosPassthroughEnabled: false,
            includeAudioExclusive: true,
          );

      expect(props['audio-spdif'], equals('ac3,eac3,truehd'));
      expect(props['audio-exclusive'], equals('yes'));
    });

    test('disables exclusive when no passthrough codecs remain', () {
      final props = MediaKitPlayerBackend
          .passthroughMpvPropertiesFromPreferences(
            audioOutputMode: AudioOutputMode.forceStereo,
            ac3PassthroughEnabled: true,
            eac3PassthroughEnabled: true,
            eac3JocPassthroughEnabled: true,
            dtsCorePassthroughEnabled: true,
            dtsHdPassthroughEnabled: true,
            trueHdPassthroughEnabled: true,
            trueHdAtmosPassthroughEnabled: true,
            includeAudioExclusive: true,
          );

      expect(props['audio-spdif'], isEmpty);
      expect(props['audio-exclusive'], equals('no'));
    });

    test('omits audio-exclusive on non-desktop path', () {
      final props = MediaKitPlayerBackend
          .passthroughMpvPropertiesFromPreferences(
            audioOutputMode: AudioOutputMode.auto,
            ac3PassthroughEnabled: true,
            eac3PassthroughEnabled: true,
            eac3JocPassthroughEnabled: false,
            dtsCorePassthroughEnabled: true,
            dtsHdPassthroughEnabled: true,
            trueHdPassthroughEnabled: false,
            trueHdAtmosPassthroughEnabled: false,
            includeAudioExclusive: false,
          );

      expect(props['audio-spdif'], equals('ac3,eac3,dts-hd'));
      expect(props.containsKey('audio-exclusive'), isFalse);
    });
  });

  group('MediaKitPlayerBackend streaming cache property synthesis', () {
    test('disables mpv cache when streaming cache is off', () {
      final props =
          MediaKitPlayerBackend.streamingCacheMpvPropertiesFromPreferences(
            mode: StreamingCacheMode.disabled,
            sizeGb: 8,
          );

      expect(props['cache'], equals('no'));
      expect(props['cache-on-disk'], equals('no'));
      expect(props['demuxer-seekable-cache'], equals('no'));
    });

    test('uses conservative read-ahead settings for auto mode', () {
      final props =
          MediaKitPlayerBackend.streamingCacheMpvPropertiesFromPreferences(
            mode: StreamingCacheMode.auto,
            sizeGb: 8,
          );

      expect(props['cache'], equals('auto'));
      expect(props['cache-on-disk'], equals('yes'));
      expect(props['demuxer-max-bytes'], equals('512MiB'));
      expect(props['demuxer-cache-unlink-files'], equals('immediate'));
    });

    test('maps only SSD size to mpv cache budgets', () {
      final props =
          MediaKitPlayerBackend.streamingCacheMpvPropertiesFromPreferences(
            mode: StreamingCacheMode.onlySsd,
            sizeGb: 8,
          );

      expect(props['cache'], equals('yes'));
      expect(props['cache-on-disk'], equals('yes'));
      expect(props['demuxer-max-bytes'], equals('8192MiB'));
      expect(props['demuxer-max-back-bytes'], equals('2048MiB'));
      expect(props['demuxer-seekable-cache'], equals('yes'));
    });

    test('clamps only SSD size to supported 2GB to 16GB range', () {
      final low =
          MediaKitPlayerBackend.streamingCacheMpvPropertiesFromPreferences(
            mode: StreamingCacheMode.onlySsd,
            sizeGb: 1,
          );
      final high =
          MediaKitPlayerBackend.streamingCacheMpvPropertiesFromPreferences(
            mode: StreamingCacheMode.onlySsd,
            sizeGb: 64,
          );

      expect(MediaKitPlayerBackend.normalizeStreamingCacheSizeGb(1), equals(2));
      expect(
        MediaKitPlayerBackend.normalizeStreamingCacheSizeGb(64),
        equals(16),
      );
      expect(low['demuxer-max-bytes'], equals('2048MiB'));
      expect(high['demuxer-max-bytes'], equals('16384MiB'));
    });
  });
}
