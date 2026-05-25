import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:intl/intl.dart';

import '../../core/database/app_database.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/services/productivity_service.dart';
import 'productivity_providers.dart';
import 'day_ring_painter.dart';
import 'edit_activity_dialog.dart';
import 'package:drift/drift.dart' as drift;

// Typography constants
const _display = TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFFEEEEF2));
const _title = TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFEEEEF2));
const _subtitle = TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFFEEEEF2));
const _body = TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFFEEEEF2));
const _caption = TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFF666680));
const _micro = TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w400, color: Color(0xFF3A3A50));
const _data = TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFFEEEEF2));
const _sectionHeader = TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w400, color: Color(0xFF3A3A50), letterSpacing: 1.5);

class LogPage extends ConsumerStatefulWidget {
  const LogPage({super.key});
  @override
  ConsumerState<LogPage> createState() => _LogPageState();
}

class _LogPageState extends ConsumerState<LogPage> with TickerProviderStateMixin {
  late AnimationController _ringAnim;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ringAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ringAnim.dispose();
    _clockTimer?.cancel();
    super.dispose();
  }

  Color _getScoreColor(double score) {
    if (score >= 75) return const Color(0xFF4ADE80);
    if (score >= 45) return const Color(0xFFF59E0B);
    return const Color(0xFFF87171);
  }

  @override
  Widget build(BuildContext context) {
    final date = ref.watch(productivityDateProvider);
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final activitiesAsync = ref.watch(activitiesProvider);
    final sleepAsync = ref.watch(sleepProvider);
    final score = ref.watch(productivityScoreProvider);

    final activities = activitiesAsync.valueOrNull ?? [];
    final sleep = sleepAsync.valueOrNull;

    int totalMins = 0;
    for (final a in activities) totalMins += ((a.endTime - a.startTime) / 60000).round();
    final hoursLogged = (totalMins / 60).toStringAsFixed(1);
    
    String sleepStr = '—';
    if (sleep != null) {
      final sMins = ((sleep.wakeTime - sleep.sleepTime) / 60000).round();
      sleepStr = '${sMins ~/ 60}h ${sMins % 60}m';
    }

    final navActive = ref.watch(navActiveProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF000000), // pitch black
      body: IgnorePointer(
        ignoring: navActive,
        child: SafeArea(
        child: Builder(
          builder: (context) {
            Offset? dragStartPos;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (details) => dragStartPos = details.globalPosition,
              onHorizontalDragEnd: (details) {
                if (dragStartPos != null && dragStartPos!.dy > MediaQuery.of(context).size.height - 100) return;
                if (details.primaryVelocity != null) {
                  if (details.primaryVelocity! < -300) {
                    final nextDate = date.add(const Duration(days: 1));
                    final today = DateTime.now();
                    final todayStart = DateTime(today.year, today.month, today.day);
                    final nextStart = DateTime(nextDate.year, nextDate.month, nextDate.day);
                    if (!nextStart.isAfter(todayStart)) {
                      ref.read(productivityDateProvider.notifier).state = nextDate;
                    }
                  } else if (details.primaryVelocity! > 300) {
                    ref.read(productivityDateProvider.notifier).state = date.subtract(const Duration(days: 1));
                  }
                }
              },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            children: [
              const SizedBox(height: 16),
              
              // ── PAGE HEADER ──────────────────────────────────────────────────
              const Text('PRODUCTIVITY', style: _sectionHeader),
              const SizedBox(height: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Color(0xFF666680), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(isToday ? 'Today' : DateFormat('EEE, d MMM').format(date), style: _title),
                ],
              ),
            
            const SizedBox(height: 32),

            // ── THE 24H RING ────────────────────────────────────────────────
            Center(
              child: SizedBox(
                width: 220, height: 220,
                child: AnimatedBuilder(
                  animation: _ringAnim,
                  builder: (ctx, _) => CustomPaint(
                    size: const Size(220, 220),
                    painter: DayRingPainter(
                      activities: activities,
                      sleep: sleep,
                      animProgress: Curves.easeOut.transform(_ringAnim.value),
                      currentTime: _now,
                      showTimeIndicator: isToday,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: score.total),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.linear,
                            builder: (_, val, __) => Text(
                              val.round().toString(),
                              style: TextStyle(
                                color: _getScoreColor(val),
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                          Text(score.label, style: const TextStyle(color: Color(0xFF666680), fontSize: 10, fontWeight: FontWeight.w400)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── STATS ROW ───────────────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFF1E1E1E), width: 0.5),
                  bottom: BorderSide(color: Color(0xFF1E1E1E), width: 0.5),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text('${hoursLogged}h', style: const TextStyle(color: Color(0xFFEEEEF2), fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        const Text('Hours Logged', style: TextStyle(color: Color(0xFF666680), fontSize: 11, fontWeight: FontWeight.w400)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 32, color: const Color(0xFF1E1E1E)),
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 6, height: 6, decoration: BoxDecoration(color: _getScoreColor(score.total), shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text('${score.total.round()}', style: const TextStyle(color: Color(0xFFEEEEF2), fontSize: 18, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text('Score', style: TextStyle(color: Color(0xFF666680), fontSize: 11, fontWeight: FontWeight.w400)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 32, color: const Color(0xFF1E1E1E)),
                  Expanded(
                    child: Column(
                      children: [
                        Text(sleepStr, style: const TextStyle(color: Color(0xFFEEEEF2), fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        const Text('Sleep', style: TextStyle(color: Color(0xFF666680), fontSize: 11, fontWeight: FontWeight.w400)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── LOG ACTIVITY FORM ──────────────────────────────────────────
            const Text('LOG ACTIVITY', style: _sectionHeader),
            const SizedBox(height: 16),
            _ActivityForm(date: date, activities: activities),

            const SizedBox(height: 32),

            // ── SLEEP LOG ──────────────────────────────────────────────────
            const Text('SLEEP', style: _sectionHeader),
            const SizedBox(height: 16),
            _SleepLogForm(date: date, existingSleep: sleep),

            const SizedBox(height: 32),

            // ── TODAY'S LOG LIST ───────────────────────────────────────────
            const Text('TODAY\'S LOG', style: _sectionHeader),
            const SizedBox(height: 16),
            _TimelineList(date: date, activities: activities, sleep: sleep),

            const SizedBox(height: 120),
          ],
        ),
            );
          },
        ),
      ),
      ),
    );
  }
}

// ── ACTIVITY FORM ───────────────────────────────────────────────────────────

class _ActivityForm extends ConsumerStatefulWidget {
  final DateTime date;
  final List<ActivityLog> activities;
  const _ActivityForm({required this.date, required this.activities});
  @override
  ConsumerState<_ActivityForm> createState() => _ActivityFormState();
}

class _ActivityFormState extends ConsumerState<_ActivityForm> {
  final _nameCtrl = TextEditingController();
  final _focusNode = FocusNode();
  bool _isFocused = false;
  String? _selectedCategory;
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now().replacing(hour: (TimeOfDay.now().hour + 1) % 24);

  final List<String> _cats = ['deep_work', 'exercise', 'learning', 'goal_tasks', 'social', 'routine', 'leisure', 'sleep'];
  final List<String> _suggestions = ['Deep work', 'Meeting', 'Reading', 'Workout', 'Coding', 'Writing'];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _isFocused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  int _durationMinutes() {
    int startMins = _startTime.hour * 60 + _startTime.minute;
    int endMins = _endTime.hour * 60 + _endTime.minute;
    if (endMins <= startMins) endMins += 1440;
    return endMins - startMins;
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFF7C6AF7), surface: Color(0xFF111118), onSurface: Color(0xFFEEEEF2)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => isStart ? _startTime = picked : _endTime = picked);
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty || _selectedCategory == null) return;
    if (_checkOverlap() != null) return; // Prevent submitting overlaps!
    final db = ref.read(databaseProvider);
    final midnight = DateTime(widget.date.year, widget.date.month, widget.date.day);
    final startMs = midnight.add(Duration(hours: _startTime.hour, minutes: _startTime.minute)).millisecondsSinceEpoch;
    int endMs = midnight.add(Duration(hours: _endTime.hour, minutes: _endTime.minute)).millisecondsSinceEpoch;
    if (endMs <= startMs) endMs += 86400000;

    await db.insertActivity(ActivityLogsCompanion.insert(
      date: midnight.millisecondsSinceEpoch,
      category: _selectedCategory!,
      name: _nameCtrl.text.trim(),
      startTime: startMs,
      endTime: endMs,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
    await db.invalidateCache(midnight.millisecondsSinceEpoch);
    await ProductivityService.ensureScore(db, midnight.millisecondsSinceEpoch);
    final hapticsOn = (ref.read(profileProvider).value?.hapticsEnabled ?? 1) == 1;
    if (hapticsOn) {
      HapticFeedback.mediumImpact();
    }
    
    setState(() {
      _nameCtrl.clear();
      _selectedCategory = null;
    });
  }

  String? _checkOverlap() {
    final midnight = DateTime(widget.date.year, widget.date.month, widget.date.day);
    final startMs = midnight.add(Duration(hours: _startTime.hour, minutes: _startTime.minute)).millisecondsSinceEpoch;
    int endMs = midnight.add(Duration(hours: _endTime.hour, minutes: _endTime.minute)).millisecondsSinceEpoch;
    if (endMs <= startMs) endMs += 86400000;

    for (final a in widget.activities) {
      if (startMs < a.endTime && endMs > a.startTime) return a.name;
    }
    
    // Check against sleep
    final sleep = ref.read(sleepProvider).valueOrNull;
    if (sleep != null) {
      if (startMs < sleep.wakeTime && endMs > sleep.sleepTime) return 'Sleep';
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final dur = _durationMinutes();
    final overlapName = _checkOverlap();
    final canSubmit = _nameCtrl.text.trim().isNotEmpty && _selectedCategory != null && overlapName == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // What
        Row(
          children: [
            const SizedBox(width: 40, child: Text('What', style: _caption)),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  border: Border(bottom: BorderSide(color: _isFocused ? const Color(0xFF7C6AF7) : const Color(0xFF1E1E1E), width: _isFocused ? 1.5 : 0.5)),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
                child: TextField(
                  controller: _nameCtrl,
                  focusNode: _focusNode,
                  style: const TextStyle(color: Color(0xFFEEEEF2), fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Describe the activity',
                    hintStyle: TextStyle(color: Color(0xFF3A3A50), fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const SizedBox(width: 40),
              ..._suggestions.map((s) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _nameCtrl.text = s),
                  child: Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: const Color(0xFF1E1E1E), width: 0.5),
                    ),
                    child: Text(s, style: const TextStyle(color: Color(0xFF666680), fontSize: 12)),
                  ),
                ),
              )),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Type
        Row(
          children: [
            const SizedBox(width: 40, child: Text('Type', style: _caption)),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _cats.map((c) {
                    final isSel = _selectedCategory == c;
                    final cat = ActivityCategory.fromKey(c);
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = c),
                      child: Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSel ? cat.color.withValues(alpha: 0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isSel ? cat.color.withValues(alpha: 0.5) : Colors.transparent),
                        ),
                        child: Text(cat.label, style: TextStyle(color: isSel ? cat.color : const Color(0xFF666680), fontSize: 12, fontWeight: isSel ? FontWeight.w600 : FontWeight.w500)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // When
        Row(
          children: [
            const SizedBox(width: 40, child: Text('When', style: _caption)),
            GestureDetector(
              onTap: () => _pickTime(true),
              child: Text('${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Color(0xFFEEEEF2), fontSize: 16, fontWeight: FontWeight.w500)),
            ),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('→', style: TextStyle(color: Color(0xFF3A3A50), fontSize: 14))),
            GestureDetector(
              onTap: () => _pickTime(false),
              child: Text('${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Color(0xFFEEEEF2), fontSize: 16, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(width: 16),
            Text('${dur ~/ 60}h ${dur % 60}m', style: const TextStyle(color: Color(0xFF7C6AF7), fontSize: 12)),
          ],
        ),
        if (overlapName != null) ...[
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.only(left: 40),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 14),
                const SizedBox(width: 8),
                Text('Overlaps with $overlapName', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 12)),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Submit
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: canSubmit ? _submit : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Add Activity', style: TextStyle(color: canSubmit ? const Color(0xFF7C6AF7) : const Color(0xFF3A3A50), fontSize: 14, fontWeight: FontWeight.w600)),
                if (canSubmit) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.arrow_forward, color: Color(0xFF7C6AF7), size: 14)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        Container(height: 0.5, color: const Color(0xFF1E1E1E)),
      ],
    );
  }
}

// ── SLEEP FORM ──────────────────────────────────────────────────────────────

class _SleepLogForm extends ConsumerStatefulWidget {
  final DateTime date;
  final SleepLog? existingSleep;
  const _SleepLogForm({required this.date, required this.existingSleep});
  @override
  ConsumerState<_SleepLogForm> createState() => _SleepLogFormState();
}

class _SleepLogFormState extends ConsumerState<_SleepLogForm> {
  TimeOfDay _sleepTime = const TimeOfDay(hour: 22, minute: 30);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);

  @override
  void initState() {
    super.initState();
    _initTimes();
  }

  @override
  void didUpdateWidget(covariant _SleepLogForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.existingSleep != oldWidget.existingSleep || widget.date != oldWidget.date) {
      _initTimes();
    }
  }

  void _initTimes() {
    if (widget.existingSleep != null) {
      final sDt = DateTime.fromMillisecondsSinceEpoch(widget.existingSleep!.sleepTime);
      final wDt = DateTime.fromMillisecondsSinceEpoch(widget.existingSleep!.wakeTime);
      _sleepTime = TimeOfDay(hour: sDt.hour, minute: sDt.minute);
      _wakeTime = TimeOfDay(hour: wDt.hour, minute: wDt.minute);
    } else {
      _sleepTime = const TimeOfDay(hour: 22, minute: 30);
      _wakeTime = const TimeOfDay(hour: 7, minute: 0);
    }
  }

  double get _sleepHours {
    int sleepMins = _sleepTime.hour * 60 + _sleepTime.minute;
    int wakeMins = _wakeTime.hour * 60 + _wakeTime.minute;
    if (wakeMins <= sleepMins) wakeMins += 1440;
    return (wakeMins - sleepMins) / 60.0;
  }

  Future<void> _pickTime(bool isSleep) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isSleep ? _sleepTime : _wakeTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFF7C6AF7), surface: Color(0xFF111118), onSurface: Color(0xFFEEEEF2))),
        child: child!,
      ),
    );
    if (picked != null) setState(() => isSleep ? _sleepTime = picked : _wakeTime = picked);
  }

  Future<void> _submit() async {
    final db = ref.read(databaseProvider);
    final midnight = DateTime(widget.date.year, widget.date.month, widget.date.day);
    final sleepDt = _sleepTime.hour >= 12
        ? midnight.subtract(const Duration(days: 1)).add(Duration(hours: _sleepTime.hour, minutes: _sleepTime.minute))
        : midnight.add(Duration(hours: _sleepTime.hour, minutes: _sleepTime.minute));
    final wakeDt = midnight.add(Duration(hours: _wakeTime.hour, minutes: _wakeTime.minute));

    // Check overlaps with activity logs on both previous and current day
    final prevMidnight = midnight.subtract(const Duration(days: 1)).millisecondsSinceEpoch;
    final currMidnight = midnight.millisecondsSinceEpoch;
    final candidateActivities = await db.getActivitiesInRange(prevMidnight, currMidnight);
    final overlappingActivities = candidateActivities.where((a) =>
        sleepDt.millisecondsSinceEpoch < a.endTime && wakeDt.millisecondsSinceEpoch > a.startTime && a.category != 'sleep');

    if (overlappingActivities.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot log sleep: Overlaps with activity "${overlappingActivities.first.name}"'),
            backgroundColor: const Color(0xFFE74C3C),
          ),
        );
      }
      return;
    }

    if (widget.existingSleep != null) {
      await db.updateSleep(SleepLogsCompanion(
        id: drift.Value(widget.existingSleep!.id),
        date: drift.Value(midnight.millisecondsSinceEpoch),
        sleepTime: drift.Value(sleepDt.millisecondsSinceEpoch),
        wakeTime: drift.Value(wakeDt.millisecondsSinceEpoch),
      ));
    } else {
      await db.deleteSleepForDate(midnight.millisecondsSinceEpoch);
      await db.insertSleep(SleepLogsCompanion.insert(
        date: midnight.millisecondsSinceEpoch,
        sleepTime: sleepDt.millisecondsSinceEpoch,
        wakeTime: wakeDt.millisecondsSinceEpoch,
        qualityNote: const drift.Value('logged'),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
    }
    await db.invalidateCache(midnight.millisecondsSinceEpoch);
    await ProductivityService.ensureScore(db, midnight.millisecondsSinceEpoch);
    final hapticsOn = (ref.read(profileProvider).value?.hapticsEnabled ?? 1) == 1;
    if (hapticsOn) {
      HapticFeedback.mediumImpact();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingSleep != null ? 'Sleep log updated!' : 'Sleep logged successfully!'),
          backgroundColor: const Color(0xFF4ADE80),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = _sleepHours;
    final color = (h >= 7 && h <= 9) ? const Color(0xFF4ADE80) : const Color(0xFFF59E0B);
    final durStr = '${h.floor()}h ${((h - h.floor()) * 60).round()}m';

    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 60, child: Text('Slept at', style: _caption)),
            GestureDetector(
              onTap: () => _pickTime(true),
              child: Text('${_sleepTime.hour.toString().padLeft(2, '0')}:${_sleepTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Color(0xFFEEEEF2), fontSize: 16, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const SizedBox(width: 60, child: Text('Woke at', style: _caption)),
            GestureDetector(
              onTap: () => _pickTime(false),
              child: Text('${_wakeTime.hour.toString().padLeft(2, '0')}:${_wakeTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Color(0xFFEEEEF2), fontSize: 16, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(width: 16),
            Text(durStr, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: _submit,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.existingSleep != null ? 'Update Sleep' : 'Log Sleep', style: const TextStyle(color: Color(0xFF7C6AF7), fontSize: 13, fontWeight: FontWeight.w500)),
                if (widget.existingSleep == null) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.arrow_forward, color: Color(0xFF7C6AF7), size: 14)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(height: 0.5, color: const Color(0xFF1E1E1E)),
      ],
    );
  }
}

// ── TIMELINE ────────────────────────────────────────────────────────────────

class _TimelineList extends ConsumerWidget {
  final DateTime date;
  final List<ActivityLog> activities;
  final SleepLog? sleep;
  const _TimelineList({required this.date, required this.activities, required this.sleep});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (activities.isEmpty && sleep == null) {
      return const Text('No activities logged.', style: TextStyle(color: Color(0xFF666680), fontSize: 13));
    }

    final items = <Widget>[];

    if (sleep != null) {
      final s = sleep!;
      final dur = Duration(milliseconds: s.wakeTime - s.sleepTime);
      final sFmt = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(s.sleepTime));
      final eFmt = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(s.wakeTime));
      items.add(_TimelineRow(
        id: s.id,
        name: 'Sleep',
        categoryLabel: 'sleep',
        color: const Color(0xFFA78BFA),
        timeStr: '$sFmt → $eFmt',
        durStr: '${dur.inHours}h ${dur.inMinutes % 60}m',
        onDelete: () async {
          final db = ref.read(databaseProvider);
          final midnightMs = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
          await db.deleteSleep(s.id);
          await db.invalidateCache(midnightMs);
          await ProductivityService.ensureScore(db, midnightMs);
        },
      ));
    }

    for (final a in activities.reversed) {
      final cat = ActivityCategory.fromKey(a.category);
      final dur = Duration(milliseconds: a.endTime - a.startTime);
      final sFmt = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(a.startTime));
      final eFmt = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(a.endTime));
      items.add(_TimelineRow(
        activity: a,
        id: a.id,
        name: a.name,
        categoryLabel: cat.label,
        color: cat.color,
        timeStr: '$sFmt → $eFmt',
        durStr: '${dur.inHours > 0 ? '${dur.inHours}h ' : ''}${dur.inMinutes % 60}m',
        onDelete: () async {
          final db = ref.read(databaseProvider);
          final midnightMs = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
          await db.deleteActivity(a.id);
          await db.invalidateCache(midnightMs);
          await ProductivityService.ensureScore(db, midnightMs);
        },
        onEdit: () {
          showDialog(
            context: context,
            builder: (ctx) => EditActivityDialog(activity: a),
          );
        },
      ));
    }

    return Column(children: items);
  }
}

class _TimelineRow extends StatelessWidget {
  final ActivityLog? activity;
  final int id;
  final String name;
  final String categoryLabel;
  final Color color;
  final String timeStr;
  final String durStr;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  const _TimelineRow({
    this.activity,
    required this.id,
    required this.name,
    required this.categoryLabel,
    required this.color,
    required this.timeStr,
    required this.durStr,
    required this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      child: Dismissible(
      key: ValueKey('tl_$id'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Text('Delete', style: TextStyle(color: Color(0xFFF87171), fontSize: 13, fontWeight: FontWeight.w500)),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        height: 56,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 4, height: double.infinity,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: const TextStyle(color: Color(0xFFEEEEF2), fontSize: 13, fontWeight: FontWeight.w500)),
                      Text(timeStr, style: const TextStyle(color: Color(0xFF666680), fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(categoryLabel, style: const TextStyle(color: Color(0xFF666680), fontSize: 11)),
                      Text(durStr, style: const TextStyle(color: Color(0xFF3A3A50), fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
