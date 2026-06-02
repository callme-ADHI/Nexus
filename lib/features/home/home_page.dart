import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/providers.dart';
import '../../core/database/app_database.dart';
import '../../core/models/models.dart';
import '../graph/goal_detail_sheet.dart';
import '../../shared/widgets/nexus_logo.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile          = ref.watch(profileProvider);
    final goalGraph        = ref.watch(goalGraphProvider);
    final todayCompletions = ref.watch(todayCompletionsProvider);
    final allTasks         = ref.watch(allTasksProvider);
    final blockedIds       = ref.watch(blockedGoalIdsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Minimal Header ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: profile.when(
                  data: (p) => _MinimalHeader(name: p?.displayName ?? 'You'),
                  loading: () => const _MinimalHeader(name: 'You'),
                  error: (_, __) => const _MinimalHeader(name: 'You'),
                ),
              ),
            ),

            // ── Progress Banner ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: todayCompletions.when(
                data: (comps) {
                  if (comps.isEmpty) return const SizedBox.shrink();
                  final done = comps.where((c) => c.completedDate != null).length;
                  final total = comps.length;
                  final pct = total > 0 ? done / total : 0.0;
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'DAILY PROGRESS',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white38,
                              ),
                            ),
                            Text(
                              '$done / $total',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: pct,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // ── Tasks Header ────────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(28, 28, 24, 12),
                child: Text(
                  'TODAY\'S TASKS',
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

            // ── Tasks List ──────────────────────────────────────────────────
            todayCompletions.when(
              data: (completions) => allTasks.when(
                data: (tasks) {
                  if (completions.isEmpty) {
                    return const SliverToBoxAdapter(child: _EmptyState('No tasks for today.'));
                  }
                  final taskMap = {for (final t in tasks) t.id: t};
                  return blockedIds.when(
                    data: (blocked) {
                      final sorted = [...completions]
                        ..removeWhere((c) {
                          final t = taskMap[c.taskId];
                          return t != null &&
                              t.goalId != null &&
                              blocked.contains(t.goalId);
                        })
                        ..sort((a, b) {
                          // Sort tasks: incomplete first, then Task of the Day first, then by reminder time
                          if (a.completedDate != null && b.completedDate == null) return 1;
                          if (a.completedDate == null && b.completedDate != null) return -1;
                          
                          final tA = taskMap[a.taskId];
                          final tB = taskMap[b.taskId];
                          if (tA != null && tB != null) {
                            if (tA.isTaskOfTheDay && !tB.isTaskOfTheDay) return -1;
                            if (!tA.isTaskOfTheDay && tB.isTaskOfTheDay) return 1;
                            return tA.reminderTime.compareTo(tB.reminderTime);
                          }
                          return 0;
                        });

                      if (sorted.isEmpty) {
                        return const SliverToBoxAdapter(child: _EmptyState('No tasks for today.'));
                      }

                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final c = sorted[i];
                            final task = taskMap[c.taskId];
                            if (task == null) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0A0A0A),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                ),
                                child: _MinimalTaskRow(
                                  completion: c,
                                  task: task,
                                  onToggle: (done) {
                                    if (done) {
                                      ref.read(taskNotifierProvider.notifier).completeTask(taskId: c.taskId, scheduledDate: c.scheduledDate);
                                    } else {
                                      ref.read(taskNotifierProvider.notifier).uncompleteTask(taskId: c.taskId, scheduledDate: c.scheduledDate);
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                          childCount: sorted.length,
                        ),
                      );
                    },
                    loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                    error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator(color: Colors.white24, strokeWidth: 2)),
                ),
              ),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            // ── View All Tasks Action ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: InkWell(
                  onTap: () {
                    ref.read(pageIndexProvider.notifier).state = 2; // Tasks Page
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      borderRadius: BorderRadius.circular(12),
                    ),
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
              ),
            ),

            // ── Active Goals Header ─────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(28, 28, 24, 12),
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

            // ── Active Goals List ───────────────────────────────────────────
            goalGraph.when(
              data: (goals) {
                final active = goals.where((g) => g.status != GoalStatus.completed && g.status != GoalStatus.blocked).toList();
                active.sort((a, b) => (b.goal.weight ?? 0).compareTo(a.goal.weight ?? 0));
                
                if (active.isEmpty) {
                  return const SliverToBoxAdapter(child: _EmptyState('No active goals.'));
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final g = active[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0, left: 24, right: 24),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A0A0A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: _MinimalGoalRow(
                            goalWP: g,
                            onTap: () => _openGoalDetail(context, g.goal as Goal),
                          ),
                        ),
                      );
                    },
                    childCount: math.min(active.length, 5),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
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
    final isTotd = task.isTaskOfTheDay;
    
    return InkWell(
      onTap: () => onToggle(!isDone),
      splashColor: Colors.transparent,
      highlightColor: const Color(0xFF111111),
      child: Container(
        decoration: BoxDecoration(
          border: isTotd
              ? Border(left: BorderSide(color: Colors.amber.withValues(alpha: 0.8), width: 3))
              : null,
          color: isTotd ? Colors.amber.withValues(alpha: 0.03) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isTotd ? 17 : 20,
          vertical: 14,
        ),
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
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      task.name,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: isTotd ? FontWeight.w600 : FontWeight.w400,
                        color: isDone ? const Color(0xFF555555) : (isTotd ? Colors.amber : Colors.white),
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        decorationColor: const Color(0xFF555555),
                      ),
                    ),
                  ),
                  if (isTotd) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'TASK OF THE DAY',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
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
    final progress = goalWP.effectiveProgress.round().clamp(0, 100);

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: const Color(0xFF111111),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    goal.name,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
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
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(1.5),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress / 100.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
