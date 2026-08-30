// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PlaylistsTable extends Playlists
    with TableInfo<$PlaylistsTable, Playlist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<PlaylistType, String> type =
      GeneratedColumn<String>('type', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<PlaylistType>($PlaylistsTable.$convertertype);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
      'url', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _epgUrlMeta = const VerificationMeta('epgUrl');
  @override
  late final GeneratedColumn<String> epgUrl = GeneratedColumn<String>(
      'epg_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _usernameMeta =
      const VerificationMeta('username');
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
      'username', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _credentialKeyMeta =
      const VerificationMeta('credentialKey');
  @override
  late final GeneratedColumn<String> credentialKey = GeneratedColumn<String>(
      'credential_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _xtreamPortOverrideMeta =
      const VerificationMeta('xtreamPortOverride');
  @override
  late final GeneratedColumn<int> xtreamPortOverride = GeneratedColumn<int>(
      'xtream_port_override', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lastSyncAtMeta =
      const VerificationMeta('lastSyncAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
      'last_sync_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<PlaylistSyncStatus, String>
      syncStatus = GeneratedColumn<String>('sync_status', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: Constant(PlaylistSyncStatus.idle.name))
          .withConverter<PlaylistSyncStatus>(
              $PlaylistsTable.$convertersyncStatus);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _allowInsecureTlsMeta =
      const VerificationMeta('allowInsecureTls');
  @override
  late final GeneratedColumn<bool> allowInsecureTls = GeneratedColumn<bool>(
      'allow_insecure_tls', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("allow_insecure_tls" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        type,
        url,
        epgUrl,
        username,
        credentialKey,
        xtreamPortOverride,
        lastSyncAt,
        syncStatus,
        createdAt,
        updatedAt,
        isActive,
        allowInsecureTls
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlists';
  @override
  VerificationContext validateIntegrity(Insertable<Playlist> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
          _urlMeta, url.isAcceptableOrUnknown(data['url']!, _urlMeta));
    }
    if (data.containsKey('epg_url')) {
      context.handle(_epgUrlMeta,
          epgUrl.isAcceptableOrUnknown(data['epg_url']!, _epgUrlMeta));
    }
    if (data.containsKey('username')) {
      context.handle(_usernameMeta,
          username.isAcceptableOrUnknown(data['username']!, _usernameMeta));
    }
    if (data.containsKey('credential_key')) {
      context.handle(
          _credentialKeyMeta,
          credentialKey.isAcceptableOrUnknown(
              data['credential_key']!, _credentialKeyMeta));
    }
    if (data.containsKey('xtream_port_override')) {
      context.handle(
          _xtreamPortOverrideMeta,
          xtreamPortOverride.isAcceptableOrUnknown(
              data['xtream_port_override']!, _xtreamPortOverrideMeta));
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
          _lastSyncAtMeta,
          lastSyncAt.isAcceptableOrUnknown(
              data['last_sync_at']!, _lastSyncAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('allow_insecure_tls')) {
      context.handle(
          _allowInsecureTlsMeta,
          allowInsecureTls.isAcceptableOrUnknown(
              data['allow_insecure_tls']!, _allowInsecureTlsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Playlist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Playlist(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: $PlaylistsTable.$convertertype.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!),
      url: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}url'])!,
      epgUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}epg_url']),
      username: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}username']),
      credentialKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}credential_key']),
      xtreamPortOverride: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}xtream_port_override']),
      lastSyncAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_sync_at']),
      syncStatus: $PlaylistsTable.$convertersyncStatus.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      allowInsecureTls: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}allow_insecure_tls'])!,
    );
  }

  @override
  $PlaylistsTable createAlias(String alias) {
    return $PlaylistsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PlaylistType, String, String> $convertertype =
      const EnumNameConverter<PlaylistType>(PlaylistType.values);
  static JsonTypeConverter2<PlaylistSyncStatus, String, String>
      $convertersyncStatus =
      const EnumNameConverter<PlaylistSyncStatus>(PlaylistSyncStatus.values);
}

class Playlist extends DataClass implements Insertable<Playlist> {
  final int id;
  final String name;
  final PlaylistType type;
  final String url;
  final String? epgUrl;
  final String? username;
  final String? credentialKey;
  final int? xtreamPortOverride;
  final DateTime? lastSyncAt;
  final PlaylistSyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  /// Per-source opt-in to accept invalid/self-signed TLS certificates
  /// from this playlist's host (ADR-002). Never enabled globally.
  final bool allowInsecureTls;
  const Playlist(
      {required this.id,
      required this.name,
      required this.type,
      required this.url,
      this.epgUrl,
      this.username,
      this.credentialKey,
      this.xtreamPortOverride,
      this.lastSyncAt,
      required this.syncStatus,
      required this.createdAt,
      required this.updatedAt,
      required this.isActive,
      required this.allowInsecureTls});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['type'] =
          Variable<String>($PlaylistsTable.$convertertype.toSql(type));
    }
    map['url'] = Variable<String>(url);
    if (!nullToAbsent || epgUrl != null) {
      map['epg_url'] = Variable<String>(epgUrl);
    }
    if (!nullToAbsent || username != null) {
      map['username'] = Variable<String>(username);
    }
    if (!nullToAbsent || credentialKey != null) {
      map['credential_key'] = Variable<String>(credentialKey);
    }
    if (!nullToAbsent || xtreamPortOverride != null) {
      map['xtream_port_override'] = Variable<int>(xtreamPortOverride);
    }
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    }
    {
      map['sync_status'] = Variable<String>(
          $PlaylistsTable.$convertersyncStatus.toSql(syncStatus));
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_active'] = Variable<bool>(isActive);
    map['allow_insecure_tls'] = Variable<bool>(allowInsecureTls);
    return map;
  }

  PlaylistsCompanion toCompanion(bool nullToAbsent) {
    return PlaylistsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      url: Value(url),
      epgUrl:
          epgUrl == null && nullToAbsent ? const Value.absent() : Value(epgUrl),
      username: username == null && nullToAbsent
          ? const Value.absent()
          : Value(username),
      credentialKey: credentialKey == null && nullToAbsent
          ? const Value.absent()
          : Value(credentialKey),
      xtreamPortOverride: xtreamPortOverride == null && nullToAbsent
          ? const Value.absent()
          : Value(xtreamPortOverride),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isActive: Value(isActive),
      allowInsecureTls: Value(allowInsecureTls),
    );
  }

  factory Playlist.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Playlist(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: $PlaylistsTable.$convertertype
          .fromJson(serializer.fromJson<String>(json['type'])),
      url: serializer.fromJson<String>(json['url']),
      epgUrl: serializer.fromJson<String?>(json['epgUrl']),
      username: serializer.fromJson<String?>(json['username']),
      credentialKey: serializer.fromJson<String?>(json['credentialKey']),
      xtreamPortOverride: serializer.fromJson<int?>(json['xtreamPortOverride']),
      lastSyncAt: serializer.fromJson<DateTime?>(json['lastSyncAt']),
      syncStatus: $PlaylistsTable.$convertersyncStatus
          .fromJson(serializer.fromJson<String>(json['syncStatus'])),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      allowInsecureTls: serializer.fromJson<bool>(json['allowInsecureTls']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer
          .toJson<String>($PlaylistsTable.$convertertype.toJson(type)),
      'url': serializer.toJson<String>(url),
      'epgUrl': serializer.toJson<String?>(epgUrl),
      'username': serializer.toJson<String?>(username),
      'credentialKey': serializer.toJson<String?>(credentialKey),
      'xtreamPortOverride': serializer.toJson<int?>(xtreamPortOverride),
      'lastSyncAt': serializer.toJson<DateTime?>(lastSyncAt),
      'syncStatus': serializer.toJson<String>(
          $PlaylistsTable.$convertersyncStatus.toJson(syncStatus)),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isActive': serializer.toJson<bool>(isActive),
      'allowInsecureTls': serializer.toJson<bool>(allowInsecureTls),
    };
  }

  Playlist copyWith(
          {int? id,
          String? name,
          PlaylistType? type,
          String? url,
          Value<String?> epgUrl = const Value.absent(),
          Value<String?> username = const Value.absent(),
          Value<String?> credentialKey = const Value.absent(),
          Value<int?> xtreamPortOverride = const Value.absent(),
          Value<DateTime?> lastSyncAt = const Value.absent(),
          PlaylistSyncStatus? syncStatus,
          DateTime? createdAt,
          DateTime? updatedAt,
          bool? isActive,
          bool? allowInsecureTls}) =>
      Playlist(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        url: url ?? this.url,
        epgUrl: epgUrl.present ? epgUrl.value : this.epgUrl,
        username: username.present ? username.value : this.username,
        credentialKey:
            credentialKey.present ? credentialKey.value : this.credentialKey,
        xtreamPortOverride: xtreamPortOverride.present
            ? xtreamPortOverride.value
            : this.xtreamPortOverride,
        lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isActive: isActive ?? this.isActive,
        allowInsecureTls: allowInsecureTls ?? this.allowInsecureTls,
      );
  Playlist copyWithCompanion(PlaylistsCompanion data) {
    return Playlist(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      url: data.url.present ? data.url.value : this.url,
      epgUrl: data.epgUrl.present ? data.epgUrl.value : this.epgUrl,
      username: data.username.present ? data.username.value : this.username,
      credentialKey: data.credentialKey.present
          ? data.credentialKey.value
          : this.credentialKey,
      xtreamPortOverride: data.xtreamPortOverride.present
          ? data.xtreamPortOverride.value
          : this.xtreamPortOverride,
      lastSyncAt:
          data.lastSyncAt.present ? data.lastSyncAt.value : this.lastSyncAt,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      allowInsecureTls: data.allowInsecureTls.present
          ? data.allowInsecureTls.value
          : this.allowInsecureTls,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Playlist(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('url: $url, ')
          ..write('epgUrl: $epgUrl, ')
          ..write('username: $username, ')
          ..write('credentialKey: $credentialKey, ')
          ..write('xtreamPortOverride: $xtreamPortOverride, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isActive: $isActive, ')
          ..write('allowInsecureTls: $allowInsecureTls')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      type,
      url,
      epgUrl,
      username,
      credentialKey,
      xtreamPortOverride,
      lastSyncAt,
      syncStatus,
      createdAt,
      updatedAt,
      isActive,
      allowInsecureTls);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Playlist &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.url == this.url &&
          other.epgUrl == this.epgUrl &&
          other.username == this.username &&
          other.credentialKey == this.credentialKey &&
          other.xtreamPortOverride == this.xtreamPortOverride &&
          other.lastSyncAt == this.lastSyncAt &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isActive == this.isActive &&
          other.allowInsecureTls == this.allowInsecureTls);
}

