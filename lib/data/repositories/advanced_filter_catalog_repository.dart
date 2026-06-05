import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/offline_database.dart';
import '../models/aggregated_item.dart';

class AdvancedFilterCatalogSnapshot {
  final List<AggregatedItem> items;
  final DateTime? syncedAt;
  final int itemCount;

  const AdvancedFilterCatalogSnapshot({
    required this.items,
    required this.syncedAt,
    required this.itemCount,
  });
}

class AdvancedFilterCatalogRepository {
  static const cacheVersion = 1;
  static const defaultMaxAge = Duration(hours: 24);

  final OfflineDatabase _db;

  AdvancedFilterCatalogRepository(this._db);

  bool isExpired(
    AdvancedFilterCatalogSnapshot snapshot, {
    Duration maxAge = defaultMaxAge,
  }) {
    final syncedAt = snapshot.syncedAt;
    if (syncedAt == null) return true;
    return DateTime.now().toUtc().difference(syncedAt.toUtc()) >= maxAge;
  }

  Future<bool> hasScope({
    required String serverId,
    required String userId,
  }) async {
    final state =
        await (_db.select(_db.advancedFilterCatalogSyncStates)..where(
              (t) => t.serverId.equals(serverId) & t.userId.equals(userId),
            ))
            .getSingleOrNull();

    if (state != null && state.cacheVersion != cacheVersion) {
      await clearScope(serverId: serverId, userId: userId);
      return false;
    }

    return state != null;
  }

  Future<AdvancedFilterCatalogSnapshot?> loadSnapshot({
    required String serverId,
    required String userId,
  }) async {
    final state =
        await (_db.select(_db.advancedFilterCatalogSyncStates)..where(
              (t) => t.serverId.equals(serverId) & t.userId.equals(userId),
            ))
            .getSingleOrNull();

    if (state != null && state.cacheVersion != cacheVersion) {
      await clearScope(serverId: serverId, userId: userId);
      return null;
    }

    final rows =
        await (_db.select(_db.advancedFilterCatalogItems)
              ..where(
                (t) => t.serverId.equals(serverId) & t.userId.equals(userId),
              )
              ..orderBy([
                (t) => OrderingTerm.asc(t.sortName),
                (t) => OrderingTerm.asc(t.name),
              ]))
            .get();

    if (rows.isEmpty) {
      if (state != null && state.itemCount == 0) {
        return AdvancedFilterCatalogSnapshot(
          items: const [],
          syncedAt: state.syncedAt,
          itemCount: 0,
        );
      }
      return null;
    }

    final items = <AggregatedItem>[];
    for (final row in rows) {
      try {
        final raw = jsonDecode(row.metadataJson);
        if (raw is! Map<String, dynamic>) continue;
        items.add(
          AggregatedItem(id: row.itemId, serverId: row.serverId, rawData: raw),
        );
      } catch (_) {
        continue;
      }
    }

    if (items.isEmpty && (state?.itemCount ?? 0) > 0) return null;

    return AdvancedFilterCatalogSnapshot(
      items: items,
      syncedAt: state?.syncedAt,
      itemCount: state?.itemCount ?? items.length,
    );
  }

