import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:server_core/server_core.dart' hide ImageType;

import '../../preference/user_preferences.dart';
import '../models/aggregated_item.dart';
import '../repositories/advanced_filter_catalog_repository.dart';
import '../services/advanced_filter_catalog_constants.dart';
import '../services/advanced_filter_perf_logger.dart';
import '../services/advanced_filter_catalog_sync_service.dart';

enum AdvancedFilterLoadState { loading, ready, error }

enum AdvancedFilterSortField { name, year }

class AdvancedFilterViewModel extends ChangeNotifier {
  static const movieType = AdvancedFilterCatalogConstants.movieType;
  static const seriesType = AdvancedFilterCatalogConstants.seriesType;
  static const _cacheVersion = 1;

  final MediaServerClient _client;
  final UserPreferences _prefs;
  final AdvancedFilterCatalogRepository _catalogRepository;
  final AdvancedFilterCatalogSyncService _catalogSyncService;
  final Duration _catalogMaxAge;
  final bool _ownsCatalogSyncService;
  StreamSubscription<void>? _catalogChangeSub;
  bool _disposed = false;
  int _perfTraceSequence = 0;
  int? _lastPerfTraceId;

  AdvancedFilterViewModel({
    required MediaServerClient client,
    required UserPreferences prefs,
    required AdvancedFilterCatalogRepository catalogRepository,
    AdvancedFilterCatalogSyncService? catalogSyncService,
    Duration catalogMaxAge =
        AdvancedFilterCatalogSyncService.defaultCacheMaxAge,
  }) : _client = client,
       _prefs = prefs,
       _catalogRepository = catalogRepository,
       _catalogSyncService =
           catalogSyncService ??
           AdvancedFilterCatalogSyncService(
             client: client,
             repository: catalogRepository,
             events: const Stream<ServerWebSocketMessage>.empty(),
           ),
       _ownsCatalogSyncService = catalogSyncService == null,
       _catalogMaxAge = catalogMaxAge {
    if (!_ownsCatalogSyncService) {
      _catalogChangeSub = _catalogSyncService.catalogChanged.listen((_) {
        unawaited(_reloadCatalogFromCacheAfterExternalChange());
      });
    }
  }

  AdvancedFilterLoadState _state = AdvancedFilterLoadState.loading;
  AdvancedFilterLoadState get state => _state;

  int? get lastPerfTraceId => _lastPerfTraceId;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _loadedItemCount = 0;
  int get loadedItemCount => _loadedItemCount;

  int? _totalItemCount;
  int? get totalItemCount => _totalItemCount;

  double? get loadingProgress {
    final total = _totalItemCount;
    if (total == null || total <= 0) return null;
    return (_loadedItemCount / total).clamp(0.0, 1.0);
  }

  bool _isRefreshingCatalog = false;
  bool get isRefreshingCatalog => _isRefreshingCatalog;

  DateTime? _catalogSyncedAt;
  DateTime? get catalogSyncedAt => _catalogSyncedAt;

  bool _hasApplied = false;
  bool get hasApplied => _hasApplied;

  List<String> _genres = const [];
  List<String> get genres => _genres;

  List<String> _regions = const [];
  List<String> get regions => _regions;

  List<String> _years = const [];
  List<String> get years => _years;

  List<AggregatedItem> _catalogItems = const [];
  List<AggregatedItem> _results = const [];
  List<AggregatedItem> get results => _results;

  Set<String> _selectedTypes = <String>{};
  Set<String> get selectedTypes => _selectedTypes;

  Set<String> _selectedGenres = <String>{};
  Set<String> get selectedGenres => _selectedGenres;

  Set<String> _selectedRegions = <String>{};
  Set<String> get selectedRegions => _selectedRegions;

  Set<String> _selectedYears = <String>{};
  Set<String> get selectedYears => _selectedYears;

  AdvancedFilterSortField _sortField = AdvancedFilterSortField.name;
  AdvancedFilterSortField get sortField => _sortField;

  bool _sortAscending = true;
  bool get sortAscending => _sortAscending;

  bool get hasActiveFilters =>
      _selectedTypes.isNotEmpty ||
      _selectedGenres.isNotEmpty ||
      _selectedRegions.isNotEmpty ||
      _selectedYears.isNotEmpty;

  String get _preferenceScopeKey {
    final userId = _client.userId?.trim();
    if (userId == null || userId.isEmpty) return _client.baseUrl;
    return '${_client.baseUrl}::$userId';
  }

  String get _catalogUserId => _client.userId?.trim() ?? '';

