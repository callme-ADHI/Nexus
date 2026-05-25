import 'package:drift/drift.dart' show Value, InsertMode;

import '../database/app_database.dart';

/// Generates TaskCompletion records anchored to each goal's startDate.
///
/// Key invariant:
///   • Unblocked goal  → startDate is set (createdAt or YAML start_date or unlock date)
///   • Blocked goal    → startDate is null; tasks are never scheduled until unlock
///
class SchedulingService {
  final AppDatabase db;
  SchedulingService(this.db);

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC API
  // ─────────────────────────────────────────────────────────────────────────

  /// Call on app launch or after a bulk import.
  /// Skips blocked goals entirely; for unblocked goals uses goal.startDate
  /// as the window start so historical task slots are also generated.
  /// Always generates TODAY's record regardless of startDate so pending
  /// goals' tasks always appear in the Today tab.
  Future<void> generateCompletionWindow() async {
    final tasks     = await db.getAllTasks();
    final goals     = await db.getAllGoals();
    final deps      = await db.getAllDependencies();
    final now       = DateTime.now();
    final today     = DateTime(now.year, now.month, now.day); // midnight
    final windowEnd = now.add(const Duration(days: 30));

    final blockedIds = _computeBlockedGoalIds(goals, deps);
    final goalMap    = {for (final g in goals) g.id: g};

    for (final task in tasks) {
      final from = _goalStartDate(task, goalMap, fallback: now);
      // Always cover TODAY even if the goal's official startDate is in the future.
      // This ensures pending goals with future start dates still show in Today tab.
      final effectiveFrom = from.isAfter(today) ? today : from;

      var to = windowEnd;
      if (task.goalId != null) {
        final goal = goalMap[task.goalId];
        if (goal != null && goal.hasStrictDeadline) {
          final goalDeadline = DateTime.fromMillisecondsSinceEpoch(goal.deadline);
          if (goalDeadline.isAfter(to)) {
            to = goalDeadline;
          }
        }
      }

      await _generateForTaskInternal(task, effectiveFrom, to);
    }
  }

  Future<void> generateForTask(Task task, {Set<String>? blockedGoalIds}) async {
    final now       = DateTime.now();
    final today     = DateTime(now.year, now.month, now.day);
    final windowEnd = now.add(const Duration(days: 30));
    var to = windowEnd;
    Goal? goal;
    if (task.goalId != null) {
      goal = await db.getGoalById(task.goalId!);
      if (goal != null && goal.hasStrictDeadline) {
        final goalDeadline = DateTime.fromMillisecondsSinceEpoch(goal.deadline);
        if (goalDeadline.isAfter(to)) {
          to = goalDeadline;
        }
      }
    }
    final from = _startDateFromGoal(goal, fallback: now);
    final effectiveFrom = from.isAfter(today) ? today : from;
    await _generateForTaskInternal(task, effectiveFrom, to);
  }

