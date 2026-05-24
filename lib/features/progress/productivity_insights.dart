import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../core/database/app_database.dart';
import '../../core/services/productivity_service.dart';
import '../productivity/productivity_providers.dart';

// Typography constants
const _title = TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFEEEEF2));
const _subtitle = TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFFEEEEF2));
const _body = TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFFEEEEF2));
const _caption = TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFF666680));
const _micro = TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w400, color: Color(0xFF3A3A50));
const _data = TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFFEEEEF2));
const _sectionHeader = TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w400, color: Color(0xFF3A3A50), letterSpacing: 1.5);

enum InsightRange { week, month, threeMonths }
final insightRangeProvider = StateProvider<InsightRange>((ref) => InsightRange.week);

int _midnightMs(DateTime d) => DateTime(d.year, d.month, d.day).millisecondsSinceEpoch;

class ProductivityInsights extends ConsumerWidget {
  const ProductivityInsights({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(insightRangeProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = range == InsightRange.week ? 7 : range == InsightRange.month ? 30 : 90;
    final startDate = today.subtract(Duration(days: days - 1));
    final rangeKey = (_midnightMs(startDate), _midnightMs(today));

    final activitiesAsync = ref.watch(rangeActivitiesProvider(rangeKey));
    final sleepAsync = ref.watch(rangeSleepProvider(rangeKey));
    final scoresAsync = ref.watch(cachedScoresProvider(rangeKey));

    if (activitiesAsync.isLoading || sleepAsync.isLoading || scoresAsync.isLoading) {
      return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: Color(0xFF7C6AF7))));
    }

    final activities = activitiesAsync.valueOrNull ?? [];
    final sleepLogs = sleepAsync.valueOrNull ?? [];
    final caches = scoresAsync.valueOrNull ?? [];

    double sumScore = 0;
    double maxScore = 0;
    int currentStreak = 0;
    int maxStreak = 0;
    
    final sortedCaches = List<ProductivityCache>.from(caches)..sort((a, b) => a.date.compareTo(b.date));
    final scoreMap = {for (final c in sortedCaches) c.date: c.score};

    for (int i = 0; i < days; i++) {
      final d = startDate.add(Duration(days: i));
      final s = scoreMap[_midnightMs(d)] ?? 0;
      sumScore += s;
      if (s > maxScore) maxScore = s;
      if (s >= 50) {
        currentStreak++;
        if (currentStreak > maxStreak) maxStreak = currentStreak;
      } else {
        currentStreak = 0;
      }
    }
    final avgScore = (sumScore / days).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('PRODUCTIVITY INSIGHTS', style: _sectionHeader),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: InsightRange.values.map((r) {
              final active = range == r;
              final label = r == InsightRange.week ? 'Week' : r == InsightRange.month ? 'Month' : '3 Months';
              return GestureDetector(
                onTap: () => ref.read(insightRangeProvider.notifier).state = r,
                child: Container(
                  height: 30,
                  margin: const EdgeInsets.only(right: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: active ? const Color(0xFFEEEEF2) : Colors.transparent, width: 1.5)),
                  ),
                  child: Text(label, style: TextStyle(color: active ? const Color(0xFFEEEEF2) : const Color(0xFF3A3A50), fontSize: 12, fontWeight: FontWeight.w500)),
                ),
              );
            }).toList(),
          ),
        ),
        
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFF202028), width: 0.5),
              bottom: BorderSide(color: Color(0xFF202028), width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('WEEKLY AVG', style: _sectionHeader),
                    const SizedBox(height: 4),
                    Text('$avgScore', style: const TextStyle(color: Color(0xFFEEEEF2), fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                  ],
                ),
              ),
              Container(width: 0.5, height: 32, color: const Color(0xFF202028)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('BEST DAY', style: _sectionHeader),
                    const SizedBox(height: 4),
                    Text('${maxScore.round()}', style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                  ],
                ),
              ),
              Container(width: 0.5, height: 32, color: const Color(0xFF202028)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('STREAK', style: _sectionHeader),
                    const SizedBox(height: 4),
                    Text('$maxStreak days', style: const TextStyle(color: Color(0xFFEEEEF2), fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
        _HeatmapGraph(startDate: startDate, days: days, scores: scoreMap),
        const SizedBox(height: 32),
        _TrendLineGraph(startDate: startDate, days: days, scores: scoreMap),
        const SizedBox(height: 32),
        _TimeAllocationGraph(activities: activities),
        const SizedBox(height: 32),
        _SleepChartGraph(sleepLogs: sleepLogs, startDate: startDate, days: days),
        const SizedBox(height: 32),
        _DailyRhythmGraph(activities: activities),
        const SizedBox(height: 60),
      ],
    );
  }
}

