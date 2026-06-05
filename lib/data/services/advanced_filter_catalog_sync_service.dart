import 'dart:async';

import 'package:server_core/server_core.dart';

import '../models/aggregated_item.dart';
import '../repositories/advanced_filter_catalog_repository.dart';
import 'advanced_filter_catalog_constants.dart';

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
    _subscription = _events.listen((message) {
      unawaited(_handleMessage(message));
    });
  }

  Future<List<AggregatedItem>> refreshCatalog({
    AdvancedFilterCatalogProgress? onProgress,
  }) {
    final existing = _fullRefreshFuture;
    if (existing != null) return existing;

    final future = _fetchFullCatalog(onProgress: onProgress).then((
      items,
    ) async {
      await _repository.replaceScope(
        serverId: _serverId,
        userId: _userId,
        items: items,
      );
      _notifyCatalogChanged();
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
    final current =
        snapshot ??
        await _repository.loadSnapshot(serverId: _serverId, userId: _userId);
    if (current == null || !_repository.isExpired(current, maxAge: maxAge)) {
      return null;
    }
    return refreshCatalog();
  }

  Future<void> _handleMessage(ServerWebSocketMessage message) async {
    if (!await _repository.hasScope(serverId: _serverId, userId: _userId)) {
      return;
    }

    switch (message) {
      case LibraryChangedMessage():
        final removed = message.itemsRemoved.toSet();
        final changed = <String>{...message.itemsAdded, ...message.itemsUpdated}
          ..removeAll(removed);
        _queueIncremental(refreshIds: changed, removeIds: removed);
      case UserDataChangedMessage():
        if (message.userId.trim() == _userId) {
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
    _incrementalTimer = Timer(_incrementalDebounce, () {
      unawaited(_flushIncremental());
    });
  }

  Future<void> _flushIncremental() async {
    if (_incrementalFlushRunning || _disposed) return;
    _incrementalFlushRunning = true;

    try {
      while (!_disposed) {
        final removeIds = _pendingRemoveIds.toList();
        final refreshIds = _pendingRefreshIds.toList()
          ..removeWhere(removeIds.contains);
        _pendingRemoveIds.clear();
        _pendingRefreshIds.clear();

        if (removeIds.isEmpty && refreshIds.isEmpty) break;

        if (removeIds.isNotEmpty) {
          await _repository.removeItems(
            serverId: _serverId,
            userId: _userId,
            itemIds: removeIds,
          );
        }

        if (refreshIds.isNotEmpty) {
          final items = await _fetchItemsByIds(refreshIds);
          final returnedIds = items.map((item) => item.id).toSet();
          final missingIds = refreshIds
              .where((id) => !returnedIds.contains(id))
              .toList(growable: false);

          if (items.isNotEmpty) {
            await _repository.upsertItems(
              serverId: _serverId,
              userId: _userId,
              items: items,
            );
          }

          if (missingIds.isNotEmpty) {
            await _repository.removeItems(
              serverId: _serverId,
              userId: _userId,
              itemIds: missingIds,
            );
          }
        }

        _notifyCatalogChanged();
      }
    } finally {
      _incrementalFlushRunning = false;
    }
  }

  Future<List<AggregatedItem>> _fetchFullCatalog({
    AdvancedFilterCatalogProgress? onProgress,
  }) async {
    final items = <AggregatedItem>[];
    var startIndex = 0;
    int? total;

    while (true) {
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
      if (pageItems.isEmpty) break;

      items.addAll(_parseItems(pageItems));
      startIndex += pageItems.length;
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

  List<AggregatedItem> _parseItems(List rawItems) {
    final items = <AggregatedItem>[];
    for (final item in rawItems) {
      if (item is! Map) continue;
      final data = Map<String, dynamic>.from(item);
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
