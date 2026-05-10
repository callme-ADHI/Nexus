import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../core/providers/providers.dart';
import '../../core/database/app_database.dart';
import '../../core/models/models.dart';
import '../graph/goal_detail_sheet.dart';

class ProgressPage extends ConsumerWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalGraph = ref.watch(goalGraphProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Minimal Header ──────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 32, 24, 40),
                child: Text(
                  'PROGRESS',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // ── Past 7 Days Activity (Bar Chart) ────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Text(
                  'LAST 7 DAYS ACTIVITY',
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
            const SliverToBoxAdapter(child: _ActivityBarChart()),

            // ── Goal Status Distribution (Pie Chart) ────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 48, 24, 24),
                child: Text(
                  'GOAL DISTRIBUTION',
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
                data: (goals) => _GoalDistributionChart(goals: goals),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // ── Active Goals List ───────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 48, 24, 16),
                child: Text(
                  'TRACKING',
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
            goalGraph.when(
              data: (goals) {
                final active = goals.where((g) => g.status != GoalStatus.completed).toList();
                if (active.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'No active goals.',
                        style: TextStyle(color: Color(0xFF555555), fontSize: 14),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _MinimalProgressRow(
                      gwp: active[i],
                      onTap: () => _openGoalDetail(context, active[i].goal as Goal),
                    ),
                    childCount: active.length,
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
      builder: (_) => GoalDetailSheet(goal: goal),
    );
  }
}

// ── Activity Bar Chart ──────────────────────────────────────────────────────

class _ActivityBarChart extends ConsumerStatefulWidget {
  const _ActivityBarChart();
  @override
  ConsumerState<_ActivityBarChart> createState() => _ActivityBarChartState();
}

class _ActivityBarChartState extends ConsumerState<_ActivityBarChart> {
  List<TaskCompletion>? _completions;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = ref.read(databaseProvider);
    final data = await db.getPastCompletions(6);
    if (mounted) setState(() => _completions = data);
  }

  @override
  Widget build(BuildContext context) {
    if (_completions == null) return const SizedBox(height: 200);

    // Group by day (0 = 6 days ago, 6 = today)
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final msPerDay = 86400000;

    final counts = List.filled(7, 0);
    for (final c in _completions!) {
      if (c.completedDate != null) {
        final daysAgo = (todayMidnight - c.scheduledDate) ~/ msPerDay;
        if (daysAgo >= 0 && daysAgo <= 6) {
          counts[6 - daysAgo]++;
        }
      }
    }

    double maxCount = counts.reduce((a, b) => a > b ? a : b).toDouble();
    if (maxCount < 5) maxCount = 5;

    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxCount,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final daysAgo = 6 - value.toInt();
                  final date = now.subtract(Duration(days: daysAgo));
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      DateFormat('E').format(date).toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => const FlLine(
              color: Color(0xFF1A1A1A),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: counts[i].toDouble(),
                  color: i == 6 ? Colors.white : const Color(0xFF333333),
                  width: 12,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ── Goal Distribution Pie Chart ─────────────────────────────────────────────

class _GoalDistributionChart extends StatelessWidget {
  final List<GoalWithProgress> goals;
  const _GoalDistributionChart({required this.goals});

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) return const SizedBox.shrink();

    int completed = 0;
    int inProgress = 0;
    int blocked = 0;
    int notStarted = 0;

    for (final g in goals) {
      if (g.status == GoalStatus.completed) {
        completed++;
      } else if (g.status == GoalStatus.blocked) {
        blocked++;
      } else if (g.effectiveProgress > 0) {
        inProgress++;
      } else {
        notStarted++;
      }
    }

    return Container(
      height: 180,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 35,
                sections: [
                  if (completed > 0)
                    PieChartSectionData(
                      color: Colors.white,
                      value: completed.toDouble(),
                      title: '',
                      radius: 12,
                    ),
                  if (inProgress > 0)
                    PieChartSectionData(
                      color: const Color(0xFF666666),
                      value: inProgress.toDouble(),
                      title: '',
                      radius: 12,
                    ),
                  if (notStarted > 0)
                    PieChartSectionData(
                      color: const Color(0xFF333333),
                      value: notStarted.toDouble(),
                      title: '',
                      radius: 12,
                    ),
                  if (blocked > 0)
                    PieChartSectionData(
                      color: const Color(0xFF990000),
                      value: blocked.toDouble(),
                      title: '',
                      radius: 12,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendRow(color: Colors.white, text: 'Completed', count: completed),
                const SizedBox(height: 12),
                _LegendRow(color: const Color(0xFF666666), text: 'In Progress', count: inProgress),
                const SizedBox(height: 12),
                _LegendRow(color: const Color(0xFF333333), text: 'Not Started', count: notStarted),
                const SizedBox(height: 12),
                _LegendRow(color: const Color(0xFF990000), text: 'Blocked', count: blocked),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String text;
  final int count;
  const _LegendRow({required this.color, required this.text, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF888888)),
          ),
        ),
        Text(
          count.toString(),
          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ── Minimal Progress Row ────────────────────────────────────────────────────

class _MinimalProgressRow extends StatelessWidget {
  final GoalWithProgress gwp;
  final VoidCallback onTap;

  const _MinimalProgressRow({required this.gwp, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final goal = gwp.goal as Goal;
    final progress = gwp.effectiveProgress;

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: const Color(0xFF111111),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.name,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Custom minimal progress bar
                  Stack(
                    children: [
                      Container(
                        height: 2,
                        width: double.infinity,
                        color: const Color(0xFF222222),
                      ),
                      FractionallySizedBox(
                        widthFactor: (progress / 100).clamp(0.0, 1.0),
                        child: Container(
                          height: 2,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            SizedBox(
              width: 36,
              child: Text(
                '${progress.round()}%',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF888888),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
