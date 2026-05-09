import 'package:drift/drift.dart' show Value;

import '../database/app_database.dart';

/// Generates TaskCompletion records for the 30-day rolling window.
class SchedulingService {
  final AppDatabase db;
  SchedulingService(this.db);

  /// Call on app launch and when tasks are created/modified.
  Future<void> generateCompletionWindow() async {
    final tasks = await db.getAllTasks();
    final now = DateTime.now();
    final windowEnd = now.add(const Duration(days: 30));

    for (final task in tasks) {
      if (task.isActive == 0) continue;
      final dates = _scheduledDates(task, now, windowEnd);
      for (final date in dates) {
        await db.upsertCompletion(TaskCompletionsCompanion(
          taskId: Value(task.id),
          scheduledDate: Value(date),
        ));
      }
    }
  }

  /// Returns list of midnight timestamps for a task in [from, to]
  List<int> _scheduledDates(Task task, DateTime from, DateTime to) {
    final schedule = task.schedule;
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
        final day = int.tryParse(parts[1]) ?? 1;
        return _yearlyDates(from, to, month, day);

      case 'specific_date':
        if (scheduleOn == null) return [];
        final dt = DateTime.tryParse(scheduleOn);
        if (dt == null) return [];
        final midnight = DateTime(dt.year, dt.month, dt.day);
        if (midnight.isAfter(to) || midnight.isBefore(from)) return [];
        return [midnight.millisecondsSinceEpoch];

      default:
        return [];
    }
  }

  List<int> _dailyDates(DateTime from, DateTime to) {
    final result = <int>[];
    var current = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    while (!current.isAfter(end)) {
      result.add(current.millisecondsSinceEpoch);
      current = current.add(const Duration(days: 1));
    }
    return result;
  }

  List<int> _weeklyDates(DateTime from, DateTime to, int targetWeekday) {
    final result = <int>[];
    var current = DateTime(from.year, from.month, from.day);
    // Find next occurrence of targetWeekday
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
    var year = from.year;
    var month = from.month;

    while (true) {
      final candidate = DateTime(year, month, dayNum);
      if (candidate.isAfter(to)) break;
      if (!candidate.isBefore(from)) {
        result.add(candidate.millisecondsSinceEpoch);
      }
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
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
