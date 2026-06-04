import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';
import 'package:moonfin_design/moonfin_design.dart';
import 'package:server_core/server_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moonfin/data/repositories/mdblist_repository.dart';
import 'package:moonfin/data/services/background_service.dart';
import 'package:moonfin/data/viewmodels/library_browse_view_model.dart';
import 'package:moonfin/l10n/app_localizations.dart';
import 'package:moonfin/preference/user_preferences.dart';
import 'package:moonfin/ui/navigation/app_router.dart';
import 'package:moonfin/ui/screens/browse/library_browse_screen.dart';
import 'package:moonfin/ui/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeItemsApi itemsApi;
  late _FakeDisplayPreferencesApi displayPreferencesApi;
  late _FakeMediaServerClient client;
  late UserPreferences userPreferences;

  Future<void> setUpDependencies({bool hangDisplayPreferences = false}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await GetIt.instance.reset();

    final store = PreferenceStore();
    await store.init();
    userPreferences = UserPreferences(store);
    itemsApi = _FakeItemsApi();
    displayPreferencesApi = _FakeDisplayPreferencesApi(
      hang: hangDisplayPreferences,
    );
    client = _FakeMediaServerClient(
      itemsApi: itemsApi,
      displayPreferencesApi: displayPreferencesApi,
    );

    GetIt.instance.registerSingleton<UserPreferences>(userPreferences);
    GetIt.instance.registerSingleton<BackgroundService>(BackgroundService());
    GetIt.instance.registerSingleton<MediaServerClient>(client);
    GetIt.instance.registerSingleton<MdbListRepository>(
      MdbListRepository(client),
    );
  }

  tearDown(() async {
    await GetIt.instance.reset();
  });

  test('route path parameter keeps already decoded genre names', () {
    expect(decodeRoutePathParameter('动作'), '动作');
  });

  test('route path parameter decodes encoded genre names', () {
    expect(decodeRoutePathParameter('%E5%8A%A8%E4%BD%9C'), '动作');
  });

  test('route path parameter tolerates literal percent characters', () {
    expect(decodeRoutePathParameter('100% 科幻'), '100% 科幻');
  });

  test('genre browse by name sends Genres filter without a genre id', () async {
    await setUpDependencies();

    final vm = LibraryBrowseViewModel(
      libraryId: '',
      client: client,
      prefs: userPreferences,
      mdbListRepository: MdbListRepository(client),
      overrideName: '科幻',
      includeItemTypes: const ['Movie'],
    );

    await vm.load();

    expect(vm.state, LibraryBrowseState.ready);
    expect(vm.libraryName, '科幻');
    expect(itemsApi.lastGenres, const ['科幻']);
    expect(itemsApi.lastGenreIds, isNull);
    expect(itemsApi.lastIncludeItemTypes, const ['Movie']);
    expect(itemsApi.lastParentId, isNull);
  });

  test('unscoped genre browse skips server display preferences', () async {
    await setUpDependencies(hangDisplayPreferences: true);

    final vm = LibraryBrowseViewModel(
      libraryId: '',
      client: client,
      prefs: userPreferences,
      mdbListRepository: MdbListRepository(client),
      overrideName: '科幻',
      includeItemTypes: const ['Movie'],
    );

    await vm.load().timeout(const Duration(seconds: 1));

    expect(vm.state, LibraryBrowseState.ready);
    expect(itemsApi.lastGenres, const ['科幻']);
    expect(displayPreferencesApi.getCalls, isEmpty);
  });

  test('unscoped genre browse by id also skips server display preferences', () async {
    await setUpDependencies(hangDisplayPreferences: true);

    final vm = LibraryBrowseViewModel(
      libraryId: '',
      client: client,
      prefs: userPreferences,
      mdbListRepository: MdbListRepository(client),
      genreId: 'genre-id',
      overrideName: '犯罪',
      includeItemTypes: const ['Movie'],
    );

    await vm.load().timeout(const Duration(seconds: 1));

    expect(vm.state, LibraryBrowseState.ready);
    expect(itemsApi.lastGenreIds, const ['genre-id']);
    expect(itemsApi.lastGenres, isNull);
    expect(displayPreferencesApi.getCalls, isEmpty);
  });

  testWidgets('genre browse screen renders without a grey error widget', (
    tester,
  ) async {
    await setUpDependencies();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildTheme(ThemeRegistry.resolveById(
          ThemeRegistry.moonfinId,
        )),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LibraryBrowseScreen(
          libraryId: '',
          genreName: '科幻',
          includeItemTypes: ['Movie'],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('科幻'), findsOneWidget);
    expect(find.textContaining('No items'), findsOneWidget);
    expect(itemsApi.lastGenres, const ['科幻']);
    expect(itemsApi.lastGenreIds, isNull);
  });

  testWidgets('genre browse screen renders returned movie cards', (
    tester,
  ) async {
    await setUpDependencies();
    itemsApi.responseItems = const [
      {
        'Id': 'movie-1',
        'Name': '0',
        'Type': 'Movie',
        'ProductionYear': 2007,
        'Genres': ['动作', '冒险', '科幻'],
        'CommunityRating': 5.0,
        'UserData': <String, dynamic>{},
      },
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildTheme(ThemeRegistry.resolveById(
          ThemeRegistry.moonfinId,
        )),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LibraryBrowseScreen(
          libraryId: '',
          genreName: '科幻',
          includeItemTypes: ['Movie'],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('科幻'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.textContaining('No items'), findsNothing);
    expect(itemsApi.lastGenres, const ['科幻']);
    expect(itemsApi.lastIncludeItemTypes, const ['Movie']);
  });
}

class _FakeMediaServerClient implements MediaServerClient {
  _FakeMediaServerClient({
    required this.itemsApi,
    required this.displayPreferencesApi,
  });

  @override
  final ItemsApi itemsApi;

  @override
  final DisplayPreferencesApi displayPreferencesApi;

  @override
  final ImageApi imageApi = const _FakeImageApi();

  @override
  final UserViewsApi userViewsApi = const _FakeUserViewsApi();

  @override
  ServerType get serverType => ServerType.emby;

  @override
  DeviceInfo get deviceInfo => const DeviceInfo(
        id: 'test',
        name: 'test',
        appName: 'Moonfin',
        appVersion: 'test',
      );

  @override
  String baseUrl = 'http://example.test';

  @override
  String? accessToken;

  @override
  String? userId = 'user';

  @override
  void dispose() {}

  @override
  AuthApi get authApi => throw UnimplementedError();

  @override
  PlaybackApi get playbackApi => throw UnimplementedError();

  @override
  SessionApi get sessionApi => throw UnimplementedError();

  @override
  SystemApi get systemApi => throw UnimplementedError();

  @override
  UserLibraryApi get userLibraryApi => throw UnimplementedError();

  @override
  LiveTvApi get liveTvApi => throw UnimplementedError();

  @override
  InstantMixApi get instantMixApi => throw UnimplementedError();

  @override
  UsersApi get usersApi => throw UnimplementedError();

  @override
  AdminSystemApi get adminSystemApi => throw UnimplementedError();

  @override
  AdminUsersApi get adminUsersApi => throw UnimplementedError();

  @override
  AdminLibraryApi get adminLibraryApi => throw UnimplementedError();

  @override
  AdminEnvironmentApi get adminEnvironmentApi => throw UnimplementedError();

  @override
  AdminTasksApi get adminTasksApi => throw UnimplementedError();

  @override
  AdminPluginsApi get adminPluginsApi => throw UnimplementedError();

  @override
  AdminDevicesApi get adminDevicesApi => throw UnimplementedError();

  @override
  AdminApiKeysApi get adminApiKeysApi => throw UnimplementedError();

  @override
  AdminBackupApi get adminBackupApi => throw UnimplementedError();

  @override
  AdminLiveTvApi get adminLiveTvApi => throw UnimplementedError();

  @override
  AdminItemsApi get adminItemsApi => throw UnimplementedError();

  @override
  SyncPlayApi? get syncPlayApi => null;

  @override
  HomeScreenSectionsApi? get homeScreenSectionsApi => null;

  @override
  KefinTweaksApi? get kefinTweaksApi => null;
}

class _FakeItemsApi implements ItemsApi {
  List<Map<String, dynamic>> responseItems = const <Map<String, dynamic>>[];
  List<String>? lastGenreIds;
  List<String>? lastGenres;
  List<String>? lastIncludeItemTypes;
  String? lastParentId;

  @override
  Future<Map<String, dynamic>> getItems({
    String? parentId,
    List<String>? ids,
    List<String>? includeItemTypes,
    List<String>? excludeItemTypes,
    String? sortBy,
    String? sortOrder,
    int? startIndex,
    int? limit,
    bool? recursive,
    String? searchTerm,
    String? fields,
    List<String>? personIds,
    List<String>? artistIds,
    List<String>? filters,
    List<String>? seriesStatus,
    String? nameStartsWith,
    String? nameLessThan,
    List<String>? genreIds,
    List<String>? genres,
    bool? isFavorite,
    bool? collapseBoxSetItems,
    bool? enableTotalRecordCount,
    String? enableImageTypes,
    List<String>? tags,
    List<String>? studios,
    DateTime? minPremiereDate,
    String? maxOfficialRating,
    bool? hasParentalRating,
  }) async {
    lastParentId = parentId;
    lastGenreIds = genreIds;
    lastGenres = genres;
    lastIncludeItemTypes = includeItemTypes;
    return {
      'Items': responseItems,
      'TotalRecordCount': responseItems.length,
    };
  }

  @override
  Future<Map<String, dynamic>> getItem(String itemId) =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> getAncestors(String itemId) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getSimilarItems(String itemId, {int? limit}) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getNextUp({
    String? seriesId,
    String? parentId,
    int? limit,
    String? fields,
    bool? enableResumable,
  }) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getResumeItems({
    String? parentId,
    List<String>? includeItemTypes,
    int? limit,
    String? fields,
  }) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getLatestItems({
    String? parentId,
    List<String>? includeItemTypes,
    int? limit,
    String? fields,
  }) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getSeasons(String seriesId) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getEpisodes(
    String seriesId, {
    String? seasonId,
    String? fields,
  }) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getThemeMedia(
    String itemId, {
    bool inheritFromParent = true,
  }) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getPlaylists() => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getArtists({
    String? parentId,
    String? userId,
    String? sortBy,
    String? sortOrder,
    int? startIndex,
    int? limit,
    bool? recursive,
    String? fields,
    String? nameStartsWith,
    String? nameLessThan,
    bool? isFavorite,
  }) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getAlbumArtists({
    String? parentId,
    String? userId,
    String? sortBy,
    String? sortOrder,
    int? startIndex,
    int? limit,
    bool? recursive,
    String? fields,
    String? nameStartsWith,
    String? nameLessThan,
    bool? isFavorite,
  }) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getPlaylistItems(String playlistId) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> createPlaylist({
    required String name,
    List<String>? itemIds,
  }) => throw UnimplementedError();

  @override
  Future<void> addToPlaylist(String playlistId, List<String> itemIds) =>
      throw UnimplementedError();

  @override
  Future<void> removeFromPlaylist(String playlistId, List<String> entryIds) =>
      throw UnimplementedError();

  @override
  Future<void> movePlaylistItem(
    String playlistId,
    String playlistItemId,
    int newIndex,
  ) => throw UnimplementedError();

  @override
  Future<void> renamePlaylist(String playlistId, String name) =>
      throw UnimplementedError();

  @override
  Future<void> deleteItem(String itemId) => throw UnimplementedError();

  @override
  Future<void> deletePlaylist(String playlistId) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getGenres({
    String? parentId,
    String? userId,
    String? sortBy,
    String? sortOrder,
    int? startIndex,
    int? limit,
    bool? recursive,
    String? fields,
    List<String>? includeItemTypes,
  }) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getLyrics(String itemId) =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> getLocalTrailers(String itemId) =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> getIntros(String itemId) =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> getSpecialFeatures(String itemId) =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> getMediaSegments(String itemId) =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> searchRemoteSubtitles(
    String itemId, {
    required String language,
    bool? isPerfectMatch,
  }) => throw UnimplementedError();

  @override
  Future<void> downloadRemoteSubtitle(String itemId, String subtitleId) =>
      throw UnimplementedError();
}

class _FakeDisplayPreferencesApi implements DisplayPreferencesApi {
  _FakeDisplayPreferencesApi({this.hang = false});

  final bool hang;
  final List<String> getCalls = <String>[];

  @override
  Future<DisplayPreferences> getDisplayPreferences(
    String id, {
    String? client,
  }) async {
    getCalls.add(id);
    if (hang) {
      return Completer<DisplayPreferences>().future;
    }
    return DisplayPreferences(id: id);
  }

  @override
  Future<void> saveDisplayPreferences(
    String id,
    DisplayPreferences prefs, {
    String? client,
  }) async {}
}

class _FakeUserViewsApi implements UserViewsApi {
  const _FakeUserViewsApi();

  @override
  Future<Map<String, dynamic>> getUserViews() async =>
      const {'Items': <Map<String, dynamic>>[]};
}

class _FakeImageApi implements ImageApi {
  const _FakeImageApi();

  @override
  String getPrimaryImageUrl(
    String itemId, {
    int? maxWidth,
    int? maxHeight,
    String? tag,
  }) => '';

  @override
  String getBackdropImageUrl(
    String itemId, {
    int? maxWidth,
    int? index,
    String? tag,
  }) => '';

  @override
  String getLogoImageUrl(String itemId, {int? maxWidth, String? tag}) => '';

  @override
  String getBannerImageUrl(String itemId, {int? maxWidth, String? tag}) => '';

  @override
  String getThumbImageUrl(String itemId, {int? maxWidth, String? tag}) => '';

  @override
  String getChapterImageUrl(
    String itemId, {
    required int index,
    int? maxWidth,
    String? tag,
  }) => '';

  @override
  String getUserImageUrl(String userId) => '';

  @override
  String getTrickplayTileImageUrl(
    String itemId, {
    required int width,
    required int index,
    String? mediaSourceId,
  }) => '';
}