  Future<void> replaceScope({
    required String serverId,
    required String userId,
    required List<AggregatedItem> items,
    DateTime? syncedAt,
  }) async {
    final cachedAt = (syncedAt ?? DateTime.now()).toUtc();

    await _db.transaction(() async {
      await clearScope(serverId: serverId, userId: userId);

      await _db.batch((batch) {
        batch.insertAllOnConflictUpdate(_db.advancedFilterCatalogItems, [
          for (final item in items)
            AdvancedFilterCatalogItemsCompanion(
              serverId: Value(serverId),
              userId: Value(userId),
              itemId: Value(item.id),
              type: Value(item.type ?? ''),
              name: Value(item.name),
              sortName: Value(_sortNameFor(item)),
              productionYear: Value(item.productionYear),
              metadataJson: Value(jsonEncode(item.rawData)),
              cachedAt: Value(cachedAt),
            ),
        ]);

        batch.insertAllOnConflictUpdate(_db.advancedFilterCatalogItemGenres, [
          for (final item in items)
            for (final genre in _stringValues(item.rawData['Genres']))
              AdvancedFilterCatalogItemGenresCompanion(
                serverId: Value(serverId),
                userId: Value(userId),
                itemId: Value(item.id),
                genre: Value(genre),
              ),
        ]);

        batch.insertAllOnConflictUpdate(_db.advancedFilterCatalogItemRegions, [
          for (final item in items)
            for (final region in _stringValues(
              item.rawData['ProductionLocations'],
            ))
              AdvancedFilterCatalogItemRegionsCompanion(
                serverId: Value(serverId),
                userId: Value(userId),
                itemId: Value(item.id),
                region: Value(region),
              ),
        ]);

        batch.insertAll(_db.advancedFilterCatalogSyncStates, [
          AdvancedFilterCatalogSyncStatesCompanion(
            serverId: Value(serverId),
            userId: Value(userId),
            cacheVersion: const Value(cacheVersion),
            itemCount: Value(items.length),
            syncedAt: Value(cachedAt),
          ),
        ]);
      });
    });
  }

  Future<void> upsertItems({
    required String serverId,
    required String userId,
    required List<AggregatedItem> items,
  }) async {
    if (items.isEmpty) return;

    final itemIds = items.map((item) => item.id).toSet().toList();
    final cachedAt = DateTime.now().toUtc();

    await _db.transaction(() async {
      await _deleteItemsByIds(
        serverId: serverId,
        userId: userId,
        itemIds: itemIds,
      );

      await _db.batch((batch) {
        batch.insertAllOnConflictUpdate(
          _db.advancedFilterCatalogItems,
          _itemCompanions(serverId, userId, items, cachedAt),
        );

        batch.insertAllOnConflictUpdate(
          _db.advancedFilterCatalogItemGenres,
          _genreCompanions(serverId, userId, items),
        );

        batch.insertAllOnConflictUpdate(
          _db.advancedFilterCatalogItemRegions,
          _regionCompanions(serverId, userId, items),
        );
      });

      await _upsertSyncState(
        serverId: serverId,
        userId: userId,
        syncedAt: cachedAt,
      );
    });
  }

  Future<void> removeItems({
    required String serverId,
    required String userId,
    required List<String> itemIds,
  }) async {
    final ids = itemIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (ids.isEmpty) return;

    final cachedAt = DateTime.now().toUtc();

    await _db.transaction(() async {
      await _deleteItemsByIds(serverId: serverId, userId: userId, itemIds: ids);

      await _upsertSyncState(
        serverId: serverId,
        userId: userId,
        syncedAt: cachedAt,
      );
    });
  }

  Future<void> clearScope({
    required String serverId,
    required String userId,
  }) async {
    await (_db.delete(_db.advancedFilterCatalogItemGenres)
          ..where((t) => t.serverId.equals(serverId) & t.userId.equals(userId)))
        .go();
    await (_db.delete(_db.advancedFilterCatalogItemRegions)
          ..where((t) => t.serverId.equals(serverId) & t.userId.equals(userId)))
        .go();
    await (_db.delete(_db.advancedFilterCatalogItems)
          ..where((t) => t.serverId.equals(serverId) & t.userId.equals(userId)))
        .go();
    await (_db.delete(_db.advancedFilterCatalogSyncStates)
          ..where((t) => t.serverId.equals(serverId) & t.userId.equals(userId)))
        .go();
  }

