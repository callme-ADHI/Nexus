import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../database/app_database.dart';

// ════════════════════════════════════════════════════════════════════════════
// NOTIFICATION SERVICE
//
//   ALL tasks:
//     - On the scheduled date @ assigned time (task.reminderTime)
//     - On the scheduled date @ 20:00 (8 PM) → Follow-up IF assigned time < 20:00
//
//   GOAL deadline:
//     - 3 days before deadline @ 09:00 → "Goal deadline: [Goal] — 3 days left"
//
// Note: We use the completion window (TaskCompletion table) to determine
// whether a task was completed or not. The evening follow-ups are scheduled
// unconditionally, but the user can dismiss them if already done.
// ════════════════════════════════════════════════════════════════════════════

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // ─── CHANNELS ─────────────────────────────────────────────────────────────

  static const _chDailyMorning = AndroidNotificationChannel(
    'daily_morning', 'Daily Task — Morning',
    description: '6:00 AM reminder for daily tasks',
    importance: Importance.high,
  );

  static const _chDailyEvening = AndroidNotificationChannel(
    'daily_evening', 'Daily Task — Evening Follow-up',
    description: '8:00 PM evening follow-up for incomplete daily tasks',
    importance: Importance.defaultImportance,
  );

  static const _chWeeklyStart = AndroidNotificationChannel(
    'weekly_start', 'Weekly Task — Monday',
    description: 'Monday morning reminder for weekly tasks',
    importance: Importance.high,
  );

  static const _chWeeklySat = AndroidNotificationChannel(
    'weekly_saturday', 'Weekly Task — Saturday Follow-up',
    description: 'Saturday follow-up for incomplete weekly tasks',
    importance: Importance.defaultImportance,
  );

  static const _chDeadline = AndroidNotificationChannel(
    'deadline_warning', 'Deadline Warning',
    description: 'Goal approaching deadline — 3 days left',
    importance: Importance.high,
  );

  // ─── INIT ─────────────────────────────────────────────────────────────────

  static Future<void> initialize() async {
    if (_initialized) return;

    // Use Future.microtask or yield to avoid blocking UI immediately on boot
    await Future.delayed(const Duration(milliseconds: 100));
    
    tz_data.initializeTimeZones();
    try {
      final tzName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    _initialized = true;
  }

  static Future<void> requestPermissions() async {
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {}
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (_) {}
  }

  // ─── RESCHEDULE ALL ────────────────────────────────────────────────────────

  /// Cancels all notifications and schedules fresh ones for the next 30 days.
  static Future<void> rescheduleAll(AppDatabase db) async {
    try {
      await _plugin.cancelAll();
      await _createChannels();
    } catch (_) {
      return; // notifications not supported on this device/emulator
    }

    final now   = tz.TZDateTime.now(tz.local);
    // Reduced to 7 days to stay within Android's 500-alarm limit
    final end   = now.add(const Duration(days: 7));
    final tasks = await db.getAllTasks();
    final goals = await db.getAllGoals();
    final goalMap = {for (final g in goals) g.id: g};

    int notifId = 1000;

    for (final task in tasks) {
      if (task.isActive == 0) continue;
      final goal = goalMap[task.goalId];
      if (goal == null) continue;

      final schedule = task.schedule;

      // ── Get dates for this task within the window ──────────────────────
      final dates = _scheduleDates(task: task, from: now, to: end);

      for (final date in dates) {
        // Parse the assigned time
        int h = 8;
        int m = 0;
        final timeParts = task.reminderTime.split(':');
        if (timeParts.length == 2) {
          h = int.tryParse(timeParts[0]) ?? 8;
          m = int.tryParse(timeParts[1]) ?? 0;
        }

        // 1. Notification at the assigned time
        final reminderDt = _atTime(date, h, m);
        if (reminderDt.isAfter(now) && notifId < 9900) {
          await _schedule(
            id: notifId++,
            channelId: _chDailyMorning.id,
              title: 'Scheduled Task',
              body: '${task.name}${goal != null ? ' · ${goal.name}' : ''}',
              when: reminderDt,
          );
        }

        // 2. Incomplete task notification at 8 PM (20:00)
        final eveningDt = _atTime(date, 20, 0);
        // Only schedule evening follow-up if the assigned time is before 8 PM
        if (eveningDt.isAfter(now) && reminderDt.isBefore(eveningDt) && notifId < 9900) {
          await _schedule(
            id: notifId++,
            channelId: _chDailyEvening.id,
              title: 'Incomplete Task',
              body: '${task.name} — complete it tonight!${goal != null ? ' · ${goal.name}' : ''}',
              when: eveningDt,
          );
        }
      }

      // ── Deadline warning ───────────────────────────────────────────────
      if (goal == null || goal.status == 'completed') continue;
      final deadline = tz.TZDateTime.fromMillisecondsSinceEpoch(tz.local, goal.deadline);
      final warnDay  = deadline.subtract(const Duration(days: 3));
      final warnAt   = _atTime(warnDay, 9, 0);
      if (warnAt.isAfter(now) && warnAt.isBefore(end) && notifId < 9900) {
        await _schedule(
          id: notifId++,
          channelId: _chDeadline.id,
          title: 'Deadline in 3 days',
          body: '${goal.name} — push through the final stretch.',
          when: warnAt,
        );
      }
    }
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  /// Build list of TZDateTimes within [from, to] when this task is scheduled.
  static List<tz.TZDateTime> _scheduleDates({
    required Task task,
    required tz.TZDateTime from,
    required tz.TZDateTime to,
  }) {
    final results = <tz.TZDateTime>[];
    var cursor = tz.TZDateTime(tz.local, from.year, from.month, from.day);

    while (cursor.isBefore(to)) {
      bool include = false;
      switch (task.schedule) {
        case 'daily':
          include = true;
          break;
        case 'weekly':
          final on = task.scheduleOn?.toLowerCase() ?? '';
          final dayNames = ['monday','tuesday','wednesday','thursday','friday','saturday','sunday'];
          final dayIdx = dayNames.indexOf(on); // 0=Mon … 6=Sun
          if (dayIdx >= 0) {
            include = cursor.weekday - 1 == dayIdx;
          }
          break;
        case 'monthly':
          final dom = int.tryParse(task.scheduleOn ?? '') ?? 0;
          include = dom > 0 && cursor.day == dom;
          break;
        case 'specific_date':
          if (task.scheduleOn != null) {
            final parts = task.scheduleOn!.split('-');
            if (parts.length == 3) {
              final y = int.tryParse(parts[0]) ?? 0;
              final m = int.tryParse(parts[1]) ?? 0;
              final d = int.tryParse(parts[2]) ?? 0;
              include = cursor.year == y && cursor.month == m && cursor.day == d;
            }
          }
          break;
      }
      if (include) results.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }

    return results;
  }

  static tz.TZDateTime _atTime(tz.TZDateTime date, int hour, int min) {
    return tz.TZDateTime(tz.local, date.year, date.month, date.day, hour, min);
  }

  /// Find the most recent Monday on or before [date].
  static tz.TZDateTime _findPreviousOrSame(tz.TZDateTime date, int weekday) {
    var d = date;
    while (d.weekday != weekday) {
      d = d.subtract(const Duration(days: 1));
    }
    return d;
  }

  /// Find the next occurrence of [weekday] after [date].
  static tz.TZDateTime _findNextDay(tz.TZDateTime date, int weekday) {
    var d = date.add(const Duration(days: 1));
    while (d.weekday != weekday) {
      d = d.add(const Duration(days: 1));
    }
    return d;
  }

  static Future<void> _schedule({
    required int id,
    required String channelId,
    required String title,
    required String body,
    required tz.TZDateTime when,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId, channelId,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _plugin.zonedSchedule(
        id, title, body, when, details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      try {
        await _plugin.zonedSchedule(
          id, title, body, when, details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {}
    }
  }

  static Future<void> showTestNotification() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_morning', 'Test Notification',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    await _plugin.show(999, 'Nexus Test', 'Your notifications are working perfectly!', details);
  }

  static Future<void> _createChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    for (final ch in [_chDailyMorning, _chDailyEvening, _chWeeklyStart, _chWeeklySat, _chDeadline]) {
      await android.createNotificationChannel(ch);
    }
  }
}
