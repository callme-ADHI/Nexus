import 'package:yaml/yaml.dart';

import '../models/models.dart';
import '../database/app_database.dart';

class YamlParser {
  final AppDatabase db;
  YamlParser(this.db);

  Future<YamlImportResult> parse(String yamlText) async {
    final errors = <String>[];
    final validGoals = <YamlGoalData>[];
    final conflictGoals = <YamlGoalData>[];

    List<YamlDocument> documents;
    try {
      documents = loadYamlDocuments(yamlText);
    } catch (e) {
      return YamlImportResult(
        validGoals: [], conflictGoals: [],
        errors: ['YAML parse error: $e'],
      );
    }

    final mergedGoalsYaml = [];
    final mergedActivityLogsYaml = [];
    final mergedSleepLogsYaml = [];

    for (final document in documents) {
      final doc = document.contents.value;
      if (doc is! Map) {
        errors.add('A document root must be a YAML map.');
        continue;
      }

      // Check version
      final version = doc['version']?.toString();
      if (version != '1.0' && version != '1.1') {
        errors.add('version must be "1.0" or "1.1". Got: $version');
      }

      final goals = doc['goals'];
      if (goals != null && goals is List) {
        mergedGoalsYaml.addAll(goals);
      }

      final activityLogs = doc['activity_logs'];
      if (activityLogs != null && activityLogs is List) {
        mergedActivityLogsYaml.addAll(activityLogs);
      }

      final sleepLogs = doc['sleep_logs'];
      if (sleepLogs != null && sleepLogs is List) {
        mergedSleepLogsYaml.addAll(sleepLogs);
      }
    }

    final goalsYaml = mergedGoalsYaml;
    final activityLogsYaml = mergedActivityLogsYaml;
    final sleepLogsYaml = mergedSleepLogsYaml;

    final hasGoals = goalsYaml.isNotEmpty;
    final hasActivity = activityLogsYaml.isNotEmpty;
    final hasSleep = sleepLogsYaml.isNotEmpty;

    if (!hasGoals && !hasActivity && !hasSleep) {
      return YamlImportResult(
        validGoals: [], conflictGoals: [],
        errors: [...errors, 'No goals, activity_logs, or sleep_logs lists found.'],
      );
    }

    // ── PASS 1: collect all ids in file ──────────────────────────────────
    final fileIds = <String>{};
    if (hasGoals) {
      for (final raw in goalsYaml) {
        if (raw is Map) {
          final id = raw['id']?.toString();
          if (id != null) fileIds.add(id);
        }
      }
    }

    // Load existing DB ids
    final existingGoals = await db.getAllGoals();
    final existingIds = {for (final g in existingGoals) g.id};
    final knownIds = fileIds.union(existingIds);

    // Also build a dep map from file for cycle detection
    final fileDepsMap = <String, List<String>>{};
    if (hasGoals) {
      for (final raw in goalsYaml) {
        if (raw is Map) {
          final id = raw['id']?.toString() ?? '';
          final deps = _stringList(raw['depends_on']);
          fileDepsMap[id] = deps;
        }
      }
    }

    // ── PASS 2: validate each goal ────────────────────────────────────────
    final seenIds = <String>{};

    if (hasGoals) {
      for (final raw in goalsYaml) {
        if (raw is! Map) continue;

        final goalErrors = <String>[];

        // ID
        final id = raw['id']?.toString() ?? '';
        if (id.isEmpty) {
          goalErrors.add('A goal is missing the required "id" field.');
          errors.addAll(goalErrors);
          continue;
        }
        if (!RegExp(r'^[a-z0-9_]+$').hasMatch(id)) {
          goalErrors.add(
            'Goal id "$id" is invalid. Use only lowercase letters, numbers, and underscores.',
          );
        }
        if (seenIds.contains(id)) {
          goalErrors.add('Duplicate goal id "$id" in import file.');
        }
        seenIds.add(id);

        // Name
        final name = raw['name']?.toString();
        if (name == null || name.isEmpty) {
          goalErrors.add("Goal '$id': field 'name' is required.");
        }

        // Timeframe
        final timeframe = raw['timeframe']?.toString();
        if (timeframe == null ||
            !{'day', 'week', 'month', 'year'}.contains(timeframe)) {
          goalErrors.add(
              "Goal '$id': timeframe must be one of: day, week, month, year.");
        }

        // Deadline
        final deadlineStr = raw['deadline']?.toString();
        DateTime? deadline;
        if (deadlineStr == null) {
          goalErrors.add("Goal '$id': field 'deadline' is required.");
        } else {
          deadline = DateTime.tryParse(deadlineStr);
          if (deadline == null) {
            goalErrors.add(
                "Goal '$id': deadline '$deadlineStr' is not a valid date.");
          } else if (deadline.isBefore(
              DateTime.now().subtract(const Duration(days: 1)))) {
            goalErrors.add(
                "Goal '$id' has a deadline in the past ($deadlineStr). Update the deadline or import will skip this goal.");
          }
        }

        // start_date (optional)
        final startDateStr = raw['start_date']?.toString();
        DateTime? startDate;
        if (startDateStr != null && startDateStr.isNotEmpty) {
          startDate = DateTime.tryParse(startDateStr);
          if (startDate == null) {
            goalErrors.add(
                "Goal '$id': start_date '$startDateStr' is not a valid date (use YYYY-MM-DD).");
          } else if (deadline != null && startDate.isAfter(deadline)) {
            goalErrors.add(
                "Goal '$id': start_date '$startDateStr' cannot be after the deadline '$deadlineStr'.");
            startDate = null;
          }
        }

        // Weight
        final weightRaw = raw['weight'];
        int weight = 1;
        if (weightRaw != null) {
          weight = weightRaw is int ? weightRaw : int.tryParse(weightRaw.toString()) ?? -1;
          if (weight < 1 || weight > 10) {
            goalErrors.add("Goal '$id': weight must be an integer from 1 to 10.");
            weight = 1;
          }
        }

        // Parent
        final parent = raw['parent']?.toString();
        if (parent != null && !knownIds.contains(parent)) {
          goalErrors.add(
              "Goal '$id': parent '$parent' was not found in this file or your existing goals.");
        }

        // depends_on
        final dependsOn = _stringList(raw['depends_on']);
        for (final dep in dependsOn) {
          if (!knownIds.contains(dep)) {
            goalErrors.add(
                "Goal '$id' depends on '$dep', which was not found in this file or your existing goals.");
          }
          if (dep == id) {
            goalErrors.add("Goal '$id' cannot depend on itself.");
          }
        }

        // Cycle detection using existing db graph merged with file
        final mergedDeps = Map<String, List<String>>.from(fileDepsMap);
        for (final g in existingGoals) {
          // only add if not in file
          if (!fileIds.contains(g.id)) {
            mergedDeps[g.id] = [];
          }
        }
        final existingDbDeps = await db.getAllDependencies();
        for (final d in existingDbDeps) {
          if (!fileIds.contains(d.goalId)) {
            mergedDeps[d.goalId] ??= [];
            mergedDeps[d.goalId]!.add(d.dependsOnId);
          }
        }

        for (final dep in dependsOn) {
          if (_wouldCreateCycle(id, dep, mergedDeps)) {
            goalErrors.add("Circular dependency detected: $id → $dep → $id.");
          }
        }

        // Parse tasks
        final tasksYaml = raw['tasks'];
        final parsedTasks = <YamlTaskData>[];
        if (tasksYaml is List) {
          for (final t in tasksYaml) {
            if (t is! Map) continue;
            final tName = t['name']?.toString() ?? '';
            final schedule = t['schedule']?.toString() ?? '';
            final validSchedules = {
              'daily', 'weekly', 'monthly', 'yearly', 'specific_date'
            };
            if (!validSchedules.contains(schedule)) {
              goalErrors.add(
                  "Task '$tName' in goal '$id': schedule '$schedule' is not valid.");
              continue;
            }

            final on = t['on']?.toString();

            // Validate 'on' field
            if (schedule == 'weekly' && (on == null || on.isEmpty)) {
              goalErrors.add(
                  "Task '$tName' in goal '$id': schedule 'weekly' requires an 'on' field with a day name.");
            }
            if (schedule == 'monthly' &&
                (on == null ||
                    (int.tryParse(on) ?? 0) < 1 ||
                    (int.tryParse(on) ?? 0) > 28)) {
              goalErrors.add(
                  "Task '$tName' in goal '$id': 'on' must be a number between 1 and 28.");
            }
            if (schedule == 'yearly' && on != null && on == '02-29') {
              goalErrors.add(
                  "Task '$tName': '02-29' is not supported. Use '02-28'.");
            }

            final reminder = t['reminder']?.toString() ?? '';
            if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(reminder)) {
              goalErrors.add(
                  "Task '$tName': reminder '$reminder' must be in HH:MM format (24-hour).");
            }

            final active = t['active'] is bool ? t['active'] as bool : true;

            parsedTasks.add(YamlTaskData(
              name: tName,
              schedule: schedule,
              on: on,
              reminder: reminder,
              active: active,
            ));
          }
        }

        if (goalErrors.isNotEmpty) {
          errors.addAll(goalErrors);
          continue;
        }

        final hasStrictDeadline = raw['has_strict_deadline'] is bool ? raw['has_strict_deadline'] as bool : false;

        final goalData = YamlGoalData(
          id: id,
          name: name!,
          aim: raw['aim']?.toString(),
          timeframe: timeframe!,
          deadline: deadlineStr!,
          weight: weight,
          parent: parent,
          dependsOn: dependsOn,
          tasks: parsedTasks,
          startDate: startDate,
          hasStrictDeadline: hasStrictDeadline,
        );

        if (existingIds.contains(id)) {
          conflictGoals.add(goalData);
        } else {
          validGoals.add(goalData);
        }
      }
    }

