import 'package:drift/drift.dart';
import 'package:drift/native.dart';
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
  // The date from which tasks begin scheduling.
  // null for blocked goals (set to unlock timestamp when dependency completes).
  // For non-blocked goals, set to createdAt or the YAML-specified start_date.
  IntColumn get startDate => integer().nullable()();
  BoolColumn get hasStrictDeadline => boolean().withDefault(const Constant(false))();

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
  TextColumn get goalId => text().nullable().references(Goals, #id)();
  TextColumn get name => text()();
  TextColumn get schedule => text()(); // daily|weekly|monthly|yearly|specific_date
  TextColumn get scheduleOn => text().nullable()();
  TextColumn get reminderTime => text()(); // "HH:MM"
  IntColumn get isActive => integer().withDefault(const Constant(1))();
  IntColumn get createdAt => integer()();
  BoolColumn get isTaskOfTheDay => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class TaskCompletions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get taskId => text().references(Tasks, #id)();
  IntColumn get scheduledDate => integer()(); // midnight unix ms
  IntColumn get completedDate => integer().nullable()();
  IntColumn get isLate => integer().withDefault(const Constant(0))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

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
  // Productivity settings
  TextColumn get defaultWakeTime =>
      text().withDefault(const Constant('07:00'))();
  TextColumn get defaultSleepTime =>
      text().withDefault(const Constant('22:30'))();
  IntColumn get autoLogTasks =>
      integer().withDefault(const Constant(1))();
  TextColumn get navStyle =>
      text().withDefault(const Constant('radial'))();

  @override
  Set<Column> get primaryKey => {id};
}

// ════════════════════════════════════════════════════════════════════════════
// ACTIVITY LOGS
// ════════════════════════════════════════════════════════════════════════════

class ActivityLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get date => integer()();         // midnight unix ms
  TextColumn get category => text()();       // deep_work|exercise|learning|goal_tasks|social|routine|leisure|sleep
  TextColumn get name => text()();           // user label
  IntColumn get startTime => integer()();    // unix ms
  IntColumn get endTime => integer()();      // unix ms
  TextColumn get notes => text().nullable()();
  IntColumn get isAuto => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
}

// ════════════════════════════════════════════════════════════════════════════
// SLEEP LOGS
// ════════════════════════════════════════════════════════════════════════════

class SleepLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get date => integer()();         // midnight unix ms of wake date
  IntColumn get sleepTime => integer()();    // unix ms
  IntColumn get wakeTime => integer()();     // unix ms
  TextColumn get qualityNote => text().nullable()();
  IntColumn get createdAt => integer()();
}

// ════════════════════════════════════════════════════════════════════════════
// PRODUCTIVITY CACHE
// ════════════════════════════════════════════════════════════════════════════

class ProductivityCaches extends Table {
  IntColumn get date => integer()();         // midnight unix ms
  RealColumn get score => real()();          // 0.0–100.0
  RealColumn get coveragePct => real()();    // 0.0–100.0
  RealColumn get sleepHours => real().nullable()();
  TextColumn get topCategory => text().nullable()();
  TextColumn get label => text()();          // "Peak Day" etc.
  IntColumn get invalidated => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {date};
}

// ════════════════════════════════════════════════════════════════════════════
// DATABASE
// ════════════════════════════════════════════════════════════════════════════