  int _startPerfTrace(String action) {
    final traceId = ++_perfTraceSequence;
    _lastPerfTraceId = traceId;
    _logPerf(
      traceId,
      '$action:start ${_stateSummary()} ${_selectionSummary()}',
    );
    return traceId;
  }

  void _logPerf(int traceId, String message) {
    AdvancedFilterPerfLogger.write(
      '[AdvancedFilterPerf][trace=$traceId] $message',
    );
  }

  String _stateSummary() {
    return 'state=${_state.name} catalog=${_catalogItems.length} '
        'results=${_results.length} genres=${_genres.length} '
        'regions=${_regions.length} years=${_years.length} '
        'sort=${_sortField.name}:${_sortAscending ? 'asc' : 'desc'}';
  }

  String _selectionSummary() {
    return 'selectedTypes=${_selectedTypes.length} '
        'selectedGenres=${_selectedGenres.length} '
        'selectedRegions=${_selectedRegions.length} '
        'selectedYears=${_selectedYears.length}';
  }

  Future<void> load() async {
    final traceId = _startPerfTrace('load');
    unawaited(
      AdvancedFilterPerfLogger.getLogPath().then(
        (path) => _logPerf(traceId, 'logPath=$path'),
      ),
    );
    _state = AdvancedFilterLoadState.loading;
    _errorMessage = null;
    _loadedItemCount = 0;
    _totalItemCount = null;
    notifyListeners();

    try {
      final restoreWatch = Stopwatch()..start();
      _restoreSelections();
      restoreWatch.stop();
      _logPerf(
        traceId,
        'load:restoreSelections ms=${restoreWatch.elapsedMilliseconds} '
        '${_selectionSummary()}',
      );

      final cacheWatch = Stopwatch()..start();
      final cachedSnapshot = await _loadCachedCatalogSnapshot();
      cacheWatch.stop();
      _logPerf(
        traceId,
        'load:cacheLookup ms=${cacheWatch.elapsedMilliseconds} '
        'hit=${cachedSnapshot != null} '
        'items=${cachedSnapshot?.items.length ?? 0} '
        'syncedAt=${cachedSnapshot?.syncedAt?.toIso8601String()}',
      );
      if (cachedSnapshot != null) {
        _catalogSyncedAt = cachedSnapshot.syncedAt;
        _useCatalogItems(
          cachedSnapshot.items,
          reason: 'load-cache',
          traceId: traceId,
        );
        _state = AdvancedFilterLoadState.ready;
        notifyListeners();
        if (_catalogRepository.isExpired(
          cachedSnapshot,
          maxAge: _catalogMaxAge,
        )) {
          _logPerf(
            traceId,
            'load:cacheExpired schedulingBackgroundRefresh=true',
          );
          unawaited(_refreshCatalogFromServer(background: true));
        }
        _logPerf(traceId, 'load:readyFromCache ${_stateSummary()}');
        return;
      }

      await _refreshCatalogFromServer(background: false);
    } catch (error) {
      _logPerf(traceId, 'load:error $error');
      _errorMessage = error.toString();
      _state = AdvancedFilterLoadState.error;
      notifyListeners();
    }
  }

  Future<void> refreshCatalog() async {
    final traceId = _startPerfTrace('manualRefreshCatalog');
    _logPerf(traceId, 'manualRefreshCatalog:requested');
    await _refreshCatalogFromServer(background: _catalogItems.isNotEmpty);
  }

  Future<void> toggleType(String value) =>
      _updateFilters('toggleType', value, () => _toggle(_selectedTypes, value));

  Future<void> toggleGenre(String value) => _updateFilters(
    'toggleGenre',
    value,
    () => _toggle(_selectedGenres, value),
  );

  Future<void> toggleRegion(String value) => _updateFilters(
    'toggleRegion',
    value,
    () => _toggle(_selectedRegions, value),
  );

  Future<void> toggleYear(String value) =>
      _updateFilters('toggleYear', value, () => _toggle(_selectedYears, value));

  Future<void> clearTypes() =>
      _updateFilters('clearTypes', 'all', _selectedTypes.clear);

  Future<void> clearGenres() =>
      _updateFilters('clearGenres', 'all', _selectedGenres.clear);

  Future<void> clearRegions() =>
      _updateFilters('clearRegions', 'all', _selectedRegions.clear);

  Future<void> clearYears() =>
      _updateFilters('clearYears', 'all', _selectedYears.clear);