    final parsedActivityLogs = <YamlActivityLogData>[];
    if (hasActivity) {
      for (final raw in activityLogsYaml) {
        if (raw is! Map) continue;
        final rawDate = raw['date'] is int ? raw['date'] as int : int.tryParse(raw['date']?.toString() ?? '');
        final category = raw['category']?.toString();
        final name = raw['name']?.toString();
        final startTime = raw['start_time'] is int ? raw['start_time'] as int : int.tryParse(raw['start_time']?.toString() ?? '');
        final endTime = raw['end_time'] is int ? raw['end_time'] as int : int.tryParse(raw['end_time']?.toString() ?? '');
        final notes = raw['notes']?.toString();
        final isAuto = raw['is_auto'] is bool ? raw['is_auto'] as bool : false;
        final createdAt = raw['created_at'] is int ? raw['created_at'] as int : int.tryParse(raw['created_at']?.toString() ?? '') ?? DateTime.now().millisecondsSinceEpoch;

        if (rawDate == null || category == null || name == null || startTime == null || endTime == null) {
          errors.add('Activity log missing required fields.');
          continue;
        }

        // Normalize midnight to device local midnight
        final dt = DateTime.fromMillisecondsSinceEpoch(rawDate);
        final date = DateTime(dt.year, dt.month, dt.day).millisecondsSinceEpoch;

        parsedActivityLogs.add(YamlActivityLogData(
          date: date,
          category: category,
          name: name,
          startTime: startTime,
          endTime: endTime,
          notes: notes,
          isAuto: isAuto,
          createdAt: createdAt,
        ));
      }
    }

