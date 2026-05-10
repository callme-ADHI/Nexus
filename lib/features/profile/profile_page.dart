import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/providers.dart';
import '../../shared/theme/app_theme.dart';
import '../../core/services/notification_service.dart';
import '../yaml_import/yaml_import_page.dart';
import '../yaml_prompt/yaml_prompt_page.dart';

// ════════════════════════════════════════════════════════════════════════════
// PROFILE PAGE
// ════════════════════════════════════════════════════════════════════════════

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  int? _dbSizeKb;

  @override
  void initState() {
    super.initState();
    _loadDbSize();
  }

  Future<void> _loadDbSize() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/nexus.db');
      if (await f.exists()) {
        final size = await f.length();
        if (mounted) setState(() => _dbSizeKb = (size / 1024).ceil());
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final allGoals = ref.watch(allGoalsProvider);
    final todayCompletions = ref.watch(todayCompletionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.accentSecondary,
        onRefresh: () async {
          ref.invalidate(profileProvider);
          ref.invalidate(allGoalsProvider);
          ref.invalidate(todayCompletionsProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // ── Header ─────────────────────────────────────────
                  profile.when(
                    data: (p) => _ProfileHeader(
                      profile: p,
                      onSettingsTap: () =>
                          _openSettings(context, ref, p),
                      onNameTap: () => _editName(context, ref, p),
                    ),
                    loading: () => const _ProfileHeader(profile: null),
                    error: (_, __) => const _ProfileHeader(profile: null),
                  ),

                  const SizedBox(height: AppSpacing.sectionSpacing),

                  // ── Journey stats ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Journey',
                            style: AppTypography.sectionHeader),
                        const SizedBox(height: AppSpacing.md),
                        allGoals.when(
                          data: (goals) => todayCompletions.when(
                            data: (comps) => _StatsGrid(
                              totalGoals: goals.length,
                              tasksCompleted: comps
                                  .where((c) => c.completedDate != null)
                                  .length,
                              completedGoals: goals
                                  .where((g) => g.status == 'completed')
                                  .length,
                              totalGoalsDenominator: goals.length,
                            ),
                            loading: () => const _StatsGrid(
                                totalGoals: 0,
                                tasksCompleted: 0,
                                completedGoals: 0,
                                totalGoalsDenominator: 0),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                          loading: () => const _StatsGrid(
                              totalGoals: 0,
                              tasksCompleted: 0,
                              completedGoals: 0,
                              totalGoalsDenominator: 0),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sectionSpacing),

                  // ── Data section ───────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Data', style: AppTypography.sectionHeader),
                        const SizedBox(height: AppSpacing.md),
                        _DataTile(
                          icon: Icons.auto_awesome,
                          label: 'Generate with AI',
                          subtitle:
                              'Get a prompt to create your YAML with any AI assistant',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const YamlPromptPage()),
                          ),
                        ),
                        _DataTile(
                          icon: Icons.upload_rounded,
                          label: 'Import YAML',
                          subtitle:
                              'Paste or load a YAML goal definition',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const YamlImportPage()),
                          ),
                        ),
                        _DataTile(
                          icon: Icons.download_rounded,
                          label: 'Export Data',
                          subtitle:
                              'Save your goals and progress as a YAML file',
                          onTap: () => _exportData(context, ref),
                        ),
                        _DataTile(
                          icon: Icons.storage_rounded,
                          label: 'Storage Used',
                          subtitle: _dbSizeKb != null
                              ? '$_dbSizeKb KB'
                              : 'Calculating...',
                          showChevron: false,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text('Troubleshooting', style: AppTypography.sectionHeader),
                        const SizedBox(height: AppSpacing.md),
                        _DataTile(
                          icon: Icons.notification_important_rounded,
                          label: 'Test Notification',
                          subtitle: 'Fire an immediate notification to check setup',
                          onTap: () => NotificationService.showTestNotification(),
                        ),
                        _DataTile(
                          icon: Icons.settings_suggest_rounded,
                          label: 'Fix Permissions',
                          subtitle: 'Request notification and exact alarm permissions',
                          onTap: () async {
                             await NotificationService.requestPermissions();
                             if (context.mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(content: Text('Permissions requested. Please allow if prompted.')),
                               );
                             }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSettings(BuildContext context, WidgetRef ref, UserProfile? p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SettingsSheet(profile: p, ref: ref),
    );
  }

  void _editName(
      BuildContext context, WidgetRef ref, UserProfile? profile) {
    final ctrl = TextEditingController(
        text: profile?.displayName ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Your Name', style: AppTypography.cardTitle),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: AppTypography.body,
          decoration: const InputDecoration(
            hintText: 'Enter your name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                await ref.read(databaseProvider).updateProfile(
                      UserProfilesCompanion(
                        displayName: Value(name),
                      ),
                    );
                ref.invalidate(profileProvider);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final goals = await db.getAllGoals();
    final tasks = await db.getAllTasks();

    final buf = StringBuffer();
    buf.writeln('version: "1.0"');
    buf.writeln();
    buf.writeln('goals:');
    for (final g in goals) {
      buf.writeln('  - id: ${g.id}');
      buf.writeln('    name: "${g.name}"');
      if (g.aim != null) buf.writeln('    aim: "${g.aim}"');
      buf.writeln('    timeframe: ${g.timeframe}');
      buf.writeln(
          '    deadline: "${DateTime.fromMillisecondsSinceEpoch(g.deadline).toIso8601String().substring(0, 10)}"');
      buf.writeln('    weight: ${g.weight}');
      buf.writeln('    color_index: ${g.colorIndex}');
      buf.writeln('    status: ${g.status}');
      if (g.parentId != null) buf.writeln('    parent: ${g.parentId}');
      final goalTasks = tasks.where((t) => t.goalId == g.id).toList();
      if (goalTasks.isNotEmpty) {
        buf.writeln('    tasks:');
        for (final t in goalTasks) {
          buf.writeln('      - name: "${t.name}"');
          buf.writeln('        schedule: ${t.schedule}');
          if (t.scheduleOn != null) {
            buf.writeln('        on: ${t.scheduleOn}');
          }
          buf.writeln('        reminder: "${t.reminderTime}"');
          buf.writeln('        active: ${t.isActive == 1}');
        }
      }
    }

    final now = DateTime.now();
    final filename =
        'nexus_export_${now.year}${_p(now.month)}${_p(now.day)}_${_p(now.hour)}${_p(now.minute)}${_p(now.second)}.yaml';

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(buf.toString());

      await Share.shareXFiles([XFile(file.path)], subject: filename);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to $filename')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  String _p(int n) => n.toString().padLeft(2, '0');
}

// ════════════════════════════════════════════════════════════════════════════
// PROFILE HEADER
// ════════════════════════════════════════════════════════════════════════════

class _ProfileHeader extends StatelessWidget {
  final UserProfile? profile;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onNameTap;

  const _ProfileHeader({
    required this.profile,
    this.onSettingsTap,
    this.onNameTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = profile?.displayName ?? 'You';
    final initials = name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    final createdAt = profile != null
        ? DateTime.fromMillisecondsSinceEpoch(profile!.createdAt)
        : DateTime.now();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        MediaQuery.of(context).padding.top + 24,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          GestureDetector(
            onTap: onNameTap,
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentPrimary,
              ),
              alignment: Alignment.center,
              child: Text(
                initials.isEmpty ? 'Y' : initials,
                style: AppTypography.pageTitle.copyWith(fontSize: 26),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onNameTap,
                  child: Text(name,
                      style: AppTypography.pageTitle.copyWith(fontSize: 20)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Using Nexus since ${_monthYear(createdAt)}',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onSettingsTap,
            icon: const Icon(Icons.settings_rounded,
                color: AppColors.textSecondary),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  String _monthYear(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}

// ════════════════════════════════════════════════════════════════════════════
// STATS GRID
// ════════════════════════════════════════════════════════════════════════════

class _StatsGrid extends StatelessWidget {
  final int totalGoals;
  final int tasksCompleted;
  final int completedGoals;
  final int totalGoalsDenominator;
  const _StatsGrid({
    required this.totalGoals,
    required this.tasksCompleted,
    required this.completedGoals,
    required this.totalGoalsDenominator,
  });

  @override
  Widget build(BuildContext context) {
    final rate = totalGoalsDenominator == 0
        ? 'N/A'
        : '${(completedGoals / totalGoalsDenominator * 100).round()}%';

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.55,
      children: [
        _StatCard(
            label: 'Total Goals',
            value: '$totalGoals',
            accent: AppColors.accentSecondary),
        _StatCard(
            label: 'Tasks Completed',
            value: '$tasksCompleted',
            accent: AppColors.success),
        _StatCard(
            label: 'Goals Completed',
            value: '$completedGoals',
            accent: AppColors.nodeAccents[1]),
        _StatCard(
            label: 'Completion Rate',
            value: rate,
            accent: AppColors.nodeAccents[3]),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  const _StatCard(
      {required this.label, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: AppTypography.progressPct.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: AppTypography.caption,
                textAlign: TextAlign.center),
          ],
        ),
      );
}

// ════════════════════════════════════════════════════════════════════════════
// DATA TILE
// ════════════════════════════════════════════════════════════════════════════

class _DataTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;
  final bool showChevron;
  const _DataTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: onTap != null
                      ? AppColors.accentSecondary
                      : AppColors.textSecondary,
                  size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTypography.cardTitle),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTypography.caption),
                  ],
                ),
              ),
              if (showChevron && onTap != null)
                const Icon(Icons.chevron_right,
                    color: AppColors.textSecondary, size: 18),
            ],
          ),
        ),
      );
}

