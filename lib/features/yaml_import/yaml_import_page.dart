import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../shared/theme/app_theme.dart';

// ════════════════════════════════════════════════════════════════════════════
// YAML IMPORT PAGE — paste, validate, resolve conflicts, commit
// ════════════════════════════════════════════════════════════════════════════

class YamlImportPage extends ConsumerStatefulWidget {
  const YamlImportPage({super.key});

  @override
  ConsumerState<YamlImportPage> createState() => _YamlImportPageState();
}

class _YamlImportPageState extends ConsumerState<YamlImportPage> {
  late final _textCtrl = TextEditingController(text: _testYaml);
  bool _hasParsed = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final importState = ref.watch(yamlImportProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DATA SYNCHRONIZATION',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            letterSpacing: 2.0,
                            color: Color(0xFF666666),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'YAML Parser',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 28,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: importState.when(
                data: (result) {
                  if (!_hasParsed || result == null) {
                    return _PasteView(
                      textCtrl: _textCtrl,
                      onParse: () {
                        if (_textCtrl.text.trim().isEmpty) return;
                        setState(() => _hasParsed = true);
                        ref.read(yamlImportProvider.notifier).parse(_textCtrl.text);
                      },
                    );
                  }
                  return _ResultView(
                    result: result,
                    onReset: () {
                      setState(() => _hasParsed = false);
                      ref.read(yamlImportProvider.notifier).reset();
                    },
                    onCommit: () async {
                      await ref.read(yamlImportProvider.notifier).commitImport(result);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Goals imported successfully!')),
                        );
                        setState(() => _hasParsed = false);
                        ref.read(pageIndexProvider.notifier).state = 0;
                      }
                    },
                  );
                },
                loading: () => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.accentBlue),
                      SizedBox(height: 16),
                      Text('Validating YAML…', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: AppTypography.body.copyWith(color: AppColors.accentRed)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Paste view ─────────────────────────────────────────────────────────────

class _PasteView extends StatelessWidget {
  final TextEditingController textCtrl;
  final VoidCallback onParse;
  const _PasteView({required this.textCtrl, required this.onParse});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          // Example hint
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.white54),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Paste your YAML below. Use the AI Prompt page to generate it from an AI chat.',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      height: 1.5,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Text area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: TextField(
                controller: textCtrl,
                maxLines: null,
                expands: true,
                style: const TextStyle(
                  fontFamily: 'Inter', // Or a monospace font
                  fontSize: 13,
                  height: 1.6,
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: 'version: "1.0"\ngoals:\n  - id: my_goal\n    name: "My Goal"\n    ...',
                  hintStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Colors.white38,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onParse,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'VALIDATE YAML',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Result view ────────────────────────────────────────────────────────────

class _ResultView extends StatefulWidget {
  final YamlImportResult result;
  final VoidCallback onReset;
  final VoidCallback onCommit;
  const _ResultView({
    required this.result,
    required this.onReset,
    required this.onCommit,
  });

  @override
  State<_ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<_ResultView> {
  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final canCommit = r.validGoals.isNotEmpty ||
        r.conflictGoals.any((g) => !g.skipOnConflict);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          // Summary row
          _SummaryRow(
            valid: r.validGoals.length,
            conflicts: r.conflictGoals.length,
            errors: r.errors.length,
          ),

          const SizedBox(height: 24),

          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                // Errors
                if (r.errors.isNotEmpty) ...[
                  const _SectionHeader('ERRORS'),
                  const SizedBox(height: 12),
                  ...r.errors.map((e) => _ErrorCard(message: e)),
                  const SizedBox(height: 24),
                ],

                // Valid goals
                if (r.validGoals.isNotEmpty) ...[
                  const _SectionHeader('VALID GOALS'),
                  const SizedBox(height: 12),
                  ...r.validGoals.map((g) => _GoalCard(
                        name: g.name,
                        tasks: g.tasks.length,
                        badge: 'New',
                        badgeColor: Colors.white,
                        trailingWidget: const Icon(Icons.check_circle, color: Color(0xFF27AE60), size: 18),
                      )),
                  const SizedBox(height: 24),
                ],

                // Conflicts
                if (r.conflictGoals.isNotEmpty) ...[
                  const _SectionHeader('CONFLICTS (Goal IDs exist)'),
                  const SizedBox(height: 12),
                  ...r.conflictGoals.map((g) => _ConflictCard(
                        goalData: g,
                        onSkipChanged: (skip) {
                          setState(() => g.skipOnConflict = skip);
                        },
                      )),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onReset,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'EDIT YAML',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, letterSpacing: 1.0, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: canCommit ? widget.onCommit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'IMPORT',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, letterSpacing: 1.0, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 10,
        letterSpacing: 2.0,
        fontWeight: FontWeight.w700,
        color: Colors.white54,
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final int valid;
  final int conflicts;
  final int errors;
  const _SummaryRow({required this.valid, required this.conflicts, required this.errors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SummaryBadge('$valid valid', const Color(0xFF27AE60)),
        const SizedBox(width: 8),
        if (conflicts > 0) _SummaryBadge('$conflicts conflict${conflicts > 1 ? 's' : ''}', const Color(0xFFF39C12)),
        if (conflicts > 0) const SizedBox(width: 8),
        if (errors > 0) _SummaryBadge('$errors error${errors > 1 ? 's' : ''}', const Color(0xFFE74C3C)),
      ],
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _SummaryBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 9,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A0505),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE74C3C).withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFE74C3C), size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Color(0xFFE74C3C),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
}

class _GoalCard extends StatelessWidget {
  final String name;
  final int tasks;
  final String badge;
  final Color badgeColor;
  final Widget? trailingWidget;
  const _GoalCard({
    required this.name,
    required this.tasks,
    required this.badge,
    required this.badgeColor,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$tasks task${tasks == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w600,
                  color: badgeColor,
                ),
              ),
            ),
            if (trailingWidget != null) ...[
              const SizedBox(width: 12),
              trailingWidget!,
            ],
          ],
        ),
      );
}

