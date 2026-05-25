
import '../database/app_database.dart';
import '../models/models.dart';

/// Evaluates and updates goal statuses.
/// Holds an in-memory dependency graph.
class StatusService {
  // Cache: goalId → list of ids it depends on
  Map<String, List<String>> _depGraph = {};

  void buildGraph(List<Goal> goals, List<GoalDependency> deps) {
    _depGraph = {};
    for (final g in goals) {
      _depGraph[g.id] = [];
    }
    for (final d in deps) {
      _depGraph[d.goalId] ??= [];
      _depGraph[d.goalId]!.add(d.dependsOnId);
    }
  }

  GoalStatus evaluateStatus({
    required Goal goal,
    required Map<String, Goal> allGoalsMap,
    required double effectiveProgress,
    required List<TaskCompletion> completions,
  }) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // 1. Completed always wins — even if past deadline
    if (goal.status == 'completed') return GoalStatus.completed;

    // 2. Overdue: past deadline and not completed
    if (nowMs > goal.deadline) return GoalStatus.overdue;

    // 3. Blocked: has at least one incomplete dependency
    final deps = _depGraph[goal.id] ?? [];
    final isBlocked = deps.any((depId) {
      final dep = allGoalsMap[depId];
      return dep != null && dep.status != 'completed';
    });
    if (isBlocked) return GoalStatus.blocked;

    // 4. Not Started: startDate is in the future (goal not kicked off yet)
    //    e.g. imported with a future start_date, or just unlocked today.
    final sd = goal.startDate;
    if (sd != null && sd > nowMs) return GoalStatus.notStarted;

    // 5. Pending: Goal has started, but has missed tasks.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayMs = today.millisecondsSinceEpoch;
    final hasMissedTasks = completions.any((c) =>
        c.scheduledDate < todayMs && c.completedDate == null);
    if (hasMissedTasks) return GoalStatus.pending;

    // 6. Active vs Not Started based on actual task completion progress
    if (effectiveProgress > 0) return GoalStatus.inProgress;
    return GoalStatus.notStarted;
  }

  /// Check for circular dependency before adding
  /// Returns true if adding goalId → dependsOnId would create a cycle
  bool wouldCreateCycle({
    required String goalId,
    required String dependsOnId,
    required Map<String, List<String>> currentDeps,
  }) {
    if (goalId == dependsOnId) return true;

    // DFS from dependsOnId; if we reach goalId, it's a cycle
    final visited = <String>{};
    final stack = [dependsOnId];

    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      if (current == goalId) return true;
      if (visited.contains(current)) continue;
      visited.add(current);
      final nextDeps = currentDeps[current] ?? [];
      stack.addAll(nextDeps);
    }

    return false;
  }

  /// Returns the path that creates the cycle (for error message)
  List<String> findCyclePath({
    required String goalId,
    required String dependsOnId,
    required Map<String, List<String>> currentDeps,
  }) {
    final path = <String>[];
    final visited = <String>{};

    bool dfs(String node, List<String> currentPath) {
      if (node == goalId) {
        path.addAll(currentPath);
        path.add(goalId);
        return true;
      }
      if (visited.contains(node)) return false;
      visited.add(node);
      currentPath.add(node);
      for (final next in currentDeps[node] ?? []) {
        if (dfs(next, currentPath)) return true;
      }
      currentPath.removeLast();
      return false;
    }

    dfs(dependsOnId, []);
    return path;
  }
}
