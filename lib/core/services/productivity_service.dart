import 'package:drift/drift.dart';
import 'package:flutter/material.dart' show Color, debugPrint;
import '../database/app_database.dart';
import 'widget_service.dart';

// ════════════════════════════════════════════════════════════════════════════
// ACTIVITY CATEGORIES
// ════════════════════════════════════════════════════════════════════════════

enum ActivityCategory {
  deepWork('deep_work', 'Deep Work', 1.00, 0xFF7C6AF7),
  exercise('exercise', 'Exercise', 0.95, 0xFF4ADE80),
  learning('learning', 'Learning', 0.90, 0xFF60A5FA),
  goalTasks('goal_tasks', 'Goal Tasks', 1.00, 0xFFA78BFA),
  social('social', 'Social', 0.70, 0xFFF59E0B),
  routine('routine', 'Routine', 0.60, 0xFF374151),
  leisure('leisure', 'Leisure', 0.40, 0xFF6B7280),
  sleep('sleep', 'Sleep', 0.85, 0xFF1E1B4B);

  final String key;
  final String label;
  final double qualityMultiplier;
  final int colorValue;

  const ActivityCategory(this.key, this.label, this.qualityMultiplier, this.colorValue);

  Color get color => Color(colorValue);

  static ActivityCategory fromKey(String key) =>
      ActivityCategory.values.firstWhere((c) => c.key == key, orElse: () => ActivityCategory.routine);
}

// ════════════════════════════════════════════════════════════════════════════
// SCORE RESULT
// ════════════════════════════════════════════════════════════════════════════

class ProductivityScore {
  final double total;          // 0–100
  final double coverageScore;  // 0–40
  final double qualityScore;   // 0–40
  final double sleepScore;     // 0–20
  final double coveragePct;    // 0–100% of day mapped
  final double? sleepHours;
  final String? topCategory;
  final String label;
  final Color labelColor;

  ProductivityScore({
    required this.total,
    required this.coverageScore,
    required this.qualityScore,
    required this.sleepScore,
    required this.coveragePct,
    this.sleepHours,
    this.topCategory,
    required this.label,
    required this.labelColor,
  });