  /// Call after marking a goal as complete, so its dependents can unlock.
  ///
  /// For each goal that is no longer blocked:
  ///   1. If startDate is null (it was blocked since import), set startDate = now.
  ///   2. Generate task completion records from startDate onward.
  Future<void> refreshBlockedTasks() async {
    final tasks     = await db.getAllTasks();
    final goals     = await db.getAllGoals();
    final deps      = await db.getAllDependencies();
    final now       = DateTime.now();
    final nowMs     = now.millisecondsSinceEpoch;
    final windowEnd = now.add(const Duration(days: 30));

    final blockedIds = _computeBlockedGoalIds(goals, deps);
    // Mutable local map so we can see updated startDates within this run
    final goalMap    = {for (final g in goals) g.id: g};

    for (final task in tasks) {
      if (task.isActive == 0) continue;
      if (task.goalId != null && blockedIds.contains(task.goalId)) continue;

      // Goal was previously blocked (startDate == null) → just unlocked.
      // Stamp it with today as its official start date.
      if (task.goalId != null) {
        final goal = goalMap[task.goalId];
        if (goal != null && goal.startDate == null) {
          await db.updateGoal(GoalsCompanion(
            id: Value(goal.id),
            startDate: Value(nowMs),
          ));
          // Reflect the update in our local map
          goalMap[goal.id] = Goal(
            id: goal.id,
            parentId: goal.parentId,
            name: goal.name,
            aim: goal.aim,
            timeframe: goal.timeframe,
            deadline: goal.deadline,
            weight: goal.weight,
            status: goal.status,
            createdAt: goal.createdAt,
            completedAt: goal.completedAt,
            colorIndex: goal.colorIndex,
            startDate: nowMs,
            hasStrictDeadline: goal.hasStrictDeadline,
          );
        }
      }

      var to = windowEnd;
      if (task.goalId != null) {
        final goal = goalMap[task.goalId];
        if (goal != null && goal.hasStrictDeadline) {
          final goalDeadline = DateTime.fromMillisecondsSinceEpoch(goal.deadline);
          if (goalDeadline.isAfter(to)) {
            to = goalDeadline;
          }
        }
      }

      final from = _goalStartDate(task, goalMap, fallback: now);
      await _generateForTaskInternal(task, from, to);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // INTERNAL
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _generateForTaskInternal(
    Task task,
    DateTime from,
    DateTime to,
  ) async {
    if (task.isActive == 0) return;
    final dates = _scheduledDates(task, from, to);
    if (dates.isEmpty) return;
    await db.batch((batch) {
      for (final date in dates) {
        batch.insert(
          db.taskCompletions,
          TaskCompletionsCompanion(
            taskId: Value(task.id),
            scheduledDate: Value(date),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  // ── Dependency helpers ────────────────────────────────────────────────────

  /// Returns the set of goal IDs that have at least one incomplete dependency.
  Set<String> _computeBlockedGoalIds(
    List<Goal> goals,
    List<GoalDependency> deps,
  ) {
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
  }

  Future<Set<String>> _loadBlockedGoalIds() async {
    final goals = await db.getAllGoals();
    final deps  = await db.getAllDependencies();
    return _computeBlockedGoalIds(goals, deps);
  }

  // ── startDate helpers ─────────────────────────────────────────────────────

  DateTime _goalStartDate(
    Task task,
    Map<String, Goal> goalMap, {
    required DateTime fallback,
  }) {
    if (task.goalId == null) return fallback;
    return _startDateFromGoal(goalMap[task.goalId], fallback: fallback);
  }

  DateTime _startDateFromGoal(Goal? goal, {required DateTime fallback}) {
    final sd = goal?.startDate;
    if (sd == null) return fallback;
    return DateTime.fromMillisecondsSinceEpoch(sd);
  }

  // ── Date generation ───────────────────────────────────────────────────────

  /// Returns list of midnight timestamps for a task in [from, to]
  List<int> _scheduledDates(Task task, DateTime from, DateTime to) {
    final schedule   = task.schedule;
    final scheduleOn = task.scheduleOn;

    switch (schedule) {
      case 'daily':
        return _dailyDates(from, to);

      case 'weekly':
        if (scheduleOn == null) return [];
        final targetWeekday = _weekdayFromString(scheduleOn);
        return _weeklyDates(from, to, targetWeekday);

      case 'monthly':
        if (scheduleOn == null) return [];
        final dayNum = int.tryParse(scheduleOn) ?? 1;
        return _monthlyDates(from, to, dayNum);

      case 'yearly':
        if (scheduleOn == null) return [];
        final parts = scheduleOn.split('-');
        if (parts.length != 2) return [];
        final month = int.tryParse(parts[0]) ?? 1;
        final day   = int.tryParse(parts[1]) ?? 1;
        return _yearlyDates(from, to, month, day);

      case 'specific_date':
        if (scheduleOn == null) return [];
        final dt = DateTime.tryParse(scheduleOn);
        if (dt == null) return [];
        final midnight    = DateTime(dt.year, dt.month, dt.day);
        final fromMidnight = DateTime(from.year, from.month, from.day);
        final toMidnight  = DateTime(to.year, to.month, to.day);
        if (midnight.isAfter(toMidnight) || midnight.isBefore(fromMidnight)) return [];
        return [midnight.millisecondsSinceEpoch];

      default:
        return [];
    }
  }

  List<int> _dailyDates(DateTime from, DateTime to) {
    final result  = <int>[];
    var current   = DateTime(from.year, from.month, from.day);
    final end     = DateTime(to.year, to.month, to.day);
    while (!current.isAfter(end)) {
      result.add(current.millisecondsSinceEpoch);
      current = current.add(const Duration(days: 1));
    }
    return result;
  }

  List<int> _weeklyDates(DateTime from, DateTime to, int targetWeekday) {
    final result = <int>[];
    var current  = DateTime(from.year, from.month, from.day);
    while (current.weekday != targetWeekday) {
      current = current.add(const Duration(days: 1));
    }
    final end = DateTime(to.year, to.month, to.day);
    while (!current.isAfter(end)) {
      result.add(current.millisecondsSinceEpoch);
      current = current.add(const Duration(days: 7));
    }
    return result;
  }

  List<int> _monthlyDates(DateTime from, DateTime to, int dayNum) {
    final result = <int>[];
    var year     = from.year;
    var month    = from.month;
    while (true) {
      final candidate = DateTime(year, month, dayNum);
      if (candidate.isAfter(to)) break;
      if (!candidate.isBefore(from)) {
        result.add(candidate.millisecondsSinceEpoch);
      }
      month++;
      if (month > 12) { month = 1; year++; }
    }
    return result;
  }

  List<int> _yearlyDates(DateTime from, DateTime to, int month, int day) {
    final result = <int>[];
    for (var year = from.year; year <= to.year; year++) {
      final candidate = DateTime(year, month, day);
      if (!candidate.isBefore(from) && !candidate.isAfter(to)) {
        result.add(candidate.millisecondsSinceEpoch);
      }
    }
    return result;
  }

  int _weekdayFromString(String s) => switch (s.toLowerCase()) {
    'monday'    => DateTime.monday,
    'tuesday'   => DateTime.tuesday,
    'wednesday' => DateTime.wednesday,
    'thursday'  => DateTime.thursday,
    'friday'    => DateTime.friday,
    'saturday'  => DateTime.saturday,
    'sunday'    => DateTime.sunday,
    _           => DateTime.monday,
  };
}
