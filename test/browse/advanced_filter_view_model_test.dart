import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';
import 'package:server_core/server_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moonfin/data/database/offline_database.dart';
import 'package:moonfin/data/models/aggregated_item.dart';
import 'package:moonfin/data/repositories/advanced_filter_catalog_repository.dart';
import 'package:moonfin/data/services/advanced_filter_catalog_sync_service.dart';
import 'package:moonfin/data/viewmodels/advanced_filter_view_model.dart';
import 'package:moonfin/preference/user_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const serverUrl = 'https://example.test';

  Future<UserPreferences> createPreferences() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = PreferenceStore();
    await store.init();
    return UserPreferences(store);
  }

  AdvancedFilterCatalogRepository createCatalogRepository() {
    final db = OfflineDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    return AdvancedFilterCatalogRepository(db);
  }

  test('loads dynamic filter options and restores persisted results', () async {
    final prefs = await createPreferences();
    final catalogRepository = createCatalogRepository();
    await prefs.set(UserPreferences.advancedFilterTypes(serverUrl), const [
      'Movie',
    ]);
    await prefs.set(UserPreferences.advancedFilterGenres(serverUrl), const [
      'Science Fiction',
    ]);
    await prefs.set(UserPreferences.advancedFilterRegions(serverUrl), const [
      'United States',
    ]);
    await prefs.set(UserPreferences.advancedFilterYears(serverUrl), const [
      '2024',
    ]);
    await prefs.set(UserPreferences.advancedFilterApplied(serverUrl), true);

    final vm = AdvancedFilterViewModel(
      client: _FakeMediaServerClient(
        itemsApi: _FakeItemsApi(items: _items),
        baseUrl: serverUrl,
      ),
      prefs: prefs,
      catalogRepository: catalogRepository,
    );

    await vm.load();

    expect(vm.state, AdvancedFilterLoadState.ready);
    expect(vm.genres, const ['Adventure', 'Drama', 'Science Fiction']);
    expect(vm.regions, const ['France', 'United States']);
    expect(vm.years, const ['2024', '2023']);
    expect(vm.results.map((item) => item.name), const ['Alpha']);
  });

  test('loads all movies and series by default', () async {
    final prefs = await createPreferences();
    final catalogRepository = createCatalogRepository();
    final vm = AdvancedFilterViewModel(
      client: _FakeMediaServerClient(
        itemsApi: _FakeItemsApi(items: _items),
        baseUrl: serverUrl,
      ),
      prefs: prefs,
      catalogRepository: catalogRepository,
    );

    await vm.load();

    expect(vm.hasApplied, true);
    expect(vm.hasActiveFilters, false);
    expect(vm.results.map((item) => item.name), const [
      'Alpha',
      'Beta',
      'Delta',
      'Gamma',
    ]);
  });

  test(
    'filters immediately with multi-value rows requiring all selections',
    () async {
      final prefs = await createPreferences();
      final catalogRepository = createCatalogRepository();
      final vm = AdvancedFilterViewModel(
        client: _FakeMediaServerClient(
          itemsApi: _FakeItemsApi(items: _items),
          baseUrl: serverUrl,
        ),
        prefs: prefs,
        catalogRepository: catalogRepository,
      );

      await vm.load();
      await vm.toggleType('Movie');
      await vm.toggleType('Series');
      await vm.toggleGenre('Science Fiction');
      await vm.toggleGenre('Adventure');
      await vm.toggleRegion('France');
      await vm.toggleYear('2024');

      expect(vm.results.map((item) => item.name), const ['Delta']);
      expect(vm.hasActiveFilters, true);
      expect(prefs.get(UserPreferences.advancedFilterTypes(serverUrl)), const [
        'Movie',
        'Series',
      ]);
      expect(prefs.get(UserPreferences.advancedFilterApplied(serverUrl)), true);
    },
  );

  test('sorts results by name or year in either direction', () async {
    final prefs = await createPreferences();
    final catalogRepository = createCatalogRepository();
    final vm = AdvancedFilterViewModel(
      client: _FakeMediaServerClient(
        itemsApi: _FakeItemsApi(items: _items),
        baseUrl: serverUrl,
      ),
      prefs: prefs,
      catalogRepository: catalogRepository,
    );

    await vm.load();

    expect(vm.sortField, AdvancedFilterSortField.name);
    expect(vm.sortAscending, true);
    expect(vm.results.map((item) => item.name), const [
      'Alpha',
      'Beta',
      'Delta',
      'Gamma',
    ]);

    await vm.setSortField(AdvancedFilterSortField.year);

    expect(vm.results.map((item) => item.name), const [
      'Beta',
      'Alpha',
      'Delta',
      'Gamma',
    ]);

    await vm.toggleSortDirection();

    expect(vm.results.map((item) => item.name), const [
      'Alpha',
      'Delta',
      'Gamma',
      'Beta',
    ]);
    expect(
      prefs.get(UserPreferences.advancedFilterSortField(serverUrl)),
      'year',
    );
    expect(
      prefs.get(UserPreferences.advancedFilterSortAscending(serverUrl)),
      false,
    );

    await vm.setSortField(AdvancedFilterSortField.name);

    expect(vm.results.map((item) => item.name), const [
      'Gamma',
      'Delta',
      'Beta',
      'Alpha',
    ]);
  });

  test('restores persisted sort settings', () async {
    final prefs = await createPreferences();
    final catalogRepository = createCatalogRepository();
    await prefs.set(
      UserPreferences.advancedFilterSortField(serverUrl),
      AdvancedFilterSortField.year.name,
    );
    await prefs.set(
      UserPreferences.advancedFilterSortAscending(serverUrl),
      false,
    );

    final vm = AdvancedFilterViewModel(
      client: _FakeMediaServerClient(
        itemsApi: _FakeItemsApi(items: _items),
        baseUrl: serverUrl,
      ),
      prefs: prefs,
      catalogRepository: catalogRepository,
    );

    await vm.load();

    expect(vm.sortField, AdvancedFilterSortField.year);
    expect(vm.sortAscending, false);
    expect(vm.results.map((item) => item.name), const [
      'Alpha',
      'Delta',
      'Gamma',
      'Beta',
    ]);
  });

  test('clearAll resets persisted filter state', () async {
    final prefs = await createPreferences();
    final catalogRepository = createCatalogRepository();
    final vm = AdvancedFilterViewModel(
      client: _FakeMediaServerClient(
        itemsApi: _FakeItemsApi(items: _items),
        baseUrl: serverUrl,
      ),
      prefs: prefs,
      catalogRepository: catalogRepository,
    );

    await vm.load();
    await vm.toggleType('Movie');
    await vm.toggleGenre('Drama');
    await vm.clearAll();

    expect(vm.hasApplied, true);
    expect(vm.hasActiveFilters, false);
    expect(vm.results.map((item) => item.name), const [
      'Alpha',
      'Beta',
      'Delta',
      'Gamma',
    ]);
    expect(prefs.get(UserPreferences.advancedFilterTypes(serverUrl)), isEmpty);
    expect(prefs.get(UserPreferences.advancedFilterGenres(serverUrl)), isEmpty);
    expect(prefs.get(UserPreferences.advancedFilterApplied(serverUrl)), true);
  });

  test('uses local catalog cache on subsequent loads', () async {
    final prefs = await createPreferences();
    final catalogRepository = createCatalogRepository();
    final firstApi = _FakeItemsApi(items: _items);
    final firstVm = AdvancedFilterViewModel(
      client: _FakeMediaServerClient(itemsApi: firstApi, baseUrl: serverUrl),
      prefs: prefs,
      catalogRepository: catalogRepository,
    );

    await firstVm.load();
    await _waitForCatalogCache(catalogRepository, serverUrl, '');

    expect(firstApi.getItemsCalls, 1);

    final secondApi = _FakeItemsApi(items: const []);
    final secondVm = AdvancedFilterViewModel(
      client: _FakeMediaServerClient(itemsApi: secondApi, baseUrl: serverUrl),
      prefs: prefs,
      catalogRepository: catalogRepository,
    );

    await secondVm.load();

    expect(secondApi.getItemsCalls, 0);
    expect(secondVm.genres, const ['Adventure', 'Drama', 'Science Fiction']);
    expect(secondVm.regions, const ['France', 'United States']);
  });

  test('isolates catalog cache and selections per server user', () async {
    final prefs = await createPreferences();
    final catalogRepository = createCatalogRepository();
    final firstUserApi = _FakeItemsApi(items: _items);
    final firstUserVm = AdvancedFilterViewModel(
      client: _FakeMediaServerClient(
        itemsApi: firstUserApi,
        baseUrl: serverUrl,
        userId: 'user-a',
      ),
      prefs: prefs,
      catalogRepository: catalogRepository,
    );

    await firstUserVm.load();
    await _waitForCatalogCache(catalogRepository, serverUrl, 'user-a');
    await firstUserVm.toggleGenre('Drama');

    expect(firstUserApi.getItemsCalls, 1);
    expect(
      prefs.get(UserPreferences.advancedFilterGenres('$serverUrl::user-a')),
      const ['Drama'],
    );
    expect(
      prefs.get(UserPreferences.advancedFilterGenres('$serverUrl::user-b')),
      isEmpty,
    );

    final secondUserApi = _FakeItemsApi(items: _secondUserItems);
    final secondUserVm = AdvancedFilterViewModel(
      client: _FakeMediaServerClient(
        itemsApi: secondUserApi,
        baseUrl: serverUrl,
        userId: 'user-b',
      ),
      prefs: prefs,
      catalogRepository: catalogRepository,
    );

    await secondUserVm.load();

    expect(secondUserApi.getItemsCalls, 1);
    expect(secondUserVm.selectedGenres, isEmpty);
    expect(secondUserVm.genres, const ['Comedy']);
    expect(secondUserVm.regions, const ['Japan']);
    expect(secondUserVm.years, const ['2025']);
    expect(secondUserVm.results.map((item) => item.name), const ['Omega']);

    final firstUserReloadApi = _FakeItemsApi(items: const []);
    final firstUserReloadVm = AdvancedFilterViewModel(
      client: _FakeMediaServerClient(
        itemsApi: firstUserReloadApi,
        baseUrl: serverUrl,
        userId: 'user-a',
      ),
      prefs: prefs,
      catalogRepository: catalogRepository,
    );

    await firstUserReloadVm.load();

    expect(firstUserReloadApi.getItemsCalls, 0);
    expect(firstUserReloadVm.selectedGenres, const {'Drama'});
    expect(firstUserReloadVm.genres, const [
      'Adventure',
      'Drama',
      'Science Fiction',
    ]);
    expect(firstUserReloadVm.results.map((item) => item.name), const ['Gamma']);
  });

  test(
    'loads an existing local catalog without requesting the server',
    () async {
      final prefs = await createPreferences();
      final catalogRepository = createCatalogRepository();
      await catalogRepository.replaceScope(
        serverId: serverUrl,
        userId: 'cached-user',
        items: _items
            .map(
              (raw) => AggregatedItem(
                id: raw['Id'] as String,
                serverId: serverUrl,
                rawData: raw,
              ),
            )
            .toList(),
      );

      final api = _FakeItemsApi(items: const []);
      final vm = AdvancedFilterViewModel(
        client: _FakeMediaServerClient(
          itemsApi: api,
          baseUrl: serverUrl,
          userId: 'cached-user',
        ),
        prefs: prefs,
        catalogRepository: catalogRepository,
      );

      await vm.load();

      expect(api.getItemsCalls, 0);
      expect(vm.state, AdvancedFilterLoadState.ready);
      expect(vm.results.map((item) => item.name), const [
        'Alpha',
        'Beta',
        'Delta',
        'Gamma',
      ]);
    },
  );

  test(
    'clears all legacy shared preferences catalogs after loading local cache',
    () async {
      final prefs = await createPreferences();
      final catalogRepository = createCatalogRepository();
      await catalogRepository.replaceScope(
        serverId: serverUrl,
        userId: 'cached-user',
        items: _items
            .map(
              (raw) => AggregatedItem(
                id: raw['Id'] as String,
                serverId: serverUrl,
                rawData: raw,
              ),
            )
            .toList(),
      );
      await prefs.set(
        UserPreferences.advancedFilterCache('$serverUrl::cached-user'),
        jsonEncode({'version': 1, 'items': _items}),
      );
      await prefs.set(
        UserPreferences.advancedFilterCache(serverUrl),
        jsonEncode({'version': 1, 'items': _secondUserItems}),
      );
      await prefs.set(
        UserPreferences.advancedFilterCache('$serverUrl::other-user'),
        jsonEncode({'version': 1, 'items': _updatedItems}),
      );

      final api = _FakeItemsApi(items: const []);
      final vm = AdvancedFilterViewModel(
        client: _FakeMediaServerClient(
          itemsApi: api,
          baseUrl: serverUrl,
          userId: 'cached-user',
        ),
        prefs: prefs,
        catalogRepository: catalogRepository,
      );

      await vm.load();

      expect(api.getItemsCalls, 0);
      expect(
        prefs.get(
          UserPreferences.advancedFilterCache('$serverUrl::cached-user'),
        ),
        isEmpty,
      );
      expect(
        prefs.get(UserPreferences.advancedFilterCache(serverUrl)),
        isEmpty,
      );
      expect(
        prefs.get(
          UserPreferences.advancedFilterCache('$serverUrl::other-user'),
        ),
        isEmpty,
      );
    },
  );

  test('manual refresh rebuilds the local catalog cache', () async {
    final prefs = await createPreferences();
    final catalogRepository = createCatalogRepository();
    final api = _FakeItemsApi(items: _items);
    final vm = AdvancedFilterViewModel(
      client: _FakeMediaServerClient(itemsApi: api, baseUrl: serverUrl),
      prefs: prefs,
      catalogRepository: catalogRepository,
    );

    await vm.load();
    await _waitForCatalogCache(catalogRepository, serverUrl, '');

    expect(api.getItemsCalls, 1);

    api.items = _secondUserItems;
    await vm.refreshCatalog();

    final snapshot = await catalogRepository.loadSnapshot(
      serverId: serverUrl,
      userId: '',
    );
    expect(api.getItemsCalls, 2);
    expect(vm.results.map((item) => item.name), const ['Omega']);
    expect(snapshot?.items.map((item) => item.name), const ['Omega']);
  });

  test(
    'stale catalog loads immediately and refreshes in the background',
    () async {
      final prefs = await createPreferences();
      final catalogRepository = createCatalogRepository();
      await catalogRepository.replaceScope(
        serverId: serverUrl,
        userId: 'stale-user',
        syncedAt: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
        items: _items
            .map(
              (raw) => AggregatedItem(
                id: raw['Id'] as String,
                serverId: serverUrl,
                rawData: raw,
              ),
            )
            .toList(),
      );

      final api = _FakeItemsApi(
        items: _secondUserItems,
        delay: const Duration(milliseconds: 20),
      );
      final vm = AdvancedFilterViewModel(
        client: _FakeMediaServerClient(
          itemsApi: api,
          baseUrl: serverUrl,
          userId: 'stale-user',
        ),
        prefs: prefs,
        catalogRepository: catalogRepository,
        catalogMaxAge: Duration.zero,
      );

      await vm.load();

      expect(vm.state, AdvancedFilterLoadState.ready);
      expect(vm.results.map((item) => item.name), const [
        'Alpha',
        'Beta',
        'Delta',
        'Gamma',
      ]);

      await _waitForCatalogNames(catalogRepository, serverUrl, 'stale-user', [
        'Omega',
      ]);
      await _waitForViewModelNames(vm, ['Omega']);

      expect(api.getItemsCalls, 1);
      expect(vm.results.map((item) => item.name), const ['Omega']);
    },
  );

  test(
    'websocket library changes incrementally update cache and open view model',
    () async {
      final prefs = await createPreferences();
      final catalogRepository = createCatalogRepository();
      await catalogRepository.replaceScope(
        serverId: serverUrl,
        userId: 'ws-user',
        items: _items
            .map(
              (raw) => AggregatedItem(
                id: raw['Id'] as String,
                serverId: serverUrl,
                rawData: raw,
              ),
            )
            .toList(),
      );

      final controller = StreamController<ServerWebSocketMessage>.broadcast();
      addTearDown(controller.close);
      final api = _FakeItemsApi(items: _updatedItems);
      final client = _FakeMediaServerClient(
        itemsApi: api,
        baseUrl: serverUrl,
        userId: 'ws-user',
      );
      final syncService = AdvancedFilterCatalogSyncService(
        client: client,
        repository: catalogRepository,
        events: controller.stream,
      )..start();
      addTearDown(syncService.dispose);
      final vm = AdvancedFilterViewModel(
        client: client,
        prefs: prefs,
        catalogRepository: catalogRepository,
        catalogSyncService: syncService,
      );

      await vm.load();

      controller.add(
        const LibraryChangedMessage(itemsUpdated: ['1'], itemsRemoved: ['2']),
      );

      await _waitForCatalogNames(catalogRepository, serverUrl, 'ws-user', [
        'Alpha Prime',
        'Delta',
        'Gamma',
      ]);
      await _waitForViewModelNames(vm, ['Alpha Prime', 'Delta', 'Gamma']);

      expect(api.getItemsCalls, 1);
      expect(vm.results.map((item) => item.name), const [
        'Alpha Prime',
        'Delta',
        'Gamma',
      ]);
    },
  );
}

