import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';
import 'package:server_core/server_core.dart' hide ImageType;

import '../../preference/user_preferences.dart';
import '../models/aggregated_item.dart';
import '../repositories/advanced_filter_catalog_repository.dart';
import '../services/advanced_filter_catalog_constants.dart';
import '../services/advanced_filter_perf_logger.dart';
import '../services/advanced_filter_catalog_sync_service.dart';

enum AdvancedFilterLoadState { loading, ready, error }

enum AdvancedFilterSortField { name, year }

@immutable
class AdvancedFilterInitialSelection {
  final List<String> genres;
  final List<String> years;

  const AdvancedFilterInitialSelection({
    this.genres = const [],
    this.years = const [],
  });

  Set<String> get normalizedGenres => _normalizeTextValues(genres);

  Set<String> get normalizedYears {
    final values = <String>{};
    for (final rawYear in years) {
      final year = int.tryParse(rawYear.trim());
      if (year != null && year > 0) {
        values.add(year.toString());
      }
    }
    return values;
  }

  bool get hasSelections =>
      normalizedGenres.isNotEmpty || normalizedYears.isNotEmpty;

  static Set<String> _normalizeTextValues(Iterable<String> values) {
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
  }
}

@immutable
class AdvancedFilterLibraryOption {
  final String id;
  final String name;

  const AdvancedFilterLibraryOption({required this.id, required this.name});
}

class AdvancedFilterViewModel extends ChangeNotifier {
  static const movieType = AdvancedFilterCatalogConstants.movieType;
  static const seriesType = AdvancedFilterCatalogConstants.seriesType;
  static const _cacheVersion = 3;

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
  static const _selectionPersistDelay = Duration(milliseconds: 80);
  Timer? _selectionPersistTimer;
  Future<void>? _selectionPersistInFlight;
  final List<Completer<void>> _selectionPersistWaiters = <Completer<void>>[];
  int? _selectionPersistTraceId;
  String? _selectionPersistReason;
  bool _legacyCatalogPreferenceCleared = false;

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

  List<String> _types = const [movieType, seriesType];
  List<String> get types => _types;

  List<String> _catalogGenres = const [];
  List<String> _genres = const [];
  List<String> get genres => _genres;

  List<String> _catalogRegions = const [];
  List<String> _regions = const [];
  List<String> get regions => _regions;

  List<AdvancedFilterLibraryOption> _catalogLibraries = const [];
  List<AdvancedFilterLibraryOption> _libraries = const [];
  List<AdvancedFilterLibraryOption> get libraries => _libraries;

  List<String> _catalogYears = const [];
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

  Set<String> _selectedLibraries = <String>{};
  Set<String> get selectedLibraries => _selectedLibraries;

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
      _selectedLibraries.isNotEmpty ||
      _selectedYears.isNotEmpty;

