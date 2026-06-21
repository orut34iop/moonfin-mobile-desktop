# Streaming Cache Test Strategy

## Why the old checks were weak

The first Streaming Cache checks proved that mpv options were applied and that
the seekbar could render a secondary buffered segment. They did not prove the
user-facing contract: repeated clicks inside the displayed cached range should
resume playback quickly.

The structural gaps were:

- Unit tests covered property synthesis and buffer normalization, not seek
  recovery behavior.
- The smoke app performed a single cached seek per episode, while manual
  failures happened during repeated clicks inside one video's buffered range.
- The smoke app selected random episodes without a stable replay path.
- Disk cache evidence was logged but not required.
- Seek diagnostics had no sequence id, so overlapping clicks could attach an old
  result to a newer final playback position.

## Required validation levels

1. Run the deterministic unit tests:

   ```bash
   flutter test --no-pub test/playback/media_kit_player_backend_passthrough_test.dart test/playback/streaming_cache_diagnostics_summary_test.dart
   ```

2. After any manual playback session, analyze the latest playback diagnostics:

   ```bash
   dart run tool/streaming_cache_diagnostics.dart
   ```

   This exits non-zero when the latest session contains slow clean cached seeks,
   unrecovered clean cached seeks, or seeks without a matching result.

3. For end-to-end validation against Jellyfin, run the smoke app with a fixed
   episode when reproducing a failure:

   ```bash
   flutter run -d macos \
     --target tool/streaming_cache_smoke_app.dart \
     --dart-define=MOONFIN_TEST_JELLYFIN_PASSWORD="$MOONFIN_TEST_JELLYFIN_PASSWORD" \
     --dart-define=MOONFIN_TEST_JELLYFIN_ITEM_ID=bbd30fcca1b4f10eeec37dc2bfdd8369 \
     --dart-define=MOONFIN_STREAMING_CACHE_SMOKE_SEED=1 \
     --dart-define=MOONFIN_STREAMING_CACHE_CACHED_SEEK_ATTEMPTS=6
   ```

   The smoke app now performs repeated cached seeks, fails when any cached seek
   is slower than `MOONFIN_STREAMING_CACHE_CACHED_SEEK_MAX_MS`, fails when p90 is
   above `MOONFIN_STREAMING_CACHE_CACHED_SEEK_P90_MAX_MS`, and requires visible
   or open-file disk cache evidence.

## Acceptance signal

A Streaming Cache change is not validated by `flutter test` alone. It needs:

- Green unit tests for diagnostics and buffer mapping.
- A clean diagnostics summary for the latest manual session.
- A repeated cached-seek smoke pass on the target media or an explicit note that
  the external Jellyfin environment was unavailable.
