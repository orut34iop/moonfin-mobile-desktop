import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:server_core/server_core.dart' hide ImageType;

import '../../preference/user_preferences.dart';
import '../models/aggregated_item.dart';

enum AdvancedFilterLoadState { loading, ready, error }

class AdvancedFilterViewModel extends ChangeNotifier {
  static const movieType = 'Movie';
  static const seriesType = 'Series';
  static const _cacheVersion = 1;
  static const _pageSize = 1000;
  static const _itemFields =
      'Type,UserData,PrimaryImageAspectRatio,SortName,CommunityRating,'
      'OfficialRating,RunTimeTicks,ProductionYear,PremiereDate,Genres,'
      'ProductionLocations,ImageTags,BackdropImageTags,ParentBackdropItemId,'
      'ParentBackdropImageTags,ParentThumbItemId,ParentThumbImageTag,SeriesId,'
      'SeriesPrimaryImageTag,PrimaryImageTag,PrimaryImageItemId';

  final MediaServerClient _client;
  final UserPreferences _prefs;

  AdvancedFilterViewModel({
    required MediaServerClient client,
    required UserPreferences prefs,
  }) : _client = client,
       _prefs = prefs;

  AdvancedFilterLoadState _state = AdvancedFilterLoadState.loading;
  AdvancedFilterLoadState get state => _state;

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

  bool get hasActiveFilters =>
      _selectedTypes.isNotEmpty ||
      _selectedGenres.isNotEmpty ||
      _selectedRegions.isNotEmpty ||
      _selectedYears.isNotEmpty;

  String get _serverKey => _client.baseUrl;

  Future<void> load() async {
    _state = AdvancedFilterLoadState.loading;
    _errorMessage = null;
    _loadedItemCount = 0;
    _totalItemCount = null;
    notifyListeners();

    _restoreSelections();

    final cachedItems = _loadCachedCatalogItems();
    if (cachedItems != null) {
      _useCatalogItems(cachedItems);
      _state = AdvancedFilterLoadState.ready;
      notifyListeners();
      return;
    }

    try {
      final items = await _loadCatalogItems();
      _useCatalogItems(items);
      _state = AdvancedFilterLoadState.ready;
      unawaited(_saveCatalogCache(items));
    } catch (error) {
      _errorMessage = error.toString();
      _state = AdvancedFilterLoadState.error;
    }

    notifyListeners();
  }

  Future<void> toggleType(String value) =>
      _updateFilters(() => _toggle(_selectedTypes, value));

  Future<void> toggleGenre(String value) =>
      _updateFilters(() => _toggle(_selectedGenres, value));

  Future<void> toggleRegion(String value) =>
      _updateFilters(() => _toggle(_selectedRegions, value));

  Future<void> toggleYear(String value) =>
      _updateFilters(() => _toggle(_selectedYears, value));

  Future<void> clearTypes() => _updateFilters(_selectedTypes.clear);

  Future<void> clearGenres() => _updateFilters(_selectedGenres.clear);

  Future<void> clearRegions() => _updateFilters(_selectedRegions.clear);

  Future<void> clearYears() => _updateFilters(_selectedYears.clear);

  Future<void> clearAll() async {
    _selectedTypes = <String>{};
    _selectedGenres = <String>{};
    _selectedRegions = <String>{};
    _selectedYears = <String>{};
    _results = _filterItems();
    _hasApplied = true;
    await _persistSelections(applied: true);
    notifyListeners();
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
        .get(UserPreferences.advancedFilterTypes(_serverKey))
        .where(_validType)
        .toSet();
    _selectedGenres = _prefs
        .get(UserPreferences.advancedFilterGenres(_serverKey))
        .toSet();
    _selectedRegions = _prefs
        .get(UserPreferences.advancedFilterRegions(_serverKey))
        .toSet();
    _selectedYears = _prefs
        .get(UserPreferences.advancedFilterYears(_serverKey))
        .toSet();
    _hasApplied = _prefs.get(UserPreferences.advancedFilterApplied(_serverKey));
  }

