import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/providers.dart';
import '../../core/services/notification_service.dart';
import '../yaml_import/yaml_import_page.dart';
import '../yaml_prompt/yaml_prompt_page.dart';
import 'all_goals_page.dart';

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
    final allGoalsAsync = ref.watch(allGoalsProvider);
    final todayCompletions = ref.watch(todayCompletionsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        color: Colors.white54,
        backgroundColor: const Color(0xFF111111),
        onRefresh: () async {
          ref.invalidate(profileProvider);
          ref.invalidate(allGoalsProvider);
          ref.invalidate(todayCompletionsProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ─────────────────────────────────────────
                  profile.when(
                    data: (p) => _ProfileHeader(
                      profile: p,
                      onSettingsTap: () => _openSettings(context, ref, p),
                      onNameTap: () => _editName(context, ref, p),
                    ),
                    loading: () => const _ProfileHeader(profile: null),
                    error: (_, __) => const _ProfileHeader(profile: null),
                  ),

                  const SizedBox(height: 32),

                  // ── Journey stats ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR JOURNEY',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        allGoalsAsync.when(
                          data: (goals) => todayCompletions.when(
                            data: (comps) => _StatsGrid(
                              totalGoals: goals.length,
                              tasksCompleted: comps.where((c) => c.completedDate != null).length,
                              completedGoals: goals.where((g) => g.status == 'completed').length,
                              totalGoalsDenominator: goals.length,
                              onTapAllGoals: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AllGoalsPage()),
                              ),
                            ),
                            loading: () => const _StatsGrid(totalGoals: 0, tasksCompleted: 0, completedGoals: 0, totalGoalsDenominator: 0),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                          loading: () => const _StatsGrid(totalGoals: 0, tasksCompleted: 0, completedGoals: 0, totalGoalsDenominator: 0),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Data section ───────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DATA',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _DataTile(
                          icon: Icons.auto_awesome,
                          label: 'Generate with AI',
                          subtitle: 'Get a prompt to create your YAML with any AI assistant',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const YamlPromptPage())),
                        ),
                        _DataTile(
                          icon: Icons.upload_rounded,
                          label: 'Import YAML',
                          subtitle: 'Paste or load a YAML goal definition',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const YamlImportPage())),
                        ),
                        _DataTile(
                          icon: Icons.download_rounded,
                          label: 'Export Data',
                          subtitle: 'Save your goals and progress as a YAML file',
                          onTap: () => _exportData(context, ref),
                        ),
                        _DataTile(
                          icon: Icons.storage_rounded,
                          label: 'Storage Used',
                          subtitle: _dbSizeKb != null ? '$_dbSizeKb KB' : 'Calculating...',
                          showChevron: false,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        Text(
                          'TROUBLESHOOTING',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 12),
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
                                SnackBar(
                                  content: Text('Permissions requested', style: GoogleFonts.inter(color: Colors.white, fontSize: 12)),
                                  backgroundColor: const Color(0xFF111111),
                                ),
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

  void _editName(BuildContext context, WidgetRef ref, UserProfile? profile) {
    final ctrl = TextEditingController(text: profile?.displayName ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.white12),
        ),
        title: Text('Your Name', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: GoogleFonts.inter(color: Colors.white24),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                await ref.read(databaseProvider).updateProfile(UserProfilesCompanion(displayName: Value(name)));
                ref.invalidate(profileProvider);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text('Save', style: GoogleFonts.inter(color: Colors.white)),
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
    buf.writeln('version: "1.0"\n\ngoals:');
    for (final g in goals) {
      buf.writeln('  - id: ${g.id}');
      buf.writeln('    name: "${g.name}"');
      if (g.aim != null) buf.writeln('    aim: "${g.aim}"');
      buf.writeln('    timeframe: ${g.timeframe}');
      buf.writeln('    deadline: "${DateTime.fromMillisecondsSinceEpoch(g.deadline).toIso8601String().substring(0, 10)}"');
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
          if (t.scheduleOn != null) buf.writeln('        on: ${t.scheduleOn}');
          buf.writeln('        reminder: "${t.reminderTime}"');
          buf.writeln('        active: ${t.isActive == 1}');
        }
      }
    }

    final now = DateTime.now();
    final filename = 'nexus_export_${now.year}${_p(now.month)}${_p(now.day)}_${_p(now.hour)}${_p(now.minute)}${_p(now.second)}.yaml';

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(buf.toString());

      await Share.shareXFiles([XFile(file.path)], subject: filename);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Exported to $filename', style: GoogleFonts.inter(color: Colors.white, fontSize: 12)),
          backgroundColor: const Color(0xFF0A0A0A),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Export failed: $e', style: GoogleFonts.inter(color: Colors.white, fontSize: 12)),
          backgroundColor: const Color(0xFFE74C3C),
        ));
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
    final initials = name.split(' ').take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
    final createdAt = profile != null ? DateTime.fromMillisecondsSinceEpoch(profile!.createdAt) : DateTime.now();

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: onNameTap,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials.isEmpty ? 'Y' : initials,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: onNameTap,
                    child: Text(
                      name,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Using Nexus since ${_monthYear(createdAt)}',
                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onSettingsTap,
              icon: const Icon(Icons.settings_outlined, color: Colors.white54, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  String _monthYear(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
  final VoidCallback? onTapAllGoals;

  const _StatsGrid({
    required this.totalGoals,
    required this.tasksCompleted,
    required this.completedGoals,
    required this.totalGoalsDenominator,
    this.onTapAllGoals,
  });

  @override
  Widget build(BuildContext context) {
    final rate = totalGoalsDenominator == 0 ? 'N/A' : '${(completedGoals / totalGoalsDenominator * 100).round()}%';

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.6,
      children: [
        _StatCard(
          label: 'Total Goals',
          value: '$totalGoals',
          onTap: onTapAllGoals,
        ),
        _StatCard(
          label: 'Tasks Completed',
          value: '$tasksCompleted',
        ),
        _StatCard(
          label: 'Goals Completed',
          value: '$completedGoals',
        ),
        _StatCard(
          label: 'Completion Rate',
          value: rate,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _StatCard({required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),
              if (onTap != null)
                const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 12),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
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
  Widget build(BuildContext context) {
    final tile = Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Icon(icon, color: onTap != null ? Colors.white70 : Colors.white24, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          if (showChevron && onTap != null)
            const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: tile);
    }
    return tile;
  }
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
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'PREFERENCES',
            style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2.0),
          ),
          const SizedBox(height: 16),

          _SettingRow(
            label: 'Notifications',
            description: 'Task reminders and goal alerts',
            trailing: Switch(
              value: notifsOn,
              activeColor: Colors.white,
              activeTrackColor: Colors.white24,
              inactiveThumbColor: Colors.white54,
              inactiveTrackColor: Colors.transparent,
              trackOutlineColor: WidgetStateProperty.resolveWith((states) => Colors.white24),
              onChanged: (v) => _update(ref, notifsEnabled: v),
            ),
          ),
          const Divider(color: Colors.white10, height: 24),
          _SettingRow(
            label: 'Haptic Feedback',
            description: 'Subtle vibration on navigation',
            trailing: Switch(
              value: hapticsOn,
              activeColor: Colors.white,
              activeTrackColor: Colors.white24,
              inactiveThumbColor: Colors.white54,
              inactiveTrackColor: Colors.transparent,
              trackOutlineColor: WidgetStateProperty.resolveWith((states) => Colors.white24),
              onChanged: (v) => _update(ref, hapticsEnabled: v),
            ),
          ),
          const Divider(color: Colors.white10, height: 24),
          _SettingRow(
            label: 'Reduced Motion',
            description: 'Simplify app-wide animations',
            trailing: Switch(
              value: reducedMotion,
              activeColor: Colors.white,
              activeTrackColor: Colors.white24,
              inactiveThumbColor: Colors.white54,
              inactiveTrackColor: Colors.transparent,
              trackOutlineColor: WidgetStateProperty.resolveWith((states) => Colors.white24),
              onChanged: (v) => _update(ref, reducedMotion: v),
            ),
          ),
          const Divider(color: Colors.white10, height: 24),
          _SettingRow(
            label: 'Navigation Side',
            description: 'Placement of the control bubble',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MiniToggle(label: 'L', selected: bubbleSide == 'left', onTap: () => _update(ref, bubbleSide: 'left')),
                const SizedBox(width: 8),
                _MiniToggle(label: 'R', selected: bubbleSide == 'right', onTap: () => _update(ref, bubbleSide: 'right')),
              ],
            ),
          ),

          const SizedBox(height: 48),
          Text('DANGER ZONE', style: GoogleFonts.inter(color: const Color(0xFFE74C3C), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2.0)),
          const SizedBox(height: 16),
          
          _DangerButton(
            label: 'Delete All Data',
            onTap: () => _confirmDelete(context, ref, 'ALL', () => ref.read(databaseProvider).clearAllData()),
          ),
          const SizedBox(height: 8),
          _DangerButton(
            label: 'Clear Future Schedule',
            onTap: () => _confirmDelete(context, ref, 'FUTURE', () => ref.read(databaseProvider).clearFutureData()),
          ),
        ],
      ),
    );
  }

  Future<void> _update(WidgetRef ref, {bool? notifsEnabled, bool? hapticsEnabled, bool? reducedMotion, String? bubbleSide}) async {
    await ref.read(databaseProvider).updateProfile(UserProfilesCompanion(
      notifsEnabled: notifsEnabled != null ? Value(notifsEnabled ? 1 : 0) : const Value.absent(),
      hapticsEnabled: hapticsEnabled != null ? Value(hapticsEnabled ? 1 : 0) : const Value.absent(),
      reducedMotion: reducedMotion != null ? Value(reducedMotion ? 1 : 0) : const Value.absent(),
      bubbleSide: bubbleSide != null ? Value(bubbleSide) : const Value.absent(),
    ));
    ref.invalidate(profileProvider);
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String type, Future<void> Function() action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.white12),
        ),
        title: Text('Confirm Deletion', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text(
          type == 'ALL' 
            ? 'This will permanently erase all your goals, tasks, and progress. This cannot be undone.'
            : 'This will clear all future task completions. You will need to regenerate your schedule.',
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              await action();
              ref.invalidate(allGoalsProvider);
              ref.invalidate(allTasksProvider);
              ref.invalidate(todayCompletionsProvider);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Data cleared successfully.', style: GoogleFonts.inter(color: Colors.white, fontSize: 12)),
                  backgroundColor: const Color(0xFF111111),
                ));
              }
            },
            child: Text('Confirm', style: GoogleFonts.inter(color: const Color(0xFFE74C3C))),
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
              Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(description, style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
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
          color: selected ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: selected ? Colors.white : Colors.white24),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected ? Colors.black : Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w700,
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE74C3C).withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(color: const Color(0xFFE74C3C), fontSize: 13, fontWeight: FontWeight.w600)),
            const Icon(Icons.delete_outline, color: Color(0xFFE74C3C), size: 18),
          ],
        ),
      ),
    );
  }
}