  static ProductivityScore empty() => ProductivityScore(
    total: 0, coverageScore: 0, qualityScore: 0, sleepScore: 0,
    coveragePct: 0, label: '—', labelColor: const Color(0xFF555555),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// PRODUCTIVITY SERVICE — Score Calculation Engine
// ════════════════════════════════════════════════════════════════════════════

class ProductivityService {
  static const int _dayMinutes = 1440;

  // Score label thresholds
  static const _peakColor     = Color(0xFF9B6FF5); // violet-light
  static const _strongColor   = Color(0xFF4A90D9); // dark-blue-accent
  static const _solidColor    = Color(0xFF27AE60); // dark-green-accent
  static const _averageColor  = Color(0xFFF39C12); // amber
  static const _lightColor    = Color(0xB3F39C12); // amber 70%
  static const _lostColor     = Color(0xFFE74C3C); // dark-red-accent

  /// Calculate the full productivity score for a given day.
  static ProductivityScore calculate({
    required List<ActivityLog> activities,
    SleepLog? sleep,
    int completedTasksCount = 0,
    double? completedTasksPoints,
  }) {
    // ── Gather minutes per category ────────────────────────────────────
    final Map<String, int> categoryMinutes = {};
    int totalLoggedMinutes = 0;

    for (final a in activities) {
      final mins = ((a.endTime - a.startTime) / 60000).round().clamp(0, _dayMinutes);
      categoryMinutes[a.category] = (categoryMinutes[a.category] ?? 0) + mins;
      totalLoggedMinutes += mins;
    }

    // Add sleep minutes
    int sleepMinutes = 0;
    double? sleepHours;
    if (sleep != null) {
      sleepMinutes = ((sleep.wakeTime - sleep.sleepTime) / 60000).round().clamp(0, _dayMinutes);
      sleepHours = sleepMinutes / 60.0;
      categoryMinutes['sleep'] = (categoryMinutes['sleep'] ?? 0) + sleepMinutes;
      totalLoggedMinutes += sleepMinutes;
    } else {
      // Fallback: look for activity logs of category 'sleep'
      final sleepActivities = activities.where((a) => a.category == 'sleep');
      if (sleepActivities.isNotEmpty) {
        int totalSleepMins = 0;
        for (final sa in sleepActivities) {
          totalSleepMins += ((sa.endTime - sa.startTime) / 60000).round().clamp(0, _dayMinutes);
        }
        sleepMinutes = totalSleepMins.clamp(0, _dayMinutes);
        sleepHours = sleepMinutes / 60.0;
      }
    }

    // Cap at 1440
    totalLoggedMinutes = totalLoggedMinutes.clamp(0, _dayMinutes);

    // ── COMPONENT 1: Coverage (40%) ──────────────────────────────────
    final coverage = totalLoggedMinutes / _dayMinutes;
    final coverageScore = coverage * 40;

    // ── COMPONENT 2: Quality (40%) ───────────────────────────────────
    double weightedSum = 0;
    categoryMinutes.forEach((key, mins) {
      final cat = ActivityCategory.fromKey(key);
      weightedSum += mins * cat.qualityMultiplier;
    });
    final qualityScore = (weightedSum / _dayMinutes) * 40;

    // ── COMPONENT 3: Sleep (20%) ─────────────────────────────────────
    double sleepScoreVal = 0;
    if (sleepHours != null) {
      if (sleepHours >= 7.0 && sleepHours <= 9.0) {
        sleepScoreVal = 20;
      } else if ((sleepHours >= 6.0 && sleepHours < 7.0) || (sleepHours > 9.0 && sleepHours <= 10.0)) {
        sleepScoreVal = 14;
      } else if ((sleepHours >= 5.0 && sleepHours < 6.0) || (sleepHours > 10.0 && sleepHours <= 11.0)) {
        sleepScoreVal = 8;
      } else {
        sleepScoreVal = 2;
      }
    }

    final points = completedTasksPoints ?? (completedTasksCount * 5.0);
    final total = (coverageScore + qualityScore + sleepScoreVal + points).clamp(0.0, 100.0);

    // ── Top category ─────────────────────────────────────────────────
    String? topCat;
    int topMins = 0;
    categoryMinutes.forEach((key, mins) {
      if (mins > topMins) { topMins = mins; topCat = key; }
    });

    // ── Label ────────────────────────────────────────────────────────
    // Don't show score if < 2h logged
    if (totalLoggedMinutes < 120) {
      return ProductivityScore(
        total: total, coverageScore: coverageScore, qualityScore: qualityScore,
        sleepScore: sleepScoreVal, coveragePct: coverage * 100,
        sleepHours: sleepHours, topCategory: topCat,
        label: '—', labelColor: const Color(0xFF555555),
      );
    }

    final (label, color) = _labelForScore(total);

    return ProductivityScore(
      total: total, coverageScore: coverageScore, qualityScore: qualityScore,
      sleepScore: sleepScoreVal, coveragePct: coverage * 100,
      sleepHours: sleepHours, topCategory: topCat,
      label: label, labelColor: color,
    );
  }

  static (String, Color) _labelForScore(double score) {
    if (score >= 90) return ('Peak Day', _peakColor);
    if (score >= 75) return ('Strong Day', _strongColor);
    if (score >= 60) return ('Solid Day', _solidColor);
    if (score >= 45) return ('Average Day', _averageColor);
    if (score >= 30) return ('Light Day', _lightColor);
    return ('Lost Day', _lostColor);
  }

  static (String, Color) labelForScore(double score) => _labelForScore(score);

  /// Persist the calculated score to the cache.
  static Future<void> cacheScore(AppDatabase db, int dateMidnight, ProductivityScore score) async {
    await db.upsertCache(ProductivityCachesCompanion.insert(
      date: Value(dateMidnight),
      score: score.total,
      coveragePct: score.coveragePct,
      sleepHours: Value(score.sleepHours),
      topCategory: Value(score.topCategory),
      label: score.label,
      invalidated: const Value(0),
    ));
    
    try {
      final today = DateTime.now();
      final startDate = today.subtract(const Duration(days: 27)); // 28 days
      final rangeStart = DateTime(startDate.year, startDate.month, startDate.day).millisecondsSinceEpoch;
      final rangeEnd = DateTime(today.year, today.month, today.day).millisecondsSinceEpoch;
      final caches = await db.getCachedScoresInRange(rangeStart, rangeEnd);
      await WidgetService.updateProductivityWidget(caches);
    } catch (e) {
      debugPrint('Failed to update home widget: $e');
    }
  }

  /// Recalculate and cache if invalidated or missing.
  static Future<ProductivityScore> ensureScore(AppDatabase db, int dateMidnight) async {
    final cached = await db.getCachedScore(dateMidnight);
    if (cached != null && cached.invalidated == 0) {
      final (label, color) = _labelForScore(cached.score);
      return ProductivityScore(
        total: cached.score, coverageScore: cached.coveragePct * 0.4,
        qualityScore: 0, sleepScore: 0, // approx — full recalc not needed for display
        coveragePct: cached.coveragePct,
        sleepHours: cached.sleepHours, topCategory: cached.topCategory,
        label: label, labelColor: color,
      );
    }

    // Full recalculation
    final activities = await db.getActivitiesForDate(dateMidnight);
    final sleep = await db.getSleepForDate(dateMidnight);
    final completions = await db.getCompletionsForDate(dateMidnight);
    final tasks = await db.getAllTasks();
    final taskOfTheDayIds = tasks.where((t) => t.isTaskOfTheDay).map((t) => t.id).toSet();

    double completedTasksPoints = 0;
    int completedCount = 0;
    for (final c in completions) {
      if (c.completedDate == null) continue;
      final s = DateTime.fromMillisecondsSinceEpoch(c.scheduledDate);
      final comp = DateTime.fromMillisecondsSinceEpoch(c.completedDate!);
      final isSameDay = s.year == comp.year && s.month == comp.month && s.day == comp.day;
      if (isSameDay) {
        completedCount++;
        final isTotd = taskOfTheDayIds.contains(c.taskId);
        completedTasksPoints += isTotd ? 20.0 : 5.0;
      }
    }
    final score = calculate(
      activities: activities,
      sleep: sleep,
      completedTasksCount: completedCount,
      completedTasksPoints: completedTasksPoints,
    );
    await cacheScore(db, dateMidnight, score);
    return score;
  }

  /// Make sure all days in [startMs, endMs] have cached scores.
  static Future<void> checkAndFillCacheRange(AppDatabase db, int startMs, int endMs) async {
    final caches = await db.getCachedScoresInRange(startMs, endMs);
    final cacheMap = {for (final c in caches) c.date: c};

    final msPerDay = 86400000;
    for (int ms = startMs; ms <= endMs; ms += msPerDay) {
      final cached = cacheMap[ms];
      if (cached == null || cached.invalidated == 1) {
        await ensureScore(db, ms);
      }
    }
  }
}

