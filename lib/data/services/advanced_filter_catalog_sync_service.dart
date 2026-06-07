import 'dart:async';

import 'package:server_core/server_core.dart';

import '../models/aggregated_item.dart';
import '../repositories/advanced_filter_catalog_repository.dart';
import 'advanced_filter_catalog_constants.dart';
import 'advanced_filter_perf_logger.dart';

typedef AdvancedFilterCatalogProgress = void Function(int loaded, int? total);

class AdvancedFilterCatalogSyncService {
  static const defaultCacheMaxAge =
      AdvancedFilterCatalogRepository.defaultMaxAge;
  static const _incrementalDebounce = Duration(milliseconds: 350);
  static const _incrementalBatchSize = 100;

  final MediaServerClient _client;
  final AdvancedFilterCatalogRepository _repository;
  final Stream<ServerWebSocketMessage> _events;
  final _catalogChangedController = StreamController<void>.broadcast();

  StreamSubscription<ServerWebSocketMessage>? _subscription;
  Future<List<AggregatedItem>>? _fullRefreshFuture;
  Timer? _incrementalTimer;
  final Set<String> _pendingRefreshIds = <String>{};
  final Set<String> _pendingRemoveIds = <String>{};
  bool _incrementalFlushRunning = false;
  bool _disposed = false;

  AdvancedFilterCatalogSyncService({
    required MediaServerClient client,
    required AdvancedFilterCatalogRepository repository,
    required Stream<ServerWebSocketMessage> events,
  }) : _client = client,
       _repository = repository,
       _events = events;

  Stream<void> get catalogChanged => _catalogChangedController.stream;

  String get _serverId => _client.baseUrl;

  String get _userId => _client.userId?.trim() ?? '';

  void start() {
    if (_disposed || _subscription != null) return;
    AdvancedFilterPerfLogger.write(
      '[AdvancedFilterPerf][sync] start serverScope active',
    );
    _subscription = _events.listen((message) {
      unawaited(_handleMessage(message));
    });
  }

  Future<List<AggregatedItem>> refreshCatalog({
    AdvancedFilterCatalogProgress? onProgress,
  }) {
    final existing = _fullRefreshFuture;
    if (existing != null) {
      AdvancedFilterPerfLogger.write(
        '[AdvancedFilterPerf][sync] fullRefresh reuseInFlight=true',
      );
      return existing;
    }

    final refreshWatch = Stopwatch()..start();
    AdvancedFilterPerfLogger.write(
      '[AdvancedFilterPerf][sync] fullRefresh:start',
    );
    final future = _fetchFullCatalog(onProgress: onProgress).then((
      items,
    ) async {
      final replaceWatch = Stopwatch()..start();
      await _repository.replaceScope(
        serverId: _serverId,
        userId: _userId,
        items: items,
      );
      replaceWatch.stop();
      _notifyCatalogChanged();
      refreshWatch.stop();
      AdvancedFilterPerfLogger.write(
        '[AdvancedFilterPerf][sync] fullRefresh:done '
        'totalMs=${refreshWatch.elapsedMilliseconds} '
        'replaceScopeMs=${replaceWatch.elapsedMilliseconds} '
        'items=${items.length}',
      );
      return items;
    });

    _fullRefreshFuture = future.whenComplete(() {
      _fullRefreshFuture = null;
    });
    return _fullRefreshFuture!;
  }

  Future<List<AggregatedItem>?> refreshIfStale({
    AdvancedFilterCatalogSnapshot? snapshot,
    Duration maxAge = defaultCacheMaxAge,
  }) async {
    final watch = Stopwatch()..start();
    final current =
        snapshot ??
        await _repository.loadSnapshot(serverId: _serverId, userId: _userId);
    watch.stop();
    if (current == null || !_repository.isExpired(current, maxAge: maxAge)) {
      AdvancedFilterPerfLogger.write(
        '[AdvancedFilterPerf][sync] refreshIfStale skip '
        'loadMs=${watch.elapsedMilliseconds} hasSnapshot=${current != null}',
      );
      return null;
    }
    AdvancedFilterPerfLogger.write(
      '[AdvancedFilterPerf][sync] refreshIfStale expired '
      'loadMs=${watch.elapsedMilliseconds} items=${current.items.length}',
    );
    return refreshCatalog();
  }

