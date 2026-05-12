import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/providers.dart';
import '../../core/database/app_database.dart';
import '../../core/models/models.dart';
import '../../shared/theme/app_theme.dart';
import '../graph/goal_detail_sheet.dart';
import '../tasks/add_task_form.dart';
import '../../shared/widgets/nexus_logo.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile          = ref.watch(profileProvider);
    final goalGraph        = ref.watch(goalGraphProvider);
    final todayCompletions = ref.watch(todayCompletionsProvider);
    final allTasks         = ref.watch(allTasksProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Minimal Header ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                child: profile.when(
                  data: (p) => _MinimalHeader(name: p?.displayName ?? 'You'),
                  loading: () => const _MinimalHeader(name: 'You'),
                  error: (_, __) => const _MinimalHeader(name: 'You'),
                ),
              ),
            ),

            // ── Today's Tasks ───────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Text(
                  'TODAY',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
            ),

            todayCompletions.when(
              data: (completions) => allTasks.when(
                data: (tasks) {
                  if (completions.isEmpty) {
                    return const SliverToBoxAdapter(child: _EmptyState('No tasks for today.'));
                  }
                  final taskMap = {for (final t in tasks) t.id: t};
                  final sorted = [...completions]..sort((a, b) {
                      if (a.completedDate != null && b.completedDate == null) return 1;
                      if (a.completedDate == null && b.completedDate != null) return -1;
                      return (taskMap[a.taskId]?.reminderTime ?? '')
                          .compareTo(taskMap[b.taskId]?.reminderTime ?? '');
                    });
                  
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final c = sorted[i];
                        final task = taskMap[c.taskId];
                        if (task == null) return const SizedBox.shrink();
                        return _MinimalTaskRow(
                          completion: c,
                          task: task,
                          onToggle: (done) {
                            if (done) {
                              ref.read(taskNotifierProvider.notifier).completeTask(
                                taskId: c.taskId, scheduledDate: c.scheduledDate);
                            } else {
                              ref.read(taskNotifierProvider.notifier).uncompleteTask(
                                taskId: c.taskId, scheduledDate: c.scheduledDate);
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
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            // ── Active Goals ───────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 48, 24, 16),
                child: Text(
                  'ACTIVE GOALS',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: goalGraph.when(
                data: (goals) {
                  final active = goals.where((g) =>
                      g.status != GoalStatus.completed &&
                      g.status != GoalStatus.blocked).toList();
                  
                  if (active.isEmpty) {
                    return const _EmptyState('No active goals.');
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: active.map((g) => _MinimalGoalRow(
                      goalWP: g,
                      onTap: () => _openGoalDetail(context, g.goal as Goal),
                    )).toList(),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  void _openGoalDetail(BuildContext context, Goal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GoalDetailSheet(goal: goal),
    );
  }
}

// ── Minimal Components ──────────────────────────────────────────────────

class _MinimalHeader extends StatelessWidget {
  final String name;
  const _MinimalHeader({required this.name});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMMM d, yyyy').format(DateTime.now());
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateStr.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                letterSpacing: 2.0,
                color: Color(0xFF666666),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 28,
                fontWeight: FontWeight.w300,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: NexusLogo(size: 28, color: Colors.white24),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF444444),
        ),
      ),
    );
  }
}

class _MinimalTaskRow extends StatelessWidget {
  final TaskCompletion completion;
  final Task task;
  final ValueChanged<bool> onToggle;

  const _MinimalTaskRow({
    required this.completion,
    required this.task,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = completion.completedDate != null;
    
    return InkWell(
      onTap: () => onToggle(!isDone),
      splashColor: Colors.transparent,
      highlightColor: const Color(0xFF111111),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone ? Colors.white : const Color(0xFF333333),
                  width: 1.5,
                ),
                color: isDone ? Colors.white : Colors.transparent,
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 12, color: Colors.black)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                task.name,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: isDone ? const Color(0xFF555555) : Colors.white,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  decorationColor: const Color(0xFF555555),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              task.reminderTime,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: isDone ? const Color(0xFF444444) : const Color(0xFF888888),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MinimalGoalRow extends StatelessWidget {
  final GoalWithProgress goalWP;
  final VoidCallback onTap;

  const _MinimalGoalRow({required this.goalWP, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final goal = goalWP.goal as Goal;
    final progress = goalWP.effectiveProgress.round();

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: const Color(0xFF111111),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                goal.name,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '$progress%',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF888888),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
