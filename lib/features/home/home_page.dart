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
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: profile.when(
                  data: (p) => _MinimalHeader(name: p?.displayName ?? 'You'),
                  loading: () => const _MinimalHeader(name: 'You'),
                  error: (_, __) => const _MinimalHeader(name: 'You'),
                ),
              ),
            ),

            // ── Tasks Frame ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TASKS',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                letterSpacing: 2.0,
                                fontWeight: FontWeight.w700,
                                color: Colors.white70,
                              ),
                            ),
                            todayCompletions.when(
                              data: (comps) {
                                final done = comps.where((c) => c.completedDate != null).length;
                                return Text(
                                  '$done / ${comps.length}',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF444444),
                                  ),
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      Expanded(
                        child: todayCompletions.when(
                          data: (completions) => allTasks.when(
                            data: (tasks) {
                              if (completions.isEmpty) {
                                return const Center(child: _EmptyState('No tasks for today.'));
                              }
                              final taskMap = {for (final t in tasks) t.id: t};
                              final sorted = [...completions]..sort((a, b) {
                                if (a.completedDate != null && b.completedDate == null) return 1;
                                if (a.completedDate == null && b.completedDate != null) return -1;
                                return (taskMap[a.taskId]?.reminderTime ?? '').compareTo(taskMap[b.taskId]?.reminderTime ?? '');
                              });

                              return ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: sorted.length,
                                itemBuilder: (ctx, i) {
                                  final c = sorted[i];
                                  final task = taskMap[c.taskId];
                                  if (task == null) return const SizedBox.shrink();
                                  return _MinimalTaskRow(
                                    completion: c,
                                    task: task,
                                    onToggle: (done) {
                                      if (done) {
                                        ref.read(taskNotifierProvider.notifier).completeTask(taskId: c.taskId, scheduledDate: c.scheduledDate);
                                      } else {
                                        ref.read(taskNotifierProvider.notifier).uncompleteTask(taskId: c.taskId, scheduledDate: c.scheduledDate);
                                      }
                                    },
                                  );
                                },
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                          loading: () => const Center(child: CircularProgressIndicator(color: Colors.white24, strokeWidth: 2)),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      InkWell(
                        onTap: () {
                          ref.read(pageIndexProvider.notifier).state = 2; // Tasks Page
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          child: const Text(
                            'VIEW ALL TASKS',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Active Goals ───────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(28, 40, 24, 16),
                child: Text(
                  'MAIN GOALS',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w700,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: goalGraph.when(
                data: (goals) {
                  final active = goals.where((g) => g.status != GoalStatus.completed && g.status != GoalStatus.blocked).toList();
                  active.sort((a, b) => (b.goal.weight ?? 0).compareTo(a.goal.weight ?? 0));
                  
                  if (active.isEmpty) {
                    return const _EmptyState('No active goals.');
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: active.take(5).map((g) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, left: 24, right: 24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0A0A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: _MinimalGoalRow(
                          goalWP: g,
                          onTap: () => _openGoalDetail(context, g.goal as Goal),
                        ),
                      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
