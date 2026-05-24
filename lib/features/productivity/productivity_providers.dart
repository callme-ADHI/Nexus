import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/providers.dart';
import '../../core/services/productivity_service.dart';

// ════════════════════════════════════════════════════════════════════════════
// PRODUCTIVITY PROVIDERS
// ════════════════════════════════════════════════════════════════════════════

/// Currently selected date for the productivity page
final productivityDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

int _midnightMs(DateTime d) => DateTime(d.year, d.month, d.day).millisecondsSinceEpoch;

/// Activities for the selected date (reactive stream)
final activitiesProvider = StreamProvider<List<ActivityLog>>((ref) {
  final db = ref.watch(databaseProvider);
  final date = ref.watch(productivityDateProvider);
  return db.watchActivitiesForDate(_midnightMs(date));
});

/// Sleep log for the selected date (reactive stream)
final sleepProvider = StreamProvider<SleepLog?>((ref) {
  final db = ref.watch(databaseProvider);
  final date = ref.watch(productivityDateProvider);
  return db.watchSleepForDate(_midnightMs(date));
});

/// Live productivity score for the selected date
final productivityScoreProvider = Provider<ProductivityScore>((ref) {
  final activitiesAsync = ref.watch(activitiesProvider);
  final sleepAsync = ref.watch(sleepProvider);

  final activities = activitiesAsync.valueOrNull ?? [];
  final sleep = sleepAsync.valueOrNull;

  if (activities.isEmpty && sleep == null) return ProductivityScore.empty();
  return ProductivityService.calculate(activities: activities, sleep: sleep);
});



/// Selected category in the log form
final selectedCategoryProvider = StateProvider<ActivityCategory?>((ref) => null);

/// Scores for a date range (for graphs, reactive stream)
final cachedScoresProvider = StreamProvider.family<List<ProductivityCache>, (int, int)>((ref, range) async* {
  final db = ref.watch(databaseProvider);
  _fillCacheAsync(db, range.$1, range.$2);
  yield* db.watchCachedScoresInRange(range.$1, range.$2);
});

void _fillCacheAsync(AppDatabase db, int startMs, int endMs) async {
  try {
    await ProductivityService.checkAndFillCacheRange(db, startMs, endMs);
  } catch (_) {}
}

/// Activities for a date range (for graphs, reactive stream)
final rangeActivitiesProvider = StreamProvider.family<List<ActivityLog>, (int, int)>((ref, range) {
  final db = ref.watch(databaseProvider);
  return db.watchActivitiesInRange(range.$1, range.$2);
});

/// Sleep logs for a date range (for graphs, reactive stream)
final rangeSleepProvider = StreamProvider.family<List<SleepLog>, (int, int)>((ref, range) {
  final db = ref.watch(databaseProvider);
  return db.watchSleepInRange(range.$1, range.$2);
});