  Future<void> _handleMessage(ServerWebSocketMessage message) async {
    if (!await _repository.hasScope(serverId: _serverId, userId: _userId)) {
      return;
    }

    switch (message) {
      case LibraryChangedMessage():
        AdvancedFilterPerfLogger.write(
          '[AdvancedFilterPerf][sync] websocket:LibraryChanged '
          'added=${message.itemsAdded.length} '
          'updated=${message.itemsUpdated.length} '
          'removed=${message.itemsRemoved.length}',
        );
        final removed = message.itemsRemoved.toSet();
        final changed = <String>{...message.itemsAdded, ...message.itemsUpdated}
          ..removeAll(removed);
        _queueIncremental(refreshIds: changed, removeIds: removed);
      case UserDataChangedMessage():
        if (message.userId.trim() == _userId) {
          AdvancedFilterPerfLogger.write(
            '[AdvancedFilterPerf][sync] websocket:UserDataChanged '
            'items=${message.itemIds.length}',
          );
          _queueIncremental(refreshIds: message.itemIds);
        }
      default:
        break;
    }
  }

  void _queueIncremental({
    Iterable<String> refreshIds = const [],
    Iterable<String> removeIds = const [],
  }) {
    if (_disposed) return;

    for (final rawId in removeIds) {
      final id = rawId.trim();
      if (id.isEmpty) continue;
      _pendingRemoveIds.add(id);
      _pendingRefreshIds.remove(id);
    }

    for (final rawId in refreshIds) {
      final id = rawId.trim();
      if (id.isEmpty || _pendingRemoveIds.contains(id)) continue;
      _pendingRefreshIds.add(id);
    }

    _incrementalTimer?.cancel();
    AdvancedFilterPerfLogger.write(
      '[AdvancedFilterPerf][sync] incremental:queued '
      'pendingRefresh=${_pendingRefreshIds.length} '
      'pendingRemove=${_pendingRemoveIds.length}',
    );
    _incrementalTimer = Timer(_incrementalDebounce, () {
      unawaited(_flushIncremental());
    });
  }

  Future<void> _flushIncremental() async {
    if (_incrementalFlushRunning || _disposed) return;
    _incrementalFlushRunning = true;
    final flushWatch = Stopwatch()..start();

    try {
      while (!_disposed) {
        final removeIds = _pendingRemoveIds.toList();
        final refreshIds = _pendingRefreshIds.toList()
          ..removeWhere(removeIds.contains);
        _pendingRemoveIds.clear();
        _pendingRefreshIds.clear();

        if (removeIds.isEmpty && refreshIds.isEmpty) break;

        AdvancedFilterPerfLogger.write(
          '[AdvancedFilterPerf][sync] incremental:flushBatch '
          'refresh=${refreshIds.length} remove=${removeIds.length}',
        );
        if (removeIds.isNotEmpty) {
          final removeWatch = Stopwatch()..start();
          await _repository.removeItems(
            serverId: _serverId,
            userId: _userId,
            itemIds: removeIds,
          );
          removeWatch.stop();
          AdvancedFilterPerfLogger.write(
            '[AdvancedFilterPerf][sync] incremental:removeItems '
            'ms=${removeWatch.elapsedMilliseconds} count=${removeIds.length}',
          );
        }

        if (refreshIds.isNotEmpty) {
          final fetchWatch = Stopwatch()..start();
          final items = await _fetchItemsByIds(refreshIds);
          fetchWatch.stop();
          final returnedIds = items.map((item) => item.id).toSet();
          final missingIds = refreshIds
              .where((id) => !returnedIds.contains(id))
              .toList(growable: false);
          AdvancedFilterPerfLogger.write(
            '[AdvancedFilterPerf][sync] incremental:fetchByIds '
            'ms=${fetchWatch.elapsedMilliseconds} requested=${refreshIds.length} '
            'returned=${items.length} missing=${missingIds.length}',
          );

          if (items.isNotEmpty) {
            final upsertWatch = Stopwatch()..start();
            await _repository.upsertItems(
              serverId: _serverId,
              userId: _userId,
              items: items,
            );
            upsertWatch.stop();
            AdvancedFilterPerfLogger.write(
              '[AdvancedFilterPerf][sync] incremental:upsertItems '
              'ms=${upsertWatch.elapsedMilliseconds} count=${items.length}',
            );
          }

          if (missingIds.isNotEmpty) {
            final missingWatch = Stopwatch()..start();
            await _repository.removeItems(
              serverId: _serverId,
              userId: _userId,
              itemIds: missingIds,
            );
            missingWatch.stop();
            AdvancedFilterPerfLogger.write(
              '[AdvancedFilterPerf][sync] incremental:removeMissing '
              'ms=${missingWatch.elapsedMilliseconds} count=${missingIds.length}',
            );
          }
        }

        _notifyCatalogChanged();
      }
    } finally {
      _incrementalFlushRunning = false;
      flushWatch.stop();
      AdvancedFilterPerfLogger.write(
        '[AdvancedFilterPerf][sync] incremental:flushDone '
        'ms=${flushWatch.elapsedMilliseconds}',
      );
    }
  }