  bool get showLibraryFilter => _client.serverType == ServerType.emby;

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
        'regions=${_regions.length} libraries=${_libraries.length} '
        'years=${_years.length} '
        'sort=${_sortField.name}:${_sortAscending ? 'asc' : 'desc'}';
  }

  String _selectionSummary() {
    return 'selectedTypes=${_selectedTypes.length} '
        'selectedGenres=${_selectedGenres.length} '
        'selectedRegions=${_selectedRegions.length} '
        'selectedLibraries=${_selectedLibraries.length} '
        'selectedYears=${_selectedYears.length}';
  }

  Future<void> load({AdvancedFilterInitialSelection? initialSelection}) async {
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
      final initialSelectionWatch = Stopwatch()..start();
      final appliedInitialSelection = _applyInitialSelection(initialSelection);
      initialSelectionWatch.stop();
      _logPerf(
        traceId,
        'load:applyInitialSelection '
        'applied=$appliedInitialSelection '
        'ms=${initialSelectionWatch.elapsedMilliseconds} '
        '${_selectionSummary()}',
      );

      final cacheWatch = Stopwatch()..start();
      final cachedSnapshot = await _loadCachedCatalogSnapshot(traceId);
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
        await _useCatalogItems(
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
        if (appliedInitialSelection) {
          await _persistInitialSelections(
            traceId: traceId,
            reason: 'load-cache-initialSelection',
          );
        }
        return;
      }

      await _refreshCatalogFromServer(background: false);
      if (appliedInitialSelection && _state == AdvancedFilterLoadState.ready) {
        await _persistInitialSelections(
          traceId: traceId,
          reason: 'load-refresh-initialSelection',
        );
      }
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

  Future<void> toggleType(String value) => _updateFilters(
    'toggleType',
    value,
    () => _toggleExclusive(_selectedTypes, value),
  );

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

  Future<void> toggleLibrary(String value) => _updateFilters(
    'toggleLibrary',
    value,
    () => _toggle(_selectedLibraries, value),
  );

  Future<void> toggleYear(String value) => _updateFilters(
    'toggleYear',
    value,
    () => _toggleExclusive(_selectedYears, value),
  );

  Future<void> clearTypes() =>
      _updateFilters('clearTypes', 'all', _selectedTypes.clear);

  Future<void> clearGenres() =>
      _updateFilters('clearGenres', 'all', _selectedGenres.clear);

  Future<void> clearRegions() =>
      _updateFilters('clearRegions', 'all', _selectedRegions.clear);

  Future<void> clearLibraries() =>
      _updateFilters('clearLibraries', 'all', _selectedLibraries.clear);

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
    _selectedLibraries = <String>{};
    _selectedYears = <String>{};
    _results = _filterItems(reason: 'clearAll', traceId: traceId);
    _refreshVisibleFilterOptions(reason: 'clearAll', traceId: traceId);
    _hasApplied = true;
    _logPerf(traceId, 'clearAll:filterDone results=${_results.length}');
    final notifyWatch = Stopwatch()..start();
    notifyListeners();
    notifyWatch.stop();
    _logPerf(
      traceId,
      'clearAll:notifyListeners ms=${notifyWatch.elapsedMilliseconds}',
    );
    await _schedulePersistSelections(
      traceId: traceId,
      reason: 'clearAll',
      applied: true,
    );
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
    _selectedLibraries = showLibraryFilter
        ? _prefs
              .get(UserPreferences.advancedFilterLibraries(_preferenceScopeKey))
              .toSet()
        : <String>{};
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

  bool _applyInitialSelection(AdvancedFilterInitialSelection? selection) {
    if (selection == null || !selection.hasSelections) return false;

    final years = selection.normalizedYears.toList()
      ..sort((a, b) => b.compareTo(a));
    _selectedTypes = <String>{};
    _selectedGenres = selection.normalizedGenres;
    _selectedRegions = <String>{};
    _selectedLibraries = <String>{};
    _selectedYears = years.take(1).toSet();
    _hasApplied = true;
    return true;
  }

  Future<void> _persistSelections({required bool applied}) async {
    final orderedTypes = _selectedTypes.toList()..sort(_typeSort);
    final orderedGenres = _selectedGenres.toList()..sort(_compareText);
    final orderedRegions = _selectedRegions.toList()..sort(_compareText);
    final orderedLibraries = _selectedLibraries.toList()..sort(_compareText);
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
        UserPreferences.advancedFilterLibraries(_preferenceScopeKey),
        orderedLibraries,
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

  Future<void> _persistInitialSelections({
    required int traceId,
    required String reason,
  }) async {
    final persistWatch = Stopwatch()..start();
    await _persistSelections(applied: true);
    persistWatch.stop();
    _logPerf(
      traceId,
      '$reason:persistSelectionsDone '
      'ms=${persistWatch.elapsedMilliseconds} ${_selectionSummary()}',
    );
  }

  Future<void> _schedulePersistSelections({
    required int traceId,
    required String reason,
    required bool applied,
  }) {
    final waiter = Completer<void>();
    _selectionPersistWaiters.add(waiter);
    _selectionPersistTraceId = traceId;
    _selectionPersistReason = reason;
    _selectionPersistTimer?.cancel();
    _selectionPersistTimer = Timer(_selectionPersistDelay, () {
      _selectionPersistTimer = null;
      final runTraceId = _selectionPersistTraceId ?? traceId;
      final runReason = _selectionPersistReason ?? reason;
      _selectionPersistTraceId = null;
      _selectionPersistReason = null;
      _runScheduledSelectionPersist(
        traceId: runTraceId,
        reason: runReason,
        applied: applied,
      );
    });
    _logPerf(
      traceId,
      '$reason:persistSelectionsScheduled '
      'delayMs=${_selectionPersistDelay.inMilliseconds} '
      'pending=${_selectionPersistWaiters.length}',
    );
    return waiter.future;
  }

  void _runScheduledSelectionPersist({
    required int traceId,
    required String reason,
    required bool applied,
  }) {
    final waiters = List<Completer<void>>.of(_selectionPersistWaiters);
    _selectionPersistWaiters.clear();
    if (waiters.isEmpty) return;

    unawaited(
      _persistSelectionsAfterInFlight(
        traceId: traceId,
        reason: reason,
        applied: applied,
        waiters: waiters,
      ),
    );
  }

  Future<void> _persistSelectionsAfterInFlight({
    required int traceId,
    required String reason,
    required bool applied,
    required List<Completer<void>> waiters,
  }) async {
    final totalWatch = Stopwatch()..start();
    Future<void>? persistFuture;
    try {
      final previous = _selectionPersistInFlight;
      if (previous != null) {
        final waitWatch = Stopwatch()..start();
        try {
          await previous;
        } catch (_) {
          // The new selection snapshot should still be attempted.
        }
        waitWatch.stop();
        _logPerf(
          traceId,
          '$reason:persistSelectionsWaitForInFlight '
          'ms=${waitWatch.elapsedMilliseconds}',
        );
      }

      final persistWatch = Stopwatch()..start();
      persistFuture = _persistSelections(applied: applied);
      _selectionPersistInFlight = persistFuture;
      await persistFuture;
      persistWatch.stop();
      totalWatch.stop();
      _logPerf(
        traceId,
        '$reason:persistSelectionsDone '
        'persistMs=${persistWatch.elapsedMilliseconds} '
        'totalMs=${totalWatch.elapsedMilliseconds} '
        'waiters=${waiters.length}',
      );
      for (final waiter in waiters) {
        if (!waiter.isCompleted) waiter.complete();
      }
    } catch (error, stackTrace) {
      totalWatch.stop();
      _logPerf(
        traceId,
        '$reason:persistSelectionsError '
        'ms=${totalWatch.elapsedMilliseconds} error=$error',
      );
      for (final waiter in waiters) {
        if (!waiter.isCompleted) waiter.completeError(error, stackTrace);
      }
    } finally {
      if (_selectionPersistInFlight == persistFuture) {
        _selectionPersistInFlight = null;
      }
    }
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
      await _useCatalogItems(
        items,
        reason: background ? 'refresh-background' : 'refresh-foreground',
        traceId: traceId,
      );
      await _clearLegacyCatalogPreferences(
        traceId: traceId,
        reason: 'server-refresh',
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

  Future<void> _useCatalogItems(
    List<AggregatedItem> items, {
    required String reason,
    required int traceId,
  }) async {
    final totalWatch = Stopwatch()..start();
    _catalogItems = items;
    final genresWatch = Stopwatch()..start();
    _catalogGenres = _collectGenres(items);
    genresWatch.stop();
    final regionsWatch = Stopwatch()..start();
    _catalogRegions = _collectRegions(items);
    regionsWatch.stop();
    final librariesWatch = Stopwatch()..start();
    _catalogLibraries = showLibraryFilter
        ? await _loadEmbyLibrariesForItems(items, traceId: traceId)
        : const [];
    librariesWatch.stop();
    final yearsWatch = Stopwatch()..start();
    _catalogYears = _collectYears(items);
    yearsWatch.stop();
    final dropWatch = Stopwatch()..start();
    _dropUnavailableSelections();
    dropWatch.stop();
    _hasApplied = true;
    _results = _filterItems(
      reason: '$reason-useCatalogItems',
      traceId: traceId,
    );
    final optionsWatch = Stopwatch()..start();
    _refreshVisibleFilterOptions(
      reason: '$reason-useCatalogItems',
      traceId: traceId,
    );
    optionsWatch.stop();
    totalWatch.stop();
    _logPerf(
      traceId,
      'useCatalogItems:$reason totalMs=${totalWatch.elapsedMilliseconds} '
      'items=${items.length} genres=${_catalogGenres.length} '
      'regions=${_catalogRegions.length} libraries=${_catalogLibraries.length} '
      'years=${_catalogYears.length} '
      'collectGenresMs=${genresWatch.elapsedMilliseconds} '
      'collectRegionsMs=${regionsWatch.elapsedMilliseconds} '
      'collectLibrariesMs=${librariesWatch.elapsedMilliseconds} '
      'collectYearsMs=${yearsWatch.elapsedMilliseconds} '
      'dropUnavailableMs=${dropWatch.elapsedMilliseconds} '
      'refreshOptionsMs=${optionsWatch.elapsedMilliseconds} '
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
    _refreshVisibleFilterOptions(reason: action, traceId: traceId);
    _logPerf(traceId, '$action:filterDone results=${_results.length}');
    final notifyWatch = Stopwatch()..start();
    notifyListeners();
    notifyWatch.stop();
    _logPerf(
      traceId,
      '$action:notifyListeners ms=${notifyWatch.elapsedMilliseconds}',
    );
    totalWatch.stop();
    _logPerf(
      traceId,
      '$action:persistSelectionsQueued totalMethodMs=${totalWatch.elapsedMilliseconds}',
    );
    await _schedulePersistSelections(
      traceId: traceId,
      reason: action,
      applied: true,
    );
  }

  Future<AdvancedFilterCatalogSnapshot?> _loadCachedCatalogSnapshot(
    int traceId,
  ) async {
    final snapshot = await _catalogRepository.loadSnapshot(
      serverId: _client.baseUrl,
      userId: _catalogUserId,
    );
    if (snapshot != null) {
      await _clearLegacyCatalogPreferences(
        traceId: traceId,
        reason: 'sqlite-cache-hit',
      );
      return snapshot;
    }

    final legacyItems = _loadLegacyCachedCatalogItems();
    if (legacyItems != null) {
      unawaited(
        _saveCatalogCache(
          legacyItems,
          traceId: traceId,
          clearLegacyAfterSave: true,
        ),
      );
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

  Future<void> _clearLegacyCatalogPreferences({
    required int traceId,
    required String reason,
  }) async {
    if (_legacyCatalogPreferenceCleared) return;
    final cacheKeys = _prefs.preferenceKeys
        .where(
          (key) => key.startsWith(UserPreferences.advancedFilterCacheKeyPrefix),
        )
        .toSet();
    _legacyCatalogPreferenceCleared = true;
    if (cacheKeys.isEmpty) {
      _logPerf(traceId, 'legacyCacheClear:skip reason=$reason empty=true');
      return;
    }
    final rawLength = cacheKeys.fold<int>(0, (total, key) {
      return total +
          _prefs.get(Preference<String>(key: key, defaultValue: '')).length;
    });

    final clearWatch = Stopwatch()..start();
    try {
      final removedCount = await _prefs.removePreferenceKeys(cacheKeys);
      clearWatch.stop();
      _logPerf(
        traceId,
        'legacyCacheClear:done reason=$reason keys=$removedCount '
        'bytes=$rawLength '
        'ms=${clearWatch.elapsedMilliseconds}',
      );
    } catch (error) {
      clearWatch.stop();
      _legacyCatalogPreferenceCleared = false;
      _logPerf(
        traceId,
        'legacyCacheClear:error reason=$reason keys=${cacheKeys.length} '
        'bytes=$rawLength '
        'ms=${clearWatch.elapsedMilliseconds} error=$error',
      );
    }
  }

  Future<void> _saveCatalogCache(
    List<AggregatedItem> items, {
    int? traceId,
    bool clearLegacyAfterSave = false,
  }) async {
    try {
      await _catalogRepository.replaceScope(
        serverId: _client.baseUrl,
        userId: _catalogUserId,
        items: items,
      );
      if (clearLegacyAfterSave && traceId != null) {
        await _clearLegacyCatalogPreferences(
          traceId: traceId,
          reason: 'legacy-migrated-to-sqlite',
        );
      }
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
    await _useCatalogItems(
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
    var libraryPassed = 0;
    var yearPassed = 0;
    final filtered = <AggregatedItem>[];

    for (final item in _catalogItems) {
      final matchesType = _matchesSingleValue(item.type, _selectedTypes);
      if (!matchesType) continue;
      typePassed++;

      final matchesGenre = _containsAllValues(item.genres, _selectedGenres);
      if (!matchesGenre) continue;
      genrePassed++;

      final matchesRegion = _containsAllValues(
        item.productionLocations,
        _selectedRegions,
      );
      if (!matchesRegion) continue;
      regionPassed++;

      final matchesLibrary = _matchesAnyValue(
        _itemLibraryId(item),
        _selectedLibraries,
      );
      if (!matchesLibrary) continue;
      libraryPassed++;

      final year = item.productionYear?.toString();
      final matchesYear = _matchesSingleValue(year, _selectedYears);
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
      'libraryPassed=$libraryPassed yearPassed=$yearPassed '
      'selectedTypes=${_selectedTypes.length} '
      'selectedGenres=${_selectedGenres.length} '
      'selectedRegions=${_selectedRegions.length} '
      'selectedLibraries=${_selectedLibraries.length} '
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
    _selectedGenres.removeWhere((genre) => !_catalogGenres.contains(genre));
    _selectedRegions.removeWhere((region) => !_catalogRegions.contains(region));
    if (showLibraryFilter) {
      final libraryIds = _catalogLibraries.map((library) => library.id).toSet();
      _selectedLibraries.removeWhere(
        (libraryId) => !libraryIds.contains(libraryId),
      );
    } else {
      _selectedLibraries.clear();
    }
    _selectedYears.removeWhere((year) => !_catalogYears.contains(year));
  }

  void _refreshVisibleFilterOptions({
    required String reason,
    required int traceId,
  }) {
    final optionsWatch = Stopwatch()..start();
    _types = _collectTypes(_results, include: _selectedTypes);
    _genres = _collectGenres(_results, include: _selectedGenres);
    _regions = _collectRegions(_results, include: _selectedRegions);
    _libraries = showLibraryFilter
        ? _collectLibraries(_results, include: _selectedLibraries)
        : const [];
    _years = _collectYears(_results, include: _selectedYears);
    optionsWatch.stop();
    _logPerf(
      traceId,
      'filterOptions:$reason ms=${optionsWatch.elapsedMilliseconds} '
      'types=${_types.length} genres=${_genres.length} '
      'libraries=${_libraries.length} '
      'regions=${_regions.length} years=${_years.length}',
    );
  }

  List<String> _collectTypes(
    List<AggregatedItem> items, {
    Set<String> include = const <String>{},
  }) {
    final values = include.where(_validType).toSet();
    for (final item in items) {
      final type = item.type;
      if (type != null && _validType(type)) values.add(type);
    }
    return values.toList()..sort(_typeSort);
  }

  List<String> _collectGenres(
    List<AggregatedItem> items, {
    Set<String> include = const <String>{},
  }) {
    final values = include
        .map((genre) => genre.trim())
        .where((genre) => genre.isNotEmpty)
        .toSet();
    for (final item in items) {
      for (final genre in item.genres) {
        final normalized = genre.trim();
        if (normalized.isNotEmpty) values.add(normalized);
      }
    }
    return values.toList()..sort(_compareText);
  }

  List<String> _collectRegions(
    List<AggregatedItem> items, {
    Set<String> include = const <String>{},
  }) {
    final values = include
        .map((region) => region.trim())
        .where((region) => region.isNotEmpty)
        .toSet();
    for (final item in items) {
      for (final region in item.productionLocations) {
        final normalized = region.trim();
        if (normalized.isNotEmpty) values.add(normalized);
      }
    }
    return values.toList()..sort(_compareText);
  }

  List<AdvancedFilterLibraryOption> _collectLibraries(
    List<AggregatedItem> items, {
    Set<String> include = const <String>{},
  }) {
    final visibleIds = include
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    for (final item in items) {
      final libraryId = _itemLibraryId(item);
      if (libraryId != null && libraryId.isNotEmpty) {
        visibleIds.add(libraryId);
      }
    }

    return _catalogLibraries
        .where((library) => visibleIds.contains(library.id))
        .toList(growable: false);
  }

  List<String> _collectYears(
    List<AggregatedItem> items, {
    Set<String> include = const <String>{},
  }) {
    final values = include
        .map((year) => year.trim())
        .where((year) => year.isNotEmpty)
        .toSet();
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

  void _toggleExclusive(Set<String> values, String value) {
    if (values.length == 1 && values.contains(value)) {
      values.clear();
      return;
    }
    values
      ..clear()
      ..add(value);
  }

  bool _validType(String value) => value == movieType || value == seriesType;

  Future<List<AdvancedFilterLibraryOption>> _loadEmbyLibrariesForItems(
    List<AggregatedItem> items, {
    required int traceId,
  }) async {
    final parentIds = <String>{};
    for (final item in items) {
      final libraryId = _itemLibraryId(item);
      if (libraryId != null && libraryId.isNotEmpty) {
        parentIds.add(libraryId);
      }
    }

    try {
      final response = await _client.userViewsApi.getUserViews();
      final rawViews = response['Items'] as List? ?? const [];
      final libraries = <AdvancedFilterLibraryOption>[];
      for (final rawView in rawViews) {
        if (rawView is! Map) continue;
        final data = Map<String, dynamic>.from(rawView);
        final id = (data['Id'] as String?)?.trim();
        final name = (data['Name'] as String?)?.trim();
        if (id == null || id.isEmpty || name == null || name.isEmpty) continue;
        if (parentIds.isNotEmpty && !parentIds.contains(id)) continue;
        final collectionType = (data['CollectionType'] as String?)
            ?.trim()
            .toLowerCase();
        if (collectionType == 'playlists' ||
            collectionType == 'boxsets' ||
            collectionType == 'livetv') {
          continue;
        }
        libraries.add(AdvancedFilterLibraryOption(id: id, name: name));
      }
      libraries.sort((a, b) => _compareText(a.name, b.name));
      return libraries;
    } catch (error) {
      _logPerf(traceId, 'loadEmbyLibraries:error $error');
      return const [];
    }
  }

  String? _itemLibraryId(AggregatedItem item) {
    final annotated =
        item.rawData[AdvancedFilterCatalogConstants.embyLibraryIdField]
            as String?;
    final annotatedId = annotated?.trim();
    if (annotatedId != null && annotatedId.isNotEmpty) {
      return annotatedId;
    }

    final parentId = item.parentId?.trim();
    if (parentId != null && parentId.isNotEmpty) {
      return parentId;
    }
    return null;
  }

  AdvancedFilterSortField _normalizeSortField(String value) {
    for (final field in AdvancedFilterSortField.values) {
      if (field.name == value) return field;
    }
    return AdvancedFilterSortField.name;
  }

  bool _containsAllValues(Iterable<String> values, Set<String> requiredValues) {
    if (requiredValues.isEmpty) return true;
    if (requiredValues.length == 1) {
      final requiredValue = requiredValues.first;
      return values.any((value) => value.trim() == requiredValue);
    }
    final availableValues = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    return requiredValues.every(availableValues.contains);
  }

  bool _matchesSingleValue(String? value, Set<String> selectedValues) {
    if (selectedValues.isEmpty) return true;
    return selectedValues.length == 1 &&
        value != null &&
        selectedValues.contains(value);
  }

  bool _matchesAnyValue(String? value, Set<String> selectedValues) {
    if (selectedValues.isEmpty) return true;
    return value != null && selectedValues.contains(value);
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
    _flushPendingSelectionPersistOnDispose();
    _disposed = true;
    _catalogChangeSub?.cancel();
    _catalogChangeSub = null;
    if (_ownsCatalogSyncService) {
      _catalogSyncService.dispose();
    }
    super.dispose();
  }

  void _flushPendingSelectionPersistOnDispose() {
    if (_selectionPersistWaiters.isEmpty) return;
    _selectionPersistTimer?.cancel();
    _selectionPersistTimer = null;
    final traceId = _selectionPersistTraceId ?? _lastPerfTraceId ?? 0;
    final reason = _selectionPersistReason ?? 'dispose';
    _selectionPersistTraceId = null;
    _selectionPersistReason = null;
    _runScheduledSelectionPersist(
      traceId: traceId,
      reason: '$reason-dispose',
      applied: true,
    );
  }
}
