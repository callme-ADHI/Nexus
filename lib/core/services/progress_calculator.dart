import '../database/app_database.dart';

/// Pure functions for calculating goal progress.
/// NEVER reads/writes the database — takes pre-fetched data.
abstract final class ProgressCalculator {
  // ─────────────────────────────────────────────────────────────────────────
  // STEP 1 — Individual goal task progress
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns 0–100.
  static double taskProgress({
    required Goal goal,
    required List<TaskCompletion> completions,
  }) {
    if (goal.status == 'completed') return 100.0;

    final todayMidnight = _todayMidnight();
    final dueSoFar = completions
        .where((c) => c.scheduledDate <= todayMidnight)
        .toList();

    if (dueSoFar.isEmpty) return 0.0;

    final completedCount =
        dueSoFar.where((c) => c.completedDate != null).length;
    return (completedCount / dueSoFar.length) * 100.0;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 2 — Weighted aggregate for goals with sub-goals
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns 0–100. [selfTaskProgress] is from Step 1.
  static double effectiveProgress({
    required Goal goal,
    required double selfTaskProgress,
    required List<({Goal goal, double progress})> subGoals,
  }) {
    if (goal.status == 'completed') return 100.0;

    if (subGoals.isEmpty) {
      return selfTaskProgress;
    }

    // Has both sub-goals and (potentially) direct tasks.
    double numerator = 0;
    double denominator = 0;

    for (final sg in subGoals) {
      numerator += sg.goal.weight * sg.progress;
      denominator += sg.goal.weight;
    }

    // Self task contribution uses the goal's own weight
    numerator += goal.weight * selfTaskProgress;
    denominator += goal.weight;

    if (denominator == 0) return 0.0;
    return numerator / denominator;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 3 — Chain progress (for DAG display only)
  // ─────────────────────────────────────────────────────────────────────────

  static double chainProgress({
    required Goal goal,
    required double ownEffectiveProgress,
    required List<({Goal goal, double effectiveProgress})> dependencies,
  }) {
    if (dependencies.isEmpty) return ownEffectiveProgress;

    double numerator = 0;
    double denominator = 0;

    for (final dep in dependencies) {
      numerator += dep.goal.weight * dep.effectiveProgress;
      denominator += dep.goal.weight;
    }

    numerator += goal.weight * ownEffectiveProgress;
    denominator += goal.weight;

    if (denominator == 0) return ownEffectiveProgress;
    return numerator / denominator;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 4 — Time warning
  // ─────────────────────────────────────────────────────────────────────────

  static double timeElapsedPct(Goal goal) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final created = goal.createdAt;
    final deadline = goal.deadline;

    if (deadline <= created) return 100.0; // edge case

    final pct = (now - created) / (deadline - created) * 100.0;
    return pct.clamp(0.0, 100.0);
  }

  static bool hasTimeWarning(double timeElapsed, double effectiveProg) {
    return timeElapsed > (effectiveProg + 15);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STREAK CALCULATION
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns {current, best} streaks for a daily task.
  static ({int current, int best}) streaks(List<TaskCompletion> completions) {
    if (completions.isEmpty) return (current: 0, best: 0);

    // Sort by scheduled_date ascending
    final sorted = List.of(completions)
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

    int current = 0;
    int best = 0;
    int run = 0;

    // Walk backward from today
    final todayMs = _todayMidnight();
    final dayMs = const Duration(days: 1).inMilliseconds;

    // Build a set of dates that have completions
    final completedDates = <int>{};
    for (final c in sorted) {
      if (c.completedDate != null) completedDates.add(c.scheduledDate);
    }

    // Count current streak from today backward
    int check = todayMs;
    while (completedDates.contains(check)) {
      current++;
      check -= dayMs;
    }

    // Count best streak overall
    int? prevDate;
    for (final c in sorted) {
      if (c.completedDate != null) {
        if (prevDate == null || c.scheduledDate - prevDate == dayMs) {
          run++;
        } else {
          run = 1;
        }
        if (run > best) best = run;
        prevDate = c.scheduledDate;
      } else {
        run = 0;
        prevDate = c.scheduledDate;
      }
    }

    return (current: current, best: best);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  static int _todayMidnight() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
  }
}