  Future<List<AggregatedItem>> _fetchFullCatalog({
    AdvancedFilterCatalogProgress? onProgress,
  }) async {
    if (_client.serverType == ServerType.emby) {
      return _fetchFullCatalogByEmbyLibraries(onProgress: onProgress);
    }

    final items = <AggregatedItem>[];
    var startIndex = 0;
    int? total;

    while (true) {
      final pageWatch = Stopwatch()..start();
      final response = await _client.itemsApi.getItems(
        includeItemTypes: AdvancedFilterCatalogConstants.mediaTypes,
        recursive: true,
        fields: AdvancedFilterCatalogConstants.itemFields,
        sortBy: 'SortName',
        sortOrder: 'Ascending',
        startIndex: startIndex,
        limit: AdvancedFilterCatalogConstants.pageSize,
        enableTotalRecordCount: true,
        enableImageTypes: 'Primary,Backdrop,Thumb',
      );

      total ??= _readTotal(response['TotalRecordCount']);
      final pageItems = response['Items'] as List? ?? const [];
      pageWatch.stop();
      if (pageItems.isEmpty) break;

      items.addAll(_parseItems(pageItems));
      startIndex += pageItems.length;
      AdvancedFilterPerfLogger.write(
        '[AdvancedFilterPerf][sync] fullRefresh:page '
        'pageMs=${pageWatch.elapsedMilliseconds} loaded=$startIndex '
        'pageItems=${pageItems.length} total=$total',
      );
      onProgress?.call(startIndex, total);

      if (pageItems.length < AdvancedFilterCatalogConstants.pageSize) break;
      if (total != null && startIndex >= total) break;
    }

    items.sort((a, b) => _compareText(a.name, b.name));
    return items;
  }

  Future<List<AggregatedItem>> _fetchFullCatalogByEmbyLibraries({
    AdvancedFilterCatalogProgress? onProgress,
  }) async {
    final libraries = await _loadEmbyMediaLibraries();
    if (libraries.isEmpty) {
      AdvancedFilterPerfLogger.write(
        '[AdvancedFilterPerf][sync] fullRefresh:embyLibraries empty=true fallbackGlobal=true',
      );
      return _fetchFullCatalogGlobally(onProgress: onProgress);
    }

    final byId = <String, AggregatedItem>{};
    var loaded = 0;
    for (final library in libraries) {
      var startIndex = 0;
      int? total;

      while (true) {
        final pageWatch = Stopwatch()..start();
        final response = await _client.itemsApi.getItems(
          parentId: library.id,
          includeItemTypes: AdvancedFilterCatalogConstants.mediaTypes,
          recursive: true,
          fields: AdvancedFilterCatalogConstants.itemFields,
          sortBy: 'SortName',
          sortOrder: 'Ascending',
          startIndex: startIndex,
          limit: AdvancedFilterCatalogConstants.pageSize,
          enableTotalRecordCount: true,
          enableImageTypes: 'Primary,Backdrop,Thumb',
        );

        total ??= _readTotal(response['TotalRecordCount']);
        final pageItems = response['Items'] as List? ?? const [];
        pageWatch.stop();
        if (pageItems.isEmpty) break;

        final parsed = _parseItems(
          pageItems,
          libraryId: library.id,
          libraryName: library.name,
        );
        for (final item in parsed) {
          byId[item.id] = item;
        }
        startIndex += pageItems.length;
        loaded += pageItems.length;
        AdvancedFilterPerfLogger.write(
          '[AdvancedFilterPerf][sync] fullRefresh:embyLibraryPage '
          'library="${library.name}" libraryId=${library.id} '
          'pageMs=${pageWatch.elapsedMilliseconds} libraryLoaded=$startIndex '
          'pageItems=${pageItems.length} libraryTotal=$total loaded=$loaded',
        );
        onProgress?.call(loaded, null);

        if (pageItems.length < AdvancedFilterCatalogConstants.pageSize) break;
        if (total != null && startIndex >= total) break;
      }
    }

    final items = byId.values.toList()
      ..sort((a, b) => _compareText(a.name, b.name));
    return items;
  }