    final parsedSleepLogs = <YamlSleepLogData>[];
    if (hasSleep) {
      for (final raw in sleepLogsYaml) {
        if (raw is! Map) continue;
        final rawDate = raw['date'] is int ? raw['date'] as int : int.tryParse(raw['date']?.toString() ?? '');
        final sleepTime = raw['sleep_time'] is int ? raw['sleep_time'] as int : int.tryParse(raw['sleep_time']?.toString() ?? '');
        final wakeTime = raw['wake_time'] is int ? raw['wake_time'] as int : int.tryParse(raw['wake_time']?.toString() ?? '');
        final qualityNote = raw['quality_note']?.toString();
        final createdAt = raw['created_at'] is int ? raw['created_at'] as int : int.tryParse(raw['created_at']?.toString() ?? '') ?? DateTime.now().millisecondsSinceEpoch;

        if (rawDate == null || sleepTime == null || wakeTime == null) {
          errors.add('Sleep log missing required fields.');
          continue;
        }

        // Normalize midnight to device local midnight
        final dt = DateTime.fromMillisecondsSinceEpoch(rawDate);
        final date = DateTime(dt.year, dt.month, dt.day).millisecondsSinceEpoch;

        parsedSleepLogs.add(YamlSleepLogData(
          date: date,
          sleepTime: sleepTime,
          wakeTime: wakeTime,
          qualityNote: qualityNote,
          createdAt: createdAt,
        ));
      }
    }

    return YamlImportResult(
      validGoals: validGoals,
      conflictGoals: conflictGoals,
      activityLogs: parsedActivityLogs,
      sleepLogs: parsedSleepLogs,
      errors: errors,
    );
  }

  bool _wouldCreateCycle(
    String goalId,
    String dependsOnId,
    Map<String, List<String>> deps,
  ) {
    if (goalId == dependsOnId) return true;
    final visited = <String>{};
    final stack = [dependsOnId];
    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      if (current == goalId) return true;
      if (visited.contains(current)) continue;
      visited.add(current);
      stack.addAll(deps[current] ?? []);
    }
    return false;
  }

  List<String> _stringList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return [];
  }
}
