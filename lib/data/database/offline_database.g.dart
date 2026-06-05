// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_database.dart';

// ignore_for_file: type=lint
class $DownloadedItemsTable extends DownloadedItems
    with TableInfo<$DownloadedItemsTable, DownloadedItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadedItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localFilePathMeta = const VerificationMeta(
    'localFilePath',
  );
  @override
  late final GeneratedColumn<String> localFilePath = GeneratedColumn<String>(
    'local_file_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metadataJsonMeta = const VerificationMeta(
    'metadataJson',
  );
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
    'metadata_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _posterPathMeta = const VerificationMeta(
    'posterPath',
  );
  @override
  late final GeneratedColumn<String> posterPath = GeneratedColumn<String>(
    'poster_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _backdropPathMeta = const VerificationMeta(
    'backdropPath',
  );
  @override
  late final GeneratedColumn<String> backdropPath = GeneratedColumn<String>(
    'backdrop_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _logoPathMeta = const VerificationMeta(
    'logoPath',
  );
  @override
  late final GeneratedColumn<String> logoPath = GeneratedColumn<String>(
    'logo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbPathMeta = const VerificationMeta(
    'thumbPath',
  );
  @override
  late final GeneratedColumn<String> thumbPath = GeneratedColumn<String>(
    'thumb_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _downloadStatusMeta = const VerificationMeta(
    'downloadStatus',
  );
  @override
  late final GeneratedColumn<int> downloadStatus = GeneratedColumn<int>(
    'download_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _downloadProgressMeta = const VerificationMeta(
    'downloadProgress',
  );
  @override
  late final GeneratedColumn<double> downloadProgress = GeneratedColumn<double>(
    'download_progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileSizeBytesMeta = const VerificationMeta(
    'fileSizeBytes',
  );
  @override
  late final GeneratedColumn<int> fileSizeBytes = GeneratedColumn<int>(
    'file_size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _playbackPositionTicksMeta =
      const VerificationMeta('playbackPositionTicks');
  @override
  late final GeneratedColumn<int> playbackPositionTicks = GeneratedColumn<int>(
    'playback_position_ticks',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _progressSyncedMeta = const VerificationMeta(
    'progressSynced',
  );
  @override
  late final GeneratedColumn<bool> progressSynced = GeneratedColumn<bool>(
    'progress_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("progress_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _downloadedAtMeta = const VerificationMeta(
    'downloadedAt',
  );
  @override
  late final GeneratedColumn<DateTime> downloadedAt = GeneratedColumn<DateTime>(
    'downloaded_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _qualityPresetMeta = const VerificationMeta(
    'qualityPreset',
  );
  @override
  late final GeneratedColumn<String> qualityPreset = GeneratedColumn<String>(
    'quality_preset',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('original'),
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
    'series_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seasonIdMeta = const VerificationMeta(
    'seasonId',
  );
  @override
  late final GeneratedColumn<String> seasonId = GeneratedColumn<String>(
    'season_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seriesNameMeta = const VerificationMeta(
    'seriesName',
  );
  @override
  late final GeneratedColumn<String> seriesName = GeneratedColumn<String>(
    'series_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seasonNameMeta = const VerificationMeta(
    'seasonName',
  );
  @override
  late final GeneratedColumn<String> seasonName = GeneratedColumn<String>(
    'season_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _indexNumberMeta = const VerificationMeta(
    'indexNumber',
  );
  @override
  late final GeneratedColumn<int> indexNumber = GeneratedColumn<int>(
    'index_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parentIndexNumberMeta = const VerificationMeta(
    'parentIndexNumber',
  );
  @override
  late final GeneratedColumn<int> parentIndexNumber = GeneratedColumn<int>(
    'parent_index_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    itemId,
    serverId,
    type,
    name,
    localFilePath,
    metadataJson,
    posterPath,
    backdropPath,
    logoPath,
    thumbPath,
    downloadStatus,
    downloadProgress,
    errorMessage,
    fileSizeBytes,
    playbackPositionTicks,
    progressSynced,
    downloadedAt,
    qualityPreset,
    seriesId,
    seasonId,
    seriesName,
    seasonName,
    indexNumber,
    parentIndexNumber,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloaded_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadedItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('local_file_path')) {
      context.handle(
        _localFilePathMeta,
        localFilePath.isAcceptableOrUnknown(
          data['local_file_path']!,
          _localFilePathMeta,
        ),
      );
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
        _metadataJsonMeta,
        metadataJson.isAcceptableOrUnknown(
          data['metadata_json']!,
          _metadataJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_metadataJsonMeta);
    }
    if (data.containsKey('poster_path')) {
      context.handle(
        _posterPathMeta,
        posterPath.isAcceptableOrUnknown(data['poster_path']!, _posterPathMeta),
      );
    }
    if (data.containsKey('backdrop_path')) {
      context.handle(
        _backdropPathMeta,
        backdropPath.isAcceptableOrUnknown(
          data['backdrop_path']!,
          _backdropPathMeta,
        ),
      );
    }
    if (data.containsKey('logo_path')) {
      context.handle(
        _logoPathMeta,
        logoPath.isAcceptableOrUnknown(data['logo_path']!, _logoPathMeta),
      );
    }
    if (data.containsKey('thumb_path')) {
      context.handle(
        _thumbPathMeta,
        thumbPath.isAcceptableOrUnknown(data['thumb_path']!, _thumbPathMeta),
      );
    }
    if (data.containsKey('download_status')) {
      context.handle(
        _downloadStatusMeta,
        downloadStatus.isAcceptableOrUnknown(
          data['download_status']!,
          _downloadStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_downloadStatusMeta);
    }
    if (data.containsKey('download_progress')) {
      context.handle(
        _downloadProgressMeta,
        downloadProgress.isAcceptableOrUnknown(
          data['download_progress']!,
          _downloadProgressMeta,
        ),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
        _fileSizeBytesMeta,
        fileSizeBytes.isAcceptableOrUnknown(
          data['file_size_bytes']!,
          _fileSizeBytesMeta,
        ),
      );
    }
    if (data.containsKey('playback_position_ticks')) {
      context.handle(
        _playbackPositionTicksMeta,
        playbackPositionTicks.isAcceptableOrUnknown(
          data['playback_position_ticks']!,
          _playbackPositionTicksMeta,
        ),
      );
    }
    if (data.containsKey('progress_synced')) {
      context.handle(
        _progressSyncedMeta,
        progressSynced.isAcceptableOrUnknown(
          data['progress_synced']!,
          _progressSyncedMeta,
        ),
      );
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
        _downloadedAtMeta,
        downloadedAt.isAcceptableOrUnknown(
          data['downloaded_at']!,
          _downloadedAtMeta,
        ),
      );
    }
    if (data.containsKey('quality_preset')) {
      context.handle(
        _qualityPresetMeta,
        qualityPreset.isAcceptableOrUnknown(
          data['quality_preset']!,
          _qualityPresetMeta,
        ),
      );
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    }
    if (data.containsKey('season_id')) {
      context.handle(
        _seasonIdMeta,
        seasonId.isAcceptableOrUnknown(data['season_id']!, _seasonIdMeta),
      );
    }
    if (data.containsKey('series_name')) {
      context.handle(
        _seriesNameMeta,
        seriesName.isAcceptableOrUnknown(data['series_name']!, _seriesNameMeta),
      );
    }
    if (data.containsKey('season_name')) {
      context.handle(
        _seasonNameMeta,
        seasonName.isAcceptableOrUnknown(data['season_name']!, _seasonNameMeta),
      );
    }
    if (data.containsKey('index_number')) {
      context.handle(
        _indexNumberMeta,
        indexNumber.isAcceptableOrUnknown(
          data['index_number']!,
          _indexNumberMeta,
        ),
      );
    }
    if (data.containsKey('parent_index_number')) {
      context.handle(
        _parentIndexNumberMeta,
        parentIndexNumber.isAcceptableOrUnknown(
          data['parent_index_number']!,
          _parentIndexNumberMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId, serverId};
  @override
  DownloadedItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadedItem(
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      localFilePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_file_path'],
      ),
      metadataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_json'],
      )!,
      posterPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poster_path'],
      ),
      backdropPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backdrop_path'],
      ),
      logoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logo_path'],
      ),
      thumbPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumb_path'],
      ),
      downloadStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}download_status'],
      )!,
      downloadProgress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}download_progress'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      fileSizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size_bytes'],
      )!,
      playbackPositionTicks: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}playback_position_ticks'],
      )!,
      progressSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}progress_synced'],
      )!,
      downloadedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}downloaded_at'],
      ),
      qualityPreset: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quality_preset'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_id'],
      ),
      seasonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}season_id'],
      ),
      seriesName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_name'],
      ),
      seasonName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}season_name'],
      ),
      indexNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}index_number'],
      ),
      parentIndexNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parent_index_number'],
      ),
    );
  }

  @override
  $DownloadedItemsTable createAlias(String alias) {
    return $DownloadedItemsTable(attachedDatabase, alias);
  }
}

