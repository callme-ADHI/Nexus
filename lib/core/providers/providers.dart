import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../models/models.dart';
import '../services/progress_calculator.dart';
import '../services/scheduling_service.dart';
import '../services/status_service.dart';
import '../services/notification_service.dart';
import '../services/yaml_parser.dart';
import '../services/productivity_service.dart';

// ════════════════════════════════════════════════════════════════════════════
// UI STATE PROVIDERS
// ════════════════════════════════════════════════════════════════════════════

final navActiveProvider = StateProvider<bool>((ref) => false);

// ════════════════════════════════════════════════════════════════════════════
// DATABASE PROVIDER
// ════════════════════════════════════════════════════════════════════════════

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ════════════════════════════════════════════════════════════════════════════
// PROFILE
// ════════════════════════════════════════════════════════════════════════════

final profileProvider = StreamProvider<UserProfile?>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.userProfiles).watch().map((rows) =>
      rows.isEmpty ? null : rows.first);
});

// ════════════════════════════════════════════════════════════════════════════
// GOALS
// ════════════════════════════════════════════════════════════════════════════

final allGoalsProvider = StreamProvider<List<Goal>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllGoals();
});

final allDependenciesProvider = StreamProvider<List<GoalDependency>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllDependencies();
});


/// Provides the set of goal IDs that are currently blocked by incomplete dependencies.
/// Reactive: re-evaluates whenever goals or dependencies stream-emit new data.
/// FutureProvider watching stream .future is the correct Riverpod 2 reactive pattern.
final blockedGoalIdsProvider = FutureProvider<Set<String>>((ref) async {
  final goals = await ref.watch(allGoalsProvider.future);
  final deps  = await ref.watch(allDependenciesProvider.future);
  final goalMap  = {for (final g in goals) g.id: g};
  final depGraph = <String, List<String>>{};
  for (final d in deps) {
    depGraph[d.goalId] ??= [];
    depGraph[d.goalId]!.add(d.dependsOnId);
  }
  final blocked = <String>{};
  for (final g in goals) {
    final myDeps = depGraph[g.id] ?? [];
    if (myDeps.any((id) => goalMap[id]?.status != 'completed')) {
      blocked.add(g.id);
    }
  }
  return blocked;
});

/// Full graph model with progress, status, and dependency info
final goalGraphProvider = FutureProvider<List<GoalWithProgress>>((ref) async {
  final db = ref.watch(databaseProvider);
  final goals = await db.getAllGoals();
  final deps = await db.getAllDependencies();
  final tasks = await db.getAllTasks();
  final allCompletions = <String, List<TaskCompletion>>{};

  // Optimize: Fetch all completions in one query instead of loop (fixes UI freeze/lag)
  final completions = await db.select(db.taskCompletions).get();
  final taskCompletionsMap = <String, List<TaskCompletion>>{};
  for (final c in completions) {
    taskCompletionsMap[c.taskId] ??= [];
    taskCompletionsMap[c.taskId]!.add(c);
  }

  for (final t in tasks) {
    if (t.goalId == null) continue;
    final comps = taskCompletionsMap[t.id] ?? [];
    allCompletions[t.goalId!] ??= [];
    allCompletions[t.goalId!]!.addAll(comps);
  }

  final goalMap = {for (final g in goals) g.id: g};
  final statusService = StatusService();
  statusService.buildGraph(goals, deps);

  // Build sub-goal map
  final subGoalMap = <String, List<String>>{};
  for (final g in goals) {
    if (g.parentId != null) {
      subGoalMap[g.parentId!] ??= [];
      subGoalMap[g.parentId!]!.add(g.id);
    }
  }

  // Dep map
  final depMap = <String, List<String>>{};
  for (final d in deps) {
    depMap[d.goalId] ??= [];
    depMap[d.goalId]!.add(d.dependsOnId);
  }

  // Compute effective progress for each goal (bottom-up)
  final progressMap = <String, double>{};

  // Topological-ish order: process leaves first
  // Simple: compute in two passes (handle up to 2 levels of nesting)
  for (final g in goals) {
    final comps = allCompletions[g.id] ?? [];
    final tp = ProgressCalculator.taskProgress(goal: g, completions: comps);
    progressMap[g.id] = tp; // default (overwritten below if has children)
  }

  // Second pass: incorporate sub-goals
  for (final g in goals) {
    final subIds = subGoalMap[g.id] ?? [];
    final comps = allCompletions[g.id] ?? [];
    final tp = ProgressCalculator.taskProgress(goal: g, completions: comps);

    final subGoalProgressList =
        subIds.map((sid) {
          final sg = goalMap[sid];
          if (sg == null) {
            return (goal: Goal(
            id: sid, name: '', timeframe: '', deadline: 0, weight: 1,
            status: 'not_started', createdAt: 0, colorIndex: 0,
            hasStrictDeadline: false,
          ), progress: 0.0);
          }
          return (goal: sg, progress: progressMap[sid] ?? 0.0);
        }).toList();

    progressMap[g.id] = ProgressCalculator.effectiveProgress(
      goal: g,
      selfTaskProgress: tp,
      subGoals: subGoalProgressList,
    );
  }

  // Build GoalWithProgress list
  return goals.map((g) {
    final ep = progressMap[g.id] ?? 0.0;
    final depIds = depMap[g.id] ?? [];
    final depGoalProgress = depIds
        .map((did) => (
              goal: goalMap[did] ?? Goal(
                id: did, name: '', timeframe: '', deadline: 0,
                weight: 1, status: 'not_started', createdAt: 0,
                colorIndex: 0, hasStrictDeadline: false,
              ),
              effectiveProgress: progressMap[did] ?? 0.0,
            ))
        .toList();

    final cp = ProgressCalculator.chainProgress(
      goal: g,
      ownEffectiveProgress: ep,
      dependencies: depGoalProgress,
    );
    final te = ProgressCalculator.timeElapsedPct(g);
    final hasActiveTasks = tasks.any((t) => t.goalId == g.id && t.isActive == 1);
    final status = statusService.evaluateStatus(
      goal: g,
      allGoalsMap: goalMap,
      effectiveProgress: ep,
      completions: allCompletions[g.id] ?? [],
      hasActiveTasks: hasActiveTasks,
    );

    return GoalWithProgress(
      goal: g,
      effectiveProgress: ep,
      chainProgress: cp,
      status: status,
      timeElapsedPct: te,
      hasTimeWarning: ProgressCalculator.hasTimeWarning(te, ep),
      dependsOnIds: depIds,
      subGoals: [],
    );
  }).toList();
});

