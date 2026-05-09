import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/providers/providers.dart';
import '../../core/database/app_database.dart';
import '../../core/models/models.dart';
import '../../shared/theme/app_theme.dart';
import '../graph/goal_detail_sheet.dart';

class ProgressPage extends ConsumerWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalGraph = ref.watch(goalGraphProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.sectionSpacing),
                child: Text('Progress', style: AppTypography.pageTitle),
              ),
            ),

            // ── Goal progress rings ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.titleContentGap),
                child: Text('Goal Progress', style: AppTypography.sectionHeader),
              ),
            ),

            goalGraph.when(
              data: (goals) {
                final active = goals
                    .where((g) => g.status != GoalStatus.completed)
                    .toList();
                if (active.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Text('No active goals.',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _ProgressCard(
                        gwp: active[i],
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) =>
                              GoalDetailSheet(goal: active[i].goal as Goal),
                        ),
                      ),
                      childCount: active.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) =>
                  const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            // ── Weekly chart ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.sectionSpacing, AppSpacing.xl, AppSpacing.titleContentGap),
                child: Text('This Week', style: AppTypography.sectionHeader),
              ),
            ),

            const SliverToBoxAdapter(child: _WeeklyChart()),

            // ── Time warnings ────────────────────────────────────────────
            goalGraph.when(
              data: (goals) {
                final warnings = goals
                    .where((g) => g.hasTimeWarning)
                    .toList()
                  ..sort((a, b) => ((b.timeElapsedPct - b.effectiveProgress) -
                          (a.timeElapsedPct - a.effectiveProgress))
                      .toInt());

                if (warnings.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

                return SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl, AppSpacing.sectionSpacing, AppSpacing.xl, AppSpacing.titleContentGap),
                      child: Text('Needs Attention',
                          style: AppTypography.sectionHeader),
                    ),
                    ...warnings.map((g) => Padding(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: AppRadius.card,
                              border: Border(
                                left: const BorderSide(
                                    color: AppColors.warning, width: 3),
                                top: BorderSide(color: AppColors.border),
                                right: BorderSide(color: AppColors.border),
                                bottom: BorderSide(color: AppColors.border),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text((g.goal as Goal).name,
                                    style: AppTypography.cardTitle),
                                const SizedBox(height: 4),
                                Text(
                                  'Time elapsed: ${g.timeElapsedPct.round()}% | Progress: ${g.effectiveProgress.round()}%',
                                  style: AppTypography.caption
                                      .copyWith(color: AppColors.warning),
                                ),
                              ],
                            ),
                          ),
                        )),
                  ]),
                );
              },
              loading: () =>
                  const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, __) =>
                  const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            // Completed goals section
            goalGraph.when(
              data: (goals) {
                final completed = goals
                    .where((g) => g.status == GoalStatus.completed)
                    .toList();
                if (completed.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl, AppSpacing.sectionSpacing, AppSpacing.xl, AppSpacing.md),
                      child: Text('Completed', style: AppTypography.sectionHeader),
                    ),
                    ...completed.map((g) => Padding(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.nodeCompleted,
                              borderRadius: AppRadius.card,
                              border: Border.all(
                                  color: AppColors.nodeBorderCompleted),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: AppColors.success),
                                const SizedBox(width: 12),
                                Text((g.goal as Goal).name,
                                    style: AppTypography.cardTitle),
                              ],
                            ),
                          ),
                        )),
                  ]),
                );
              },
              loading: () =>
                  const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, __) =>
                  const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// ── Progress card ─────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  final GoalWithProgress gwp;
  final VoidCallback onTap;
  const _ProgressCard({required this.gwp, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final goal = gwp.goal as Goal;
    final progress = gwp.effectiveProgress;
    final daysLeft =
        DateTime.fromMillisecondsSinceEpoch(goal.deadline)
            .difference(DateTime.now())
            .inDays;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Expanded(
              child: SizedBox(
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
                    Text(
                      '${progress.round()}%',
                      style: AppTypography.badge.copyWith(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              goal.name,
              style: AppTypography.cardTitle,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              daysLeft < 0 ? 'Overdue' : '$daysLeft days left',
              style: AppTypography.caption.copyWith(
                color: daysLeft < 0 ? AppColors.error : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Weekly chart ──────────────────────────────────────────────────────────

class _WeeklyChart extends ConsumerWidget {
  const _WeeklyChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayCompletions = ref.watch(todayCompletionsProvider);

    // Build 7 days of data
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      height: 180,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 10,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Text(
                  days[value.toInt() % 7],
                  style: AppTypography.caption.copyWith(fontSize: 10),
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: AppTypography.caption.copyWith(fontSize: 10),
                ),
              ),
            ),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (v) => FlLine(
              color: AppColors.border.withValues(alpha: 0.3),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: i == (now.weekday - 1)
                      ? (todayCompletions.value
                                  ?.where((c) => c.completedDate != null)
                                  .length
                                  .toDouble() ??
                              0)
                          .toDouble()
                      : 0,
                  color: AppColors.accentPrimary,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4)),
                ),
              ],
            );
          }),
        ),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      ),
    );
  }
}