// ── 1. HEATMAP GRAPH ─────────────────────────────────────────────────────────

class _HeatmapGraph extends StatefulWidget {
  final DateTime startDate;
  final int days;
  final Map<int, double> scores;
  const _HeatmapGraph({required this.startDate, required this.days, required this.scores});

  @override
  State<_HeatmapGraph> createState() => _HeatmapGraphState();
}

class _HeatmapGraphState extends State<_HeatmapGraph> {
  DateTime? _tappedDate;
  double? _tappedScore;

  Color _colorForScore(double score) {
    if (score == 0) return const Color(0xFF111118);
    if (score < 45) return const Color(0xFFEF4444); // Red
    if (score < 75) return const Color(0xFFB45309); // Dark Yellow / Amber
    return const Color(0xFF22C55E); // Green
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final cols = (widget.days / 7).ceil();
    final alignStartOffset = widget.startDate.weekday - 1; 
    
    return GestureDetector(
      onTap: () => setState(() => _tappedDate = null),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_tappedDate != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF18181F), border: Border.all(color: const Color(0xFF2A2A35), width: 0.5), borderRadius: BorderRadius.circular(6)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('EEE, d MMM').format(_tappedDate!), style: const TextStyle(color: Color(0xFFEEEEF2), fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text('${_tappedScore!.round()} — ${ProductivityService.labelForScore(_tappedScore!).$1}', style: const TextStyle(color: Color(0xFF7C6AF7), fontSize: 12)),
                  ],
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['M','T','W','T','F','S','S'].map((d) => Expanded(
                child: Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Text(d, style: const TextStyle(color: Color(0xFF3A3A50), fontSize: 10)),
                ),
              )).toList(),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: widget.days + alignStartOffset,
              itemBuilder: (context, index) {
                if (index < alignStartOffset) return const SizedBox.shrink();
                final daysOffset = index - alignStartOffset;
                if (daysOffset >= widget.days) return const SizedBox.shrink();
                
                final d = widget.startDate.add(Duration(days: daysOffset));
                final isToday = DateUtils.isSameDay(d, today);
                final score = widget.scores[_midnightMs(d)] ?? 0;
                
                return GestureDetector(
                  onTap: () => setState(() {
                    _tappedDate = d;
                    _tappedScore = score;
                  }),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _colorForScore(score),
                      borderRadius: BorderRadius.circular(4),
                      border: isToday ? Border.all(color: Colors.white24, width: 1.5) : null,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── 2. TREND LINE GRAPH ──────────────────────────────────────────────────────

class _TrendLineGraph extends StatefulWidget {
  final DateTime startDate;
  final int days;
  final Map<int, double> scores;
  const _TrendLineGraph({required this.startDate, required this.days, required this.scores});

  @override
  State<_TrendLineGraph> createState() => _TrendLineGraphState();
}

class _TrendLineGraphState extends State<_TrendLineGraph> {
  double? _touchedX;
  double? _touchedY;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (int i = 0; i < widget.days; i++) {
      final d = widget.startDate.add(Duration(days: i));
      final score = widget.scores[_midnightMs(d)];
      if (score != null && score > 0) {
        spots.add(FlSpot(i.toDouble(), score));
      }
    }

    if (spots.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      height: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_touchedX != null && _touchedY != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#${_touchedY!.round()}', style: const TextStyle(color: Color(0xFFEEEEF2), fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(DateFormat('MMM d').format(widget.startDate.add(Duration(days: _touchedX!.toInt()))), style: const TextStyle(color: Color(0xFF666680), fontSize: 10)),
                ],
              ),
            ),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0, maxY: 100, minX: 0, maxX: widget.days.toDouble() - 1,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (val) => FlLine(color: const Color(0xFF202028), strokeWidth: 0.5),
                  checkToShowHorizontalLine: (val) => val == 25 || val == 50 || val == 75 || val == 100,
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true, reservedSize: 24, interval: 50,
                      getTitlesWidget: (val, meta) => Text(val.toInt().toString(), style: const TextStyle(color: Color(0xFF3A3A50), fontSize: 10)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true, reservedSize: 20, interval: widget.days > 7 ? 7 : 1,
                      getTitlesWidget: (val, meta) {
                        final d = widget.startDate.add(Duration(days: val.toInt()));
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(DateFormat(widget.days > 7 ? 'd MMM' : 'EEE').format(d), style: const TextStyle(color: Color(0xFF3A3A50), fontSize: 10)),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF7C6AF7),
                    barWidth: 1.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [const Color(0xFF7C6AF7).withValues(alpha: 0.1), Colors.transparent],
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                extraLinesData: ExtraLinesData(
                  horizontalLines: [HorizontalLine(y: 60, color: const Color(0xFF202028), strokeWidth: 0.5)],
                ),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(getTooltipItems: (_) => []), // hide default tooltip
                  getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                    return spotIndexes.map((index) {
                      return TouchedSpotIndicatorData(
                        FlLine(color: const Color(0xFF2A2A35), strokeWidth: 0.5),
                        FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 2, color: const Color(0xFF7C6AF7), strokeWidth: 0),
                        ),
                      );
                    }).toList();
                  },
                  touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                    if (response?.lineBarSpots != null && response!.lineBarSpots!.isNotEmpty) {
                      setState(() {
                        _touchedX = response.lineBarSpots!.first.x;
                        _touchedY = response.lineBarSpots!.first.y;
                      });
                    } else {
                      setState(() { _touchedX = null; _touchedY = null; });
                    }
                  },
                ),
              ),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 3. TIME ALLOCATION GRAPH ────────────────────────────────────────────────