  List<AdvancedFilterCatalogItemsCompanion> _itemCompanions(
    String serverId,
    String userId,
    List<AggregatedItem> items,
    DateTime cachedAt,
  ) {
    return [
      for (final item in items)
        AdvancedFilterCatalogItemsCompanion(
          serverId: Value(serverId),
          userId: Value(userId),
          itemId: Value(item.id),
          type: Value(item.type ?? ''),
          name: Value(item.name),
          sortName: Value(_sortNameFor(item)),
          productionYear: Value(item.productionYear),
          metadataJson: Value(jsonEncode(item.rawData)),
          cachedAt: Value(cachedAt),
        ),
    ];
  }

  List<AdvancedFilterCatalogItemGenresCompanion> _genreCompanions(
    String serverId,
    String userId,
    List<AggregatedItem> items,
  ) {
    return [
      for (final item in items)
        for (final genre in _stringValues(item.rawData['Genres']))
          AdvancedFilterCatalogItemGenresCompanion(
            serverId: Value(serverId),
            userId: Value(userId),
            itemId: Value(item.id),
            genre: Value(genre),
          ),
    ];
  }

  List<AdvancedFilterCatalogItemRegionsCompanion> _regionCompanions(
    String serverId,
    String userId,
    List<AggregatedItem> items,
  ) {
    return [
      for (final item in items)
        for (final region in _stringValues(item.rawData['ProductionLocations']))
          AdvancedFilterCatalogItemRegionsCompanion(
            serverId: Value(serverId),
            userId: Value(userId),
            itemId: Value(item.id),
            region: Value(region),
          ),
    ];
  }

  Future<void> _deleteItemsByIds({
    required String serverId,
    required String userId,
    required List<String> itemIds,
  }) async {
    await (_db.delete(_db.advancedFilterCatalogItemGenres)..where(
          (t) =>
              t.serverId.equals(serverId) &
              t.userId.equals(userId) &
              t.itemId.isIn(itemIds),
        ))
        .go();
    await (_db.delete(_db.advancedFilterCatalogItemRegions)..where(
          (t) =>
              t.serverId.equals(serverId) &
              t.userId.equals(userId) &
              t.itemId.isIn(itemIds),
        ))
        .go();
    await (_db.delete(_db.advancedFilterCatalogItems)..where(
          (t) =>
              t.serverId.equals(serverId) &
              t.userId.equals(userId) &
              t.itemId.isIn(itemIds),
        ))
        .go();
  }

  Future<void> _upsertSyncState({
    required String serverId,
    required String userId,
    required DateTime syncedAt,
  }) async {
    final itemCount = await _countScopeItems(
      serverId: serverId,
      userId: userId,
    );
    await _db
        .into(_db.advancedFilterCatalogSyncStates)
        .insertOnConflictUpdate(
          AdvancedFilterCatalogSyncStatesCompanion(
            serverId: Value(serverId),
            userId: Value(userId),
            cacheVersion: const Value(cacheVersion),
            itemCount: Value(itemCount),
            syncedAt: Value(syncedAt),
          ),
        );
  }

  Future<int> _countScopeItems({
    required String serverId,
    required String userId,
  }) async {
    final countExpression = _db.advancedFilterCatalogItems.itemId.count();
    final query = _db.selectOnly(_db.advancedFilterCatalogItems)
      ..addColumns([countExpression])
      ..where(
        _db.advancedFilterCatalogItems.serverId.equals(serverId) &
            _db.advancedFilterCatalogItems.userId.equals(userId),
      );

    final row = await query.getSingle();
    return row.read(countExpression) ?? 0;
  }

  String _sortNameFor(AggregatedItem item) {
    final rawSortName = item.rawData['SortName'] as String?;
    final sortName = rawSortName?.trim();
    if (sortName != null && sortName.isNotEmpty) return sortName.toLowerCase();
    return item.name.toLowerCase();
  }

  List<String> _stringValues(dynamic value) {
    if (value is! List) return const [];
    final result = <String>[];
    for (final raw in value) {
      final normalized = raw.toString().trim();
      if (normalized.isNotEmpty) result.add(normalized);
    }
    return result;
  }
}
