// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $GoalsTable extends Goals with TableInfo<$GoalsTable, Goal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _parentIdMeta =
      const VerificationMeta('parentId');
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
      'parent_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES goals (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _aimMeta = const VerificationMeta('aim');
  @override
  late final GeneratedColumn<String> aim = GeneratedColumn<String>(
      'aim', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _timeframeMeta =
      const VerificationMeta('timeframe');
  @override
  late final GeneratedColumn<String> timeframe = GeneratedColumn<String>(
      'timeframe', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deadlineMeta =
      const VerificationMeta('deadline');
  @override
  late final GeneratedColumn<int> deadline = GeneratedColumn<int>(
      'deadline', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<int> weight = GeneratedColumn<int>(
      'weight', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('not_started'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _colorIndexMeta =
      const VerificationMeta('colorIndex');
  @override
  late final GeneratedColumn<int> colorIndex = GeneratedColumn<int>(
      'color_index', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        parentId,
        name,
        aim,
        timeframe,
        deadline,
        weight,
        status,
        createdAt,
        completedAt,
        colorIndex
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(Insertable<Goal> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(_parentIdMeta,
          parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('aim')) {
      context.handle(
          _aimMeta, aim.isAcceptableOrUnknown(data['aim']!, _aimMeta));
    }
    if (data.containsKey('timeframe')) {
      context.handle(_timeframeMeta,
          timeframe.isAcceptableOrUnknown(data['timeframe']!, _timeframeMeta));
    } else if (isInserting) {
      context.missing(_timeframeMeta);
    }
    if (data.containsKey('deadline')) {
      context.handle(_deadlineMeta,
          deadline.isAcceptableOrUnknown(data['deadline']!, _deadlineMeta));
    } else if (isInserting) {
      context.missing(_deadlineMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(_weightMeta,
          weight.isAcceptableOrUnknown(data['weight']!, _weightMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('color_index')) {
      context.handle(
          _colorIndexMeta,
          colorIndex.isAcceptableOrUnknown(
              data['color_index']!, _colorIndexMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Goal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Goal(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      parentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      aim: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}aim']),
      timeframe: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}timeframe'])!,
      deadline: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deadline'])!,
      weight: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}weight'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}completed_at']),
      colorIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color_index'])!,
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }
}

class Goal extends DataClass implements Insertable<Goal> {
  final String id;
  final String? parentId;
  final String name;
  final String? aim;
  final String timeframe;
  final int deadline;
  final int weight;
  final String status;
  final int createdAt;
  final int? completedAt;
  final int colorIndex;
  const Goal(
      {required this.id,
      this.parentId,
      required this.name,
      this.aim,
      required this.timeframe,
      required this.deadline,
      required this.weight,
      required this.status,
      required this.createdAt,
      this.completedAt,
      required this.colorIndex});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || aim != null) {
      map['aim'] = Variable<String>(aim);
    }
    map['timeframe'] = Variable<String>(timeframe);
    map['deadline'] = Variable<int>(deadline);
    map['weight'] = Variable<int>(weight);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    map['color_index'] = Variable<int>(colorIndex);
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      name: Value(name),
      aim: aim == null && nullToAbsent ? const Value.absent() : Value(aim),
      timeframe: Value(timeframe),
      deadline: Value(deadline),
      weight: Value(weight),
      status: Value(status),
      createdAt: Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      colorIndex: Value(colorIndex),
    );
  }

  factory Goal.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Goal(
      id: serializer.fromJson<String>(json['id']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      name: serializer.fromJson<String>(json['name']),
      aim: serializer.fromJson<String?>(json['aim']),
      timeframe: serializer.fromJson<String>(json['timeframe']),
      deadline: serializer.fromJson<int>(json['deadline']),
      weight: serializer.fromJson<int>(json['weight']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
      colorIndex: serializer.fromJson<int>(json['colorIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'parentId': serializer.toJson<String?>(parentId),
      'name': serializer.toJson<String>(name),
      'aim': serializer.toJson<String?>(aim),
      'timeframe': serializer.toJson<String>(timeframe),
      'deadline': serializer.toJson<int>(deadline),
      'weight': serializer.toJson<int>(weight),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<int>(createdAt),
      'completedAt': serializer.toJson<int?>(completedAt),
      'colorIndex': serializer.toJson<int>(colorIndex),
    };
  }

  Goal copyWith(
          {String? id,
          Value<String?> parentId = const Value.absent(),
          String? name,
          Value<String?> aim = const Value.absent(),
          String? timeframe,
          int? deadline,
          int? weight,
          String? status,
          int? createdAt,
          Value<int?> completedAt = const Value.absent(),
          int? colorIndex}) =>
      Goal(
        id: id ?? this.id,
        parentId: parentId.present ? parentId.value : this.parentId,
        name: name ?? this.name,
        aim: aim.present ? aim.value : this.aim,
        timeframe: timeframe ?? this.timeframe,
        deadline: deadline ?? this.deadline,
        weight: weight ?? this.weight,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
        colorIndex: colorIndex ?? this.colorIndex,
      );
  Goal copyWithCompanion(GoalsCompanion data) {
    return Goal(
      id: data.id.present ? data.id.value : this.id,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      name: data.name.present ? data.name.value : this.name,
      aim: data.aim.present ? data.aim.value : this.aim,
      timeframe: data.timeframe.present ? data.timeframe.value : this.timeframe,
      deadline: data.deadline.present ? data.deadline.value : this.deadline,
      weight: data.weight.present ? data.weight.value : this.weight,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      colorIndex:
          data.colorIndex.present ? data.colorIndex.value : this.colorIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Goal(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name, ')
          ..write('aim: $aim, ')
          ..write('timeframe: $timeframe, ')
          ..write('deadline: $deadline, ')
          ..write('weight: $weight, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('colorIndex: $colorIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, parentId, name, aim, timeframe, deadline,
      weight, status, createdAt, completedAt, colorIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Goal &&
          other.id == this.id &&
          other.parentId == this.parentId &&
          other.name == this.name &&
          other.aim == this.aim &&
          other.timeframe == this.timeframe &&
          other.deadline == this.deadline &&
          other.weight == this.weight &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt &&
          other.colorIndex == this.colorIndex);
}

class GoalsCompanion extends UpdateCompanion<Goal> {
  final Value<String> id;
  final Value<String?> parentId;
  final Value<String> name;
  final Value<String?> aim;
  final Value<String> timeframe;
  final Value<int> deadline;
  final Value<int> weight;
  final Value<String> status;
  final Value<int> createdAt;
  final Value<int?> completedAt;
  final Value<int> colorIndex;
  final Value<int> rowid;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    this.name = const Value.absent(),
    this.aim = const Value.absent(),
    this.timeframe = const Value.absent(),
    this.deadline = const Value.absent(),
    this.weight = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.colorIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalsCompanion.insert({
    required String id,
    this.parentId = const Value.absent(),
    required String name,
    this.aim = const Value.absent(),
    required String timeframe,
    required int deadline,
    this.weight = const Value.absent(),
    this.status = const Value.absent(),
    required int createdAt,
    this.completedAt = const Value.absent(),
    this.colorIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        timeframe = Value(timeframe),
        deadline = Value(deadline),
        createdAt = Value(createdAt);
  static Insertable<Goal> custom({
    Expression<String>? id,
    Expression<String>? parentId,
    Expression<String>? name,
    Expression<String>? aim,
    Expression<String>? timeframe,
    Expression<int>? deadline,
    Expression<int>? weight,
    Expression<String>? status,
    Expression<int>? createdAt,
    Expression<int>? completedAt,
    Expression<int>? colorIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parentId != null) 'parent_id': parentId,
      if (name != null) 'name': name,
      if (aim != null) 'aim': aim,
      if (timeframe != null) 'timeframe': timeframe,
      if (deadline != null) 'deadline': deadline,
      if (weight != null) 'weight': weight,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (colorIndex != null) 'color_index': colorIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalsCompanion copyWith(
      {Value<String>? id,
      Value<String?>? parentId,
      Value<String>? name,
      Value<String?>? aim,
      Value<String>? timeframe,
      Value<int>? deadline,
      Value<int>? weight,
      Value<String>? status,
      Value<int>? createdAt,
      Value<int?>? completedAt,
      Value<int>? colorIndex,
      Value<int>? rowid}) {
    return GoalsCompanion(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      aim: aim ?? this.aim,
      timeframe: timeframe ?? this.timeframe,
      deadline: deadline ?? this.deadline,
      weight: weight ?? this.weight,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      colorIndex: colorIndex ?? this.colorIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (aim.present) {
      map['aim'] = Variable<String>(aim.value);
    }
    if (timeframe.present) {
      map['timeframe'] = Variable<String>(timeframe.value);
    }
    if (deadline.present) {
      map['deadline'] = Variable<int>(deadline.value);
    }
    if (weight.present) {
      map['weight'] = Variable<int>(weight.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (colorIndex.present) {
      map['color_index'] = Variable<int>(colorIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name, ')
          ..write('aim: $aim, ')
          ..write('timeframe: $timeframe, ')
          ..write('deadline: $deadline, ')
          ..write('weight: $weight, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('colorIndex: $colorIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalDependenciesTable extends GoalDependencies
    with TableInfo<$GoalDependenciesTable, GoalDependency> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalDependenciesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<String> goalId = GeneratedColumn<String>(
      'goal_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES goals (id)'));
  static const VerificationMeta _dependsOnIdMeta =
      const VerificationMeta('dependsOnId');
  @override
  late final GeneratedColumn<String> dependsOnId = GeneratedColumn<String>(
      'depends_on_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES goals (id)'));
  @override
  List<GeneratedColumn> get $columns => [goalId, dependsOnId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goal_dependencies';
  @override
  VerificationContext validateIntegrity(Insertable<GoalDependency> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('goal_id')) {
      context.handle(_goalIdMeta,
          goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta));
    } else if (isInserting) {
      context.missing(_goalIdMeta);
    }
    if (data.containsKey('depends_on_id')) {
      context.handle(
          _dependsOnIdMeta,
          dependsOnId.isAcceptableOrUnknown(
              data['depends_on_id']!, _dependsOnIdMeta));
    } else if (isInserting) {
      context.missing(_dependsOnIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {goalId, dependsOnId};
  @override
  GoalDependency map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GoalDependency(
      goalId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}goal_id'])!,
      dependsOnId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}depends_on_id'])!,
    );
  }

  @override
  $GoalDependenciesTable createAlias(String alias) {
    return $GoalDependenciesTable(attachedDatabase, alias);
  }
}

class GoalDependency extends DataClass implements Insertable<GoalDependency> {
  final String goalId;
  final String dependsOnId;
  const GoalDependency({required this.goalId, required this.dependsOnId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['goal_id'] = Variable<String>(goalId);
    map['depends_on_id'] = Variable<String>(dependsOnId);
    return map;
  }

  GoalDependenciesCompanion toCompanion(bool nullToAbsent) {
    return GoalDependenciesCompanion(
      goalId: Value(goalId),
      dependsOnId: Value(dependsOnId),
    );
  }

  factory GoalDependency.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GoalDependency(
      goalId: serializer.fromJson<String>(json['goalId']),
      dependsOnId: serializer.fromJson<String>(json['dependsOnId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'goalId': serializer.toJson<String>(goalId),
      'dependsOnId': serializer.toJson<String>(dependsOnId),
    };
  }

  GoalDependency copyWith({String? goalId, String? dependsOnId}) =>
      GoalDependency(
        goalId: goalId ?? this.goalId,
        dependsOnId: dependsOnId ?? this.dependsOnId,
      );
  GoalDependency copyWithCompanion(GoalDependenciesCompanion data) {
    return GoalDependency(
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      dependsOnId:
          data.dependsOnId.present ? data.dependsOnId.value : this.dependsOnId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GoalDependency(')
          ..write('goalId: $goalId, ')
          ..write('dependsOnId: $dependsOnId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(goalId, dependsOnId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoalDependency &&
          other.goalId == this.goalId &&
          other.dependsOnId == this.dependsOnId);
}

class GoalDependenciesCompanion extends UpdateCompanion<GoalDependency> {
  final Value<String> goalId;
  final Value<String> dependsOnId;
  final Value<int> rowid;
  const GoalDependenciesCompanion({
    this.goalId = const Value.absent(),
    this.dependsOnId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalDependenciesCompanion.insert({
    required String goalId,
    required String dependsOnId,
    this.rowid = const Value.absent(),
  })  : goalId = Value(goalId),
        dependsOnId = Value(dependsOnId);
  static Insertable<GoalDependency> custom({
    Expression<String>? goalId,
    Expression<String>? dependsOnId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (goalId != null) 'goal_id': goalId,
      if (dependsOnId != null) 'depends_on_id': dependsOnId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalDependenciesCompanion copyWith(
      {Value<String>? goalId, Value<String>? dependsOnId, Value<int>? rowid}) {
    return GoalDependenciesCompanion(
      goalId: goalId ?? this.goalId,
      dependsOnId: dependsOnId ?? this.dependsOnId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (goalId.present) {
      map['goal_id'] = Variable<String>(goalId.value);
    }
    if (dependsOnId.present) {
      map['depends_on_id'] = Variable<String>(dependsOnId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalDependenciesCompanion(')
          ..write('goalId: $goalId, ')
          ..write('dependsOnId: $dependsOnId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<String> goalId = GeneratedColumn<String>(
      'goal_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES goals (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _scheduleMeta =
      const VerificationMeta('schedule');
  @override
  late final GeneratedColumn<String> schedule = GeneratedColumn<String>(
      'schedule', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _scheduleOnMeta =
      const VerificationMeta('scheduleOn');
  @override
  late final GeneratedColumn<String> scheduleOn = GeneratedColumn<String>(
      'schedule_on', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _reminderTimeMeta =
      const VerificationMeta('reminderTime');
  @override
  late final GeneratedColumn<String> reminderTime = GeneratedColumn<String>(
      'reminder_time', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<int> isActive = GeneratedColumn<int>(
      'is_active', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        goalId,
        name,
        schedule,
        scheduleOn,
        reminderTime,
        isActive,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(Insertable<Task> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('goal_id')) {
      context.handle(_goalIdMeta,
          goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta));
    } else if (isInserting) {
      context.missing(_goalIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('schedule')) {
      context.handle(_scheduleMeta,
          schedule.isAcceptableOrUnknown(data['schedule']!, _scheduleMeta));
    } else if (isInserting) {
      context.missing(_scheduleMeta);
    }
    if (data.containsKey('schedule_on')) {
      context.handle(
          _scheduleOnMeta,
          scheduleOn.isAcceptableOrUnknown(
              data['schedule_on']!, _scheduleOnMeta));
    }
    if (data.containsKey('reminder_time')) {
      context.handle(
          _reminderTimeMeta,
          reminderTime.isAcceptableOrUnknown(
              data['reminder_time']!, _reminderTimeMeta));
    } else if (isInserting) {
      context.missing(_reminderTimeMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      goalId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}goal_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      schedule: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}schedule'])!,
      scheduleOn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}schedule_on']),
      reminderTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reminder_time'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class Task extends DataClass implements Insertable<Task> {
  final String id;
  final String goalId;
  final String name;
  final String schedule;
  final String? scheduleOn;
  final String reminderTime;
  final int isActive;
  final int createdAt;
  const Task(
      {required this.id,
      required this.goalId,
      required this.name,
      required this.schedule,
      this.scheduleOn,
      required this.reminderTime,
      required this.isActive,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['goal_id'] = Variable<String>(goalId);
    map['name'] = Variable<String>(name);
    map['schedule'] = Variable<String>(schedule);
    if (!nullToAbsent || scheduleOn != null) {
      map['schedule_on'] = Variable<String>(scheduleOn);
    }
    map['reminder_time'] = Variable<String>(reminderTime);
    map['is_active'] = Variable<int>(isActive);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      goalId: Value(goalId),
      name: Value(name),
      schedule: Value(schedule),
      scheduleOn: scheduleOn == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduleOn),
      reminderTime: Value(reminderTime),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
    );
  }

  factory Task.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<String>(json['id']),
      goalId: serializer.fromJson<String>(json['goalId']),
      name: serializer.fromJson<String>(json['name']),
      schedule: serializer.fromJson<String>(json['schedule']),
      scheduleOn: serializer.fromJson<String?>(json['scheduleOn']),
      reminderTime: serializer.fromJson<String>(json['reminderTime']),
      isActive: serializer.fromJson<int>(json['isActive']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'goalId': serializer.toJson<String>(goalId),
      'name': serializer.toJson<String>(name),
      'schedule': serializer.toJson<String>(schedule),
      'scheduleOn': serializer.toJson<String?>(scheduleOn),
      'reminderTime': serializer.toJson<String>(reminderTime),
      'isActive': serializer.toJson<int>(isActive),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  Task copyWith(
          {String? id,
          String? goalId,
          String? name,
          String? schedule,
          Value<String?> scheduleOn = const Value.absent(),
          String? reminderTime,
          int? isActive,
          int? createdAt}) =>
      Task(
        id: id ?? this.id,
        goalId: goalId ?? this.goalId,
        name: name ?? this.name,
        schedule: schedule ?? this.schedule,
        scheduleOn: scheduleOn.present ? scheduleOn.value : this.scheduleOn,
        reminderTime: reminderTime ?? this.reminderTime,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
      );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      name: data.name.present ? data.name.value : this.name,
      schedule: data.schedule.present ? data.schedule.value : this.schedule,
      scheduleOn:
          data.scheduleOn.present ? data.scheduleOn.value : this.scheduleOn,
      reminderTime: data.reminderTime.present
          ? data.reminderTime.value
          : this.reminderTime,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('name: $name, ')
          ..write('schedule: $schedule, ')
          ..write('scheduleOn: $scheduleOn, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, goalId, name, schedule, scheduleOn,
      reminderTime, isActive, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.goalId == this.goalId &&
          other.name == this.name &&
          other.schedule == this.schedule &&
          other.scheduleOn == this.scheduleOn &&
          other.reminderTime == this.reminderTime &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<String> id;
  final Value<String> goalId;
  final Value<String> name;
  final Value<String> schedule;
  final Value<String?> scheduleOn;
  final Value<String> reminderTime;
  final Value<int> isActive;
  final Value<int> createdAt;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.goalId = const Value.absent(),
    this.name = const Value.absent(),
    this.schedule = const Value.absent(),
    this.scheduleOn = const Value.absent(),
    this.reminderTime = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required String goalId,
    required String name,
    required String schedule,
    this.scheduleOn = const Value.absent(),
    required String reminderTime,
    this.isActive = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        goalId = Value(goalId),
        name = Value(name),
        schedule = Value(schedule),
        reminderTime = Value(reminderTime),
        createdAt = Value(createdAt);
  static Insertable<Task> custom({
    Expression<String>? id,
    Expression<String>? goalId,
    Expression<String>? name,
    Expression<String>? schedule,
    Expression<String>? scheduleOn,
    Expression<String>? reminderTime,
    Expression<int>? isActive,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (goalId != null) 'goal_id': goalId,
      if (name != null) 'name': name,
      if (schedule != null) 'schedule': schedule,
      if (scheduleOn != null) 'schedule_on': scheduleOn,
      if (reminderTime != null) 'reminder_time': reminderTime,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith(
      {Value<String>? id,
      Value<String>? goalId,
      Value<String>? name,
      Value<String>? schedule,
      Value<String?>? scheduleOn,
      Value<String>? reminderTime,
      Value<int>? isActive,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return TasksCompanion(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      name: name ?? this.name,
      schedule: schedule ?? this.schedule,
      scheduleOn: scheduleOn ?? this.scheduleOn,
      reminderTime: reminderTime ?? this.reminderTime,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<String>(goalId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (schedule.present) {
      map['schedule'] = Variable<String>(schedule.value);
    }
    if (scheduleOn.present) {
      map['schedule_on'] = Variable<String>(scheduleOn.value);
    }
    if (reminderTime.present) {
      map['reminder_time'] = Variable<String>(reminderTime.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<int>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('name: $name, ')
          ..write('schedule: $schedule, ')
          ..write('scheduleOn: $scheduleOn, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskCompletionsTable extends TaskCompletions
    with TableInfo<$TaskCompletionsTable, TaskCompletion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskCompletionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
      'task_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES tasks (id)'));
  static const VerificationMeta _scheduledDateMeta =
      const VerificationMeta('scheduledDate');
  @override
  late final GeneratedColumn<int> scheduledDate = GeneratedColumn<int>(
      'scheduled_date', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _completedDateMeta =
      const VerificationMeta('completedDate');
  @override
  late final GeneratedColumn<int> completedDate = GeneratedColumn<int>(
      'completed_date', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isLateMeta = const VerificationMeta('isLate');
  @override
  late final GeneratedColumn<int> isLate = GeneratedColumn<int>(
      'is_late', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, taskId, scheduledDate, completedDate, isLate];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_completions';
  @override
  VerificationContext validateIntegrity(Insertable<TaskCompletion> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('task_id')) {
      context.handle(_taskIdMeta,
          taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta));
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('scheduled_date')) {
      context.handle(
          _scheduledDateMeta,
          scheduledDate.isAcceptableOrUnknown(
              data['scheduled_date']!, _scheduledDateMeta));
    } else if (isInserting) {
      context.missing(_scheduledDateMeta);
    }
    if (data.containsKey('completed_date')) {
      context.handle(
          _completedDateMeta,
          completedDate.isAcceptableOrUnknown(
              data['completed_date']!, _completedDateMeta));
    }
    if (data.containsKey('is_late')) {
      context.handle(_isLateMeta,
          isLate.isAcceptableOrUnknown(data['is_late']!, _isLateMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {taskId, scheduledDate},
      ];
  @override
  TaskCompletion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskCompletion(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      taskId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}task_id'])!,
      scheduledDate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}scheduled_date'])!,
      completedDate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}completed_date']),
      isLate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}is_late'])!,
    );
  }

  @override
  $TaskCompletionsTable createAlias(String alias) {
    return $TaskCompletionsTable(attachedDatabase, alias);
  }
}

class TaskCompletion extends DataClass implements Insertable<TaskCompletion> {
  final int id;
  final String taskId;
  final int scheduledDate;
  final int? completedDate;
  final int isLate;
  const TaskCompletion(
      {required this.id,
      required this.taskId,
      required this.scheduledDate,
      this.completedDate,
      required this.isLate});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['task_id'] = Variable<String>(taskId);
    map['scheduled_date'] = Variable<int>(scheduledDate);
    if (!nullToAbsent || completedDate != null) {
      map['completed_date'] = Variable<int>(completedDate);
    }
    map['is_late'] = Variable<int>(isLate);
    return map;
  }

  TaskCompletionsCompanion toCompanion(bool nullToAbsent) {
    return TaskCompletionsCompanion(
      id: Value(id),
      taskId: Value(taskId),
      scheduledDate: Value(scheduledDate),
      completedDate: completedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(completedDate),
      isLate: Value(isLate),
    );
  }

  factory TaskCompletion.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskCompletion(
      id: serializer.fromJson<int>(json['id']),
      taskId: serializer.fromJson<String>(json['taskId']),
      scheduledDate: serializer.fromJson<int>(json['scheduledDate']),
      completedDate: serializer.fromJson<int?>(json['completedDate']),
      isLate: serializer.fromJson<int>(json['isLate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'taskId': serializer.toJson<String>(taskId),
      'scheduledDate': serializer.toJson<int>(scheduledDate),
      'completedDate': serializer.toJson<int?>(completedDate),
      'isLate': serializer.toJson<int>(isLate),
    };
  }

  TaskCompletion copyWith(
          {int? id,
          String? taskId,
          int? scheduledDate,
          Value<int?> completedDate = const Value.absent(),
          int? isLate}) =>
      TaskCompletion(
        id: id ?? this.id,
        taskId: taskId ?? this.taskId,
        scheduledDate: scheduledDate ?? this.scheduledDate,
        completedDate:
            completedDate.present ? completedDate.value : this.completedDate,
        isLate: isLate ?? this.isLate,
      );
  TaskCompletion copyWithCompanion(TaskCompletionsCompanion data) {
    return TaskCompletion(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      scheduledDate: data.scheduledDate.present
          ? data.scheduledDate.value
          : this.scheduledDate,
      completedDate: data.completedDate.present
          ? data.completedDate.value
          : this.completedDate,
      isLate: data.isLate.present ? data.isLate.value : this.isLate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskCompletion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('completedDate: $completedDate, ')
          ..write('isLate: $isLate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, taskId, scheduledDate, completedDate, isLate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskCompletion &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.scheduledDate == this.scheduledDate &&
          other.completedDate == this.completedDate &&
          other.isLate == this.isLate);
}

class TaskCompletionsCompanion extends UpdateCompanion<TaskCompletion> {
  final Value<int> id;
  final Value<String> taskId;
  final Value<int> scheduledDate;
  final Value<int?> completedDate;
  final Value<int> isLate;
  const TaskCompletionsCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.scheduledDate = const Value.absent(),
    this.completedDate = const Value.absent(),
    this.isLate = const Value.absent(),
  });
  TaskCompletionsCompanion.insert({
    this.id = const Value.absent(),
    required String taskId,
    required int scheduledDate,
    this.completedDate = const Value.absent(),
    this.isLate = const Value.absent(),
  })  : taskId = Value(taskId),
        scheduledDate = Value(scheduledDate);
  static Insertable<TaskCompletion> custom({
    Expression<int>? id,
    Expression<String>? taskId,
    Expression<int>? scheduledDate,
    Expression<int>? completedDate,
    Expression<int>? isLate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (scheduledDate != null) 'scheduled_date': scheduledDate,
      if (completedDate != null) 'completed_date': completedDate,
      if (isLate != null) 'is_late': isLate,
    });
  }

  TaskCompletionsCompanion copyWith(
      {Value<int>? id,
      Value<String>? taskId,
      Value<int>? scheduledDate,
      Value<int?>? completedDate,
      Value<int>? isLate}) {
    return TaskCompletionsCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      completedDate: completedDate ?? this.completedDate,
      isLate: isLate ?? this.isLate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (scheduledDate.present) {
      map['scheduled_date'] = Variable<int>(scheduledDate.value);
    }
    if (completedDate.present) {
      map['completed_date'] = Variable<int>(completedDate.value);
    }
    if (isLate.present) {
      map['is_late'] = Variable<int>(isLate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskCompletionsCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('completedDate: $completedDate, ')
          ..write('isLate: $isLate')
          ..write(')'))
        .toString();
  }
}

class $UserProfilesTable extends UserProfiles
    with TableInfo<$UserProfilesTable, UserProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('You'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _bubbleSideMeta =
      const VerificationMeta('bubbleSide');
  @override
  late final GeneratedColumn<String> bubbleSide = GeneratedColumn<String>(
      'bubble_side', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('right'));
  static const VerificationMeta _bubbleYFracMeta =
      const VerificationMeta('bubbleYFrac');
  @override
  late final GeneratedColumn<double> bubbleYFrac = GeneratedColumn<double>(
      'bubble_y_frac', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.72));
  static const VerificationMeta _reducedMotionMeta =
      const VerificationMeta('reducedMotion');
  @override
  late final GeneratedColumn<int> reducedMotion = GeneratedColumn<int>(
      'reduced_motion', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _hapticsEnabledMeta =
      const VerificationMeta('hapticsEnabled');
  @override
  late final GeneratedColumn<int> hapticsEnabled = GeneratedColumn<int>(
      'haptics_enabled', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _notifsEnabledMeta =
      const VerificationMeta('notifsEnabled');
  @override
  late final GeneratedColumn<int> notifsEnabled = GeneratedColumn<int>(
      'notifs_enabled', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _onboardingDoneMeta =
      const VerificationMeta('onboardingDone');
  @override
  late final GeneratedColumn<int> onboardingDone = GeneratedColumn<int>(
      'onboarding_done', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        displayName,
        createdAt,
        bubbleSide,
        bubbleYFrac,
        reducedMotion,
        hapticsEnabled,
        notifsEnabled,
        onboardingDone
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_profiles';
  @override
  VerificationContext validateIntegrity(Insertable<UserProfile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('bubble_side')) {
      context.handle(
          _bubbleSideMeta,
          bubbleSide.isAcceptableOrUnknown(
              data['bubble_side']!, _bubbleSideMeta));
    }
    if (data.containsKey('bubble_y_frac')) {
      context.handle(
          _bubbleYFracMeta,
          bubbleYFrac.isAcceptableOrUnknown(
              data['bubble_y_frac']!, _bubbleYFracMeta));
    }
    if (data.containsKey('reduced_motion')) {
      context.handle(
          _reducedMotionMeta,
          reducedMotion.isAcceptableOrUnknown(
              data['reduced_motion']!, _reducedMotionMeta));
    }
    if (data.containsKey('haptics_enabled')) {
      context.handle(
          _hapticsEnabledMeta,
          hapticsEnabled.isAcceptableOrUnknown(
              data['haptics_enabled']!, _hapticsEnabledMeta));
    }
    if (data.containsKey('notifs_enabled')) {
      context.handle(
          _notifsEnabledMeta,
          notifsEnabled.isAcceptableOrUnknown(
              data['notifs_enabled']!, _notifsEnabledMeta));
    }
    if (data.containsKey('onboarding_done')) {
      context.handle(
          _onboardingDoneMeta,
          onboardingDone.isAcceptableOrUnknown(
              data['onboarding_done']!, _onboardingDoneMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfile(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      bubbleSide: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bubble_side'])!,
      bubbleYFrac: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}bubble_y_frac'])!,
      reducedMotion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reduced_motion'])!,
      hapticsEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}haptics_enabled'])!,
      notifsEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}notifs_enabled'])!,
      onboardingDone: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}onboarding_done'])!,
    );
  }

  @override
  $UserProfilesTable createAlias(String alias) {
    return $UserProfilesTable(attachedDatabase, alias);
  }
}

class UserProfile extends DataClass implements Insertable<UserProfile> {
  final int id;
  final String displayName;
  final int createdAt;
  final String bubbleSide;
  final double bubbleYFrac;
  final int reducedMotion;
  final int hapticsEnabled;
  final int notifsEnabled;
  final int onboardingDone;
  const UserProfile(
      {required this.id,
      required this.displayName,
      required this.createdAt,
      required this.bubbleSide,
      required this.bubbleYFrac,
      required this.reducedMotion,
      required this.hapticsEnabled,
      required this.notifsEnabled,
      required this.onboardingDone});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['display_name'] = Variable<String>(displayName);
    map['created_at'] = Variable<int>(createdAt);
    map['bubble_side'] = Variable<String>(bubbleSide);
    map['bubble_y_frac'] = Variable<double>(bubbleYFrac);
    map['reduced_motion'] = Variable<int>(reducedMotion);
    map['haptics_enabled'] = Variable<int>(hapticsEnabled);
    map['notifs_enabled'] = Variable<int>(notifsEnabled);
    map['onboarding_done'] = Variable<int>(onboardingDone);
    return map;
  }

  UserProfilesCompanion toCompanion(bool nullToAbsent) {
    return UserProfilesCompanion(
      id: Value(id),
      displayName: Value(displayName),
      createdAt: Value(createdAt),
      bubbleSide: Value(bubbleSide),
      bubbleYFrac: Value(bubbleYFrac),
      reducedMotion: Value(reducedMotion),
      hapticsEnabled: Value(hapticsEnabled),
      notifsEnabled: Value(notifsEnabled),
      onboardingDone: Value(onboardingDone),
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfile(
      id: serializer.fromJson<int>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      bubbleSide: serializer.fromJson<String>(json['bubbleSide']),
      bubbleYFrac: serializer.fromJson<double>(json['bubbleYFrac']),
      reducedMotion: serializer.fromJson<int>(json['reducedMotion']),
      hapticsEnabled: serializer.fromJson<int>(json['hapticsEnabled']),
      notifsEnabled: serializer.fromJson<int>(json['notifsEnabled']),
      onboardingDone: serializer.fromJson<int>(json['onboardingDone']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'displayName': serializer.toJson<String>(displayName),
      'createdAt': serializer.toJson<int>(createdAt),
      'bubbleSide': serializer.toJson<String>(bubbleSide),
      'bubbleYFrac': serializer.toJson<double>(bubbleYFrac),
      'reducedMotion': serializer.toJson<int>(reducedMotion),
      'hapticsEnabled': serializer.toJson<int>(hapticsEnabled),
      'notifsEnabled': serializer.toJson<int>(notifsEnabled),
      'onboardingDone': serializer.toJson<int>(onboardingDone),
    };
  }

  UserProfile copyWith(
          {int? id,
          String? displayName,
          int? createdAt,
          String? bubbleSide,
          double? bubbleYFrac,
          int? reducedMotion,
          int? hapticsEnabled,
          int? notifsEnabled,
          int? onboardingDone}) =>
      UserProfile(
        id: id ?? this.id,
        displayName: displayName ?? this.displayName,
        createdAt: createdAt ?? this.createdAt,
        bubbleSide: bubbleSide ?? this.bubbleSide,
        bubbleYFrac: bubbleYFrac ?? this.bubbleYFrac,
        reducedMotion: reducedMotion ?? this.reducedMotion,
        hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
        notifsEnabled: notifsEnabled ?? this.notifsEnabled,
        onboardingDone: onboardingDone ?? this.onboardingDone,
      );
  UserProfile copyWithCompanion(UserProfilesCompanion data) {
    return UserProfile(
      id: data.id.present ? data.id.value : this.id,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      bubbleSide:
          data.bubbleSide.present ? data.bubbleSide.value : this.bubbleSide,
      bubbleYFrac:
          data.bubbleYFrac.present ? data.bubbleYFrac.value : this.bubbleYFrac,
      reducedMotion: data.reducedMotion.present
          ? data.reducedMotion.value
          : this.reducedMotion,
      hapticsEnabled: data.hapticsEnabled.present
          ? data.hapticsEnabled.value
          : this.hapticsEnabled,
      notifsEnabled: data.notifsEnabled.present
          ? data.notifsEnabled.value
          : this.notifsEnabled,
      onboardingDone: data.onboardingDone.present
          ? data.onboardingDone.value
          : this.onboardingDone,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProfile(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('createdAt: $createdAt, ')
          ..write('bubbleSide: $bubbleSide, ')
          ..write('bubbleYFrac: $bubbleYFrac, ')
          ..write('reducedMotion: $reducedMotion, ')
          ..write('hapticsEnabled: $hapticsEnabled, ')
          ..write('notifsEnabled: $notifsEnabled, ')
          ..write('onboardingDone: $onboardingDone')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      displayName,
      createdAt,
      bubbleSide,
      bubbleYFrac,
      reducedMotion,
      hapticsEnabled,
      notifsEnabled,
      onboardingDone);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfile &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.createdAt == this.createdAt &&
          other.bubbleSide == this.bubbleSide &&
          other.bubbleYFrac == this.bubbleYFrac &&
          other.reducedMotion == this.reducedMotion &&
          other.hapticsEnabled == this.hapticsEnabled &&
          other.notifsEnabled == this.notifsEnabled &&
          other.onboardingDone == this.onboardingDone);
}

class UserProfilesCompanion extends UpdateCompanion<UserProfile> {
  final Value<int> id;
  final Value<String> displayName;
  final Value<int> createdAt;
  final Value<String> bubbleSide;
  final Value<double> bubbleYFrac;
  final Value<int> reducedMotion;
  final Value<int> hapticsEnabled;
  final Value<int> notifsEnabled;
  final Value<int> onboardingDone;
  const UserProfilesCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.bubbleSide = const Value.absent(),
    this.bubbleYFrac = const Value.absent(),
    this.reducedMotion = const Value.absent(),
    this.hapticsEnabled = const Value.absent(),
    this.notifsEnabled = const Value.absent(),
    this.onboardingDone = const Value.absent(),
  });
  UserProfilesCompanion.insert({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    required int createdAt,
    this.bubbleSide = const Value.absent(),
    this.bubbleYFrac = const Value.absent(),
    this.reducedMotion = const Value.absent(),
    this.hapticsEnabled = const Value.absent(),
    this.notifsEnabled = const Value.absent(),
    this.onboardingDone = const Value.absent(),
  }) : createdAt = Value(createdAt);
  static Insertable<UserProfile> custom({
    Expression<int>? id,
    Expression<String>? displayName,
    Expression<int>? createdAt,
    Expression<String>? bubbleSide,
    Expression<double>? bubbleYFrac,
    Expression<int>? reducedMotion,
    Expression<int>? hapticsEnabled,
    Expression<int>? notifsEnabled,
    Expression<int>? onboardingDone,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (createdAt != null) 'created_at': createdAt,
      if (bubbleSide != null) 'bubble_side': bubbleSide,
      if (bubbleYFrac != null) 'bubble_y_frac': bubbleYFrac,
      if (reducedMotion != null) 'reduced_motion': reducedMotion,
      if (hapticsEnabled != null) 'haptics_enabled': hapticsEnabled,
      if (notifsEnabled != null) 'notifs_enabled': notifsEnabled,
      if (onboardingDone != null) 'onboarding_done': onboardingDone,
    });
  }

  UserProfilesCompanion copyWith(
      {Value<int>? id,
      Value<String>? displayName,
      Value<int>? createdAt,
      Value<String>? bubbleSide,
      Value<double>? bubbleYFrac,
      Value<int>? reducedMotion,
      Value<int>? hapticsEnabled,
      Value<int>? notifsEnabled,
      Value<int>? onboardingDone}) {
    return UserProfilesCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      bubbleSide: bubbleSide ?? this.bubbleSide,
      bubbleYFrac: bubbleYFrac ?? this.bubbleYFrac,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      notifsEnabled: notifsEnabled ?? this.notifsEnabled,
      onboardingDone: onboardingDone ?? this.onboardingDone,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (bubbleSide.present) {
      map['bubble_side'] = Variable<String>(bubbleSide.value);
    }
    if (bubbleYFrac.present) {
      map['bubble_y_frac'] = Variable<double>(bubbleYFrac.value);
    }
    if (reducedMotion.present) {
      map['reduced_motion'] = Variable<int>(reducedMotion.value);
    }
    if (hapticsEnabled.present) {
      map['haptics_enabled'] = Variable<int>(hapticsEnabled.value);
    }
    if (notifsEnabled.present) {
      map['notifs_enabled'] = Variable<int>(notifsEnabled.value);
    }
    if (onboardingDone.present) {
      map['onboarding_done'] = Variable<int>(onboardingDone.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProfilesCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('createdAt: $createdAt, ')
          ..write('bubbleSide: $bubbleSide, ')
          ..write('bubbleYFrac: $bubbleYFrac, ')
          ..write('reducedMotion: $reducedMotion, ')
          ..write('hapticsEnabled: $hapticsEnabled, ')
          ..write('notifsEnabled: $notifsEnabled, ')
          ..write('onboardingDone: $onboardingDone')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final $GoalDependenciesTable goalDependencies =
      $GoalDependenciesTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $TaskCompletionsTable taskCompletions =
      $TaskCompletionsTable(this);
  late final $UserProfilesTable userProfiles = $UserProfilesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [goals, goalDependencies, tasks, taskCompletions, userProfiles];
}

typedef $$GoalsTableCreateCompanionBuilder = GoalsCompanion Function({
  required String id,
  Value<String?> parentId,
  required String name,
  Value<String?> aim,
  required String timeframe,
  required int deadline,
  Value<int> weight,
  Value<String> status,
  required int createdAt,
  Value<int?> completedAt,
  Value<int> colorIndex,
  Value<int> rowid,
});
typedef $$GoalsTableUpdateCompanionBuilder = GoalsCompanion Function({
  Value<String> id,
  Value<String?> parentId,
  Value<String> name,
  Value<String?> aim,
  Value<String> timeframe,
  Value<int> deadline,
  Value<int> weight,
  Value<String> status,
  Value<int> createdAt,
  Value<int?> completedAt,
  Value<int> colorIndex,
  Value<int> rowid,
});

final class $$GoalsTableReferences
    extends BaseReferences<_$AppDatabase, $GoalsTable, Goal> {
  $$GoalsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GoalsTable _parentIdTable(_$AppDatabase db) => db.goals
      .createAlias($_aliasNameGenerator(db.goals.parentId, db.goals.id));

  $$GoalsTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<String>('parent_id');
    if ($_column == null) return null;
    final manager = $$GoalsTableTableManager($_db, $_db.goals)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$TasksTable, List<Task>> _tasksRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.tasks,
          aliasName: $_aliasNameGenerator(db.goals.id, db.tasks.goalId));

  $$TasksTableProcessedTableManager get tasksRefs {
    final manager = $$TasksTableTableManager($_db, $_db.tasks)
        .filter((f) => f.goalId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_tasksRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$GoalsTableFilterComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get aim => $composableBuilder(
      column: $table.aim, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get timeframe => $composableBuilder(
      column: $table.timeframe, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deadline => $composableBuilder(
      column: $table.deadline, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get colorIndex => $composableBuilder(
      column: $table.colorIndex, builder: (column) => ColumnFilters(column));

  $$GoalsTableFilterComposer get parentId {
    final $$GoalsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.parentId,
        referencedTable: $db.goals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GoalsTableFilterComposer(
              $db: $db,
              $table: $db.goals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> tasksRefs(
      Expression<bool> Function($$TasksTableFilterComposer f) f) {
    final $$TasksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.tasks,
        getReferencedColumn: (t) => t.goalId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TasksTableFilterComposer(
              $db: $db,
              $table: $db.tasks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$GoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get aim => $composableBuilder(
      column: $table.aim, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get timeframe => $composableBuilder(
      column: $table.timeframe, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deadline => $composableBuilder(
      column: $table.deadline, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get colorIndex => $composableBuilder(
      column: $table.colorIndex, builder: (column) => ColumnOrderings(column));

  $$GoalsTableOrderingComposer get parentId {
    final $$GoalsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.parentId,
        referencedTable: $db.goals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GoalsTableOrderingComposer(
              $db: $db,
              $table: $db.goals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get aim =>
      $composableBuilder(column: $table.aim, builder: (column) => column);

  GeneratedColumn<String> get timeframe =>
      $composableBuilder(column: $table.timeframe, builder: (column) => column);

  GeneratedColumn<int> get deadline =>
      $composableBuilder(column: $table.deadline, builder: (column) => column);

  GeneratedColumn<int> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<int> get colorIndex => $composableBuilder(
      column: $table.colorIndex, builder: (column) => column);

  $$GoalsTableAnnotationComposer get parentId {
    final $$GoalsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.parentId,
        referencedTable: $db.goals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GoalsTableAnnotationComposer(
              $db: $db,
              $table: $db.goals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> tasksRefs<T extends Object>(
      Expression<T> Function($$TasksTableAnnotationComposer a) f) {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.tasks,
        getReferencedColumn: (t) => t.goalId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TasksTableAnnotationComposer(
              $db: $db,
              $table: $db.tasks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$GoalsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GoalsTable,
    Goal,
    $$GoalsTableFilterComposer,
    $$GoalsTableOrderingComposer,
    $$GoalsTableAnnotationComposer,
    $$GoalsTableCreateCompanionBuilder,
    $$GoalsTableUpdateCompanionBuilder,
    (Goal, $$GoalsTableReferences),
    Goal,
    PrefetchHooks Function({bool parentId, bool tasksRefs})> {
  $$GoalsTableTableManager(_$AppDatabase db, $GoalsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> parentId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> aim = const Value.absent(),
            Value<String> timeframe = const Value.absent(),
            Value<int> deadline = const Value.absent(),
            Value<int> weight = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int?> completedAt = const Value.absent(),
            Value<int> colorIndex = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GoalsCompanion(
            id: id,
            parentId: parentId,
            name: name,
            aim: aim,
            timeframe: timeframe,
            deadline: deadline,
            weight: weight,
            status: status,
            createdAt: createdAt,
            completedAt: completedAt,
            colorIndex: colorIndex,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> parentId = const Value.absent(),
            required String name,
            Value<String?> aim = const Value.absent(),
            required String timeframe,
            required int deadline,
            Value<int> weight = const Value.absent(),
            Value<String> status = const Value.absent(),
            required int createdAt,
            Value<int?> completedAt = const Value.absent(),
            Value<int> colorIndex = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GoalsCompanion.insert(
            id: id,
            parentId: parentId,
            name: name,
            aim: aim,
            timeframe: timeframe,
            deadline: deadline,
            weight: weight,
            status: status,
            createdAt: createdAt,
            completedAt: completedAt,
            colorIndex: colorIndex,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$GoalsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({parentId = false, tasksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (tasksRefs) db.tasks],
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
                if (parentId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.parentId,
                    referencedTable: $$GoalsTableReferences._parentIdTable(db),
                    referencedColumn:
                        $$GoalsTableReferences._parentIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (tasksRefs)
                    await $_getPrefetchedData<Goal, $GoalsTable, Task>(
                        currentTable: table,
                        referencedTable:
                            $$GoalsTableReferences._tasksRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$GoalsTableReferences(db, table, p0).tasksRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.goalId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$GoalsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GoalsTable,
    Goal,
    $$GoalsTableFilterComposer,
    $$GoalsTableOrderingComposer,
    $$GoalsTableAnnotationComposer,
    $$GoalsTableCreateCompanionBuilder,
    $$GoalsTableUpdateCompanionBuilder,
    (Goal, $$GoalsTableReferences),
    Goal,
    PrefetchHooks Function({bool parentId, bool tasksRefs})>;
typedef $$GoalDependenciesTableCreateCompanionBuilder
    = GoalDependenciesCompanion Function({
  required String goalId,
  required String dependsOnId,
  Value<int> rowid,
});
typedef $$GoalDependenciesTableUpdateCompanionBuilder
    = GoalDependenciesCompanion Function({
  Value<String> goalId,
  Value<String> dependsOnId,
  Value<int> rowid,
});

final class $$GoalDependenciesTableReferences extends BaseReferences<
    _$AppDatabase, $GoalDependenciesTable, GoalDependency> {
  $$GoalDependenciesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $GoalsTable _goalIdTable(_$AppDatabase db) => db.goals.createAlias(
      $_aliasNameGenerator(db.goalDependencies.goalId, db.goals.id));

  $$GoalsTableProcessedTableManager get goalId {
    final $_column = $_itemColumn<String>('goal_id')!;

    final manager = $$GoalsTableTableManager($_db, $_db.goals)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_goalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $GoalsTable _dependsOnIdTable(_$AppDatabase db) =>
      db.goals.createAlias(
          $_aliasNameGenerator(db.goalDependencies.dependsOnId, db.goals.id));

  $$GoalsTableProcessedTableManager get dependsOnId {
    final $_column = $_itemColumn<String>('depends_on_id')!;

    final manager = $$GoalsTableTableManager($_db, $_db.goals)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dependsOnIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$GoalDependenciesTableFilterComposer
    extends Composer<_$AppDatabase, $GoalDependenciesTable> {
  $$GoalDependenciesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$GoalsTableFilterComposer get goalId {
    final $$GoalsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.goalId,
        referencedTable: $db.goals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GoalsTableFilterComposer(
              $db: $db,
              $table: $db.goals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$GoalsTableFilterComposer get dependsOnId {
    final $$GoalsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.dependsOnId,
        referencedTable: $db.goals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GoalsTableFilterComposer(
              $db: $db,
              $table: $db.goals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GoalDependenciesTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalDependenciesTable> {
  $$GoalDependenciesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$GoalsTableOrderingComposer get goalId {
    final $$GoalsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.goalId,
        referencedTable: $db.goals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GoalsTableOrderingComposer(
              $db: $db,
              $table: $db.goals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$GoalsTableOrderingComposer get dependsOnId {
    final $$GoalsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.dependsOnId,
        referencedTable: $db.goals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GoalsTableOrderingComposer(
              $db: $db,
              $table: $db.goals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GoalDependenciesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalDependenciesTable> {
  $$GoalDependenciesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$GoalsTableAnnotationComposer get goalId {
    final $$GoalsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.goalId,
        referencedTable: $db.goals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GoalsTableAnnotationComposer(
              $db: $db,
              $table: $db.goals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$GoalsTableAnnotationComposer get dependsOnId {
    final $$GoalsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.dependsOnId,
        referencedTable: $db.goals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GoalsTableAnnotationComposer(
              $db: $db,
              $table: $db.goals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GoalDependenciesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GoalDependenciesTable,
    GoalDependency,
    $$GoalDependenciesTableFilterComposer,
    $$GoalDependenciesTableOrderingComposer,
    $$GoalDependenciesTableAnnotationComposer,
    $$GoalDependenciesTableCreateCompanionBuilder,
    $$GoalDependenciesTableUpdateCompanionBuilder,
    (GoalDependency, $$GoalDependenciesTableReferences),
    GoalDependency,
    PrefetchHooks Function({bool goalId, bool dependsOnId})> {
  $$GoalDependenciesTableTableManager(
      _$AppDatabase db, $GoalDependenciesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalDependenciesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalDependenciesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalDependenciesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> goalId = const Value.absent(),
            Value<String> dependsOnId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GoalDependenciesCompanion(
            goalId: goalId,
            dependsOnId: dependsOnId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String goalId,
            required String dependsOnId,
            Value<int> rowid = const Value.absent(),
          }) =>
              GoalDependenciesCompanion.insert(
            goalId: goalId,
            dependsOnId: dependsOnId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$GoalDependenciesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({goalId = false, dependsOnId = false}) {
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
                if (goalId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.goalId,
                    referencedTable:
                        $$GoalDependenciesTableReferences._goalIdTable(db),
                    referencedColumn:
                        $$GoalDependenciesTableReferences._goalIdTable(db).id,
                  ) as T;
                }
                if (dependsOnId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.dependsOnId,
                    referencedTable:
                        $$GoalDependenciesTableReferences._dependsOnIdTable(db),
                    referencedColumn: $$GoalDependenciesTableReferences
                        ._dependsOnIdTable(db)
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

typedef $$GoalDependenciesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GoalDependenciesTable,
    GoalDependency,
    $$GoalDependenciesTableFilterComposer,
    $$GoalDependenciesTableOrderingComposer,
    $$GoalDependenciesTableAnnotationComposer,
    $$GoalDependenciesTableCreateCompanionBuilder,
    $$GoalDependenciesTableUpdateCompanionBuilder,
    (GoalDependency, $$GoalDependenciesTableReferences),
    GoalDependency,
    PrefetchHooks Function({bool goalId, bool dependsOnId})>;
typedef $$TasksTableCreateCompanionBuilder = TasksCompanion Function({
  required String id,
  required String goalId,
  required String name,
  required String schedule,
  Value<String?> scheduleOn,
  required String reminderTime,
  Value<int> isActive,
  required int createdAt,
  Value<int> rowid,
});
typedef $$TasksTableUpdateCompanionBuilder = TasksCompanion Function({
  Value<String> id,
  Value<String> goalId,
  Value<String> name,
  Value<String> schedule,
  Value<String?> scheduleOn,
  Value<String> reminderTime,
  Value<int> isActive,
  Value<int> createdAt,
  Value<int> rowid,
});

final class $$TasksTableReferences
    extends BaseReferences<_$AppDatabase, $TasksTable, Task> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GoalsTable _goalIdTable(_$AppDatabase db) =>
      db.goals.createAlias($_aliasNameGenerator(db.tasks.goalId, db.goals.id));

  $$GoalsTableProcessedTableManager get goalId {
    final $_column = $_itemColumn<String>('goal_id')!;

    final manager = $$GoalsTableTableManager($_db, $_db.goals)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_goalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$TaskCompletionsTable, List<TaskCompletion>>
      _taskCompletionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.taskCompletions,
              aliasName:
                  $_aliasNameGenerator(db.tasks.id, db.taskCompletions.taskId));

  $$TaskCompletionsTableProcessedTableManager get taskCompletionsRefs {
    final manager =
        $$TaskCompletionsTableTableManager($_db, $_db.taskCompletions)
            .filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_taskCompletionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get schedule => $composableBuilder(
      column: $table.schedule, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get scheduleOn => $composableBuilder(
      column: $table.scheduleOn, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reminderTime => $composableBuilder(
      column: $table.reminderTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$GoalsTableFilterComposer get goalId {
    final $$GoalsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.goalId,
        referencedTable: $db.goals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GoalsTableFilterComposer(
              $db: $db,
              $table: $db.goals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> taskCompletionsRefs(
      Expression<bool> Function($$TaskCompletionsTableFilterComposer f) f) {
    final $$TaskCompletionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.taskCompletions,
        getReferencedColumn: (t) => t.taskId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TaskCompletionsTableFilterComposer(
              $db: $db,
              $table: $db.taskCompletions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get schedule => $composableBuilder(
      column: $table.schedule, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get scheduleOn => $composableBuilder(
      column: $table.scheduleOn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reminderTime => $composableBuilder(
      column: $table.reminderTime,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$GoalsTableOrderingComposer get goalId {
    final $$GoalsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.goalId,
        referencedTable: $db.goals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GoalsTableOrderingComposer(
              $db: $db,
              $table: $db.goals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get schedule =>
      $composableBuilder(column: $table.schedule, builder: (column) => column);

  GeneratedColumn<String> get scheduleOn => $composableBuilder(
      column: $table.scheduleOn, builder: (column) => column);

  GeneratedColumn<String> get reminderTime => $composableBuilder(
      column: $table.reminderTime, builder: (column) => column);

  GeneratedColumn<int> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$GoalsTableAnnotationComposer get goalId {
    final $$GoalsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.goalId,
        referencedTable: $db.goals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GoalsTableAnnotationComposer(
              $db: $db,
              $table: $db.goals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> taskCompletionsRefs<T extends Object>(
      Expression<T> Function($$TaskCompletionsTableAnnotationComposer a) f) {
    final $$TaskCompletionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.taskCompletions,
        getReferencedColumn: (t) => t.taskId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TaskCompletionsTableAnnotationComposer(
              $db: $db,
              $table: $db.taskCompletions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TasksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TasksTable,
    Task,
    $$TasksTableFilterComposer,
    $$TasksTableOrderingComposer,
    $$TasksTableAnnotationComposer,
    $$TasksTableCreateCompanionBuilder,
    $$TasksTableUpdateCompanionBuilder,
    (Task, $$TasksTableReferences),
    Task,
    PrefetchHooks Function({bool goalId, bool taskCompletionsRefs})> {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> goalId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> schedule = const Value.absent(),
            Value<String?> scheduleOn = const Value.absent(),
            Value<String> reminderTime = const Value.absent(),
            Value<int> isActive = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TasksCompanion(
            id: id,
            goalId: goalId,
            name: name,
            schedule: schedule,
            scheduleOn: scheduleOn,
            reminderTime: reminderTime,
            isActive: isActive,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String goalId,
            required String name,
            required String schedule,
            Value<String?> scheduleOn = const Value.absent(),
            required String reminderTime,
            Value<int> isActive = const Value.absent(),
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              TasksCompanion.insert(
            id: id,
            goalId: goalId,
            name: name,
            schedule: schedule,
            scheduleOn: scheduleOn,
            reminderTime: reminderTime,
            isActive: isActive,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$TasksTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {goalId = false, taskCompletionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (taskCompletionsRefs) db.taskCompletions
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
                if (goalId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.goalId,
                    referencedTable: $$TasksTableReferences._goalIdTable(db),
                    referencedColumn:
                        $$TasksTableReferences._goalIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (taskCompletionsRefs)
                    await $_getPrefetchedData<Task, $TasksTable,
                            TaskCompletion>(
                        currentTable: table,
                        referencedTable: $$TasksTableReferences
                            ._taskCompletionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TasksTableReferences(db, table, p0)
                                .taskCompletionsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.taskId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TasksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TasksTable,
    Task,
    $$TasksTableFilterComposer,
    $$TasksTableOrderingComposer,
    $$TasksTableAnnotationComposer,
    $$TasksTableCreateCompanionBuilder,
    $$TasksTableUpdateCompanionBuilder,
    (Task, $$TasksTableReferences),
    Task,
    PrefetchHooks Function({bool goalId, bool taskCompletionsRefs})>;
typedef $$TaskCompletionsTableCreateCompanionBuilder = TaskCompletionsCompanion
    Function({
  Value<int> id,
  required String taskId,
  required int scheduledDate,
  Value<int?> completedDate,
  Value<int> isLate,
});
typedef $$TaskCompletionsTableUpdateCompanionBuilder = TaskCompletionsCompanion
    Function({
  Value<int> id,
  Value<String> taskId,
  Value<int> scheduledDate,
  Value<int?> completedDate,
  Value<int> isLate,
});

final class $$TaskCompletionsTableReferences extends BaseReferences<
    _$AppDatabase, $TaskCompletionsTable, TaskCompletion> {
  $$TaskCompletionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $TasksTable _taskIdTable(_$AppDatabase db) => db.tasks.createAlias(
      $_aliasNameGenerator(db.taskCompletions.taskId, db.tasks.id));

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TasksTableTableManager($_db, $_db.tasks)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TaskCompletionsTableFilterComposer
    extends Composer<_$AppDatabase, $TaskCompletionsTable> {
  $$TaskCompletionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get scheduledDate => $composableBuilder(
      column: $table.scheduledDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get completedDate => $composableBuilder(
      column: $table.completedDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get isLate => $composableBuilder(
      column: $table.isLate, builder: (column) => ColumnFilters(column));

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.taskId,
        referencedTable: $db.tasks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TasksTableFilterComposer(
              $db: $db,
              $table: $db.tasks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TaskCompletionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskCompletionsTable> {
  $$TaskCompletionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get scheduledDate => $composableBuilder(
      column: $table.scheduledDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get completedDate => $composableBuilder(
      column: $table.completedDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get isLate => $composableBuilder(
      column: $table.isLate, builder: (column) => ColumnOrderings(column));

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.taskId,
        referencedTable: $db.tasks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TasksTableOrderingComposer(
              $db: $db,
              $table: $db.tasks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TaskCompletionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskCompletionsTable> {
  $$TaskCompletionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get scheduledDate => $composableBuilder(
      column: $table.scheduledDate, builder: (column) => column);

  GeneratedColumn<int> get completedDate => $composableBuilder(
      column: $table.completedDate, builder: (column) => column);

  GeneratedColumn<int> get isLate =>
      $composableBuilder(column: $table.isLate, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.taskId,
        referencedTable: $db.tasks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TasksTableAnnotationComposer(
              $db: $db,
              $table: $db.tasks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TaskCompletionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TaskCompletionsTable,
    TaskCompletion,
    $$TaskCompletionsTableFilterComposer,
    $$TaskCompletionsTableOrderingComposer,
    $$TaskCompletionsTableAnnotationComposer,
    $$TaskCompletionsTableCreateCompanionBuilder,
    $$TaskCompletionsTableUpdateCompanionBuilder,
    (TaskCompletion, $$TaskCompletionsTableReferences),
    TaskCompletion,
    PrefetchHooks Function({bool taskId})> {
  $$TaskCompletionsTableTableManager(
      _$AppDatabase db, $TaskCompletionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskCompletionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskCompletionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskCompletionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> taskId = const Value.absent(),
            Value<int> scheduledDate = const Value.absent(),
            Value<int?> completedDate = const Value.absent(),
            Value<int> isLate = const Value.absent(),
          }) =>
              TaskCompletionsCompanion(
            id: id,
            taskId: taskId,
            scheduledDate: scheduledDate,
            completedDate: completedDate,
            isLate: isLate,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String taskId,
            required int scheduledDate,
            Value<int?> completedDate = const Value.absent(),
            Value<int> isLate = const Value.absent(),
          }) =>
              TaskCompletionsCompanion.insert(
            id: id,
            taskId: taskId,
            scheduledDate: scheduledDate,
            completedDate: completedDate,
            isLate: isLate,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TaskCompletionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
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
                if (taskId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.taskId,
                    referencedTable:
                        $$TaskCompletionsTableReferences._taskIdTable(db),
                    referencedColumn:
                        $$TaskCompletionsTableReferences._taskIdTable(db).id,
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

typedef $$TaskCompletionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TaskCompletionsTable,
    TaskCompletion,
    $$TaskCompletionsTableFilterComposer,
    $$TaskCompletionsTableOrderingComposer,
    $$TaskCompletionsTableAnnotationComposer,
    $$TaskCompletionsTableCreateCompanionBuilder,
    $$TaskCompletionsTableUpdateCompanionBuilder,
    (TaskCompletion, $$TaskCompletionsTableReferences),
    TaskCompletion,
    PrefetchHooks Function({bool taskId})>;
typedef $$UserProfilesTableCreateCompanionBuilder = UserProfilesCompanion
    Function({
  Value<int> id,
  Value<String> displayName,
  required int createdAt,
  Value<String> bubbleSide,
  Value<double> bubbleYFrac,
  Value<int> reducedMotion,
  Value<int> hapticsEnabled,
  Value<int> notifsEnabled,
  Value<int> onboardingDone,
});
typedef $$UserProfilesTableUpdateCompanionBuilder = UserProfilesCompanion
    Function({
  Value<int> id,
  Value<String> displayName,
  Value<int> createdAt,
  Value<String> bubbleSide,
  Value<double> bubbleYFrac,
  Value<int> reducedMotion,
  Value<int> hapticsEnabled,
  Value<int> notifsEnabled,
  Value<int> onboardingDone,
});

class $$UserProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bubbleSide => $composableBuilder(
      column: $table.bubbleSide, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get bubbleYFrac => $composableBuilder(
      column: $table.bubbleYFrac, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reducedMotion => $composableBuilder(
      column: $table.reducedMotion, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get hapticsEnabled => $composableBuilder(
      column: $table.hapticsEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get notifsEnabled => $composableBuilder(
      column: $table.notifsEnabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get onboardingDone => $composableBuilder(
      column: $table.onboardingDone,
      builder: (column) => ColumnFilters(column));
}

class $$UserProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bubbleSide => $composableBuilder(
      column: $table.bubbleSide, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get bubbleYFrac => $composableBuilder(
      column: $table.bubbleYFrac, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reducedMotion => $composableBuilder(
      column: $table.reducedMotion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get hapticsEnabled => $composableBuilder(
      column: $table.hapticsEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get notifsEnabled => $composableBuilder(
      column: $table.notifsEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get onboardingDone => $composableBuilder(
      column: $table.onboardingDone,
      builder: (column) => ColumnOrderings(column));
}

class $$UserProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get bubbleSide => $composableBuilder(
      column: $table.bubbleSide, builder: (column) => column);

  GeneratedColumn<double> get bubbleYFrac => $composableBuilder(
      column: $table.bubbleYFrac, builder: (column) => column);

  GeneratedColumn<int> get reducedMotion => $composableBuilder(
      column: $table.reducedMotion, builder: (column) => column);

  GeneratedColumn<int> get hapticsEnabled => $composableBuilder(
      column: $table.hapticsEnabled, builder: (column) => column);

  GeneratedColumn<int> get notifsEnabled => $composableBuilder(
      column: $table.notifsEnabled, builder: (column) => column);

  GeneratedColumn<int> get onboardingDone => $composableBuilder(
      column: $table.onboardingDone, builder: (column) => column);
}

class $$UserProfilesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserProfilesTable,
    UserProfile,
    $$UserProfilesTableFilterComposer,
    $$UserProfilesTableOrderingComposer,
    $$UserProfilesTableAnnotationComposer,
    $$UserProfilesTableCreateCompanionBuilder,
    $$UserProfilesTableUpdateCompanionBuilder,
    (
      UserProfile,
      BaseReferences<_$AppDatabase, $UserProfilesTable, UserProfile>
    ),
    UserProfile,
    PrefetchHooks Function()> {
  $$UserProfilesTableTableManager(_$AppDatabase db, $UserProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<String> bubbleSide = const Value.absent(),
            Value<double> bubbleYFrac = const Value.absent(),
            Value<int> reducedMotion = const Value.absent(),
            Value<int> hapticsEnabled = const Value.absent(),
            Value<int> notifsEnabled = const Value.absent(),
            Value<int> onboardingDone = const Value.absent(),
          }) =>
              UserProfilesCompanion(
            id: id,
            displayName: displayName,
            createdAt: createdAt,
            bubbleSide: bubbleSide,
            bubbleYFrac: bubbleYFrac,
            reducedMotion: reducedMotion,
            hapticsEnabled: hapticsEnabled,
            notifsEnabled: notifsEnabled,
            onboardingDone: onboardingDone,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            required int createdAt,
            Value<String> bubbleSide = const Value.absent(),
            Value<double> bubbleYFrac = const Value.absent(),
            Value<int> reducedMotion = const Value.absent(),
            Value<int> hapticsEnabled = const Value.absent(),
            Value<int> notifsEnabled = const Value.absent(),
            Value<int> onboardingDone = const Value.absent(),
          }) =>
              UserProfilesCompanion.insert(
            id: id,
            displayName: displayName,
            createdAt: createdAt,
            bubbleSide: bubbleSide,
            bubbleYFrac: bubbleYFrac,
            reducedMotion: reducedMotion,
            hapticsEnabled: hapticsEnabled,
            notifsEnabled: notifsEnabled,
            onboardingDone: onboardingDone,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UserProfilesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UserProfilesTable,
    UserProfile,
    $$UserProfilesTableFilterComposer,
    $$UserProfilesTableOrderingComposer,
    $$UserProfilesTableAnnotationComposer,
    $$UserProfilesTableCreateCompanionBuilder,
    $$UserProfilesTableUpdateCompanionBuilder,
    (
      UserProfile,
      BaseReferences<_$AppDatabase, $UserProfilesTable, UserProfile>
    ),
    UserProfile,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
  $$GoalDependenciesTableTableManager get goalDependencies =>
      $$GoalDependenciesTableTableManager(_db, _db.goalDependencies);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$TaskCompletionsTableTableManager get taskCompletions =>
      $$TaskCompletionsTableTableManager(_db, _db.taskCompletions);
  $$UserProfilesTableTableManager get userProfiles =>
      $$UserProfilesTableTableManager(_db, _db.userProfiles);
}
