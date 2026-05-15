import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/database/app_database.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../shared/theme/app_theme.dart';
import '../graph/goal_detail_sheet.dart';

class AllGoalsPage extends ConsumerWidget {
  const AllGoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(allGoalsProvider);

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
      body: goalsAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            return Center(
              child: Text(
                'No goals yet.',
                style: GoogleFonts.inter(color: Colors.white38),
              ),
            );
          }

          // Sort goals: In Progress first, then Not Started, then Completed/Others
          final sortedGoals = List<Goal>.from(goals)..sort((a, b) {
            final order = {'in_progress': 0, 'not_started': 1, 'blocked': 2, 'overdue': 3, 'completed': 4};
            final weightA = order[a.status] ?? 5;
            final weightB = order[b.status] ?? 5;
            if (weightA != weightB) return weightA.compareTo(weightB);
            return (b.weight ?? 0).compareTo(a.weight ?? 0);
          });

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: sortedGoals.length,
            separatorBuilder: (context, index) => const Divider(
              color: Colors.white10,
              height: 1,
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              final goal = sortedGoals[index];
              return _GoalListTile(goal: goal);
            },
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
}

class _GoalListTile extends StatelessWidget {
  final Goal goal;
  const _GoalListTile({required this.goal});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => GoalDetailSheet(goal: goal),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _StatusIndicator(status: goal.status),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.name,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (goal.aim != null && goal.aim!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      goal.aim!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
          ],
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final String status;
  const _StatusIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    Color c;
    switch (status.toLowerCase()) {
      case 'completed':
        c = const Color(0xFF27AE60);
        break;
      case 'in_progress':
        c = AppColors.accentBlue;
        break;
      case 'blocked':
        c = Colors.white38;
        break;
      case 'overdue':
        c = const Color(0xFFE74C3C);
        break;
      default:
        c = Colors.white24;
    }

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
      ),
    );
  }
}