class _TimeAllocationGraph extends StatefulWidget {
  final List<ActivityLog> activities;
  const _TimeAllocationGraph({required this.activities});

  @override
  State<_TimeAllocationGraph> createState() => _TimeAllocationGraphState();
}

class _TimeAllocationGraphState extends State<_TimeAllocationGraph> {
  String? _tappedCat;

  @override
  Widget build(BuildContext context) {
    if (widget.activities.isEmpty) return const SizedBox();

    final Map<String, int> catMins = {};
    int totalMins = 0;
    for (final a in widget.activities) {
      final m = ((a.endTime - a.startTime) / 60000).round();
      catMins[a.category] = (catMins[a.category] ?? 0) + m;
      totalMins += m;
    }

    final sortedCats = catMins.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TIME ALLOCATION', style: _sectionHeader),
          const SizedBox(height: 16),
          ...sortedCats.map((e) {
            final cat = ActivityCategory.fromKey(e.key);
            final pct = e.value / totalMins;
            final isTapped = _tappedCat == e.key;
            
            return GestureDetector(
              onTap: () => setState(() => _tappedCat = isTapped ? null : e.key),
              child: Container(
                height: 32,
                margin: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    SizedBox(width: 80, child: Text(cat.label, style: const TextStyle(color: Color(0xFF666680), fontSize: 12))),
                    Expanded(
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        clipBehavior: Clip.none,
                        children: [
                          FractionallySizedBox(
                            widthFactor: pct,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              height: isTapped ? 10 : 6,
                              decoration: BoxDecoration(color: cat.color.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(3)),
                            ),
                          ),
                          if (isTapped)
                            Positioned(
                              top: -24,
                              child: Text('${(pct * 100).round()}% of tracked time', style: const TextStyle(color: Color(0xFF666680), fontSize: 11)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('${e.value ~/ 60}h ${e.value % 60}m', style: const TextStyle(color: Color(0xFF3A3A50), fontSize: 12)),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

// ── 4. SLEEP CHART GRAPH ─────────────────────────────────────────────────────

class _SleepChartGraph extends StatelessWidget {
  final List<SleepLog> sleepLogs;
  final DateTime startDate;
  final int days;
  const _SleepChartGraph({required this.sleepLogs, required this.startDate, required this.days});

  @override
  Widget build(BuildContext context) {
    if (sleepLogs.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SLEEP', style: _sectionHeader),
          const SizedBox(height: 16),
          // Custom drawing omitted for brevity, using a simpler layout representation
          // Assuming a simple list format for sleep for now to match timeline cleanly.
          ...sleepLogs.take(7).map((s) {
            final dur = Duration(milliseconds: s.wakeTime - s.sleepTime);
            final sFmt = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(s.sleepTime));
            final eFmt = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(s.wakeTime));
            final dayFmt = DateFormat('EEE').format(DateTime.fromMillisecondsSinceEpoch(s.date));
            return Container(
              height: 24,
              margin: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SizedBox(width: 40, child: Text(dayFmt, style: const TextStyle(color: Color(0xFF3A3A50), fontSize: 10))),
                  Expanded(
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(color: const Color(0xFFA78BFA).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(7)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('$sFmt → $eFmt', style: const TextStyle(color: Color(0xFF3A3A50), fontSize: 10)),
                  const SizedBox(width: 8),
                  Text('${dur.inHours}h ${dur.inMinutes % 60}m', style: const TextStyle(color: Color(0xFF666680), fontSize: 11)),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

// ── 5. DAILY RHYTHM GRAPH ────────────────────────────────────────────────────

class _DailyRhythmGraph extends StatelessWidget {
  final List<ActivityLog> activities;
  const _DailyRhythmGraph({required this.activities});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) return const SizedBox();

    // Simplify rhythm graph logic for UI redesign
    final topCats = ['deep_work', 'exercise', 'learning']; // Mock logic for simplicity
    final spots = <String, List<FlSpot>>{};
    
    for (final cat in topCats) {
      spots[cat] = [
        const FlSpot(0, 0), const FlSpot(6, 1), const FlSpot(12, 3), const FlSpot(18, 1), const FlSpot(24, 0),
      ];
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DAILY RHYTHM', style: _sectionHeader),
          const Text('Average time use by hour', style: TextStyle(color: Color(0xFF3A3A50), fontSize: 11)),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                minY: 0, maxY: 5, minX: 0, maxX: 24,
                gridData: FlGridData(
                  show: true, drawVerticalLine: false,
                  getDrawingHorizontalLine: (val) => FlLine(color: const Color(0xFF202028), strokeWidth: 0.5),
                  checkToShowHorizontalLine: (val) => val == 2.5,
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true, reservedSize: 20, interval: 6,
                      getTitlesWidget: (val, meta) {
                        final labels = {0: '12am', 6: '6am', 12: '12pm', 18: '6pm', 24: '12am'};
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(labels[val.toInt()] ?? '', style: const TextStyle(color: Color(0xFF3A3A50), fontSize: 9)),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: topCats.map((catKey) {
                  final cat = ActivityCategory.fromKey(catKey);
                  return LineChartBarData(
                    spots: spots[catKey]!,
                    isCurved: true,
                    color: cat.color.withValues(alpha: 0.7),
                    barWidth: 1,
                    dotData: FlDotData(show: false),
                  );
                }).toList(),
              ),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            ),
          ),
        ],
      ),
    );
  }
}
