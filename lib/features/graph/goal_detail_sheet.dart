import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/providers/providers.dart';
import '../../core/database/app_database.dart';
import '../../core/models/models.dart';
import '../../shared/theme/app_theme.dart';

class GoalDetailSheet extends ConsumerStatefulWidget {
  final Goal goal;
  const GoalDetailSheet({super.key, required this.goal});

  @override
  ConsumerState<GoalDetailSheet> createState() => _GoalDetailSheetState();
}

class _GoalDetailSheetState extends ConsumerState<GoalDetailSheet> {
  late Goal _goal;

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
  }

  @override
  Widget build(BuildContext context) {
    final goalGraph = ref.watch(goalGraphProvider);
    final allGoals = ref.watch(allGoalsProvider);
    final allTasks = ref.watch(allTasksProvider);
    final todayCompletions = ref.watch(todayCompletionsProvider);

    return goalGraph.when(
      data: (goals) {
        final gwp = goals.where((g) => (g.goal as Goal).id == _goal.id).firstOrNull;
        if (gwp == null) return const SizedBox.shrink();

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.95,
          minChildSize: 0.3,
          expand: false,
          builder: (ctx, scrollCtrl) => Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.sheet,
            ),
            child: CustomScrollView(
              controller: scrollCtrl,
              slivers: [
                // Handle
                SliverToBoxAdapter(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: AppRadius.chip,
                      ),
                    ),
                  ),
                ),

                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: _SheetHeader(gwp: gwp, goal: _goal),
                  ),
                ),

                // Time warning
                if (gwp.hasTimeWarning)
                  SliverToBoxAdapter(
                    child: _TimeWarningBanner(
                      timeElapsed: gwp.timeElapsedPct,
                      progress: gwp.effectiveProgress,
                    ),
                  ),

                // Dependencies breadcrumb
                if (gwp.dependsOnIds.isNotEmpty)
                  SliverToBoxAdapter(
                    child: allGoals.when(
                      data: (allGoalsList) => _DepBreadcrumb(
                        depIds: gwp.dependsOnIds,
                        allGoals: allGoalsList,
                        onTap: (g) => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GoalDetailSheet(goal: g),
                          ),
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),

                // Tasks section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.md),
                    child: allTasks.when(
                      data: (tasks) => todayCompletions.when(
                        data: (completions) {
                          final goalTasks =
                              tasks.where((t) => t.goalId == _goal.id).toList();
                          final completionMap = {
                            for (final c in completions) c.taskId: c
                          };
                          return _TasksSection(
                            tasks: goalTasks,
                            completionMap: completionMap,
                            isBlocked: gwp.status == GoalStatus.blocked,
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                ),

                // Mark complete button
                if (gwp.effectiveProgress >= 80 &&
                    gwp.status != GoalStatus.completed &&
                    gwp.status != GoalStatus.blocked)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl, vertical: 8),
                      child: ElevatedButton(
                        onPressed: () => _confirmComplete(context, gwp, ref),
                        child: const Text('Mark Goal as Complete'),
                      ),
                    ),
                  ),

                // Delete button
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl, 8, AppSpacing.xl, AppSpacing.xxl),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      onPressed: () => _confirmDelete(context, ref),
                      child: const Text('Delete Goal'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _confirmComplete(
      BuildContext context, GoalWithProgress gwp, WidgetRef ref) {
    final pct = gwp.effectiveProgress.round();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Mark as Complete?', style: AppTypography.cardTitle),
        content: Text(
          "You've completed $pct% of tasks. Mark '${_goal.name}' as done?",
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              ref
                  .read(goalNotifierProvider.notifier)
                  .markGoalComplete(_goal.id);
            },
            child: const Text('Mark Complete'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete Goal?', style: AppTypography.cardTitle),
        content: Text(
          "Delete '${_goal.name}'? This cannot be undone.",
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              ref.read(goalNotifierProvider.notifier).deleteGoal(_goal.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Sheet header ──────────────────────────────────────────────────────────

class _SheetHeader extends StatelessWidget {
  final GoalWithProgress gwp;
  final Goal goal;
  const _SheetHeader({required this.gwp, required this.goal});

  @override
  Widget build(BuildContext context) {
    final progress = gwp.effectiveProgress;
    final deadline = DateTime.fromMillisecondsSinceEpoch(goal.deadline);
    final daysLeft = deadline.difference(DateTime.now()).inDays;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(goal.name, style: AppTypography.pageTitle),
              if (goal.aim != null && goal.aim!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(goal.aim!,
                    style: AppTypography.body
                        .copyWith(color: AppColors.textSecondary)),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _InfoChip(goal.timeframe),
                  _InfoChip(daysLeft < 0
                      ? 'Overdue'
                      : '$daysLeft days left',
                    color: daysLeft < 0 ? AppColors.error : null),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Large progress ring
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  startDegreeOffset: -90,
                  sections: [
                    PieChartSectionData(
                      value: progress,
                      color: AppColors.accentSecondary,
                      radius: 10,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      value: 100 - progress,
                      color: AppColors.progressTrack,
                      radius: 10,
                      showTitle: false,
                    ),
                  ],
                  sectionsSpace: 0,
                  centerSpaceRadius: 28,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${progress.round()}%',
                    style: AppTypography.badge.copyWith(
                      fontSize: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color? color;
  const _InfoChip(this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.chip,
        border: Border.all(
          color: color ?? AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.badge.copyWith(
          color: color ?? AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Time warning banner ────────────────────────────────────────────────────

class _TimeWarningBanner extends StatelessWidget {
  final double timeElapsed;
  final double progress;
  const _TimeWarningBanner(
      {required this.timeElapsed, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: 8),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.warning, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '⚠ Time elapsed: ${timeElapsed.round()}% — Progress: ${progress.round()}%. You may be falling behind.',
              style: AppTypography.caption
                  .copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dependency breadcrumb ─────────────────────────────────────────────────

class _DepBreadcrumb extends StatelessWidget {
  final List<String> depIds;
  final List<Goal> allGoals;
  final ValueChanged<Goal> onTap;
  const _DepBreadcrumb(
      {required this.depIds, required this.allGoals, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final goalMap = {for (final g in allGoals) g.id: g};
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: 8),
      child: Row(
        children: depIds.expand((id) {
          final g = goalMap[id];
          if (g == null) return <Widget>[];
          return [
            GestureDetector(
              onTap: () => onTap(g),
              child: Text(
                g.name,
                style: AppTypography.caption
                    .copyWith(color: AppColors.accentSecondary),
              ),
            ),
            Text(' → ',
                style: AppTypography.caption
                    .copyWith(color: AppColors.textSecondary)),
          ];
        }).toList(),
      ),
    );
  }
}

// ── Tasks section ─────────────────────────────────────────────────────────

class _TasksSection extends ConsumerWidget {
  final List<Task> tasks;
  final Map<String, TaskCompletion> completionMap;
  final bool isBlocked;
  const _TasksSection({
    required this.tasks,
    required this.completionMap,
    required this.isBlocked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doneCount =
        completionMap.values.where((c) => c.completedDate != null).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Tasks', style: AppTypography.sectionHeader),
            const SizedBox(width: 8),
            Text(
              '$doneCount/${tasks.length} done today',
              style: AppTypography.caption,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (tasks.isEmpty)
          Text('No tasks yet.',
              style: AppTypography.body
                  .copyWith(color: AppColors.textSecondary)),
        ...tasks.map((task) {
          final completion = completionMap[task.id];
          final isDone = completion?.completedDate != null;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: isBlocked
                      ? null
                      : () {
                          if (isDone && completion != null) {
                            ref
                                .read(taskNotifierProvider.notifier)
                                .uncompleteTask(
                                  taskId: task.id,
                                  scheduledDate: completion.scheduledDate,
                                );
                          } else if (completion != null) {
                            ref
                                .read(taskNotifierProvider.notifier)
                                .completeTask(
                                  taskId: task.id,
                                  scheduledDate: completion.scheduledDate,
                                );
                          }
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? AppColors.accentPrimary
                          : Colors.transparent,
                      border: Border.all(
                        color: isBlocked
                            ? AppColors.border
                            : isDone
                                ? AppColors.accentPrimary
                                : AppColors.textPrimary,
                        width: 2,
                      ),
                    ),
                    child: isDone
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 12)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.name,
                          style: AppTypography.body.copyWith(
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : null,
                          )),
                      Text(
                        '${_scheduleLabel(task)} · ${task.reminderTime}',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _scheduleLabel(Task task) {
    return switch (task.schedule) {
      'daily'         => 'Daily',
      'weekly'        => 'Weekly (${task.scheduleOn ?? ''})',
      'monthly'       => 'Monthly (day ${task.scheduleOn ?? ''})',
      'yearly'        => 'Yearly (${task.scheduleOn ?? ''})',
      'specific_date' => task.scheduleOn ?? 'Once',
      _               => task.schedule,
    };
  }
}
