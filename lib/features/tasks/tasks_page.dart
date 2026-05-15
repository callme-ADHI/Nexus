import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../core/database/app_database.dart';
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
    _tabCtrl = TabController(length: 5, vsync: this);
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
    final completedCompletions = ref.watch(completedCompletionsProvider);
    final allTasks = ref.watch(allTasksProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Minimal Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TASKS',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const AddTaskForm(),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),

            // ── Minimal Tab Bar ─────────────────────────────────────────────
            TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: Colors.white,
              indicatorWeight: 1,
              dividerColor: const Color(0xFF222222),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF666666),
              labelStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              labelPadding: const EdgeInsets.symmetric(horizontal: 24),
              tabs: const [
                Tab(text: 'Today'),
                Tab(text: 'Missed'),
                Tab(text: 'Upcoming'),
                Tab(text: 'All'),
                Tab(text: 'Completed'),
              ],
            ),

            // ── Goal Filter ───────────────────────────────────────────────
            allGoals.when(
              data: (goals) => goals.isEmpty
                  ? const SizedBox.shrink()
                  : Container(
                      height: 56,
                      alignment: Alignment.centerLeft,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        children: [
                          _FilterChip(
                            label: 'All',
                            selected: _filterGoalId == null,
                            onTap: () => setState(() => _filterGoalId = null),
                          ),
                          const SizedBox(width: 12),
                          ...goals.map((g) => Padding(
                                padding: const EdgeInsets.only(right: 12),
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

            // ── Content ───────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _TodaySection(
                    completions: todayCompletions,
                    allTasks: allTasks,
                    filterGoalId: _filterGoalId,
                    ref: ref,
                  ),
                  _MissedSection(
                    completions: missedCompletions,
                    allTasks: allTasks,
                    filterGoalId: _filterGoalId,
                    ref: ref,
                  ),
                  _UpcomingSection(
                    allTasks: allTasks,
                    filterGoalId: _filterGoalId,
                    ref: ref,
                  ),
                  _AllSection(
                    allTasks: allTasks,
                    filterGoalId: _filterGoalId,
                    ref: ref,
                  ),
                  _CompletedSection(
                    completions: completedCompletions,
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

// ── Components ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: selected ? Colors.white : const Color(0xFF444444),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? Colors.black : const Color(0xFFAAAAAA),
            ),
          ),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState(this.text);

  @override
  Widget build(BuildContext context) => Center(
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

class _MinimalTaskRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDone;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onLongPress;

  const _MinimalTaskRow({
    required this.title,
    required this.subtitle,
    this.isDone = false,
    this.onToggle,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle == null ? null : () => onToggle!(!isDone),
      onLongPress: onLongPress,
      splashColor: Colors.transparent,
      highlightColor: const Color(0xFF111111),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (onToggle != null) ...[
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
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: isDone ? const Color(0xFF555555) : Colors.white,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      decorationColor: const Color(0xFF555555),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: isDone ? const Color(0xFF444444) : const Color(0xFF888888),
                    ),
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

// ── Tab Sections ────────────────────────────────────────────────────────────

class _TodaySection extends StatelessWidget {
  final AsyncValue<List<TaskCompletion>> completions;
  final AsyncValue<List<Task>> allTasks;
  final String? filterGoalId;
  final WidgetRef ref;

  const _TodaySection({
    required this.completions,
    required this.allTasks,
    this.filterGoalId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return completions.when(
      data: (comps) => allTasks.when(
        data: (tasks) {
          final taskMap = {for (final t in tasks) t.id: t};
          var filtered = comps.where((c) {
            final t = taskMap[c.taskId];
            if (t == null) return false;
            if (filterGoalId != null && t.goalId != filterGoalId) return false;
            return true;
          }).toList();

          if (filtered.isEmpty) return const _EmptyState('No tasks for today.');

          filtered.sort((a, b) {
            if (a.completedDate != null && b.completedDate == null) return 1;
            if (a.completedDate == null && b.completedDate != null) return -1;
            return (taskMap[a.taskId]?.reminderTime ?? '').compareTo(taskMap[b.taskId]?.reminderTime ?? '');
          });

          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final c = filtered[i];
              final t = taskMap[c.taskId]!;
              return _MinimalTaskRow(
                title: t.name,
                subtitle: t.reminderTime,
                isDone: c.completedDate != null,
                onToggle: (done) {
                  if (done) {
                    ref.read(taskNotifierProvider.notifier).completeTask(taskId: c.taskId, scheduledDate: c.scheduledDate);
                  } else {
                    ref.read(taskNotifierProvider.notifier).uncompleteTask(taskId: c.taskId, scheduledDate: c.scheduledDate);
                  }
                },
                onLongPress: () => _showTaskOptions(context, ref, t),
              );
            },
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _MissedSection extends StatelessWidget {
  final AsyncValue<List<TaskCompletion>> completions;
  final AsyncValue<List<Task>> allTasks;
  final String? filterGoalId;
  final WidgetRef ref;

  const _MissedSection({
    required this.completions,
    required this.allTasks,
    this.filterGoalId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return completions.when(
      data: (comps) => allTasks.when(
        data: (tasks) {
          final taskMap = {for (final t in tasks) t.id: t};
          var filtered = comps.where((c) {
            final t = taskMap[c.taskId];
            if (t == null) return false;
            if (filterGoalId != null && t.goalId != filterGoalId) return false;
            return true;
          }).toList();

          if (filtered.isEmpty) return const _EmptyState('No missed tasks.');

          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final c = filtered[i];
              final t = taskMap[c.taskId]!;
              final d = DateTime.fromMillisecondsSinceEpoch(c.scheduledDate);
              return _MinimalTaskRow(
                title: t.name,
                subtitle: 'Missed on ${d.month}/${d.day}',
                isDone: false,
                onToggle: (done) {
                  if (done) {
                    ref.read(taskNotifierProvider.notifier).completeTask(taskId: c.taskId, scheduledDate: c.scheduledDate);
                  }
                },
                onLongPress: () => _showTaskOptions(context, ref, t),
              );
            },
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _UpcomingSection extends StatelessWidget {
  final AsyncValue<List<Task>> allTasks;
  final String? filterGoalId;
  final WidgetRef ref;

  const _UpcomingSection({
    required this.allTasks,
    this.filterGoalId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return allTasks.when(
      data: (tasks) {
        var filtered = tasks.where((t) {
          if (t.isActive == 0) return false;
          if (filterGoalId != null && t.goalId != filterGoalId) return false;
          return true;
        }).toList();

        if (filtered.isEmpty) return const _EmptyState('No upcoming tasks.');

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (ctx, i) {
            final t = filtered[i];
            return _MinimalTaskRow(
              title: t.name,
              subtitle: t.schedule == 'specific_date' 
                  ? 'Scheduled for ${t.scheduleOn} at ${t.reminderTime}'
                  : 'Repeats: ${t.schedule} at ${t.reminderTime}',
              onLongPress: () => _showTaskOptions(context, ref, t),
            );
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _AllSection extends StatelessWidget {
  final AsyncValue<List<Task>> allTasks;
  final String? filterGoalId;
  final WidgetRef ref;

  const _AllSection({
    required this.allTasks,
    this.filterGoalId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return allTasks.when(
      data: (tasks) {
        var filtered = tasks.where((t) {
          if (filterGoalId != null && t.goalId != filterGoalId) return false;
          return true;
        }).toList();

        if (filtered.isEmpty) return const _EmptyState('No tasks created.');

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (ctx, i) {
            final t = filtered[i];
            return _MinimalTaskRow(
              title: t.name,
              subtitle: t.isActive == 1 ? 'Active' : 'Inactive',
              onLongPress: () => _showTaskOptions(context, ref, t),
            );
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _CompletedSection extends StatelessWidget {
  final AsyncValue<List<TaskCompletion>> completions;
  final AsyncValue<List<Task>> allTasks;
  final AsyncValue<List<Goal>> allGoals;
  final String? filterGoalId;
  final WidgetRef ref;

  const _CompletedSection({
    required this.completions,
    required this.allTasks,
    required this.allGoals,
    this.filterGoalId,
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
            var filtered = comps.where((c) {
              final t = taskMap[c.taskId];
              if (t == null) return false;
              if (filterGoalId != null && t.goalId != filterGoalId) return false;
              return true;
            }).toList();

            if (filtered.isEmpty) return const _EmptyState('No completed tasks.');

            return ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (ctx, i) {
                final c = filtered[i];
                final t = taskMap[c.taskId]!;
                final g = goalMap[t.goalId];
                
                final scheduledD = DateTime.fromMillisecondsSinceEpoch(c.scheduledDate);
                final completedD = DateTime.fromMillisecondsSinceEpoch(c.completedDate!);
                
                final scheduledStr = '${scheduledD.month.toString().padLeft(2, '0')}/${scheduledD.day.toString().padLeft(2, '0')}/${scheduledD.year}';
                final completedStr = '${completedD.month.toString().padLeft(2, '0')}/${completedD.day.toString().padLeft(2, '0')} at ${completedD.hour.toString().padLeft(2, '0')}:${completedD.minute.toString().padLeft(2, '0')}';

                return GestureDetector(
                  onLongPress: () => _showTaskOptions(context, ref, t),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                t.name,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Icon(Icons.check_circle, color: Color(0xFF27AE60), size: 18),
                          ],
                        ),
                        if (g != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.track_changes, color: Colors.white38, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                g.name.toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  letterSpacing: 1.0,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white38,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white10, height: 1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'SCHEDULED FOR',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 9,
                                      letterSpacing: 1.0,
                                      color: Colors.white38,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    scheduledStr,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'COMPLETED ON',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 9,
                                      letterSpacing: 1.0,
                                      color: Colors.white38,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    completedStr,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

void _showTaskOptions(BuildContext context, WidgetRef ref, Task task) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.only(bottom: 32, top: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.white),
            title: const Text('Edit Task', style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
            onTap: () {
              Navigator.pop(ctx);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AddTaskForm(taskToEdit: task),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Color(0xFFE74C3C)),
            title: const Text('Delete Task', style: TextStyle(color: Color(0xFFE74C3C), fontFamily: 'Inter')),
            onTap: () {
              Navigator.pop(ctx);
              _confirmDeleteTask(context, ref, task);
            },
          ),
        ],
      ),
    ),
  );
}

void _confirmDeleteTask(BuildContext context, WidgetRef ref, Task task) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF0A0A0A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white12)),
      title: const Text('Delete Task', style: TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
      content: const Text('Are you sure you want to delete this task? This will permanently remove all associated progress.', style: TextStyle(color: Colors.white70, fontFamily: 'Inter')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54, fontFamily: 'Inter'))),
        TextButton(
          onPressed: () {
            ref.read(taskNotifierProvider.notifier).deleteTask(task.id);
            Navigator.pop(ctx);
          },
          child: const Text('Delete', style: TextStyle(color: Color(0xFFE74C3C), fontFamily: 'Inter')),
        ),
      ],
    ),
  );
}