class _ConflictCard extends StatelessWidget {
  final YamlGoalData goalData;
  final ValueChanged<bool> onSkipChanged;
  const _ConflictCard({required this.goalData, required this.onSkipChanged});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF39C12).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goalData.name,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'ID already exists',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFFF39C12),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => onSkipChanged(false),
                  child: _ConflictOption(
                    label: 'OVERWRITE',
                    selected: !goalData.skipOnConflict,
                    color: const Color(0xFFE74C3C),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => onSkipChanged(true),
                  child: _ConflictOption(
                    label: 'SKIP',
                    selected: goalData.skipOnConflict,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _ConflictOption extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  const _ConflictOption({required this.label, required this.selected, required this.color});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? color : Colors.white10,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 9,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w600,
            color: selected ? color : Colors.white54,
          ),
        ),
      );
}


const String _testYaml = r'''version: "1.1"

goals:
  - id: health_fitness
    name: "Elevate Physical Fitness & Health"
    aim: "Transform cardiovascular strength, flexibility, and lean muscle mass."
    timeframe: month
    deadline: "2026-06-11"
    weight: 9
    color_index: 2
    status: in_progress
    tasks:
      - name: "Morning HIIT Cardio"
        schedule: daily
        reminder: "06:45"
        active: true
      - name: "Resistance Training (Upper Body)"
        schedule: weekly
        on: "Monday"
        reminder: "17:30"
        active: true
      - name: "Resistance Training (Lower Body)"
        schedule: weekly
        on: "Thursday"
        reminder: "17:30"
        active: true
      - name: "Mobility & Core Stretching"
        schedule: weekly
        on: "Saturday"
        reminder: "08:30"
        active: true
      - name: "Body Composition Analysis"
        schedule: monthly
        on: "1"
        reminder: "07:00"
        active: true
  - id: nutrition_science
    name: "Master Practical Nutrition Science"
    aim: "Optimize diet for sustained cognitive energy and physical recovery."
    timeframe: month
    deadline: "2026-06-06"
    weight: 7
    color_index: 3
    status: in_progress
    parent: health_fitness
    tasks:
      - name: "Log Daily Caloric Intake"
        schedule: daily
        reminder: "21:30"
        active: true
      - name: "Batch Meal Prep"
        schedule: weekly
        on: "Sunday"
        reminder: "15:00"
        active: true
      - name: "Read Nutrition Study"
        schedule: weekly
        on: "Wednesday"
        reminder: "20:00"
        active: true
  - id: software_engineering
    name: "Advanced Software Architecture Mastery"
    aim: "Build high-performance distributed systems and clean mobile applications."
    timeframe: month
    deadline: "2026-06-16"
    weight: 10
    color_index: 0
    status: in_progress
    tasks:
      - name: "System Design Architecture Study"
        schedule: daily
        reminder: "09:00"
        active: true
      - name: "Open Source Contributions"
        schedule: weekly
        on: "Friday"
        reminder: "19:00"
        active: true
      - name: "Write Tech Blog Post"
        schedule: monthly
        on: "28"
        reminder: "10:00"
        active: true
  - id: nexus_launch
    name: "Nexus Suite Production Launch"
    aim: "Compile production-ready app bundle, test widgets, and publish to Play Store."
    timeframe: month
    deadline: "2026-05-27"
    weight: 10
    color_index: 1
    status: in_progress
    depends_on:
      - software_engineering
      - health_fitness
    tasks:
      - name: "Beta Integration Testing"
        schedule: daily
        reminder: "11:30"
        active: true
      - name: "Build APK Release Candidate"
        schedule: weekly
        on: "Tuesday"
        reminder: "16:00"
        active: true
      - name: "Marketing Press Kit Assembly"
        schedule: specific_date
        reminder: "14:00"
        active: true
  - id: financial_freedom
    name: "Personal Finance & Investment Portfolio"
    aim: "Build a robust long-term investment strategy and automate savings."
    timeframe: month
    deadline: "2026-06-19"
    weight: 8
    color_index: 5
    status: not_started
    tasks:
      - name: "Track Monthly Budget Expenses"
        schedule: monthly
        on: "28"
        reminder: "21:00"
        active: true
      - name: "Review Portfolio Asset Allocation"
        schedule: weekly
        on: "Saturday"
        reminder: "10:30"
        active: true
  - id: academic_research
    name: "AI & Large Language Model Research"
    aim: "Publish novel research on local agents and offline optimization."
    timeframe: year
    deadline: "2026-11-18"
    weight: 9
    color_index: 6
    status: in_progress
    tasks:
      - name: "Read AI Research Paper"
        schedule: daily
        reminder: "08:00"
        active: true
      - name: "Write Thesis Abstract Section"
        schedule: weekly
        on: "Wednesday"
        reminder: "13:00"
        active: true
  - id: creative_writing
    name: "Write Sci-Fi Short Story Anthology"
    aim: "Complete 5 distinct speculative fiction short stories."
    timeframe: month
    deadline: "2026-06-03"
    weight: 4
    color_index: 7
    status: not_started
    tasks:
      - name: "Daily Word Count Write"
        schedule: daily
        reminder: "22:00"
        active: true
      - name: "Peer Review Workshop"
        schedule: weekly
        on: "Saturday"
        reminder: "16:00"
        active: true
  - id: home_organization
    name: "Complete Smart Home Automation Setup"
    aim: "Configure local servers, security automation, and home dashboard."
    timeframe: week
    deadline: "2026-05-17"
    weight: 5
    color_index: 4
    status: completed
    tasks:
      - name: "Maintain Automation Servers"
        schedule: weekly
        on: "Sunday"
        reminder: "11:00"
        active: true
  - id: language_learning
    name: "Learn Intermediate Spanish (B2)"
    aim: "Engage in natural conversations and read literature in Spanish."
    timeframe: month
    deadline: "2026-06-21"
    weight: 6
    color_index: 2
    status: in_progress
    tasks:
      - name: "Vocabulary Flashcards Review"
        schedule: daily
        reminder: "07:15"
        active: true
      - name: "Spanish Speaking Tandem Session"
        schedule: weekly
        on: "Friday"
        reminder: "18:00"
        active: true
  - id: meditation_mindfulness
    name: "Cultivate High Focus & Presence"
    aim: "Achieve consistent morning mindfulness routines to reduce stress."
    timeframe: day
    deadline: "2026-05-23"
    weight: 7
    color_index: 1
    status: in_progress
    tasks:
      - name: "Vipassana Meditation Session"
        schedule: daily
        reminder: "06:00"
        active: true
activity_logs:
  - date: 1776796200000
    category: "routine"
    name: "Morning Meditation"
    start_time: 1776817800000
    end_time: 1776819000000
    notes: "Vipassana focus session"
    is_auto: false
    created_at: 1776817800000
  - date: 1776796200000
    category: "exercise"
    name: "HIIT Run"
    start_time: 1776820500000
    end_time: 1776822300000
    notes: "Fast intervals on track"
    is_auto: false
    created_at: 1776820500000
  - date: 1776796200000
    category: "deep_work"
    name: "Core Engine Dev"
    start_time: 1776828600000
    end_time: 1776839400000
    notes: "Refactoring Rust synchronization client"
    is_auto: false
    created_at: 1776828600000
  - date: 1776796200000
    category: "learning"
    name: "System Design Study"
    start_time: 1776843000000
    end_time: 1776850200000
    notes: "Studying Raft consensus algorithm"
    is_auto: false
    created_at: 1776843000000
  - date: 1776796200000
    category: "deep_work"
    name: "Flutter UI Features"
    start_time: 1776852000000
    end_time: 1776859200000
    notes: "Implemented new radial bubble options"
    is_auto: false
    created_at: 1776852000000
  - date: 1776796200000
    category: "routine"
    name: "Evening Meal Prep"
    start_time: 1776862800000
    end_time: 1776864600000
    notes: "Cooking high-protein meals"
    is_auto: false
    created_at: 1776862800000
  - date: 1776796200000
    category: "leisure"
    name: "Wind down reading"
    start_time: 1776873600000
    end_time: 1776875400000
    notes: "Reading Dune chapter 4"
    is_auto: false
    created_at: 1776873600000
  - date: 1776882600000
    category: "leisure"
    name: "Binge Watching Series"
    start_time: 1776918600000
    end_time: 1776947400000
    notes: "Wasted the whole day on netflix"
    is_auto: false
    created_at: 1776918600000
  - date: 1776882600000
    category: "leisure"
    name: "Gaming session"
    start_time: 1776951000000
    end_time: 1776961800000
    notes: "Played multiplayer games late"
    is_auto: false
    created_at: 1776951000000
  - date: 1776969000000
    category: "routine"
    name: "Morning Clean"
    start_time: 1776997800000
    end_time: 1777001400000
    notes: "Quick house maintenance"
    is_auto: false
    created_at: 1776997800000
  - date: 1776969000000
    category: "leisure"
    name: "Social Media & TV"
    start_time: 1777005000000
    end_time: 1777023000000
    notes: "Unproductive scrolling"
    is_auto: false
    created_at: 1777005000000
  - date: 1776969000000
    category: "deep_work"
    name: "Email responses"
    start_time: 1777026600000
    end_time: 1777030200000
    notes: "Answered client tickets"
    is_auto: false
    created_at: 1777026600000
  - date: 1777055400000
    category: "routine"
    name: "Laundry & Groceries"
    start_time: 1777091400000
    end_time: 1777098600000
    notes: "Weekly chores"
    is_auto: false
    created_at: 1777091400000
  - date: 1777055400000
    category: "leisure"
    name: "Streaming Movies"
    start_time: 1777102200000
    end_time: 1777113000000
    notes: "Watched dynamic documentaries"
    is_auto: false
    created_at: 1777102200000
  - date: 1777055400000
    category: "deep_work"
    name: "Bug Triage"
    start_time: 1777114800000
    end_time: 1777122000000
    notes: "Fixed minor UI overflows in profile view"
    is_auto: false
    created_at: 1777114800000
  - date: 1777141800000
    category: "exercise"
    name: "Weight Lifting"
    start_time: 1777167000000
    end_time: 1777170600000
    notes: "Bench press and squats"
    is_auto: false
    created_at: 1777167000000
  - date: 1777141800000
    category: "routine"
    name: "Morning Commute & Admin"
    start_time: 1777172400000
    end_time: 1777176000000
    notes: "Organized daily tasks"
    is_auto: false
    created_at: 1777172400000
  - date: 1777141800000
    category: "deep_work"
    name: "Nexus App Layouts"
    start_time: 1777177800000
    end_time: 1777188600000
    notes: "Designed new settings menu and tiles"
    is_auto: false
    created_at: 1777177800000
  - date: 1777141800000
    category: "leisure"
    name: "Video games"
    start_time: 1777213800000
    end_time: 1777221000000
    notes: "Played some casual games"
    is_auto: false
    created_at: 1777213800000
  - date: 1777228200000
    category: "deep_work"
    name: "Core Engine Dev"
    start_time: 1777260600000
    end_time: 1777275000000
    notes: "Fixed database deadlock bugs"
    is_auto: false
    created_at: 1777260600000
  - date: 1777228200000
    category: "learning"
    name: "Spanish Vocab"
    start_time: 1777278600000
    end_time: 1777282200000
    notes: "Completed flashcards"
    is_auto: false
    created_at: 1777278600000
  - date: 1777228200000
    category: "routine"
    name: "Tidy room & desk"
    start_time: 1777285800000
    end_time: 1777289400000
    notes: "Cleaned workspaces"
    is_auto: false
    created_at: 1777285800000
  - date: 1777228200000
    category: "social"
    name: "Dinner with friends"
    start_time: 1777296600000
    end_time: 1777303800000
    notes: "Enjoyed good conversations"
    is_auto: false
    created_at: 1777296600000
  - date: 1777314600000
    category: "routine"
    name: "Morning Meditation"
    start_time: 1777336200000
    end_time: 1777337400000
    notes: "Vipassana focus session"
    is_auto: false
    created_at: 1777336200000
  - date: 1777314600000
    category: "exercise"
    name: "HIIT Run"
    start_time: 1777338900000
    end_time: 1777340700000
    notes: "Fast intervals on track"
    is_auto: false
    created_at: 1777338900000
  - date: 1777314600000
    category: "deep_work"
    name: "Core Engine Dev"
    start_time: 1777347000000
    end_time: 1777357800000
    notes: "Refactoring Rust synchronization client"
    is_auto: false
    created_at: 1777347000000
  - date: 1777314600000
    category: "learning"
    name: "System Design Study"
    start_time: 1777361400000
    end_time: 1777368600000
    notes: "Studying Raft consensus algorithm"
    is_auto: false
    created_at: 1777361400000
  - date: 1777314600000
    category: "deep_work"
    name: "Flutter UI Features"
    start_time: 1777370400000
    end_time: 1777377600000
    notes: "Implemented new radial bubble options"
    is_auto: false
    created_at: 1777370400000
  - date: 1777314600000
    category: "routine"
    name: "Evening Meal Prep"
    start_time: 1777381200000
    end_time: 1777383000000
    notes: "Cooking high-protein meals"
    is_auto: false
    created_at: 1777381200000
  - date: 1777314600000
    category: "leisure"
    name: "Wind down reading"
    start_time: 1777392000000
    end_time: 1777393800000
    notes: "Reading Dune chapter 4"
    is_auto: false
    created_at: 1777392000000
  - date: 1777401000000
    category: "leisure"
    name: "Binge Watching Series"
    start_time: 1777437000000
    end_time: 1777465800000
    notes: "Wasted the whole day on netflix"
    is_auto: false
    created_at: 1777437000000
  - date: 1777401000000
    category: "leisure"
    name: "Gaming session"
    start_time: 1777469400000
    end_time: 1777480200000
    notes: "Played multiplayer games late"
    is_auto: false
    created_at: 1777469400000
  - date: 1777487400000
    category: "routine"
    name: "Morning Clean"
    start_time: 1777516200000
    end_time: 1777519800000
    notes: "Quick house maintenance"
    is_auto: false
    created_at: 1777516200000
  - date: 1777487400000
    category: "leisure"
    name: "Social Media & TV"
    start_time: 1777523400000
    end_time: 1777541400000
    notes: "Unproductive scrolling"
    is_auto: false
    created_at: 1777523400000
  - date: 1777487400000
    category: "deep_work"
    name: "Email responses"
    start_time: 1777545000000
    end_time: 1777548600000
    notes: "Answered client tickets"
    is_auto: false
    created_at: 1777545000000
  - date: 1777573800000
    category: "routine"
    name: "Laundry & Groceries"
    start_time: 1777609800000
    end_time: 1777617000000
    notes: "Weekly chores"
    is_auto: false
    created_at: 1777609800000
  - date: 1777573800000
    category: "leisure"
    name: "Streaming Movies"
    start_time: 1777620600000
    end_time: 1777631400000
    notes: "Watched dynamic documentaries"
    is_auto: false
    created_at: 1777620600000
  - date: 1777573800000
    category: "deep_work"
    name: "Bug Triage"
    start_time: 1777633200000
    end_time: 1777640400000
    notes: "Fixed minor UI overflows in profile view"
    is_auto: false
    created_at: 1777633200000
  - date: 1777660200000
    category: "exercise"
    name: "Weight Lifting"
    start_time: 1777685400000
    end_time: 1777689000000
    notes: "Bench press and squats"
    is_auto: false
    created_at: 1777685400000
  - date: 1777660200000
    category: "routine"
    name: "Morning Commute & Admin"
    start_time: 1777690800000
    end_time: 1777694400000
    notes: "Organized daily tasks"
    is_auto: false
    created_at: 1777690800000
  - date: 1777660200000
    category: "deep_work"
    name: "Nexus App Layouts"
    start_time: 1777696200000
    end_time: 1777707000000
    notes: "Designed new settings menu and tiles"
    is_auto: false
    created_at: 1777696200000
  - date: 1777660200000
    category: "leisure"
    name: "Video games"
    start_time: 1777732200000
    end_time: 1777739400000
    notes: "Played some casual games"
    is_auto: false
    created_at: 1777732200000
  - date: 1777746600000
    category: "deep_work"
    name: "Core Engine Dev"
    start_time: 1777779000000
    end_time: 1777793400000
    notes: "Fixed database deadlock bugs"
    is_auto: false
    created_at: 1777779000000
  - date: 1777746600000
    category: "learning"
    name: "Spanish Vocab"
    start_time: 1777797000000
    end_time: 1777800600000
    notes: "Completed flashcards"
    is_auto: false
    created_at: 1777797000000
  - date: 1777746600000
    category: "routine"
    name: "Tidy room & desk"
    start_time: 1777804200000
    end_time: 1777807800000
    notes: "Cleaned workspaces"
    is_auto: false
    created_at: 1777804200000
  - date: 1777746600000
    category: "social"
    name: "Dinner with friends"
    start_time: 1777815000000
    end_time: 1777822200000
    notes: "Enjoyed good conversations"
    is_auto: false
    created_at: 1777815000000
  - date: 1777833000000
    category: "routine"
    name: "Morning Meditation"
    start_time: 1777854600000
    end_time: 1777855800000
    notes: "Vipassana focus session"
    is_auto: false
    created_at: 1777854600000
  - date: 1777833000000
    category: "exercise"
    name: "HIIT Run"
    start_time: 1777857300000
    end_time: 1777859100000
    notes: "Fast intervals on track"
    is_auto: false
    created_at: 1777857300000
  - date: 1777833000000
    category: "deep_work"
    name: "Core Engine Dev"
    start_time: 1777865400000
    end_time: 1777876200000
    notes: "Refactoring Rust synchronization client"
    is_auto: false
    created_at: 1777865400000
  - date: 1777833000000
    category: "learning"
    name: "System Design Study"
    start_time: 1777879800000
    end_time: 1777887000000
    notes: "Studying Raft consensus algorithm"
    is_auto: false
    created_at: 1777879800000
  - date: 1777833000000
    category: "deep_work"
    name: "Flutter UI Features"
    start_time: 1777888800000
    end_time: 1777896000000
    notes: "Implemented new radial bubble options"
    is_auto: false
    created_at: 1777888800000
  - date: 1777833000000
    category: "routine"
    name: "Evening Meal Prep"
    start_time: 1777899600000
    end_time: 1777901400000
    notes: "Cooking high-protein meals"
    is_auto: false
    created_at: 1777899600000
  - date: 1777833000000
    category: "leisure"
    name: "Wind down reading"
    start_time: 1777910400000
    end_time: 1777912200000
    notes: "Reading Dune chapter 4"
    is_auto: false
    created_at: 1777910400000
  - date: 1777919400000
    category: "leisure"
    name: "Binge Watching Series"
    start_time: 1777955400000
    end_time: 1777984200000
    notes: "Wasted the whole day on netflix"
    is_auto: false
    created_at: 1777955400000
  - date: 1777919400000
    category: "leisure"
    name: "Gaming session"
    start_time: 1777987800000
    end_time: 1777998600000
    notes: "Played multiplayer games late"
    is_auto: false
    created_at: 1777987800000
  - date: 1778005800000
    category: "routine"
    name: "Morning Clean"
    start_time: 1778034600000
    end_time: 1778038200000
    notes: "Quick house maintenance"
    is_auto: false
    created_at: 1778034600000
  - date: 1778005800000
    category: "leisure"
    name: "Social Media & TV"
    start_time: 1778041800000
    end_time: 1778059800000
    notes: "Unproductive scrolling"
    is_auto: false
    created_at: 1778041800000
  - date: 1778005800000
    category: "deep_work"
    name: "Email responses"
    start_time: 1778063400000
    end_time: 1778067000000
    notes: "Answered client tickets"
    is_auto: false
    created_at: 1778063400000
  - date: 1778092200000
    category: "routine"
    name: "Laundry & Groceries"
    start_time: 1778128200000
    end_time: 1778135400000
    notes: "Weekly chores"
    is_auto: false
    created_at: 1778128200000
  - date: 1778092200000
    category: "leisure"
    name: "Streaming Movies"
    start_time: 1778139000000
    end_time: 1778149800000
    notes: "Watched dynamic documentaries"
    is_auto: false
    created_at: 1778139000000
  - date: 1778092200000
    category: "deep_work"
    name: "Bug Triage"
    start_time: 1778151600000
    end_time: 1778158800000
    notes: "Fixed minor UI overflows in profile view"
    is_auto: false
    created_at: 1778151600000
  - date: 1778178600000
    category: "exercise"
    name: "Weight Lifting"
    start_time: 1778203800000
    end_time: 1778207400000
    notes: "Bench press and squats"
    is_auto: false
    created_at: 1778203800000
  - date: 1778178600000
    category: "routine"
    name: "Morning Commute & Admin"
    start_time: 1778209200000
    end_time: 1778212800000
    notes: "Organized daily tasks"
    is_auto: false
    created_at: 1778209200000
  - date: 1778178600000
    category: "deep_work"
    name: "Nexus App Layouts"
    start_time: 1778214600000
    end_time: 1778225400000
    notes: "Designed new settings menu and tiles"
    is_auto: false
    created_at: 1778214600000
  - date: 1778178600000
    category: "leisure"
    name: "Video games"
    start_time: 1778250600000
    end_time: 1778257800000
    notes: "Played some casual games"
    is_auto: false
    created_at: 1778250600000
  - date: 1778265000000
    category: "deep_work"
    name: "Core Engine Dev"
    start_time: 1778297400000
    end_time: 1778311800000
    notes: "Fixed database deadlock bugs"
    is_auto: false
    created_at: 1778297400000
  - date: 1778265000000
    category: "learning"
    name: "Spanish Vocab"
    start_time: 1778315400000
    end_time: 1778319000000
    notes: "Completed flashcards"
    is_auto: false
    created_at: 1778315400000
  - date: 1778265000000
    category: "routine"
    name: "Tidy room & desk"
    start_time: 1778322600000
    end_time: 1778326200000
    notes: "Cleaned workspaces"
    is_auto: false
    created_at: 1778322600000
  - date: 1778265000000
    category: "social"
    name: "Dinner with friends"
    start_time: 1778333400000
    end_time: 1778340600000
    notes: "Enjoyed good conversations"
    is_auto: false
    created_at: 1778333400000
  - date: 1778351400000
    category: "routine"
    name: "Morning Meditation"
    start_time: 1778373000000
    end_time: 1778374200000
    notes: "Vipassana focus session"
    is_auto: false
    created_at: 1778373000000
  - date: 1778351400000
    category: "exercise"
    name: "HIIT Run"
    start_time: 1778375700000
    end_time: 1778377500000
    notes: "Fast intervals on track"
    is_auto: false
    created_at: 1778375700000
  - date: 1778351400000
    category: "deep_work"
    name: "Core Engine Dev"
    start_time: 1778383800000
    end_time: 1778394600000
    notes: "Refactoring Rust synchronization client"
    is_auto: false
    created_at: 1778383800000
  - date: 1778351400000
    category: "learning"
    name: "System Design Study"
    start_time: 1778398200000
    end_time: 1778405400000
    notes: "Studying Raft consensus algorithm"
    is_auto: false
    created_at: 1778398200000
  - date: 1778351400000
    category: "deep_work"
    name: "Flutter UI Features"
    start_time: 1778407200000
    end_time: 1778414400000
    notes: "Implemented new radial bubble options"
    is_auto: false
    created_at: 1778407200000
  - date: 1778351400000
    category: "routine"
    name: "Evening Meal Prep"
    start_time: 1778418000000
    end_time: 1778419800000
    notes: "Cooking high-protein meals"
    is_auto: false
    created_at: 1778418000000
  - date: 1778351400000
    category: "leisure"
    name: "Wind down reading"
    start_time: 1778428800000
    end_time: 1778430600000
    notes: "Reading Dune chapter 4"
    is_auto: false
    created_at: 1778428800000
  - date: 1778437800000
    category: "leisure"
    name: "Binge Watching Series"
    start_time: 1778473800000
    end_time: 1778502600000
    notes: "Wasted the whole day on netflix"
    is_auto: false
    created_at: 1778473800000
  - date: 1778437800000
    category: "leisure"
    name: "Gaming session"
    start_time: 1778506200000
    end_time: 1778517000000
    notes: "Played multiplayer games late"
    is_auto: false
    created_at: 1778506200000
  - date: 1778524200000
    category: "routine"
    name: "Morning Clean"
    start_time: 1778553000000
    end_time: 1778556600000
    notes: "Quick house maintenance"
    is_auto: false
    created_at: 1778553000000
  - date: 1778524200000
    category: "leisure"
    name: "Social Media & TV"
    start_time: 1778560200000
    end_time: 1778578200000
    notes: "Unproductive scrolling"
    is_auto: false
    created_at: 1778560200000
  - date: 1778524200000
    category: "deep_work"
    name: "Email responses"
    start_time: 1778581800000
    end_time: 1778585400000
    notes: "Answered client tickets"
    is_auto: false
    created_at: 1778581800000
  - date: 1778610600000
    category: "routine"
    name: "Laundry & Groceries"
    start_time: 1778646600000
    end_time: 1778653800000
    notes: "Weekly chores"
    is_auto: false
    created_at: 1778646600000
  - date: 1778610600000
    category: "leisure"
    name: "Streaming Movies"
    start_time: 1778657400000
    end_time: 1778668200000
    notes: "Watched dynamic documentaries"
    is_auto: false
    created_at: 1778657400000
  - date: 1778610600000
    category: "deep_work"
    name: "Bug Triage"
    start_time: 1778670000000
    end_time: 1778677200000
    notes: "Fixed minor UI overflows in profile view"
    is_auto: false
    created_at: 1778670000000
  - date: 1778697000000
    category: "exercise"
    name: "Weight Lifting"
    start_time: 1778722200000
    end_time: 1778725800000
    notes: "Bench press and squats"
    is_auto: false
    created_at: 1778722200000
  - date: 1778697000000
    category: "routine"
    name: "Morning Commute & Admin"
    start_time: 1778727600000
    end_time: 1778731200000
    notes: "Organized daily tasks"
    is_auto: false
    created_at: 1778727600000
  - date: 1778697000000
    category: "deep_work"
    name: "Nexus App Layouts"
    start_time: 1778733000000
    end_time: 1778743800000
    notes: "Designed new settings menu and tiles"
    is_auto: false
    created_at: 1778733000000
  - date: 1778697000000
    category: "leisure"
    name: "Video games"
    start_time: 1778769000000
    end_time: 1778776200000
    notes: "Played some casual games"
    is_auto: false
    created_at: 1778769000000
  - date: 1778783400000
    category: "deep_work"
    name: "Core Engine Dev"
    start_time: 1778815800000
    end_time: 1778830200000
    notes: "Fixed database deadlock bugs"
    is_auto: false
    created_at: 1778815800000
  - date: 1778783400000
    category: "learning"
    name: "Spanish Vocab"
    start_time: 1778833800000
    end_time: 1778837400000
    notes: "Completed flashcards"
    is_auto: false
    created_at: 1778833800000
  - date: 1778783400000
    category: "routine"
    name: "Tidy room & desk"
    start_time: 1778841000000
    end_time: 1778844600000
    notes: "Cleaned workspaces"
    is_auto: false
    created_at: 1778841000000
  - date: 1778783400000
    category: "social"
    name: "Dinner with friends"
    start_time: 1778851800000
    end_time: 1778859000000
    notes: "Enjoyed good conversations"
    is_auto: false
    created_at: 1778851800000
  - date: 1778869800000
    category: "routine"
    name: "Morning Meditation"
    start_time: 1778891400000
    end_time: 1778892600000
    notes: "Vipassana focus session"
    is_auto: false
    created_at: 1778891400000
  - date: 1778869800000
    category: "exercise"
    name: "HIIT Run"
    start_time: 1778894100000
    end_time: 1778895900000
    notes: "Fast intervals on track"
    is_auto: false
    created_at: 1778894100000
  - date: 1778869800000
    category: "deep_work"
    name: "Core Engine Dev"
    start_time: 1778902200000
    end_time: 1778913000000
    notes: "Refactoring Rust synchronization client"
    is_auto: false
    created_at: 1778902200000
  - date: 1778869800000
    category: "learning"
    name: "System Design Study"
    start_time: 1778916600000
    end_time: 1778923800000
    notes: "Studying Raft consensus algorithm"
    is_auto: false
    created_at: 1778916600000
  - date: 1778869800000
    category: "deep_work"
    name: "Flutter UI Features"
    start_time: 1778925600000
    end_time: 1778932800000
    notes: "Implemented new radial bubble options"
    is_auto: false
    created_at: 1778925600000
  - date: 1778869800000
    category: "routine"
    name: "Evening Meal Prep"
    start_time: 1778936400000
    end_time: 1778938200000
    notes: "Cooking high-protein meals"
    is_auto: false
    created_at: 1778936400000
  - date: 1778869800000
    category: "leisure"
    name: "Wind down reading"
    start_time: 1778947200000
    end_time: 1778949000000
    notes: "Reading Dune chapter 4"
    is_auto: false
    created_at: 1778947200000
  - date: 1778956200000
    category: "leisure"
    name: "Binge Watching Series"
    start_time: 1778992200000
    end_time: 1779021000000
    notes: "Wasted the whole day on netflix"
    is_auto: false
    created_at: 1778992200000
  - date: 1778956200000
    category: "leisure"
    name: "Gaming session"
    start_time: 1779024600000
    end_time: 1779035400000
    notes: "Played multiplayer games late"
    is_auto: false
    created_at: 1779024600000
  - date: 1779042600000
    category: "routine"
    name: "Morning Clean"
    start_time: 1779071400000
    end_time: 1779075000000
    notes: "Quick house maintenance"
    is_auto: false
    created_at: 1779071400000
  - date: 1779042600000
    category: "leisure"
    name: "Social Media & TV"
    start_time: 1779078600000
    end_time: 1779096600000
    notes: "Unproductive scrolling"
    is_auto: false
    created_at: 1779078600000
  - date: 1779042600000
    category: "deep_work"
    name: "Email responses"
    start_time: 1779100200000
    end_time: 1779103800000
    notes: "Answered client tickets"
    is_auto: false
    created_at: 1779100200000
  - date: 1779129000000
    category: "routine"
    name: "Laundry & Groceries"
    start_time: 1779165000000
    end_time: 1779172200000
    notes: "Weekly chores"
    is_auto: false
    created_at: 1779165000000
  - date: 1779129000000
    category: "leisure"
    name: "Streaming Movies"
    start_time: 1779175800000
    end_time: 1779186600000
    notes: "Watched dynamic documentaries"
    is_auto: false
    created_at: 1779175800000
  - date: 1779129000000
    category: "deep_work"
    name: "Bug Triage"
    start_time: 1779188400000
    end_time: 1779195600000
    notes: "Fixed minor UI overflows in profile view"
    is_auto: false
    created_at: 1779188400000
  - date: 1779215400000
    category: "exercise"
    name: "Weight Lifting"
    start_time: 1779240600000
    end_time: 1779244200000
    notes: "Bench press and squats"
    is_auto: false
    created_at: 1779240600000
  - date: 1779215400000
    category: "routine"
    name: "Morning Commute & Admin"
    start_time: 1779246000000
    end_time: 1779249600000
    notes: "Organized daily tasks"
    is_auto: false
    created_at: 1779246000000
  - date: 1779215400000
    category: "deep_work"
    name: "Nexus App Layouts"
    start_time: 1779251400000
    end_time: 1779262200000
    notes: "Designed new settings menu and tiles"
    is_auto: false
    created_at: 1779251400000
  - date: 1779215400000
    category: "leisure"
    name: "Video games"
    start_time: 1779287400000
    end_time: 1779294600000
    notes: "Played some casual games"
    is_auto: false
    created_at: 1779287400000
  - date: 1779301800000
    category: "deep_work"
    name: "Core Engine Dev"
    start_time: 1779334200000
    end_time: 1779348600000
    notes: "Fixed database deadlock bugs"
    is_auto: false
    created_at: 1779334200000
  - date: 1779301800000
    category: "learning"
    name: "Spanish Vocab"
    start_time: 1779352200000
    end_time: 1779355800000
    notes: "Completed flashcards"
    is_auto: false
    created_at: 1779352200000
  - date: 1779301800000
    category: "routine"
    name: "Tidy room & desk"
    start_time: 1779359400000
    end_time: 1779363000000
    notes: "Cleaned workspaces"
    is_auto: false
    created_at: 1779359400000
  - date: 1779301800000
    category: "social"
    name: "Dinner with friends"
    start_time: 1779370200000
    end_time: 1779377400000
    notes: "Enjoyed good conversations"
    is_auto: false
    created_at: 1779370200000
  - date: 1779388200000
    category: "routine"
    name: "Morning Meditation"
    start_time: 1779409800000
    end_time: 1779411000000
    notes: "Vipassana focus session"
    is_auto: false
    created_at: 1779409800000
  - date: 1779388200000
    category: "exercise"
    name: "HIIT Run"
    start_time: 1779412500000
    end_time: 1779414300000
    notes: "Fast intervals on track"
    is_auto: false
    created_at: 1779412500000
  - date: 1779388200000
    category: "deep_work"
    name: "Core Engine Dev"
    start_time: 1779420600000
    end_time: 1779431400000
    notes: "Refactoring Rust synchronization client"
    is_auto: false
    created_at: 1779420600000
  - date: 1779388200000
    category: "learning"
    name: "System Design Study"
    start_time: 1779435000000
    end_time: 1779442200000
    notes: "Studying Raft consensus algorithm"
    is_auto: false
    created_at: 1779435000000
  - date: 1779388200000
    category: "deep_work"
    name: "Flutter UI Features"
    start_time: 1779444000000
    end_time: 1779451200000
    notes: "Implemented new radial bubble options"
    is_auto: false
    created_at: 1779444000000
  - date: 1779388200000
    category: "routine"
    name: "Evening Meal Prep"
    start_time: 1779454800000
    end_time: 1779456600000
    notes: "Cooking high-protein meals"
    is_auto: false
    created_at: 1779454800000
  - date: 1779388200000
    category: "leisure"
    name: "Wind down reading"
    start_time: 1779465600000
    end_time: 1779467400000
    notes: "Reading Dune chapter 4"
    is_auto: false
    created_at: 1779465600000

sleep_logs:
  - date: 1776796200000
    sleep_time: 1776790800000
    wake_time: 1776819600000
    quality_note: "Woke up feeling incredibly focused. REM and Deep Sleep cycles were perfect."
    created_at: 1776819600000
  - date: 1776882600000
    sleep_time: 1776801600000
    wake_time: 1776904200000
    quality_note: "Late night work. Exhausted."
    created_at: 1776904200000
  - date: 1776969000000
    sleep_time: 1776884400000
    wake_time: 1776990600000
    quality_note: "Too short. Difficult to fall asleep."
    created_at: 1776990600000
  - date: 1777055400000
    sleep_time: 1777053600000
    wake_time: 1777077000000
    quality_note: "Slightly interrupted sleep, felt a bit tired."
    created_at: 1777077000000
  - date: 1777141800000
    sleep_time: 1777140000000
    wake_time: 1777165200000
    quality_note: "Good sleep. Ready for the day."
    created_at: 1777165200000
  - date: 1777228200000
    sleep_time: 1777224600000
    wake_time: 1777251600000
    quality_note: "Restful sleep, minimal waking periods."
    created_at: 1777251600000
  - date: 1777314600000
    sleep_time: 1777309200000
    wake_time: 1777338000000
    quality_note: "Woke up feeling incredibly focused. REM and Deep Sleep cycles were perfect."
    created_at: 1777338000000
  - date: 1777401000000
    sleep_time: 1777320000000
    wake_time: 1777422600000
    quality_note: "Late night work. Exhausted."
    created_at: 1777422600000
  - date: 1777487400000
    sleep_time: 1777402800000
    wake_time: 1777509000000
    quality_note: "Too short. Difficult to fall asleep."
    created_at: 1777509000000
  - date: 1777573800000
    sleep_time: 1777572000000
    wake_time: 1777595400000
    quality_note: "Slightly interrupted sleep, felt a bit tired."
    created_at: 1777595400000
  - date: 1777660200000
    sleep_time: 1777658400000
    wake_time: 1777683600000
    quality_note: "Good sleep. Ready for the day."
    created_at: 1777683600000
  - date: 1777746600000
    sleep_time: 1777743000000
    wake_time: 1777770000000
    quality_note: "Restful sleep, minimal waking periods."
    created_at: 1777770000000
  - date: 1777833000000
    sleep_time: 1777827600000
    wake_time: 1777856400000
    quality_note: "Woke up feeling incredibly focused. REM and Deep Sleep cycles were perfect."
    created_at: 1777856400000
  - date: 1777919400000
    sleep_time: 1777838400000
    wake_time: 1777941000000
    quality_note: "Late night work. Exhausted."
    created_at: 1777941000000
  - date: 1778005800000
    sleep_time: 1777921200000
    wake_time: 1778027400000
    quality_note: "Too short. Difficult to fall asleep."
    created_at: 1778027400000
  - date: 1778092200000
    sleep_time: 1778090400000
    wake_time: 1778113800000
    quality_note: "Slightly interrupted sleep, felt a bit tired."
    created_at: 1778113800000
  - date: 1778178600000
    sleep_time: 1778176800000
    wake_time: 1778202000000
    quality_note: "Good sleep. Ready for the day."
    created_at: 1778202000000
  - date: 1778265000000
    sleep_time: 1778261400000
    wake_time: 1778288400000
    quality_note: "Restful sleep, minimal waking periods."
    created_at: 1778288400000
  - date: 1778351400000
    sleep_time: 1778346000000
    wake_time: 1778374800000
    quality_note: "Woke up feeling incredibly focused. REM and Deep Sleep cycles were perfect."
    created_at: 1778374800000
  - date: 1778437800000
    sleep_time: 1778356800000
    wake_time: 1778459400000
    quality_note: "Late night work. Exhausted."
    created_at: 1778459400000
  - date: 1778524200000
    sleep_time: 1778439600000
    wake_time: 1778545800000
    quality_note: "Too short. Difficult to fall asleep."
    created_at: 1778545800000
  - date: 1778610600000
    sleep_time: 1778608800000
    wake_time: 1778632200000
    quality_note: "Slightly interrupted sleep, felt a bit tired."
    created_at: 1778632200000
  - date: 1778697000000
    sleep_time: 1778695200000
    wake_time: 1778720400000
    quality_note: "Good sleep. Ready for the day."
    created_at: 1778720400000
  - date: 1778783400000
    sleep_time: 1778779800000
    wake_time: 1778806800000
    quality_note: "Restful sleep, minimal waking periods."
    created_at: 1778806800000
  - date: 1778869800000
    sleep_time: 1778864400000
    wake_time: 1778893200000
    quality_note: "Woke up feeling incredibly focused. REM and Deep Sleep cycles were perfect."
    created_at: 1778893200000
  - date: 1778956200000
    sleep_time: 1778875200000
    wake_time: 1778977800000
    quality_note: "Late night work. Exhausted."
    created_at: 1778977800000
  - date: 1779042600000
    sleep_time: 1778958000000
    wake_time: 1779064200000
    quality_note: "Too short. Difficult to fall asleep."
    created_at: 1779064200000
  - date: 1779129000000
    sleep_time: 1779127200000
    wake_time: 1779150600000
    quality_note: "Slightly interrupted sleep, felt a bit tired."
    created_at: 1779150600000
  - date: 1779215400000
    sleep_time: 1779213600000
    wake_time: 1779238800000
    quality_note: "Good sleep. Ready for the day."
    created_at: 1779238800000
  - date: 1779301800000
    sleep_time: 1779298200000
    wake_time: 1779325200000
    quality_note: "Restful sleep, minimal waking periods."
    created_at: 1779325200000
  - date: 1779388200000
    sleep_time: 1779382800000
    wake_time: 1779411600000
    quality_note: "Woke up feeling incredibly focused. REM and Deep Sleep cycles were perfect."
    created_at: 1779411600000''';
