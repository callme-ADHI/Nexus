import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/providers.dart';
import '../../core/database/app_database.dart';
import '../../shared/theme/app_theme.dart';
import 'add_task_form.dart';

class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  String? _filterGoalId;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allGoals = ref.watch(allGoalsProvider);
    final todayCompletions = ref.watch(todayCompletionsProvider);
    final missedCompletions = ref.watch(missedCompletionsProvider);
    final allTasks = ref.watch(allTasksProvider);

    final todayPending = todayCompletions.value?.where((c) => c.completedDate == null).length ?? 0;
    final missedCount  = missedCompletions.value?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tasks', style: AppTypography.pageTitle),
                  IconButton(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const AddTaskForm(),
                    ),
                    icon: const Icon(Icons.add, color: AppColors.textPrimary),
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ],
              ),
            ),

            // ── Tab bar ───────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: AppRadius.button,
              ),
              child: TabBar(
                controller: _tabCtrl,
                indicator: BoxDecoration(
                  color: AppColors.accentBlue,
                  borderRadius: AppRadius.button,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: AppTypography.badge.copyWith(fontSize: 11),
                unselectedLabelStyle: AppTypography.caption,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                dividerColor: Colors.transparent,
                tabs: [
                  _Tab('Today', todayPending),
                  _Tab('Missed', missedCount),
                  const Tab(text: 'Upcoming'),
                  const Tab(text: 'All'),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── Goal filter chips ─────────────────────────────────────
            allGoals.when(
              data: (goals) => goals.isEmpty
                  ? const SizedBox.shrink()
                  : SizedBox(
                      height: 34,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                        children: [
                          _FilterChip(
                            label: 'All',
                            selected: _filterGoalId == null,
                            onTap: () => setState(() => _filterGoalId = null),
                          ),
                          const SizedBox(width: 6),
                          ...goals.map((g) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: _FilterChip(
                                  label: g.name,
                                  selected: _filterGoalId == g.id,
                                  onTap: () => setState(() => _filterGoalId = g.id),
                                ),
                              )),
                        ],
                      ),
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 10),

            // ── Content ───────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _TodaySection(
                    completions: todayCompletions,
                    allTasks: allTasks,
                    allGoals: allGoals,
                    filterGoalId: _filterGoalId,
                    ref: ref,
                  ),
                  _MissedSection(
                    completions: missedCompletions,
                    allTasks: allTasks,
                    allGoals: allGoals,
                    filterGoalId: _filterGoalId,
                    ref: ref,
                  ),
                  _UpcomingSection(
                    allTasks: allTasks,
                    allGoals: allGoals,
                    filterGoalId: _filterGoalId,
                    ref: ref,
                  ),
                  _AllSection(
                    allTasks: allTasks,
                    allGoals: allGoals,
                    filterGoalId: _filterGoalId,
                    ref: ref,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final int count;
  const _Tab(this.label, this.count);

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: AppRadius.chip,
              ),
              child: Text('$count', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentBlueDim : AppColors.surfaceAlt,
            borderRadius: AppRadius.chip,
            border: Border.all(
              color: selected ? AppColors.accentBlue : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: selected ? AppColors.accentBlue : AppColors.textSecondary,
              fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
}

// ── Today section ─────────────────────────────────────────────────────────

class _TodaySection extends StatelessWidget {
  final AsyncValue<List<TaskCompletion>> completions;
  final AsyncValue<List<Task>> allTasks;
  final AsyncValue<List<Goal>> allGoals;
  final String? filterGoalId;
  final WidgetRef ref;

  const _TodaySection({
    required this.completions,
    required this.allTasks,
    required this.allGoals,
    required this.filterGoalId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return completions.when(
      data: (comps) => allTasks.when(
        data: (tasks) => allGoals.when(
          data: (goals) {
            final taskMap = {for (final t in tasks) t.id: t};
            final goalMap = {for (final g in goals) g.id: g};
            var items = comps;
            if (filterGoalId != null) {
              items = comps.where((c) => taskMap[c.taskId]?.goalId == filterGoalId).toList();
            }
            // Sort: incomplete first, then by time
            items = [...items]..sort((a, b) {
                if (a.completedDate != null && b.completedDate == null) return 1;
                if (a.completedDate == null && b.completedDate != null) return -1;
                final ta = taskMap[a.taskId];
                final tb = taskMap[b.taskId];
                if (ta == null || tb == null) return 0;
                return ta.reminderTime.compareTo(tb.reminderTime);
              });

            if (items.isEmpty) return _EmptyState('No tasks for today');

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final c = items[i];
                final task = taskMap[c.taskId];
                final goal = task != null ? goalMap[task.goalId] : null;
                if (task == null) return const SizedBox.shrink();
                final isDone = c.completedDate != null;
                return _TaskRow(
                  task: task,
                  goalName: goal?.name,
                  isDone: isDone,
                  accentColor: isDone ? AppColors.success : null,
                  trailing: Text(task.reminderTime, style: AppTypography.caption),
                  onToggle: () {
                    if (isDone) {
                      ref.read(taskNotifierProvider.notifier).uncompleteTask(
                        taskId: c.taskId, scheduledDate: c.scheduledDate,
                      );
                    } else {
                      ref.read(taskNotifierProvider.notifier).completeTask(
                        taskId: c.taskId, scheduledDate: c.scheduledDate,
                      );
                    }
                  },
                );
              },
            );
          },
          loading: () => const _Loading(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        loading: () => const _Loading(),
        error: (_, __) => const SizedBox.shrink(),
      ),
      loading: () => const _Loading(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── Missed section ────────────────────────────────────────────────────────

class _MissedSection extends StatelessWidget {
  final AsyncValue<List<TaskCompletion>> completions;
  final AsyncValue<List<Task>> allTasks;
  final AsyncValue<List<Goal>> allGoals;
  final String? filterGoalId;
  final WidgetRef ref;

  const _MissedSection({
    required this.completions,
    required this.allTasks,
    required this.allGoals,
    required this.filterGoalId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return completions.when(
      data: (comps) => allTasks.when(
        data: (tasks) => allGoals.when(
          data: (goals) {
            final taskMap = {for (final t in tasks) t.id: t};
            final goalMap = {for (final g in goals) g.id: g};
            var items = comps;
            if (filterGoalId != null) {
              items = comps.where((c) => taskMap[c.taskId]?.goalId == filterGoalId).toList();
            }
            items = [...items]..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));

            if (items.isEmpty) return _EmptyState('No missed tasks 🎉');

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final c = items[i];
                final task = taskMap[c.taskId];
                final goal = task != null ? goalMap[task.goalId] : null;
                if (task == null) return const SizedBox.shrink();
                final schDate = DateTime.fromMillisecondsSinceEpoch(c.scheduledDate);
                final diff = DateTime.now().difference(schDate).inDays;
                final isDone = c.completedDate != null;
                return _TaskRow(
                  task: task,
                  goalName: goal?.name,
                  isDone: isDone,
                  accentColor: AppColors.accentRed,
                  trailing: Text(
                    diff == 1 ? 'Yesterday' : '${diff}d ago',
                    style: AppTypography.caption.copyWith(color: AppColors.accentRed, fontSize: 11),
                  ),
                  onToggle: isDone ? null : () {
                    ref.read(taskNotifierProvider.notifier).completeTask(
                      taskId: c.taskId, scheduledDate: c.scheduledDate,
                    );
                  },
                );
              },
            );
          },
          loading: () => const _Loading(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        loading: () => const _Loading(),
        error: (_, __) => const SizedBox.shrink(),
      ),
      loading: () => const _Loading(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── Upcoming section ──────────────────────────────────────────────────────

class _UpcomingSection extends StatelessWidget {
  final AsyncValue<List<Task>> allTasks;
  final AsyncValue<List<Goal>> allGoals;
  final String? filterGoalId;
  final WidgetRef ref;

  const _UpcomingSection({
    required this.allTasks,
    required this.allGoals,
    required this.filterGoalId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return allTasks.when(
      data: (tasks) => allGoals.when(
        data: (goals) {
          final goalMap = {for (final g in goals) g.id: g};
          var activeTasks = tasks.where((t) => t.isActive == 1);
          if (filterGoalId != null) {
            activeTasks = activeTasks.where((t) => t.goalId == filterGoalId);
          }
          final taskList = activeTasks.toList();

          if (taskList.isEmpty) return _EmptyState('No upcoming tasks');

          // Build upcoming schedule for next 7 days
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final upcoming = <({DateTime date, Task task, Goal? goal})>[];

          for (final task in taskList) {
            final goal = goalMap[task.goalId];
            final schedule = task.schedule;

            for (int d = 1; d <= 7; d++) {
              final day = today.add(Duration(days: d));
              bool include = false;

              if (schedule == 'daily') {
                include = true;
              } else if (schedule == 'weekly') {
                final on = task.scheduleOn?.toLowerCase() ?? '';
                final dayNames = ['monday','tuesday','wednesday','thursday','friday','saturday','sunday'];
                final dayIdx = dayNames.indexOf(on);
                include = (dayIdx >= 0) && (day.weekday - 1 == dayIdx);
              } else if (schedule == 'monthly') {
                final dayOfMonth = int.tryParse(task.scheduleOn ?? '') ?? 0;
                include = day.day == dayOfMonth;
              }

              if (include) {
                upcoming.add((date: day, task: task, goal: goal));
              }
            }
          }

          upcoming.sort((a, b) => a.date.compareTo(b.date));

          if (upcoming.isEmpty) return _EmptyState('No upcoming tasks in the next 7 days');

          // Group by date
          final grouped = <DateTime, List<({Task task, Goal? goal})>>{};
          for (final item in upcoming) {
            grouped.putIfAbsent(item.date, () => []).add((task: item.task, goal: item.goal));
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            children: grouped.entries.map((entry) {
              final dayLabel = DateFormat('EEE, d MMM').format(entry.key);
              final isToday = entry.key.difference(today).inDays == 0;
              final isTomorrow = entry.key.difference(today).inDays == 1;
              final label = isToday ? 'Today' : isTomorrow ? 'Tomorrow' : dayLabel;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Text(label.toUpperCase(), style: AppTypography.sectionHeader),
                  ),
                  ...entry.value.map((item) => _TaskRow(
                        task: item.task,
                        goalName: item.goal?.name,
                        isDone: false,
                        accentColor: null,
                        trailing: Text(item.task.reminderTime, style: AppTypography.caption),
                        onToggle: null,
                      )),
                ],
              );
            }).toList(),
          );
        },
        loading: () => const _Loading(),
        error: (_, __) => const SizedBox.shrink(),
      ),
      loading: () => const _Loading(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── All section ───────────────────────────────────────────────────────────

class _AllSection extends StatelessWidget {
  final AsyncValue<List<Task>> allTasks;
  final AsyncValue<List<Goal>> allGoals;
  final String? filterGoalId;
  final WidgetRef ref;

  const _AllSection({
    required this.allTasks,
    required this.allGoals,
    required this.filterGoalId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return allTasks.when(
      data: (tasks) => allGoals.when(
        data: (goals) {
          final goalMap = {for (final g in goals) g.id: g};
          var items = tasks;
          if (filterGoalId != null) {
            items = tasks.where((t) => t.goalId == filterGoalId).toList();
          }
          if (items.isEmpty) return _EmptyState('No tasks yet');

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            itemCount: items.length,
            itemBuilder: (ctx, i) {
              final task = items[i];
              final goal = goalMap[task.goalId];
              final isActive = task.isActive == 1;
              return Dismissible(
                key: Key(task.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accentRedDim,
                    borderRadius: AppRadius.card,
                  ),
                  child: const Icon(Icons.delete_outline, color: AppColors.accentRed),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('Delete Task', style: AppTypography.cardTitle),
                      content: Text('Delete "${task.name}"?', style: AppTypography.body),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRed),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) {
                  ref.read(taskNotifierProvider.notifier).deleteTask(task.id);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.card,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(task.name, style: AppTypography.cardTitle),
                            const SizedBox(height: 3),
                            if (goal != null)
                              Text(goal.name, style: AppTypography.caption),
                            const SizedBox(height: 2),
                            Text(
                              '${task.schedule.toUpperCase()} · ${task.reminderTime}',
                              style: AppTypography.caption.copyWith(fontSize: 10, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.accentBlueDim : AppColors.surfaceAlt,
                          borderRadius: AppRadius.chip,
                          border: Border.all(
                            color: isActive ? AppColors.accentBlue : AppColors.border,
                          ),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Inactive',
                          style: AppTypography.badge.copyWith(
                            color: isActive ? AppColors.accentBlue : AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const _Loading(),
        error: (_, __) => const SizedBox.shrink(),
      ),
      loading: () => const _Loading(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── Task row widget ────────────────────────────────────────────────────────

class _TaskRow extends StatelessWidget {
  final Task task;
  final String? goalName;
  final bool isDone;
  final Color? accentColor;
  final Widget? trailing;
  final VoidCallback? onToggle;

  const _TaskRow({
    required this.task,
    required this.goalName,
    required this.isDone,
    required this.accentColor,
    required this.trailing,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border(
          left: BorderSide(
            color: accentColor ?? AppColors.border,
            width: accentColor != null ? 2.5 : 1,
          ),
          top: const BorderSide(color: AppColors.border),
          right: const BorderSide(color: AppColors.border),
          bottom: const BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          if (onToggle != null) ...[
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? AppColors.success : Colors.transparent,
                  border: Border.all(
                    color: isDone ? AppColors.success : AppColors.textSecondary,
                    width: 1.5,
                  ),
                ),
                child: isDone
                    ? const Icon(Icons.check, color: Colors.white, size: 13)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.name,
                  style: AppTypography.cardTitle.copyWith(
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? AppColors.textSecondary : AppColors.textPrimary,
                  ),
                ),
                if (goalName != null) ...[
                  const SizedBox(height: 2),
                  Text(goalName!, style: AppTypography.caption),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ── Utilities ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState(this.message);

  @override
  Widget build(BuildContext context) => Center(
        child: Text(message, style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
      );
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: AppColors.accentBlue));
}