  Future<void> _persistSelections({required bool applied}) async {
    final orderedTypes = _selectedTypes.toList()..sort(_typeSort);
    final orderedGenres = _selectedGenres.toList()..sort(_compareText);
    final orderedRegions = _selectedRegions.toList()..sort(_compareText);
    final orderedYears = _selectedYears.toList()
      ..sort((a, b) => b.compareTo(a));

    await Future.wait([
      _prefs.set(UserPreferences.advancedFilterTypes(_serverKey), orderedTypes),
      _prefs.set(
        UserPreferences.advancedFilterGenres(_serverKey),
        orderedGenres,
      ),
      _prefs.set(
        UserPreferences.advancedFilterRegions(_serverKey),
        orderedRegions,
      ),
      _prefs.set(UserPreferences.advancedFilterYears(_serverKey), orderedYears),
      _prefs.set(UserPreferences.advancedFilterApplied(_serverKey), applied),
    ]);
  }

  Future<List<AggregatedItem>> _loadCatalogItems() async {
    final items = <AggregatedItem>[];
    var startIndex = 0;
    int? total;

    while (true) {
      final response = await _client.itemsApi.getItems(
        includeItemTypes: const [movieType, seriesType],
        recursive: true,
        fields: _itemFields,
        sortBy: 'SortName',
        sortOrder: 'Ascending',
        startIndex: startIndex,
        limit: _pageSize,
        enableTotalRecordCount: true,
        enableImageTypes: 'Primary,Backdrop,Thumb',
      );

      total ??= response['TotalRecordCount'] as int?;
      _totalItemCount = total;
      final pageItems = response['Items'] as List? ?? const [];
      if (pageItems.isEmpty) break;

      for (final item in pageItems) {
        if (item is! Map) continue;
        final data = Map<String, dynamic>.from(item);
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

      startIndex += pageItems.length;
      _loadedItemCount = startIndex;
      notifyListeners();
      if (pageItems.length < _pageSize) break;
      if (total != null && startIndex >= total) break;
    }

    items.sort((a, b) => _compareText(a.name, b.name));
    return items;
  }

  void _useCatalogItems(List<AggregatedItem> items) {
    _catalogItems = items;
    _genres = _collectGenres(items);
    _regions = _collectRegions(items);
    _years = _collectYears(items);
    _dropUnavailableSelections();
    _hasApplied = true;
    _results = _filterItems();
  }

  Future<void> _updateFilters(VoidCallback updateSelection) async {
    updateSelection();
    _hasApplied = true;
    _results = _filterItems();
    notifyListeners();
    await _persistSelections(applied: true);
  }

  List<AggregatedItem>? _loadCachedCatalogItems() {
    final raw = _prefs.get(UserPreferences.advancedFilterCache(_serverKey));
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
      final payload = <String, dynamic>{
        'version': _cacheVersion,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'items': items.map((item) => item.rawData).toList(growable: false),
      };
      await _prefs.set(
        UserPreferences.advancedFilterCache(_serverKey),
        jsonEncode(payload),
      );
    } catch (_) {
      // A cache write failure should not block filtering or navigation.
    }
  }

  List<AggregatedItem> _filterItems() {
    final filtered = _catalogItems.where((item) {
      final type = item.type;
      final matchesType =
          _selectedTypes.isEmpty ||
          (type != null && _selectedTypes.contains(type));
      if (!matchesType) return false;

      final matchesGenre =
          _selectedGenres.isEmpty ||
          item.genres.any((genre) => _selectedGenres.contains(genre));
      if (!matchesGenre) return false;

      final matchesRegion =
          _selectedRegions.isEmpty ||
          item.productionLocations.any(
            (region) => _selectedRegions.contains(region),
          );
      if (!matchesRegion) return false;

      final year = item.productionYear?.toString();
      final matchesYear =
          _selectedYears.isEmpty ||
          (year != null && _selectedYears.contains(year));
      return matchesYear;
    }).toList();

    filtered.sort((a, b) => _compareText(a.name, b.name));
    return filtered;
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

  int _typeSort(String a, String b) {
    const order = {movieType: 0, seriesType: 1};
    return (order[a] ?? 99).compareTo(order[b] ?? 99);
  }

  static int _compareText(String a, String b) {
    final lower = a.toLowerCase().compareTo(b.toLowerCase());
    if (lower != 0) return lower;
    return a.compareTo(b);
  }
}
