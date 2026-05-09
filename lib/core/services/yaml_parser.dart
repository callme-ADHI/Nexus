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

    dynamic doc;
    try {
      doc = loadYaml(yamlText);
    } catch (e) {
      return YamlImportResult(
        validGoals: [], conflictGoals: [],
        errors: ['YAML parse error: $e'],
      );
    }

    if (doc is! Map) {
      return YamlImportResult(
        validGoals: [], conflictGoals: [],
        errors: ['Root must be a YAML map.'],
      );
    }

    // Check version
    final version = doc['version']?.toString();
    if (version != '1.0') {
      errors.add('version must be "1.0". Got: $version');
    }

    final goalsYaml = doc['goals'];
    if (goalsYaml == null || goalsYaml is! List) {
      return YamlImportResult(
        validGoals: [], conflictGoals: [],
        errors: [...errors, 'No "goals" list found.'],
      );
    }

    // ── PASS 1: collect all ids in file ──────────────────────────────────
    final fileIds = <String>{};
    for (final raw in goalsYaml) {
      if (raw is Map) {
        final id = raw['id']?.toString();
        if (id != null) fileIds.add(id);
      }
    }

    // Load existing DB ids
    final existingGoals = await db.getAllGoals();
    final existingIds = {for (final g in existingGoals) g.id};
    final knownIds = fileIds.union(existingIds);

    // Also build a dep map from file for cycle detection
    final fileDepsMap = <String, List<String>>{};
    for (final raw in goalsYaml) {
      if (raw is Map) {
        final id = raw['id']?.toString() ?? '';
        final deps = _stringList(raw['depends_on']);
        fileDepsMap[id] = deps;
      }
    }

    // ── PASS 2: validate each goal ────────────────────────────────────────
    final seenIds = <String>{};

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
      );

      if (existingIds.contains(id)) {
        conflictGoals.add(goalData);
      } else {
        validGoals.add(goalData);
      }
    }

    return YamlImportResult(
      validGoals: validGoals,
      conflictGoals: conflictGoals,
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
