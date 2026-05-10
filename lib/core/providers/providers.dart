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

final allDependenciesProvider = FutureProvider<List<GoalDependency>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.getAllDependencies();
});

/// Full graph model with progress, status, and dependency info
final goalGraphProvider = FutureProvider<List<GoalWithProgress>>((ref) async {
  final db = ref.watch(databaseProvider);
  final goals = await db.getAllGoals();
  final deps = await db.getAllDependencies();
  final tasks = await db.getAllTasks();
  final allCompletions = <String, List<TaskCompletion>>{};

  for (final t in tasks) {
    allCompletions[t.goalId] ??= [];
  }

  // Fetch all completions
  for (final t in tasks) {
    final comps = await db.getCompletionsForTask(t.id);
    allCompletions[t.goalId] = [
      ...(allCompletions[t.goalId] ?? []),
      ...comps,
    ];
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
                colorIndex: 0,
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
    final status = statusService.evaluateStatus(
      goal: g,
      allGoalsMap: goalMap,
      effectiveProgress: ep,
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

final allTasksProvider = FutureProvider<List<Task>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.getAllTasks();
});

final todayCompletionsProvider = FutureProvider<List<TaskCompletion>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.getTodayCompletions();
});

final missedCompletionsProvider = FutureProvider<List<TaskCompletion>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.getMissedCompletions();
});

// ════════════════════════════════════════════════════════════════════════════
// NAVIGATION STATE
// ════════════════════════════════════════════════════════════════════════════

final pageIndexProvider = StateProvider<int>((ref) => 0);

// ════════════════════════════════════════════════════════════════════════════
// GOAL ACTIONS
// ════════════════════════════════════════════════════════════════════════════

class GoalNotifier extends StateNotifier<AsyncValue<void>> {
  GoalNotifier(this.db, this.ref) : super(const AsyncData(null));

  final AppDatabase db;
  final Ref ref;

  Future<void> createGoal({
    required String id,
    String? parentId,
    required String name,
    String? aim,
    required String timeframe,
    required DateTime deadline,
    int weight = 1,
    List<String> dependsOn = const [],
  }) async {
    state = const AsyncLoading();
    try {
      final colorIdx = (await db.getGoalCount()) % 8;
      await db.insertGoal(GoalsCompanion.insert(
        id: id,
        parentId: Value(parentId),
        name: name,
        aim: Value(aim),
        timeframe: timeframe,
        deadline: deadline.millisecondsSinceEpoch,
        weight: Value(weight),
        colorIndex: Value(colorIdx),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
      for (final dep in dependsOn) {
        await db.insertDependency(GoalDependenciesCompanion.insert(
          goalId: id,
          dependsOnId: dep,
        ));
      }
      ref.invalidate(allGoalsProvider);
      ref.invalidate(goalGraphProvider);
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
      ref.invalidate(allGoalsProvider);
      ref.invalidate(goalGraphProvider);
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
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final goalNotifierProvider =
    StateNotifierProvider<GoalNotifier, AsyncValue<void>>((ref) {
  final db = ref.watch(databaseProvider);
  return GoalNotifier(db, ref);
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
    required String goalId,
    required String name,
    required String schedule,
    String? scheduleOn,
    required String reminderTime,
    bool isActive = true,
  }) async {
    state = const AsyncLoading();
    try {
      final id = const Uuid().v4();
      await db.insertTask(TasksCompanion.insert(
        id: id,
        goalId: goalId,
        name: name,
        schedule: schedule,
        scheduleOn: Value(scheduleOn),
        reminderTime: reminderTime,
        isActive: Value(isActive ? 1 : 0),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
      await schedulingService.generateCompletionWindow();
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
      ref.invalidate(todayCompletionsProvider);
      ref.invalidate(missedCompletionsProvider);
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
      ref.invalidate(todayCompletionsProvider);
      ref.invalidate(goalGraphProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await db.deleteTask(taskId);
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
        final deadline =
            DateTime.parse(gd.deadline).millisecondsSinceEpoch;
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
            goalId: gd.id,
            name: td.name,
            schedule: td.schedule,
            scheduleOn: Value(td.on),
            reminderTime: td.reminder,
            isActive: Value(td.active ? 1 : 0),
            createdAt: now,
          ));
        }
      }

      await db.importBatch(
        newGoals: goalCompanions,
        newDeps: depCompanions,
        newTasks: taskCompanions,
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