@DriftDatabase(
    tables: [Goals, GoalDependencies, Tasks, TaskCompletions, UserProfiles,
             ActivityLogs, SleepLogs, ProductivityCaches])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.withExecutor(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(goals, goals.colorIndex);
          }
          if (from < 3) {
            await m.alterTable(TableMigration(tasks));
          }
          if (from < 4) {
            await m.createTable(activityLogs);
            await m.createTable(sleepLogs);
            await m.createTable(productivityCaches);
            await m.addColumn(userProfiles, userProfiles.defaultWakeTime);
            await m.addColumn(userProfiles, userProfiles.defaultSleepTime);
            await m.addColumn(userProfiles, userProfiles.autoLogTasks);
          }
          if (from < 5) {
            // Add startDate to Goals — the date from which tasks begin scheduling.
            // Existing goals get startDate = createdAt so their history is preserved.
            await m.addColumn(goals, goals.startDate);
            await customStatement(
              'UPDATE goals SET start_date = created_at WHERE start_date IS NULL',
            );
          }
          if (from < 6) {
            // Clear any old mock records on the device/emulator to allow a clean startup.
            await customStatement('DELETE FROM task_completions');
            await customStatement('DELETE FROM tasks');
            await customStatement('DELETE FROM goal_dependencies');
            await customStatement('DELETE FROM goals');
            await customStatement('DELETE FROM activity_logs');
            await customStatement('DELETE FROM sleep_logs');
            await customStatement('DELETE FROM productivity_caches');
            await customStatement('DELETE FROM user_profiles');
          }
          if (from < 7) {
            await m.addColumn(goals, goals.hasStrictDeadline);
          }
          if (from < 8) {
            await m.addColumn(userProfiles, userProfiles.navStyle);
          }
          if (from < 9) {
            await m.addColumn(tasks, tasks.isTaskOfTheDay);
          }
          if (from < 10) {
            await m.addColumn(taskCompletions, taskCompletions.isDeleted);
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

  Stream<List<GoalDependency>> watchAllDependencies() =>
      select(goalDependencies).watch();


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

  Stream<List<Task>> watchAllTasks() => select(tasks).watch();

  /// All TaskCompletion records whose taskId belongs to tasks of [goalId].
  /// Used by GoalDetailSheet so tasks can be toggled regardless of schedule date.
  Stream<List<TaskCompletion>> watchCompletionsForGoal(String goalId) {
    final query = select(taskCompletions).join([
      innerJoin(tasks, tasks.id.equalsExp(taskCompletions.taskId)),
    ])..where(tasks.goalId.equals(goalId) & taskCompletions.isDeleted.equals(false));
    return query
        .map((row) => row.readTable(taskCompletions))
        .watch();
  }


  Future<List<Task>> getActiveTasksForGoal(String goalId) =>
      (select(tasks)
            ..where((t) => t.goalId.equals(goalId) & t.isActive.equals(1)))
          .get();

  Future<void> insertTask(TasksCompanion companion) =>
      into(tasks).insert(companion, mode: InsertMode.insertOrReplace);

  Future<void> updateTask(TasksCompanion companion) =>
      update(tasks).replace(companion);

  Future<void> deleteTask(String taskId) async {
    await (delete(taskCompletions)
          ..where((t) => t.taskId.equals(taskId)))
        .go();
    await (delete(tasks)..where((t) => t.id.equals(taskId))).go();
  }

  // ── TASK COMPLETIONS ─────────────────────────────────────────────────────

  Future<List<TaskCompletion>> getCompletionsForTask(String taskId) =>
      (select(taskCompletions)..where((t) => t.taskId.equals(taskId) & t.isDeleted.equals(false))).get();

  Future<List<TaskCompletion>> getCompletionsForDate(int scheduledDate) =>
      (select(taskCompletions)
            ..where((t) => t.scheduledDate.equals(scheduledDate) & t.isDeleted.equals(false)))
          .get();

  Future<List<TaskCompletion>> getMissedCompletions() {
    final todayMidnight = _todayMidnightMs();
    return (select(taskCompletions)
          ..where((t) =>
              t.scheduledDate.isSmallerThanValue(todayMidnight) &
              t.completedDate.isNull() &
              t.isDeleted.equals(false)))
        .get();
  }

  Stream<List<TaskCompletion>> watchMissedCompletions() {
    final todayMidnight = _todayMidnightMs();
    return (select(taskCompletions)
          ..where((t) =>
              t.scheduledDate.isSmallerThanValue(todayMidnight) &
              t.completedDate.isNull() &
              t.isDeleted.equals(false)))
        .watch();
  }


  Future<List<TaskCompletion>> getTodayCompletions() {
    final todayMidnight = _todayMidnightMs();
    return (select(taskCompletions)
          ..where((t) => t.scheduledDate.equals(todayMidnight) & t.isDeleted.equals(false)))
        .get();
  }

  Stream<List<TaskCompletion>> watchTodayCompletions() {
    final todayMidnight = _todayMidnightMs();
    return (select(taskCompletions)
          ..where((t) => t.scheduledDate.equals(todayMidnight) & t.isDeleted.equals(false)))
        .watch();
  }


  Future<List<TaskCompletion>> getPastCompletions(int days) {
    final todayMidnight = _todayMidnightMs();
    final past = todayMidnight - (days * 86400000);
    return (select(taskCompletions)
          ..where((t) => t.scheduledDate.isBiggerOrEqualValue(past) & t.scheduledDate.isSmallerOrEqualValue(todayMidnight) & t.isDeleted.equals(false)))
        .get();
  }

  Stream<List<TaskCompletion>> watchPastCompletions(int days) {
    final todayMidnight = _todayMidnightMs();
    final past = todayMidnight - (days * 86400000);
    return (select(taskCompletions)
          ..where((t) => t.scheduledDate.isBiggerOrEqualValue(past) & t.scheduledDate.isSmallerOrEqualValue(todayMidnight) & t.isDeleted.equals(false)))
        .watch();
  }


  Future<List<TaskCompletion>> getUpcomingCompletions(int untilMs) {
    final todayMidnight = _todayMidnightMs();
    return (select(taskCompletions)
          ..where((t) =>
              t.scheduledDate.isBiggerThanValue(todayMidnight) &
              t.scheduledDate.isSmallerOrEqualValue(untilMs) &
              t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledDate)]))
        .get();
  }

  Future<List<TaskCompletion>> getCompletedCompletions() {
    return (select(taskCompletions)
          ..where((t) => t.completedDate.isNotNull() & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.completedDate)]))
        .get();
  }

  Stream<List<TaskCompletion>> watchCompletedCompletions() {
    return (select(taskCompletions)
          ..where((t) => t.completedDate.isNotNull() & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.completedDate)]))
        .watch();
  }

  Future<void> deleteOccurrence(String taskId, int scheduledDate) async {
    await into(taskCompletions).insert(
      TaskCompletionsCompanion(
        taskId: Value(taskId),
        scheduledDate: Value(scheduledDate),
        isDeleted: const Value(true),
      ),
      mode: InsertMode.insertOrReplace,
    );
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
    List<ActivityLogsCompanion> newActivities = const [],
    List<SleepLogsCompanion> newSleeps = const [],
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
      for (final a in newActivities) {
        await into(activityLogs).insert(a);
      }
      for (final s in newSleeps) {
        await into(sleepLogs).insert(s);
      }
    });
  }

  Future<void> clearAllData() async {
    await transaction(() async {
      await delete(taskCompletions).go();
      await delete(tasks).go();
      await delete(goalDependencies).go();
      await delete(goals).go();
      await delete(activityLogs).go();
      await delete(sleepLogs).go();
      await delete(productivityCaches).go();
      await delete(userProfiles).go();
      await into(userProfiles).insert(UserProfilesCompanion.insert(
        id: const Value(1),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
    });
  }

  Future<void> clearAllLogs() async {
    await delete(activityLogs).go();
    await delete(sleepLogs).go();
    await delete(productivityCaches).go();
  }

  Future<void> clearFutureData() async {
    final todayMidnight = _todayMidnightMs();
    await (delete(taskCompletions)
          ..where((t) => t.scheduledDate.isBiggerThanValue(todayMidnight)))
        .go();
  }

  // ── ACTIVITY LOGS ─────────────────────────────────────────────────────────

  Future<List<ActivityLog>> getAllActivityLogs() => select(activityLogs).get();

  Future<List<ActivityLog>> getActivitiesForDate(int dateMidnight) =>
      (select(activityLogs)
            ..where((t) => t.date.equals(dateMidnight))
            ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
          .get();

  Stream<List<ActivityLog>> watchActivitiesForDate(int dateMidnight) =>
      (select(activityLogs)
            ..where((t) => t.date.equals(dateMidnight))
            ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
          .watch();

  Future<List<ActivityLog>> getActivitiesInRange(int startMs, int endMs) =>
      (select(activityLogs)
            ..where((t) => t.date.isBiggerOrEqualValue(startMs) & t.date.isSmallerOrEqualValue(endMs))
            ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
          .get();

  Stream<List<ActivityLog>> watchActivitiesInRange(int startMs, int endMs) =>
      (select(activityLogs)
            ..where((t) => t.date.isBiggerOrEqualValue(startMs) & t.date.isSmallerOrEqualValue(endMs))
            ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
          .watch();


  Future<int> insertActivity(ActivityLogsCompanion companion) =>
      into(activityLogs).insert(companion);

  Future<void> updateActivity(ActivityLogsCompanion companion) =>
      (update(activityLogs)..where((t) => t.id.equals(companion.id.value)))
          .write(companion);

  Future<void> deleteActivity(int id) =>
      (delete(activityLogs)..where((t) => t.id.equals(id))).go();

  // ── SLEEP LOGS ────────────────────────────────────────────────────────────

  Future<List<SleepLog>> getAllSleepLogs() => select(sleepLogs).get();

  Future<SleepLog?> getSleepForDate(int dateMidnight) =>
      (select(sleepLogs)
            ..where((t) => t.date.equals(dateMidnight))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(1))
          .getSingleOrNull();

  Stream<SleepLog?> watchSleepForDate(int dateMidnight) =>
      (select(sleepLogs)
            ..where((t) => t.date.equals(dateMidnight))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(1))
          .watchSingleOrNull();

  Future<List<SleepLog>> getSleepInRange(int startMs, int endMs) =>
      (select(sleepLogs)
            ..where((t) => t.date.isBiggerOrEqualValue(startMs) & t.date.isSmallerOrEqualValue(endMs))
            ..orderBy([(t) => OrderingTerm.asc(t.date)]))
          .get();

  Stream<List<SleepLog>> watchSleepInRange(int startMs, int endMs) =>
      (select(sleepLogs)
            ..where((t) => t.date.isBiggerOrEqualValue(startMs) & t.date.isSmallerOrEqualValue(endMs))
            ..orderBy([(t) => OrderingTerm.asc(t.date)]))
          .watch();


  Future<int> insertSleep(SleepLogsCompanion companion) =>
      into(sleepLogs).insert(companion);

  Future<void> updateSleep(SleepLogsCompanion companion) =>
      (update(sleepLogs)..where((t) => t.id.equals(companion.id.value)))
          .write(companion);

  Future<void> deleteSleep(int id) =>
      (delete(sleepLogs)..where((t) => t.id.equals(id))).go();

  Future<void> deleteSleepForDate(int dateMidnight) =>
      (delete(sleepLogs)..where((t) => t.date.equals(dateMidnight))).go();

  // ── PRODUCTIVITY CACHE ────────────────────────────────────────────────────

  Future<ProductivityCache?> getCachedScore(int dateMidnight) =>
      (select(productivityCaches)..where((t) => t.date.equals(dateMidnight)))
          .getSingleOrNull();

  Future<List<ProductivityCache>> getCachedScoresInRange(int startMs, int endMs) =>
      (select(productivityCaches)
            ..where((t) => t.date.isBiggerOrEqualValue(startMs) & t.date.isSmallerOrEqualValue(endMs))
            ..orderBy([(t) => OrderingTerm.asc(t.date)]))
          .get();

  Stream<List<ProductivityCache>> watchCachedScoresInRange(int startMs, int endMs) =>
      (select(productivityCaches)
            ..where((t) => t.date.isBiggerOrEqualValue(startMs) & t.date.isSmallerOrEqualValue(endMs))
            ..orderBy([(t) => OrderingTerm.asc(t.date)]))
          .watch();


  Future<void> upsertCache(ProductivityCachesCompanion companion) =>
      into(productivityCaches).insert(companion, mode: InsertMode.insertOrReplace);

  Future<void> invalidateCache(int dateMidnight) =>
      (update(productivityCaches)..where((t) => t.date.equals(dateMidnight)))
          .write(const ProductivityCachesCompanion(invalidated: Value(1)));

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