  Future<void> setSortField(AdvancedFilterSortField field) async {
    if (_sortField == field) return;
    final traceId = _startPerfTrace('setSortField:${field.name}');
    _sortField = field;
    _results = _sortItems(_results, reason: 'setSortField', traceId: traceId);
    notifyListeners();
    _logPerf(
      traceId,
      'setSortField:notifyListeners results=${_results.length}',
    );
    final persistWatch = Stopwatch()..start();
    await _persistSort();
    persistWatch.stop();
    _logPerf(
      traceId,
      'setSortField:persistSort ms=${persistWatch.elapsedMilliseconds}',
    );
  }

  Future<void> toggleSortDirection() async {
    final traceId = _startPerfTrace('toggleSortDirection');
    _sortAscending = !_sortAscending;
    _results = _sortItems(
      _results,
      reason: 'toggleSortDirection',
      traceId: traceId,
    );
    notifyListeners();
    _logPerf(
      traceId,
      'toggleSortDirection:notifyListeners results=${_results.length}',
    );
    final persistWatch = Stopwatch()..start();
    await _persistSort();
    persistWatch.stop();
    _logPerf(
      traceId,
      'toggleSortDirection:persistSort ms=${persistWatch.elapsedMilliseconds}',
    );
  }

  Future<void> clearAll() async {
    final traceId = _startPerfTrace('clearAll');
    _selectedTypes = <String>{};
    _selectedGenres = <String>{};
    _selectedRegions = <String>{};
    _selectedYears = <String>{};
    _results = _filterItems(reason: 'clearAll', traceId: traceId);
    _hasApplied = true;
    _logPerf(traceId, 'clearAll:filterDone results=${_results.length}');
    final persistWatch = Stopwatch()..start();
    await _persistSelections(applied: true);
    persistWatch.stop();
    _logPerf(
      traceId,
      'clearAll:persistSelections ms=${persistWatch.elapsedMilliseconds}',
    );
    notifyListeners();
    _logPerf(traceId, 'clearAll:notifyListeners');
  }

  String? imageUrl(AggregatedItem item) {
    final primaryTag = item.primaryImageTag ?? item.primaryImageTagField;
    final primaryId = item.primaryImageItemId ?? item.id;
    if (primaryTag != null && primaryTag.isNotEmpty) {
      return _client.imageApi.getPrimaryImageUrl(
        primaryId,
        maxHeight: 500,
        tag: primaryTag,
      );
    }

    if (item.seriesId != null && item.seriesPrimaryImageTag != null) {
      return _client.imageApi.getPrimaryImageUrl(
        item.seriesId!,
        maxHeight: 500,
        tag: item.seriesPrimaryImageTag,
      );
    }

    return null;
  }

  void _restoreSelections() {
    _selectedTypes = _prefs
        .get(UserPreferences.advancedFilterTypes(_preferenceScopeKey))
        .where(_validType)
        .toSet();
    _selectedGenres = _prefs
        .get(UserPreferences.advancedFilterGenres(_preferenceScopeKey))
        .toSet();
    _selectedRegions = _prefs
        .get(UserPreferences.advancedFilterRegions(_preferenceScopeKey))
        .toSet();
    _selectedYears = _prefs
        .get(UserPreferences.advancedFilterYears(_preferenceScopeKey))
        .toSet();
    _sortField = _normalizeSortField(
      _prefs.get(UserPreferences.advancedFilterSortField(_preferenceScopeKey)),
    );
    _sortAscending = _prefs.get(
      UserPreferences.advancedFilterSortAscending(_preferenceScopeKey),
    );
    _hasApplied = _prefs.get(
      UserPreferences.advancedFilterApplied(_preferenceScopeKey),
    );
  }

  Future<void> _persistSelections({required bool applied}) async {
    final orderedTypes = _selectedTypes.toList()..sort(_typeSort);
    final orderedGenres = _selectedGenres.toList()..sort(_compareText);
    final orderedRegions = _selectedRegions.toList()..sort(_compareText);
    final orderedYears = _selectedYears.toList()
      ..sort((a, b) => b.compareTo(a));

    await Future.wait([
      _prefs.set(
        UserPreferences.advancedFilterTypes(_preferenceScopeKey),
        orderedTypes,
      ),
      _prefs.set(
        UserPreferences.advancedFilterGenres(_preferenceScopeKey),
        orderedGenres,
      ),
      _prefs.set(
        UserPreferences.advancedFilterRegions(_preferenceScopeKey),
        orderedRegions,
      ),
      _prefs.set(
        UserPreferences.advancedFilterYears(_preferenceScopeKey),
        orderedYears,
      ),
      _prefs.set(
        UserPreferences.advancedFilterApplied(_preferenceScopeKey),
        applied,
      ),
    ]);
  }