class DownloadedItem extends DataClass implements Insertable<DownloadedItem> {
  final String itemId;
  final String serverId;
  final String type;
  final String name;
  final String? localFilePath;
  final String metadataJson;
  final String? posterPath;
  final String? backdropPath;
  final String? logoPath;
  final String? thumbPath;
  final int downloadStatus;
  final double downloadProgress;
  final String? errorMessage;
  final int fileSizeBytes;
  final int playbackPositionTicks;
  final bool progressSynced;
  final DateTime? downloadedAt;
  final String qualityPreset;
  final String? seriesId;
  final String? seasonId;
  final String? seriesName;
  final String? seasonName;
  final int? indexNumber;
  final int? parentIndexNumber;
  const DownloadedItem({
    required this.itemId,
    required this.serverId,
    required this.type,
    required this.name,
    this.localFilePath,
    required this.metadataJson,
    this.posterPath,
    this.backdropPath,
    this.logoPath,
    this.thumbPath,
    required this.downloadStatus,
    required this.downloadProgress,
    this.errorMessage,
    required this.fileSizeBytes,
    required this.playbackPositionTicks,
    required this.progressSynced,
    this.downloadedAt,
    required this.qualityPreset,
    this.seriesId,
    this.seasonId,
    this.seriesName,
    this.seasonName,
    this.indexNumber,
    this.parentIndexNumber,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<String>(itemId);
    map['server_id'] = Variable<String>(serverId);
    map['type'] = Variable<String>(type);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || localFilePath != null) {
      map['local_file_path'] = Variable<String>(localFilePath);
    }
    map['metadata_json'] = Variable<String>(metadataJson);
    if (!nullToAbsent || posterPath != null) {
      map['poster_path'] = Variable<String>(posterPath);
    }
    if (!nullToAbsent || backdropPath != null) {
      map['backdrop_path'] = Variable<String>(backdropPath);
    }
    if (!nullToAbsent || logoPath != null) {
      map['logo_path'] = Variable<String>(logoPath);
    }
    if (!nullToAbsent || thumbPath != null) {
      map['thumb_path'] = Variable<String>(thumbPath);
    }
    map['download_status'] = Variable<int>(downloadStatus);
    map['download_progress'] = Variable<double>(downloadProgress);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['file_size_bytes'] = Variable<int>(fileSizeBytes);
    map['playback_position_ticks'] = Variable<int>(playbackPositionTicks);
    map['progress_synced'] = Variable<bool>(progressSynced);
    if (!nullToAbsent || downloadedAt != null) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt);
    }
    map['quality_preset'] = Variable<String>(qualityPreset);
    if (!nullToAbsent || seriesId != null) {
      map['series_id'] = Variable<String>(seriesId);
    }
    if (!nullToAbsent || seasonId != null) {
      map['season_id'] = Variable<String>(seasonId);
    }
    if (!nullToAbsent || seriesName != null) {
      map['series_name'] = Variable<String>(seriesName);
    }
    if (!nullToAbsent || seasonName != null) {
      map['season_name'] = Variable<String>(seasonName);
    }
    if (!nullToAbsent || indexNumber != null) {
      map['index_number'] = Variable<int>(indexNumber);
    }
    if (!nullToAbsent || parentIndexNumber != null) {
      map['parent_index_number'] = Variable<int>(parentIndexNumber);
    }
    return map;
  }

  DownloadedItemsCompanion toCompanion(bool nullToAbsent) {
    return DownloadedItemsCompanion(
      itemId: Value(itemId),
      serverId: Value(serverId),
      type: Value(type),
      name: Value(name),
      localFilePath: localFilePath == null && nullToAbsent
          ? const Value.absent()
          : Value(localFilePath),
      metadataJson: Value(metadataJson),
      posterPath: posterPath == null && nullToAbsent
          ? const Value.absent()
          : Value(posterPath),
      backdropPath: backdropPath == null && nullToAbsent
          ? const Value.absent()
          : Value(backdropPath),
      logoPath: logoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(logoPath),
      thumbPath: thumbPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbPath),
      downloadStatus: Value(downloadStatus),
      downloadProgress: Value(downloadProgress),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      fileSizeBytes: Value(fileSizeBytes),
      playbackPositionTicks: Value(playbackPositionTicks),
      progressSynced: Value(progressSynced),
      downloadedAt: downloadedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(downloadedAt),
      qualityPreset: Value(qualityPreset),
      seriesId: seriesId == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesId),
      seasonId: seasonId == null && nullToAbsent
          ? const Value.absent()
          : Value(seasonId),
      seriesName: seriesName == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesName),
      seasonName: seasonName == null && nullToAbsent
          ? const Value.absent()
          : Value(seasonName),
      indexNumber: indexNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(indexNumber),
      parentIndexNumber: parentIndexNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(parentIndexNumber),
    );
  }

  factory DownloadedItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadedItem(
      itemId: serializer.fromJson<String>(json['itemId']),
      serverId: serializer.fromJson<String>(json['serverId']),
      type: serializer.fromJson<String>(json['type']),
      name: serializer.fromJson<String>(json['name']),
      localFilePath: serializer.fromJson<String?>(json['localFilePath']),
      metadataJson: serializer.fromJson<String>(json['metadataJson']),
      posterPath: serializer.fromJson<String?>(json['posterPath']),
      backdropPath: serializer.fromJson<String?>(json['backdropPath']),
      logoPath: serializer.fromJson<String?>(json['logoPath']),
      thumbPath: serializer.fromJson<String?>(json['thumbPath']),
      downloadStatus: serializer.fromJson<int>(json['downloadStatus']),
      downloadProgress: serializer.fromJson<double>(json['downloadProgress']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      fileSizeBytes: serializer.fromJson<int>(json['fileSizeBytes']),
      playbackPositionTicks: serializer.fromJson<int>(
        json['playbackPositionTicks'],
      ),
      progressSynced: serializer.fromJson<bool>(json['progressSynced']),
      downloadedAt: serializer.fromJson<DateTime?>(json['downloadedAt']),
      qualityPreset: serializer.fromJson<String>(json['qualityPreset']),
      seriesId: serializer.fromJson<String?>(json['seriesId']),
      seasonId: serializer.fromJson<String?>(json['seasonId']),
      seriesName: serializer.fromJson<String?>(json['seriesName']),
      seasonName: serializer.fromJson<String?>(json['seasonName']),
      indexNumber: serializer.fromJson<int?>(json['indexNumber']),
      parentIndexNumber: serializer.fromJson<int?>(json['parentIndexNumber']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemId': serializer.toJson<String>(itemId),
      'serverId': serializer.toJson<String>(serverId),
      'type': serializer.toJson<String>(type),
      'name': serializer.toJson<String>(name),
      'localFilePath': serializer.toJson<String?>(localFilePath),
      'metadataJson': serializer.toJson<String>(metadataJson),
      'posterPath': serializer.toJson<String?>(posterPath),
      'backdropPath': serializer.toJson<String?>(backdropPath),
      'logoPath': serializer.toJson<String?>(logoPath),
      'thumbPath': serializer.toJson<String?>(thumbPath),
      'downloadStatus': serializer.toJson<int>(downloadStatus),
      'downloadProgress': serializer.toJson<double>(downloadProgress),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'fileSizeBytes': serializer.toJson<int>(fileSizeBytes),
      'playbackPositionTicks': serializer.toJson<int>(playbackPositionTicks),
      'progressSynced': serializer.toJson<bool>(progressSynced),
      'downloadedAt': serializer.toJson<DateTime?>(downloadedAt),
      'qualityPreset': serializer.toJson<String>(qualityPreset),
      'seriesId': serializer.toJson<String?>(seriesId),
      'seasonId': serializer.toJson<String?>(seasonId),
      'seriesName': serializer.toJson<String?>(seriesName),
      'seasonName': serializer.toJson<String?>(seasonName),
      'indexNumber': serializer.toJson<int?>(indexNumber),
      'parentIndexNumber': serializer.toJson<int?>(parentIndexNumber),
    };
  }

  DownloadedItem copyWith({
    String? itemId,
    String? serverId,
    String? type,
    String? name,
    Value<String?> localFilePath = const Value.absent(),
    String? metadataJson,
    Value<String?> posterPath = const Value.absent(),
    Value<String?> backdropPath = const Value.absent(),
    Value<String?> logoPath = const Value.absent(),
    Value<String?> thumbPath = const Value.absent(),
    int? downloadStatus,
    double? downloadProgress,
    Value<String?> errorMessage = const Value.absent(),
    int? fileSizeBytes,
    int? playbackPositionTicks,
    bool? progressSynced,
    Value<DateTime?> downloadedAt = const Value.absent(),
    String? qualityPreset,
    Value<String?> seriesId = const Value.absent(),
    Value<String?> seasonId = const Value.absent(),
    Value<String?> seriesName = const Value.absent(),
    Value<String?> seasonName = const Value.absent(),
    Value<int?> indexNumber = const Value.absent(),
    Value<int?> parentIndexNumber = const Value.absent(),
  }) => DownloadedItem(
    itemId: itemId ?? this.itemId,
    serverId: serverId ?? this.serverId,
    type: type ?? this.type,
    name: name ?? this.name,
    localFilePath: localFilePath.present
        ? localFilePath.value
        : this.localFilePath,
    metadataJson: metadataJson ?? this.metadataJson,
    posterPath: posterPath.present ? posterPath.value : this.posterPath,
    backdropPath: backdropPath.present ? backdropPath.value : this.backdropPath,
    logoPath: logoPath.present ? logoPath.value : this.logoPath,
    thumbPath: thumbPath.present ? thumbPath.value : this.thumbPath,
    downloadStatus: downloadStatus ?? this.downloadStatus,
    downloadProgress: downloadProgress ?? this.downloadProgress,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    playbackPositionTicks: playbackPositionTicks ?? this.playbackPositionTicks,
    progressSynced: progressSynced ?? this.progressSynced,
    downloadedAt: downloadedAt.present ? downloadedAt.value : this.downloadedAt,
    qualityPreset: qualityPreset ?? this.qualityPreset,
    seriesId: seriesId.present ? seriesId.value : this.seriesId,
    seasonId: seasonId.present ? seasonId.value : this.seasonId,
    seriesName: seriesName.present ? seriesName.value : this.seriesName,
    seasonName: seasonName.present ? seasonName.value : this.seasonName,
    indexNumber: indexNumber.present ? indexNumber.value : this.indexNumber,
    parentIndexNumber: parentIndexNumber.present
        ? parentIndexNumber.value
        : this.parentIndexNumber,
  );
  DownloadedItem copyWithCompanion(DownloadedItemsCompanion data) {
    return DownloadedItem(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      type: data.type.present ? data.type.value : this.type,
      name: data.name.present ? data.name.value : this.name,
      localFilePath: data.localFilePath.present
          ? data.localFilePath.value
          : this.localFilePath,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
      posterPath: data.posterPath.present
          ? data.posterPath.value
          : this.posterPath,
      backdropPath: data.backdropPath.present
          ? data.backdropPath.value
          : this.backdropPath,
      logoPath: data.logoPath.present ? data.logoPath.value : this.logoPath,
      thumbPath: data.thumbPath.present ? data.thumbPath.value : this.thumbPath,
      downloadStatus: data.downloadStatus.present
          ? data.downloadStatus.value
          : this.downloadStatus,
      downloadProgress: data.downloadProgress.present
          ? data.downloadProgress.value
          : this.downloadProgress,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      playbackPositionTicks: data.playbackPositionTicks.present
          ? data.playbackPositionTicks.value
          : this.playbackPositionTicks,
      progressSynced: data.progressSynced.present
          ? data.progressSynced.value
          : this.progressSynced,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
      qualityPreset: data.qualityPreset.present
          ? data.qualityPreset.value
          : this.qualityPreset,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      seasonId: data.seasonId.present ? data.seasonId.value : this.seasonId,
      seriesName: data.seriesName.present
          ? data.seriesName.value
          : this.seriesName,
      seasonName: data.seasonName.present
          ? data.seasonName.value
          : this.seasonName,
      indexNumber: data.indexNumber.present
          ? data.indexNumber.value
          : this.indexNumber,
      parentIndexNumber: data.parentIndexNumber.present
          ? data.parentIndexNumber.value
          : this.parentIndexNumber,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadedItem(')
          ..write('itemId: $itemId, ')
          ..write('serverId: $serverId, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('localFilePath: $localFilePath, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('posterPath: $posterPath, ')
          ..write('backdropPath: $backdropPath, ')
          ..write('logoPath: $logoPath, ')
          ..write('thumbPath: $thumbPath, ')
          ..write('downloadStatus: $downloadStatus, ')
          ..write('downloadProgress: $downloadProgress, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('playbackPositionTicks: $playbackPositionTicks, ')
          ..write('progressSynced: $progressSynced, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('qualityPreset: $qualityPreset, ')
          ..write('seriesId: $seriesId, ')
          ..write('seasonId: $seasonId, ')
          ..write('seriesName: $seriesName, ')
          ..write('seasonName: $seasonName, ')
          ..write('indexNumber: $indexNumber, ')
          ..write('parentIndexNumber: $parentIndexNumber')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    itemId,
    serverId,
    type,
    name,
    localFilePath,
    metadataJson,
    posterPath,
    backdropPath,
    logoPath,
    thumbPath,
    downloadStatus,
    downloadProgress,
    errorMessage,
    fileSizeBytes,
    playbackPositionTicks,
    progressSynced,
    downloadedAt,
    qualityPreset,
    seriesId,
    seasonId,
    seriesName,
    seasonName,
    indexNumber,
    parentIndexNumber,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadedItem &&
          other.itemId == this.itemId &&
          other.serverId == this.serverId &&
          other.type == this.type &&
          other.name == this.name &&
          other.localFilePath == this.localFilePath &&
          other.metadataJson == this.metadataJson &&
          other.posterPath == this.posterPath &&
          other.backdropPath == this.backdropPath &&
          other.logoPath == this.logoPath &&
          other.thumbPath == this.thumbPath &&
          other.downloadStatus == this.downloadStatus &&
          other.downloadProgress == this.downloadProgress &&
          other.errorMessage == this.errorMessage &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.playbackPositionTicks == this.playbackPositionTicks &&
          other.progressSynced == this.progressSynced &&
          other.downloadedAt == this.downloadedAt &&
          other.qualityPreset == this.qualityPreset &&
          other.seriesId == this.seriesId &&
          other.seasonId == this.seasonId &&
          other.seriesName == this.seriesName &&
          other.seasonName == this.seasonName &&
          other.indexNumber == this.indexNumber &&
          other.parentIndexNumber == this.parentIndexNumber);
}

class DownloadedItemsCompanion extends UpdateCompanion<DownloadedItem> {
  final Value<String> itemId;
  final Value<String> serverId;
  final Value<String> type;
  final Value<String> name;
  final Value<String?> localFilePath;
  final Value<String> metadataJson;
  final Value<String?> posterPath;
  final Value<String?> backdropPath;
  final Value<String?> logoPath;
  final Value<String?> thumbPath;
  final Value<int> downloadStatus;
  final Value<double> downloadProgress;
  final Value<String?> errorMessage;
  final Value<int> fileSizeBytes;
  final Value<int> playbackPositionTicks;
  final Value<bool> progressSynced;
  final Value<DateTime?> downloadedAt;
  final Value<String> qualityPreset;
  final Value<String?> seriesId;
  final Value<String?> seasonId;
  final Value<String?> seriesName;
  final Value<String?> seasonName;
  final Value<int?> indexNumber;
  final Value<int?> parentIndexNumber;
  final Value<int> rowid;
  const DownloadedItemsCompanion({
    this.itemId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.type = const Value.absent(),
    this.name = const Value.absent(),
    this.localFilePath = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.backdropPath = const Value.absent(),
    this.logoPath = const Value.absent(),
    this.thumbPath = const Value.absent(),
    this.downloadStatus = const Value.absent(),
    this.downloadProgress = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.playbackPositionTicks = const Value.absent(),
    this.progressSynced = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.qualityPreset = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.seasonId = const Value.absent(),
    this.seriesName = const Value.absent(),
    this.seasonName = const Value.absent(),
    this.indexNumber = const Value.absent(),
    this.parentIndexNumber = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadedItemsCompanion.insert({
    required String itemId,
    required String serverId,
    required String type,
    required String name,
    this.localFilePath = const Value.absent(),
    required String metadataJson,
    this.posterPath = const Value.absent(),
    this.backdropPath = const Value.absent(),
    this.logoPath = const Value.absent(),
    this.thumbPath = const Value.absent(),
    required int downloadStatus,
    this.downloadProgress = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.playbackPositionTicks = const Value.absent(),
    this.progressSynced = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.qualityPreset = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.seasonId = const Value.absent(),
    this.seriesName = const Value.absent(),
    this.seasonName = const Value.absent(),
    this.indexNumber = const Value.absent(),
    this.parentIndexNumber = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : itemId = Value(itemId),
       serverId = Value(serverId),
       type = Value(type),
       name = Value(name),
       metadataJson = Value(metadataJson),
       downloadStatus = Value(downloadStatus);
  static Insertable<DownloadedItem> custom({
    Expression<String>? itemId,
    Expression<String>? serverId,
    Expression<String>? type,
    Expression<String>? name,
    Expression<String>? localFilePath,
    Expression<String>? metadataJson,
    Expression<String>? posterPath,
    Expression<String>? backdropPath,
    Expression<String>? logoPath,
    Expression<String>? thumbPath,
    Expression<int>? downloadStatus,
    Expression<double>? downloadProgress,
    Expression<String>? errorMessage,
    Expression<int>? fileSizeBytes,
    Expression<int>? playbackPositionTicks,
    Expression<bool>? progressSynced,
    Expression<DateTime>? downloadedAt,
    Expression<String>? qualityPreset,
    Expression<String>? seriesId,
    Expression<String>? seasonId,
    Expression<String>? seriesName,
    Expression<String>? seasonName,
    Expression<int>? indexNumber,
    Expression<int>? parentIndexNumber,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (serverId != null) 'server_id': serverId,
      if (type != null) 'type': type,
      if (name != null) 'name': name,
      if (localFilePath != null) 'local_file_path': localFilePath,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (posterPath != null) 'poster_path': posterPath,
      if (backdropPath != null) 'backdrop_path': backdropPath,
      if (logoPath != null) 'logo_path': logoPath,
      if (thumbPath != null) 'thumb_path': thumbPath,
      if (downloadStatus != null) 'download_status': downloadStatus,
      if (downloadProgress != null) 'download_progress': downloadProgress,
      if (errorMessage != null) 'error_message': errorMessage,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (playbackPositionTicks != null)
        'playback_position_ticks': playbackPositionTicks,
      if (progressSynced != null) 'progress_synced': progressSynced,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
      if (qualityPreset != null) 'quality_preset': qualityPreset,
      if (seriesId != null) 'series_id': seriesId,
      if (seasonId != null) 'season_id': seasonId,
      if (seriesName != null) 'series_name': seriesName,
      if (seasonName != null) 'season_name': seasonName,
      if (indexNumber != null) 'index_number': indexNumber,
      if (parentIndexNumber != null) 'parent_index_number': parentIndexNumber,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadedItemsCompanion copyWith({
    Value<String>? itemId,
    Value<String>? serverId,
    Value<String>? type,
    Value<String>? name,
    Value<String?>? localFilePath,
    Value<String>? metadataJson,
    Value<String?>? posterPath,
    Value<String?>? backdropPath,
    Value<String?>? logoPath,
    Value<String?>? thumbPath,
    Value<int>? downloadStatus,
    Value<double>? downloadProgress,
    Value<String?>? errorMessage,
    Value<int>? fileSizeBytes,
    Value<int>? playbackPositionTicks,
    Value<bool>? progressSynced,
    Value<DateTime?>? downloadedAt,
    Value<String>? qualityPreset,
    Value<String?>? seriesId,
    Value<String?>? seasonId,
    Value<String?>? seriesName,
    Value<String?>? seasonName,
    Value<int?>? indexNumber,
    Value<int?>? parentIndexNumber,
    Value<int>? rowid,
  }) {
    return DownloadedItemsCompanion(
      itemId: itemId ?? this.itemId,
      serverId: serverId ?? this.serverId,
      type: type ?? this.type,
      name: name ?? this.name,
      localFilePath: localFilePath ?? this.localFilePath,
      metadataJson: metadataJson ?? this.metadataJson,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      logoPath: logoPath ?? this.logoPath,
      thumbPath: thumbPath ?? this.thumbPath,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      errorMessage: errorMessage ?? this.errorMessage,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      playbackPositionTicks:
          playbackPositionTicks ?? this.playbackPositionTicks,
      progressSynced: progressSynced ?? this.progressSynced,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      qualityPreset: qualityPreset ?? this.qualityPreset,
      seriesId: seriesId ?? this.seriesId,
      seasonId: seasonId ?? this.seasonId,
      seriesName: seriesName ?? this.seriesName,
      seasonName: seasonName ?? this.seasonName,
      indexNumber: indexNumber ?? this.indexNumber,
      parentIndexNumber: parentIndexNumber ?? this.parentIndexNumber,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (localFilePath.present) {
      map['local_file_path'] = Variable<String>(localFilePath.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (posterPath.present) {
      map['poster_path'] = Variable<String>(posterPath.value);
    }
    if (backdropPath.present) {
      map['backdrop_path'] = Variable<String>(backdropPath.value);
    }
    if (logoPath.present) {
      map['logo_path'] = Variable<String>(logoPath.value);
    }
    if (thumbPath.present) {
      map['thumb_path'] = Variable<String>(thumbPath.value);
    }
    if (downloadStatus.present) {
      map['download_status'] = Variable<int>(downloadStatus.value);
    }
    if (downloadProgress.present) {
      map['download_progress'] = Variable<double>(downloadProgress.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes.value);
    }
    if (playbackPositionTicks.present) {
      map['playback_position_ticks'] = Variable<int>(
        playbackPositionTicks.value,
      );
    }
    if (progressSynced.present) {
      map['progress_synced'] = Variable<bool>(progressSynced.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt.value);
    }
    if (qualityPreset.present) {
      map['quality_preset'] = Variable<String>(qualityPreset.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (seasonId.present) {
      map['season_id'] = Variable<String>(seasonId.value);
    }
    if (seriesName.present) {
      map['series_name'] = Variable<String>(seriesName.value);
    }
    if (seasonName.present) {
      map['season_name'] = Variable<String>(seasonName.value);
    }
    if (indexNumber.present) {
      map['index_number'] = Variable<int>(indexNumber.value);
    }
    if (parentIndexNumber.present) {
      map['parent_index_number'] = Variable<int>(parentIndexNumber.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadedItemsCompanion(')
          ..write('itemId: $itemId, ')
          ..write('serverId: $serverId, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('localFilePath: $localFilePath, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('posterPath: $posterPath, ')
          ..write('backdropPath: $backdropPath, ')
          ..write('logoPath: $logoPath, ')
          ..write('thumbPath: $thumbPath, ')
          ..write('downloadStatus: $downloadStatus, ')
          ..write('downloadProgress: $downloadProgress, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('playbackPositionTicks: $playbackPositionTicks, ')
          ..write('progressSynced: $progressSynced, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('qualityPreset: $qualityPreset, ')
          ..write('seriesId: $seriesId, ')
          ..write('seasonId: $seasonId, ')
          ..write('seriesName: $seriesName, ')
          ..write('seasonName: $seasonName, ')
          ..write('indexNumber: $indexNumber, ')
          ..write('parentIndexNumber: $parentIndexNumber, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AdvancedFilterCatalogItemsTable extends AdvancedFilterCatalogItems
    with
        TableInfo<$AdvancedFilterCatalogItemsTable, AdvancedFilterCatalogItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AdvancedFilterCatalogItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortNameMeta = const VerificationMeta(
    'sortName',
  );
  @override
  late final GeneratedColumn<String> sortName = GeneratedColumn<String>(
    'sort_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productionYearMeta = const VerificationMeta(
    'productionYear',
  );
  @override
  late final GeneratedColumn<int> productionYear = GeneratedColumn<int>(
    'production_year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metadataJsonMeta = const VerificationMeta(
    'metadataJson',
  );
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
    'metadata_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    serverId,
    userId,
    itemId,
    type,
    name,
    sortName,
    productionYear,
    metadataJson,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'advanced_filter_catalog_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<AdvancedFilterCatalogItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_name')) {
      context.handle(
        _sortNameMeta,
        sortName.isAcceptableOrUnknown(data['sort_name']!, _sortNameMeta),
      );
    } else if (isInserting) {
      context.missing(_sortNameMeta);
    }
    if (data.containsKey('production_year')) {
      context.handle(
        _productionYearMeta,
        productionYear.isAcceptableOrUnknown(
          data['production_year']!,
          _productionYearMeta,
        ),
      );
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
        _metadataJsonMeta,
        metadataJson.isAcceptableOrUnknown(
          data['metadata_json']!,
          _metadataJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_metadataJsonMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {serverId, userId, itemId};
  @override
  AdvancedFilterCatalogItem map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AdvancedFilterCatalogItem(
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sortName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sort_name'],
      )!,
      productionYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}production_year'],
      ),
      metadataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_json'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $AdvancedFilterCatalogItemsTable createAlias(String alias) {
    return $AdvancedFilterCatalogItemsTable(attachedDatabase, alias);
  }
}

class AdvancedFilterCatalogItem extends DataClass
    implements Insertable<AdvancedFilterCatalogItem> {
  final String serverId;
  final String userId;
  final String itemId;
  final String type;
  final String name;
  final String sortName;
  final int? productionYear;
  final String metadataJson;
  final DateTime cachedAt;
  const AdvancedFilterCatalogItem({
    required this.serverId,
    required this.userId,
    required this.itemId,
    required this.type,
    required this.name,
    required this.sortName,
    this.productionYear,
    required this.metadataJson,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['server_id'] = Variable<String>(serverId);
    map['user_id'] = Variable<String>(userId);
    map['item_id'] = Variable<String>(itemId);
    map['type'] = Variable<String>(type);
    map['name'] = Variable<String>(name);
    map['sort_name'] = Variable<String>(sortName);
    if (!nullToAbsent || productionYear != null) {
      map['production_year'] = Variable<int>(productionYear);
    }
    map['metadata_json'] = Variable<String>(metadataJson);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  AdvancedFilterCatalogItemsCompanion toCompanion(bool nullToAbsent) {
    return AdvancedFilterCatalogItemsCompanion(
      serverId: Value(serverId),
      userId: Value(userId),
      itemId: Value(itemId),
      type: Value(type),
      name: Value(name),
      sortName: Value(sortName),
      productionYear: productionYear == null && nullToAbsent
          ? const Value.absent()
          : Value(productionYear),
      metadataJson: Value(metadataJson),
      cachedAt: Value(cachedAt),
    );
  }

  factory AdvancedFilterCatalogItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AdvancedFilterCatalogItem(
      serverId: serializer.fromJson<String>(json['serverId']),
      userId: serializer.fromJson<String>(json['userId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      type: serializer.fromJson<String>(json['type']),
      name: serializer.fromJson<String>(json['name']),
      sortName: serializer.fromJson<String>(json['sortName']),
      productionYear: serializer.fromJson<int?>(json['productionYear']),
      metadataJson: serializer.fromJson<String>(json['metadataJson']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'serverId': serializer.toJson<String>(serverId),
      'userId': serializer.toJson<String>(userId),
      'itemId': serializer.toJson<String>(itemId),
      'type': serializer.toJson<String>(type),
      'name': serializer.toJson<String>(name),
      'sortName': serializer.toJson<String>(sortName),
      'productionYear': serializer.toJson<int?>(productionYear),
      'metadataJson': serializer.toJson<String>(metadataJson),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  AdvancedFilterCatalogItem copyWith({
    String? serverId,
    String? userId,
    String? itemId,
    String? type,
    String? name,
    String? sortName,
    Value<int?> productionYear = const Value.absent(),
    String? metadataJson,
    DateTime? cachedAt,
  }) => AdvancedFilterCatalogItem(
    serverId: serverId ?? this.serverId,
    userId: userId ?? this.userId,
    itemId: itemId ?? this.itemId,
    type: type ?? this.type,
    name: name ?? this.name,
    sortName: sortName ?? this.sortName,
    productionYear: productionYear.present
        ? productionYear.value
        : this.productionYear,
    metadataJson: metadataJson ?? this.metadataJson,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  AdvancedFilterCatalogItem copyWithCompanion(
    AdvancedFilterCatalogItemsCompanion data,
  ) {
    return AdvancedFilterCatalogItem(
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      userId: data.userId.present ? data.userId.value : this.userId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      type: data.type.present ? data.type.value : this.type,
      name: data.name.present ? data.name.value : this.name,
      sortName: data.sortName.present ? data.sortName.value : this.sortName,
      productionYear: data.productionYear.present
          ? data.productionYear.value
          : this.productionYear,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AdvancedFilterCatalogItem(')
          ..write('serverId: $serverId, ')
          ..write('userId: $userId, ')
          ..write('itemId: $itemId, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('sortName: $sortName, ')
          ..write('productionYear: $productionYear, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    serverId,
    userId,
    itemId,
    type,
    name,
    sortName,
    productionYear,
    metadataJson,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdvancedFilterCatalogItem &&
          other.serverId == this.serverId &&
          other.userId == this.userId &&
          other.itemId == this.itemId &&
          other.type == this.type &&
          other.name == this.name &&
          other.sortName == this.sortName &&
          other.productionYear == this.productionYear &&
          other.metadataJson == this.metadataJson &&
          other.cachedAt == this.cachedAt);
}

class AdvancedFilterCatalogItemsCompanion
    extends UpdateCompanion<AdvancedFilterCatalogItem> {
  final Value<String> serverId;
  final Value<String> userId;
  final Value<String> itemId;
  final Value<String> type;
  final Value<String> name;
  final Value<String> sortName;
  final Value<int?> productionYear;
  final Value<String> metadataJson;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const AdvancedFilterCatalogItemsCompanion({
    this.serverId = const Value.absent(),
    this.userId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.type = const Value.absent(),
    this.name = const Value.absent(),
    this.sortName = const Value.absent(),
    this.productionYear = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AdvancedFilterCatalogItemsCompanion.insert({
    required String serverId,
    required String userId,
    required String itemId,
    required String type,
    required String name,
    required String sortName,
    this.productionYear = const Value.absent(),
    required String metadataJson,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : serverId = Value(serverId),
       userId = Value(userId),
       itemId = Value(itemId),
       type = Value(type),
       name = Value(name),
       sortName = Value(sortName),
       metadataJson = Value(metadataJson),
       cachedAt = Value(cachedAt);
  static Insertable<AdvancedFilterCatalogItem> custom({
    Expression<String>? serverId,
    Expression<String>? userId,
    Expression<String>? itemId,
    Expression<String>? type,
    Expression<String>? name,
    Expression<String>? sortName,
    Expression<int>? productionYear,
    Expression<String>? metadataJson,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (serverId != null) 'server_id': serverId,
      if (userId != null) 'user_id': userId,
      if (itemId != null) 'item_id': itemId,
      if (type != null) 'type': type,
      if (name != null) 'name': name,
      if (sortName != null) 'sort_name': sortName,
      if (productionYear != null) 'production_year': productionYear,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AdvancedFilterCatalogItemsCompanion copyWith({
    Value<String>? serverId,
    Value<String>? userId,
    Value<String>? itemId,
    Value<String>? type,
    Value<String>? name,
    Value<String>? sortName,
    Value<int?>? productionYear,
    Value<String>? metadataJson,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return AdvancedFilterCatalogItemsCompanion(
      serverId: serverId ?? this.serverId,
      userId: userId ?? this.userId,
      itemId: itemId ?? this.itemId,
      type: type ?? this.type,
      name: name ?? this.name,
      sortName: sortName ?? this.sortName,
      productionYear: productionYear ?? this.productionYear,
      metadataJson: metadataJson ?? this.metadataJson,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortName.present) {
      map['sort_name'] = Variable<String>(sortName.value);
    }
    if (productionYear.present) {
      map['production_year'] = Variable<int>(productionYear.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AdvancedFilterCatalogItemsCompanion(')
          ..write('serverId: $serverId, ')
          ..write('userId: $userId, ')
          ..write('itemId: $itemId, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('sortName: $sortName, ')
          ..write('productionYear: $productionYear, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AdvancedFilterCatalogItemGenresTable
    extends AdvancedFilterCatalogItemGenres
    with
        TableInfo<
          $AdvancedFilterCatalogItemGenresTable,
          AdvancedFilterCatalogItemGenre
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AdvancedFilterCatalogItemGenresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
    'genre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [serverId, userId, itemId, genre];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'advanced_filter_catalog_item_genres';
  @override
  VerificationContext validateIntegrity(
    Insertable<AdvancedFilterCatalogItemGenre> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('genre')) {
      context.handle(
        _genreMeta,
        genre.isAcceptableOrUnknown(data['genre']!, _genreMeta),
      );
    } else if (isInserting) {
      context.missing(_genreMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {serverId, userId, itemId, genre};
  @override
  AdvancedFilterCatalogItemGenre map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AdvancedFilterCatalogItemGenre(
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      genre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre'],
      )!,
    );
  }

  @override
  $AdvancedFilterCatalogItemGenresTable createAlias(String alias) {
    return $AdvancedFilterCatalogItemGenresTable(attachedDatabase, alias);
  }
}

class AdvancedFilterCatalogItemGenre extends DataClass
    implements Insertable<AdvancedFilterCatalogItemGenre> {
  final String serverId;
  final String userId;
  final String itemId;
  final String genre;
  const AdvancedFilterCatalogItemGenre({
    required this.serverId,
    required this.userId,
    required this.itemId,
    required this.genre,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['server_id'] = Variable<String>(serverId);
    map['user_id'] = Variable<String>(userId);
    map['item_id'] = Variable<String>(itemId);
    map['genre'] = Variable<String>(genre);
    return map;
  }

  AdvancedFilterCatalogItemGenresCompanion toCompanion(bool nullToAbsent) {
    return AdvancedFilterCatalogItemGenresCompanion(
      serverId: Value(serverId),
      userId: Value(userId),
      itemId: Value(itemId),
      genre: Value(genre),
    );
  }

  factory AdvancedFilterCatalogItemGenre.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AdvancedFilterCatalogItemGenre(
      serverId: serializer.fromJson<String>(json['serverId']),
      userId: serializer.fromJson<String>(json['userId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      genre: serializer.fromJson<String>(json['genre']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'serverId': serializer.toJson<String>(serverId),
      'userId': serializer.toJson<String>(userId),
      'itemId': serializer.toJson<String>(itemId),
      'genre': serializer.toJson<String>(genre),
    };
  }

  AdvancedFilterCatalogItemGenre copyWith({
    String? serverId,
    String? userId,
    String? itemId,
    String? genre,
  }) => AdvancedFilterCatalogItemGenre(
    serverId: serverId ?? this.serverId,
    userId: userId ?? this.userId,
    itemId: itemId ?? this.itemId,
    genre: genre ?? this.genre,
  );
  AdvancedFilterCatalogItemGenre copyWithCompanion(
    AdvancedFilterCatalogItemGenresCompanion data,
  ) {
    return AdvancedFilterCatalogItemGenre(
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      userId: data.userId.present ? data.userId.value : this.userId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      genre: data.genre.present ? data.genre.value : this.genre,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AdvancedFilterCatalogItemGenre(')
          ..write('serverId: $serverId, ')
          ..write('userId: $userId, ')
          ..write('itemId: $itemId, ')
          ..write('genre: $genre')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(serverId, userId, itemId, genre);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdvancedFilterCatalogItemGenre &&
          other.serverId == this.serverId &&
          other.userId == this.userId &&
          other.itemId == this.itemId &&
          other.genre == this.genre);
}

class AdvancedFilterCatalogItemGenresCompanion
    extends UpdateCompanion<AdvancedFilterCatalogItemGenre> {
  final Value<String> serverId;
  final Value<String> userId;
  final Value<String> itemId;
  final Value<String> genre;
  final Value<int> rowid;
  const AdvancedFilterCatalogItemGenresCompanion({
    this.serverId = const Value.absent(),
    this.userId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.genre = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AdvancedFilterCatalogItemGenresCompanion.insert({
    required String serverId,
    required String userId,
    required String itemId,
    required String genre,
    this.rowid = const Value.absent(),
  }) : serverId = Value(serverId),
       userId = Value(userId),
       itemId = Value(itemId),
       genre = Value(genre);
  static Insertable<AdvancedFilterCatalogItemGenre> custom({
    Expression<String>? serverId,
    Expression<String>? userId,
    Expression<String>? itemId,
    Expression<String>? genre,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (serverId != null) 'server_id': serverId,
      if (userId != null) 'user_id': userId,
      if (itemId != null) 'item_id': itemId,
      if (genre != null) 'genre': genre,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AdvancedFilterCatalogItemGenresCompanion copyWith({
    Value<String>? serverId,
    Value<String>? userId,
    Value<String>? itemId,
    Value<String>? genre,
    Value<int>? rowid,
  }) {
    return AdvancedFilterCatalogItemGenresCompanion(
      serverId: serverId ?? this.serverId,
      userId: userId ?? this.userId,
      itemId: itemId ?? this.itemId,
      genre: genre ?? this.genre,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AdvancedFilterCatalogItemGenresCompanion(')
          ..write('serverId: $serverId, ')
          ..write('userId: $userId, ')
          ..write('itemId: $itemId, ')
          ..write('genre: $genre, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AdvancedFilterCatalogItemRegionsTable
    extends AdvancedFilterCatalogItemRegions
    with
        TableInfo<
          $AdvancedFilterCatalogItemRegionsTable,
          AdvancedFilterCatalogItemRegion
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AdvancedFilterCatalogItemRegionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _regionMeta = const VerificationMeta('region');
  @override
  late final GeneratedColumn<String> region = GeneratedColumn<String>(
    'region',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [serverId, userId, itemId, region];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'advanced_filter_catalog_item_regions';
  @override
  VerificationContext validateIntegrity(
    Insertable<AdvancedFilterCatalogItemRegion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('region')) {
      context.handle(
        _regionMeta,
        region.isAcceptableOrUnknown(data['region']!, _regionMeta),
      );
    } else if (isInserting) {
      context.missing(_regionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {serverId, userId, itemId, region};
  @override
  AdvancedFilterCatalogItemRegion map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AdvancedFilterCatalogItemRegion(
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      region: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}region'],
      )!,
    );
  }

  @override
  $AdvancedFilterCatalogItemRegionsTable createAlias(String alias) {
    return $AdvancedFilterCatalogItemRegionsTable(attachedDatabase, alias);
  }
}

class AdvancedFilterCatalogItemRegion extends DataClass
    implements Insertable<AdvancedFilterCatalogItemRegion> {
  final String serverId;
  final String userId;
  final String itemId;
  final String region;
  const AdvancedFilterCatalogItemRegion({
    required this.serverId,
    required this.userId,
    required this.itemId,
    required this.region,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['server_id'] = Variable<String>(serverId);
    map['user_id'] = Variable<String>(userId);
    map['item_id'] = Variable<String>(itemId);
    map['region'] = Variable<String>(region);
    return map;
  }

  AdvancedFilterCatalogItemRegionsCompanion toCompanion(bool nullToAbsent) {
    return AdvancedFilterCatalogItemRegionsCompanion(
      serverId: Value(serverId),
      userId: Value(userId),
      itemId: Value(itemId),
      region: Value(region),
    );
  }

  factory AdvancedFilterCatalogItemRegion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AdvancedFilterCatalogItemRegion(
      serverId: serializer.fromJson<String>(json['serverId']),
      userId: serializer.fromJson<String>(json['userId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      region: serializer.fromJson<String>(json['region']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'serverId': serializer.toJson<String>(serverId),
      'userId': serializer.toJson<String>(userId),
      'itemId': serializer.toJson<String>(itemId),
      'region': serializer.toJson<String>(region),
    };
  }

  AdvancedFilterCatalogItemRegion copyWith({
    String? serverId,
    String? userId,
    String? itemId,
    String? region,
  }) => AdvancedFilterCatalogItemRegion(
    serverId: serverId ?? this.serverId,
    userId: userId ?? this.userId,
    itemId: itemId ?? this.itemId,
    region: region ?? this.region,
  );
  AdvancedFilterCatalogItemRegion copyWithCompanion(
    AdvancedFilterCatalogItemRegionsCompanion data,
  ) {
    return AdvancedFilterCatalogItemRegion(
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      userId: data.userId.present ? data.userId.value : this.userId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      region: data.region.present ? data.region.value : this.region,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AdvancedFilterCatalogItemRegion(')
          ..write('serverId: $serverId, ')
          ..write('userId: $userId, ')
          ..write('itemId: $itemId, ')
          ..write('region: $region')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(serverId, userId, itemId, region);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdvancedFilterCatalogItemRegion &&
          other.serverId == this.serverId &&
          other.userId == this.userId &&
          other.itemId == this.itemId &&
          other.region == this.region);
}

class AdvancedFilterCatalogItemRegionsCompanion
    extends UpdateCompanion<AdvancedFilterCatalogItemRegion> {
  final Value<String> serverId;
  final Value<String> userId;
  final Value<String> itemId;
  final Value<String> region;
  final Value<int> rowid;
  const AdvancedFilterCatalogItemRegionsCompanion({
    this.serverId = const Value.absent(),
    this.userId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.region = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AdvancedFilterCatalogItemRegionsCompanion.insert({
    required String serverId,
    required String userId,
    required String itemId,
    required String region,
    this.rowid = const Value.absent(),
  }) : serverId = Value(serverId),
       userId = Value(userId),
       itemId = Value(itemId),
       region = Value(region);
  static Insertable<AdvancedFilterCatalogItemRegion> custom({
    Expression<String>? serverId,
    Expression<String>? userId,
    Expression<String>? itemId,
    Expression<String>? region,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (serverId != null) 'server_id': serverId,
      if (userId != null) 'user_id': userId,
      if (itemId != null) 'item_id': itemId,
      if (region != null) 'region': region,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AdvancedFilterCatalogItemRegionsCompanion copyWith({
    Value<String>? serverId,
    Value<String>? userId,
    Value<String>? itemId,
    Value<String>? region,
    Value<int>? rowid,
  }) {
    return AdvancedFilterCatalogItemRegionsCompanion(
      serverId: serverId ?? this.serverId,
      userId: userId ?? this.userId,
      itemId: itemId ?? this.itemId,
      region: region ?? this.region,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (region.present) {
      map['region'] = Variable<String>(region.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AdvancedFilterCatalogItemRegionsCompanion(')
          ..write('serverId: $serverId, ')
          ..write('userId: $userId, ')
          ..write('itemId: $itemId, ')
          ..write('region: $region, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AdvancedFilterCatalogSyncStatesTable
    extends AdvancedFilterCatalogSyncStates
    with
        TableInfo<
          $AdvancedFilterCatalogSyncStatesTable,
          AdvancedFilterCatalogSyncState
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AdvancedFilterCatalogSyncStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cacheVersionMeta = const VerificationMeta(
    'cacheVersion',
  );
  @override
  late final GeneratedColumn<int> cacheVersion = GeneratedColumn<int>(
    'cache_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemCountMeta = const VerificationMeta(
    'itemCount',
  );
  @override
  late final GeneratedColumn<int> itemCount = GeneratedColumn<int>(
    'item_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    serverId,
    userId,
    cacheVersion,
    itemCount,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'advanced_filter_catalog_sync_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<AdvancedFilterCatalogSyncState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('cache_version')) {
      context.handle(
        _cacheVersionMeta,
        cacheVersion.isAcceptableOrUnknown(
          data['cache_version']!,
          _cacheVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cacheVersionMeta);
    }
    if (data.containsKey('item_count')) {
      context.handle(
        _itemCountMeta,
        itemCount.isAcceptableOrUnknown(data['item_count']!, _itemCountMeta),
      );
    } else if (isInserting) {
      context.missing(_itemCountMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {serverId, userId};
  @override
  AdvancedFilterCatalogSyncState map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AdvancedFilterCatalogSyncState(
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      cacheVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cache_version'],
      )!,
      itemCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_count'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $AdvancedFilterCatalogSyncStatesTable createAlias(String alias) {
    return $AdvancedFilterCatalogSyncStatesTable(attachedDatabase, alias);
  }
}

class AdvancedFilterCatalogSyncState extends DataClass
    implements Insertable<AdvancedFilterCatalogSyncState> {
  final String serverId;
  final String userId;
  final int cacheVersion;
  final int itemCount;
  final DateTime syncedAt;
  const AdvancedFilterCatalogSyncState({
    required this.serverId,
    required this.userId,
    required this.cacheVersion,
    required this.itemCount,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['server_id'] = Variable<String>(serverId);
    map['user_id'] = Variable<String>(userId);
    map['cache_version'] = Variable<int>(cacheVersion);
    map['item_count'] = Variable<int>(itemCount);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  AdvancedFilterCatalogSyncStatesCompanion toCompanion(bool nullToAbsent) {
    return AdvancedFilterCatalogSyncStatesCompanion(
      serverId: Value(serverId),
      userId: Value(userId),
      cacheVersion: Value(cacheVersion),
      itemCount: Value(itemCount),
      syncedAt: Value(syncedAt),
    );
  }

  factory AdvancedFilterCatalogSyncState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AdvancedFilterCatalogSyncState(
      serverId: serializer.fromJson<String>(json['serverId']),
      userId: serializer.fromJson<String>(json['userId']),
      cacheVersion: serializer.fromJson<int>(json['cacheVersion']),
      itemCount: serializer.fromJson<int>(json['itemCount']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'serverId': serializer.toJson<String>(serverId),
      'userId': serializer.toJson<String>(userId),
      'cacheVersion': serializer.toJson<int>(cacheVersion),
      'itemCount': serializer.toJson<int>(itemCount),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  AdvancedFilterCatalogSyncState copyWith({
    String? serverId,
    String? userId,
    int? cacheVersion,
    int? itemCount,
    DateTime? syncedAt,
  }) => AdvancedFilterCatalogSyncState(
    serverId: serverId ?? this.serverId,
    userId: userId ?? this.userId,
    cacheVersion: cacheVersion ?? this.cacheVersion,
    itemCount: itemCount ?? this.itemCount,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  AdvancedFilterCatalogSyncState copyWithCompanion(
    AdvancedFilterCatalogSyncStatesCompanion data,
  ) {
    return AdvancedFilterCatalogSyncState(
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      userId: data.userId.present ? data.userId.value : this.userId,
      cacheVersion: data.cacheVersion.present
          ? data.cacheVersion.value
          : this.cacheVersion,
      itemCount: data.itemCount.present ? data.itemCount.value : this.itemCount,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AdvancedFilterCatalogSyncState(')
          ..write('serverId: $serverId, ')
          ..write('userId: $userId, ')
          ..write('cacheVersion: $cacheVersion, ')
          ..write('itemCount: $itemCount, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(serverId, userId, cacheVersion, itemCount, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdvancedFilterCatalogSyncState &&
          other.serverId == this.serverId &&
          other.userId == this.userId &&
          other.cacheVersion == this.cacheVersion &&
          other.itemCount == this.itemCount &&
          other.syncedAt == this.syncedAt);
}

class AdvancedFilterCatalogSyncStatesCompanion
    extends UpdateCompanion<AdvancedFilterCatalogSyncState> {
  final Value<String> serverId;
  final Value<String> userId;
  final Value<int> cacheVersion;
  final Value<int> itemCount;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const AdvancedFilterCatalogSyncStatesCompanion({
    this.serverId = const Value.absent(),
    this.userId = const Value.absent(),
    this.cacheVersion = const Value.absent(),
    this.itemCount = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AdvancedFilterCatalogSyncStatesCompanion.insert({
    required String serverId,
    required String userId,
    required int cacheVersion,
    required int itemCount,
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  }) : serverId = Value(serverId),
       userId = Value(userId),
       cacheVersion = Value(cacheVersion),
       itemCount = Value(itemCount),
       syncedAt = Value(syncedAt);
  static Insertable<AdvancedFilterCatalogSyncState> custom({
    Expression<String>? serverId,
    Expression<String>? userId,
    Expression<int>? cacheVersion,
    Expression<int>? itemCount,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (serverId != null) 'server_id': serverId,
      if (userId != null) 'user_id': userId,
      if (cacheVersion != null) 'cache_version': cacheVersion,
      if (itemCount != null) 'item_count': itemCount,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AdvancedFilterCatalogSyncStatesCompanion copyWith({
    Value<String>? serverId,
    Value<String>? userId,
    Value<int>? cacheVersion,
    Value<int>? itemCount,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return AdvancedFilterCatalogSyncStatesCompanion(
      serverId: serverId ?? this.serverId,
      userId: userId ?? this.userId,
      cacheVersion: cacheVersion ?? this.cacheVersion,
      itemCount: itemCount ?? this.itemCount,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (cacheVersion.present) {
      map['cache_version'] = Variable<int>(cacheVersion.value);
    }
    if (itemCount.present) {
      map['item_count'] = Variable<int>(itemCount.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AdvancedFilterCatalogSyncStatesCompanion(')
          ..write('serverId: $serverId, ')
          ..write('userId: $userId, ')
          ..write('cacheVersion: $cacheVersion, ')
          ..write('itemCount: $itemCount, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$OfflineDatabase extends GeneratedDatabase {
  _$OfflineDatabase(QueryExecutor e) : super(e);
  $OfflineDatabaseManager get managers => $OfflineDatabaseManager(this);
  late final $DownloadedItemsTable downloadedItems = $DownloadedItemsTable(
    this,
  );
  late final $AdvancedFilterCatalogItemsTable advancedFilterCatalogItems =
      $AdvancedFilterCatalogItemsTable(this);
  late final $AdvancedFilterCatalogItemGenresTable
  advancedFilterCatalogItemGenres = $AdvancedFilterCatalogItemGenresTable(this);
  late final $AdvancedFilterCatalogItemRegionsTable
  advancedFilterCatalogItemRegions = $AdvancedFilterCatalogItemRegionsTable(
    this,
  );
  late final $AdvancedFilterCatalogSyncStatesTable
  advancedFilterCatalogSyncStates = $AdvancedFilterCatalogSyncStatesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    downloadedItems,
    advancedFilterCatalogItems,
    advancedFilterCatalogItemGenres,
    advancedFilterCatalogItemRegions,
    advancedFilterCatalogSyncStates,
  ];
}

typedef $$DownloadedItemsTableCreateCompanionBuilder =
    DownloadedItemsCompanion Function({
      required String itemId,
      required String serverId,
      required String type,
      required String name,
      Value<String?> localFilePath,
      required String metadataJson,
      Value<String?> posterPath,
      Value<String?> backdropPath,
      Value<String?> logoPath,
      Value<String?> thumbPath,
      required int downloadStatus,
      Value<double> downloadProgress,
      Value<String?> errorMessage,
      Value<int> fileSizeBytes,
      Value<int> playbackPositionTicks,
      Value<bool> progressSynced,
      Value<DateTime?> downloadedAt,
      Value<String> qualityPreset,
      Value<String?> seriesId,
      Value<String?> seasonId,
      Value<String?> seriesName,
      Value<String?> seasonName,
      Value<int?> indexNumber,
      Value<int?> parentIndexNumber,
      Value<int> rowid,
    });
typedef $$DownloadedItemsTableUpdateCompanionBuilder =
    DownloadedItemsCompanion Function({
      Value<String> itemId,
      Value<String> serverId,
      Value<String> type,
      Value<String> name,
      Value<String?> localFilePath,
      Value<String> metadataJson,
      Value<String?> posterPath,
      Value<String?> backdropPath,
      Value<String?> logoPath,
      Value<String?> thumbPath,
      Value<int> downloadStatus,
      Value<double> downloadProgress,
      Value<String?> errorMessage,
      Value<int> fileSizeBytes,
      Value<int> playbackPositionTicks,
      Value<bool> progressSynced,
      Value<DateTime?> downloadedAt,
      Value<String> qualityPreset,
      Value<String?> seriesId,
      Value<String?> seasonId,
      Value<String?> seriesName,
      Value<String?> seasonName,
      Value<int?> indexNumber,
      Value<int?> parentIndexNumber,
      Value<int> rowid,
    });

class $$DownloadedItemsTableFilterComposer
    extends Composer<_$OfflineDatabase, $DownloadedItemsTable> {
  $$DownloadedItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localFilePath => $composableBuilder(
    column: $table.localFilePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backdropPath => $composableBuilder(
    column: $table.backdropPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logoPath => $composableBuilder(
    column: $table.logoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbPath => $composableBuilder(
    column: $table.thumbPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get downloadStatus => $composableBuilder(
    column: $table.downloadStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get downloadProgress => $composableBuilder(
    column: $table.downloadProgress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playbackPositionTicks => $composableBuilder(
    column: $table.playbackPositionTicks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get progressSynced => $composableBuilder(
    column: $table.progressSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get qualityPreset => $composableBuilder(
    column: $table.qualityPreset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seasonId => $composableBuilder(
    column: $table.seasonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seriesName => $composableBuilder(
    column: $table.seriesName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seasonName => $composableBuilder(
    column: $table.seasonName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get indexNumber => $composableBuilder(
    column: $table.indexNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get parentIndexNumber => $composableBuilder(
    column: $table.parentIndexNumber,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadedItemsTableOrderingComposer
    extends Composer<_$OfflineDatabase, $DownloadedItemsTable> {
  $$DownloadedItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localFilePath => $composableBuilder(
    column: $table.localFilePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backdropPath => $composableBuilder(
    column: $table.backdropPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logoPath => $composableBuilder(
    column: $table.logoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbPath => $composableBuilder(
    column: $table.thumbPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get downloadStatus => $composableBuilder(
    column: $table.downloadStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get downloadProgress => $composableBuilder(
    column: $table.downloadProgress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playbackPositionTicks => $composableBuilder(
    column: $table.playbackPositionTicks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get progressSynced => $composableBuilder(
    column: $table.progressSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get qualityPreset => $composableBuilder(
    column: $table.qualityPreset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seasonId => $composableBuilder(
    column: $table.seasonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seriesName => $composableBuilder(
    column: $table.seriesName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seasonName => $composableBuilder(
    column: $table.seasonName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get indexNumber => $composableBuilder(
    column: $table.indexNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get parentIndexNumber => $composableBuilder(
    column: $table.parentIndexNumber,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadedItemsTableAnnotationComposer
    extends Composer<_$OfflineDatabase, $DownloadedItemsTable> {
  $$DownloadedItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get localFilePath => $composableBuilder(
    column: $table.localFilePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backdropPath => $composableBuilder(
    column: $table.backdropPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get logoPath =>
      $composableBuilder(column: $table.logoPath, builder: (column) => column);

  GeneratedColumn<String> get thumbPath =>
      $composableBuilder(column: $table.thumbPath, builder: (column) => column);

  GeneratedColumn<int> get downloadStatus => $composableBuilder(
    column: $table.downloadStatus,
    builder: (column) => column,
  );

  GeneratedColumn<double> get downloadProgress => $composableBuilder(
    column: $table.downloadProgress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get playbackPositionTicks => $composableBuilder(
    column: $table.playbackPositionTicks,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get progressSynced => $composableBuilder(
    column: $table.progressSynced,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get qualityPreset => $composableBuilder(
    column: $table.qualityPreset,
    builder: (column) => column,
  );

  GeneratedColumn<String> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => column);

  GeneratedColumn<String> get seasonId =>
      $composableBuilder(column: $table.seasonId, builder: (column) => column);

  GeneratedColumn<String> get seriesName => $composableBuilder(
    column: $table.seriesName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get seasonName => $composableBuilder(
    column: $table.seasonName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get indexNumber => $composableBuilder(
    column: $table.indexNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get parentIndexNumber => $composableBuilder(
    column: $table.parentIndexNumber,
    builder: (column) => column,
  );
}

class $$DownloadedItemsTableTableManager
    extends
        RootTableManager<
          _$OfflineDatabase,
          $DownloadedItemsTable,
          DownloadedItem,
          $$DownloadedItemsTableFilterComposer,
          $$DownloadedItemsTableOrderingComposer,
          $$DownloadedItemsTableAnnotationComposer,
          $$DownloadedItemsTableCreateCompanionBuilder,
          $$DownloadedItemsTableUpdateCompanionBuilder,
          (
            DownloadedItem,
            BaseReferences<
              _$OfflineDatabase,
              $DownloadedItemsTable,
              DownloadedItem
            >,
          ),
          DownloadedItem,
          PrefetchHooks Function()
        > {
  $$DownloadedItemsTableTableManager(
    _$OfflineDatabase db,
    $DownloadedItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadedItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadedItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadedItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> itemId = const Value.absent(),
                Value<String> serverId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> localFilePath = const Value.absent(),
                Value<String> metadataJson = const Value.absent(),
                Value<String?> posterPath = const Value.absent(),
                Value<String?> backdropPath = const Value.absent(),
                Value<String?> logoPath = const Value.absent(),
                Value<String?> thumbPath = const Value.absent(),
                Value<int> downloadStatus = const Value.absent(),
                Value<double> downloadProgress = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> fileSizeBytes = const Value.absent(),
                Value<int> playbackPositionTicks = const Value.absent(),
                Value<bool> progressSynced = const Value.absent(),
                Value<DateTime?> downloadedAt = const Value.absent(),
                Value<String> qualityPreset = const Value.absent(),
                Value<String?> seriesId = const Value.absent(),
                Value<String?> seasonId = const Value.absent(),
                Value<String?> seriesName = const Value.absent(),
                Value<String?> seasonName = const Value.absent(),
                Value<int?> indexNumber = const Value.absent(),
                Value<int?> parentIndexNumber = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadedItemsCompanion(
                itemId: itemId,
                serverId: serverId,
                type: type,
                name: name,
                localFilePath: localFilePath,
                metadataJson: metadataJson,
                posterPath: posterPath,
                backdropPath: backdropPath,
                logoPath: logoPath,
                thumbPath: thumbPath,
                downloadStatus: downloadStatus,
                downloadProgress: downloadProgress,
                errorMessage: errorMessage,
                fileSizeBytes: fileSizeBytes,
                playbackPositionTicks: playbackPositionTicks,
                progressSynced: progressSynced,
                downloadedAt: downloadedAt,
                qualityPreset: qualityPreset,
                seriesId: seriesId,
                seasonId: seasonId,
                seriesName: seriesName,
                seasonName: seasonName,
                indexNumber: indexNumber,
                parentIndexNumber: parentIndexNumber,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String itemId,
                required String serverId,
                required String type,
                required String name,
                Value<String?> localFilePath = const Value.absent(),
                required String metadataJson,
                Value<String?> posterPath = const Value.absent(),
                Value<String?> backdropPath = const Value.absent(),
                Value<String?> logoPath = const Value.absent(),
                Value<String?> thumbPath = const Value.absent(),
                required int downloadStatus,
                Value<double> downloadProgress = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> fileSizeBytes = const Value.absent(),
                Value<int> playbackPositionTicks = const Value.absent(),
                Value<bool> progressSynced = const Value.absent(),
                Value<DateTime?> downloadedAt = const Value.absent(),
                Value<String> qualityPreset = const Value.absent(),
                Value<String?> seriesId = const Value.absent(),
                Value<String?> seasonId = const Value.absent(),
                Value<String?> seriesName = const Value.absent(),
                Value<String?> seasonName = const Value.absent(),
                Value<int?> indexNumber = const Value.absent(),
                Value<int?> parentIndexNumber = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadedItemsCompanion.insert(
                itemId: itemId,
                serverId: serverId,
                type: type,
                name: name,
                localFilePath: localFilePath,
                metadataJson: metadataJson,
                posterPath: posterPath,
                backdropPath: backdropPath,
                logoPath: logoPath,
                thumbPath: thumbPath,
                downloadStatus: downloadStatus,
                downloadProgress: downloadProgress,
                errorMessage: errorMessage,
                fileSizeBytes: fileSizeBytes,
                playbackPositionTicks: playbackPositionTicks,
                progressSynced: progressSynced,
                downloadedAt: downloadedAt,
                qualityPreset: qualityPreset,
                seriesId: seriesId,
                seasonId: seasonId,
                seriesName: seriesName,
                seasonName: seasonName,
                indexNumber: indexNumber,
                parentIndexNumber: parentIndexNumber,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadedItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$OfflineDatabase,
      $DownloadedItemsTable,
      DownloadedItem,
      $$DownloadedItemsTableFilterComposer,
      $$DownloadedItemsTableOrderingComposer,
      $$DownloadedItemsTableAnnotationComposer,
      $$DownloadedItemsTableCreateCompanionBuilder,
      $$DownloadedItemsTableUpdateCompanionBuilder,
      (
        DownloadedItem,
        BaseReferences<
          _$OfflineDatabase,
          $DownloadedItemsTable,
          DownloadedItem
        >,
      ),
      DownloadedItem,
      PrefetchHooks Function()
    >;
typedef $$AdvancedFilterCatalogItemsTableCreateCompanionBuilder =
    AdvancedFilterCatalogItemsCompanion Function({
      required String serverId,
      required String userId,
      required String itemId,
      required String type,
      required String name,
      required String sortName,
      Value<int?> productionYear,
      required String metadataJson,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$AdvancedFilterCatalogItemsTableUpdateCompanionBuilder =
    AdvancedFilterCatalogItemsCompanion Function({
      Value<String> serverId,
      Value<String> userId,
      Value<String> itemId,
      Value<String> type,
      Value<String> name,
      Value<String> sortName,
      Value<int?> productionYear,
      Value<String> metadataJson,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$AdvancedFilterCatalogItemsTableFilterComposer
    extends Composer<_$OfflineDatabase, $AdvancedFilterCatalogItemsTable> {
  $$AdvancedFilterCatalogItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sortName => $composableBuilder(
    column: $table.sortName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get productionYear => $composableBuilder(
    column: $table.productionYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AdvancedFilterCatalogItemsTableOrderingComposer
    extends Composer<_$OfflineDatabase, $AdvancedFilterCatalogItemsTable> {
  $$AdvancedFilterCatalogItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sortName => $composableBuilder(
    column: $table.sortName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get productionYear => $composableBuilder(
    column: $table.productionYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AdvancedFilterCatalogItemsTableAnnotationComposer
    extends Composer<_$OfflineDatabase, $AdvancedFilterCatalogItemsTable> {
  $$AdvancedFilterCatalogItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get sortName =>
      $composableBuilder(column: $table.sortName, builder: (column) => column);

  GeneratedColumn<int> get productionYear => $composableBuilder(
    column: $table.productionYear,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$AdvancedFilterCatalogItemsTableTableManager
    extends
        RootTableManager<
          _$OfflineDatabase,
          $AdvancedFilterCatalogItemsTable,
          AdvancedFilterCatalogItem,
          $$AdvancedFilterCatalogItemsTableFilterComposer,
          $$AdvancedFilterCatalogItemsTableOrderingComposer,
          $$AdvancedFilterCatalogItemsTableAnnotationComposer,
          $$AdvancedFilterCatalogItemsTableCreateCompanionBuilder,
          $$AdvancedFilterCatalogItemsTableUpdateCompanionBuilder,
          (
            AdvancedFilterCatalogItem,
            BaseReferences<
              _$OfflineDatabase,
              $AdvancedFilterCatalogItemsTable,
              AdvancedFilterCatalogItem
            >,
          ),
          AdvancedFilterCatalogItem,
          PrefetchHooks Function()
        > {
  $$AdvancedFilterCatalogItemsTableTableManager(
    _$OfflineDatabase db,
    $AdvancedFilterCatalogItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AdvancedFilterCatalogItemsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AdvancedFilterCatalogItemsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AdvancedFilterCatalogItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> serverId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> sortName = const Value.absent(),
                Value<int?> productionYear = const Value.absent(),
                Value<String> metadataJson = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AdvancedFilterCatalogItemsCompanion(
                serverId: serverId,
                userId: userId,
                itemId: itemId,
                type: type,
                name: name,
                sortName: sortName,
                productionYear: productionYear,
                metadataJson: metadataJson,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String serverId,
                required String userId,
                required String itemId,
                required String type,
                required String name,
                required String sortName,
                Value<int?> productionYear = const Value.absent(),
                required String metadataJson,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => AdvancedFilterCatalogItemsCompanion.insert(
                serverId: serverId,
                userId: userId,
                itemId: itemId,
                type: type,
                name: name,
                sortName: sortName,
                productionYear: productionYear,
                metadataJson: metadataJson,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AdvancedFilterCatalogItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$OfflineDatabase,
      $AdvancedFilterCatalogItemsTable,
      AdvancedFilterCatalogItem,
      $$AdvancedFilterCatalogItemsTableFilterComposer,
      $$AdvancedFilterCatalogItemsTableOrderingComposer,
      $$AdvancedFilterCatalogItemsTableAnnotationComposer,
      $$AdvancedFilterCatalogItemsTableCreateCompanionBuilder,
      $$AdvancedFilterCatalogItemsTableUpdateCompanionBuilder,
      (
        AdvancedFilterCatalogItem,
        BaseReferences<
          _$OfflineDatabase,
          $AdvancedFilterCatalogItemsTable,
          AdvancedFilterCatalogItem
        >,
      ),
      AdvancedFilterCatalogItem,
      PrefetchHooks Function()
    >;
typedef $$AdvancedFilterCatalogItemGenresTableCreateCompanionBuilder =
    AdvancedFilterCatalogItemGenresCompanion Function({
      required String serverId,
      required String userId,
      required String itemId,
      required String genre,
      Value<int> rowid,
    });
typedef $$AdvancedFilterCatalogItemGenresTableUpdateCompanionBuilder =
    AdvancedFilterCatalogItemGenresCompanion Function({
      Value<String> serverId,
      Value<String> userId,
      Value<String> itemId,
      Value<String> genre,
      Value<int> rowid,
    });

class $$AdvancedFilterCatalogItemGenresTableFilterComposer
    extends Composer<_$OfflineDatabase, $AdvancedFilterCatalogItemGenresTable> {
  $$AdvancedFilterCatalogItemGenresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AdvancedFilterCatalogItemGenresTableOrderingComposer
    extends Composer<_$OfflineDatabase, $AdvancedFilterCatalogItemGenresTable> {
  $$AdvancedFilterCatalogItemGenresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AdvancedFilterCatalogItemGenresTableAnnotationComposer
    extends Composer<_$OfflineDatabase, $AdvancedFilterCatalogItemGenresTable> {
  $$AdvancedFilterCatalogItemGenresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);
}

class $$AdvancedFilterCatalogItemGenresTableTableManager
    extends
        RootTableManager<
          _$OfflineDatabase,
          $AdvancedFilterCatalogItemGenresTable,
          AdvancedFilterCatalogItemGenre,
          $$AdvancedFilterCatalogItemGenresTableFilterComposer,
          $$AdvancedFilterCatalogItemGenresTableOrderingComposer,
          $$AdvancedFilterCatalogItemGenresTableAnnotationComposer,
          $$AdvancedFilterCatalogItemGenresTableCreateCompanionBuilder,
          $$AdvancedFilterCatalogItemGenresTableUpdateCompanionBuilder,
          (
            AdvancedFilterCatalogItemGenre,
            BaseReferences<
              _$OfflineDatabase,
              $AdvancedFilterCatalogItemGenresTable,
              AdvancedFilterCatalogItemGenre
            >,
          ),
          AdvancedFilterCatalogItemGenre,
          PrefetchHooks Function()
        > {
  $$AdvancedFilterCatalogItemGenresTableTableManager(
    _$OfflineDatabase db,
    $AdvancedFilterCatalogItemGenresTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AdvancedFilterCatalogItemGenresTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AdvancedFilterCatalogItemGenresTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AdvancedFilterCatalogItemGenresTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> serverId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> genre = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AdvancedFilterCatalogItemGenresCompanion(
                serverId: serverId,
                userId: userId,
                itemId: itemId,
                genre: genre,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String serverId,
                required String userId,
                required String itemId,
                required String genre,
                Value<int> rowid = const Value.absent(),
              }) => AdvancedFilterCatalogItemGenresCompanion.insert(
                serverId: serverId,
                userId: userId,
                itemId: itemId,
                genre: genre,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AdvancedFilterCatalogItemGenresTableProcessedTableManager =
    ProcessedTableManager<
      _$OfflineDatabase,
      $AdvancedFilterCatalogItemGenresTable,
      AdvancedFilterCatalogItemGenre,
      $$AdvancedFilterCatalogItemGenresTableFilterComposer,
      $$AdvancedFilterCatalogItemGenresTableOrderingComposer,
      $$AdvancedFilterCatalogItemGenresTableAnnotationComposer,
      $$AdvancedFilterCatalogItemGenresTableCreateCompanionBuilder,
      $$AdvancedFilterCatalogItemGenresTableUpdateCompanionBuilder,
      (
        AdvancedFilterCatalogItemGenre,
        BaseReferences<
          _$OfflineDatabase,
          $AdvancedFilterCatalogItemGenresTable,
          AdvancedFilterCatalogItemGenre
        >,
      ),
      AdvancedFilterCatalogItemGenre,
      PrefetchHooks Function()
    >;
typedef $$AdvancedFilterCatalogItemRegionsTableCreateCompanionBuilder =
    AdvancedFilterCatalogItemRegionsCompanion Function({
      required String serverId,
      required String userId,
      required String itemId,
      required String region,
      Value<int> rowid,
    });
typedef $$AdvancedFilterCatalogItemRegionsTableUpdateCompanionBuilder =
    AdvancedFilterCatalogItemRegionsCompanion Function({
      Value<String> serverId,
      Value<String> userId,
      Value<String> itemId,
      Value<String> region,
      Value<int> rowid,
    });

class $$AdvancedFilterCatalogItemRegionsTableFilterComposer
    extends
        Composer<_$OfflineDatabase, $AdvancedFilterCatalogItemRegionsTable> {
  $$AdvancedFilterCatalogItemRegionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get region => $composableBuilder(
    column: $table.region,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AdvancedFilterCatalogItemRegionsTableOrderingComposer
    extends
        Composer<_$OfflineDatabase, $AdvancedFilterCatalogItemRegionsTable> {
  $$AdvancedFilterCatalogItemRegionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get region => $composableBuilder(
    column: $table.region,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AdvancedFilterCatalogItemRegionsTableAnnotationComposer
    extends
        Composer<_$OfflineDatabase, $AdvancedFilterCatalogItemRegionsTable> {
  $$AdvancedFilterCatalogItemRegionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get region =>
      $composableBuilder(column: $table.region, builder: (column) => column);
}

class $$AdvancedFilterCatalogItemRegionsTableTableManager
    extends
        RootTableManager<
          _$OfflineDatabase,
          $AdvancedFilterCatalogItemRegionsTable,
          AdvancedFilterCatalogItemRegion,
          $$AdvancedFilterCatalogItemRegionsTableFilterComposer,
          $$AdvancedFilterCatalogItemRegionsTableOrderingComposer,
          $$AdvancedFilterCatalogItemRegionsTableAnnotationComposer,
          $$AdvancedFilterCatalogItemRegionsTableCreateCompanionBuilder,
          $$AdvancedFilterCatalogItemRegionsTableUpdateCompanionBuilder,
          (
            AdvancedFilterCatalogItemRegion,
            BaseReferences<
              _$OfflineDatabase,
              $AdvancedFilterCatalogItemRegionsTable,
              AdvancedFilterCatalogItemRegion
            >,
          ),
          AdvancedFilterCatalogItemRegion,
          PrefetchHooks Function()
        > {
  $$AdvancedFilterCatalogItemRegionsTableTableManager(
    _$OfflineDatabase db,
    $AdvancedFilterCatalogItemRegionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AdvancedFilterCatalogItemRegionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AdvancedFilterCatalogItemRegionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AdvancedFilterCatalogItemRegionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> serverId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> region = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AdvancedFilterCatalogItemRegionsCompanion(
                serverId: serverId,
                userId: userId,
                itemId: itemId,
                region: region,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String serverId,
                required String userId,
                required String itemId,
                required String region,
                Value<int> rowid = const Value.absent(),
              }) => AdvancedFilterCatalogItemRegionsCompanion.insert(
                serverId: serverId,
                userId: userId,
                itemId: itemId,
                region: region,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AdvancedFilterCatalogItemRegionsTableProcessedTableManager =
    ProcessedTableManager<
      _$OfflineDatabase,
      $AdvancedFilterCatalogItemRegionsTable,
      AdvancedFilterCatalogItemRegion,
      $$AdvancedFilterCatalogItemRegionsTableFilterComposer,
      $$AdvancedFilterCatalogItemRegionsTableOrderingComposer,
      $$AdvancedFilterCatalogItemRegionsTableAnnotationComposer,
      $$AdvancedFilterCatalogItemRegionsTableCreateCompanionBuilder,
      $$AdvancedFilterCatalogItemRegionsTableUpdateCompanionBuilder,
      (
        AdvancedFilterCatalogItemRegion,
        BaseReferences<
          _$OfflineDatabase,
          $AdvancedFilterCatalogItemRegionsTable,
          AdvancedFilterCatalogItemRegion
        >,
      ),
      AdvancedFilterCatalogItemRegion,
      PrefetchHooks Function()
    >;
typedef $$AdvancedFilterCatalogSyncStatesTableCreateCompanionBuilder =
    AdvancedFilterCatalogSyncStatesCompanion Function({
      required String serverId,
      required String userId,
      required int cacheVersion,
      required int itemCount,
      required DateTime syncedAt,
      Value<int> rowid,
    });
typedef $$AdvancedFilterCatalogSyncStatesTableUpdateCompanionBuilder =
    AdvancedFilterCatalogSyncStatesCompanion Function({
      Value<String> serverId,
      Value<String> userId,
      Value<int> cacheVersion,
      Value<int> itemCount,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

class $$AdvancedFilterCatalogSyncStatesTableFilterComposer
    extends Composer<_$OfflineDatabase, $AdvancedFilterCatalogSyncStatesTable> {
  $$AdvancedFilterCatalogSyncStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cacheVersion => $composableBuilder(
    column: $table.cacheVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemCount => $composableBuilder(
    column: $table.itemCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AdvancedFilterCatalogSyncStatesTableOrderingComposer
    extends Composer<_$OfflineDatabase, $AdvancedFilterCatalogSyncStatesTable> {
  $$AdvancedFilterCatalogSyncStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cacheVersion => $composableBuilder(
    column: $table.cacheVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemCount => $composableBuilder(
    column: $table.itemCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AdvancedFilterCatalogSyncStatesTableAnnotationComposer
    extends Composer<_$OfflineDatabase, $AdvancedFilterCatalogSyncStatesTable> {
  $$AdvancedFilterCatalogSyncStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get cacheVersion => $composableBuilder(
    column: $table.cacheVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get itemCount =>
      $composableBuilder(column: $table.itemCount, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$AdvancedFilterCatalogSyncStatesTableTableManager
    extends
        RootTableManager<
          _$OfflineDatabase,
          $AdvancedFilterCatalogSyncStatesTable,
          AdvancedFilterCatalogSyncState,
          $$AdvancedFilterCatalogSyncStatesTableFilterComposer,
          $$AdvancedFilterCatalogSyncStatesTableOrderingComposer,
          $$AdvancedFilterCatalogSyncStatesTableAnnotationComposer,
          $$AdvancedFilterCatalogSyncStatesTableCreateCompanionBuilder,
          $$AdvancedFilterCatalogSyncStatesTableUpdateCompanionBuilder,
          (
            AdvancedFilterCatalogSyncState,
            BaseReferences<
              _$OfflineDatabase,
              $AdvancedFilterCatalogSyncStatesTable,
              AdvancedFilterCatalogSyncState
            >,
          ),
          AdvancedFilterCatalogSyncState,
          PrefetchHooks Function()
        > {
  $$AdvancedFilterCatalogSyncStatesTableTableManager(
    _$OfflineDatabase db,
    $AdvancedFilterCatalogSyncStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AdvancedFilterCatalogSyncStatesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AdvancedFilterCatalogSyncStatesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AdvancedFilterCatalogSyncStatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> serverId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> cacheVersion = const Value.absent(),
                Value<int> itemCount = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AdvancedFilterCatalogSyncStatesCompanion(
                serverId: serverId,
                userId: userId,
                cacheVersion: cacheVersion,
                itemCount: itemCount,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String serverId,
                required String userId,
                required int cacheVersion,
                required int itemCount,
                required DateTime syncedAt,
                Value<int> rowid = const Value.absent(),
              }) => AdvancedFilterCatalogSyncStatesCompanion.insert(
                serverId: serverId,
                userId: userId,
                cacheVersion: cacheVersion,
                itemCount: itemCount,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AdvancedFilterCatalogSyncStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$OfflineDatabase,
      $AdvancedFilterCatalogSyncStatesTable,
      AdvancedFilterCatalogSyncState,
      $$AdvancedFilterCatalogSyncStatesTableFilterComposer,
      $$AdvancedFilterCatalogSyncStatesTableOrderingComposer,
      $$AdvancedFilterCatalogSyncStatesTableAnnotationComposer,
      $$AdvancedFilterCatalogSyncStatesTableCreateCompanionBuilder,
      $$AdvancedFilterCatalogSyncStatesTableUpdateCompanionBuilder,
      (
        AdvancedFilterCatalogSyncState,
        BaseReferences<
          _$OfflineDatabase,
          $AdvancedFilterCatalogSyncStatesTable,
          AdvancedFilterCatalogSyncState
        >,
      ),
      AdvancedFilterCatalogSyncState,
      PrefetchHooks Function()
    >;

class $OfflineDatabaseManager {
  final _$OfflineDatabase _db;
  $OfflineDatabaseManager(this._db);
  $$DownloadedItemsTableTableManager get downloadedItems =>
      $$DownloadedItemsTableTableManager(_db, _db.downloadedItems);
  $$AdvancedFilterCatalogItemsTableTableManager
  get advancedFilterCatalogItems =>
      $$AdvancedFilterCatalogItemsTableTableManager(
        _db,
        _db.advancedFilterCatalogItems,
      );
  $$AdvancedFilterCatalogItemGenresTableTableManager
  get advancedFilterCatalogItemGenres =>
      $$AdvancedFilterCatalogItemGenresTableTableManager(
        _db,
        _db.advancedFilterCatalogItemGenres,
      );
  $$AdvancedFilterCatalogItemRegionsTableTableManager
  get advancedFilterCatalogItemRegions =>
      $$AdvancedFilterCatalogItemRegionsTableTableManager(
        _db,
        _db.advancedFilterCatalogItemRegions,
      );
  $$AdvancedFilterCatalogSyncStatesTableTableManager
  get advancedFilterCatalogSyncStates =>
      $$AdvancedFilterCatalogSyncStatesTableTableManager(
        _db,
        _db.advancedFilterCatalogSyncStates,
      );
}
