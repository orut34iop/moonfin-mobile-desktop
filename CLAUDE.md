# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 沟通语言

所有交互和回复均使用中文。

## Build / Dev Commands

```bash
# Install dependencies
flutter pub get

# Run code generation (after changing freezed/json_serializable/drift models)
dart run build_runner build --delete-conflicting-outputs

# Static analysis
flutter analyze

# Run tests (only widget tests exist; no comprehensive suite)
flutter test

# Build release binaries per platform
flutter build apk --release                # Android
flutter build ios --release                # iOS (macOS only)
flutter build linux --release              # Linux
flutter build macos --release              # macOS
flutter build windows --release            # Windows
```

## Architecture Overview

This is a Flutter media client for Jellyfin and Emby servers. The codebase is organized into **local packages** under `packages/` that form a layered abstraction, plus the main app in `lib/`.

### Package Architecture (Bottom → Top)

| Package | Role |
|---------|------|
| `server_core` | Abstract `MediaServerClient` defining the API contract (auth, items, playback, admin, live TV, etc.). All models, API interfaces, and network configuration live here. |
| `server_jellyfin` / `server_emby` | Concrete `MediaServerClient` implementations per backend. |
| `playback_core` | Abstract playback engine: `PlaybackManager`, `PlayerBackend`, `PlayerService`, `QueueService`, `MediaStreamResolver`. |
| `playback_jellyfin` / `playback_emby` | Per-server playback implementations (stream resolution, transcoding profiles). |
| `moonfin_design` | Shared design system: themes (`MoonfinThemeSpec`, `NeonPulseThemeSpec`), colors, typography, spacing tokens. |
| `moonfin_native_video` | Android TV plugin for SurfaceView-based mpv rendering. |
| `jellyfin_preference` (alias `preference`) | Typed preferences API backed by `shared_preferences`. |
| `archive_extract`, `rar_fork`, `custom_tv_text_field_fork` | Forked third-party packages. |

### Main App (`lib/`)

```
lib/
  main.dart            # Entry point: init MediaKit, detect platform capabilities, configure DI, launch
  app.dart             # MaterialApp.router with theme, localization, global shortcuts, mini players
  auth/                # Login flow (repos, stores, services, models for servers/users/sessions)
  data/                # Repositories, services (download, cast, sync, etc.), view models, database
  di/                  # GetIt service locator setup (injection.dart + modules/)
  platform/            # Platform-specific code
  playback/            # Audio handler, device profiles, player backends, HDR/offline playback
  preference/          # PreferenceConstants + UserPreferences (typed wrappers)
  syncplay/            # SyncPlay group watch support
  ui/                  # All screens, widgets, navigation, theme, screensaver
  util/                # Platform detection, focus/input handling, fullscreen, distribution info
```

### State Management & DI

- **GetIt** (`lib/di/injection.dart`) is the service locator. Registration is split into modules: `app_module`, `auth_module`, `server_module`, `playback_module`, `preference_module`.
- **Riverpod** (`flutter_riverpod`) is used alongside GetIt for reactive UI state (connectivity, SyncPlay, etc.).
- `UserPreferences` (wrapping `jellyfin_preference`) is the central preferences store — all settings flow through typed `Preference<T>` instances.

### Navigation

- `go_router` via `lib/ui/navigation/app_router.dart`. Routes are defined as a flat list of `GoRoute` entries, each mapping to a screen.
- The `_GlobalShortcutScope` in `app.dart` manages keyboard shortcuts (Esc for back, F11 fullscreen, Ctrl+Q quit) and mouse thumb-button history navigation on desktop.
- The `PlatformDetection` utility (`lib/util/platform_detection.dart`) drives responsive layout via `useDesktopUi`, `useMobileUi`, `useLeanbackUi` getters.

### Playback Pipeline

1. `PlaybackManager` (`playback_core`) orchestrates playback lifecycle
2. `PlayerBackend` implementations (media_kit via `MediaKitPlayerBackend`, or `Media3PlayerBackend` for Android external players)
3. `MediaStreamResolver` (per-server: `playback_jellyfin`/`playback_emby`) resolves playable stream URLs, applying device profiles and transcoding preferences
4. `media_kit` + libmpv renders video/audio on all platforms
5. Android TV gets `moonfin_native_video` for performant SurfaceView rendering
6. Audio passthrough/codec capabilities are auto-detected on Android TV at startup and seeded into preferences

### Key Patterns

- **Server abstraction**: `MediaServerClientFactory.getClient(serverId, serverType, baseUrl)` creates typed clients. Multiple servers can coexist.
- **Code generation**: Models use `freezed` + `json_serializable`; DI uses `injectable_generator`; database uses `drift` with `drift_dev`. Run `dart run build_runner build --delete-conflicting-outputs` after model changes.
- **Preferences**: All preference keys are defined in `lib/preference/preference_constants.dart` as `Preference<T>` constants. Use `UserPreferences.get/set` for typed access.
- **Platform branching**: Use `PlatformDetection.isDesktop/isMobile/isTV/isAndroid` etc., not `Theme.of(context).platform`.
- **Localization**: Generated from `.arb` files in `lib/l10n/` via `flutter_localizations`. Uses `AppLocalizations.of(context)`.