  Future<void> _persistSort() async {
    await Future.wait([
      _prefs.set(
        UserPreferences.advancedFilterSortField(_preferenceScopeKey),
        _sortField.name,
      ),
      _prefs.set(
        UserPreferences.advancedFilterSortAscending(_preferenceScopeKey),
        _sortAscending,
      ),
    ]);
  }

  Future<void> _refreshCatalogFromServer({required bool background}) async {
    if (_disposed || _isRefreshingCatalog) return;
    final traceId = _startPerfTrace(
      background ? 'refreshCatalogBackground' : 'refreshCatalogForeground',
    );

    _isRefreshingCatalog = true;
    _loadedItemCount = 0;
    _totalItemCount = null;
    if (!background) {
      _state = AdvancedFilterLoadState.loading;
    }
    notifyListeners();
    _logPerf(
      traceId,
      'refreshCatalog:notifyLoading background=$background ${_stateSummary()}',
    );

    try {
      final refreshWatch = Stopwatch()..start();
      final items = await _catalogSyncService.refreshCatalog(
        onProgress: _setLoadProgress,
      );
      refreshWatch.stop();
      _logPerf(
        traceId,
        'refreshCatalog:serverAndCache ms=${refreshWatch.elapsedMilliseconds} '
        'items=${items.length}',
      );
      _catalogSyncedAt = DateTime.now().toUtc();
      _useCatalogItems(
        items,
        reason: background ? 'refresh-background' : 'refresh-foreground',
        traceId: traceId,
      );
      _state = AdvancedFilterLoadState.ready;
      _errorMessage = null;
    } catch (error) {
      _logPerf(traceId, 'refreshCatalog:error $error');
      _errorMessage = error.toString();
      if (!background || _catalogItems.isEmpty) {
        _state = AdvancedFilterLoadState.error;
      }
    } finally {
      _isRefreshingCatalog = false;
      if (!_disposed) notifyListeners();
      _logPerf(traceId, 'refreshCatalog:done ${_stateSummary()}');
    }
  }

  void _setLoadProgress(int loaded, int? total) {
    if (_disposed) return;
    _loadedItemCount = loaded;
    _totalItemCount = total;
    final traceId = _lastPerfTraceId ?? 0;
    _logPerf(traceId, 'refreshCatalog:progress loaded=$loaded total=$total');
    notifyListeners();
  }

  void _useCatalogItems(
    List<AggregatedItem> items, {
    required String reason,
    required int traceId,
  }) {
    final totalWatch = Stopwatch()..start();
    _catalogItems = items;
    final genresWatch = Stopwatch()..start();
    _genres = _collectGenres(items);
    genresWatch.stop();
    final regionsWatch = Stopwatch()..start();
    _regions = _collectRegions(items);
    regionsWatch.stop();
    final yearsWatch = Stopwatch()..start();
    _years = _collectYears(items);
    yearsWatch.stop();
    final dropWatch = Stopwatch()..start();
    _dropUnavailableSelections();
    dropWatch.stop();
    _hasApplied = true;
    _results = _filterItems(
      reason: '$reason-useCatalogItems',
      traceId: traceId,
    );
    totalWatch.stop();
    _logPerf(
      traceId,
      'useCatalogItems:$reason totalMs=${totalWatch.elapsedMilliseconds} '
      'items=${items.length} genres=${_genres.length} '
      'regions=${_regions.length} years=${_years.length} '
      'collectGenresMs=${genresWatch.elapsedMilliseconds} '
      'collectRegionsMs=${regionsWatch.elapsedMilliseconds} '
      'collectYearsMs=${yearsWatch.elapsedMilliseconds} '
      'dropUnavailableMs=${dropWatch.elapsedMilliseconds} '
      'results=${_results.length}',
    );
  }

