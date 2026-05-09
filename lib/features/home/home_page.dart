import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';

import '../../core/providers/providers.dart';
import '../../core/database/app_database.dart';
import '../../core/models/models.dart';
import '../../shared/theme/app_theme.dart';
import '../graph/goal_detail_sheet.dart';
import '../graph/add_goal_form.dart';
import '../tasks/add_task_form.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile           = ref.watch(profileProvider);
    final goalGraph         = ref.watch(goalGraphProvider);
    final todayCompletions  = ref.watch(todayCompletionsProvider);
    final missedCompletions = ref.watch(missedCompletionsProvider);
    final allTasks          = ref.watch(allTasksProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.md),
                child: profile.when(
                  data: (p) => _Header(name: p?.displayName ?? 'You'),
                  loading: () => const _Header(name: 'You'),
                  error: (_, __) => const _Header(name: 'You'),
                ),
              ),
            ),

            // ── Missed Banner ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: missedCompletions.when(
                data: (missed) => missed.isEmpty
                    ? const SizedBox.shrink()
                    : _MissedBanner(
                        count: missed.length,
                        onTap: () =>
                            ref.read(pageIndexProvider.notifier).state = 2,
                      ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // ── Today's Tasks ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.sectionSpacing, AppSpacing.xl, AppSpacing.titleContentGap),
                child: Row(
                  children: [
                    Text('TODAY', style: AppTypography.sectionHeader),
                    const SizedBox(width: 8),
                    todayCompletions.when(
                      data: (completions) {
                        final incomplete =
                            completions.where((c) => c.completedDate == null).length;
                        return incomplete > 0
                            ? _CountBadge(incomplete)
                            : const SizedBox.shrink();
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),

            // Tasks list
            todayCompletions.when(
              data: (completions) => allTasks.when(
                data: (tasks) {
                  if (completions.isEmpty) {
                    return const SliverToBoxAdapter(child: _EmptyTasks());
                  }
                  final taskMap = {for (final t in tasks) t.id: t};
                  final sorted = [...completions]..sort((a, b) {
                      if (a.completedDate != null && b.completedDate == null) return 1;
                      if (a.completedDate == null && b.completedDate != null) return -1;
                      final ta = taskMap[a.taskId];
                      final tb = taskMap[b.taskId];
                      if (ta == null || tb == null) return 0;
                      return ta.reminderTime.compareTo(tb.reminderTime);
                    });
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final c = sorted[i];
                        final task = taskMap[c.taskId];
                        if (task == null) return null;
                        return _TodayTaskRow(
                          completion: c,
                          task: task,
                          onToggle: (done) {
                            if (done) {
                              ref.read(taskNotifierProvider.notifier).completeTask(
                                taskId: c.taskId,
                                scheduledDate: c.scheduledDate,
                              );
                            } else {
                              ref.read(taskNotifierProvider.notifier).uncompleteTask(
                                taskId: c.taskId,
                                scheduledDate: c.scheduledDate,
                              );
                            }
                          },
                        );
                      },
                      childCount: sorted.length,
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator(color: AppColors.accentBlue)),
                ),
              ),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            // ── Active Goals ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.sectionSpacing, AppSpacing.xl, AppSpacing.titleContentGap),
                child: Text('ACTIVE GOALS', style: AppTypography.sectionHeader),
              ),
            ),

            SliverToBoxAdapter(
              child: goalGraph.when(
                data: (goals) {
                  final active = goals
                      .where((g) =>
                          g.status != GoalStatus.completed &&
                          g.status != GoalStatus.blocked)
                      .toList();
                  if (active.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      child: Text(
                        'No active goals. Tap + to add your first goal.',
                        style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return SizedBox(
                    height: 140,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      itemCount: active.length,
                      separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                      itemBuilder: (ctx, i) => _GoalCard(
                        goalWP: active[i],
                        onTap: () => _openGoalDetail(context, active[i].goal as Goal, ref),
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox(
                  height: 140,
                  child: Center(child: CircularProgressIndicator(color: AppColors.accentBlue)),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // Bottom padding for FAB
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
      floatingActionButton: _QuickAddFAB(),
    );
  }

  void _openGoalDetail(BuildContext context, Goal goal, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GoalDetailSheet(goal: goal),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String name;
  const _Header({required this.name});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour >= 5 && hour < 12
        ? 'Good morning'
        : hour >= 12 && hour < 18
            ? 'Good afternoon'
            : 'Good evening';

    final now = DateTime.now();
    final dateStr = DateFormat('EEE, d MMM').format(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$greeting,',
              style: AppTypography.body.copyWith(color: AppColors.textSecondary, fontSize: 15),
            ),
            Text(
              dateStr,
              style: AppTypography.caption.copyWith(fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(name, style: AppTypography.pageTitle),
      ],
    );
  }
}

// ── Missed tasks banner ────────────────────────────────────────────────────

class _MissedBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _MissedBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.accentRedDim.withValues(alpha: 0.3),
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.accentRed.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.accentRed, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$count missed task${count == 1 ? '' : 's'} — tap to review',
                style: AppTypography.body.copyWith(color: AppColors.accentRed, fontSize: 13),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.accentRed, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Today task row ─────────────────────────────────────────────────────────

class _TodayTaskRow extends ConsumerWidget {
  final TaskCompletion completion;
  final Task task;
  final ValueChanged<bool> onToggle;

  const _TodayTaskRow({
    required this.completion,
    required this.task,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDone = completion.completedDate != null;
    final allGoals = ref.watch(allGoalsProvider);

    return allGoals.when(
      data: (goals) {
        final goal = goals.where((g) => g.id == task.goalId).firstOrNull;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
          decoration: BoxDecoration(
            color: isDone ? AppColors.surface : AppColors.surface,
            borderRadius: AppRadius.card,
            border: Border.all(
              color: isDone
                  ? AppColors.border
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              // Checkbox
              GestureDetector(
                onTap: () => onToggle(!isDone),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
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
                    if (goal != null) ...[
                      const SizedBox(height: 2),
                      Text(goal.name, style: AppTypography.caption),
                    ],
                  ],
                ),
              ),
              Text(task.reminderTime, style: AppTypography.caption),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── Goal card ────────────────────────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  final GoalWithProgress goalWP;
  final VoidCallback onTap;
  const _GoalCard({required this.goalWP, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final goal = goalWP.goal as Goal;
    final progress = goalWP.effectiveProgress;
    final daysLeft = _daysLeft(goal.deadline);
    final accent = AppColors.nodeAccent(goal.colorIndex);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status indicator line
            Container(
              height: 2,
              width: 32,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: AppRadius.chip,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                goal.name,
                style: AppTypography.cardTitle.copyWith(fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            // Progress bar
            ClipRRect(
              borderRadius: AppRadius.chip,
              child: LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: AppColors.progressTrack,
                valueColor: AlwaysStoppedAnimation(accent),
                minHeight: 3,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${progress.round()}%',
                  style: AppTypography.badge.copyWith(fontSize: 11, color: accent),
                ),
                Text(
                  daysLeft < 0 ? 'Overdue' : '${daysLeft}d left',
                  style: AppTypography.caption.copyWith(
                    color: daysLeft < 0 ? AppColors.accentRed : AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _daysLeft(int deadlineMs) =>
      DateTime.fromMillisecondsSinceEpoch(deadlineMs).difference(DateTime.now()).inDays;
}

// ── Empty tasks ──────────────────────────────────────────────────────────

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.wb_sunny_outlined, color: AppColors.textSecondary, size: 28),
            const SizedBox(height: 8),
            Text(
              'No tasks scheduled for today.',
              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick add FAB ─────────────────────────────────────────────────────────

class _QuickAddFAB extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () => _showQuickAdd(context, ref),
      child: const Icon(Icons.add),
    );
  }

  void _showQuickAdd(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 32, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: AppRadius.chip),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.accentBlueDim,
                borderRadius: AppRadius.button,
              ),
              child: const Icon(Icons.flag_rounded, color: AppColors.accentBlue, size: 18),
            ),
            title: Text('Add Goal', style: AppTypography.cardTitle),
            subtitle: Text('Create a new goal', style: AppTypography.caption),
            onTap: () {
              Navigator.pop(ctx);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (c) => const AddGoalForm(),
              );
            },
          ),
          ListTile(
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.accentBlueDim,
                borderRadius: AppRadius.button,
              ),
              child: const Icon(Icons.check_box_rounded, color: AppColors.accentBlue, size: 18),
            ),
            title: Text('Add Task', style: AppTypography.cardTitle),
            subtitle: Text('Add a task to an existing goal', style: AppTypography.caption),
            onTap: () {
              Navigator.pop(ctx);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (c) => const AddTaskForm(),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Count badge ───────────────────────────────────────────────────────────

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge(this.count);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accentBlue,
        borderRadius: AppRadius.chip,
      ),
      child: Text('$count', style: AppTypography.badge.copyWith(fontSize: 10, color: Colors.white)),
    );
  }
}
