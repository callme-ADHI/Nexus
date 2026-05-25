import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/database/app_database.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../shared/theme/app_theme.dart';
import '../graph/goal_detail_sheet.dart';

class AllGoalsPage extends ConsumerStatefulWidget {
  const AllGoalsPage({super.key});

  @override
  ConsumerState<AllGoalsPage> createState() => _AllGoalsPageState();
}

class _AllGoalsPageState extends ConsumerState<AllGoalsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  GoalStatus? _selectedStatusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goalGraphAsync = ref.watch(goalGraphProvider);
    final tasksAsync = ref.watch(allTasksProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ALL GOALS',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withValues(alpha: 0.1),
            height: 1,
          ),
        ),
      ),
      body: goalGraphAsync.when(
        data: (goals) {
          return tasksAsync.when(
            data: (tasks) {
              return _buildContent(goals, tasks);
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white24, strokeWidth: 1),
            ),
            error: (e, _) => Center(
              child: Text('Error: $e', style: GoogleFonts.inter(color: Colors.red)),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white24, strokeWidth: 1),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e', style: GoogleFonts.inter(color: Colors.red)),
        ),
      ),
    );
  }

  Widget _buildContent(List<GoalWithProgress> goals, List<Task> tasks) {
    // 1. Group tasks by goalId
    final goalTasksMap = <String, List<Task>>{};
    for (final task in tasks) {
      if (task.goalId != null) {
        goalTasksMap[task.goalId!] ??= [];
        goalTasksMap[task.goalId!]!.add(task);
      }
    }

    // 2. Count goals per status
    final totalCount = goals.length;
    final inProgressCount = goals.where((g) => g.status == GoalStatus.inProgress).length;
    final blockedCount = goals.where((g) => g.status == GoalStatus.blocked).length;
    final overdueCount = goals.where((g) => g.status == GoalStatus.overdue).length;
    final completedCount = goals.where((g) => g.status == GoalStatus.completed).length;

    // 3. Map for goal names (to lookup blocked-by dependencies)
    final goalMap = {for (final g in goals) (g.goal as Goal).id: g.goal as Goal};

    // 4. Apply search & status filter
    var filteredGoals = goals;
    if (_selectedStatusFilter != null) {
      filteredGoals = filteredGoals.where((g) => g.status == _selectedStatusFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filteredGoals = filteredGoals.where((g) {
        final goalObj = g.goal as Goal;
        return goalObj.name.toLowerCase().contains(q) ||
            (goalObj.aim?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // 5. Sort filtered goals: Overdue first, then Blocked, then In Progress, then Not Started, then Completed.
    // Within same status, sort by weight descending.
    filteredGoals = List<GoalWithProgress>.from(filteredGoals)..sort((a, b) {
      final order = {
        GoalStatus.overdue: 0,
        GoalStatus.blocked: 1,
        GoalStatus.inProgress: 2,
        GoalStatus.notStarted: 3,
        GoalStatus.completed: 4,
      };
      final weightA = order[a.status] ?? 5;
      final weightB = order[b.status] ?? 5;
      if (weightA != weightB) return weightA.compareTo(weightB);
      
      final goalA = a.goal as Goal;
      final goalB = b.goal as Goal;
      return goalB.weight.compareTo(goalA.weight);
    });

    return CustomScrollView(
      slivers: [
        // Horizontal scrollable stats cards (filter tabs)
        SliverToBoxAdapter(
          child: Container(
            height: 75,
            margin: const EdgeInsets.only(top: 14, bottom: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _StatCard(
                  label: 'ALL GOALS',
                  count: totalCount,
                  icon: Icons.grid_view_rounded,
                  color: AppColors.accentBlue,
                  isSelected: _selectedStatusFilter == null,
                  onTap: () => setState(() => _selectedStatusFilter = null),
                ),
                _StatCard(
                  label: 'ACTIVE',
                  count: inProgressCount,
                  icon: Icons.play_circle_fill_rounded,
                  color: AppColors.nodeBorderInProgress,
                  isSelected: _selectedStatusFilter == GoalStatus.inProgress,
                  onTap: () => setState(() => _selectedStatusFilter = GoalStatus.inProgress),
                ),
                _StatCard(
                  label: 'BLOCKED',
                  count: blockedCount,
                  icon: Icons.lock_rounded,
                  color: Colors.amber,
                  isSelected: _selectedStatusFilter == GoalStatus.blocked,
                  onTap: () => setState(() => _selectedStatusFilter = GoalStatus.blocked),
                ),
                _StatCard(
                  label: 'OVERDUE',
                  count: overdueCount,
                  icon: Icons.error_rounded,
                  color: AppColors.nodeBorderOverdue,
                  isSelected: _selectedStatusFilter == GoalStatus.overdue,
                  onTap: () => setState(() => _selectedStatusFilter = GoalStatus.overdue),
                ),
                _StatCard(
                  label: 'COMPLETED',
                  count: completedCount,
                  icon: Icons.check_circle_rounded,
                  color: AppColors.nodeBorderCompleted,
                  isSelected: _selectedStatusFilter == GoalStatus.completed,
                  onTap: () => setState(() => _selectedStatusFilter = GoalStatus.completed),
                ),
              ],
            ),
          ),
        ),

        // Search Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
                hintText: 'Search goals...',
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Icon(Icons.close, color: Colors.white38, size: 16),
                      )
                    : null,
              ),
            ),
          ),
        ),

        // Goals List
        if (filteredGoals.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.assignment_outlined,
                    color: Colors.white24,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty ? 'No goals match your search.' : 'No goals in this category.',
                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final gwp = filteredGoals[index];
                  final goal = gwp.goal as Goal;
                  final goalTasks = goalTasksMap[goal.id] ?? [];
                  final subGoalsCount = goals.where((g) => (g.goal as Goal).parentId == goal.id).length;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _GoalCard(
                      gwp: gwp,
                      goal: goal,
                      taskCount: goalTasks.length,
                      subGoalsCount: subGoalsCount,
                      goalMap: goalMap,
                    ),
                  );
                },
                childCount: filteredGoals.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 105,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 16),
                Text(
                  '$count',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final GoalWithProgress gwp;
  final Goal goal;
  final int taskCount;
  final int subGoalsCount;
  final Map<String, Goal> goalMap;

  const _GoalCard({
    required this.gwp,
    required this.goal,
    required this.taskCount,
    required this.subGoalsCount,
    required this.goalMap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(gwp.status);
    final statusBg = _getStatusBg(gwp.status);
    final statusBorder = _getStatusBorder(gwp.status);

    // Calculate incomplete dependencies for blocked goals
    final incompleteDeps = gwp.status == GoalStatus.blocked
        ? gwp.dependsOnIds.where((depId) {
            final depGoal = goalMap[depId];
            return depGoal == null || depGoal.status != 'completed';
          }).map((depId) => goalMap[depId]?.name ?? depId).toList()
        : <String>[];

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => GoalDetailSheet(goal: goal),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: statusBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: statusBorder.withValues(alpha: 0.35),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: statusBorder.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Goal Name & Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (goal.aim != null && goal.aim!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          goal.aim!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white60,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _StatusBadge(status: gwp.status),
              ],
            ),

            const SizedBox(height: 16),

            // Progress Bar Row
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: gwp.effectiveProgress / 100,
                      backgroundColor: Colors.white.withValues(alpha: 0.04),
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${gwp.effectiveProgress.round()}%',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Footer Metadata Row: Timeframe, Task Count, Sub-goals Count
            Row(
              children: [
                // Timeframe/Deadline
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: Colors.white38, size: 12),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${goal.timeframe} · Ends ${_formatDate(goal.deadline)}',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white38,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Tasks count indicator
                if (taskCount > 0) ...[
                  Row(
                    children: [
                      const Icon(Icons.assignment_outlined, color: Colors.white38, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '$taskCount',
                        style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                ],

                // Sub-goals indicator
                if (subGoalsCount > 0)
                  Row(
                    children: [
                      const Icon(Icons.account_tree_outlined, color: Colors.white38, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '$subGoalsCount',
                        style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // Blocked by dependency details
            if (incompleteDeps.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 14),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.15),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_outline_rounded, color: Colors.amber, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BLOCKED BY DEPENDENCY',
                            style: GoogleFonts.inter(
                              color: Colors.amber,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            incompleteDeps.join(', '),
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 11,
                              height: 1.2,
                            ),
                          ),
                        ],
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

  Color _getStatusColor(GoalStatus status) {
    switch (status) {
      case GoalStatus.completed: return AppColors.nodeBorderCompleted;
      case GoalStatus.inProgress: return AppColors.nodeBorderInProgress;
      case GoalStatus.blocked: return Colors.amber;
      case GoalStatus.overdue: return AppColors.nodeBorderOverdue;
      case GoalStatus.notStarted: return Colors.white38;
    }
  }

  Color _getStatusBg(GoalStatus status) {
    switch (status) {
      case GoalStatus.completed: return AppColors.nodeCompleted;
      case GoalStatus.inProgress: return AppColors.nodeInProgress;
      case GoalStatus.blocked: return AppColors.nodeBlocked;
      case GoalStatus.overdue: return AppColors.nodeOverdue;
      case GoalStatus.notStarted: return AppColors.nodeNotStarted;
    }
  }

  Color _getStatusBorder(GoalStatus status) {
    switch (status) {
      case GoalStatus.completed: return AppColors.nodeBorderCompleted;
      case GoalStatus.inProgress: return AppColors.nodeBorderInProgress;
      case GoalStatus.blocked: return AppColors.nodeBorderBlocked;
      case GoalStatus.overdue: return AppColors.nodeBorderOverdue;
      case GoalStatus.notStarted: return AppColors.nodeBorderNotStarted;
    }
  }

  String _formatDate(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class _StatusBadge extends StatelessWidget {
  final GoalStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
    final label = _getStatusLabel(status);
    final icon = _getStatusIcon(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 10),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(GoalStatus status) {
    switch (status) {
      case GoalStatus.completed: return AppColors.nodeBorderCompleted;
      case GoalStatus.inProgress: return AppColors.nodeBorderInProgress;
      case GoalStatus.blocked: return Colors.amber;
      case GoalStatus.overdue: return AppColors.nodeBorderOverdue;
      case GoalStatus.notStarted: return Colors.white38;
    }
  }

  String _getStatusLabel(GoalStatus status) {
    switch (status) {
      case GoalStatus.completed: return 'COMPLETED';
      case GoalStatus.inProgress: return 'ACTIVE';
      case GoalStatus.blocked: return 'BLOCKED';
      case GoalStatus.overdue: return 'OVERDUE';
      case GoalStatus.notStarted: return 'NOT STARTED';
    }
  }

  IconData _getStatusIcon(GoalStatus status) {
    switch (status) {
      case GoalStatus.completed: return Icons.check_circle_rounded;
      case GoalStatus.inProgress: return Icons.play_arrow_rounded;
      case GoalStatus.blocked: return Icons.lock_rounded;
      case GoalStatus.overdue: return Icons.error_rounded;
      case GoalStatus.notStarted: return Icons.help_outline_rounded;
    }
  }
}