// ════════════════════════════════════════════════════════════════════════════
// SETTINGS BOTTOM SHEET
// ════════════════════════════════════════════════════════════════════════════

class _SettingsSheet extends ConsumerWidget {
  final UserProfile? profile;
  final WidgetRef ref;
  const _SettingsSheet({required this.profile, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsOn = profile?.notifsEnabled == 1;
    final hapticsOn = profile?.hapticsEnabled == 1;
    final reducedMotion = profile?.reducedMotion == 1;
    final bubbleSide = profile?.bubbleSide ?? 'right';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 12, AppSpacing.xl, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Preferences', style: AppTypography.pageTitle.copyWith(fontSize: 22)),
          const SizedBox(height: 24),

          _SettingRow(
            label: 'Notifications',
            description: 'Task reminders and goal alerts',
            trailing: Switch(
              value: notifsOn,
              onChanged: (v) => _update(ref, notifsEnabled: v),
            ),
          ),
          const Divider(color: AppColors.border, height: 32),
          _SettingRow(
            label: 'Haptic Feedback',
            description: 'Subtle vibration on navigation',
            trailing: Switch(
              value: hapticsOn,
              onChanged: (v) => _update(ref, hapticsEnabled: v),
            ),
          ),
          const Divider(color: AppColors.border, height: 32),
          _SettingRow(
            label: 'Reduced Motion',
            description: 'Simplify app-wide animations',
            trailing: Switch(
              value: reducedMotion,
              onChanged: (v) => _update(ref, reducedMotion: v),
            ),
          ),
          const Divider(color: AppColors.border, height: 32),
          
          _SettingRow(
            label: 'Navigation Side',
            description: 'Placement of the control bubble',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MiniToggle(
                  label: 'L',
                  selected: bubbleSide == 'left',
                  onTap: () => _update(ref, bubbleSide: 'left'),
                ),
                const SizedBox(width: 8),
                _MiniToggle(
                  label: 'R',
                  selected: bubbleSide == 'right',
                  onTap: () => _update(ref, bubbleSide: 'right'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),
          Text('Danger Zone', style: AppTypography.sectionHeader.copyWith(color: AppColors.error)),
          const SizedBox(height: 16),
          
          _DangerButton(
            label: 'Delete All Data',
            onTap: () => _confirmDelete(context, ref, 'ALL', () => ref.read(databaseProvider).clearAllData()),
          ),
          const SizedBox(height: 12),
          _DangerButton(
            label: 'Clear Future Schedule',
            onTap: () => _confirmDelete(context, ref, 'FUTURE', () => ref.read(databaseProvider).clearFutureData()),
          ),
        ],
      ),
    );
  }