Future<void> _waitForCatalogCache(
  AdvancedFilterCatalogRepository catalogRepository,
  String serverId,
  String userId,
) async {
  for (var i = 0; i < 10; i++) {
    final snapshot = await catalogRepository.loadSnapshot(
      serverId: serverId,
      userId: userId,
    );
    if (snapshot != null) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Expected advanced filter cache for $serverId / $userId');
}

Future<void> _waitForCatalogNames(
  AdvancedFilterCatalogRepository catalogRepository,
  String serverId,
  String userId,
  List<String> expectedNames,
) async {
  for (var i = 0; i < 30; i++) {
    final snapshot = await catalogRepository.loadSnapshot(
      serverId: serverId,
      userId: userId,
    );
    final names = snapshot?.items.map((item) => item.name).toList();
    if (_listEquals(names, expectedNames)) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  fail('Expected advanced filter catalog names $expectedNames');
}

Future<void> _waitForViewModelNames(
  AdvancedFilterViewModel vm,
  List<String> expectedNames,
) async {
  for (var i = 0; i < 30; i++) {
    final names = vm.results.map((item) => item.name).toList();
    if (_listEquals(names, expectedNames)) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  fail('Expected advanced filter view model names $expectedNames');
}

bool _listEquals(List<String>? left, List<String> right) {
  if (left == null || left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}

const _items = [
  {
    'Id': '1',
    'Name': 'Alpha',
    'Type': 'Movie',
    'ProductionYear': 2024,
    'Genres': ['Science Fiction'],
    'ProductionLocations': ['United States'],
    'UserData': <String, dynamic>{},
  },
  {
    'Id': '2',
    'Name': 'Beta',
    'Type': 'Series',
    'ProductionYear': 2023,
    'Genres': ['Science Fiction', 'Adventure'],
    'ProductionLocations': ['United States'],
    'UserData': <String, dynamic>{},
  },
  {
    'Id': '3',
    'Name': 'Gamma',
    'Type': 'Movie',
    'ProductionYear': 2024,
    'Genres': ['Drama'],
    'ProductionLocations': ['France'],
    'UserData': <String, dynamic>{},
  },
  {
    'Id': '4',
    'Name': 'Delta',
    'Type': 'Movie',
    'ProductionYear': 2024,
    'Genres': ['Science Fiction', 'Adventure'],
    'ProductionLocations': ['France'],
    'UserData': <String, dynamic>{},
  },
];

const _secondUserItems = [
  {
    'Id': '5',
    'Name': 'Omega',
    'Type': 'Movie',
    'ProductionYear': 2025,
    'Genres': ['Comedy'],
    'ProductionLocations': ['Japan'],
    'UserData': <String, dynamic>{},
  },
];

const _updatedItems = [
  {
    'Id': '1',
    'Name': 'Alpha Prime',
    'Type': 'Movie',
    'ProductionYear': 2026,
    'Genres': ['Science Fiction'],
    'ProductionLocations': ['United States'],
    'UserData': <String, dynamic>{},
  },
];

class _FakeMediaServerClient implements MediaServerClient {
  _FakeMediaServerClient({
    required this.itemsApi,
    required this.baseUrl,
    this.userId,
  });

  @override
  final ItemsApi itemsApi;

  @override
  String baseUrl;

  @override
  String? userId;

  @override
  ServerType get serverType => ServerType.emby;

  @override
  DeviceInfo get deviceInfo => const DeviceInfo(
    name: 'Test',
    id: 'test-device',
    appName: 'Moonfin Test',
    appVersion: '1.0.0',
  );

  @override
  ImageApi get imageApi => _FakeImageApi();

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeItemsApi implements ItemsApi {
  _FakeItemsApi({required this.items, this.delay = Duration.zero});

  List<Map<String, dynamic>> items;
  final Duration delay;
  int getItemsCalls = 0;

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
    getItemsCalls += 1;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    var source = items;
    if (ids != null && ids.isNotEmpty) {
      final idSet = ids.toSet();
      source = source
          .where((item) => idSet.contains(item['Id']))
          .toList(growable: false);
    }
    if (includeItemTypes != null && includeItemTypes.isNotEmpty) {
      final typeSet = includeItemTypes.toSet();
      source = source
          .where((item) => typeSet.contains(item['Type']))
          .toList(growable: false);
    }
    final start = startIndex ?? 0;
    final end = limit == null
        ? source.length
        : (start + limit).clamp(0, source.length).toInt();
    return {
      'Items': source.sublist(start, end),
      'TotalRecordCount': source.length,
    };
  }

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
  }) async {
    final names = <String>{};
    for (final item in items) {
      for (final genre in (item['Genres'] as List).cast<String>()) {
        names.add(genre);
      }
    }
    final sorted = names.toList()..sort();
    final start = startIndex ?? 0;
    final end = limit == null
        ? sorted.length
        : (start + limit).clamp(0, sorted.length);
    return {
      'Items': [
        for (final name in sorted.sublist(start, end))
          {'Id': name, 'Name': name},
      ],
      'TotalRecordCount': sorted.length,
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeImageApi implements ImageApi {
  @override
  String getPrimaryImageUrl(
    String itemId, {
    int? maxWidth,
    int? maxHeight,
    String? tag,
  }) => 'https://images.test/$itemId';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
