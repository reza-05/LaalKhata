// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_database.dart';

// ignore_for_file: type=lint
class $LocalLedgerStatesTable extends LocalLedgerStates
    with TableInfo<$LocalLedgerStatesTable, LocalLedgerState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalLedgerStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _smsTransactionCutoffAtMeta =
      const VerificationMeta('smsTransactionCutoffAt');
  @override
  late final GeneratedColumn<DateTime> smsTransactionCutoffAt =
      GeneratedColumn<DateTime>('sms_transaction_cutoff_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [userId, smsTransactionCutoffAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_ledger_states';
  @override
  VerificationContext validateIntegrity(Insertable<LocalLedgerState> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('sms_transaction_cutoff_at')) {
      context.handle(
          _smsTransactionCutoffAtMeta,
          smsTransactionCutoffAt.isAcceptableOrUnknown(
              data['sms_transaction_cutoff_at']!, _smsTransactionCutoffAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  LocalLedgerState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalLedgerState(
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      smsTransactionCutoffAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}sms_transaction_cutoff_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LocalLedgerStatesTable createAlias(String alias) {
    return $LocalLedgerStatesTable(attachedDatabase, alias);
  }
}

class LocalLedgerState extends DataClass
    implements Insertable<LocalLedgerState> {
  final String userId;
  final DateTime? smsTransactionCutoffAt;
  final DateTime updatedAt;
  const LocalLedgerState(
      {required this.userId,
      this.smsTransactionCutoffAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || smsTransactionCutoffAt != null) {
      map['sms_transaction_cutoff_at'] =
          Variable<DateTime>(smsTransactionCutoffAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalLedgerStatesCompanion toCompanion(bool nullToAbsent) {
    return LocalLedgerStatesCompanion(
      userId: Value(userId),
      smsTransactionCutoffAt: smsTransactionCutoffAt == null && nullToAbsent
          ? const Value.absent()
          : Value(smsTransactionCutoffAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalLedgerState.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalLedgerState(
      userId: serializer.fromJson<String>(json['userId']),
      smsTransactionCutoffAt:
          serializer.fromJson<DateTime?>(json['smsTransactionCutoffAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'smsTransactionCutoffAt':
          serializer.toJson<DateTime?>(smsTransactionCutoffAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalLedgerState copyWith(
          {String? userId,
          Value<DateTime?> smsTransactionCutoffAt = const Value.absent(),
          DateTime? updatedAt}) =>
      LocalLedgerState(
        userId: userId ?? this.userId,
        smsTransactionCutoffAt: smsTransactionCutoffAt.present
            ? smsTransactionCutoffAt.value
            : this.smsTransactionCutoffAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LocalLedgerState copyWithCompanion(LocalLedgerStatesCompanion data) {
    return LocalLedgerState(
      userId: data.userId.present ? data.userId.value : this.userId,
      smsTransactionCutoffAt: data.smsTransactionCutoffAt.present
          ? data.smsTransactionCutoffAt.value
          : this.smsTransactionCutoffAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalLedgerState(')
          ..write('userId: $userId, ')
          ..write('smsTransactionCutoffAt: $smsTransactionCutoffAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, smsTransactionCutoffAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalLedgerState &&
          other.userId == this.userId &&
          other.smsTransactionCutoffAt == this.smsTransactionCutoffAt &&
          other.updatedAt == this.updatedAt);
}

class LocalLedgerStatesCompanion extends UpdateCompanion<LocalLedgerState> {
  final Value<String> userId;
  final Value<DateTime?> smsTransactionCutoffAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalLedgerStatesCompanion({
    this.userId = const Value.absent(),
    this.smsTransactionCutoffAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalLedgerStatesCompanion.insert({
    required String userId,
    this.smsTransactionCutoffAt = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : userId = Value(userId),
        updatedAt = Value(updatedAt);
  static Insertable<LocalLedgerState> custom({
    Expression<String>? userId,
    Expression<DateTime>? smsTransactionCutoffAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (smsTransactionCutoffAt != null)
        'sms_transaction_cutoff_at': smsTransactionCutoffAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalLedgerStatesCompanion copyWith(
      {Value<String>? userId,
      Value<DateTime?>? smsTransactionCutoffAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return LocalLedgerStatesCompanion(
      userId: userId ?? this.userId,
      smsTransactionCutoffAt:
          smsTransactionCutoffAt ?? this.smsTransactionCutoffAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (smsTransactionCutoffAt.present) {
      map['sms_transaction_cutoff_at'] =
          Variable<DateTime>(smsTransactionCutoffAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalLedgerStatesCompanion(')
          ..write('userId: $userId, ')
          ..write('smsTransactionCutoffAt: $smsTransactionCutoffAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalMoneySourcesTable extends LocalMoneySources
    with TableInfo<$LocalMoneySourcesTable, LocalMoneySource> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMoneySourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceKeyMeta =
      const VerificationMeta('sourceKey');
  @override
  late final GeneratedColumn<String> sourceKey = GeneratedColumn<String>(
      'source_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceTypeMeta =
      const VerificationMeta('sourceType');
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
      'source_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _balanceMeta =
      const VerificationMeta('balance');
  @override
  late final GeneratedColumn<double> balance = GeneratedColumn<double>(
      'balance', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _colorValueMeta =
      const VerificationMeta('colorValue');
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
      'color_value', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _iconCodePointMeta =
      const VerificationMeta('iconCodePoint');
  @override
  late final GeneratedColumn<int> iconCodePoint = GeneratedColumn<int>(
      'icon_code_point', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _archivedMeta =
      const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
      'archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sortPositionMeta =
      const VerificationMeta('sortPosition');
  @override
  late final GeneratedColumn<int> sortPosition = GeneratedColumn<int>(
      'sort_position', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        userId,
        sourceKey,
        name,
        sourceType,
        balance,
        colorValue,
        iconCodePoint,
        archived,
        sortPosition,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_money_sources';
  @override
  VerificationContext validateIntegrity(Insertable<LocalMoneySource> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('source_key')) {
      context.handle(_sourceKeyMeta,
          sourceKey.isAcceptableOrUnknown(data['source_key']!, _sourceKeyMeta));
    } else if (isInserting) {
      context.missing(_sourceKeyMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
          _sourceTypeMeta,
          sourceType.isAcceptableOrUnknown(
              data['source_type']!, _sourceTypeMeta));
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('balance')) {
      context.handle(_balanceMeta,
          balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta));
    }
    if (data.containsKey('color_value')) {
      context.handle(
          _colorValueMeta,
          colorValue.isAcceptableOrUnknown(
              data['color_value']!, _colorValueMeta));
    } else if (isInserting) {
      context.missing(_colorValueMeta);
    }
    if (data.containsKey('icon_code_point')) {
      context.handle(
          _iconCodePointMeta,
          iconCodePoint.isAcceptableOrUnknown(
              data['icon_code_point']!, _iconCodePointMeta));
    } else if (isInserting) {
      context.missing(_iconCodePointMeta);
    }
    if (data.containsKey('archived')) {
      context.handle(_archivedMeta,
          archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta));
    }
    if (data.containsKey('sort_position')) {
      context.handle(
          _sortPositionMeta,
          sortPosition.isAcceptableOrUnknown(
              data['sort_position']!, _sortPositionMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, sourceKey};
  @override
  LocalMoneySource map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMoneySource(
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      sourceKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_key'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      sourceType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_type'])!,
      balance: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}balance']),
      colorValue: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color_value'])!,
      iconCodePoint: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}icon_code_point'])!,
      archived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}archived'])!,
      sortPosition: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_position'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LocalMoneySourcesTable createAlias(String alias) {
    return $LocalMoneySourcesTable(attachedDatabase, alias);
  }
}

class LocalMoneySource extends DataClass
    implements Insertable<LocalMoneySource> {
  final String userId;
  final String sourceKey;
  final String name;
  final String sourceType;
  final double? balance;
  final int colorValue;
  final int iconCodePoint;
  final bool archived;
  final int sortPosition;
  final DateTime updatedAt;
  const LocalMoneySource(
      {required this.userId,
      required this.sourceKey,
      required this.name,
      required this.sourceType,
      this.balance,
      required this.colorValue,
      required this.iconCodePoint,
      required this.archived,
      required this.sortPosition,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['source_key'] = Variable<String>(sourceKey);
    map['name'] = Variable<String>(name);
    map['source_type'] = Variable<String>(sourceType);
    if (!nullToAbsent || balance != null) {
      map['balance'] = Variable<double>(balance);
    }
    map['color_value'] = Variable<int>(colorValue);
    map['icon_code_point'] = Variable<int>(iconCodePoint);
    map['archived'] = Variable<bool>(archived);
    map['sort_position'] = Variable<int>(sortPosition);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalMoneySourcesCompanion toCompanion(bool nullToAbsent) {
    return LocalMoneySourcesCompanion(
      userId: Value(userId),
      sourceKey: Value(sourceKey),
      name: Value(name),
      sourceType: Value(sourceType),
      balance: balance == null && nullToAbsent
          ? const Value.absent()
          : Value(balance),
      colorValue: Value(colorValue),
      iconCodePoint: Value(iconCodePoint),
      archived: Value(archived),
      sortPosition: Value(sortPosition),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalMoneySource.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMoneySource(
      userId: serializer.fromJson<String>(json['userId']),
      sourceKey: serializer.fromJson<String>(json['sourceKey']),
      name: serializer.fromJson<String>(json['name']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      balance: serializer.fromJson<double?>(json['balance']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
      iconCodePoint: serializer.fromJson<int>(json['iconCodePoint']),
      archived: serializer.fromJson<bool>(json['archived']),
      sortPosition: serializer.fromJson<int>(json['sortPosition']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'sourceKey': serializer.toJson<String>(sourceKey),
      'name': serializer.toJson<String>(name),
      'sourceType': serializer.toJson<String>(sourceType),
      'balance': serializer.toJson<double?>(balance),
      'colorValue': serializer.toJson<int>(colorValue),
      'iconCodePoint': serializer.toJson<int>(iconCodePoint),
      'archived': serializer.toJson<bool>(archived),
      'sortPosition': serializer.toJson<int>(sortPosition),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalMoneySource copyWith(
          {String? userId,
          String? sourceKey,
          String? name,
          String? sourceType,
          Value<double?> balance = const Value.absent(),
          int? colorValue,
          int? iconCodePoint,
          bool? archived,
          int? sortPosition,
          DateTime? updatedAt}) =>
      LocalMoneySource(
        userId: userId ?? this.userId,
        sourceKey: sourceKey ?? this.sourceKey,
        name: name ?? this.name,
        sourceType: sourceType ?? this.sourceType,
        balance: balance.present ? balance.value : this.balance,
        colorValue: colorValue ?? this.colorValue,
        iconCodePoint: iconCodePoint ?? this.iconCodePoint,
        archived: archived ?? this.archived,
        sortPosition: sortPosition ?? this.sortPosition,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LocalMoneySource copyWithCompanion(LocalMoneySourcesCompanion data) {
    return LocalMoneySource(
      userId: data.userId.present ? data.userId.value : this.userId,
      sourceKey: data.sourceKey.present ? data.sourceKey.value : this.sourceKey,
      name: data.name.present ? data.name.value : this.name,
      sourceType:
          data.sourceType.present ? data.sourceType.value : this.sourceType,
      balance: data.balance.present ? data.balance.value : this.balance,
      colorValue:
          data.colorValue.present ? data.colorValue.value : this.colorValue,
      iconCodePoint: data.iconCodePoint.present
          ? data.iconCodePoint.value
          : this.iconCodePoint,
      archived: data.archived.present ? data.archived.value : this.archived,
      sortPosition: data.sortPosition.present
          ? data.sortPosition.value
          : this.sortPosition,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMoneySource(')
          ..write('userId: $userId, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('name: $name, ')
          ..write('sourceType: $sourceType, ')
          ..write('balance: $balance, ')
          ..write('colorValue: $colorValue, ')
          ..write('iconCodePoint: $iconCodePoint, ')
          ..write('archived: $archived, ')
          ..write('sortPosition: $sortPosition, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, sourceKey, name, sourceType, balance,
      colorValue, iconCodePoint, archived, sortPosition, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMoneySource &&
          other.userId == this.userId &&
          other.sourceKey == this.sourceKey &&
          other.name == this.name &&
          other.sourceType == this.sourceType &&
          other.balance == this.balance &&
          other.colorValue == this.colorValue &&
          other.iconCodePoint == this.iconCodePoint &&
          other.archived == this.archived &&
          other.sortPosition == this.sortPosition &&
          other.updatedAt == this.updatedAt);
}

class LocalMoneySourcesCompanion extends UpdateCompanion<LocalMoneySource> {
  final Value<String> userId;
  final Value<String> sourceKey;
  final Value<String> name;
  final Value<String> sourceType;
  final Value<double?> balance;
  final Value<int> colorValue;
  final Value<int> iconCodePoint;
  final Value<bool> archived;
  final Value<int> sortPosition;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalMoneySourcesCompanion({
    this.userId = const Value.absent(),
    this.sourceKey = const Value.absent(),
    this.name = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.balance = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.iconCodePoint = const Value.absent(),
    this.archived = const Value.absent(),
    this.sortPosition = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMoneySourcesCompanion.insert({
    required String userId,
    required String sourceKey,
    required String name,
    required String sourceType,
    this.balance = const Value.absent(),
    required int colorValue,
    required int iconCodePoint,
    this.archived = const Value.absent(),
    this.sortPosition = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : userId = Value(userId),
        sourceKey = Value(sourceKey),
        name = Value(name),
        sourceType = Value(sourceType),
        colorValue = Value(colorValue),
        iconCodePoint = Value(iconCodePoint),
        updatedAt = Value(updatedAt);
  static Insertable<LocalMoneySource> custom({
    Expression<String>? userId,
    Expression<String>? sourceKey,
    Expression<String>? name,
    Expression<String>? sourceType,
    Expression<double>? balance,
    Expression<int>? colorValue,
    Expression<int>? iconCodePoint,
    Expression<bool>? archived,
    Expression<int>? sortPosition,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (sourceKey != null) 'source_key': sourceKey,
      if (name != null) 'name': name,
      if (sourceType != null) 'source_type': sourceType,
      if (balance != null) 'balance': balance,
      if (colorValue != null) 'color_value': colorValue,
      if (iconCodePoint != null) 'icon_code_point': iconCodePoint,
      if (archived != null) 'archived': archived,
      if (sortPosition != null) 'sort_position': sortPosition,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalMoneySourcesCompanion copyWith(
      {Value<String>? userId,
      Value<String>? sourceKey,
      Value<String>? name,
      Value<String>? sourceType,
      Value<double?>? balance,
      Value<int>? colorValue,
      Value<int>? iconCodePoint,
      Value<bool>? archived,
      Value<int>? sortPosition,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return LocalMoneySourcesCompanion(
      userId: userId ?? this.userId,
      sourceKey: sourceKey ?? this.sourceKey,
      name: name ?? this.name,
      sourceType: sourceType ?? this.sourceType,
      balance: balance ?? this.balance,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      archived: archived ?? this.archived,
      sortPosition: sortPosition ?? this.sortPosition,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (sourceKey.present) {
      map['source_key'] = Variable<String>(sourceKey.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (balance.present) {
      map['balance'] = Variable<double>(balance.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (iconCodePoint.present) {
      map['icon_code_point'] = Variable<int>(iconCodePoint.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (sortPosition.present) {
      map['sort_position'] = Variable<int>(sortPosition.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMoneySourcesCompanion(')
          ..write('userId: $userId, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('name: $name, ')
          ..write('sourceType: $sourceType, ')
          ..write('balance: $balance, ')
          ..write('colorValue: $colorValue, ')
          ..write('iconCodePoint: $iconCodePoint, ')
          ..write('archived: $archived, ')
          ..write('sortPosition: $sortPosition, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalLedgerActivitiesTable extends LocalLedgerActivities
    with TableInfo<$LocalLedgerActivitiesTable, LocalLedgerActivity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalLedgerActivitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _activityKeyMeta =
      const VerificationMeta('activityKey');
  @override
  late final GeneratedColumn<String> activityKey = GeneratedColumn<String>(
      'activity_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _displayTimeMeta =
      const VerificationMeta('displayTime');
  @override
  late final GeneratedColumn<String> displayTime = GeneratedColumn<String>(
      'display_time', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconCodePointMeta =
      const VerificationMeta('iconCodePoint');
  @override
  late final GeneratedColumn<int> iconCodePoint = GeneratedColumn<int>(
      'icon_code_point', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _occurredAtMeta =
      const VerificationMeta('occurredAt');
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
      'occurred_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _activityTypeMeta =
      const VerificationMeta('activityType');
  @override
  late final GeneratedColumn<String> activityType = GeneratedColumn<String>(
      'activity_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sortPositionMeta =
      const VerificationMeta('sortPosition');
  @override
  late final GeneratedColumn<int> sortPosition = GeneratedColumn<int>(
      'sort_position', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        userId,
        activityKey,
        name,
        source,
        amount,
        displayTime,
        iconCodePoint,
        occurredAt,
        category,
        activityType,
        sortPosition,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_ledger_activities';
  @override
  VerificationContext validateIntegrity(
      Insertable<LocalLedgerActivity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('activity_key')) {
      context.handle(
          _activityKeyMeta,
          activityKey.isAcceptableOrUnknown(
              data['activity_key']!, _activityKeyMeta));
    } else if (isInserting) {
      context.missing(_activityKeyMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('display_time')) {
      context.handle(
          _displayTimeMeta,
          displayTime.isAcceptableOrUnknown(
              data['display_time']!, _displayTimeMeta));
    } else if (isInserting) {
      context.missing(_displayTimeMeta);
    }
    if (data.containsKey('icon_code_point')) {
      context.handle(
          _iconCodePointMeta,
          iconCodePoint.isAcceptableOrUnknown(
              data['icon_code_point']!, _iconCodePointMeta));
    } else if (isInserting) {
      context.missing(_iconCodePointMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
          _occurredAtMeta,
          occurredAt.isAcceptableOrUnknown(
              data['occurred_at']!, _occurredAtMeta));
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('activity_type')) {
      context.handle(
          _activityTypeMeta,
          activityType.isAcceptableOrUnknown(
              data['activity_type']!, _activityTypeMeta));
    } else if (isInserting) {
      context.missing(_activityTypeMeta);
    }
    if (data.containsKey('sort_position')) {
      context.handle(
          _sortPositionMeta,
          sortPosition.isAcceptableOrUnknown(
              data['sort_position']!, _sortPositionMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, activityKey};
  @override
  LocalLedgerActivity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalLedgerActivity(
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      activityKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}activity_key'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      displayTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_time'])!,
      iconCodePoint: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}icon_code_point'])!,
      occurredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}occurred_at'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      activityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}activity_type'])!,
      sortPosition: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_position'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LocalLedgerActivitiesTable createAlias(String alias) {
    return $LocalLedgerActivitiesTable(attachedDatabase, alias);
  }
}

class LocalLedgerActivity extends DataClass
    implements Insertable<LocalLedgerActivity> {
  final String userId;
  final String activityKey;
  final String name;
  final String source;
  final double amount;
  final String displayTime;
  final int iconCodePoint;
  final DateTime occurredAt;
  final String category;
  final String activityType;
  final int sortPosition;
  final DateTime updatedAt;
  const LocalLedgerActivity(
      {required this.userId,
      required this.activityKey,
      required this.name,
      required this.source,
      required this.amount,
      required this.displayTime,
      required this.iconCodePoint,
      required this.occurredAt,
      required this.category,
      required this.activityType,
      required this.sortPosition,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['activity_key'] = Variable<String>(activityKey);
    map['name'] = Variable<String>(name);
    map['source'] = Variable<String>(source);
    map['amount'] = Variable<double>(amount);
    map['display_time'] = Variable<String>(displayTime);
    map['icon_code_point'] = Variable<int>(iconCodePoint);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['category'] = Variable<String>(category);
    map['activity_type'] = Variable<String>(activityType);
    map['sort_position'] = Variable<int>(sortPosition);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalLedgerActivitiesCompanion toCompanion(bool nullToAbsent) {
    return LocalLedgerActivitiesCompanion(
      userId: Value(userId),
      activityKey: Value(activityKey),
      name: Value(name),
      source: Value(source),
      amount: Value(amount),
      displayTime: Value(displayTime),
      iconCodePoint: Value(iconCodePoint),
      occurredAt: Value(occurredAt),
      category: Value(category),
      activityType: Value(activityType),
      sortPosition: Value(sortPosition),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalLedgerActivity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalLedgerActivity(
      userId: serializer.fromJson<String>(json['userId']),
      activityKey: serializer.fromJson<String>(json['activityKey']),
      name: serializer.fromJson<String>(json['name']),
      source: serializer.fromJson<String>(json['source']),
      amount: serializer.fromJson<double>(json['amount']),
      displayTime: serializer.fromJson<String>(json['displayTime']),
      iconCodePoint: serializer.fromJson<int>(json['iconCodePoint']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      category: serializer.fromJson<String>(json['category']),
      activityType: serializer.fromJson<String>(json['activityType']),
      sortPosition: serializer.fromJson<int>(json['sortPosition']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'activityKey': serializer.toJson<String>(activityKey),
      'name': serializer.toJson<String>(name),
      'source': serializer.toJson<String>(source),
      'amount': serializer.toJson<double>(amount),
      'displayTime': serializer.toJson<String>(displayTime),
      'iconCodePoint': serializer.toJson<int>(iconCodePoint),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'category': serializer.toJson<String>(category),
      'activityType': serializer.toJson<String>(activityType),
      'sortPosition': serializer.toJson<int>(sortPosition),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalLedgerActivity copyWith(
          {String? userId,
          String? activityKey,
          String? name,
          String? source,
          double? amount,
          String? displayTime,
          int? iconCodePoint,
          DateTime? occurredAt,
          String? category,
          String? activityType,
          int? sortPosition,
          DateTime? updatedAt}) =>
      LocalLedgerActivity(
        userId: userId ?? this.userId,
        activityKey: activityKey ?? this.activityKey,
        name: name ?? this.name,
        source: source ?? this.source,
        amount: amount ?? this.amount,
        displayTime: displayTime ?? this.displayTime,
        iconCodePoint: iconCodePoint ?? this.iconCodePoint,
        occurredAt: occurredAt ?? this.occurredAt,
        category: category ?? this.category,
        activityType: activityType ?? this.activityType,
        sortPosition: sortPosition ?? this.sortPosition,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LocalLedgerActivity copyWithCompanion(LocalLedgerActivitiesCompanion data) {
    return LocalLedgerActivity(
      userId: data.userId.present ? data.userId.value : this.userId,
      activityKey:
          data.activityKey.present ? data.activityKey.value : this.activityKey,
      name: data.name.present ? data.name.value : this.name,
      source: data.source.present ? data.source.value : this.source,
      amount: data.amount.present ? data.amount.value : this.amount,
      displayTime:
          data.displayTime.present ? data.displayTime.value : this.displayTime,
      iconCodePoint: data.iconCodePoint.present
          ? data.iconCodePoint.value
          : this.iconCodePoint,
      occurredAt:
          data.occurredAt.present ? data.occurredAt.value : this.occurredAt,
      category: data.category.present ? data.category.value : this.category,
      activityType: data.activityType.present
          ? data.activityType.value
          : this.activityType,
      sortPosition: data.sortPosition.present
          ? data.sortPosition.value
          : this.sortPosition,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalLedgerActivity(')
          ..write('userId: $userId, ')
          ..write('activityKey: $activityKey, ')
          ..write('name: $name, ')
          ..write('source: $source, ')
          ..write('amount: $amount, ')
          ..write('displayTime: $displayTime, ')
          ..write('iconCodePoint: $iconCodePoint, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('category: $category, ')
          ..write('activityType: $activityType, ')
          ..write('sortPosition: $sortPosition, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      userId,
      activityKey,
      name,
      source,
      amount,
      displayTime,
      iconCodePoint,
      occurredAt,
      category,
      activityType,
      sortPosition,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalLedgerActivity &&
          other.userId == this.userId &&
          other.activityKey == this.activityKey &&
          other.name == this.name &&
          other.source == this.source &&
          other.amount == this.amount &&
          other.displayTime == this.displayTime &&
          other.iconCodePoint == this.iconCodePoint &&
          other.occurredAt == this.occurredAt &&
          other.category == this.category &&
          other.activityType == this.activityType &&
          other.sortPosition == this.sortPosition &&
          other.updatedAt == this.updatedAt);
}

class LocalLedgerActivitiesCompanion
    extends UpdateCompanion<LocalLedgerActivity> {
  final Value<String> userId;
  final Value<String> activityKey;
  final Value<String> name;
  final Value<String> source;
  final Value<double> amount;
  final Value<String> displayTime;
  final Value<int> iconCodePoint;
  final Value<DateTime> occurredAt;
  final Value<String> category;
  final Value<String> activityType;
  final Value<int> sortPosition;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalLedgerActivitiesCompanion({
    this.userId = const Value.absent(),
    this.activityKey = const Value.absent(),
    this.name = const Value.absent(),
    this.source = const Value.absent(),
    this.amount = const Value.absent(),
    this.displayTime = const Value.absent(),
    this.iconCodePoint = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.category = const Value.absent(),
    this.activityType = const Value.absent(),
    this.sortPosition = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalLedgerActivitiesCompanion.insert({
    required String userId,
    required String activityKey,
    required String name,
    required String source,
    required double amount,
    required String displayTime,
    required int iconCodePoint,
    required DateTime occurredAt,
    required String category,
    required String activityType,
    this.sortPosition = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : userId = Value(userId),
        activityKey = Value(activityKey),
        name = Value(name),
        source = Value(source),
        amount = Value(amount),
        displayTime = Value(displayTime),
        iconCodePoint = Value(iconCodePoint),
        occurredAt = Value(occurredAt),
        category = Value(category),
        activityType = Value(activityType),
        updatedAt = Value(updatedAt);
  static Insertable<LocalLedgerActivity> custom({
    Expression<String>? userId,
    Expression<String>? activityKey,
    Expression<String>? name,
    Expression<String>? source,
    Expression<double>? amount,
    Expression<String>? displayTime,
    Expression<int>? iconCodePoint,
    Expression<DateTime>? occurredAt,
    Expression<String>? category,
    Expression<String>? activityType,
    Expression<int>? sortPosition,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (activityKey != null) 'activity_key': activityKey,
      if (name != null) 'name': name,
      if (source != null) 'source': source,
      if (amount != null) 'amount': amount,
      if (displayTime != null) 'display_time': displayTime,
      if (iconCodePoint != null) 'icon_code_point': iconCodePoint,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (category != null) 'category': category,
      if (activityType != null) 'activity_type': activityType,
      if (sortPosition != null) 'sort_position': sortPosition,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalLedgerActivitiesCompanion copyWith(
      {Value<String>? userId,
      Value<String>? activityKey,
      Value<String>? name,
      Value<String>? source,
      Value<double>? amount,
      Value<String>? displayTime,
      Value<int>? iconCodePoint,
      Value<DateTime>? occurredAt,
      Value<String>? category,
      Value<String>? activityType,
      Value<int>? sortPosition,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return LocalLedgerActivitiesCompanion(
      userId: userId ?? this.userId,
      activityKey: activityKey ?? this.activityKey,
      name: name ?? this.name,
      source: source ?? this.source,
      amount: amount ?? this.amount,
      displayTime: displayTime ?? this.displayTime,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      occurredAt: occurredAt ?? this.occurredAt,
      category: category ?? this.category,
      activityType: activityType ?? this.activityType,
      sortPosition: sortPosition ?? this.sortPosition,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (activityKey.present) {
      map['activity_key'] = Variable<String>(activityKey.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (displayTime.present) {
      map['display_time'] = Variable<String>(displayTime.value);
    }
    if (iconCodePoint.present) {
      map['icon_code_point'] = Variable<int>(iconCodePoint.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (activityType.present) {
      map['activity_type'] = Variable<String>(activityType.value);
    }
    if (sortPosition.present) {
      map['sort_position'] = Variable<int>(sortPosition.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalLedgerActivitiesCompanion(')
          ..write('userId: $userId, ')
          ..write('activityKey: $activityKey, ')
          ..write('name: $name, ')
          ..write('source: $source, ')
          ..write('amount: $amount, ')
          ..write('displayTime: $displayTime, ')
          ..write('iconCodePoint: $iconCodePoint, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('category: $category, ')
          ..write('activityType: $activityType, ')
          ..write('sortPosition: $sortPosition, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSyncOutboxTable extends LocalSyncOutbox
    with TableInfo<$LocalSyncOutboxTable, LocalSyncOutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSyncOutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _operationIdMeta =
      const VerificationMeta('operationId');
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
      'operation_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
      'entity_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _attemptsMeta =
      const VerificationMeta('attempts');
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
      'attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _nextAttemptAtMeta =
      const VerificationMeta('nextAttemptAt');
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>('next_attempt_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        operationId,
        userId,
        entityType,
        entityId,
        operation,
        payloadJson,
        status,
        attempts,
        lastError,
        createdAt,
        nextAttemptAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_sync_outbox';
  @override
  VerificationContext validateIntegrity(
      Insertable<LocalSyncOutboxData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('operation_id')) {
      context.handle(
          _operationIdMeta,
          operationId.isAcceptableOrUnknown(
              data['operation_id']!, _operationIdMeta));
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
          _entityTypeMeta,
          entityType.isAcceptableOrUnknown(
              data['entity_type']!, _entityTypeMeta));
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('attempts')) {
      context.handle(_attemptsMeta,
          attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
          _nextAttemptAtMeta,
          nextAttemptAt.isAcceptableOrUnknown(
              data['next_attempt_at']!, _nextAttemptAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {operationId};
  @override
  LocalSyncOutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSyncOutboxData(
      operationId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      entityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_type'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      attempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempts'])!,
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}next_attempt_at']),
    );
  }

  @override
  $LocalSyncOutboxTable createAlias(String alias) {
    return $LocalSyncOutboxTable(attachedDatabase, alias);
  }
}

class LocalSyncOutboxData extends DataClass
    implements Insertable<LocalSyncOutboxData> {
  final String operationId;
  final String userId;
  final String entityType;
  final String entityId;
  final String operation;
  final String payloadJson;
  final String status;
  final int attempts;
  final String? lastError;
  final DateTime createdAt;
  final DateTime? nextAttemptAt;
  const LocalSyncOutboxData(
      {required this.operationId,
      required this.userId,
      required this.entityType,
      required this.entityId,
      required this.operation,
      required this.payloadJson,
      required this.status,
      required this.attempts,
      this.lastError,
      required this.createdAt,
      this.nextAttemptAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['operation_id'] = Variable<String>(operationId);
    map['user_id'] = Variable<String>(userId);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['operation'] = Variable<String>(operation);
    map['payload_json'] = Variable<String>(payloadJson);
    map['status'] = Variable<String>(status);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    return map;
  }

  LocalSyncOutboxCompanion toCompanion(bool nullToAbsent) {
    return LocalSyncOutboxCompanion(
      operationId: Value(operationId),
      userId: Value(userId),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operation: Value(operation),
      payloadJson: Value(payloadJson),
      status: Value(status),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
    );
  }

  factory LocalSyncOutboxData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSyncOutboxData(
      operationId: serializer.fromJson<String>(json['operationId']),
      userId: serializer.fromJson<String>(json['userId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      status: serializer.fromJson<String>(json['status']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'operationId': serializer.toJson<String>(operationId),
      'userId': serializer.toJson<String>(userId),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(operation),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'status': serializer.toJson<String>(status),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
    };
  }

  LocalSyncOutboxData copyWith(
          {String? operationId,
          String? userId,
          String? entityType,
          String? entityId,
          String? operation,
          String? payloadJson,
          String? status,
          int? attempts,
          Value<String?> lastError = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> nextAttemptAt = const Value.absent()}) =>
      LocalSyncOutboxData(
        operationId: operationId ?? this.operationId,
        userId: userId ?? this.userId,
        entityType: entityType ?? this.entityType,
        entityId: entityId ?? this.entityId,
        operation: operation ?? this.operation,
        payloadJson: payloadJson ?? this.payloadJson,
        status: status ?? this.status,
        attempts: attempts ?? this.attempts,
        lastError: lastError.present ? lastError.value : this.lastError,
        createdAt: createdAt ?? this.createdAt,
        nextAttemptAt:
            nextAttemptAt.present ? nextAttemptAt.value : this.nextAttemptAt,
      );
  LocalSyncOutboxData copyWithCompanion(LocalSyncOutboxCompanion data) {
    return LocalSyncOutboxData(
      operationId:
          data.operationId.present ? data.operationId.value : this.operationId,
      userId: data.userId.present ? data.userId.value : this.userId,
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSyncOutboxData(')
          ..write('operationId: $operationId, ')
          ..write('userId: $userId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('nextAttemptAt: $nextAttemptAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      operationId,
      userId,
      entityType,
      entityId,
      operation,
      payloadJson,
      status,
      attempts,
      lastError,
      createdAt,
      nextAttemptAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSyncOutboxData &&
          other.operationId == this.operationId &&
          other.userId == this.userId &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.payloadJson == this.payloadJson &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt &&
          other.nextAttemptAt == this.nextAttemptAt);
}

class LocalSyncOutboxCompanion extends UpdateCompanion<LocalSyncOutboxData> {
  final Value<String> operationId;
  final Value<String> userId;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> operation;
  final Value<String> payloadJson;
  final Value<String> status;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<DateTime?> nextAttemptAt;
  final Value<int> rowid;
  const LocalSyncOutboxCompanion({
    this.operationId = const Value.absent(),
    this.userId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSyncOutboxCompanion.insert({
    required String operationId,
    required String userId,
    required String entityType,
    required String entityId,
    required String operation,
    required String payloadJson,
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    required DateTime createdAt,
    this.nextAttemptAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : operationId = Value(operationId),
        userId = Value(userId),
        entityType = Value(entityType),
        entityId = Value(entityId),
        operation = Value(operation),
        payloadJson = Value(payloadJson),
        createdAt = Value(createdAt);
  static Insertable<LocalSyncOutboxData> custom({
    Expression<String>? operationId,
    Expression<String>? userId,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<String>? payloadJson,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? nextAttemptAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (operationId != null) 'operation_id': operationId,
      if (userId != null) 'user_id': userId,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSyncOutboxCompanion copyWith(
      {Value<String>? operationId,
      Value<String>? userId,
      Value<String>? entityType,
      Value<String>? entityId,
      Value<String>? operation,
      Value<String>? payloadJson,
      Value<String>? status,
      Value<int>? attempts,
      Value<String?>? lastError,
      Value<DateTime>? createdAt,
      Value<DateTime?>? nextAttemptAt,
      Value<int>? rowid}) {
    return LocalSyncOutboxCompanion(
      operationId: operationId ?? this.operationId,
      userId: userId ?? this.userId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payloadJson: payloadJson ?? this.payloadJson,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSyncOutboxCompanion(')
          ..write('operationId: $operationId, ')
          ..write('userId: $userId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LedgerDatabase extends GeneratedDatabase {
  _$LedgerDatabase(QueryExecutor e) : super(e);
  $LedgerDatabaseManager get managers => $LedgerDatabaseManager(this);
  late final $LocalLedgerStatesTable localLedgerStates =
      $LocalLedgerStatesTable(this);
  late final $LocalMoneySourcesTable localMoneySources =
      $LocalMoneySourcesTable(this);
  late final $LocalLedgerActivitiesTable localLedgerActivities =
      $LocalLedgerActivitiesTable(this);
  late final $LocalSyncOutboxTable localSyncOutbox =
      $LocalSyncOutboxTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        localLedgerStates,
        localMoneySources,
        localLedgerActivities,
        localSyncOutbox
      ];
}

typedef $$LocalLedgerStatesTableCreateCompanionBuilder
    = LocalLedgerStatesCompanion Function({
  required String userId,
  Value<DateTime?> smsTransactionCutoffAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$LocalLedgerStatesTableUpdateCompanionBuilder
    = LocalLedgerStatesCompanion Function({
  Value<String> userId,
  Value<DateTime?> smsTransactionCutoffAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$LocalLedgerStatesTableFilterComposer
    extends Composer<_$LedgerDatabase, $LocalLedgerStatesTable> {
  $$LocalLedgerStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get smsTransactionCutoffAt => $composableBuilder(
      column: $table.smsTransactionCutoffAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$LocalLedgerStatesTableOrderingComposer
    extends Composer<_$LedgerDatabase, $LocalLedgerStatesTable> {
  $$LocalLedgerStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get smsTransactionCutoffAt => $composableBuilder(
      column: $table.smsTransactionCutoffAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalLedgerStatesTableAnnotationComposer
    extends Composer<_$LedgerDatabase, $LocalLedgerStatesTable> {
  $$LocalLedgerStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get smsTransactionCutoffAt => $composableBuilder(
      column: $table.smsTransactionCutoffAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalLedgerStatesTableTableManager extends RootTableManager<
    _$LedgerDatabase,
    $LocalLedgerStatesTable,
    LocalLedgerState,
    $$LocalLedgerStatesTableFilterComposer,
    $$LocalLedgerStatesTableOrderingComposer,
    $$LocalLedgerStatesTableAnnotationComposer,
    $$LocalLedgerStatesTableCreateCompanionBuilder,
    $$LocalLedgerStatesTableUpdateCompanionBuilder,
    (
      LocalLedgerState,
      BaseReferences<_$LedgerDatabase, $LocalLedgerStatesTable,
          LocalLedgerState>
    ),
    LocalLedgerState,
    PrefetchHooks Function()> {
  $$LocalLedgerStatesTableTableManager(
      _$LedgerDatabase db, $LocalLedgerStatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalLedgerStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalLedgerStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalLedgerStatesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> userId = const Value.absent(),
            Value<DateTime?> smsTransactionCutoffAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalLedgerStatesCompanion(
            userId: userId,
            smsTransactionCutoffAt: smsTransactionCutoffAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String userId,
            Value<DateTime?> smsTransactionCutoffAt = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalLedgerStatesCompanion.insert(
            userId: userId,
            smsTransactionCutoffAt: smsTransactionCutoffAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalLedgerStatesTableProcessedTableManager = ProcessedTableManager<
    _$LedgerDatabase,
    $LocalLedgerStatesTable,
    LocalLedgerState,
    $$LocalLedgerStatesTableFilterComposer,
    $$LocalLedgerStatesTableOrderingComposer,
    $$LocalLedgerStatesTableAnnotationComposer,
    $$LocalLedgerStatesTableCreateCompanionBuilder,
    $$LocalLedgerStatesTableUpdateCompanionBuilder,
    (
      LocalLedgerState,
      BaseReferences<_$LedgerDatabase, $LocalLedgerStatesTable,
          LocalLedgerState>
    ),
    LocalLedgerState,
    PrefetchHooks Function()>;
typedef $$LocalMoneySourcesTableCreateCompanionBuilder
    = LocalMoneySourcesCompanion Function({
  required String userId,
  required String sourceKey,
  required String name,
  required String sourceType,
  Value<double?> balance,
  required int colorValue,
  required int iconCodePoint,
  Value<bool> archived,
  Value<int> sortPosition,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$LocalMoneySourcesTableUpdateCompanionBuilder
    = LocalMoneySourcesCompanion Function({
  Value<String> userId,
  Value<String> sourceKey,
  Value<String> name,
  Value<String> sourceType,
  Value<double?> balance,
  Value<int> colorValue,
  Value<int> iconCodePoint,
  Value<bool> archived,
  Value<int> sortPosition,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$LocalMoneySourcesTableFilterComposer
    extends Composer<_$LedgerDatabase, $LocalMoneySourcesTable> {
  $$LocalMoneySourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceKey => $composableBuilder(
      column: $table.sourceKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceType => $composableBuilder(
      column: $table.sourceType, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get balance => $composableBuilder(
      column: $table.balance, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get colorValue => $composableBuilder(
      column: $table.colorValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get iconCodePoint => $composableBuilder(
      column: $table.iconCodePoint, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortPosition => $composableBuilder(
      column: $table.sortPosition, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$LocalMoneySourcesTableOrderingComposer
    extends Composer<_$LedgerDatabase, $LocalMoneySourcesTable> {
  $$LocalMoneySourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceKey => $composableBuilder(
      column: $table.sourceKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceType => $composableBuilder(
      column: $table.sourceType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get balance => $composableBuilder(
      column: $table.balance, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get colorValue => $composableBuilder(
      column: $table.colorValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get iconCodePoint => $composableBuilder(
      column: $table.iconCodePoint,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortPosition => $composableBuilder(
      column: $table.sortPosition,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalMoneySourcesTableAnnotationComposer
    extends Composer<_$LedgerDatabase, $LocalMoneySourcesTable> {
  $$LocalMoneySourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get sourceKey =>
      $composableBuilder(column: $table.sourceKey, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
      column: $table.sourceType, builder: (column) => column);

  GeneratedColumn<double> get balance =>
      $composableBuilder(column: $table.balance, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
      column: $table.colorValue, builder: (column) => column);

  GeneratedColumn<int> get iconCodePoint => $composableBuilder(
      column: $table.iconCodePoint, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<int> get sortPosition => $composableBuilder(
      column: $table.sortPosition, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalMoneySourcesTableTableManager extends RootTableManager<
    _$LedgerDatabase,
    $LocalMoneySourcesTable,
    LocalMoneySource,
    $$LocalMoneySourcesTableFilterComposer,
    $$LocalMoneySourcesTableOrderingComposer,
    $$LocalMoneySourcesTableAnnotationComposer,
    $$LocalMoneySourcesTableCreateCompanionBuilder,
    $$LocalMoneySourcesTableUpdateCompanionBuilder,
    (
      LocalMoneySource,
      BaseReferences<_$LedgerDatabase, $LocalMoneySourcesTable,
          LocalMoneySource>
    ),
    LocalMoneySource,
    PrefetchHooks Function()> {
  $$LocalMoneySourcesTableTableManager(
      _$LedgerDatabase db, $LocalMoneySourcesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalMoneySourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalMoneySourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalMoneySourcesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> userId = const Value.absent(),
            Value<String> sourceKey = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> sourceType = const Value.absent(),
            Value<double?> balance = const Value.absent(),
            Value<int> colorValue = const Value.absent(),
            Value<int> iconCodePoint = const Value.absent(),
            Value<bool> archived = const Value.absent(),
            Value<int> sortPosition = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalMoneySourcesCompanion(
            userId: userId,
            sourceKey: sourceKey,
            name: name,
            sourceType: sourceType,
            balance: balance,
            colorValue: colorValue,
            iconCodePoint: iconCodePoint,
            archived: archived,
            sortPosition: sortPosition,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String userId,
            required String sourceKey,
            required String name,
            required String sourceType,
            Value<double?> balance = const Value.absent(),
            required int colorValue,
            required int iconCodePoint,
            Value<bool> archived = const Value.absent(),
            Value<int> sortPosition = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalMoneySourcesCompanion.insert(
            userId: userId,
            sourceKey: sourceKey,
            name: name,
            sourceType: sourceType,
            balance: balance,
            colorValue: colorValue,
            iconCodePoint: iconCodePoint,
            archived: archived,
            sortPosition: sortPosition,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalMoneySourcesTableProcessedTableManager = ProcessedTableManager<
    _$LedgerDatabase,
    $LocalMoneySourcesTable,
    LocalMoneySource,
    $$LocalMoneySourcesTableFilterComposer,
    $$LocalMoneySourcesTableOrderingComposer,
    $$LocalMoneySourcesTableAnnotationComposer,
    $$LocalMoneySourcesTableCreateCompanionBuilder,
    $$LocalMoneySourcesTableUpdateCompanionBuilder,
    (
      LocalMoneySource,
      BaseReferences<_$LedgerDatabase, $LocalMoneySourcesTable,
          LocalMoneySource>
    ),
    LocalMoneySource,
    PrefetchHooks Function()>;
typedef $$LocalLedgerActivitiesTableCreateCompanionBuilder
    = LocalLedgerActivitiesCompanion Function({
  required String userId,
  required String activityKey,
  required String name,
  required String source,
  required double amount,
  required String displayTime,
  required int iconCodePoint,
  required DateTime occurredAt,
  required String category,
  required String activityType,
  Value<int> sortPosition,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$LocalLedgerActivitiesTableUpdateCompanionBuilder
    = LocalLedgerActivitiesCompanion Function({
  Value<String> userId,
  Value<String> activityKey,
  Value<String> name,
  Value<String> source,
  Value<double> amount,
  Value<String> displayTime,
  Value<int> iconCodePoint,
  Value<DateTime> occurredAt,
  Value<String> category,
  Value<String> activityType,
  Value<int> sortPosition,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$LocalLedgerActivitiesTableFilterComposer
    extends Composer<_$LedgerDatabase, $LocalLedgerActivitiesTable> {
  $$LocalLedgerActivitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activityKey => $composableBuilder(
      column: $table.activityKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayTime => $composableBuilder(
      column: $table.displayTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get iconCodePoint => $composableBuilder(
      column: $table.iconCodePoint, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activityType => $composableBuilder(
      column: $table.activityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortPosition => $composableBuilder(
      column: $table.sortPosition, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$LocalLedgerActivitiesTableOrderingComposer
    extends Composer<_$LedgerDatabase, $LocalLedgerActivitiesTable> {
  $$LocalLedgerActivitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activityKey => $composableBuilder(
      column: $table.activityKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayTime => $composableBuilder(
      column: $table.displayTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get iconCodePoint => $composableBuilder(
      column: $table.iconCodePoint,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activityType => $composableBuilder(
      column: $table.activityType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortPosition => $composableBuilder(
      column: $table.sortPosition,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalLedgerActivitiesTableAnnotationComposer
    extends Composer<_$LedgerDatabase, $LocalLedgerActivitiesTable> {
  $$LocalLedgerActivitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get activityKey => $composableBuilder(
      column: $table.activityKey, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get displayTime => $composableBuilder(
      column: $table.displayTime, builder: (column) => column);

  GeneratedColumn<int> get iconCodePoint => $composableBuilder(
      column: $table.iconCodePoint, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get activityType => $composableBuilder(
      column: $table.activityType, builder: (column) => column);

  GeneratedColumn<int> get sortPosition => $composableBuilder(
      column: $table.sortPosition, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalLedgerActivitiesTableTableManager extends RootTableManager<
    _$LedgerDatabase,
    $LocalLedgerActivitiesTable,
    LocalLedgerActivity,
    $$LocalLedgerActivitiesTableFilterComposer,
    $$LocalLedgerActivitiesTableOrderingComposer,
    $$LocalLedgerActivitiesTableAnnotationComposer,
    $$LocalLedgerActivitiesTableCreateCompanionBuilder,
    $$LocalLedgerActivitiesTableUpdateCompanionBuilder,
    (
      LocalLedgerActivity,
      BaseReferences<_$LedgerDatabase, $LocalLedgerActivitiesTable,
          LocalLedgerActivity>
    ),
    LocalLedgerActivity,
    PrefetchHooks Function()> {
  $$LocalLedgerActivitiesTableTableManager(
      _$LedgerDatabase db, $LocalLedgerActivitiesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalLedgerActivitiesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalLedgerActivitiesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalLedgerActivitiesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> userId = const Value.absent(),
            Value<String> activityKey = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> displayTime = const Value.absent(),
            Value<int> iconCodePoint = const Value.absent(),
            Value<DateTime> occurredAt = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> activityType = const Value.absent(),
            Value<int> sortPosition = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalLedgerActivitiesCompanion(
            userId: userId,
            activityKey: activityKey,
            name: name,
            source: source,
            amount: amount,
            displayTime: displayTime,
            iconCodePoint: iconCodePoint,
            occurredAt: occurredAt,
            category: category,
            activityType: activityType,
            sortPosition: sortPosition,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String userId,
            required String activityKey,
            required String name,
            required String source,
            required double amount,
            required String displayTime,
            required int iconCodePoint,
            required DateTime occurredAt,
            required String category,
            required String activityType,
            Value<int> sortPosition = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalLedgerActivitiesCompanion.insert(
            userId: userId,
            activityKey: activityKey,
            name: name,
            source: source,
            amount: amount,
            displayTime: displayTime,
            iconCodePoint: iconCodePoint,
            occurredAt: occurredAt,
            category: category,
            activityType: activityType,
            sortPosition: sortPosition,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalLedgerActivitiesTableProcessedTableManager
    = ProcessedTableManager<
        _$LedgerDatabase,
        $LocalLedgerActivitiesTable,
        LocalLedgerActivity,
        $$LocalLedgerActivitiesTableFilterComposer,
        $$LocalLedgerActivitiesTableOrderingComposer,
        $$LocalLedgerActivitiesTableAnnotationComposer,
        $$LocalLedgerActivitiesTableCreateCompanionBuilder,
        $$LocalLedgerActivitiesTableUpdateCompanionBuilder,
        (
          LocalLedgerActivity,
          BaseReferences<_$LedgerDatabase, $LocalLedgerActivitiesTable,
              LocalLedgerActivity>
        ),
        LocalLedgerActivity,
        PrefetchHooks Function()>;
typedef $$LocalSyncOutboxTableCreateCompanionBuilder = LocalSyncOutboxCompanion
    Function({
  required String operationId,
  required String userId,
  required String entityType,
  required String entityId,
  required String operation,
  required String payloadJson,
  Value<String> status,
  Value<int> attempts,
  Value<String?> lastError,
  required DateTime createdAt,
  Value<DateTime?> nextAttemptAt,
  Value<int> rowid,
});
typedef $$LocalSyncOutboxTableUpdateCompanionBuilder = LocalSyncOutboxCompanion
    Function({
  Value<String> operationId,
  Value<String> userId,
  Value<String> entityType,
  Value<String> entityId,
  Value<String> operation,
  Value<String> payloadJson,
  Value<String> status,
  Value<int> attempts,
  Value<String?> lastError,
  Value<DateTime> createdAt,
  Value<DateTime?> nextAttemptAt,
  Value<int> rowid,
});

class $$LocalSyncOutboxTableFilterComposer
    extends Composer<_$LedgerDatabase, $LocalSyncOutboxTable> {
  $$LocalSyncOutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get operationId => $composableBuilder(
      column: $table.operationId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt, builder: (column) => ColumnFilters(column));
}

class $$LocalSyncOutboxTableOrderingComposer
    extends Composer<_$LedgerDatabase, $LocalSyncOutboxTable> {
  $$LocalSyncOutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get operationId => $composableBuilder(
      column: $table.operationId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt,
      builder: (column) => ColumnOrderings(column));
}

class $$LocalSyncOutboxTableAnnotationComposer
    extends Composer<_$LedgerDatabase, $LocalSyncOutboxTable> {
  $$LocalSyncOutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get operationId => $composableBuilder(
      column: $table.operationId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt, builder: (column) => column);
}

class $$LocalSyncOutboxTableTableManager extends RootTableManager<
    _$LedgerDatabase,
    $LocalSyncOutboxTable,
    LocalSyncOutboxData,
    $$LocalSyncOutboxTableFilterComposer,
    $$LocalSyncOutboxTableOrderingComposer,
    $$LocalSyncOutboxTableAnnotationComposer,
    $$LocalSyncOutboxTableCreateCompanionBuilder,
    $$LocalSyncOutboxTableUpdateCompanionBuilder,
    (
      LocalSyncOutboxData,
      BaseReferences<_$LedgerDatabase, $LocalSyncOutboxTable,
          LocalSyncOutboxData>
    ),
    LocalSyncOutboxData,
    PrefetchHooks Function()> {
  $$LocalSyncOutboxTableTableManager(
      _$LedgerDatabase db, $LocalSyncOutboxTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSyncOutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSyncOutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSyncOutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> operationId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> entityType = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> nextAttemptAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalSyncOutboxCompanion(
            operationId: operationId,
            userId: userId,
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            payloadJson: payloadJson,
            status: status,
            attempts: attempts,
            lastError: lastError,
            createdAt: createdAt,
            nextAttemptAt: nextAttemptAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String operationId,
            required String userId,
            required String entityType,
            required String entityId,
            required String operation,
            required String payloadJson,
            Value<String> status = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            required DateTime createdAt,
            Value<DateTime?> nextAttemptAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalSyncOutboxCompanion.insert(
            operationId: operationId,
            userId: userId,
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            payloadJson: payloadJson,
            status: status,
            attempts: attempts,
            lastError: lastError,
            createdAt: createdAt,
            nextAttemptAt: nextAttemptAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalSyncOutboxTableProcessedTableManager = ProcessedTableManager<
    _$LedgerDatabase,
    $LocalSyncOutboxTable,
    LocalSyncOutboxData,
    $$LocalSyncOutboxTableFilterComposer,
    $$LocalSyncOutboxTableOrderingComposer,
    $$LocalSyncOutboxTableAnnotationComposer,
    $$LocalSyncOutboxTableCreateCompanionBuilder,
    $$LocalSyncOutboxTableUpdateCompanionBuilder,
    (
      LocalSyncOutboxData,
      BaseReferences<_$LedgerDatabase, $LocalSyncOutboxTable,
          LocalSyncOutboxData>
    ),
    LocalSyncOutboxData,
    PrefetchHooks Function()>;

class $LedgerDatabaseManager {
  final _$LedgerDatabase _db;
  $LedgerDatabaseManager(this._db);
  $$LocalLedgerStatesTableTableManager get localLedgerStates =>
      $$LocalLedgerStatesTableTableManager(_db, _db.localLedgerStates);
  $$LocalMoneySourcesTableTableManager get localMoneySources =>
      $$LocalMoneySourcesTableTableManager(_db, _db.localMoneySources);
  $$LocalLedgerActivitiesTableTableManager get localLedgerActivities =>
      $$LocalLedgerActivitiesTableTableManager(_db, _db.localLedgerActivities);
  $$LocalSyncOutboxTableTableManager get localSyncOutbox =>
      $$LocalSyncOutboxTableTableManager(_db, _db.localSyncOutbox);
}
