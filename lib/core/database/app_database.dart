import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// ════════════════════════════════════════════════════════════════════════════
// TABLE DEFINITIONS
// ════════════════════════════════════════════════════════════════════════════

class Goals extends Table {
  TextColumn get id => text()();
  TextColumn get parentId => text().nullable().references(Goals, #id)();
  TextColumn get name => text()();
  TextColumn get aim => text().nullable()();
  TextColumn get timeframe => text()(); // day|week|month|year
  IntColumn get deadline => integer()();
  IntColumn get weight => integer().withDefault(const Constant(1))();
  TextColumn get status =>
      text().withDefault(const Constant('not_started'))();
  IntColumn get createdAt => integer()();
  IntColumn get completedAt => integer().nullable()();
  // Color palette index 0–7 for visual differentiation in graph
  IntColumn get colorIndex => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class GoalDependencies extends Table {
  TextColumn get goalId => text().references(Goals, #id)();
  TextColumn get dependsOnId => text().references(Goals, #id)();

  @override
  Set<Column> get primaryKey => {goalId, dependsOnId};
}

class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get goalId => text().references(Goals, #id)();
  TextColumn get name => text()();
  TextColumn get schedule => text()(); // daily|weekly|monthly|yearly|specific_date
  TextColumn get scheduleOn => text().nullable()();
  TextColumn get reminderTime => text()(); // "HH:MM"
  IntColumn get isActive => integer().withDefault(const Constant(1))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class TaskCompletions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get taskId => text().references(Tasks, #id)();
  IntColumn get scheduledDate => integer()(); // midnight unix ms
  IntColumn get completedDate => integer().nullable()();
  IntColumn get isLate => integer().withDefault(const Constant(0))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {taskId, scheduledDate},
      ];
}

class UserProfiles extends Table {
  IntColumn get id => integer()();
  TextColumn get displayName =>
      text().withDefault(const Constant('You'))();
  IntColumn get createdAt => integer()();
  TextColumn get bubbleSide =>
      text().withDefault(const Constant('right'))();
  RealColumn get bubbleYFrac =>
      real().withDefault(const Constant(0.72))();
  IntColumn get reducedMotion =>
      integer().withDefault(const Constant(0))();
  IntColumn get hapticsEnabled =>
      integer().withDefault(const Constant(1))();
  IntColumn get notifsEnabled =>
      integer().withDefault(const Constant(1))();
  IntColumn get onboardingDone =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ════════════════════════════════════════════════════════════════════════════
// DATABASE
// ════════════════════════════════════════════════════════════════════════════

@DriftDatabase(
    tables: [Goals, GoalDependencies, Tasks, TaskCompletions, UserProfiles])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(goals, goals.colorIndex);
          }
        },
      );

  // ── PROFILE ──────────────────────────────────────────────────────────────

  Future<UserProfile?> getProfile() =>
      (select(userProfiles)..where((t) => t.id.equals(1)))
          .getSingleOrNull();

  Future<void> ensureProfile() async {
    final existing = await getProfile();
    if (existing == null) {
      await into(userProfiles).insert(UserProfilesCompanion.insert(
        id: const Value(1),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
    }
  }

  Future<void> updateProfile(UserProfilesCompanion companion) =>
      (update(userProfiles)..where((t) => t.id.equals(1))).write(companion);

  // ── GOALS ─────────────────────────────────────────────────────────────────

  Stream<List<Goal>> watchAllGoals() => select(goals).watch();

  Future<List<Goal>> getAllGoals() => select(goals).get();

  Future<Goal?> getGoalById(String id) =>
      (select(goals)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> getGoalCount() async {
    final rows = await select(goals).get();
    return rows.length;
  }

  Future<void> insertGoal(GoalsCompanion companion) =>
      into(goals).insert(companion, mode: InsertMode.insertOrReplace);

  Future<void> updateGoal(GoalsCompanion companion) =>
      (update(goals)..where((t) => t.id.equals(companion.id.value)))
          .write(companion);

  Future<void> deleteGoal(String id) async {
    await (delete(goalDependencies)
          ..where((t) => t.goalId.equals(id) | t.dependsOnId.equals(id)))
        .go();
    await (delete(tasks)..where((t) => t.goalId.equals(id))).go();
    await (delete(goals)..where((t) => t.id.equals(id))).go();
  }

  // ── GOAL DEPENDENCIES ────────────────────────────────────────────────────

  Future<List<GoalDependency>> getDepsForGoal(String goalId) =>
      (select(goalDependencies)
            ..where((t) => t.goalId.equals(goalId)))
          .get();

  Future<List<GoalDependency>> getGoalsThatDependOn(String goalId) =>
      (select(goalDependencies)
            ..where((t) => t.dependsOnId.equals(goalId)))
          .get();

  Future<List<GoalDependency>> getAllDependencies() =>
      select(goalDependencies).get();

  Future<void> insertDependency(GoalDependenciesCompanion companion) =>
      into(goalDependencies)
          .insert(companion, mode: InsertMode.insertOrIgnore);

  Future<void> deleteDependency(String goalId, String dependsOnId) =>
      (delete(goalDependencies)
            ..where((t) =>
                t.goalId.equals(goalId) &
                t.dependsOnId.equals(dependsOnId)))
          .go();

  Future<void> clearDepsForGoal(String goalId) =>
      (delete(goalDependencies)..where((t) => t.goalId.equals(goalId))).go();

  // ── TASKS ─────────────────────────────────────────────────────────────────

  Stream<List<Task>> watchTasksForGoal(String goalId) =>
      (select(tasks)..where((t) => t.goalId.equals(goalId))).watch();

  Future<List<Task>> getAllTasks() => select(tasks).get();

  Future<List<Task>> getActiveTasksForGoal(String goalId) =>
      (select(tasks)
            ..where((t) => t.goalId.equals(goalId) & t.isActive.equals(1)))
          .get();

  Future<void> insertTask(TasksCompanion companion) =>
      into(tasks).insert(companion, mode: InsertMode.insertOrReplace);

  Future<void> deleteTask(String taskId) async {
    await (delete(taskCompletions)
          ..where((t) => t.taskId.equals(taskId)))
        .go();
    await (delete(tasks)..where((t) => t.id.equals(taskId))).go();
  }

  // ── TASK COMPLETIONS ─────────────────────────────────────────────────────

  Future<List<TaskCompletion>> getCompletionsForTask(String taskId) =>
      (select(taskCompletions)..where((t) => t.taskId.equals(taskId))).get();

  Future<List<TaskCompletion>> getCompletionsForDate(int scheduledDate) =>
      (select(taskCompletions)
            ..where((t) => t.scheduledDate.equals(scheduledDate)))
          .get();

  Future<List<TaskCompletion>> getMissedCompletions() {
    final todayMidnight = _todayMidnightMs();
    return (select(taskCompletions)
          ..where((t) =>
              t.scheduledDate.isSmallerThanValue(todayMidnight) &
              t.completedDate.isNull()))
        .get();
  }

  Future<List<TaskCompletion>> getTodayCompletions() {
    final todayMidnight = _todayMidnightMs();
    return (select(taskCompletions)
          ..where((t) => t.scheduledDate.equals(todayMidnight)))
        .get();
  }

  Future<List<TaskCompletion>> getPastCompletions(int days) {
    final todayMidnight = _todayMidnightMs();
    final past = todayMidnight - (days * 86400000);
    return (select(taskCompletions)
          ..where((t) => t.scheduledDate.isBiggerOrEqualValue(past) & t.scheduledDate.isSmallerOrEqualValue(todayMidnight)))
        .get();
  }

  Future<List<TaskCompletion>> getUpcomingCompletions(int untilMs) {
    final todayMidnight = _todayMidnightMs();
    return (select(taskCompletions)
          ..where((t) =>
              t.scheduledDate.isBiggerThanValue(todayMidnight) &
              t.scheduledDate.isSmallerOrEqualValue(untilMs))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledDate)]))
        .get();
  }

  Future<void> upsertCompletion(TaskCompletionsCompanion companion) =>
      into(taskCompletions)
          .insert(companion, mode: InsertMode.insertOrIgnore);

  Future<void> markCompleted(int completionId) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(taskCompletions)
          ..where((t) => t.id.equals(completionId)))
        .write(TaskCompletionsCompanion(
      completedDate: Value(now),
      isLate: const Value(1), // will be corrected below if not actually late
    ));
  }

  Future<void> completeTask({
    required String taskId,
    required int scheduledDate,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final isLate = now > scheduledDate + Duration.millisecondsPerDay ? 1 : 0;
    await (update(taskCompletions)
          ..where((t) =>
              t.taskId.equals(taskId) &
              t.scheduledDate.equals(scheduledDate)))
        .write(TaskCompletionsCompanion(
      completedDate: Value(now),
      isLate: Value(isLate),
    ));
  }

  Future<void> uncompleteTask({
    required String taskId,
    required int scheduledDate,
  }) =>
      (update(taskCompletions)
            ..where((t) =>
                t.taskId.equals(taskId) &
                t.scheduledDate.equals(scheduledDate)))
          .write(const TaskCompletionsCompanion(
        completedDate: Value(null),
        isLate: Value(0),
      ));

  // ── BULK OPERATIONS ───────────────────────────────────────────────────────

  /// Import an entire YAML batch atomically
  Future<void> importBatch({
    required List<GoalsCompanion> newGoals,
    required List<GoalDependenciesCompanion> newDeps,
    required List<TasksCompanion> newTasks,
  }) async {
    await transaction(() async {
      for (final g in newGoals) {
        await into(goals).insert(g, mode: InsertMode.insertOrReplace);
      }
      for (final d in newDeps) {
        await into(goalDependencies)
            .insert(d, mode: InsertMode.insertOrIgnore);
      }
      for (final t in newTasks) {
        await into(tasks).insert(t, mode: InsertMode.insertOrReplace);
      }
    });
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  int _todayMidnightMs() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .millisecondsSinceEpoch;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    return driftDatabase(name: 'nexus');
  });
}