  Future<List<AggregatedItem>> _fetchFullCatalogGlobally({
    AdvancedFilterCatalogProgress? onProgress,
  }) async {
    final items = <AggregatedItem>[];
    var startIndex = 0;
    int? total;

    while (true) {
      final pageWatch = Stopwatch()..start();
      final response = await _client.itemsApi.getItems(
        includeItemTypes: AdvancedFilterCatalogConstants.mediaTypes,
        recursive: true,
        fields: AdvancedFilterCatalogConstants.itemFields,
        sortBy: 'SortName',
        sortOrder: 'Ascending',
        startIndex: startIndex,
        limit: AdvancedFilterCatalogConstants.pageSize,
        enableTotalRecordCount: true,
        enableImageTypes: 'Primary,Backdrop,Thumb',
      );

      total ??= _readTotal(response['TotalRecordCount']);
      final pageItems = response['Items'] as List? ?? const [];
      pageWatch.stop();
      if (pageItems.isEmpty) break;

      items.addAll(_parseItems(pageItems));
      startIndex += pageItems.length;
      AdvancedFilterPerfLogger.write(
        '[AdvancedFilterPerf][sync] fullRefresh:fallbackPage '
        'pageMs=${pageWatch.elapsedMilliseconds} loaded=$startIndex '
        'pageItems=${pageItems.length} total=$total',
      );
      onProgress?.call(startIndex, total);

      if (pageItems.length < AdvancedFilterCatalogConstants.pageSize) break;
      if (total != null && startIndex >= total) break;
    }

    items.sort((a, b) => _compareText(a.name, b.name));
    return items;
  }

  Future<List<AggregatedItem>> _fetchItemsByIds(List<String> itemIds) async {
    final items = <AggregatedItem>[];

    for (
      var start = 0;
      start < itemIds.length;
      start += _incrementalBatchSize
    ) {
      final end = (start + _incrementalBatchSize)
          .clamp(0, itemIds.length)
          .toInt();
      final chunk = itemIds.sublist(start, end);
      final response = await _client.itemsApi.getItems(
        ids: chunk,
        includeItemTypes: AdvancedFilterCatalogConstants.mediaTypes,
        recursive: true,
        fields: AdvancedFilterCatalogConstants.itemFields,
        limit: chunk.length,
        enableTotalRecordCount: false,
        enableImageTypes: 'Primary,Backdrop,Thumb',
      );
      items.addAll(_parseItems(response['Items'] as List? ?? const []));
    }

    return items;
  }

  List<AggregatedItem> _parseItems(
    List rawItems, {
    String? libraryId,
    String? libraryName,
  }) {
    final items = <AggregatedItem>[];
    for (final item in rawItems) {
      if (item is! Map) continue;
      final data = Map<String, dynamic>.from(item);
      if (libraryId != null && libraryId.isNotEmpty) {
        data[AdvancedFilterCatalogConstants.embyLibraryIdField] = libraryId;
      }
      if (libraryName != null && libraryName.isNotEmpty) {
        data[AdvancedFilterCatalogConstants.embyLibraryNameField] = libraryName;
      }
      final id = data['Id'] as String?;
      final type = data['Type'] as String?;
      if (id == null || id.isEmpty) continue;
      if (!AdvancedFilterCatalogConstants.mediaTypes.contains(type)) continue;
      items.add(
        AggregatedItem(
          id: id,
          serverId: data['ServerId'] as String? ?? _serverId,
          rawData: data,
        ),
      );
    }
    return items;
  }

  Future<List<_EmbyLibrary>> _loadEmbyMediaLibraries() async {
    try {
      final response = await _client.userViewsApi.getUserViews();
      final rawViews = response['Items'] as List? ?? const [];
      final libraries = <_EmbyLibrary>[];
      for (final rawView in rawViews) {
        if (rawView is! Map) continue;
        final data = Map<String, dynamic>.from(rawView);
        final id = (data['Id'] as String?)?.trim();
        final name = (data['Name'] as String?)?.trim();
        if (id == null || id.isEmpty || name == null || name.isEmpty) continue;

        final collectionType = (data['CollectionType'] as String?)
            ?.trim()
            .toLowerCase();
        if (collectionType == 'playlists' ||
            collectionType == 'boxsets' ||
            collectionType == 'livetv') {
          continue;
        }

        libraries.add(_EmbyLibrary(id: id, name: name));
      }
      libraries.sort((a, b) => _compareText(a.name, b.name));
      return libraries;
    } catch (error) {
      AdvancedFilterPerfLogger.write(
        '[AdvancedFilterPerf][sync] loadEmbyLibraries:error $error',
      );
      return const [];
    }
  }

  int? _readTotal(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  void _notifyCatalogChanged() {
    if (_disposed || _catalogChangedController.isClosed) return;
    _catalogChangedController.add(null);
  }

  void dispose() {
    _disposed = true;
    _incrementalTimer?.cancel();
    _incrementalTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _catalogChangedController.close();
  }

  static int _compareText(String a, String b) {
    final lower = a.toLowerCase().compareTo(b.toLowerCase());
    if (lower != 0) return lower;
    return a.compareTo(b);
  }
}

class _EmbyLibrary {
  final String id;
  final String name;

  const _EmbyLibrary({required this.id, required this.name});
}