// ════════════════════════════════════════════════════════════════════════════
// TASKS
// ════════════════════════════════════════════════════════════════════════════

final allTasksProvider = StreamProvider<List<Task>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllTasks();
});

final todayCompletionsProvider = StreamProvider<List<TaskCompletion>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchTodayCompletions();
});

final missedCompletionsProvider = StreamProvider<List<TaskCompletion>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchMissedCompletions();
});

final completedCompletionsProvider = StreamProvider<List<TaskCompletion>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchCompletedCompletions();
});

final pastCompletionsProvider = StreamProvider.family<List<TaskCompletion>, int>((ref, days) {
  final db = ref.watch(databaseProvider);
  return db.watchPastCompletions(days);
});

/// All TaskCompletion records for tasks belonging to a specific goal.
/// Used by GoalDetailSheet to show/toggle task completions regardless of date.
final allCompletionsForGoalProvider =
    StreamProvider.family<List<TaskCompletion>, String>((ref, goalId) {
  final db = ref.watch(databaseProvider);
  return db.watchCompletionsForGoal(goalId);
});


// ════════════════════════════════════════════════════════════════════════════
// NAVIGATION STATE
// ════════════════════════════════════════════════════════════════════════════

final pageIndexProvider = StateProvider<int>((ref) => 0);

// ════════════════════════════════════════════════════════════════════════════
// GOAL ACTIONS
// ════════════════════════════════════════════════════════════════════════════

class GoalNotifier extends StateNotifier<AsyncValue<void>> {
  GoalNotifier(this.db, this.ref, this.sched) : super(const AsyncData(null));

  final AppDatabase db;
  final Ref ref;
  final SchedulingService sched;