  Future<void> _updateFilters(
    String action,
    String value,
    VoidCallback updateSelection,
  ) async {
    final traceId = _startPerfTrace('$action:$value');
    final totalWatch = Stopwatch()..start();
    final updateWatch = Stopwatch()..start();
    updateSelection();
    updateWatch.stop();
    _hasApplied = true;
    _logPerf(
      traceId,
      '$action:updateSelection value="$value" '
      'ms=${updateWatch.elapsedMilliseconds} ${_selectionSummary()}',
    );
    _results = _filterItems(reason: action, traceId: traceId);
    _logPerf(traceId, '$action:filterDone results=${_results.length}');
    final notifyWatch = Stopwatch()..start();
    notifyListeners();
    notifyWatch.stop();
    _logPerf(
      traceId,
      '$action:notifyListeners ms=${notifyWatch.elapsedMilliseconds}',
    );
    final persistWatch = Stopwatch()..start();
    await _persistSelections(applied: true);
    persistWatch.stop();
    totalWatch.stop();
    _logPerf(
      traceId,
      '$action:persistSelections ms=${persistWatch.elapsedMilliseconds} '
      'totalMethodMs=${totalWatch.elapsedMilliseconds}',
    );
  }

  Future<AdvancedFilterCatalogSnapshot?> _loadCachedCatalogSnapshot() async {
    final snapshot = await _catalogRepository.loadSnapshot(
      serverId: _client.baseUrl,
      userId: _catalogUserId,
    );
    if (snapshot != null) return snapshot;

    final legacyItems = _loadLegacyCachedCatalogItems();
    if (legacyItems != null) {
      unawaited(_saveCatalogCache(legacyItems));
      return AdvancedFilterCatalogSnapshot(
        items: legacyItems,
        syncedAt: null,
        itemCount: legacyItems.length,
      );
    }
    return null;
  }