class PlaylistsCompanion extends UpdateCompanion<Playlist> {
  final Value<int> id;
  final Value<String> name;
  final Value<PlaylistType> type;
  final Value<String> url;
  final Value<String?> epgUrl;
  final Value<String?> username;
  final Value<String?> credentialKey;
  final Value<int?> xtreamPortOverride;
  final Value<DateTime?> lastSyncAt;
  final Value<PlaylistSyncStatus> syncStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isActive;
  final Value<bool> allowInsecureTls;
  const PlaylistsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.url = const Value.absent(),
    this.epgUrl = const Value.absent(),
    this.username = const Value.absent(),
    this.credentialKey = const Value.absent(),
    this.xtreamPortOverride = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.allowInsecureTls = const Value.absent(),
  });
  PlaylistsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required PlaylistType type,
    this.url = const Value.absent(),
    this.epgUrl = const Value.absent(),
    this.username = const Value.absent(),
    this.credentialKey = const Value.absent(),
    this.xtreamPortOverride = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.allowInsecureTls = const Value.absent(),
  })  : name = Value(name),
        type = Value(type);
  static Insertable<Playlist> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? url,
    Expression<String>? epgUrl,
    Expression<String>? username,
    Expression<String>? credentialKey,
    Expression<int>? xtreamPortOverride,
    Expression<DateTime>? lastSyncAt,
    Expression<String>? syncStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isActive,
    Expression<bool>? allowInsecureTls,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (url != null) 'url': url,
      if (epgUrl != null) 'epg_url': epgUrl,
      if (username != null) 'username': username,
      if (credentialKey != null) 'credential_key': credentialKey,
      if (xtreamPortOverride != null)
        'xtream_port_override': xtreamPortOverride,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isActive != null) 'is_active': isActive,
      if (allowInsecureTls != null) 'allow_insecure_tls': allowInsecureTls,
    });
  }

  PlaylistsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<PlaylistType>? type,
      Value<String>? url,
      Value<String?>? epgUrl,
      Value<String?>? username,
      Value<String?>? credentialKey,
      Value<int?>? xtreamPortOverride,
      Value<DateTime?>? lastSyncAt,
      Value<PlaylistSyncStatus>? syncStatus,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<bool>? isActive,
      Value<bool>? allowInsecureTls}) {
    return PlaylistsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      url: url ?? this.url,
      epgUrl: epgUrl ?? this.epgUrl,
      username: username ?? this.username,
      credentialKey: credentialKey ?? this.credentialKey,
      xtreamPortOverride: xtreamPortOverride ?? this.xtreamPortOverride,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      allowInsecureTls: allowInsecureTls ?? this.allowInsecureTls,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] =
          Variable<String>($PlaylistsTable.$convertertype.toSql(type.value));
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (epgUrl.present) {
      map['epg_url'] = Variable<String>(epgUrl.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (credentialKey.present) {
      map['credential_key'] = Variable<String>(credentialKey.value);
    }
    if (xtreamPortOverride.present) {
      map['xtream_port_override'] = Variable<int>(xtreamPortOverride.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
          $PlaylistsTable.$convertersyncStatus.toSql(syncStatus.value));
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (allowInsecureTls.present) {
      map['allow_insecure_tls'] = Variable<bool>(allowInsecureTls.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('url: $url, ')
          ..write('epgUrl: $epgUrl, ')
          ..write('username: $username, ')
          ..write('credentialKey: $credentialKey, ')
          ..write('xtreamPortOverride: $xtreamPortOverride, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isActive: $isActive, ')
          ..write('allowInsecureTls: $allowInsecureTls')
          ..write(')'))
        .toString();
  }
}

class $ChannelsTable extends Channels with TableInfo<$ChannelsTable, Channel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChannelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _playlistIdMeta =
      const VerificationMeta('playlistId');
  @override
  late final GeneratedColumn<int> playlistId = GeneratedColumn<int>(
      'playlist_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES playlists (id)'));
  static const VerificationMeta _sourceIdMeta =
      const VerificationMeta('sourceId');
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
      'source_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 500),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _streamUrlMeta =
      const VerificationMeta('streamUrl');
  @override
  late final GeneratedColumn<String> streamUrl = GeneratedColumn<String>(
      'stream_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _logoUrlMeta =
      const VerificationMeta('logoUrl');
  @override
  late final GeneratedColumn<String> logoUrl = GeneratedColumn<String>(
      'logo_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _groupNameMeta =
      const VerificationMeta('groupName');
  @override
  late final GeneratedColumn<String> groupName = GeneratedColumn<String>(
      'group_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tvgIdMeta = const VerificationMeta('tvgId');
  @override
  late final GeneratedColumn<String> tvgId = GeneratedColumn<String>(
      'tvg_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tvgNameMeta =
      const VerificationMeta('tvgName');
  @override
  late final GeneratedColumn<String> tvgName = GeneratedColumn<String>(
      'tvg_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  late final GeneratedColumnWithTypeConverter<ChannelSourceType, String>
      sourceType = GeneratedColumn<String>('source_type', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<ChannelSourceType>(
              $ChannelsTable.$convertersourceType);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        playlistId,
        sourceId,
        name,
        streamUrl,
        logoUrl,
        groupName,
        tvgId,
        tvgName,
        isActive,
        sourceType,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'channels';
  @override
  VerificationContext validateIntegrity(Insertable<Channel> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
          _playlistIdMeta,
          playlistId.isAcceptableOrUnknown(
              data['playlist_id']!, _playlistIdMeta));
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(_sourceIdMeta,
          sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('stream_url')) {
      context.handle(_streamUrlMeta,
          streamUrl.isAcceptableOrUnknown(data['stream_url']!, _streamUrlMeta));
    } else if (isInserting) {
      context.missing(_streamUrlMeta);
    }
    if (data.containsKey('logo_url')) {
      context.handle(_logoUrlMeta,
          logoUrl.isAcceptableOrUnknown(data['logo_url']!, _logoUrlMeta));
    }
    if (data.containsKey('group_name')) {
      context.handle(_groupNameMeta,
          groupName.isAcceptableOrUnknown(data['group_name']!, _groupNameMeta));
    }
    if (data.containsKey('tvg_id')) {
      context.handle(
          _tvgIdMeta, tvgId.isAcceptableOrUnknown(data['tvg_id']!, _tvgIdMeta));
    }
    if (data.containsKey('tvg_name')) {
      context.handle(_tvgNameMeta,
          tvgName.isAcceptableOrUnknown(data['tvg_name']!, _tvgNameMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Channel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Channel(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      playlistId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}playlist_id'])!,
      sourceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      streamUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stream_url'])!,
      logoUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}logo_url']),
      groupName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_name']),
      tvgId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tvg_id']),
      tvgName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tvg_name']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      sourceType: $ChannelsTable.$convertersourceType.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_type'])!),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ChannelsTable createAlias(String alias) {
    return $ChannelsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ChannelSourceType, String, String>
      $convertersourceType =
      const EnumNameConverter<ChannelSourceType>(ChannelSourceType.values);
}

class Channel extends DataClass implements Insertable<Channel> {
  final int id;
  final int playlistId;
  final String? sourceId;
  final String name;
  final String streamUrl;
  final String? logoUrl;
  final String? groupName;
  final String? tvgId;
  final String? tvgName;
  final bool isActive;
  final ChannelSourceType sourceType;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Channel(
      {required this.id,
      required this.playlistId,
      this.sourceId,
      required this.name,
      required this.streamUrl,
      this.logoUrl,
      this.groupName,
      this.tvgId,
      this.tvgName,
      required this.isActive,
      required this.sourceType,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['playlist_id'] = Variable<int>(playlistId);
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    map['name'] = Variable<String>(name);
    map['stream_url'] = Variable<String>(streamUrl);
    if (!nullToAbsent || logoUrl != null) {
      map['logo_url'] = Variable<String>(logoUrl);
    }
    if (!nullToAbsent || groupName != null) {
      map['group_name'] = Variable<String>(groupName);
    }
    if (!nullToAbsent || tvgId != null) {
      map['tvg_id'] = Variable<String>(tvgId);
    }
    if (!nullToAbsent || tvgName != null) {
      map['tvg_name'] = Variable<String>(tvgName);
    }
    map['is_active'] = Variable<bool>(isActive);
    {
      map['source_type'] = Variable<String>(
          $ChannelsTable.$convertersourceType.toSql(sourceType));
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ChannelsCompanion toCompanion(bool nullToAbsent) {
    return ChannelsCompanion(
      id: Value(id),
      playlistId: Value(playlistId),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      name: Value(name),
      streamUrl: Value(streamUrl),
      logoUrl: logoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(logoUrl),
      groupName: groupName == null && nullToAbsent
          ? const Value.absent()
          : Value(groupName),
      tvgId:
          tvgId == null && nullToAbsent ? const Value.absent() : Value(tvgId),
      tvgName: tvgName == null && nullToAbsent
          ? const Value.absent()
          : Value(tvgName),
      isActive: Value(isActive),
      sourceType: Value(sourceType),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Channel.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Channel(
      id: serializer.fromJson<int>(json['id']),
      playlistId: serializer.fromJson<int>(json['playlistId']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      name: serializer.fromJson<String>(json['name']),
      streamUrl: serializer.fromJson<String>(json['streamUrl']),
      logoUrl: serializer.fromJson<String?>(json['logoUrl']),
      groupName: serializer.fromJson<String?>(json['groupName']),
      tvgId: serializer.fromJson<String?>(json['tvgId']),
      tvgName: serializer.fromJson<String?>(json['tvgName']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      sourceType: $ChannelsTable.$convertersourceType
          .fromJson(serializer.fromJson<String>(json['sourceType'])),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playlistId': serializer.toJson<int>(playlistId),
      'sourceId': serializer.toJson<String?>(sourceId),
      'name': serializer.toJson<String>(name),
      'streamUrl': serializer.toJson<String>(streamUrl),
      'logoUrl': serializer.toJson<String?>(logoUrl),
      'groupName': serializer.toJson<String?>(groupName),
      'tvgId': serializer.toJson<String?>(tvgId),
      'tvgName': serializer.toJson<String?>(tvgName),
      'isActive': serializer.toJson<bool>(isActive),
      'sourceType': serializer.toJson<String>(
          $ChannelsTable.$convertersourceType.toJson(sourceType)),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Channel copyWith(
          {int? id,
          int? playlistId,
          Value<String?> sourceId = const Value.absent(),
          String? name,
          String? streamUrl,
          Value<String?> logoUrl = const Value.absent(),
          Value<String?> groupName = const Value.absent(),
          Value<String?> tvgId = const Value.absent(),
          Value<String?> tvgName = const Value.absent(),
          bool? isActive,
          ChannelSourceType? sourceType,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Channel(
        id: id ?? this.id,
        playlistId: playlistId ?? this.playlistId,
        sourceId: sourceId.present ? sourceId.value : this.sourceId,
        name: name ?? this.name,
        streamUrl: streamUrl ?? this.streamUrl,
        logoUrl: logoUrl.present ? logoUrl.value : this.logoUrl,
        groupName: groupName.present ? groupName.value : this.groupName,
        tvgId: tvgId.present ? tvgId.value : this.tvgId,
        tvgName: tvgName.present ? tvgName.value : this.tvgName,
        isActive: isActive ?? this.isActive,
        sourceType: sourceType ?? this.sourceType,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Channel copyWithCompanion(ChannelsCompanion data) {
    return Channel(
      id: data.id.present ? data.id.value : this.id,
      playlistId:
          data.playlistId.present ? data.playlistId.value : this.playlistId,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      name: data.name.present ? data.name.value : this.name,
      streamUrl: data.streamUrl.present ? data.streamUrl.value : this.streamUrl,
      logoUrl: data.logoUrl.present ? data.logoUrl.value : this.logoUrl,
      groupName: data.groupName.present ? data.groupName.value : this.groupName,
      tvgId: data.tvgId.present ? data.tvgId.value : this.tvgId,
      tvgName: data.tvgName.present ? data.tvgName.value : this.tvgName,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      sourceType:
          data.sourceType.present ? data.sourceType.value : this.sourceType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Channel(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('sourceId: $sourceId, ')
          ..write('name: $name, ')
          ..write('streamUrl: $streamUrl, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('groupName: $groupName, ')
          ..write('tvgId: $tvgId, ')
          ..write('tvgName: $tvgName, ')
          ..write('isActive: $isActive, ')
          ..write('sourceType: $sourceType, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      playlistId,
      sourceId,
      name,
      streamUrl,
      logoUrl,
      groupName,
      tvgId,
      tvgName,
      isActive,
      sourceType,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Channel &&
          other.id == this.id &&
          other.playlistId == this.playlistId &&
          other.sourceId == this.sourceId &&
          other.name == this.name &&
          other.streamUrl == this.streamUrl &&
          other.logoUrl == this.logoUrl &&
          other.groupName == this.groupName &&
          other.tvgId == this.tvgId &&
          other.tvgName == this.tvgName &&
          other.isActive == this.isActive &&
          other.sourceType == this.sourceType &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ChannelsCompanion extends UpdateCompanion<Channel> {
  final Value<int> id;
  final Value<int> playlistId;
  final Value<String?> sourceId;
  final Value<String> name;
  final Value<String> streamUrl;
  final Value<String?> logoUrl;
  final Value<String?> groupName;
  final Value<String?> tvgId;
  final Value<String?> tvgName;
  final Value<bool> isActive;
  final Value<ChannelSourceType> sourceType;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ChannelsCompanion({
    this.id = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.name = const Value.absent(),
    this.streamUrl = const Value.absent(),
    this.logoUrl = const Value.absent(),
    this.groupName = const Value.absent(),
    this.tvgId = const Value.absent(),
    this.tvgName = const Value.absent(),
    this.isActive = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ChannelsCompanion.insert({
    this.id = const Value.absent(),
    required int playlistId,
    this.sourceId = const Value.absent(),
    required String name,
    required String streamUrl,
    this.logoUrl = const Value.absent(),
    this.groupName = const Value.absent(),
    this.tvgId = const Value.absent(),
    this.tvgName = const Value.absent(),
    this.isActive = const Value.absent(),
    required ChannelSourceType sourceType,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : playlistId = Value(playlistId),
        name = Value(name),
        streamUrl = Value(streamUrl),
        sourceType = Value(sourceType);
  static Insertable<Channel> custom({
    Expression<int>? id,
    Expression<int>? playlistId,
    Expression<String>? sourceId,
    Expression<String>? name,
    Expression<String>? streamUrl,
    Expression<String>? logoUrl,
    Expression<String>? groupName,
    Expression<String>? tvgId,
    Expression<String>? tvgName,
    Expression<bool>? isActive,
    Expression<String>? sourceType,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playlistId != null) 'playlist_id': playlistId,
      if (sourceId != null) 'source_id': sourceId,
      if (name != null) 'name': name,
      if (streamUrl != null) 'stream_url': streamUrl,
      if (logoUrl != null) 'logo_url': logoUrl,
      if (groupName != null) 'group_name': groupName,
      if (tvgId != null) 'tvg_id': tvgId,
      if (tvgName != null) 'tvg_name': tvgName,
      if (isActive != null) 'is_active': isActive,
      if (sourceType != null) 'source_type': sourceType,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ChannelsCompanion copyWith(
      {Value<int>? id,
      Value<int>? playlistId,
      Value<String?>? sourceId,
      Value<String>? name,
      Value<String>? streamUrl,
      Value<String?>? logoUrl,
      Value<String?>? groupName,
      Value<String?>? tvgId,
      Value<String?>? tvgName,
      Value<bool>? isActive,
      Value<ChannelSourceType>? sourceType,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return ChannelsCompanion(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      sourceId: sourceId ?? this.sourceId,
      name: name ?? this.name,
      streamUrl: streamUrl ?? this.streamUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      groupName: groupName ?? this.groupName,
      tvgId: tvgId ?? this.tvgId,
      tvgName: tvgName ?? this.tvgName,
      isActive: isActive ?? this.isActive,
      sourceType: sourceType ?? this.sourceType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<int>(playlistId.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (streamUrl.present) {
      map['stream_url'] = Variable<String>(streamUrl.value);
    }
    if (logoUrl.present) {
      map['logo_url'] = Variable<String>(logoUrl.value);
    }
    if (groupName.present) {
      map['group_name'] = Variable<String>(groupName.value);
    }
    if (tvgId.present) {
      map['tvg_id'] = Variable<String>(tvgId.value);
    }
    if (tvgName.present) {
      map['tvg_name'] = Variable<String>(tvgName.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(
          $ChannelsTable.$convertersourceType.toSql(sourceType.value));
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChannelsCompanion(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('sourceId: $sourceId, ')
          ..write('name: $name, ')
          ..write('streamUrl: $streamUrl, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('groupName: $groupName, ')
          ..write('tvgId: $tvgId, ')
          ..write('tvgName: $tvgName, ')
          ..write('isActive: $isActive, ')
          ..write('sourceType: $sourceType, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $FavoritesTable extends Favorites
    with TableInfo<$FavoritesTable, Favorite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _channelIdMeta =
      const VerificationMeta('channelId');
  @override
  late final GeneratedColumn<int> channelId = GeneratedColumn<int>(
      'channel_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'UNIQUE REFERENCES channels (id)'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [id, channelId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites';
  @override
  VerificationContext validateIntegrity(Insertable<Favorite> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('channel_id')) {
      context.handle(_channelIdMeta,
          channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta));
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Favorite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Favorite(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      channelId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}channel_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $FavoritesTable createAlias(String alias) {
    return $FavoritesTable(attachedDatabase, alias);
  }
}

class Favorite extends DataClass implements Insertable<Favorite> {
  final int id;
  final int channelId;
  final DateTime createdAt;
  const Favorite(
      {required this.id, required this.channelId, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['channel_id'] = Variable<int>(channelId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FavoritesCompanion toCompanion(bool nullToAbsent) {
    return FavoritesCompanion(
      id: Value(id),
      channelId: Value(channelId),
      createdAt: Value(createdAt),
    );
  }

  factory Favorite.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Favorite(
      id: serializer.fromJson<int>(json['id']),
      channelId: serializer.fromJson<int>(json['channelId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'channelId': serializer.toJson<int>(channelId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Favorite copyWith({int? id, int? channelId, DateTime? createdAt}) => Favorite(
        id: id ?? this.id,
        channelId: channelId ?? this.channelId,
        createdAt: createdAt ?? this.createdAt,
      );
  Favorite copyWithCompanion(FavoritesCompanion data) {
    return Favorite(
      id: data.id.present ? data.id.value : this.id,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Favorite(')
          ..write('id: $id, ')
          ..write('channelId: $channelId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, channelId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Favorite &&
          other.id == this.id &&
          other.channelId == this.channelId &&
          other.createdAt == this.createdAt);
}

class FavoritesCompanion extends UpdateCompanion<Favorite> {
  final Value<int> id;
  final Value<int> channelId;
  final Value<DateTime> createdAt;
  const FavoritesCompanion({
    this.id = const Value.absent(),
    this.channelId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FavoritesCompanion.insert({
    this.id = const Value.absent(),
    required int channelId,
    this.createdAt = const Value.absent(),
  }) : channelId = Value(channelId);
  static Insertable<Favorite> custom({
    Expression<int>? id,
    Expression<int>? channelId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (channelId != null) 'channel_id': channelId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FavoritesCompanion copyWith(
      {Value<int>? id, Value<int>? channelId, Value<DateTime>? createdAt}) {
    return FavoritesCompanion(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<int>(channelId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesCompanion(')
          ..write('id: $id, ')
          ..write('channelId: $channelId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $WatchHistoryEntriesTable extends WatchHistoryEntries
    with TableInfo<$WatchHistoryEntriesTable, WatchHistoryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WatchHistoryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _channelIdMeta =
      const VerificationMeta('channelId');
  @override
  late final GeneratedColumn<int> channelId = GeneratedColumn<int>(
      'channel_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES channels (id)'));
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _lastWatchedAtMeta =
      const VerificationMeta('lastWatchedAt');
  @override
  late final GeneratedColumn<DateTime> lastWatchedAt =
      GeneratedColumn<DateTime>('last_watched_at', aliasedName, false,
          type: DriftSqlType.dateTime,
          requiredDuringInsert: false,
          defaultValue: currentDateAndTime);
  static const VerificationMeta _watchedDurationMsMeta =
      const VerificationMeta('watchedDurationMs');
  @override
  late final GeneratedColumn<int> watchedDurationMs = GeneratedColumn<int>(
      'watched_duration_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, channelId, startedAt, lastWatchedAt, watchedDurationMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'watch_history_entries';
  @override
  VerificationContext validateIntegrity(Insertable<WatchHistoryEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('channel_id')) {
      context.handle(_channelIdMeta,
          channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta));
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    }
    if (data.containsKey('last_watched_at')) {
      context.handle(
          _lastWatchedAtMeta,
          lastWatchedAt.isAcceptableOrUnknown(
              data['last_watched_at']!, _lastWatchedAtMeta));
    }
    if (data.containsKey('watched_duration_ms')) {
      context.handle(
          _watchedDurationMsMeta,
          watchedDurationMs.isAcceptableOrUnknown(
              data['watched_duration_ms']!, _watchedDurationMsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WatchHistoryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WatchHistoryEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      channelId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}channel_id'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!,
      lastWatchedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_watched_at'])!,
      watchedDurationMs: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}watched_duration_ms'])!,
    );
  }

  @override
  $WatchHistoryEntriesTable createAlias(String alias) {
    return $WatchHistoryEntriesTable(attachedDatabase, alias);
  }
}

class WatchHistoryEntry extends DataClass
    implements Insertable<WatchHistoryEntry> {
  final int id;
  final int channelId;
  final DateTime startedAt;
  final DateTime lastWatchedAt;
  final int watchedDurationMs;
  const WatchHistoryEntry(
      {required this.id,
      required this.channelId,
      required this.startedAt,
      required this.lastWatchedAt,
      required this.watchedDurationMs});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['channel_id'] = Variable<int>(channelId);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['last_watched_at'] = Variable<DateTime>(lastWatchedAt);
    map['watched_duration_ms'] = Variable<int>(watchedDurationMs);
    return map;
  }

  WatchHistoryEntriesCompanion toCompanion(bool nullToAbsent) {
    return WatchHistoryEntriesCompanion(
      id: Value(id),
      channelId: Value(channelId),
      startedAt: Value(startedAt),
      lastWatchedAt: Value(lastWatchedAt),
      watchedDurationMs: Value(watchedDurationMs),
    );
  }

  factory WatchHistoryEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WatchHistoryEntry(
      id: serializer.fromJson<int>(json['id']),
      channelId: serializer.fromJson<int>(json['channelId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      lastWatchedAt: serializer.fromJson<DateTime>(json['lastWatchedAt']),
      watchedDurationMs: serializer.fromJson<int>(json['watchedDurationMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'channelId': serializer.toJson<int>(channelId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'lastWatchedAt': serializer.toJson<DateTime>(lastWatchedAt),
      'watchedDurationMs': serializer.toJson<int>(watchedDurationMs),
    };
  }

  WatchHistoryEntry copyWith(
          {int? id,
          int? channelId,
          DateTime? startedAt,
          DateTime? lastWatchedAt,
          int? watchedDurationMs}) =>
      WatchHistoryEntry(
        id: id ?? this.id,
        channelId: channelId ?? this.channelId,
        startedAt: startedAt ?? this.startedAt,
        lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
        watchedDurationMs: watchedDurationMs ?? this.watchedDurationMs,
      );
  WatchHistoryEntry copyWithCompanion(WatchHistoryEntriesCompanion data) {
    return WatchHistoryEntry(
      id: data.id.present ? data.id.value : this.id,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      lastWatchedAt: data.lastWatchedAt.present
          ? data.lastWatchedAt.value
          : this.lastWatchedAt,
      watchedDurationMs: data.watchedDurationMs.present
          ? data.watchedDurationMs.value
          : this.watchedDurationMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WatchHistoryEntry(')
          ..write('id: $id, ')
          ..write('channelId: $channelId, ')
          ..write('startedAt: $startedAt, ')
          ..write('lastWatchedAt: $lastWatchedAt, ')
          ..write('watchedDurationMs: $watchedDurationMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, channelId, startedAt, lastWatchedAt, watchedDurationMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WatchHistoryEntry &&
          other.id == this.id &&
          other.channelId == this.channelId &&
          other.startedAt == this.startedAt &&
          other.lastWatchedAt == this.lastWatchedAt &&
          other.watchedDurationMs == this.watchedDurationMs);
}

class WatchHistoryEntriesCompanion extends UpdateCompanion<WatchHistoryEntry> {
  final Value<int> id;
  final Value<int> channelId;
  final Value<DateTime> startedAt;
  final Value<DateTime> lastWatchedAt;
  final Value<int> watchedDurationMs;
  const WatchHistoryEntriesCompanion({
    this.id = const Value.absent(),
    this.channelId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.lastWatchedAt = const Value.absent(),
    this.watchedDurationMs = const Value.absent(),
  });
  WatchHistoryEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int channelId,
    this.startedAt = const Value.absent(),
    this.lastWatchedAt = const Value.absent(),
    this.watchedDurationMs = const Value.absent(),
  }) : channelId = Value(channelId);
  static Insertable<WatchHistoryEntry> custom({
    Expression<int>? id,
    Expression<int>? channelId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? lastWatchedAt,
    Expression<int>? watchedDurationMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (channelId != null) 'channel_id': channelId,
      if (startedAt != null) 'started_at': startedAt,
      if (lastWatchedAt != null) 'last_watched_at': lastWatchedAt,
      if (watchedDurationMs != null) 'watched_duration_ms': watchedDurationMs,
    });
  }

  WatchHistoryEntriesCompanion copyWith(
      {Value<int>? id,
      Value<int>? channelId,
      Value<DateTime>? startedAt,
      Value<DateTime>? lastWatchedAt,
      Value<int>? watchedDurationMs}) {
    return WatchHistoryEntriesCompanion(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      startedAt: startedAt ?? this.startedAt,
      lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
      watchedDurationMs: watchedDurationMs ?? this.watchedDurationMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<int>(channelId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (lastWatchedAt.present) {
      map['last_watched_at'] = Variable<DateTime>(lastWatchedAt.value);
    }
    if (watchedDurationMs.present) {
      map['watched_duration_ms'] = Variable<int>(watchedDurationMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WatchHistoryEntriesCompanion(')
          ..write('id: $id, ')
          ..write('channelId: $channelId, ')
          ..write('startedAt: $startedAt, ')
          ..write('lastWatchedAt: $lastWatchedAt, ')
          ..write('watchedDurationMs: $watchedDurationMs')
          ..write(')'))
        .toString();
  }
}

class $EpgProgramsTable extends EpgPrograms
    with TableInfo<$EpgProgramsTable, EpgProgram> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpgProgramsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _channelIdMeta =
      const VerificationMeta('channelId');
  @override
  late final GeneratedColumn<int> channelId = GeneratedColumn<int>(
      'channel_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES channels (id)'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startTimeUtcMeta =
      const VerificationMeta('startTimeUtc');
  @override
  late final GeneratedColumn<DateTime> startTimeUtc = GeneratedColumn<DateTime>(
      'start_time_utc', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endTimeUtcMeta =
      const VerificationMeta('endTimeUtc');
  @override
  late final GeneratedColumn<DateTime> endTimeUtc = GeneratedColumn<DateTime>(
      'end_time_utc', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _imageUrlMeta =
      const VerificationMeta('imageUrl');
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
      'image_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        channelId,
        title,
        description,
        startTimeUtc,
        endTimeUtc,
        category,
        imageUrl
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'epg_programs';
  @override
  VerificationContext validateIntegrity(Insertable<EpgProgram> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('channel_id')) {
      context.handle(_channelIdMeta,
          channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta));
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('start_time_utc')) {
      context.handle(
          _startTimeUtcMeta,
          startTimeUtc.isAcceptableOrUnknown(
              data['start_time_utc']!, _startTimeUtcMeta));
    } else if (isInserting) {
      context.missing(_startTimeUtcMeta);
    }
    if (data.containsKey('end_time_utc')) {
      context.handle(
          _endTimeUtcMeta,
          endTimeUtc.isAcceptableOrUnknown(
              data['end_time_utc']!, _endTimeUtcMeta));
    } else if (isInserting) {
      context.missing(_endTimeUtcMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('image_url')) {
      context.handle(_imageUrlMeta,
          imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EpgProgram map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EpgProgram(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      channelId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}channel_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      startTimeUtc: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}start_time_utc'])!,
      endTimeUtc: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_time_utc'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
      imageUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_url']),
    );
  }

  @override
  $EpgProgramsTable createAlias(String alias) {
    return $EpgProgramsTable(attachedDatabase, alias);
  }
}

class EpgProgram extends DataClass implements Insertable<EpgProgram> {
  final int id;
  final int channelId;
  final String title;
  final String? description;
  final DateTime startTimeUtc;
  final DateTime endTimeUtc;
  final String? category;
  final String? imageUrl;
  const EpgProgram(
      {required this.id,
      required this.channelId,
      required this.title,
      this.description,
      required this.startTimeUtc,
      required this.endTimeUtc,
      this.category,
      this.imageUrl});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['channel_id'] = Variable<int>(channelId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['start_time_utc'] = Variable<DateTime>(startTimeUtc);
    map['end_time_utc'] = Variable<DateTime>(endTimeUtc);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    return map;
  }

  EpgProgramsCompanion toCompanion(bool nullToAbsent) {
    return EpgProgramsCompanion(
      id: Value(id),
      channelId: Value(channelId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      startTimeUtc: Value(startTimeUtc),
      endTimeUtc: Value(endTimeUtc),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
    );
  }

  factory EpgProgram.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EpgProgram(
      id: serializer.fromJson<int>(json['id']),
      channelId: serializer.fromJson<int>(json['channelId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      startTimeUtc: serializer.fromJson<DateTime>(json['startTimeUtc']),
      endTimeUtc: serializer.fromJson<DateTime>(json['endTimeUtc']),
      category: serializer.fromJson<String?>(json['category']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'channelId': serializer.toJson<int>(channelId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'startTimeUtc': serializer.toJson<DateTime>(startTimeUtc),
      'endTimeUtc': serializer.toJson<DateTime>(endTimeUtc),
      'category': serializer.toJson<String?>(category),
      'imageUrl': serializer.toJson<String?>(imageUrl),
    };
  }

  EpgProgram copyWith(
          {int? id,
          int? channelId,
          String? title,
          Value<String?> description = const Value.absent(),
          DateTime? startTimeUtc,
          DateTime? endTimeUtc,
          Value<String?> category = const Value.absent(),
          Value<String?> imageUrl = const Value.absent()}) =>
      EpgProgram(
        id: id ?? this.id,
        channelId: channelId ?? this.channelId,
        title: title ?? this.title,
        description: description.present ? description.value : this.description,
        startTimeUtc: startTimeUtc ?? this.startTimeUtc,
        endTimeUtc: endTimeUtc ?? this.endTimeUtc,
        category: category.present ? category.value : this.category,
        imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
      );
  EpgProgram copyWithCompanion(EpgProgramsCompanion data) {
    return EpgProgram(
      id: data.id.present ? data.id.value : this.id,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      startTimeUtc: data.startTimeUtc.present
          ? data.startTimeUtc.value
          : this.startTimeUtc,
      endTimeUtc:
          data.endTimeUtc.present ? data.endTimeUtc.value : this.endTimeUtc,
      category: data.category.present ? data.category.value : this.category,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EpgProgram(')
          ..write('id: $id, ')
          ..write('channelId: $channelId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('startTimeUtc: $startTimeUtc, ')
          ..write('endTimeUtc: $endTimeUtc, ')
          ..write('category: $category, ')
          ..write('imageUrl: $imageUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, channelId, title, description,
      startTimeUtc, endTimeUtc, category, imageUrl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EpgProgram &&
          other.id == this.id &&
          other.channelId == this.channelId &&
          other.title == this.title &&
          other.description == this.description &&
          other.startTimeUtc == this.startTimeUtc &&
          other.endTimeUtc == this.endTimeUtc &&
          other.category == this.category &&
          other.imageUrl == this.imageUrl);
}

class EpgProgramsCompanion extends UpdateCompanion<EpgProgram> {
  final Value<int> id;
  final Value<int> channelId;
  final Value<String> title;
  final Value<String?> description;
  final Value<DateTime> startTimeUtc;
  final Value<DateTime> endTimeUtc;
  final Value<String?> category;
  final Value<String?> imageUrl;
  const EpgProgramsCompanion({
    this.id = const Value.absent(),
    this.channelId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.startTimeUtc = const Value.absent(),
    this.endTimeUtc = const Value.absent(),
    this.category = const Value.absent(),
    this.imageUrl = const Value.absent(),
  });
  EpgProgramsCompanion.insert({
    this.id = const Value.absent(),
    required int channelId,
    required String title,
    this.description = const Value.absent(),
    required DateTime startTimeUtc,
    required DateTime endTimeUtc,
    this.category = const Value.absent(),
    this.imageUrl = const Value.absent(),
  })  : channelId = Value(channelId),
        title = Value(title),
        startTimeUtc = Value(startTimeUtc),
        endTimeUtc = Value(endTimeUtc);
  static Insertable<EpgProgram> custom({
    Expression<int>? id,
    Expression<int>? channelId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<DateTime>? startTimeUtc,
    Expression<DateTime>? endTimeUtc,
    Expression<String>? category,
    Expression<String>? imageUrl,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (channelId != null) 'channel_id': channelId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (startTimeUtc != null) 'start_time_utc': startTimeUtc,
      if (endTimeUtc != null) 'end_time_utc': endTimeUtc,
      if (category != null) 'category': category,
      if (imageUrl != null) 'image_url': imageUrl,
    });
  }

  EpgProgramsCompanion copyWith(
      {Value<int>? id,
      Value<int>? channelId,
      Value<String>? title,
      Value<String?>? description,
      Value<DateTime>? startTimeUtc,
      Value<DateTime>? endTimeUtc,
      Value<String?>? category,
      Value<String?>? imageUrl}) {
    return EpgProgramsCompanion(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      title: title ?? this.title,
      description: description ?? this.description,
      startTimeUtc: startTimeUtc ?? this.startTimeUtc,
      endTimeUtc: endTimeUtc ?? this.endTimeUtc,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<int>(channelId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (startTimeUtc.present) {
      map['start_time_utc'] = Variable<DateTime>(startTimeUtc.value);
    }
    if (endTimeUtc.present) {
      map['end_time_utc'] = Variable<DateTime>(endTimeUtc.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpgProgramsCompanion(')
          ..write('id: $id, ')
          ..write('channelId: $channelId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('startTimeUtc: $startTimeUtc, ')
          ..write('endTimeUtc: $endTimeUtc, ')
          ..write('category: $category, ')
          ..write('imageUrl: $imageUrl')
          ..write(')'))
        .toString();
  }
}

class $VodItemsTable extends VodItems with TableInfo<$VodItemsTable, VodItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VodItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _playlistIdMeta =
      const VerificationMeta('playlistId');
  @override
  late final GeneratedColumn<int> playlistId = GeneratedColumn<int>(
      'playlist_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES playlists (id)'));
  static const VerificationMeta _sourceIdMeta =
      const VerificationMeta('sourceId');
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
      'source_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 500),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _streamUrlMeta =
      const VerificationMeta('streamUrl');
  @override
  late final GeneratedColumn<String> streamUrl = GeneratedColumn<String>(
      'stream_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _logoUrlMeta =
      const VerificationMeta('logoUrl');
  @override
  late final GeneratedColumn<String> logoUrl = GeneratedColumn<String>(
      'logo_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryNameMeta =
      const VerificationMeta('categoryName');
  @override
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
      'category_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _plotMeta = const VerificationMeta('plot');
  @override
  late final GeneratedColumn<String> plot = GeneratedColumn<String>(
      'plot', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _castMeta = const VerificationMeta('cast');
  @override
  late final GeneratedColumn<String> cast = GeneratedColumn<String>(
      'cast', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _directorMeta =
      const VerificationMeta('director');
  @override
  late final GeneratedColumn<String> director = GeneratedColumn<String>(
      'director', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
      'genre', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
      'rating', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _durationMeta =
      const VerificationMeta('duration');
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
      'duration', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<String> year = GeneratedColumn<String>(
      'year', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _containerExtensionMeta =
      const VerificationMeta('containerExtension');
  @override
  late final GeneratedColumn<String> containerExtension =
      GeneratedColumn<String>('container_extension', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('mp4'));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _addedAtMeta =
      const VerificationMeta('addedAt');
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
      'added_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        playlistId,
        sourceId,
        name,
        streamUrl,
        logoUrl,
        categoryName,
        plot,
        cast,
        director,
        genre,
        rating,
        duration,
        year,
        containerExtension,
        isActive,
        addedAt,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vod_items';
  @override
  VerificationContext validateIntegrity(Insertable<VodItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
          _playlistIdMeta,
          playlistId.isAcceptableOrUnknown(
              data['playlist_id']!, _playlistIdMeta));
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(_sourceIdMeta,
          sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta));
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('stream_url')) {
      context.handle(_streamUrlMeta,
          streamUrl.isAcceptableOrUnknown(data['stream_url']!, _streamUrlMeta));
    } else if (isInserting) {
      context.missing(_streamUrlMeta);
    }
    if (data.containsKey('logo_url')) {
      context.handle(_logoUrlMeta,
          logoUrl.isAcceptableOrUnknown(data['logo_url']!, _logoUrlMeta));
    }
    if (data.containsKey('category_name')) {
      context.handle(
          _categoryNameMeta,
          categoryName.isAcceptableOrUnknown(
              data['category_name']!, _categoryNameMeta));
    }
    if (data.containsKey('plot')) {
      context.handle(
          _plotMeta, plot.isAcceptableOrUnknown(data['plot']!, _plotMeta));
    }
    if (data.containsKey('cast')) {
      context.handle(
          _castMeta, cast.isAcceptableOrUnknown(data['cast']!, _castMeta));
    }
    if (data.containsKey('director')) {
      context.handle(_directorMeta,
          director.isAcceptableOrUnknown(data['director']!, _directorMeta));
    }
    if (data.containsKey('genre')) {
      context.handle(
          _genreMeta, genre.isAcceptableOrUnknown(data['genre']!, _genreMeta));
    }
    if (data.containsKey('rating')) {
      context.handle(_ratingMeta,
          rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta));
    }
    if (data.containsKey('duration')) {
      context.handle(_durationMeta,
          duration.isAcceptableOrUnknown(data['duration']!, _durationMeta));
    }
    if (data.containsKey('year')) {
      context.handle(
          _yearMeta, year.isAcceptableOrUnknown(data['year']!, _yearMeta));
    }
    if (data.containsKey('container_extension')) {
      context.handle(
          _containerExtensionMeta,
          containerExtension.isAcceptableOrUnknown(
              data['container_extension']!, _containerExtensionMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta,
          addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VodItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VodItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      playlistId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}playlist_id'])!,
      sourceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      streamUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stream_url'])!,
      logoUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}logo_url']),
      categoryName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_name']),
      plot: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plot']),
      cast: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cast']),
      director: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}director']),
      genre: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}genre']),
      rating: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}rating']),
      duration: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration']),
      year: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}year']),
      containerExtension: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}container_extension'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      addedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}added_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $VodItemsTable createAlias(String alias) {
    return $VodItemsTable(attachedDatabase, alias);
  }
}

class VodItem extends DataClass implements Insertable<VodItem> {
  final int id;
  final int playlistId;
  final String sourceId;
  final String name;
  final String streamUrl;
  final String? logoUrl;
  final String? categoryName;
  final String? plot;
  final String? cast;
  final String? director;
  final String? genre;
  final double? rating;
  final int? duration;
  final String? year;
  final String containerExtension;
  final bool isActive;
  final DateTime? addedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const VodItem(
      {required this.id,
      required this.playlistId,
      required this.sourceId,
      required this.name,
      required this.streamUrl,
      this.logoUrl,
      this.categoryName,
      this.plot,
      this.cast,
      this.director,
      this.genre,
      this.rating,
      this.duration,
      this.year,
      required this.containerExtension,
      required this.isActive,
      this.addedAt,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['playlist_id'] = Variable<int>(playlistId);
    map['source_id'] = Variable<String>(sourceId);
    map['name'] = Variable<String>(name);
    map['stream_url'] = Variable<String>(streamUrl);
    if (!nullToAbsent || logoUrl != null) {
      map['logo_url'] = Variable<String>(logoUrl);
    }
    if (!nullToAbsent || categoryName != null) {
      map['category_name'] = Variable<String>(categoryName);
    }
    if (!nullToAbsent || plot != null) {
      map['plot'] = Variable<String>(plot);
    }
    if (!nullToAbsent || cast != null) {
      map['cast'] = Variable<String>(cast);
    }
    if (!nullToAbsent || director != null) {
      map['director'] = Variable<String>(director);
    }
    if (!nullToAbsent || genre != null) {
      map['genre'] = Variable<String>(genre);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<double>(rating);
    }
    if (!nullToAbsent || duration != null) {
      map['duration'] = Variable<int>(duration);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<String>(year);
    }
    map['container_extension'] = Variable<String>(containerExtension);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || addedAt != null) {
      map['added_at'] = Variable<DateTime>(addedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  VodItemsCompanion toCompanion(bool nullToAbsent) {
    return VodItemsCompanion(
      id: Value(id),
      playlistId: Value(playlistId),
      sourceId: Value(sourceId),
      name: Value(name),
      streamUrl: Value(streamUrl),
      logoUrl: logoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(logoUrl),
      categoryName: categoryName == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryName),
      plot: plot == null && nullToAbsent ? const Value.absent() : Value(plot),
      cast: cast == null && nullToAbsent ? const Value.absent() : Value(cast),
      director: director == null && nullToAbsent
          ? const Value.absent()
          : Value(director),
      genre:
          genre == null && nullToAbsent ? const Value.absent() : Value(genre),
      rating:
          rating == null && nullToAbsent ? const Value.absent() : Value(rating),
      duration: duration == null && nullToAbsent
          ? const Value.absent()
          : Value(duration),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      containerExtension: Value(containerExtension),
      isActive: Value(isActive),
      addedAt: addedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(addedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory VodItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VodItem(
      id: serializer.fromJson<int>(json['id']),
      playlistId: serializer.fromJson<int>(json['playlistId']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      name: serializer.fromJson<String>(json['name']),
      streamUrl: serializer.fromJson<String>(json['streamUrl']),
      logoUrl: serializer.fromJson<String?>(json['logoUrl']),
      categoryName: serializer.fromJson<String?>(json['categoryName']),
      plot: serializer.fromJson<String?>(json['plot']),
      cast: serializer.fromJson<String?>(json['cast']),
      director: serializer.fromJson<String?>(json['director']),
      genre: serializer.fromJson<String?>(json['genre']),
      rating: serializer.fromJson<double?>(json['rating']),
      duration: serializer.fromJson<int?>(json['duration']),
      year: serializer.fromJson<String?>(json['year']),
      containerExtension:
          serializer.fromJson<String>(json['containerExtension']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      addedAt: serializer.fromJson<DateTime?>(json['addedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playlistId': serializer.toJson<int>(playlistId),
      'sourceId': serializer.toJson<String>(sourceId),
      'name': serializer.toJson<String>(name),
      'streamUrl': serializer.toJson<String>(streamUrl),
      'logoUrl': serializer.toJson<String?>(logoUrl),
      'categoryName': serializer.toJson<String?>(categoryName),
      'plot': serializer.toJson<String?>(plot),
      'cast': serializer.toJson<String?>(cast),
      'director': serializer.toJson<String?>(director),
      'genre': serializer.toJson<String?>(genre),
      'rating': serializer.toJson<double?>(rating),
      'duration': serializer.toJson<int?>(duration),
      'year': serializer.toJson<String?>(year),
      'containerExtension': serializer.toJson<String>(containerExtension),
      'isActive': serializer.toJson<bool>(isActive),
      'addedAt': serializer.toJson<DateTime?>(addedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  VodItem copyWith(
          {int? id,
          int? playlistId,
          String? sourceId,
          String? name,
          String? streamUrl,
          Value<String?> logoUrl = const Value.absent(),
          Value<String?> categoryName = const Value.absent(),
          Value<String?> plot = const Value.absent(),
          Value<String?> cast = const Value.absent(),
          Value<String?> director = const Value.absent(),
          Value<String?> genre = const Value.absent(),
          Value<double?> rating = const Value.absent(),
          Value<int?> duration = const Value.absent(),
          Value<String?> year = const Value.absent(),
          String? containerExtension,
          bool? isActive,
          Value<DateTime?> addedAt = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      VodItem(
        id: id ?? this.id,
        playlistId: playlistId ?? this.playlistId,
        sourceId: sourceId ?? this.sourceId,
        name: name ?? this.name,
        streamUrl: streamUrl ?? this.streamUrl,
        logoUrl: logoUrl.present ? logoUrl.value : this.logoUrl,
        categoryName:
            categoryName.present ? categoryName.value : this.categoryName,
        plot: plot.present ? plot.value : this.plot,
        cast: cast.present ? cast.value : this.cast,
        director: director.present ? director.value : this.director,
        genre: genre.present ? genre.value : this.genre,
        rating: rating.present ? rating.value : this.rating,
        duration: duration.present ? duration.value : this.duration,
        year: year.present ? year.value : this.year,
        containerExtension: containerExtension ?? this.containerExtension,
        isActive: isActive ?? this.isActive,
        addedAt: addedAt.present ? addedAt.value : this.addedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  VodItem copyWithCompanion(VodItemsCompanion data) {
    return VodItem(
      id: data.id.present ? data.id.value : this.id,
      playlistId:
          data.playlistId.present ? data.playlistId.value : this.playlistId,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      name: data.name.present ? data.name.value : this.name,
      streamUrl: data.streamUrl.present ? data.streamUrl.value : this.streamUrl,
      logoUrl: data.logoUrl.present ? data.logoUrl.value : this.logoUrl,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      plot: data.plot.present ? data.plot.value : this.plot,
      cast: data.cast.present ? data.cast.value : this.cast,
      director: data.director.present ? data.director.value : this.director,
      genre: data.genre.present ? data.genre.value : this.genre,
      rating: data.rating.present ? data.rating.value : this.rating,
      duration: data.duration.present ? data.duration.value : this.duration,
      year: data.year.present ? data.year.value : this.year,
      containerExtension: data.containerExtension.present
          ? data.containerExtension.value
          : this.containerExtension,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VodItem(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('sourceId: $sourceId, ')
          ..write('name: $name, ')
          ..write('streamUrl: $streamUrl, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('categoryName: $categoryName, ')
          ..write('plot: $plot, ')
          ..write('cast: $cast, ')
          ..write('director: $director, ')
          ..write('genre: $genre, ')
          ..write('rating: $rating, ')
          ..write('duration: $duration, ')
          ..write('year: $year, ')
          ..write('containerExtension: $containerExtension, ')
          ..write('isActive: $isActive, ')
          ..write('addedAt: $addedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      playlistId,
      sourceId,
      name,
      streamUrl,
      logoUrl,
      categoryName,
      plot,
      cast,
      director,
      genre,
      rating,
      duration,
      year,
      containerExtension,
      isActive,
      addedAt,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VodItem &&
          other.id == this.id &&
          other.playlistId == this.playlistId &&
          other.sourceId == this.sourceId &&
          other.name == this.name &&
          other.streamUrl == this.streamUrl &&
          other.logoUrl == this.logoUrl &&
          other.categoryName == this.categoryName &&
          other.plot == this.plot &&
          other.cast == this.cast &&
          other.director == this.director &&
          other.genre == this.genre &&
          other.rating == this.rating &&
          other.duration == this.duration &&
          other.year == this.year &&
          other.containerExtension == this.containerExtension &&
          other.isActive == this.isActive &&
          other.addedAt == this.addedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class VodItemsCompanion extends UpdateCompanion<VodItem> {
  final Value<int> id;
  final Value<int> playlistId;
  final Value<String> sourceId;
  final Value<String> name;
  final Value<String> streamUrl;
  final Value<String?> logoUrl;
  final Value<String?> categoryName;
  final Value<String?> plot;
  final Value<String?> cast;
  final Value<String?> director;
  final Value<String?> genre;
  final Value<double?> rating;
  final Value<int?> duration;
  final Value<String?> year;
  final Value<String> containerExtension;
  final Value<bool> isActive;
  final Value<DateTime?> addedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const VodItemsCompanion({
    this.id = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.name = const Value.absent(),
    this.streamUrl = const Value.absent(),
    this.logoUrl = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.plot = const Value.absent(),
    this.cast = const Value.absent(),
    this.director = const Value.absent(),
    this.genre = const Value.absent(),
    this.rating = const Value.absent(),
    this.duration = const Value.absent(),
    this.year = const Value.absent(),
    this.containerExtension = const Value.absent(),
    this.isActive = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  VodItemsCompanion.insert({
    this.id = const Value.absent(),
    required int playlistId,
    required String sourceId,
    required String name,
    required String streamUrl,
    this.logoUrl = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.plot = const Value.absent(),
    this.cast = const Value.absent(),
    this.director = const Value.absent(),
    this.genre = const Value.absent(),
    this.rating = const Value.absent(),
    this.duration = const Value.absent(),
    this.year = const Value.absent(),
    this.containerExtension = const Value.absent(),
    this.isActive = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : playlistId = Value(playlistId),
        sourceId = Value(sourceId),
        name = Value(name),
        streamUrl = Value(streamUrl);
  static Insertable<VodItem> custom({
    Expression<int>? id,
    Expression<int>? playlistId,
    Expression<String>? sourceId,
    Expression<String>? name,
    Expression<String>? streamUrl,
    Expression<String>? logoUrl,
    Expression<String>? categoryName,
    Expression<String>? plot,
    Expression<String>? cast,
    Expression<String>? director,
    Expression<String>? genre,
    Expression<double>? rating,
    Expression<int>? duration,
    Expression<String>? year,
    Expression<String>? containerExtension,
    Expression<bool>? isActive,
    Expression<DateTime>? addedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playlistId != null) 'playlist_id': playlistId,
      if (sourceId != null) 'source_id': sourceId,
      if (name != null) 'name': name,
      if (streamUrl != null) 'stream_url': streamUrl,
      if (logoUrl != null) 'logo_url': logoUrl,
      if (categoryName != null) 'category_name': categoryName,
      if (plot != null) 'plot': plot,
      if (cast != null) 'cast': cast,
      if (director != null) 'director': director,
      if (genre != null) 'genre': genre,
      if (rating != null) 'rating': rating,
      if (duration != null) 'duration': duration,
      if (year != null) 'year': year,
      if (containerExtension != null) 'container_extension': containerExtension,
      if (isActive != null) 'is_active': isActive,
      if (addedAt != null) 'added_at': addedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  VodItemsCompanion copyWith(
      {Value<int>? id,
      Value<int>? playlistId,
      Value<String>? sourceId,
      Value<String>? name,
      Value<String>? streamUrl,
      Value<String?>? logoUrl,
      Value<String?>? categoryName,
      Value<String?>? plot,
      Value<String?>? cast,
      Value<String?>? director,
      Value<String?>? genre,
      Value<double?>? rating,
      Value<int?>? duration,
      Value<String?>? year,
      Value<String>? containerExtension,
      Value<bool>? isActive,
      Value<DateTime?>? addedAt,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return VodItemsCompanion(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      sourceId: sourceId ?? this.sourceId,
      name: name ?? this.name,
      streamUrl: streamUrl ?? this.streamUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      categoryName: categoryName ?? this.categoryName,
      plot: plot ?? this.plot,
      cast: cast ?? this.cast,
      director: director ?? this.director,
      genre: genre ?? this.genre,
      rating: rating ?? this.rating,
      duration: duration ?? this.duration,
      year: year ?? this.year,
      containerExtension: containerExtension ?? this.containerExtension,
      isActive: isActive ?? this.isActive,
      addedAt: addedAt ?? this.addedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<int>(playlistId.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (streamUrl.present) {
      map['stream_url'] = Variable<String>(streamUrl.value);
    }
    if (logoUrl.present) {
      map['logo_url'] = Variable<String>(logoUrl.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (plot.present) {
      map['plot'] = Variable<String>(plot.value);
    }
    if (cast.present) {
      map['cast'] = Variable<String>(cast.value);
    }
    if (director.present) {
      map['director'] = Variable<String>(director.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (year.present) {
      map['year'] = Variable<String>(year.value);
    }
    if (containerExtension.present) {
      map['container_extension'] = Variable<String>(containerExtension.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VodItemsCompanion(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('sourceId: $sourceId, ')
          ..write('name: $name, ')
          ..write('streamUrl: $streamUrl, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('categoryName: $categoryName, ')
          ..write('plot: $plot, ')
          ..write('cast: $cast, ')
          ..write('director: $director, ')
          ..write('genre: $genre, ')
          ..write('rating: $rating, ')
          ..write('duration: $duration, ')
          ..write('year: $year, ')
          ..write('containerExtension: $containerExtension, ')
          ..write('isActive: $isActive, ')
          ..write('addedAt: $addedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SeriesItemsTable extends SeriesItems
    with TableInfo<$SeriesItemsTable, SeriesItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeriesItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _playlistIdMeta =
      const VerificationMeta('playlistId');
  @override
  late final GeneratedColumn<int> playlistId = GeneratedColumn<int>(
      'playlist_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES playlists (id)'));
  static const VerificationMeta _sourceIdMeta =
      const VerificationMeta('sourceId');
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
      'source_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 500),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _coverUrlMeta =
      const VerificationMeta('coverUrl');
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
      'cover_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryNameMeta =
      const VerificationMeta('categoryName');
  @override
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
      'category_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _plotMeta = const VerificationMeta('plot');
  @override
  late final GeneratedColumn<String> plot = GeneratedColumn<String>(
      'plot', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _castMeta = const VerificationMeta('cast');
  @override
  late final GeneratedColumn<String> cast = GeneratedColumn<String>(
      'cast', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _directorMeta =
      const VerificationMeta('director');
  @override
  late final GeneratedColumn<String> director = GeneratedColumn<String>(
      'director', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
      'genre', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
      'rating', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<String> year = GeneratedColumn<String>(
      'year', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _backdropUrlMeta =
      const VerificationMeta('backdropUrl');
  @override
  late final GeneratedColumn<String> backdropUrl = GeneratedColumn<String>(
      'backdrop_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        playlistId,
        sourceId,
        name,
        coverUrl,
        categoryName,
        plot,
        cast,
        director,
        genre,
        rating,
        year,
        backdropUrl,
        isActive,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'series_items';
  @override
  VerificationContext validateIntegrity(Insertable<SeriesItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
          _playlistIdMeta,
          playlistId.isAcceptableOrUnknown(
              data['playlist_id']!, _playlistIdMeta));
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(_sourceIdMeta,
          sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta));
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('cover_url')) {
      context.handle(_coverUrlMeta,
          coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta));
    }
    if (data.containsKey('category_name')) {
      context.handle(
          _categoryNameMeta,
          categoryName.isAcceptableOrUnknown(
              data['category_name']!, _categoryNameMeta));
    }
    if (data.containsKey('plot')) {
      context.handle(
          _plotMeta, plot.isAcceptableOrUnknown(data['plot']!, _plotMeta));
    }
    if (data.containsKey('cast')) {
      context.handle(
          _castMeta, cast.isAcceptableOrUnknown(data['cast']!, _castMeta));
    }
    if (data.containsKey('director')) {
      context.handle(_directorMeta,
          director.isAcceptableOrUnknown(data['director']!, _directorMeta));
    }
    if (data.containsKey('genre')) {
      context.handle(
          _genreMeta, genre.isAcceptableOrUnknown(data['genre']!, _genreMeta));
    }
    if (data.containsKey('rating')) {
      context.handle(_ratingMeta,
          rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta));
    }
    if (data.containsKey('year')) {
      context.handle(
          _yearMeta, year.isAcceptableOrUnknown(data['year']!, _yearMeta));
    }
    if (data.containsKey('backdrop_url')) {
      context.handle(
          _backdropUrlMeta,
          backdropUrl.isAcceptableOrUnknown(
              data['backdrop_url']!, _backdropUrlMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SeriesItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeriesItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      playlistId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}playlist_id'])!,
      sourceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      coverUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_url']),
      categoryName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_name']),
      plot: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plot']),
      cast: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cast']),
      director: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}director']),
      genre: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}genre']),
      rating: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}rating']),
      year: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}year']),
      backdropUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}backdrop_url']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SeriesItemsTable createAlias(String alias) {
    return $SeriesItemsTable(attachedDatabase, alias);
  }
}

class SeriesItem extends DataClass implements Insertable<SeriesItem> {
  final int id;
  final int playlistId;
  final String sourceId;
  final String name;
  final String? coverUrl;
  final String? categoryName;
  final String? plot;
  final String? cast;
  final String? director;
  final String? genre;
  final double? rating;
  final String? year;
  final String? backdropUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SeriesItem(
      {required this.id,
      required this.playlistId,
      required this.sourceId,
      required this.name,
      this.coverUrl,
      this.categoryName,
      this.plot,
      this.cast,
      this.director,
      this.genre,
      this.rating,
      this.year,
      this.backdropUrl,
      required this.isActive,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['playlist_id'] = Variable<int>(playlistId);
    map['source_id'] = Variable<String>(sourceId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    if (!nullToAbsent || categoryName != null) {
      map['category_name'] = Variable<String>(categoryName);
    }
    if (!nullToAbsent || plot != null) {
      map['plot'] = Variable<String>(plot);
    }
    if (!nullToAbsent || cast != null) {
      map['cast'] = Variable<String>(cast);
    }
    if (!nullToAbsent || director != null) {
      map['director'] = Variable<String>(director);
    }
    if (!nullToAbsent || genre != null) {
      map['genre'] = Variable<String>(genre);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<double>(rating);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<String>(year);
    }
    if (!nullToAbsent || backdropUrl != null) {
      map['backdrop_url'] = Variable<String>(backdropUrl);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SeriesItemsCompanion toCompanion(bool nullToAbsent) {
    return SeriesItemsCompanion(
      id: Value(id),
      playlistId: Value(playlistId),
      sourceId: Value(sourceId),
      name: Value(name),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      categoryName: categoryName == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryName),
      plot: plot == null && nullToAbsent ? const Value.absent() : Value(plot),
      cast: cast == null && nullToAbsent ? const Value.absent() : Value(cast),
      director: director == null && nullToAbsent
          ? const Value.absent()
          : Value(director),
      genre:
          genre == null && nullToAbsent ? const Value.absent() : Value(genre),
      rating:
          rating == null && nullToAbsent ? const Value.absent() : Value(rating),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      backdropUrl: backdropUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(backdropUrl),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SeriesItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeriesItem(
      id: serializer.fromJson<int>(json['id']),
      playlistId: serializer.fromJson<int>(json['playlistId']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      name: serializer.fromJson<String>(json['name']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      categoryName: serializer.fromJson<String?>(json['categoryName']),
      plot: serializer.fromJson<String?>(json['plot']),
      cast: serializer.fromJson<String?>(json['cast']),
      director: serializer.fromJson<String?>(json['director']),
      genre: serializer.fromJson<String?>(json['genre']),
      rating: serializer.fromJson<double?>(json['rating']),
      year: serializer.fromJson<String?>(json['year']),
      backdropUrl: serializer.fromJson<String?>(json['backdropUrl']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playlistId': serializer.toJson<int>(playlistId),
      'sourceId': serializer.toJson<String>(sourceId),
      'name': serializer.toJson<String>(name),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'categoryName': serializer.toJson<String?>(categoryName),
      'plot': serializer.toJson<String?>(plot),
      'cast': serializer.toJson<String?>(cast),
      'director': serializer.toJson<String?>(director),
      'genre': serializer.toJson<String?>(genre),
      'rating': serializer.toJson<double?>(rating),
      'year': serializer.toJson<String?>(year),
      'backdropUrl': serializer.toJson<String?>(backdropUrl),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SeriesItem copyWith(
          {int? id,
          int? playlistId,
          String? sourceId,
          String? name,
          Value<String?> coverUrl = const Value.absent(),
          Value<String?> categoryName = const Value.absent(),
          Value<String?> plot = const Value.absent(),
          Value<String?> cast = const Value.absent(),
          Value<String?> director = const Value.absent(),
          Value<String?> genre = const Value.absent(),
          Value<double?> rating = const Value.absent(),
          Value<String?> year = const Value.absent(),
          Value<String?> backdropUrl = const Value.absent(),
          bool? isActive,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      SeriesItem(
        id: id ?? this.id,
        playlistId: playlistId ?? this.playlistId,
        sourceId: sourceId ?? this.sourceId,
        name: name ?? this.name,
        coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
        categoryName:
            categoryName.present ? categoryName.value : this.categoryName,
        plot: plot.present ? plot.value : this.plot,
        cast: cast.present ? cast.value : this.cast,
        director: director.present ? director.value : this.director,
        genre: genre.present ? genre.value : this.genre,
        rating: rating.present ? rating.value : this.rating,
        year: year.present ? year.value : this.year,
        backdropUrl: backdropUrl.present ? backdropUrl.value : this.backdropUrl,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SeriesItem copyWithCompanion(SeriesItemsCompanion data) {
    return SeriesItem(
      id: data.id.present ? data.id.value : this.id,
      playlistId:
          data.playlistId.present ? data.playlistId.value : this.playlistId,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      name: data.name.present ? data.name.value : this.name,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      plot: data.plot.present ? data.plot.value : this.plot,
      cast: data.cast.present ? data.cast.value : this.cast,
      director: data.director.present ? data.director.value : this.director,
      genre: data.genre.present ? data.genre.value : this.genre,
      rating: data.rating.present ? data.rating.value : this.rating,
      year: data.year.present ? data.year.value : this.year,
      backdropUrl:
          data.backdropUrl.present ? data.backdropUrl.value : this.backdropUrl,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeriesItem(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('sourceId: $sourceId, ')
          ..write('name: $name, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('categoryName: $categoryName, ')
          ..write('plot: $plot, ')
          ..write('cast: $cast, ')
          ..write('director: $director, ')
          ..write('genre: $genre, ')
          ..write('rating: $rating, ')
          ..write('year: $year, ')
          ..write('backdropUrl: $backdropUrl, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      playlistId,
      sourceId,
      name,
      coverUrl,
      categoryName,
      plot,
      cast,
      director,
      genre,
      rating,
      year,
      backdropUrl,
      isActive,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeriesItem &&
          other.id == this.id &&
          other.playlistId == this.playlistId &&
          other.sourceId == this.sourceId &&
          other.name == this.name &&
          other.coverUrl == this.coverUrl &&
          other.categoryName == this.categoryName &&
          other.plot == this.plot &&
          other.cast == this.cast &&
          other.director == this.director &&
          other.genre == this.genre &&
          other.rating == this.rating &&
          other.year == this.year &&
          other.backdropUrl == this.backdropUrl &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SeriesItemsCompanion extends UpdateCompanion<SeriesItem> {
  final Value<int> id;
  final Value<int> playlistId;
  final Value<String> sourceId;
  final Value<String> name;
  final Value<String?> coverUrl;
  final Value<String?> categoryName;
  final Value<String?> plot;
  final Value<String?> cast;
  final Value<String?> director;
  final Value<String?> genre;
  final Value<double?> rating;
  final Value<String?> year;
  final Value<String?> backdropUrl;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SeriesItemsCompanion({
    this.id = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.name = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.plot = const Value.absent(),
    this.cast = const Value.absent(),
    this.director = const Value.absent(),
    this.genre = const Value.absent(),
    this.rating = const Value.absent(),
    this.year = const Value.absent(),
    this.backdropUrl = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SeriesItemsCompanion.insert({
    this.id = const Value.absent(),
    required int playlistId,
    required String sourceId,
    required String name,
    this.coverUrl = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.plot = const Value.absent(),
    this.cast = const Value.absent(),
    this.director = const Value.absent(),
    this.genre = const Value.absent(),
    this.rating = const Value.absent(),
    this.year = const Value.absent(),
    this.backdropUrl = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : playlistId = Value(playlistId),
        sourceId = Value(sourceId),
        name = Value(name);
  static Insertable<SeriesItem> custom({
    Expression<int>? id,
    Expression<int>? playlistId,
    Expression<String>? sourceId,
    Expression<String>? name,
    Expression<String>? coverUrl,
    Expression<String>? categoryName,
    Expression<String>? plot,
    Expression<String>? cast,
    Expression<String>? director,
    Expression<String>? genre,
    Expression<double>? rating,
    Expression<String>? year,
    Expression<String>? backdropUrl,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playlistId != null) 'playlist_id': playlistId,
      if (sourceId != null) 'source_id': sourceId,
      if (name != null) 'name': name,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (categoryName != null) 'category_name': categoryName,
      if (plot != null) 'plot': plot,
      if (cast != null) 'cast': cast,
      if (director != null) 'director': director,
      if (genre != null) 'genre': genre,
      if (rating != null) 'rating': rating,
      if (year != null) 'year': year,
      if (backdropUrl != null) 'backdrop_url': backdropUrl,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SeriesItemsCompanion copyWith(
      {Value<int>? id,
      Value<int>? playlistId,
      Value<String>? sourceId,
      Value<String>? name,
      Value<String?>? coverUrl,
      Value<String?>? categoryName,
      Value<String?>? plot,
      Value<String?>? cast,
      Value<String?>? director,
      Value<String?>? genre,
      Value<double?>? rating,
      Value<String?>? year,
      Value<String?>? backdropUrl,
      Value<bool>? isActive,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return SeriesItemsCompanion(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      sourceId: sourceId ?? this.sourceId,
      name: name ?? this.name,
      coverUrl: coverUrl ?? this.coverUrl,
      categoryName: categoryName ?? this.categoryName,
      plot: plot ?? this.plot,
      cast: cast ?? this.cast,
      director: director ?? this.director,
      genre: genre ?? this.genre,
      rating: rating ?? this.rating,
      year: year ?? this.year,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<int>(playlistId.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (plot.present) {
      map['plot'] = Variable<String>(plot.value);
    }
    if (cast.present) {
      map['cast'] = Variable<String>(cast.value);
    }
    if (director.present) {
      map['director'] = Variable<String>(director.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (year.present) {
      map['year'] = Variable<String>(year.value);
    }
    if (backdropUrl.present) {
      map['backdrop_url'] = Variable<String>(backdropUrl.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeriesItemsCompanion(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('sourceId: $sourceId, ')
          ..write('name: $name, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('categoryName: $categoryName, ')
          ..write('plot: $plot, ')
          ..write('cast: $cast, ')
          ..write('director: $director, ')
          ..write('genre: $genre, ')
          ..write('rating: $rating, ')
          ..write('year: $year, ')
          ..write('backdropUrl: $backdropUrl, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SeasonsTable extends Seasons with TableInfo<$SeasonsTable, Season> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeasonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _seriesIdMeta =
      const VerificationMeta('seriesId');
  @override
  late final GeneratedColumn<int> seriesId = GeneratedColumn<int>(
      'series_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES series_items (id)'));
  static const VerificationMeta _seasonNumberMeta =
      const VerificationMeta('seasonNumber');
  @override
  late final GeneratedColumn<int> seasonNumber = GeneratedColumn<int>(
      'season_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _coverUrlMeta =
      const VerificationMeta('coverUrl');
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
      'cover_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _episodeCountMeta =
      const VerificationMeta('episodeCount');
  @override
  late final GeneratedColumn<int> episodeCount = GeneratedColumn<int>(
      'episode_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _airDateMeta =
      const VerificationMeta('airDate');
  @override
  late final GeneratedColumn<String> airDate = GeneratedColumn<String>(
      'air_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        seriesId,
        seasonNumber,
        name,
        coverUrl,
        episodeCount,
        airDate,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'seasons';
  @override
  VerificationContext validateIntegrity(Insertable<Season> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('series_id')) {
      context.handle(_seriesIdMeta,
          seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta));
    } else if (isInserting) {
      context.missing(_seriesIdMeta);
    }
    if (data.containsKey('season_number')) {
      context.handle(
          _seasonNumberMeta,
          seasonNumber.isAcceptableOrUnknown(
              data['season_number']!, _seasonNumberMeta));
    } else if (isInserting) {
      context.missing(_seasonNumberMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('cover_url')) {
      context.handle(_coverUrlMeta,
          coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta));
    }
    if (data.containsKey('episode_count')) {
      context.handle(
          _episodeCountMeta,
          episodeCount.isAcceptableOrUnknown(
              data['episode_count']!, _episodeCountMeta));
    }
    if (data.containsKey('air_date')) {
      context.handle(_airDateMeta,
          airDate.isAcceptableOrUnknown(data['air_date']!, _airDateMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Season map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Season(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      seriesId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}series_id'])!,
      seasonNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}season_number'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
      coverUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_url']),
      episodeCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}episode_count']),
      airDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}air_date']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SeasonsTable createAlias(String alias) {
    return $SeasonsTable(attachedDatabase, alias);
  }
}

class Season extends DataClass implements Insertable<Season> {
  final int id;
  final int seriesId;
  final int seasonNumber;
  final String? name;
  final String? coverUrl;
  final int? episodeCount;
  final String? airDate;
  final DateTime createdAt;
  const Season(
      {required this.id,
      required this.seriesId,
      required this.seasonNumber,
      this.name,
      this.coverUrl,
      this.episodeCount,
      this.airDate,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['series_id'] = Variable<int>(seriesId);
    map['season_number'] = Variable<int>(seasonNumber);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    if (!nullToAbsent || episodeCount != null) {
      map['episode_count'] = Variable<int>(episodeCount);
    }
    if (!nullToAbsent || airDate != null) {
      map['air_date'] = Variable<String>(airDate);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SeasonsCompanion toCompanion(bool nullToAbsent) {
    return SeasonsCompanion(
      id: Value(id),
      seriesId: Value(seriesId),
      seasonNumber: Value(seasonNumber),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      episodeCount: episodeCount == null && nullToAbsent
          ? const Value.absent()
          : Value(episodeCount),
      airDate: airDate == null && nullToAbsent
          ? const Value.absent()
          : Value(airDate),
      createdAt: Value(createdAt),
    );
  }

  factory Season.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Season(
      id: serializer.fromJson<int>(json['id']),
      seriesId: serializer.fromJson<int>(json['seriesId']),
      seasonNumber: serializer.fromJson<int>(json['seasonNumber']),
      name: serializer.fromJson<String?>(json['name']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      episodeCount: serializer.fromJson<int?>(json['episodeCount']),
      airDate: serializer.fromJson<String?>(json['airDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'seriesId': serializer.toJson<int>(seriesId),
      'seasonNumber': serializer.toJson<int>(seasonNumber),
      'name': serializer.toJson<String?>(name),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'episodeCount': serializer.toJson<int?>(episodeCount),
      'airDate': serializer.toJson<String?>(airDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Season copyWith(
          {int? id,
          int? seriesId,
          int? seasonNumber,
          Value<String?> name = const Value.absent(),
          Value<String?> coverUrl = const Value.absent(),
          Value<int?> episodeCount = const Value.absent(),
          Value<String?> airDate = const Value.absent(),
          DateTime? createdAt}) =>
      Season(
        id: id ?? this.id,
        seriesId: seriesId ?? this.seriesId,
        seasonNumber: seasonNumber ?? this.seasonNumber,
        name: name.present ? name.value : this.name,
        coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
        episodeCount:
            episodeCount.present ? episodeCount.value : this.episodeCount,
        airDate: airDate.present ? airDate.value : this.airDate,
        createdAt: createdAt ?? this.createdAt,
      );
  Season copyWithCompanion(SeasonsCompanion data) {
    return Season(
      id: data.id.present ? data.id.value : this.id,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      seasonNumber: data.seasonNumber.present
          ? data.seasonNumber.value
          : this.seasonNumber,
      name: data.name.present ? data.name.value : this.name,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      episodeCount: data.episodeCount.present
          ? data.episodeCount.value
          : this.episodeCount,
      airDate: data.airDate.present ? data.airDate.value : this.airDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Season(')
          ..write('id: $id, ')
          ..write('seriesId: $seriesId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('name: $name, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('episodeCount: $episodeCount, ')
          ..write('airDate: $airDate, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, seriesId, seasonNumber, name, coverUrl,
      episodeCount, airDate, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Season &&
          other.id == this.id &&
          other.seriesId == this.seriesId &&
          other.seasonNumber == this.seasonNumber &&
          other.name == this.name &&
          other.coverUrl == this.coverUrl &&
          other.episodeCount == this.episodeCount &&
          other.airDate == this.airDate &&
          other.createdAt == this.createdAt);
}

class SeasonsCompanion extends UpdateCompanion<Season> {
  final Value<int> id;
  final Value<int> seriesId;
  final Value<int> seasonNumber;
  final Value<String?> name;
  final Value<String?> coverUrl;
  final Value<int?> episodeCount;
  final Value<String?> airDate;
  final Value<DateTime> createdAt;
  const SeasonsCompanion({
    this.id = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.seasonNumber = const Value.absent(),
    this.name = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.episodeCount = const Value.absent(),
    this.airDate = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SeasonsCompanion.insert({
    this.id = const Value.absent(),
    required int seriesId,
    required int seasonNumber,
    this.name = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.episodeCount = const Value.absent(),
    this.airDate = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : seriesId = Value(seriesId),
        seasonNumber = Value(seasonNumber);
  static Insertable<Season> custom({
    Expression<int>? id,
    Expression<int>? seriesId,
    Expression<int>? seasonNumber,
    Expression<String>? name,
    Expression<String>? coverUrl,
    Expression<int>? episodeCount,
    Expression<String>? airDate,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (seriesId != null) 'series_id': seriesId,
      if (seasonNumber != null) 'season_number': seasonNumber,
      if (name != null) 'name': name,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (episodeCount != null) 'episode_count': episodeCount,
      if (airDate != null) 'air_date': airDate,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SeasonsCompanion copyWith(
      {Value<int>? id,
      Value<int>? seriesId,
      Value<int>? seasonNumber,
      Value<String?>? name,
      Value<String?>? coverUrl,
      Value<int?>? episodeCount,
      Value<String?>? airDate,
      Value<DateTime>? createdAt}) {
    return SeasonsCompanion(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      name: name ?? this.name,
      coverUrl: coverUrl ?? this.coverUrl,
      episodeCount: episodeCount ?? this.episodeCount,
      airDate: airDate ?? this.airDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<int>(seriesId.value);
    }
    if (seasonNumber.present) {
      map['season_number'] = Variable<int>(seasonNumber.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (episodeCount.present) {
      map['episode_count'] = Variable<int>(episodeCount.value);
    }
    if (airDate.present) {
      map['air_date'] = Variable<String>(airDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeasonsCompanion(')
          ..write('id: $id, ')
          ..write('seriesId: $seriesId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('name: $name, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('episodeCount: $episodeCount, ')
          ..write('airDate: $airDate, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $EpisodesTable extends Episodes with TableInfo<$EpisodesTable, Episode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpisodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _seriesIdMeta =
      const VerificationMeta('seriesId');
  @override
  late final GeneratedColumn<int> seriesId = GeneratedColumn<int>(
      'series_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES series_items (id)'));
  static const VerificationMeta _seasonIdMeta =
      const VerificationMeta('seasonId');
  @override
  late final GeneratedColumn<int> seasonId = GeneratedColumn<int>(
      'season_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES seasons (id)'));
  static const VerificationMeta _sourceIdMeta =
      const VerificationMeta('sourceId');
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
      'source_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _episodeNumberMeta =
      const VerificationMeta('episodeNumber');
  @override
  late final GeneratedColumn<int> episodeNumber = GeneratedColumn<int>(
      'episode_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 500),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _streamUrlMeta =
      const VerificationMeta('streamUrl');
  @override
  late final GeneratedColumn<String> streamUrl = GeneratedColumn<String>(
      'stream_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _containerExtensionMeta =
      const VerificationMeta('containerExtension');
  @override
  late final GeneratedColumn<String> containerExtension =
      GeneratedColumn<String>('container_extension', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('mp4'));
  static const VerificationMeta _plotMeta = const VerificationMeta('plot');
  @override
  late final GeneratedColumn<String> plot = GeneratedColumn<String>(
      'plot', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _durationMeta =
      const VerificationMeta('duration');
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
      'duration', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _coverUrlMeta =
      const VerificationMeta('coverUrl');
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
      'cover_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
      'rating', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _releaseDateMeta =
      const VerificationMeta('releaseDate');
  @override
  late final GeneratedColumn<String> releaseDate = GeneratedColumn<String>(
      'release_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        seriesId,
        seasonId,
        sourceId,
        episodeNumber,
        title,
        streamUrl,
        containerExtension,
        plot,
        duration,
        coverUrl,
        rating,
        releaseDate,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'episodes';
  @override
  VerificationContext validateIntegrity(Insertable<Episode> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('series_id')) {
      context.handle(_seriesIdMeta,
          seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta));
    } else if (isInserting) {
      context.missing(_seriesIdMeta);
    }
    if (data.containsKey('season_id')) {
      context.handle(_seasonIdMeta,
          seasonId.isAcceptableOrUnknown(data['season_id']!, _seasonIdMeta));
    } else if (isInserting) {
      context.missing(_seasonIdMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(_sourceIdMeta,
          sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta));
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('episode_number')) {
      context.handle(
          _episodeNumberMeta,
          episodeNumber.isAcceptableOrUnknown(
              data['episode_number']!, _episodeNumberMeta));
    } else if (isInserting) {
      context.missing(_episodeNumberMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('stream_url')) {
      context.handle(_streamUrlMeta,
          streamUrl.isAcceptableOrUnknown(data['stream_url']!, _streamUrlMeta));
    } else if (isInserting) {
      context.missing(_streamUrlMeta);
    }
    if (data.containsKey('container_extension')) {
      context.handle(
          _containerExtensionMeta,
          containerExtension.isAcceptableOrUnknown(
              data['container_extension']!, _containerExtensionMeta));
    }
    if (data.containsKey('plot')) {
      context.handle(
          _plotMeta, plot.isAcceptableOrUnknown(data['plot']!, _plotMeta));
    }
    if (data.containsKey('duration')) {
      context.handle(_durationMeta,
          duration.isAcceptableOrUnknown(data['duration']!, _durationMeta));
    }
    if (data.containsKey('cover_url')) {
      context.handle(_coverUrlMeta,
          coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta));
    }
    if (data.containsKey('rating')) {
      context.handle(_ratingMeta,
          rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta));
    }
    if (data.containsKey('release_date')) {
      context.handle(
          _releaseDateMeta,
          releaseDate.isAcceptableOrUnknown(
              data['release_date']!, _releaseDateMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Episode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Episode(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      seriesId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}series_id'])!,
      seasonId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}season_id'])!,
      sourceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_id'])!,
      episodeNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}episode_number'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      streamUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stream_url'])!,
      containerExtension: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}container_extension'])!,
      plot: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plot']),
      duration: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration']),
      coverUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_url']),
      rating: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}rating']),
      releaseDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}release_date']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $EpisodesTable createAlias(String alias) {
    return $EpisodesTable(attachedDatabase, alias);
  }
}

class Episode extends DataClass implements Insertable<Episode> {
  final int id;
  final int seriesId;
  final int seasonId;
  final String sourceId;
  final int episodeNumber;
  final String title;
  final String streamUrl;
  final String containerExtension;
  final String? plot;
  final int? duration;
  final String? coverUrl;
  final double? rating;
  final String? releaseDate;
  final DateTime createdAt;
  const Episode(
      {required this.id,
      required this.seriesId,
      required this.seasonId,
      required this.sourceId,
      required this.episodeNumber,
      required this.title,
      required this.streamUrl,
      required this.containerExtension,
      this.plot,
      this.duration,
      this.coverUrl,
      this.rating,
      this.releaseDate,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['series_id'] = Variable<int>(seriesId);
    map['season_id'] = Variable<int>(seasonId);
    map['source_id'] = Variable<String>(sourceId);
    map['episode_number'] = Variable<int>(episodeNumber);
    map['title'] = Variable<String>(title);
    map['stream_url'] = Variable<String>(streamUrl);
    map['container_extension'] = Variable<String>(containerExtension);
    if (!nullToAbsent || plot != null) {
      map['plot'] = Variable<String>(plot);
    }
    if (!nullToAbsent || duration != null) {
      map['duration'] = Variable<int>(duration);
    }
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<double>(rating);
    }
    if (!nullToAbsent || releaseDate != null) {
      map['release_date'] = Variable<String>(releaseDate);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EpisodesCompanion toCompanion(bool nullToAbsent) {
    return EpisodesCompanion(
      id: Value(id),
      seriesId: Value(seriesId),
      seasonId: Value(seasonId),
      sourceId: Value(sourceId),
      episodeNumber: Value(episodeNumber),
      title: Value(title),
      streamUrl: Value(streamUrl),
      containerExtension: Value(containerExtension),
      plot: plot == null && nullToAbsent ? const Value.absent() : Value(plot),
      duration: duration == null && nullToAbsent
          ? const Value.absent()
          : Value(duration),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      rating:
          rating == null && nullToAbsent ? const Value.absent() : Value(rating),
      releaseDate: releaseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseDate),
      createdAt: Value(createdAt),
    );
  }

  factory Episode.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Episode(
      id: serializer.fromJson<int>(json['id']),
      seriesId: serializer.fromJson<int>(json['seriesId']),
      seasonId: serializer.fromJson<int>(json['seasonId']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      episodeNumber: serializer.fromJson<int>(json['episodeNumber']),
      title: serializer.fromJson<String>(json['title']),
      streamUrl: serializer.fromJson<String>(json['streamUrl']),
      containerExtension:
          serializer.fromJson<String>(json['containerExtension']),
      plot: serializer.fromJson<String?>(json['plot']),
      duration: serializer.fromJson<int?>(json['duration']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      rating: serializer.fromJson<double?>(json['rating']),
      releaseDate: serializer.fromJson<String?>(json['releaseDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'seriesId': serializer.toJson<int>(seriesId),
      'seasonId': serializer.toJson<int>(seasonId),
      'sourceId': serializer.toJson<String>(sourceId),
      'episodeNumber': serializer.toJson<int>(episodeNumber),
      'title': serializer.toJson<String>(title),
      'streamUrl': serializer.toJson<String>(streamUrl),
      'containerExtension': serializer.toJson<String>(containerExtension),
      'plot': serializer.toJson<String?>(plot),
      'duration': serializer.toJson<int?>(duration),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'rating': serializer.toJson<double?>(rating),
      'releaseDate': serializer.toJson<String?>(releaseDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Episode copyWith(
          {int? id,
          int? seriesId,
          int? seasonId,
          String? sourceId,
          int? episodeNumber,
          String? title,
          String? streamUrl,
          String? containerExtension,
          Value<String?> plot = const Value.absent(),
          Value<int?> duration = const Value.absent(),
          Value<String?> coverUrl = const Value.absent(),
          Value<double?> rating = const Value.absent(),
          Value<String?> releaseDate = const Value.absent(),
          DateTime? createdAt}) =>
      Episode(
        id: id ?? this.id,
        seriesId: seriesId ?? this.seriesId,
        seasonId: seasonId ?? this.seasonId,
        sourceId: sourceId ?? this.sourceId,
        episodeNumber: episodeNumber ?? this.episodeNumber,
        title: title ?? this.title,
        streamUrl: streamUrl ?? this.streamUrl,
        containerExtension: containerExtension ?? this.containerExtension,
        plot: plot.present ? plot.value : this.plot,
        duration: duration.present ? duration.value : this.duration,
        coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
        rating: rating.present ? rating.value : this.rating,
        releaseDate: releaseDate.present ? releaseDate.value : this.releaseDate,
        createdAt: createdAt ?? this.createdAt,
      );
  Episode copyWithCompanion(EpisodesCompanion data) {
    return Episode(
      id: data.id.present ? data.id.value : this.id,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      seasonId: data.seasonId.present ? data.seasonId.value : this.seasonId,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      episodeNumber: data.episodeNumber.present
          ? data.episodeNumber.value
          : this.episodeNumber,
      title: data.title.present ? data.title.value : this.title,
      streamUrl: data.streamUrl.present ? data.streamUrl.value : this.streamUrl,
      containerExtension: data.containerExtension.present
          ? data.containerExtension.value
          : this.containerExtension,
      plot: data.plot.present ? data.plot.value : this.plot,
      duration: data.duration.present ? data.duration.value : this.duration,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      rating: data.rating.present ? data.rating.value : this.rating,
      releaseDate:
          data.releaseDate.present ? data.releaseDate.value : this.releaseDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Episode(')
          ..write('id: $id, ')
          ..write('seriesId: $seriesId, ')
          ..write('seasonId: $seasonId, ')
          ..write('sourceId: $sourceId, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('title: $title, ')
          ..write('streamUrl: $streamUrl, ')
          ..write('containerExtension: $containerExtension, ')
          ..write('plot: $plot, ')
          ..write('duration: $duration, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('rating: $rating, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      seriesId,
      seasonId,
      sourceId,
      episodeNumber,
      title,
      streamUrl,
      containerExtension,
      plot,
      duration,
      coverUrl,
      rating,
      releaseDate,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Episode &&
          other.id == this.id &&
          other.seriesId == this.seriesId &&
          other.seasonId == this.seasonId &&
          other.sourceId == this.sourceId &&
          other.episodeNumber == this.episodeNumber &&
          other.title == this.title &&
          other.streamUrl == this.streamUrl &&
          other.containerExtension == this.containerExtension &&
          other.plot == this.plot &&
          other.duration == this.duration &&
          other.coverUrl == this.coverUrl &&
          other.rating == this.rating &&
          other.releaseDate == this.releaseDate &&
          other.createdAt == this.createdAt);
}

class EpisodesCompanion extends UpdateCompanion<Episode> {
  final Value<int> id;
  final Value<int> seriesId;
  final Value<int> seasonId;
  final Value<String> sourceId;
  final Value<int> episodeNumber;
  final Value<String> title;
  final Value<String> streamUrl;
  final Value<String> containerExtension;
  final Value<String?> plot;
  final Value<int?> duration;
  final Value<String?> coverUrl;
  final Value<double?> rating;
  final Value<String?> releaseDate;
  final Value<DateTime> createdAt;
  const EpisodesCompanion({
    this.id = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.seasonId = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.episodeNumber = const Value.absent(),
    this.title = const Value.absent(),
    this.streamUrl = const Value.absent(),
    this.containerExtension = const Value.absent(),
    this.plot = const Value.absent(),
    this.duration = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.rating = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  EpisodesCompanion.insert({
    this.id = const Value.absent(),
    required int seriesId,
    required int seasonId,
    required String sourceId,
    required int episodeNumber,
    required String title,
    required String streamUrl,
    this.containerExtension = const Value.absent(),
    this.plot = const Value.absent(),
    this.duration = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.rating = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : seriesId = Value(seriesId),
        seasonId = Value(seasonId),
        sourceId = Value(sourceId),
        episodeNumber = Value(episodeNumber),
        title = Value(title),
        streamUrl = Value(streamUrl);
  static Insertable<Episode> custom({
    Expression<int>? id,
    Expression<int>? seriesId,
    Expression<int>? seasonId,
    Expression<String>? sourceId,
    Expression<int>? episodeNumber,
    Expression<String>? title,
    Expression<String>? streamUrl,
    Expression<String>? containerExtension,
    Expression<String>? plot,
    Expression<int>? duration,
    Expression<String>? coverUrl,
    Expression<double>? rating,
    Expression<String>? releaseDate,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (seriesId != null) 'series_id': seriesId,
      if (seasonId != null) 'season_id': seasonId,
      if (sourceId != null) 'source_id': sourceId,
      if (episodeNumber != null) 'episode_number': episodeNumber,
      if (title != null) 'title': title,
      if (streamUrl != null) 'stream_url': streamUrl,
      if (containerExtension != null) 'container_extension': containerExtension,
      if (plot != null) 'plot': plot,
      if (duration != null) 'duration': duration,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (rating != null) 'rating': rating,
      if (releaseDate != null) 'release_date': releaseDate,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  EpisodesCompanion copyWith(
      {Value<int>? id,
      Value<int>? seriesId,
      Value<int>? seasonId,
      Value<String>? sourceId,
      Value<int>? episodeNumber,
      Value<String>? title,
      Value<String>? streamUrl,
      Value<String>? containerExtension,
      Value<String?>? plot,
      Value<int?>? duration,
      Value<String?>? coverUrl,
      Value<double?>? rating,
      Value<String?>? releaseDate,
      Value<DateTime>? createdAt}) {
    return EpisodesCompanion(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      seasonId: seasonId ?? this.seasonId,
      sourceId: sourceId ?? this.sourceId,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      title: title ?? this.title,
      streamUrl: streamUrl ?? this.streamUrl,
      containerExtension: containerExtension ?? this.containerExtension,
      plot: plot ?? this.plot,
      duration: duration ?? this.duration,
      coverUrl: coverUrl ?? this.coverUrl,
      rating: rating ?? this.rating,
      releaseDate: releaseDate ?? this.releaseDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<int>(seriesId.value);
    }
    if (seasonId.present) {
      map['season_id'] = Variable<int>(seasonId.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (episodeNumber.present) {
      map['episode_number'] = Variable<int>(episodeNumber.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (streamUrl.present) {
      map['stream_url'] = Variable<String>(streamUrl.value);
    }
    if (containerExtension.present) {
      map['container_extension'] = Variable<String>(containerExtension.value);
    }
    if (plot.present) {
      map['plot'] = Variable<String>(plot.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (releaseDate.present) {
      map['release_date'] = Variable<String>(releaseDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpisodesCompanion(')
          ..write('id: $id, ')
          ..write('seriesId: $seriesId, ')
          ..write('seasonId: $seasonId, ')
          ..write('sourceId: $sourceId, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('title: $title, ')
          ..write('streamUrl: $streamUrl, ')
          ..write('containerExtension: $containerExtension, ')
          ..write('plot: $plot, ')
          ..write('duration: $duration, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('rating: $rating, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PlaylistsTable playlists = $PlaylistsTable(this);
  late final $ChannelsTable channels = $ChannelsTable(this);
  late final $FavoritesTable favorites = $FavoritesTable(this);
  late final $WatchHistoryEntriesTable watchHistoryEntries =
      $WatchHistoryEntriesTable(this);
  late final $EpgProgramsTable epgPrograms = $EpgProgramsTable(this);
  late final $VodItemsTable vodItems = $VodItemsTable(this);
  late final $SeriesItemsTable seriesItems = $SeriesItemsTable(this);
  late final $SeasonsTable seasons = $SeasonsTable(this);
  late final $EpisodesTable episodes = $EpisodesTable(this);
  late final PlaylistsDao playlistsDao = PlaylistsDao(this as AppDatabase);
  late final ChannelsDao channelsDao = ChannelsDao(this as AppDatabase);
  late final FavoritesDao favoritesDao = FavoritesDao(this as AppDatabase);
  late final WatchHistoryDao watchHistoryDao =
      WatchHistoryDao(this as AppDatabase);
  late final EpgDao epgDao = EpgDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        playlists,
        channels,
        favorites,
        watchHistoryEntries,
        epgPrograms,
        vodItems,
        seriesItems,
        seasons,
        episodes
      ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$PlaylistsTableCreateCompanionBuilder = PlaylistsCompanion Function({
  Value<int> id,
  required String name,
  required PlaylistType type,
  Value<String> url,
  Value<String?> epgUrl,
  Value<String?> username,
  Value<String?> credentialKey,
  Value<int?> xtreamPortOverride,
  Value<DateTime?> lastSyncAt,
  Value<PlaylistSyncStatus> syncStatus,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> isActive,
  Value<bool> allowInsecureTls,
});
typedef $$PlaylistsTableUpdateCompanionBuilder = PlaylistsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<PlaylistType> type,
  Value<String> url,
  Value<String?> epgUrl,
  Value<String?> username,
  Value<String?> credentialKey,
  Value<int?> xtreamPortOverride,
  Value<DateTime?> lastSyncAt,
  Value<PlaylistSyncStatus> syncStatus,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> isActive,
  Value<bool> allowInsecureTls,
});

final class $$PlaylistsTableReferences
    extends BaseReferences<_$AppDatabase, $PlaylistsTable, Playlist> {
  $$PlaylistsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ChannelsTable, List<Channel>> _channelsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.channels,
          aliasName: 'playlists__id__channels__playlist_id');

  $$ChannelsTableProcessedTableManager get channelsRefs {
    final manager = $$ChannelsTableTableManager($_db, $_db.channels)
        .filter((f) => f.playlistId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_channelsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$VodItemsTable, List<VodItem>> _vodItemsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.vodItems,
          aliasName: 'playlists__id__vod_items__playlist_id');

  $$VodItemsTableProcessedTableManager get vodItemsRefs {
    final manager = $$VodItemsTableTableManager($_db, $_db.vodItems)
        .filter((f) => f.playlistId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_vodItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$SeriesItemsTable, List<SeriesItem>>
      _seriesItemsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.seriesItems,
              aliasName: 'playlists__id__series_items__playlist_id');

  $$SeriesItemsTableProcessedTableManager get seriesItemsRefs {
    final manager = $$SeriesItemsTableTableManager($_db, $_db.seriesItems)
        .filter((f) => f.playlistId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_seriesItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PlaylistsTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<PlaylistType, PlaylistType, String> get type =>
      $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get epgUrl => $composableBuilder(
      column: $table.epgUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get credentialKey => $composableBuilder(
      column: $table.credentialKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get xtreamPortOverride => $composableBuilder(
      column: $table.xtreamPortOverride,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<PlaylistSyncStatus, PlaylistSyncStatus, String>
      get syncStatus => $composableBuilder(
          column: $table.syncStatus,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get allowInsecureTls => $composableBuilder(
      column: $table.allowInsecureTls,
      builder: (column) => ColumnFilters(column));

  Expression<bool> channelsRefs(
      Expression<bool> Function($$ChannelsTableFilterComposer f) f) {
    final $$ChannelsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.channels,
        getReferencedColumn: (t) => t.playlistId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChannelsTableFilterComposer(
              $db: $db,
              $table: $db.channels,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> vodItemsRefs(
      Expression<bool> Function($$VodItemsTableFilterComposer f) f) {
    final $$VodItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.vodItems,
        getReferencedColumn: (t) => t.playlistId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VodItemsTableFilterComposer(
              $db: $db,
              $table: $db.vodItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> seriesItemsRefs(
      Expression<bool> Function($$SeriesItemsTableFilterComposer f) f) {
    final $$SeriesItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.seriesItems,
        getReferencedColumn: (t) => t.playlistId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SeriesItemsTableFilterComposer(
              $db: $db,
              $table: $db.seriesItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PlaylistsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get epgUrl => $composableBuilder(
      column: $table.epgUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get credentialKey => $composableBuilder(
      column: $table.credentialKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get xtreamPortOverride => $composableBuilder(
      column: $table.xtreamPortOverride,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get allowInsecureTls => $composableBuilder(
      column: $table.allowInsecureTls,
      builder: (column) => ColumnOrderings(column));
}

class $$PlaylistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PlaylistType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get epgUrl =>
      $composableBuilder(column: $table.epgUrl, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get credentialKey => $composableBuilder(
      column: $table.credentialKey, builder: (column) => column);

  GeneratedColumn<int> get xtreamPortOverride => $composableBuilder(
      column: $table.xtreamPortOverride, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PlaylistSyncStatus, String> get syncStatus =>
      $composableBuilder(
          column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<bool> get allowInsecureTls => $composableBuilder(
      column: $table.allowInsecureTls, builder: (column) => column);

  Expression<T> channelsRefs<T extends Object>(
      Expression<T> Function($$ChannelsTableAnnotationComposer a) f) {
    final $$ChannelsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.channels,
        getReferencedColumn: (t) => t.playlistId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChannelsTableAnnotationComposer(
              $db: $db,
              $table: $db.channels,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> vodItemsRefs<T extends Object>(
      Expression<T> Function($$VodItemsTableAnnotationComposer a) f) {
    final $$VodItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.vodItems,
        getReferencedColumn: (t) => t.playlistId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VodItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.vodItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> seriesItemsRefs<T extends Object>(
      Expression<T> Function($$SeriesItemsTableAnnotationComposer a) f) {
    final $$SeriesItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.seriesItems,
        getReferencedColumn: (t) => t.playlistId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SeriesItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.seriesItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PlaylistsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlaylistsTable,
    Playlist,
    $$PlaylistsTableFilterComposer,
    $$PlaylistsTableOrderingComposer,
    $$PlaylistsTableAnnotationComposer,
    $$PlaylistsTableCreateCompanionBuilder,
    $$PlaylistsTableUpdateCompanionBuilder,
    (Playlist, $$PlaylistsTableReferences),
    Playlist,
    PrefetchHooks Function(
        {bool channelsRefs, bool vodItemsRefs, bool seriesItemsRefs})> {
  $$PlaylistsTableTableManager(_$AppDatabase db, $PlaylistsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<PlaylistType> type = const Value.absent(),
            Value<String> url = const Value.absent(),
            Value<String?> epgUrl = const Value.absent(),
            Value<String?> username = const Value.absent(),
            Value<String?> credentialKey = const Value.absent(),
            Value<int?> xtreamPortOverride = const Value.absent(),
            Value<DateTime?> lastSyncAt = const Value.absent(),
            Value<PlaylistSyncStatus> syncStatus = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<bool> allowInsecureTls = const Value.absent(),
          }) =>
              PlaylistsCompanion(
            id: id,
            name: name,
            type: type,
            url: url,
            epgUrl: epgUrl,
            username: username,
            credentialKey: credentialKey,
            xtreamPortOverride: xtreamPortOverride,
            lastSyncAt: lastSyncAt,
            syncStatus: syncStatus,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isActive: isActive,
            allowInsecureTls: allowInsecureTls,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required PlaylistType type,
            Value<String> url = const Value.absent(),
            Value<String?> epgUrl = const Value.absent(),
            Value<String?> username = const Value.absent(),
            Value<String?> credentialKey = const Value.absent(),
            Value<int?> xtreamPortOverride = const Value.absent(),
            Value<DateTime?> lastSyncAt = const Value.absent(),
            Value<PlaylistSyncStatus> syncStatus = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<bool> allowInsecureTls = const Value.absent(),
          }) =>
              PlaylistsCompanion.insert(
            id: id,
            name: name,
            type: type,
            url: url,
            epgUrl: epgUrl,
            username: username,
            credentialKey: credentialKey,
            xtreamPortOverride: xtreamPortOverride,
            lastSyncAt: lastSyncAt,
            syncStatus: syncStatus,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isActive: isActive,
            allowInsecureTls: allowInsecureTls,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PlaylistsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {channelsRefs = false,
              vodItemsRefs = false,
              seriesItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (channelsRefs) db.channels,
                if (vodItemsRefs) db.vodItems,
                if (seriesItemsRefs) db.seriesItems
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (channelsRefs)
                    await $_getPrefetchedData<Playlist, $PlaylistsTable,
                            Channel>(
                        currentTable: table,
                        referencedTable:
                            $$PlaylistsTableReferences._channelsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PlaylistsTableReferences(db, table, p0)
                                .channelsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.playlistId == item.id),
                        typedResults: items),
                  if (vodItemsRefs)
                    await $_getPrefetchedData<Playlist, $PlaylistsTable,
                            VodItem>(
                        currentTable: table,
                        referencedTable:
                            $$PlaylistsTableReferences._vodItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PlaylistsTableReferences(db, table, p0)
                                .vodItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.playlistId == item.id),
                        typedResults: items),
                  if (seriesItemsRefs)
                    await $_getPrefetchedData<Playlist, $PlaylistsTable,
                            SeriesItem>(
                        currentTable: table,
                        referencedTable: $$PlaylistsTableReferences
                            ._seriesItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PlaylistsTableReferences(db, table, p0)
                                .seriesItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.playlistId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$PlaylistsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PlaylistsTable,
    Playlist,
    $$PlaylistsTableFilterComposer,
    $$PlaylistsTableOrderingComposer,
    $$PlaylistsTableAnnotationComposer,
    $$PlaylistsTableCreateCompanionBuilder,
    $$PlaylistsTableUpdateCompanionBuilder,
    (Playlist, $$PlaylistsTableReferences),
    Playlist,
    PrefetchHooks Function(
        {bool channelsRefs, bool vodItemsRefs, bool seriesItemsRefs})>;
typedef $$ChannelsTableCreateCompanionBuilder = ChannelsCompanion Function({
  Value<int> id,
  required int playlistId,
  Value<String?> sourceId,
  required String name,
  required String streamUrl,
  Value<String?> logoUrl,
  Value<String?> groupName,
  Value<String?> tvgId,
  Value<String?> tvgName,
  Value<bool> isActive,
  required ChannelSourceType sourceType,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$ChannelsTableUpdateCompanionBuilder = ChannelsCompanion Function({
  Value<int> id,
  Value<int> playlistId,
  Value<String?> sourceId,
  Value<String> name,
  Value<String> streamUrl,
  Value<String?> logoUrl,
  Value<String?> groupName,
  Value<String?> tvgId,
  Value<String?> tvgName,
  Value<bool> isActive,
  Value<ChannelSourceType> sourceType,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$ChannelsTableReferences
    extends BaseReferences<_$AppDatabase, $ChannelsTable, Channel> {
  $$ChannelsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PlaylistsTable _playlistIdTable(_$AppDatabase db) =>
      db.playlists.createAlias('channels__playlist_id__playlists__id');

  $$PlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<int>('playlist_id')!;

    final manager = $$PlaylistsTableTableManager($_db, $_db.playlists)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$FavoritesTable, List<Favorite>>
      _favoritesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.favorites,
              aliasName: 'channels__id__favorites__channel_id');

  $$FavoritesTableProcessedTableManager get favoritesRefs {
    final manager = $$FavoritesTableTableManager($_db, $_db.favorites)
        .filter((f) => f.channelId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_favoritesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$WatchHistoryEntriesTable, List<WatchHistoryEntry>>
      _watchHistoryEntriesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.watchHistoryEntries,
              aliasName: 'channels__id__watch_history_entries__channel_id');

  $$WatchHistoryEntriesTableProcessedTableManager get watchHistoryEntriesRefs {
    final manager =
        $$WatchHistoryEntriesTableTableManager($_db, $_db.watchHistoryEntries)
            .filter((f) => f.channelId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_watchHistoryEntriesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$EpgProgramsTable, List<EpgProgram>>
      _epgProgramsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.epgPrograms,
              aliasName: 'channels__id__epg_programs__channel_id');

  $$EpgProgramsTableProcessedTableManager get epgProgramsRefs {
    final manager = $$EpgProgramsTableTableManager($_db, $_db.epgPrograms)
        .filter((f) => f.channelId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_epgProgramsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ChannelsTableFilterComposer
    extends Composer<_$AppDatabase, $ChannelsTable> {
  $$ChannelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceId => $composableBuilder(
      column: $table.sourceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get streamUrl => $composableBuilder(
      column: $table.streamUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get logoUrl => $composableBuilder(
      column: $table.logoUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupName => $composableBuilder(
      column: $table.groupName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tvgId => $composableBuilder(
      column: $table.tvgId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tvgName => $composableBuilder(
      column: $table.tvgName, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<ChannelSourceType, ChannelSourceType, String>
      get sourceType => $composableBuilder(
          column: $table.sourceType,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$PlaylistsTableFilterComposer get playlistId {
    final $$PlaylistsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.playlistId,
        referencedTable: $db.playlists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlaylistsTableFilterComposer(
              $db: $db,
              $table: $db.playlists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> favoritesRefs(
      Expression<bool> Function($$FavoritesTableFilterComposer f) f) {
    final $$FavoritesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.favorites,
        getReferencedColumn: (t) => t.channelId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FavoritesTableFilterComposer(
              $db: $db,
              $table: $db.favorites,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> watchHistoryEntriesRefs(
      Expression<bool> Function($$WatchHistoryEntriesTableFilterComposer f) f) {
    final $$WatchHistoryEntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.watchHistoryEntries,
        getReferencedColumn: (t) => t.channelId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WatchHistoryEntriesTableFilterComposer(
              $db: $db,
              $table: $db.watchHistoryEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> epgProgramsRefs(
      Expression<bool> Function($$EpgProgramsTableFilterComposer f) f) {
    final $$EpgProgramsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.epgPrograms,
        getReferencedColumn: (t) => t.channelId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EpgProgramsTableFilterComposer(
              $db: $db,
              $table: $db.epgPrograms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ChannelsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChannelsTable> {
  $$ChannelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceId => $composableBuilder(
      column: $table.sourceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get streamUrl => $composableBuilder(
      column: $table.streamUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get logoUrl => $composableBuilder(
      column: $table.logoUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupName => $composableBuilder(
      column: $table.groupName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tvgId => $composableBuilder(
      column: $table.tvgId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tvgName => $composableBuilder(
      column: $table.tvgName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceType => $composableBuilder(
      column: $table.sourceType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$PlaylistsTableOrderingComposer get playlistId {
    final $$PlaylistsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.playlistId,
        referencedTable: $db.playlists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlaylistsTableOrderingComposer(
              $db: $db,
              $table: $db.playlists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ChannelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChannelsTable> {
  $$ChannelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get streamUrl =>
      $composableBuilder(column: $table.streamUrl, builder: (column) => column);

  GeneratedColumn<String> get logoUrl =>
      $composableBuilder(column: $table.logoUrl, builder: (column) => column);

  GeneratedColumn<String> get groupName =>
      $composableBuilder(column: $table.groupName, builder: (column) => column);

  GeneratedColumn<String> get tvgId =>
      $composableBuilder(column: $table.tvgId, builder: (column) => column);

  GeneratedColumn<String> get tvgName =>
      $composableBuilder(column: $table.tvgName, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ChannelSourceType, String> get sourceType =>
      $composableBuilder(
          column: $table.sourceType, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$PlaylistsTableAnnotationComposer get playlistId {
    final $$PlaylistsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.playlistId,
        referencedTable: $db.playlists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlaylistsTableAnnotationComposer(
              $db: $db,
              $table: $db.playlists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> favoritesRefs<T extends Object>(
      Expression<T> Function($$FavoritesTableAnnotationComposer a) f) {
    final $$FavoritesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.favorites,
        getReferencedColumn: (t) => t.channelId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FavoritesTableAnnotationComposer(
              $db: $db,
              $table: $db.favorites,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> watchHistoryEntriesRefs<T extends Object>(
      Expression<T> Function($$WatchHistoryEntriesTableAnnotationComposer a)
          f) {
    final $$WatchHistoryEntriesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.watchHistoryEntries,
            getReferencedColumn: (t) => t.channelId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$WatchHistoryEntriesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.watchHistoryEntries,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> epgProgramsRefs<T extends Object>(
      Expression<T> Function($$EpgProgramsTableAnnotationComposer a) f) {
    final $$EpgProgramsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.epgPrograms,
        getReferencedColumn: (t) => t.channelId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EpgProgramsTableAnnotationComposer(
              $db: $db,
              $table: $db.epgPrograms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ChannelsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChannelsTable,
    Channel,
    $$ChannelsTableFilterComposer,
    $$ChannelsTableOrderingComposer,
    $$ChannelsTableAnnotationComposer,
    $$ChannelsTableCreateCompanionBuilder,
    $$ChannelsTableUpdateCompanionBuilder,
    (Channel, $$ChannelsTableReferences),
    Channel,
    PrefetchHooks Function(
        {bool playlistId,
        bool favoritesRefs,
        bool watchHistoryEntriesRefs,
        bool epgProgramsRefs})> {
  $$ChannelsTableTableManager(_$AppDatabase db, $ChannelsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChannelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChannelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChannelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> playlistId = const Value.absent(),
            Value<String?> sourceId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> streamUrl = const Value.absent(),
            Value<String?> logoUrl = const Value.absent(),
            Value<String?> groupName = const Value.absent(),
            Value<String?> tvgId = const Value.absent(),
            Value<String?> tvgName = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<ChannelSourceType> sourceType = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              ChannelsCompanion(
            id: id,
            playlistId: playlistId,
            sourceId: sourceId,
            name: name,
            streamUrl: streamUrl,
            logoUrl: logoUrl,
            groupName: groupName,
            tvgId: tvgId,
            tvgName: tvgName,
            isActive: isActive,
            sourceType: sourceType,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int playlistId,
            Value<String?> sourceId = const Value.absent(),
            required String name,
            required String streamUrl,
            Value<String?> logoUrl = const Value.absent(),
            Value<String?> groupName = const Value.absent(),
            Value<String?> tvgId = const Value.absent(),
            Value<String?> tvgName = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            required ChannelSourceType sourceType,
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              ChannelsCompanion.insert(
            id: id,
            playlistId: playlistId,
            sourceId: sourceId,
            name: name,
            streamUrl: streamUrl,
            logoUrl: logoUrl,
            groupName: groupName,
            tvgId: tvgId,
            tvgName: tvgName,
            isActive: isActive,
            sourceType: sourceType,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ChannelsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {playlistId = false,
              favoritesRefs = false,
              watchHistoryEntriesRefs = false,
              epgProgramsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (favoritesRefs) db.favorites,
                if (watchHistoryEntriesRefs) db.watchHistoryEntries,
                if (epgProgramsRefs) db.epgPrograms
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (playlistId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.playlistId,
                    referencedTable:
                        $$ChannelsTableReferences._playlistIdTable(db),
                    referencedColumn:
                        $$ChannelsTableReferences._playlistIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (favoritesRefs)
                    await $_getPrefetchedData<Channel, $ChannelsTable,
                            Favorite>(
                        currentTable: table,
                        referencedTable:
                            $$ChannelsTableReferences._favoritesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ChannelsTableReferences(db, table, p0)
                                .favoritesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.channelId == item.id),
                        typedResults: items),
                  if (watchHistoryEntriesRefs)
                    await $_getPrefetchedData<Channel, $ChannelsTable,
                            WatchHistoryEntry>(
                        currentTable: table,
                        referencedTable: $$ChannelsTableReferences
                            ._watchHistoryEntriesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ChannelsTableReferences(db, table, p0)
                                .watchHistoryEntriesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.channelId == item.id),
                        typedResults: items),
                  if (epgProgramsRefs)
                    await $_getPrefetchedData<Channel, $ChannelsTable,
                            EpgProgram>(
                        currentTable: table,
                        referencedTable:
                            $$ChannelsTableReferences._epgProgramsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ChannelsTableReferences(db, table, p0)
                                .epgProgramsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.channelId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ChannelsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ChannelsTable,
    Channel,
    $$ChannelsTableFilterComposer,
    $$ChannelsTableOrderingComposer,
    $$ChannelsTableAnnotationComposer,
    $$ChannelsTableCreateCompanionBuilder,
    $$ChannelsTableUpdateCompanionBuilder,
    (Channel, $$ChannelsTableReferences),
    Channel,
    PrefetchHooks Function(
        {bool playlistId,
        bool favoritesRefs,
        bool watchHistoryEntriesRefs,
        bool epgProgramsRefs})>;
typedef $$FavoritesTableCreateCompanionBuilder = FavoritesCompanion Function({
  Value<int> id,
  required int channelId,
  Value<DateTime> createdAt,
});
typedef $$FavoritesTableUpdateCompanionBuilder = FavoritesCompanion Function({
  Value<int> id,
  Value<int> channelId,
  Value<DateTime> createdAt,
});

final class $$FavoritesTableReferences
    extends BaseReferences<_$AppDatabase, $FavoritesTable, Favorite> {
  $$FavoritesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChannelsTable _channelIdTable(_$AppDatabase db) =>
      db.channels.createAlias('favorites__channel_id__channels__id');

  $$ChannelsTableProcessedTableManager get channelId {
    final $_column = $_itemColumn<int>('channel_id')!;

    final manager = $$ChannelsTableTableManager($_db, $_db.channels)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_channelIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$FavoritesTableFilterComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$ChannelsTableFilterComposer get channelId {
    final $$ChannelsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.channelId,
        referencedTable: $db.channels,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChannelsTableFilterComposer(
              $db: $db,
              $table: $db.channels,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FavoritesTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$ChannelsTableOrderingComposer get channelId {
    final $$ChannelsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.channelId,
        referencedTable: $db.channels,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChannelsTableOrderingComposer(
              $db: $db,
              $table: $db.channels,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FavoritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ChannelsTableAnnotationComposer get channelId {
    final $$ChannelsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.channelId,
        referencedTable: $db.channels,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChannelsTableAnnotationComposer(
              $db: $db,
              $table: $db.channels,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FavoritesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FavoritesTable,
    Favorite,
    $$FavoritesTableFilterComposer,
    $$FavoritesTableOrderingComposer,
    $$FavoritesTableAnnotationComposer,
    $$FavoritesTableCreateCompanionBuilder,
    $$FavoritesTableUpdateCompanionBuilder,
    (Favorite, $$FavoritesTableReferences),
    Favorite,
    PrefetchHooks Function({bool channelId})> {
  $$FavoritesTableTableManager(_$AppDatabase db, $FavoritesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> channelId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              FavoritesCompanion(
            id: id,
            channelId: channelId,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int channelId,
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              FavoritesCompanion.insert(
            id: id,
            channelId: channelId,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$FavoritesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({channelId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (channelId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.channelId,
                    referencedTable:
                        $$FavoritesTableReferences._channelIdTable(db),
                    referencedColumn:
                        $$FavoritesTableReferences._channelIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$FavoritesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FavoritesTable,
    Favorite,
    $$FavoritesTableFilterComposer,
    $$FavoritesTableOrderingComposer,
    $$FavoritesTableAnnotationComposer,
    $$FavoritesTableCreateCompanionBuilder,
    $$FavoritesTableUpdateCompanionBuilder,
    (Favorite, $$FavoritesTableReferences),
    Favorite,
    PrefetchHooks Function({bool channelId})>;
typedef $$WatchHistoryEntriesTableCreateCompanionBuilder
    = WatchHistoryEntriesCompanion Function({
  Value<int> id,
  required int channelId,
  Value<DateTime> startedAt,
  Value<DateTime> lastWatchedAt,
  Value<int> watchedDurationMs,
});
typedef $$WatchHistoryEntriesTableUpdateCompanionBuilder
    = WatchHistoryEntriesCompanion Function({
  Value<int> id,
  Value<int> channelId,
  Value<DateTime> startedAt,
  Value<DateTime> lastWatchedAt,
  Value<int> watchedDurationMs,
});

final class $$WatchHistoryEntriesTableReferences extends BaseReferences<
    _$AppDatabase, $WatchHistoryEntriesTable, WatchHistoryEntry> {
  $$WatchHistoryEntriesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ChannelsTable _channelIdTable(_$AppDatabase db) => db.channels
      .createAlias('watch_history_entries__channel_id__channels__id');

  $$ChannelsTableProcessedTableManager get channelId {
    final $_column = $_itemColumn<int>('channel_id')!;

    final manager = $$ChannelsTableTableManager($_db, $_db.channels)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_channelIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$WatchHistoryEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $WatchHistoryEntriesTable> {
  $$WatchHistoryEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastWatchedAt => $composableBuilder(
      column: $table.lastWatchedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get watchedDurationMs => $composableBuilder(
      column: $table.watchedDurationMs,
      builder: (column) => ColumnFilters(column));

  $$ChannelsTableFilterComposer get channelId {
    final $$ChannelsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.channelId,
        referencedTable: $db.channels,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChannelsTableFilterComposer(
              $db: $db,
              $table: $db.channels,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WatchHistoryEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $WatchHistoryEntriesTable> {
  $$WatchHistoryEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastWatchedAt => $composableBuilder(
      column: $table.lastWatchedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get watchedDurationMs => $composableBuilder(
      column: $table.watchedDurationMs,
      builder: (column) => ColumnOrderings(column));

  $$ChannelsTableOrderingComposer get channelId {
    final $$ChannelsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.channelId,
        referencedTable: $db.channels,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChannelsTableOrderingComposer(
              $db: $db,
              $table: $db.channels,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WatchHistoryEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WatchHistoryEntriesTable> {
  $$WatchHistoryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastWatchedAt => $composableBuilder(
      column: $table.lastWatchedAt, builder: (column) => column);

  GeneratedColumn<int> get watchedDurationMs => $composableBuilder(
      column: $table.watchedDurationMs, builder: (column) => column);

  $$ChannelsTableAnnotationComposer get channelId {
    final $$ChannelsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.channelId,
        referencedTable: $db.channels,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChannelsTableAnnotationComposer(
              $db: $db,
              $table: $db.channels,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WatchHistoryEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WatchHistoryEntriesTable,
    WatchHistoryEntry,
    $$WatchHistoryEntriesTableFilterComposer,
    $$WatchHistoryEntriesTableOrderingComposer,
    $$WatchHistoryEntriesTableAnnotationComposer,
    $$WatchHistoryEntriesTableCreateCompanionBuilder,
    $$WatchHistoryEntriesTableUpdateCompanionBuilder,
    (WatchHistoryEntry, $$WatchHistoryEntriesTableReferences),
    WatchHistoryEntry,
    PrefetchHooks Function({bool channelId})> {
  $$WatchHistoryEntriesTableTableManager(
      _$AppDatabase db, $WatchHistoryEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WatchHistoryEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WatchHistoryEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WatchHistoryEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> channelId = const Value.absent(),
            Value<DateTime> startedAt = const Value.absent(),
            Value<DateTime> lastWatchedAt = const Value.absent(),
            Value<int> watchedDurationMs = const Value.absent(),
          }) =>
              WatchHistoryEntriesCompanion(
            id: id,
            channelId: channelId,
            startedAt: startedAt,
            lastWatchedAt: lastWatchedAt,
            watchedDurationMs: watchedDurationMs,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int channelId,
            Value<DateTime> startedAt = const Value.absent(),
            Value<DateTime> lastWatchedAt = const Value.absent(),
            Value<int> watchedDurationMs = const Value.absent(),
          }) =>
              WatchHistoryEntriesCompanion.insert(
            id: id,
            channelId: channelId,
            startedAt: startedAt,
            lastWatchedAt: lastWatchedAt,
            watchedDurationMs: watchedDurationMs,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$WatchHistoryEntriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({channelId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (channelId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.channelId,
                    referencedTable: $$WatchHistoryEntriesTableReferences
                        ._channelIdTable(db),
                    referencedColumn: $$WatchHistoryEntriesTableReferences
                        ._channelIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$WatchHistoryEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WatchHistoryEntriesTable,
    WatchHistoryEntry,
    $$WatchHistoryEntriesTableFilterComposer,
    $$WatchHistoryEntriesTableOrderingComposer,
    $$WatchHistoryEntriesTableAnnotationComposer,
    $$WatchHistoryEntriesTableCreateCompanionBuilder,
    $$WatchHistoryEntriesTableUpdateCompanionBuilder,
    (WatchHistoryEntry, $$WatchHistoryEntriesTableReferences),
    WatchHistoryEntry,
    PrefetchHooks Function({bool channelId})>;
typedef $$EpgProgramsTableCreateCompanionBuilder = EpgProgramsCompanion
    Function({
  Value<int> id,
  required int channelId,
  required String title,
  Value<String?> description,
  required DateTime startTimeUtc,
  required DateTime endTimeUtc,
  Value<String?> category,
  Value<String?> imageUrl,
});
typedef $$EpgProgramsTableUpdateCompanionBuilder = EpgProgramsCompanion
    Function({
  Value<int> id,
  Value<int> channelId,
  Value<String> title,
  Value<String?> description,
  Value<DateTime> startTimeUtc,
  Value<DateTime> endTimeUtc,
  Value<String?> category,
  Value<String?> imageUrl,
});

final class $$EpgProgramsTableReferences
    extends BaseReferences<_$AppDatabase, $EpgProgramsTable, EpgProgram> {
  $$EpgProgramsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChannelsTable _channelIdTable(_$AppDatabase db) =>
      db.channels.createAlias('epg_programs__channel_id__channels__id');

  $$ChannelsTableProcessedTableManager get channelId {
    final $_column = $_itemColumn<int>('channel_id')!;

    final manager = $$ChannelsTableTableManager($_db, $_db.channels)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_channelIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$EpgProgramsTableFilterComposer
    extends Composer<_$AppDatabase, $EpgProgramsTable> {
  $$EpgProgramsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startTimeUtc => $composableBuilder(
      column: $table.startTimeUtc, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endTimeUtc => $composableBuilder(
      column: $table.endTimeUtc, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imageUrl => $composableBuilder(
      column: $table.imageUrl, builder: (column) => ColumnFilters(column));

  $$ChannelsTableFilterComposer get channelId {
    final $$ChannelsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.channelId,
        referencedTable: $db.channels,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChannelsTableFilterComposer(
              $db: $db,
              $table: $db.channels,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EpgProgramsTableOrderingComposer
    extends Composer<_$AppDatabase, $EpgProgramsTable> {
  $$EpgProgramsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startTimeUtc => $composableBuilder(
      column: $table.startTimeUtc,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endTimeUtc => $composableBuilder(
      column: $table.endTimeUtc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imageUrl => $composableBuilder(
      column: $table.imageUrl, builder: (column) => ColumnOrderings(column));

  $$ChannelsTableOrderingComposer get channelId {
    final $$ChannelsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.channelId,
        referencedTable: $db.channels,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChannelsTableOrderingComposer(
              $db: $db,
              $table: $db.channels,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EpgProgramsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EpgProgramsTable> {
  $$EpgProgramsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<DateTime> get startTimeUtc => $composableBuilder(
      column: $table.startTimeUtc, builder: (column) => column);

  GeneratedColumn<DateTime> get endTimeUtc => $composableBuilder(
      column: $table.endTimeUtc, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  $$ChannelsTableAnnotationComposer get channelId {
    final $$ChannelsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.channelId,
        referencedTable: $db.channels,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChannelsTableAnnotationComposer(
              $db: $db,
              $table: $db.channels,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EpgProgramsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EpgProgramsTable,
    EpgProgram,
    $$EpgProgramsTableFilterComposer,
    $$EpgProgramsTableOrderingComposer,
    $$EpgProgramsTableAnnotationComposer,
    $$EpgProgramsTableCreateCompanionBuilder,
    $$EpgProgramsTableUpdateCompanionBuilder,
    (EpgProgram, $$EpgProgramsTableReferences),
    EpgProgram,
    PrefetchHooks Function({bool channelId})> {
  $$EpgProgramsTableTableManager(_$AppDatabase db, $EpgProgramsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EpgProgramsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EpgProgramsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EpgProgramsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> channelId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<DateTime> startTimeUtc = const Value.absent(),
            Value<DateTime> endTimeUtc = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<String?> imageUrl = const Value.absent(),
          }) =>
              EpgProgramsCompanion(
            id: id,
            channelId: channelId,
            title: title,
            description: description,
            startTimeUtc: startTimeUtc,
            endTimeUtc: endTimeUtc,
            category: category,
            imageUrl: imageUrl,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int channelId,
            required String title,
            Value<String?> description = const Value.absent(),
            required DateTime startTimeUtc,
            required DateTime endTimeUtc,
            Value<String?> category = const Value.absent(),
            Value<String?> imageUrl = const Value.absent(),
          }) =>
              EpgProgramsCompanion.insert(
            id: id,
            channelId: channelId,
            title: title,
            description: description,
            startTimeUtc: startTimeUtc,
            endTimeUtc: endTimeUtc,
            category: category,
            imageUrl: imageUrl,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$EpgProgramsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({channelId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (channelId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.channelId,
                    referencedTable:
                        $$EpgProgramsTableReferences._channelIdTable(db),
                    referencedColumn:
                        $$EpgProgramsTableReferences._channelIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$EpgProgramsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EpgProgramsTable,
    EpgProgram,
    $$EpgProgramsTableFilterComposer,
    $$EpgProgramsTableOrderingComposer,
    $$EpgProgramsTableAnnotationComposer,
    $$EpgProgramsTableCreateCompanionBuilder,
    $$EpgProgramsTableUpdateCompanionBuilder,
    (EpgProgram, $$EpgProgramsTableReferences),
    EpgProgram,
    PrefetchHooks Function({bool channelId})>;
typedef $$VodItemsTableCreateCompanionBuilder = VodItemsCompanion Function({
  Value<int> id,
  required int playlistId,
  required String sourceId,
  required String name,
  required String streamUrl,
  Value<String?> logoUrl,
  Value<String?> categoryName,
  Value<String?> plot,
  Value<String?> cast,
  Value<String?> director,
  Value<String?> genre,
  Value<double?> rating,
  Value<int?> duration,
  Value<String?> year,
  Value<String> containerExtension,
  Value<bool> isActive,
  Value<DateTime?> addedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$VodItemsTableUpdateCompanionBuilder = VodItemsCompanion Function({
  Value<int> id,
  Value<int> playlistId,
  Value<String> sourceId,
  Value<String> name,
  Value<String> streamUrl,
  Value<String?> logoUrl,
  Value<String?> categoryName,
  Value<String?> plot,
  Value<String?> cast,
  Value<String?> director,
  Value<String?> genre,
  Value<double?> rating,
  Value<int?> duration,
  Value<String?> year,
  Value<String> containerExtension,
  Value<bool> isActive,
  Value<DateTime?> addedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$VodItemsTableReferences
    extends BaseReferences<_$AppDatabase, $VodItemsTable, VodItem> {
  $$VodItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PlaylistsTable _playlistIdTable(_$AppDatabase db) =>
      db.playlists.createAlias('vod_items__playlist_id__playlists__id');

  $$PlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<int>('playlist_id')!;

    final manager = $$PlaylistsTableTableManager($_db, $_db.playlists)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$VodItemsTableFilterComposer
    extends Composer<_$AppDatabase, $VodItemsTable> {
  $$VodItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceId => $composableBuilder(
      column: $table.sourceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get streamUrl => $composableBuilder(
      column: $table.streamUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get logoUrl => $composableBuilder(
      column: $table.logoUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryName => $composableBuilder(
      column: $table.categoryName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get plot => $composableBuilder(
      column: $table.plot, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cast => $composableBuilder(
      column: $table.cast, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get director => $composableBuilder(
      column: $table.director, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get genre => $composableBuilder(
      column: $table.genre, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get year => $composableBuilder(
      column: $table.year, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get containerExtension => $composableBuilder(
      column: $table.containerExtension,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$PlaylistsTableFilterComposer get playlistId {
    final $$PlaylistsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.playlistId,
        referencedTable: $db.playlists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlaylistsTableFilterComposer(
              $db: $db,
              $table: $db.playlists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$VodItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $VodItemsTable> {
  $$VodItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceId => $composableBuilder(
      column: $table.sourceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get streamUrl => $composableBuilder(
      column: $table.streamUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get logoUrl => $composableBuilder(
      column: $table.logoUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryName => $composableBuilder(
      column: $table.categoryName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get plot => $composableBuilder(
      column: $table.plot, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cast => $composableBuilder(
      column: $table.cast, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get director => $composableBuilder(
      column: $table.director, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get genre => $composableBuilder(
      column: $table.genre, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get year => $composableBuilder(
      column: $table.year, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get containerExtension => $composableBuilder(
      column: $table.containerExtension,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$PlaylistsTableOrderingComposer get playlistId {
    final $$PlaylistsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.playlistId,
        referencedTable: $db.playlists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlaylistsTableOrderingComposer(
              $db: $db,
              $table: $db.playlists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$VodItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VodItemsTable> {
  $$VodItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get streamUrl =>
      $composableBuilder(column: $table.streamUrl, builder: (column) => column);

  GeneratedColumn<String> get logoUrl =>
      $composableBuilder(column: $table.logoUrl, builder: (column) => column);

  GeneratedColumn<String> get categoryName => $composableBuilder(
      column: $table.categoryName, builder: (column) => column);

  GeneratedColumn<String> get plot =>
      $composableBuilder(column: $table.plot, builder: (column) => column);

  GeneratedColumn<String> get cast =>
      $composableBuilder(column: $table.cast, builder: (column) => column);

  GeneratedColumn<String> get director =>
      $composableBuilder(column: $table.director, builder: (column) => column);

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<String> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get containerExtension => $composableBuilder(
      column: $table.containerExtension, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$PlaylistsTableAnnotationComposer get playlistId {
    final $$PlaylistsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.playlistId,
        referencedTable: $db.playlists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlaylistsTableAnnotationComposer(
              $db: $db,
              $table: $db.playlists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$VodItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VodItemsTable,
    VodItem,
    $$VodItemsTableFilterComposer,
    $$VodItemsTableOrderingComposer,
    $$VodItemsTableAnnotationComposer,
    $$VodItemsTableCreateCompanionBuilder,
    $$VodItemsTableUpdateCompanionBuilder,
    (VodItem, $$VodItemsTableReferences),
    VodItem,
    PrefetchHooks Function({bool playlistId})> {
  $$VodItemsTableTableManager(_$AppDatabase db, $VodItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VodItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VodItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VodItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> playlistId = const Value.absent(),
            Value<String> sourceId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> streamUrl = const Value.absent(),
            Value<String?> logoUrl = const Value.absent(),
            Value<String?> categoryName = const Value.absent(),
            Value<String?> plot = const Value.absent(),
            Value<String?> cast = const Value.absent(),
            Value<String?> director = const Value.absent(),
            Value<String?> genre = const Value.absent(),
            Value<double?> rating = const Value.absent(),
            Value<int?> duration = const Value.absent(),
            Value<String?> year = const Value.absent(),
            Value<String> containerExtension = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime?> addedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              VodItemsCompanion(
            id: id,
            playlistId: playlistId,
            sourceId: sourceId,
            name: name,
            streamUrl: streamUrl,
            logoUrl: logoUrl,
            categoryName: categoryName,
            plot: plot,
            cast: cast,
            director: director,
            genre: genre,
            rating: rating,
            duration: duration,
            year: year,
            containerExtension: containerExtension,
            isActive: isActive,
            addedAt: addedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int playlistId,
            required String sourceId,
            required String name,
            required String streamUrl,
            Value<String?> logoUrl = const Value.absent(),
            Value<String?> categoryName = const Value.absent(),
            Value<String?> plot = const Value.absent(),
            Value<String?> cast = const Value.absent(),
            Value<String?> director = const Value.absent(),
            Value<String?> genre = const Value.absent(),
            Value<double?> rating = const Value.absent(),
            Value<int?> duration = const Value.absent(),
            Value<String?> year = const Value.absent(),
            Value<String> containerExtension = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime?> addedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              VodItemsCompanion.insert(
            id: id,
            playlistId: playlistId,
            sourceId: sourceId,
            name: name,
            streamUrl: streamUrl,
            logoUrl: logoUrl,
            categoryName: categoryName,
            plot: plot,
            cast: cast,
            director: director,
            genre: genre,
            rating: rating,
            duration: duration,
            year: year,
            containerExtension: containerExtension,
            isActive: isActive,
            addedAt: addedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$VodItemsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({playlistId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (playlistId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.playlistId,
                    referencedTable:
                        $$VodItemsTableReferences._playlistIdTable(db),
                    referencedColumn:
                        $$VodItemsTableReferences._playlistIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$VodItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $VodItemsTable,
    VodItem,
    $$VodItemsTableFilterComposer,
    $$VodItemsTableOrderingComposer,
    $$VodItemsTableAnnotationComposer,
    $$VodItemsTableCreateCompanionBuilder,
    $$VodItemsTableUpdateCompanionBuilder,
    (VodItem, $$VodItemsTableReferences),
    VodItem,
    PrefetchHooks Function({bool playlistId})>;
typedef $$SeriesItemsTableCreateCompanionBuilder = SeriesItemsCompanion
    Function({
  Value<int> id,
  required int playlistId,
  required String sourceId,
  required String name,
  Value<String?> coverUrl,
  Value<String?> categoryName,
  Value<String?> plot,
  Value<String?> cast,
  Value<String?> director,
  Value<String?> genre,
  Value<double?> rating,
  Value<String?> year,
  Value<String?> backdropUrl,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$SeriesItemsTableUpdateCompanionBuilder = SeriesItemsCompanion
    Function({
  Value<int> id,
  Value<int> playlistId,
  Value<String> sourceId,
  Value<String> name,
  Value<String?> coverUrl,
  Value<String?> categoryName,
  Value<String?> plot,
  Value<String?> cast,
  Value<String?> director,
  Value<String?> genre,
  Value<double?> rating,
  Value<String?> year,
  Value<String?> backdropUrl,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$SeriesItemsTableReferences
    extends BaseReferences<_$AppDatabase, $SeriesItemsTable, SeriesItem> {
  $$SeriesItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PlaylistsTable _playlistIdTable(_$AppDatabase db) =>
      db.playlists.createAlias('series_items__playlist_id__playlists__id');

  $$PlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<int>('playlist_id')!;

    final manager = $$PlaylistsTableTableManager($_db, $_db.playlists)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$SeasonsTable, List<Season>> _seasonsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.seasons,
          aliasName: 'series_items__id__seasons__series_id');

  $$SeasonsTableProcessedTableManager get seasonsRefs {
    final manager = $$SeasonsTableTableManager($_db, $_db.seasons)
        .filter((f) => f.seriesId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_seasonsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$EpisodesTable, List<Episode>> _episodesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.episodes,
          aliasName: 'series_items__id__episodes__series_id');

  $$EpisodesTableProcessedTableManager get episodesRefs {
    final manager = $$EpisodesTableTableManager($_db, $_db.episodes)
        .filter((f) => f.seriesId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_episodesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$SeriesItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SeriesItemsTable> {
  $$SeriesItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceId => $composableBuilder(
      column: $table.sourceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryName => $composableBuilder(
      column: $table.categoryName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get plot => $composableBuilder(
      column: $table.plot, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cast => $composableBuilder(
      column: $table.cast, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get director => $composableBuilder(
      column: $table.director, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get genre => $composableBuilder(
      column: $table.genre, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get year => $composableBuilder(
      column: $table.year, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get backdropUrl => $composableBuilder(
      column: $table.backdropUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$PlaylistsTableFilterComposer get playlistId {
    final $$PlaylistsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.playlistId,
        referencedTable: $db.playlists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlaylistsTableFilterComposer(
              $db: $db,
              $table: $db.playlists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> seasonsRefs(
      Expression<bool> Function($$SeasonsTableFilterComposer f) f) {
    final $$SeasonsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.seasons,
        getReferencedColumn: (t) => t.seriesId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SeasonsTableFilterComposer(
              $db: $db,
              $table: $db.seasons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> episodesRefs(
      Expression<bool> Function($$EpisodesTableFilterComposer f) f) {
    final $$EpisodesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.episodes,
        getReferencedColumn: (t) => t.seriesId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EpisodesTableFilterComposer(
              $db: $db,
              $table: $db.episodes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SeriesItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SeriesItemsTable> {
  $$SeriesItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceId => $composableBuilder(
      column: $table.sourceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryName => $composableBuilder(
      column: $table.categoryName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get plot => $composableBuilder(
      column: $table.plot, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cast => $composableBuilder(
      column: $table.cast, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get director => $composableBuilder(
      column: $table.director, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get genre => $composableBuilder(
      column: $table.genre, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get year => $composableBuilder(
      column: $table.year, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get backdropUrl => $composableBuilder(
      column: $table.backdropUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$PlaylistsTableOrderingComposer get playlistId {
    final $$PlaylistsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.playlistId,
        referencedTable: $db.playlists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlaylistsTableOrderingComposer(
              $db: $db,
              $table: $db.playlists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SeriesItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SeriesItemsTable> {
  $$SeriesItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get categoryName => $composableBuilder(
      column: $table.categoryName, builder: (column) => column);

  GeneratedColumn<String> get plot =>
      $composableBuilder(column: $table.plot, builder: (column) => column);

  GeneratedColumn<String> get cast =>
      $composableBuilder(column: $table.cast, builder: (column) => column);

  GeneratedColumn<String> get director =>
      $composableBuilder(column: $table.director, builder: (column) => column);

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get backdropUrl => $composableBuilder(
      column: $table.backdropUrl, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$PlaylistsTableAnnotationComposer get playlistId {
    final $$PlaylistsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.playlistId,
        referencedTable: $db.playlists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlaylistsTableAnnotationComposer(
              $db: $db,
              $table: $db.playlists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> seasonsRefs<T extends Object>(
      Expression<T> Function($$SeasonsTableAnnotationComposer a) f) {
    final $$SeasonsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.seasons,
        getReferencedColumn: (t) => t.seriesId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SeasonsTableAnnotationComposer(
              $db: $db,
              $table: $db.seasons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> episodesRefs<T extends Object>(
      Expression<T> Function($$EpisodesTableAnnotationComposer a) f) {
    final $$EpisodesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.episodes,
        getReferencedColumn: (t) => t.seriesId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EpisodesTableAnnotationComposer(
              $db: $db,
              $table: $db.episodes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SeriesItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SeriesItemsTable,
    SeriesItem,
    $$SeriesItemsTableFilterComposer,
    $$SeriesItemsTableOrderingComposer,
    $$SeriesItemsTableAnnotationComposer,
    $$SeriesItemsTableCreateCompanionBuilder,
    $$SeriesItemsTableUpdateCompanionBuilder,
    (SeriesItem, $$SeriesItemsTableReferences),
    SeriesItem,
    PrefetchHooks Function(
        {bool playlistId, bool seasonsRefs, bool episodesRefs})> {
  $$SeriesItemsTableTableManager(_$AppDatabase db, $SeriesItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeriesItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeriesItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeriesItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> playlistId = const Value.absent(),
            Value<String> sourceId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> coverUrl = const Value.absent(),
            Value<String?> categoryName = const Value.absent(),
            Value<String?> plot = const Value.absent(),
            Value<String?> cast = const Value.absent(),
            Value<String?> director = const Value.absent(),
            Value<String?> genre = const Value.absent(),
            Value<double?> rating = const Value.absent(),
            Value<String?> year = const Value.absent(),
            Value<String?> backdropUrl = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              SeriesItemsCompanion(
            id: id,
            playlistId: playlistId,
            sourceId: sourceId,
            name: name,
            coverUrl: coverUrl,
            categoryName: categoryName,
            plot: plot,
            cast: cast,
            director: director,
            genre: genre,
            rating: rating,
            year: year,
            backdropUrl: backdropUrl,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int playlistId,
            required String sourceId,
            required String name,
            Value<String?> coverUrl = const Value.absent(),
            Value<String?> categoryName = const Value.absent(),
            Value<String?> plot = const Value.absent(),
            Value<String?> cast = const Value.absent(),
            Value<String?> director = const Value.absent(),
            Value<String?> genre = const Value.absent(),
            Value<double?> rating = const Value.absent(),
            Value<String?> year = const Value.absent(),
            Value<String?> backdropUrl = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              SeriesItemsCompanion.insert(
            id: id,
            playlistId: playlistId,
            sourceId: sourceId,
            name: name,
            coverUrl: coverUrl,
            categoryName: categoryName,
            plot: plot,
            cast: cast,
            director: director,
            genre: genre,
            rating: rating,
            year: year,
            backdropUrl: backdropUrl,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SeriesItemsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {playlistId = false, seasonsRefs = false, episodesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (seasonsRefs) db.seasons,
                if (episodesRefs) db.episodes
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (playlistId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.playlistId,
                    referencedTable:
                        $$SeriesItemsTableReferences._playlistIdTable(db),
                    referencedColumn:
                        $$SeriesItemsTableReferences._playlistIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (seasonsRefs)
                    await $_getPrefetchedData<SeriesItem, $SeriesItemsTable,
                            Season>(
                        currentTable: table,
                        referencedTable:
                            $$SeriesItemsTableReferences._seasonsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SeriesItemsTableReferences(db, table, p0)
                                .seasonsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.seriesId == item.id),
                        typedResults: items),
                  if (episodesRefs)
                    await $_getPrefetchedData<SeriesItem, $SeriesItemsTable,
                            Episode>(
                        currentTable: table,
                        referencedTable:
                            $$SeriesItemsTableReferences._episodesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SeriesItemsTableReferences(db, table, p0)
                                .episodesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.seriesId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$SeriesItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SeriesItemsTable,
    SeriesItem,
    $$SeriesItemsTableFilterComposer,
    $$SeriesItemsTableOrderingComposer,
    $$SeriesItemsTableAnnotationComposer,
    $$SeriesItemsTableCreateCompanionBuilder,
    $$SeriesItemsTableUpdateCompanionBuilder,
    (SeriesItem, $$SeriesItemsTableReferences),
    SeriesItem,
    PrefetchHooks Function(
        {bool playlistId, bool seasonsRefs, bool episodesRefs})>;
typedef $$SeasonsTableCreateCompanionBuilder = SeasonsCompanion Function({
  Value<int> id,
  required int seriesId,
  required int seasonNumber,
  Value<String?> name,
  Value<String?> coverUrl,
  Value<int?> episodeCount,
  Value<String?> airDate,
  Value<DateTime> createdAt,
});
typedef $$SeasonsTableUpdateCompanionBuilder = SeasonsCompanion Function({
  Value<int> id,
  Value<int> seriesId,
  Value<int> seasonNumber,
  Value<String?> name,
  Value<String?> coverUrl,
  Value<int?> episodeCount,
  Value<String?> airDate,
  Value<DateTime> createdAt,
});

final class $$SeasonsTableReferences
    extends BaseReferences<_$AppDatabase, $SeasonsTable, Season> {
  $$SeasonsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SeriesItemsTable _seriesIdTable(_$AppDatabase db) =>
      db.seriesItems.createAlias('seasons__series_id__series_items__id');

  $$SeriesItemsTableProcessedTableManager get seriesId {
    final $_column = $_itemColumn<int>('series_id')!;

    final manager = $$SeriesItemsTableTableManager($_db, $_db.seriesItems)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_seriesIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$EpisodesTable, List<Episode>> _episodesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.episodes,
          aliasName: 'seasons__id__episodes__season_id');

  $$EpisodesTableProcessedTableManager get episodesRefs {
    final manager = $$EpisodesTableTableManager($_db, $_db.episodes)
        .filter((f) => f.seasonId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_episodesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$SeasonsTableFilterComposer
    extends Composer<_$AppDatabase, $SeasonsTable> {
  $$SeasonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get seasonNumber => $composableBuilder(
      column: $table.seasonNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get episodeCount => $composableBuilder(
      column: $table.episodeCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get airDate => $composableBuilder(
      column: $table.airDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$SeriesItemsTableFilterComposer get seriesId {
    final $$SeriesItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.seriesId,
        referencedTable: $db.seriesItems,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SeriesItemsTableFilterComposer(
              $db: $db,
              $table: $db.seriesItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> episodesRefs(
      Expression<bool> Function($$EpisodesTableFilterComposer f) f) {
    final $$EpisodesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.episodes,
        getReferencedColumn: (t) => t.seasonId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EpisodesTableFilterComposer(
              $db: $db,
              $table: $db.episodes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SeasonsTableOrderingComposer
    extends Composer<_$AppDatabase, $SeasonsTable> {
  $$SeasonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get seasonNumber => $composableBuilder(
      column: $table.seasonNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get episodeCount => $composableBuilder(
      column: $table.episodeCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get airDate => $composableBuilder(
      column: $table.airDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$SeriesItemsTableOrderingComposer get seriesId {
    final $$SeriesItemsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.seriesId,
        referencedTable: $db.seriesItems,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SeriesItemsTableOrderingComposer(
              $db: $db,
              $table: $db.seriesItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SeasonsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SeasonsTable> {
  $$SeasonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get seasonNumber => $composableBuilder(
      column: $table.seasonNumber, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<int> get episodeCount => $composableBuilder(
      column: $table.episodeCount, builder: (column) => column);

  GeneratedColumn<String> get airDate =>
      $composableBuilder(column: $table.airDate, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$SeriesItemsTableAnnotationComposer get seriesId {
    final $$SeriesItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.seriesId,
        referencedTable: $db.seriesItems,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SeriesItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.seriesItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> episodesRefs<T extends Object>(
      Expression<T> Function($$EpisodesTableAnnotationComposer a) f) {
    final $$EpisodesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.episodes,
        getReferencedColumn: (t) => t.seasonId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EpisodesTableAnnotationComposer(
              $db: $db,
              $table: $db.episodes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SeasonsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SeasonsTable,
    Season,
    $$SeasonsTableFilterComposer,
    $$SeasonsTableOrderingComposer,
    $$SeasonsTableAnnotationComposer,
    $$SeasonsTableCreateCompanionBuilder,
    $$SeasonsTableUpdateCompanionBuilder,
    (Season, $$SeasonsTableReferences),
    Season,
    PrefetchHooks Function({bool seriesId, bool episodesRefs})> {
  $$SeasonsTableTableManager(_$AppDatabase db, $SeasonsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeasonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeasonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeasonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> seriesId = const Value.absent(),
            Value<int> seasonNumber = const Value.absent(),
            Value<String?> name = const Value.absent(),
            Value<String?> coverUrl = const Value.absent(),
            Value<int?> episodeCount = const Value.absent(),
            Value<String?> airDate = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              SeasonsCompanion(
            id: id,
            seriesId: seriesId,
            seasonNumber: seasonNumber,
            name: name,
            coverUrl: coverUrl,
            episodeCount: episodeCount,
            airDate: airDate,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int seriesId,
            required int seasonNumber,
            Value<String?> name = const Value.absent(),
            Value<String?> coverUrl = const Value.absent(),
            Value<int?> episodeCount = const Value.absent(),
            Value<String?> airDate = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              SeasonsCompanion.insert(
            id: id,
            seriesId: seriesId,
            seasonNumber: seasonNumber,
            name: name,
            coverUrl: coverUrl,
            episodeCount: episodeCount,
            airDate: airDate,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$SeasonsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({seriesId = false, episodesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (episodesRefs) db.episodes],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (seriesId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.seriesId,
                    referencedTable:
                        $$SeasonsTableReferences._seriesIdTable(db),
                    referencedColumn:
                        $$SeasonsTableReferences._seriesIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (episodesRefs)
                    await $_getPrefetchedData<Season, $SeasonsTable, Episode>(
                        currentTable: table,
                        referencedTable:
                            $$SeasonsTableReferences._episodesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SeasonsTableReferences(db, table, p0)
                                .episodesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.seasonId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$SeasonsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SeasonsTable,
    Season,
    $$SeasonsTableFilterComposer,
    $$SeasonsTableOrderingComposer,
    $$SeasonsTableAnnotationComposer,
    $$SeasonsTableCreateCompanionBuilder,
    $$SeasonsTableUpdateCompanionBuilder,
    (Season, $$SeasonsTableReferences),
    Season,
    PrefetchHooks Function({bool seriesId, bool episodesRefs})>;
typedef $$EpisodesTableCreateCompanionBuilder = EpisodesCompanion Function({
  Value<int> id,
  required int seriesId,
  required int seasonId,
  required String sourceId,
  required int episodeNumber,
  required String title,
  required String streamUrl,
  Value<String> containerExtension,
  Value<String?> plot,
  Value<int?> duration,
  Value<String?> coverUrl,
  Value<double?> rating,
  Value<String?> releaseDate,
  Value<DateTime> createdAt,
});
typedef $$EpisodesTableUpdateCompanionBuilder = EpisodesCompanion Function({
  Value<int> id,
  Value<int> seriesId,
  Value<int> seasonId,
  Value<String> sourceId,
  Value<int> episodeNumber,
  Value<String> title,
  Value<String> streamUrl,
  Value<String> containerExtension,
  Value<String?> plot,
  Value<int?> duration,
  Value<String?> coverUrl,
  Value<double?> rating,
  Value<String?> releaseDate,
  Value<DateTime> createdAt,
});

final class $$EpisodesTableReferences
    extends BaseReferences<_$AppDatabase, $EpisodesTable, Episode> {
  $$EpisodesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SeriesItemsTable _seriesIdTable(_$AppDatabase db) =>
      db.seriesItems.createAlias('episodes__series_id__series_items__id');

  $$SeriesItemsTableProcessedTableManager get seriesId {
    final $_column = $_itemColumn<int>('series_id')!;

    final manager = $$SeriesItemsTableTableManager($_db, $_db.seriesItems)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_seriesIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $SeasonsTable _seasonIdTable(_$AppDatabase db) =>
      db.seasons.createAlias('episodes__season_id__seasons__id');

  $$SeasonsTableProcessedTableManager get seasonId {
    final $_column = $_itemColumn<int>('season_id')!;

    final manager = $$SeasonsTableTableManager($_db, $_db.seasons)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_seasonIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$EpisodesTableFilterComposer
    extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceId => $composableBuilder(
      column: $table.sourceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get episodeNumber => $composableBuilder(
      column: $table.episodeNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get streamUrl => $composableBuilder(
      column: $table.streamUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get containerExtension => $composableBuilder(
      column: $table.containerExtension,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get plot => $composableBuilder(
      column: $table.plot, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get releaseDate => $composableBuilder(
      column: $table.releaseDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$SeriesItemsTableFilterComposer get seriesId {
    final $$SeriesItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.seriesId,
        referencedTable: $db.seriesItems,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SeriesItemsTableFilterComposer(
              $db: $db,
              $table: $db.seriesItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SeasonsTableFilterComposer get seasonId {
    final $$SeasonsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.seasonId,
        referencedTable: $db.seasons,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SeasonsTableFilterComposer(
              $db: $db,
              $table: $db.seasons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EpisodesTableOrderingComposer
    extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceId => $composableBuilder(
      column: $table.sourceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get episodeNumber => $composableBuilder(
      column: $table.episodeNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get streamUrl => $composableBuilder(
      column: $table.streamUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get containerExtension => $composableBuilder(
      column: $table.containerExtension,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get plot => $composableBuilder(
      column: $table.plot, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get releaseDate => $composableBuilder(
      column: $table.releaseDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$SeriesItemsTableOrderingComposer get seriesId {
    final $$SeriesItemsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.seriesId,
        referencedTable: $db.seriesItems,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SeriesItemsTableOrderingComposer(
              $db: $db,
              $table: $db.seriesItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SeasonsTableOrderingComposer get seasonId {
    final $$SeasonsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.seasonId,
        referencedTable: $db.seasons,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SeasonsTableOrderingComposer(
              $db: $db,
              $table: $db.seasons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EpisodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<int> get episodeNumber => $composableBuilder(
      column: $table.episodeNumber, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get streamUrl =>
      $composableBuilder(column: $table.streamUrl, builder: (column) => column);

  GeneratedColumn<String> get containerExtension => $composableBuilder(
      column: $table.containerExtension, builder: (column) => column);

  GeneratedColumn<String> get plot =>
      $composableBuilder(column: $table.plot, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get releaseDate => $composableBuilder(
      column: $table.releaseDate, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$SeriesItemsTableAnnotationComposer get seriesId {
    final $$SeriesItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.seriesId,
        referencedTable: $db.seriesItems,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SeriesItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.seriesItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SeasonsTableAnnotationComposer get seasonId {
    final $$SeasonsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.seasonId,
        referencedTable: $db.seasons,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SeasonsTableAnnotationComposer(
              $db: $db,
              $table: $db.seasons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EpisodesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EpisodesTable,
    Episode,
    $$EpisodesTableFilterComposer,
    $$EpisodesTableOrderingComposer,
    $$EpisodesTableAnnotationComposer,
    $$EpisodesTableCreateCompanionBuilder,
    $$EpisodesTableUpdateCompanionBuilder,
    (Episode, $$EpisodesTableReferences),
    Episode,
    PrefetchHooks Function({bool seriesId, bool seasonId})> {
  $$EpisodesTableTableManager(_$AppDatabase db, $EpisodesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EpisodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EpisodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EpisodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> seriesId = const Value.absent(),
            Value<int> seasonId = const Value.absent(),
            Value<String> sourceId = const Value.absent(),
            Value<int> episodeNumber = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> streamUrl = const Value.absent(),
            Value<String> containerExtension = const Value.absent(),
            Value<String?> plot = const Value.absent(),
            Value<int?> duration = const Value.absent(),
            Value<String?> coverUrl = const Value.absent(),
            Value<double?> rating = const Value.absent(),
            Value<String?> releaseDate = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              EpisodesCompanion(
            id: id,
            seriesId: seriesId,
            seasonId: seasonId,
            sourceId: sourceId,
            episodeNumber: episodeNumber,
            title: title,
            streamUrl: streamUrl,
            containerExtension: containerExtension,
            plot: plot,
            duration: duration,
            coverUrl: coverUrl,
            rating: rating,
            releaseDate: releaseDate,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int seriesId,
            required int seasonId,
            required String sourceId,
            required int episodeNumber,
            required String title,
            required String streamUrl,
            Value<String> containerExtension = const Value.absent(),
            Value<String?> plot = const Value.absent(),
            Value<int?> duration = const Value.absent(),
            Value<String?> coverUrl = const Value.absent(),
            Value<double?> rating = const Value.absent(),
            Value<String?> releaseDate = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              EpisodesCompanion.insert(
            id: id,
            seriesId: seriesId,
            seasonId: seasonId,
            sourceId: sourceId,
            episodeNumber: episodeNumber,
            title: title,
            streamUrl: streamUrl,
            containerExtension: containerExtension,
            plot: plot,
            duration: duration,
            coverUrl: coverUrl,
            rating: rating,
            releaseDate: releaseDate,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$EpisodesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({seriesId = false, seasonId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (seriesId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.seriesId,
                    referencedTable:
                        $$EpisodesTableReferences._seriesIdTable(db),
                    referencedColumn:
                        $$EpisodesTableReferences._seriesIdTable(db).id,
                  ) as T;
                }
                if (seasonId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.seasonId,
                    referencedTable:
                        $$EpisodesTableReferences._seasonIdTable(db),
                    referencedColumn:
                        $$EpisodesTableReferences._seasonIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$EpisodesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EpisodesTable,
    Episode,
    $$EpisodesTableFilterComposer,
    $$EpisodesTableOrderingComposer,
    $$EpisodesTableAnnotationComposer,
    $$EpisodesTableCreateCompanionBuilder,
    $$EpisodesTableUpdateCompanionBuilder,
    (Episode, $$EpisodesTableReferences),
    Episode,
    PrefetchHooks Function({bool seriesId, bool seasonId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PlaylistsTableTableManager get playlists =>
      $$PlaylistsTableTableManager(_db, _db.playlists);
  $$ChannelsTableTableManager get channels =>
      $$ChannelsTableTableManager(_db, _db.channels);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db, _db.favorites);
  $$WatchHistoryEntriesTableTableManager get watchHistoryEntries =>
      $$WatchHistoryEntriesTableTableManager(_db, _db.watchHistoryEntries);
  $$EpgProgramsTableTableManager get epgPrograms =>
      $$EpgProgramsTableTableManager(_db, _db.epgPrograms);
  $$VodItemsTableTableManager get vodItems =>
      $$VodItemsTableTableManager(_db, _db.vodItems);
  $$SeriesItemsTableTableManager get seriesItems =>
      $$SeriesItemsTableTableManager(_db, _db.seriesItems);
  $$SeasonsTableTableManager get seasons =>
      $$SeasonsTableTableManager(_db, _db.seasons);
  $$EpisodesTableTableManager get episodes =>
      $$EpisodesTableTableManager(_db, _db.episodes);
}
