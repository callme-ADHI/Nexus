import 'dart:async';
import 'package:usage_stats/usage_stats.dart';

class ActivityService {
  static Future<bool> isPermissionGranted() async {
    bool? isGranted = await UsageStats.checkUsagePermission();
    return isGranted ?? false;
  }

  static Future<void> grantPermission() async {
    await UsageStats.grantUsagePermission();
  }

  static Future<UsageData> fetchDailyStats(DateTime date) async {
    DateTime start = DateTime(date.year, date.month, date.day);
    DateTime end = start.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
    
    // If querying today, end at now
    if (date.year == DateTime.now().year && 
        date.month == DateTime.now().month && 
        date.day == DateTime.now().day) {
      end = DateTime.now();
    }

    // Fetch usage stats (aggregate time per app)
    List<UsageInfo> usageStats = await UsageStats.queryUsageStats(start, end);
    
    // Fetch events (for precise screen time and unlocks)
    List<EventUsageInfo> events = await UsageStats.queryEvents(start, end);

    return _processStats(usageStats, events, start, end);
  }

  static UsageData _processStats(
    List<UsageInfo> usageStats,
    List<EventUsageInfo> events,
    DateTime start,
    DateTime end,
  ) {
    int totalScreenTimeMs = 0;
    int unlockCount = 0;
    Map<String, int> appTimeMap = {};

    // 1. Process UsageStats (App aggregate time)
    // Note: Android's aggregate stats can be slightly inaccurate or delayed.
    for (var info in usageStats) {
      int time = int.tryParse(info.totalTimeInForeground ?? '0') ?? 0;
      if (time > 0) {
        appTimeMap[info.packageName ?? 'unknown'] = time;
      }
    }

    // 2. Process Events for Screen Time and Unlocks
    // Event types:
    // 1: MOVE_TO_FOREGROUND
    // 2: MOVE_TO_BACKGROUND
    // 15: SCREEN_INTERACTIVE
    // 16: SCREEN_NON_INTERACTIVE
    // 18: KEYGUARD_DISMISSED (Unlock)

    int? lastScreenOn;
    
    // Sort events by timestamp just in case
    events.sort((a, b) => (int.tryParse(a.timeStamp ?? '0') ?? 0)
        .compareTo(int.tryParse(b.timeStamp ?? '0') ?? 0));

    for (var event in events) {
      int ts = int.tryParse(event.timeStamp ?? '0') ?? 0;
      int type = int.tryParse(event.eventType ?? '0') ?? 0;

      if (type == 15) { // SCREEN_INTERACTIVE
        lastScreenOn = ts;
      } else if (type == 16) { // SCREEN_NON_INTERACTIVE
        if (lastScreenOn != null) {
          totalScreenTimeMs += (ts - lastScreenOn);
          lastScreenOn = null;
        }
      } else if (type == 18 || (type == 15 && lastScreenOn != null)) {
        // Approximate unlock if we see KEYGUARD_DISMISSED or SCREEN_INTERACTIVE
        if (type == 18) unlockCount++;
      }
    }

    // Handle case where screen is currently on
    if (lastScreenOn != null) {
      totalScreenTimeMs += (end.millisecondsSinceEpoch - lastScreenOn);
    }

    // Fallback: If totalScreenTimeMs is 0 but we have app times, use sum of app times as floor
    int sumAppTimes = appTimeMap.values.fold(0, (a, b) => a + b);
    if (totalScreenTimeMs < sumAppTimes) {
      totalScreenTimeMs = sumAppTimes;
    }

    return UsageData(
      totalScreenTimeMs: totalScreenTimeMs,
      unlockCount: unlockCount,
      appUsage: appTimeMap,
      events: events,
    );
  }
}

class UsageData {
  final int totalScreenTimeMs;
  final int unlockCount;
  final Map<String, int> appUsage;
  final List<EventUsageInfo> events;

  UsageData({
    required this.totalScreenTimeMs,
    required this.unlockCount,
    required this.appUsage,
    required this.events,
  });
}
