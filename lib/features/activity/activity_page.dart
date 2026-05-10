import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/activity_service.dart';
import '../../shared/theme/app_theme.dart';
import 'package:intl/intl.dart';

// ════════════════════════════════════════════════════════════════════════════
// ACTIVITY PAGE — Screen Time & App Usage (Daily Reports)
// ════════════════════════════════════════════════════════════════════════════

final selectedActivityDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final usageDataProvider = FutureProvider<UsageData>((ref) async {
  final date = ref.watch(selectedActivityDateProvider);
  bool granted = await ActivityService.isPermissionGranted();
  if (!granted) throw Exception('Permission required');
  return ActivityService.fetchDailyStats(date);
});

class ActivityPage extends ConsumerStatefulWidget {
  const ActivityPage({super.key});

  @override
  ConsumerState<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends ConsumerState<ActivityPage> {
  @override
  Widget build(BuildContext context) {
    final usageAsync = ref.watch(usageDataProvider);
    final selectedDate = ref.watch(selectedActivityDateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header & Date Nav ──────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.xl, MediaQuery.of(context).padding.top + 24, AppSpacing.xl, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ACTIVITY', style: AppTypography.sectionHeader),
                        const SizedBox(height: 4),
                        Text('Digital Pulse', style: AppTypography.caption),
                      ],
                    ),
                    _DateNavigator(
                      selectedDate: selectedDate,
                      onChanged: (d) => ref.read(selectedActivityDateProvider.notifier).state = d,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Main Content ───────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: AppColors.accentSecondary,
              onRefresh: () => ref.refresh(usageDataProvider.future),
              child: usageAsync.when(
                data: (data) => data.totalScreenTimeMs == 0 && data.appUsage.isEmpty
                    ? _EmptyState(date: selectedDate)
                    : _ActivityContent(data: data, date: selectedDate),
                loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                error: (err, _) {
                  if (err.toString().contains('Permission required')) {
                    return _PermissionGate();
                  }
                  return Center(child: Text('No data for this day', style: AppTypography.caption));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateNavigator extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;

  const _DateNavigator({required this.selectedDate, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(selectedDate, DateTime.now());
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 18, color: Colors.white),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => onChanged(selectedDate.subtract(const Duration(days: 1))),
          ),
          const SizedBox(width: 8),
          Text(
            isToday ? 'TODAY' : DateFormat('MMM dd').format(selectedDate).toUpperCase(),
            style: AppTypography.cardTitle.copyWith(fontSize: 11, letterSpacing: 1),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.chevron_right, size: 18, color: isToday ? Colors.white24 : Colors.white),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: isToday ? null : () => onChanged(selectedDate.add(const Duration(days: 1))),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final DateTime date;
  const _EmptyState({required this.date});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text('NO ACTIVITY LOGGED', style: AppTypography.sectionHeader.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            DateFormat('EEEE, MMMM dd').format(date),
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}

class _PermissionGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_clock_outlined, size: 64, color: AppColors.accentSecondary),
          const SizedBox(height: 24),
          Text('Usage Access Required', style: AppTypography.pageTitle),
          const SizedBox(height: 12),
          Text(
            'To monitor screen time and activity, Nexus needs "Usage Access" permission from Android settings.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => ActivityService.grantPermission(),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}

class _ActivityContent extends StatelessWidget {
  final UsageData data;
  final DateTime date;
  const _ActivityContent({required this.data, required this.date});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      children: [
        const SizedBox(height: 20),
        
        // ── Main Ring ──────────────────────────────────────
        Center(
          child: _ScreenTimeRing(timeMs: data.totalScreenTimeMs),
        ),
        
        const SizedBox(height: 40),
        
        // ── Quick Stats ────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _SmallStatCard(
                label: 'Unlocks',
                value: '${data.unlockCount}',
                icon: Icons.lock_open_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SmallStatCard(
                label: 'App Usage',
                value: _formatTimeBrief(data.appUsage.values.fold(0, (a, b) => a + b)),
                icon: Icons.apps_rounded,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 40),
        Text('TOP APPLICATIONS', style: AppTypography.sectionHeader),
        const SizedBox(height: 16),
        
        // ── App List ───────────────────────────────────────────────
        ..._buildAppList(data),
        
        const SizedBox(height: 120),
      ],
    );
  }

  List<Widget> _buildAppList(UsageData data) {
    final sortedApps = data.appUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Filter out apps with < 1 minute usage to keep it clean
    final filteredApps = sortedApps.where((e) => e.value > 60000).toList();
    
    if (filteredApps.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(child: Text('Less than 1m in apps', style: AppTypography.caption)),
        )
      ];
    }

    return filteredApps.map((app) {
      final pct = data.totalScreenTimeMs > 0 ? app.value / data.totalScreenTimeMs : 0.0;
      return _AppUsageTile(
        name: app.key.split('.').last.toUpperCase(),
        timeMs: app.value,
        pct: pct,
      );
    }).toList();
  }

  String _formatTimeBrief(int ms) {
    final duration = Duration(milliseconds: ms);
    if (duration.inHours > 0) return '${duration.inHours}h ${duration.inMinutes % 60}m';
    return '${duration.inMinutes}m';
  }
}

class _ScreenTimeRing extends StatelessWidget {
  final int timeMs;
  const _ScreenTimeRing({required this.timeMs});

  @override
  Widget build(BuildContext context) {
    final duration = Duration(milliseconds: timeMs);
    final h = duration.inHours;
    final m = duration.inMinutes % 60;

    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: 2,
            color: Colors.white.withValues(alpha: 0.05),
          ),
          SizedBox(
            width: 200,
            height: 200,
            child: CircularProgressIndicator(
              value: (timeMs / (12 * 3600 * 1000)).clamp(0.0, 1.0),
              strokeWidth: 4,
              color: AppColors.accentSecondary,
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$h', style: AppTypography.progressPct.copyWith(fontSize: 48)),
              Text('HOURS $m MIN', style: AppTypography.caption.copyWith(letterSpacing: 2)),
              const SizedBox(height: 4),
              Text('TOTAL SCREEN TIME', style: AppTypography.caption.copyWith(fontSize: 8, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SmallStatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTypography.cardTitle),
              Text(label, style: AppTypography.caption.copyWith(fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppUsageTile extends StatelessWidget {
  final String name;
  final int timeMs;
  final double pct;

  const _AppUsageTile({required this.name, required this.timeMs, required this.pct});

  @override
  Widget build(BuildContext context) {
    final duration = Duration(milliseconds: timeMs);
    final timeStr = duration.inHours > 0 
      ? '${duration.inHours}h ${duration.inMinutes % 60}m'
      : '${duration.inMinutes}m';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.card,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
              Text(timeStr, style: AppTypography.cardTitle.copyWith(fontSize: 13, color: AppColors.accentSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 2,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}