  Future<void> createGoal({
    required String id,
    String? parentId,
    required String name,
    String? aim,
    required String timeframe,
    required DateTime deadline,
    int weight = 1,
    List<String> dependsOn = const [],
    bool hasStrictDeadline = false,
  }) async {
    state = const AsyncLoading();
    try {
      final now      = DateTime.now().millisecondsSinceEpoch;
      final colorIdx = (await db.getGoalCount()) % 8;
      // Goals with dependencies start with null startDate (stamped on unlock).
      // Goals without dependencies start immediately from now.
      final startDate = dependsOn.isEmpty ? Value<int?>(now) : const Value<int?>(null);
      await db.insertGoal(GoalsCompanion.insert(
        id: id,
        parentId: Value(parentId),
        name: name,
        aim: Value(aim),
        timeframe: timeframe,
        deadline: deadline.millisecondsSinceEpoch,
        weight: Value(weight),
        colorIndex: Value(colorIdx),
        createdAt: now,
        startDate: startDate,
        hasStrictDeadline: Value(hasStrictDeadline),
      ));
      for (final dep in dependsOn) {
        await db.insertDependency(GoalDependenciesCompanion.insert(
          goalId: id,
          dependsOnId: dep,
        ));
      }
      ref.invalidate(allGoalsProvider);
      ref.invalidate(goalGraphProvider);
      ref.invalidate(blockedGoalIdsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> markGoalComplete(String goalId) async {
    state = const AsyncLoading();
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.updateGoal(GoalsCompanion(
        id: Value(goalId),
        status: const Value('completed'),
        completedAt: Value(now),
      ));

      // Unlock any goals that were blocked waiting for this one to complete,
      // and generate their task completion records now.
      await sched.refreshBlockedTasks();

      ref.invalidate(allGoalsProvider);
      ref.invalidate(goalGraphProvider);
      ref.invalidate(blockedGoalIdsProvider);
      ref.invalidate(allTasksProvider);
      ref.invalidate(todayCompletionsProvider);
      ref.invalidate(missedCompletionsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteGoal(String goalId) async {
    state = const AsyncLoading();
    try {
      await db.deleteGoal(goalId);
      ref.invalidate(allGoalsProvider);
      ref.invalidate(goalGraphProvider);
      ref.invalidate(blockedGoalIdsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final goalNotifierProvider =
    StateNotifierProvider<GoalNotifier, AsyncValue<void>>((ref) {
  final db   = ref.watch(databaseProvider);
  final sched = ref.watch(schedulingServiceProvider);
  return GoalNotifier(db, ref, sched);
});

// ════════════════════════════════════════════════════════════════════════════
// TASK ACTIONS
// ════════════════════════════════════════════════════════════════════════════

class TaskNotifier extends StateNotifier<AsyncValue<void>> {
  TaskNotifier(this.db, this.ref, this.schedulingService)
      : super(const AsyncData(null));

  final AppDatabase db;
  final Ref ref;
  final SchedulingService schedulingService;

  Future<void> createTask({
    String? goalId,
    required String name,
    required String schedule,
    String? scheduleOn,
    required String reminderTime,
    bool isActive = true,
  }) async {
    state = const AsyncLoading();
    try {
      final id = const Uuid().v4();
      final companion = TasksCompanion.insert(
        id: id,
        goalId: Value(goalId),
        name: name,
        schedule: schedule,
        scheduleOn: Value(scheduleOn),
        reminderTime: reminderTime,
        isActive: Value(isActive ? 1 : 0),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      await db.insertTask(companion);
      
      final task = Task(
        id: id,
        goalId: goalId,
        name: name,
        schedule: schedule,
        scheduleOn: scheduleOn,
        reminderTime: reminderTime,
        isActive: isActive ? 1 : 0,
        createdAt: companion.createdAt.value,
      );
      
      await schedulingService.generateForTask(task);
      await NotificationService.rescheduleAll(db);
      ref.invalidate(allTasksProvider);
      ref.invalidate(todayCompletionsProvider);
      ref.invalidate(goalGraphProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> completeTask({
    required String taskId,
    required int scheduledDate,
  }) async {
    try {
      await db.completeTask(taskId: taskId, scheduledDate: scheduledDate);
      await db.invalidateCache(scheduledDate);
      await ProductivityService.ensureScore(db, scheduledDate);

      ref.invalidate(todayCompletionsProvider);
      ref.invalidate(missedCompletionsProvider);
      ref.invalidate(completedCompletionsProvider);
      ref.invalidate(goalGraphProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> uncompleteTask({
    required String taskId,
    required int scheduledDate,
  }) async {
    try {
      await db.uncompleteTask(taskId: taskId, scheduledDate: scheduledDate);
      await db.invalidateCache(scheduledDate);
      await ProductivityService.ensureScore(db, scheduledDate);

      ref.invalidate(todayCompletionsProvider);
      ref.invalidate(missedCompletionsProvider);
      ref.invalidate(completedCompletionsProvider);
      ref.invalidate(goalGraphProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }


  Future<void> deleteTask(String taskId) async {
    try {
      await db.deleteTask(taskId);
      await NotificationService.rescheduleAll(db);
      ref.invalidate(allTasksProvider);
      ref.invalidate(todayCompletionsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final schedulingServiceProvider = Provider<SchedulingService>((ref) {
  final db = ref.watch(databaseProvider);
  return SchedulingService(db);
});

final taskNotifierProvider =
    StateNotifierProvider<TaskNotifier, AsyncValue<void>>((ref) {
  final db = ref.watch(databaseProvider);
  final sched = ref.watch(schedulingServiceProvider);
  return TaskNotifier(db, ref, sched);
});

// ════════════════════════════════════════════════════════════════════════════
// YAML IMPORT
// ════════════════════════════════════════════════════════════════════════════

final yamlParserProvider = Provider<YamlParser>((ref) {
  final db = ref.watch(databaseProvider);
  return YamlParser(db);
});

class YamlImportNotifier extends StateNotifier<AsyncValue<YamlImportResult?>> {
  YamlImportNotifier(this.parser, this.db, this.ref, this.sched)
      : super(const AsyncData(null));

  final YamlParser parser;
  final AppDatabase db;
  final Ref ref;
  final SchedulingService sched;

  Future<void> parse(String text) async {
    state = const AsyncLoading();
    try {
      final result = await parser.parse(text);
      state = AsyncData(result);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> commitImport(YamlImportResult result) async {
    state = const AsyncLoading();
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final goalsToImport = [
        ...result.validGoals,
        ...result.conflictGoals.where((g) => !g.skipOnConflict),
      ];

      final goalCompanions = <GoalsCompanion>[];
      final depCompanions = <GoalDependenciesCompanion>[];
      final taskCompanions = <TasksCompanion>[];

      int colorIdx = await db.getGoalCount();
      for (final gd in goalsToImport) {
        final deadline = DateTime.parse(gd.deadline).millisecondsSinceEpoch;

        // Determine startDate:
        //   • Has dependencies → null (will be set when dependency completes)
        //   • YAML provides start_date → use that
        //   • Otherwise → now (goal starts immediately on import)
        int? startDateMs;
        if (gd.dependsOn.isNotEmpty) {
          startDateMs = null; // blocked until dependency completes
        } else if (gd.startDate != null) {
          startDateMs = gd.startDate!.millisecondsSinceEpoch;
        } else {
          startDateMs = now;
        }

        goalCompanions.add(GoalsCompanion.insert(
          id: gd.id,
          parentId: Value(gd.parent),
          name: gd.name,
          aim: Value(gd.aim),
          timeframe: gd.timeframe,
          deadline: deadline,
          weight: Value(gd.weight),
          colorIndex: Value((colorIdx++) % 8),
          createdAt: now,
          startDate: Value(startDateMs),
          hasStrictDeadline: Value(gd.hasStrictDeadline),
        ));
        for (final dep in gd.dependsOn) {
          depCompanions.add(GoalDependenciesCompanion.insert(
            goalId: gd.id,
            dependsOnId: dep,
          ));
        }
        for (final td in gd.tasks) {
          taskCompanions.add(TasksCompanion.insert(
            id: const Uuid().v4(),
            goalId: Value(gd.id),
            name: td.name,
            schedule: td.schedule,
            scheduleOn: Value(td.on),
            reminderTime: td.reminder,
            isActive: Value(td.active ? 1 : 0),
            createdAt: now,
          ));
        }
      }

      final activityCompanions = <ActivityLogsCompanion>[];
      for (final a in result.activityLogs) {
        activityCompanions.add(ActivityLogsCompanion.insert(
          date: a.date,
          category: a.category,
          name: a.name,
          startTime: a.startTime,
          endTime: a.endTime,
          notes: Value(a.notes),
          isAuto: Value(a.isAuto ? 1 : 0),
          createdAt: a.createdAt,
        ));
      }

      final sleepCompanions = <SleepLogsCompanion>[];
      for (final s in result.sleepLogs) {
        sleepCompanions.add(SleepLogsCompanion.insert(
          date: s.date,
          sleepTime: s.sleepTime,
          wakeTime: s.wakeTime,
          qualityNote: Value(s.qualityNote),
          createdAt: s.createdAt,
        ));
      }

      await db.importBatch(
        newGoals: goalCompanions,
        newDeps: depCompanions,
        newTasks: taskCompanions,
        newActivities: activityCompanions,
        newSleeps: sleepCompanions,
      );

      await sched.generateCompletionWindow();
      await NotificationService.rescheduleAll(db);

      ref.invalidate(allGoalsProvider);
      ref.invalidate(goalGraphProvider);
      ref.invalidate(allTasksProvider);
      ref.invalidate(todayCompletionsProvider);

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void reset() => state = const AsyncData(null);
}

final yamlImportProvider =
    StateNotifierProvider<YamlImportNotifier, AsyncValue<YamlImportResult?>>(
        (ref) {
  return YamlImportNotifier(
    ref.watch(yamlParserProvider),
    ref.watch(databaseProvider),
    ref,
    ref.watch(schedulingServiceProvider),
  );
});

final widgetUpdateProvider = Provider((ref) {
  final completions = ref.watch(todayCompletionsProvider).value;
  final tasks = ref.watch(allTasksProvider).value;
  if (completions == null || tasks == null) return null;
  return (completions, tasks);
});
