// Models used throughout the app (beyond the Drift-generated DataClass types)

enum GoalStatus {
  blocked,
  notStarted,
  inProgress,
  completed,
  overdue;

  static GoalStatus fromString(String s) => switch (s) {
    'blocked'     => blocked,
    'not_started' => notStarted,
    'in_progress' => inProgress,
    'completed'   => completed,
    'overdue'     => overdue,
    _             => notStarted,
  };

  String toDb() => switch (this) {
    blocked    => 'blocked',
    notStarted => 'not_started',
    inProgress => 'in_progress',
    completed  => 'completed',
    overdue    => 'overdue',
  };
}

enum TaskSchedule {
  daily,
  weekly,
  monthly,
  yearly,
  specificDate;

  static TaskSchedule fromString(String s) => switch (s) {
    'daily'         => daily,
    'weekly'        => weekly,
    'monthly'       => monthly,
    'yearly'        => yearly,
    'specific_date' => specificDate,
    _               => daily,
  };

  String toDb() => switch (this) {
    daily        => 'daily',
    weekly       => 'weekly',
    monthly      => 'monthly',
    yearly       => 'yearly',
    specificDate => 'specific_date',
  };

  String label() => switch (this) {
    daily        => 'Daily',
    weekly       => 'Weekly',
    monthly      => 'Monthly',
    yearly       => 'Yearly',
    specificDate => 'Once',
  };
}

/// Rich goal model with computed fields (not stored in DB)
class GoalWithProgress {
  final dynamic goal; // Goal from DB
  final double effectiveProgress; // 0–100
  final double chainProgress;     // 0–100 (DAG display only)
  final GoalStatus status;
  final double timeElapsedPct;    // 0–100
  final bool hasTimeWarning;
  final List<GoalWithProgress> subGoals;
  final List<String> dependsOnIds;

  const GoalWithProgress({
    required this.goal,
    required this.effectiveProgress,
    required this.chainProgress,
    required this.status,
    required this.timeElapsedPct,
    required this.hasTimeWarning,
    this.subGoals = const [],
    this.dependsOnIds = const [],
  });
}

/// Rich task model with completion state
class TaskWithCompletion {
  final dynamic task; // Task from DB
  final dynamic todayCompletion; // TaskCompletion? from DB
  final bool isCompletedToday;
  final bool isMissedToday;
  final int currentStreak;
  final int bestStreak;

  const TaskWithCompletion({
    required this.task,
    this.todayCompletion,
    required this.isCompletedToday,
    required this.isMissedToday,
    this.currentStreak = 0,
    this.bestStreak = 0,
  });
}

/// YAML import result
class YamlImportResult {
  final List<YamlGoalData> validGoals;
  final List<YamlGoalData> conflictGoals; // ids already in DB
  final List<YamlActivityLogData> activityLogs;
  final List<YamlSleepLogData> sleepLogs;
  final List<String> errors;

  const YamlImportResult({
    required this.validGoals,
    required this.conflictGoals,
    this.activityLogs = const [],
    this.sleepLogs = const [],
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasConflicts => conflictGoals.isNotEmpty;
}

class YamlGoalData {
  final String id;
  final String name;
  final String? aim;
  final String timeframe;
  final String deadline;
  final int weight;
  final String? parent;
  final List<String> dependsOn;
  final List<YamlTaskData> tasks;
  /// Optional YAML-specified start date. Null means "start immediately on import."
  /// For blocked goals this is ignored — startDate is set when dependency completes.
  final DateTime? startDate;
  // For conflict resolution
  bool skipOnConflict = false;

  YamlGoalData({
    required this.id,
    required this.name,
    this.aim,
    required this.timeframe,
    required this.deadline,
    required this.weight,
    this.parent,
    required this.dependsOn,
    required this.tasks,
    this.startDate,
  });
}

class YamlTaskData {
  final String name;
  final String schedule;
  final String? on;
  final String reminder;
  final bool active;

  const YamlTaskData({
    required this.name,
    required this.schedule,
    this.on,
    required this.reminder,
    this.active = true,
  });
}

class YamlActivityLogData {
  final int date;
  final String category;
  final String name;
  final int startTime;
  final int endTime;
  final String? notes;
  final bool isAuto;
  final int createdAt;

  const YamlActivityLogData({
    required this.date,
    required this.category,
    required this.name,
    required this.startTime,
    required this.endTime,
    this.notes,
    this.isAuto = false,
    required this.createdAt,
  });
}

class YamlSleepLogData {
  final int date;
  final int sleepTime;
  final int wakeTime;
  final String? qualityNote;
  final int createdAt;

  const YamlSleepLogData({
    required this.date,
    required this.sleepTime,
    required this.wakeTime,
    this.qualityNote,
    required this.createdAt,
  });
}
