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
  final _textCtrl = TextEditingController();
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
