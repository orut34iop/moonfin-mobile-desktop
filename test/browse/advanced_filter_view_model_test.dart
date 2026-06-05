import 'package:flutter_test/flutter_test.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';
import 'package:server_core/server_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  test('loads dynamic filter options and restores persisted results', () async {
    final prefs = await createPreferences();
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
    );

    await vm.load();

    expect(vm.state, AdvancedFilterLoadState.ready);
    expect(vm.genres, const ['Drama', 'Science Fiction']);
    expect(vm.regions, const ['France', 'United States']);
    expect(vm.years, const ['2024', '2023']);
    expect(vm.results.map((item) => item.name), const ['Alpha']);
  });

  test('loads all movies and series by default', () async {
    final prefs = await createPreferences();
    final vm = AdvancedFilterViewModel(
      client: _FakeMediaServerClient(
        itemsApi: _FakeItemsApi(items: _items),
        baseUrl: serverUrl,
      ),
      prefs: prefs,
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

  test('filters immediately with row OR and row AND rules', () async {
    final prefs = await createPreferences();
    final vm = AdvancedFilterViewModel(
      client: _FakeMediaServerClient(
        itemsApi: _FakeItemsApi(items: _items),
        baseUrl: serverUrl,
      ),
      prefs: prefs,
    );

    await vm.load();
    await vm.toggleType('Movie');
    await vm.toggleType('Series');
    await vm.toggleGenre('Science Fiction');
    await vm.toggleRegion('France');
    await vm.toggleRegion('United States');
    await vm.toggleYear('2024');

    expect(vm.results.map((item) => item.name), const ['Alpha', 'Delta']);
    expect(vm.hasActiveFilters, true);
    expect(prefs.get(UserPreferences.advancedFilterTypes(serverUrl)), const [
      'Movie',
      'Series',
    ]);
    expect(prefs.get(UserPreferences.advancedFilterApplied(serverUrl)), true);
  });

  test('clearAll resets persisted filter state', () async {
    final prefs = await createPreferences();
    final vm = AdvancedFilterViewModel(
      client: _FakeMediaServerClient(
        itemsApi: _FakeItemsApi(items: _items),
        baseUrl: serverUrl,
      ),
      prefs: prefs,
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

  test('uses persisted catalog cache on subsequent loads', () async {
    final prefs = await createPreferences();
    final firstApi = _FakeItemsApi(items: _items);
    final firstVm = AdvancedFilterViewModel(
      client: _FakeMediaServerClient(itemsApi: firstApi, baseUrl: serverUrl),
      prefs: prefs,
    );

    await firstVm.load();
    for (var i = 0; i < 10; i++) {
      if (prefs
          .get(UserPreferences.advancedFilterCache(serverUrl))
          .isNotEmpty) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    expect(firstApi.getItemsCalls, 1);

    final secondApi = _FakeItemsApi(items: const []);
    final secondVm = AdvancedFilterViewModel(
      client: _FakeMediaServerClient(itemsApi: secondApi, baseUrl: serverUrl),
      prefs: prefs,
    );

    await secondVm.load();

    expect(secondApi.getItemsCalls, 0);
    expect(secondVm.genres, const ['Drama', 'Science Fiction']);
    expect(secondVm.regions, const ['France', 'United States']);
  });
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
    'Genres': ['Science Fiction'],
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
    'Genres': ['Science Fiction'],
    'ProductionLocations': ['France'],
    'UserData': <String, dynamic>{},
  },
];

class _FakeMediaServerClient implements MediaServerClient {
  _FakeMediaServerClient({required this.itemsApi, required this.baseUrl});

  @override
  final ItemsApi itemsApi;

  @override
  String baseUrl;

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
  _FakeItemsApi({required this.items});

  final List<Map<String, dynamic>> items;
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
    final start = startIndex ?? 0;
    final end = limit == null
        ? items.length
        : (start + limit).clamp(0, items.length);
    return {
      'Items': items.sublist(start, end),
      'TotalRecordCount': items.length,
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