  List<AggregatedItem>? _loadLegacyCachedCatalogItems() {
    final raw = _prefs.get(
      UserPreferences.advancedFilterCache(_preferenceScopeKey),
    );
    if (raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['version'] != _cacheVersion) return null;
      final rawItems = decoded['items'];
      if (rawItems is! List) return null;

      final items = <AggregatedItem>[];
      for (final rawItem in rawItems) {
        if (rawItem is! Map) continue;
        final data = Map<String, dynamic>.from(rawItem);
        final id = data['Id'] as String?;
        if (id == null || id.isEmpty) continue;
        items.add(
          AggregatedItem(
            id: id,
            serverId: data['ServerId'] as String? ?? _client.baseUrl,
            rawData: data,
          ),
        );
      }
      items.sort((a, b) => _compareText(a.name, b.name));
      return items;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCatalogCache(List<AggregatedItem> items) async {
    try {
      await _catalogRepository.replaceScope(
        serverId: _client.baseUrl,
        userId: _catalogUserId,
        items: items,
      );
    } catch (_) {
      // A cache write failure should not block filtering or navigation.
    }
  }

  Future<void> _reloadCatalogFromCacheAfterExternalChange() async {
    if (_disposed || _state != AdvancedFilterLoadState.ready) return;
    final traceId = _startPerfTrace('externalCatalogChange');

    final loadWatch = Stopwatch()..start();
    final snapshot = await _catalogRepository.loadSnapshot(
      serverId: _client.baseUrl,
      userId: _catalogUserId,
    );
    loadWatch.stop();
    if (_disposed || snapshot == null) return;
    _logPerf(
      traceId,
      'externalCatalogChange:loadSnapshot ms=${loadWatch.elapsedMilliseconds} '
      'items=${snapshot.items.length} syncedAt=${snapshot.syncedAt?.toIso8601String()}',
    );

    _catalogSyncedAt = snapshot.syncedAt;
    _useCatalogItems(
      snapshot.items,
      reason: 'external-catalog-change',
      traceId: traceId,
    );
    notifyListeners();
    _logPerf(traceId, 'externalCatalogChange:notifyListeners');
  }

  List<AggregatedItem> _filterItems({
    required String reason,
    required int traceId,
  }) {
    final scanWatch = Stopwatch()..start();
    var typePassed = 0;
    var genrePassed = 0;
    var regionPassed = 0;
    var yearPassed = 0;
    final filtered = <AggregatedItem>[];

    for (final item in _catalogItems) {
      final type = item.type;
      final matchesType =
          _selectedTypes.isEmpty ||
          (type != null && _selectedTypes.contains(type));
      if (!matchesType) continue;
      typePassed++;

      final matchesGenre =
          _selectedGenres.isEmpty ||
          item.genres.any((genre) => _selectedGenres.contains(genre));
      if (!matchesGenre) continue;
      genrePassed++;

      final matchesRegion =
          _selectedRegions.isEmpty ||
          item.productionLocations.any(
            (region) => _selectedRegions.contains(region),
          );
      if (!matchesRegion) continue;
      regionPassed++;

      final year = item.productionYear?.toString();
      final matchesYear =
          _selectedYears.isEmpty ||
          (year != null && _selectedYears.contains(year));
      if (!matchesYear) continue;
      yearPassed++;
      filtered.add(item);
    }
    scanWatch.stop();
    _logPerf(
      traceId,
      'filter:$reason scanMs=${scanWatch.elapsedMilliseconds} '
      'catalog=${_catalogItems.length} typePassed=$typePassed '
      'genrePassed=$genrePassed regionPassed=$regionPassed '
      'yearPassed=$yearPassed selectedTypes=${_selectedTypes.length} '
      'selectedGenres=${_selectedGenres.length} '
      'selectedRegions=${_selectedRegions.length} '
      'selectedYears=${_selectedYears.length}',
    );

    return _sortItems(filtered, reason: '$reason-filter', traceId: traceId);
  }

  List<AggregatedItem> _sortItems(
    List<AggregatedItem> items, {
    required String reason,
    required int traceId,
  }) {
    final copyWatch = Stopwatch()..start();
    final sorted = items.toList();
    copyWatch.stop();
    final sortWatch = Stopwatch()..start();
    sorted.sort((a, b) {
      return switch (_sortField) {
        AdvancedFilterSortField.name =>
          _sortAscending
              ? _compareText(a.name, b.name)
              : _compareText(b.name, a.name),
        AdvancedFilterSortField.year => _compareByYear(a, b),
      };
    });
    sortWatch.stop();
    _logPerf(
      traceId,
      'sort:$reason copyMs=${copyWatch.elapsedMilliseconds} '
      'sortMs=${sortWatch.elapsedMilliseconds} items=${items.length} '
      'field=${_sortField.name} direction=${_sortAscending ? 'asc' : 'desc'}',
    );
    return sorted;
  }

  void _dropUnavailableSelections() {
    _selectedTypes.removeWhere((type) => !_validType(type));
    _selectedGenres.removeWhere((genre) => !_genres.contains(genre));
    _selectedRegions.removeWhere((region) => !_regions.contains(region));
    _selectedYears.removeWhere((year) => !_years.contains(year));
  }

  List<String> _collectGenres(List<AggregatedItem> items) {
    final values = <String>{};
    for (final item in items) {
      for (final genre in item.genres) {
        final normalized = genre.trim();
        if (normalized.isNotEmpty) values.add(normalized);
      }
    }
    return values.toList()..sort(_compareText);
  }

  List<String> _collectRegions(List<AggregatedItem> items) {
    final values = <String>{};
    for (final item in items) {
      for (final region in item.productionLocations) {
        final normalized = region.trim();
        if (normalized.isNotEmpty) values.add(normalized);
      }
    }
    return values.toList()..sort(_compareText);
  }

  List<String> _collectYears(List<AggregatedItem> items) {
    final values = <String>{};
    for (final item in items) {
      final year = item.productionYear;
      if (year != null && year > 0) {
        values.add(year.toString());
      }
    }
    return values.toList()..sort((a, b) => b.compareTo(a));
  }

  void _toggle(Set<String> values, String value) {
    if (values.contains(value)) {
      values.remove(value);
    } else {
      values.add(value);
    }
  }

  bool _validType(String value) => value == movieType || value == seriesType;

  AdvancedFilterSortField _normalizeSortField(String value) {
    for (final field in AdvancedFilterSortField.values) {
      if (field.name == value) return field;
    }
    return AdvancedFilterSortField.name;
  }

  int _typeSort(String a, String b) {
    const order = {movieType: 0, seriesType: 1};
    return (order[a] ?? 99).compareTo(order[b] ?? 99);
  }

  int _compareByYear(AggregatedItem a, AggregatedItem b) {
    final yearA = a.productionYear;
    final yearB = b.productionYear;
    if (yearA == null && yearB == null) return _compareText(a.name, b.name);
    if (yearA == null) return 1;
    if (yearB == null) return -1;
    final yearComparison = _sortAscending
        ? yearA.compareTo(yearB)
        : yearB.compareTo(yearA);
    if (yearComparison != 0) return yearComparison;
    return _compareText(a.name, b.name);
  }

  static int _compareText(String a, String b) {
    final lower = a.toLowerCase().compareTo(b.toLowerCase());
    if (lower != 0) return lower;
    return a.compareTo(b);
  }

  @override
  void dispose() {
    _disposed = true;
    _catalogChangeSub?.cancel();
    _catalogChangeSub = null;
    if (_ownsCatalogSyncService) {
      _catalogSyncService.dispose();
    }
    super.dispose();
  }
}