  Future<void> _update(
    WidgetRef ref, {
    bool? notifsEnabled,
    bool? hapticsEnabled,
    bool? reducedMotion,
    String? bubbleSide,
  }) async {
    await ref.read(databaseProvider).updateProfile(UserProfilesCompanion(
      notifsEnabled: notifsEnabled != null
          ? Value(notifsEnabled ? 1 : 0)
          : const Value.absent(),
      hapticsEnabled: hapticsEnabled != null
          ? Value(hapticsEnabled ? 1 : 0)
          : const Value.absent(),
      reducedMotion: reducedMotion != null
          ? Value(reducedMotion ? 1 : 0)
          : const Value.absent(),
      bubbleSide:
          bubbleSide != null ? Value(bubbleSide) : const Value.absent(),
    ));
    ref.invalidate(profileProvider);
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String type, Future<void> Function() action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Confirm Deletion', style: AppTypography.cardTitle),
        content: Text(
          type == 'ALL' 
            ? 'This will permanently erase all your goals, tasks, and progress. This cannot be undone.'
            : 'This will clear all future task completions. You will need to regenerate your schedule.',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await action();
              ref.invalidate(allGoalsProvider);
              ref.invalidate(allTasksProvider);
              ref.invalidate(todayCompletionsProvider);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data cleared successfully.')),
                );
              }
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String description;
  final Widget trailing;

  const _SettingRow({required this.label, required this.description, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.cardTitle.copyWith(fontSize: 16)),
              const SizedBox(height: 2),
              Text(description, style: AppTypography.caption),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}

class _MiniToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MiniToggle({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : AppColors.surfaceAlt,
          shape: BoxShape.circle,
          border: Border.all(color: selected ? Colors.white : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DangerButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.button,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: AppRadius.button,
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.body.copyWith(color: AppColors.error, fontWeight: FontWeight.w600)),
            Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 20),
          ],
        ),
      ),
    );
  }
}
