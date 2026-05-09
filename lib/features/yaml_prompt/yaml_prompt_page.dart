import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../shared/theme/app_theme.dart';

// ════════════════════════════════════════════════════════════════════════════
// YAML PROMPT PAGE — 3-step AI goal planning flow
// ════════════════════════════════════════════════════════════════════════════

class YamlPromptPage extends ConsumerStatefulWidget {
  const YamlPromptPage({super.key});

  @override
  ConsumerState<YamlPromptPage> createState() => _YamlPromptPageState();
}

class _YamlPromptPageState extends ConsumerState<YamlPromptPage> {
  int _step = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Goal Planner', style: AppTypography.pageTitle),
                  const SizedBox(height: 4),
                  Text(
                    'Plan your goals with AI before importing.',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),

            // Step indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: _StepIndicator(current: _step, total: 3),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Content
            Expanded(
              child: [
                _Step1Discuss(onNext: () => setState(() => _step = 1)),
                _Step2Prompt(onNext: () => setState(() => _step = 2)),
                _Step3Done(onBack: () => setState(() => _step = 0)),
              ][_step],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step indicator ────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final isDone   = i < current;
        final isActive = i == current;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 2,
                  color: isDone || isActive ? AppColors.accentBlue : AppColors.border,
                ),
              ),
              if (i < total - 1) const SizedBox(width: 4),
            ],
          ),
        );
      }),
    );
  }
}

// ── Step 1: Discuss your goals ────────────────────────────────────────────

class _Step1Discuss extends StatelessWidget {
  final VoidCallback onNext;
  const _Step1Discuss({required this.onNext});

  static const _items = [
    (icon: Icons.flag_rounded,        title: 'Define your goal',       body: 'What exactly do you want to achieve? Be specific.'),
    (icon: Icons.calendar_today,      title: 'Set a realistic deadline', body: 'When do you need this done? Factor in your capacity.'),
    (icon: Icons.link_rounded,        title: 'Identify dependencies',   body: 'Which goals must be completed before this one?'),
    (icon: Icons.checklist_rounded,   title: 'Break it into tasks',     body: 'What daily or weekly actions will move you forward?'),
    (icon: Icons.bar_chart_rounded,   title: 'Assign priority weight',  body: 'How important is this goal relative to others? (1–10)'),
    (icon: Icons.lightbulb_outline,   title: 'Clarify your aim',        body: 'Why does this goal matter to you? What drives it?'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            children: [
              Text('STEP 1 — DISCUSS', style: AppTypography.sectionHeader),
              const SizedBox(height: 12),
              Text(
                'Before pasting a prompt, think through these questions or discuss them with an AI chatbot. The more clearly you define your goals, the better the YAML output.',
                style: AppTypography.body.copyWith(color: AppColors.textSecondary, height: 1.6),
              ),
              const SizedBox(height: 20),
              ..._items.map((item) => _CheckCard(
                icon: item.icon,
                title: item.title,
                body: item.body,
              )),
              const SizedBox(height: 20),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text('Next: Generate Prompt'),
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String body;
  const _CheckCard({required this.icon, required this.title, required this.body});

  @override
  State<_CheckCard> createState() => _CheckCardState();
}

class _CheckCardState extends State<_CheckCard> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _checked = !_checked),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: _checked ? AppColors.accentBlueDim.withValues(alpha: 0.4) : AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(
            color: _checked ? AppColors.accentBlue.withValues(alpha: 0.5) : AppColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              widget.icon,
              size: 18,
              color: _checked ? AppColors.accentBlue : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: AppTypography.cardTitle.copyWith(
                      color: _checked ? AppColors.accentBlue : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(widget.body, style: AppTypography.caption),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _checked ? AppColors.accentBlue : Colors.transparent,
                border: Border.all(
                  color: _checked ? AppColors.accentBlue : AppColors.textSecondary,
                  width: 1.5,
                ),
              ),
              child: _checked
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 2: Copy the prompt ────────────────────────────────────────────────

class _Step2Prompt extends StatelessWidget {
  final VoidCallback onNext;
  const _Step2Prompt({required this.onNext});

  static const _prompt = '''You are a goal planning assistant. Help me create a structured YAML goal file for the Nexus goal tracker app.

Based on our discussion, produce a valid YAML document that follows this schema exactly:

version: "1.0"
goals:
  - id: goal_identifier         # lowercase, no spaces
    name: "Goal Name"
    aim: "Why this goal matters"
    timeframe: month             # day | week | month | year
    deadline: "2025-12-31"      # YYYY-MM-DD
    weight: 5                   # 1-10
    parent: null                # or another goal id
    depends_on: []              # list of goal ids this depends on
    tasks:
      - name: "Task description"
        schedule: daily          # daily | weekly | monthly
        on: null                 # for weekly: day name, for monthly: 1-28
        reminder: "08:00"        # HH:MM 24-hour
        active: true

Rules:
- All goal ids must be lowercase with underscores only
- Deadlines must be in the future
- Weight must be 1-10
- Weekly tasks need an "on" field with the day name (monday, tuesday, etc.)
- Monthly tasks need an "on" field with a number 1-28
- Dependency ids must refer to goals in the same file

Now, based on our conversation, generate the YAML file for my goals. Ask me clarifying questions if needed before generating.''';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            children: [
              Text('STEP 2 — COPY PROMPT', style: AppTypography.sectionHeader),
              const SizedBox(height: 12),
              Text(
                'Copy the prompt below and paste it into ChatGPT, Claude, or Gemini. Have a conversation about your goals, then ask it to generate the YAML.',
                style: AppTypography.body.copyWith(color: AppColors.textSecondary, height: 1.6),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: AppRadius.card,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('AI PROMPT', style: AppTypography.sectionHeader),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(const ClipboardData(text: _prompt));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Prompt copied to clipboard')),
                            );
                          },
                          child: Row(
                            children: [
                              const Icon(Icons.copy, size: 14, color: AppColors.accentBlue),
                              const SizedBox(width: 4),
                              Text(
                                'Copy',
                                style: AppTypography.caption.copyWith(color: AppColors.accentBlue),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(_prompt, style: AppTypography.code.copyWith(fontSize: 11, height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.accentBlueDim.withValues(alpha: 0.2),
                  borderRadius: AppRadius.card,
                  border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tips_and_updates_outlined, size: 14, color: AppColors.accentBlue),
                        const SizedBox(width: 6),
                        Text('How it works', style: AppTypography.cardTitle.copyWith(color: AppColors.accentBlue, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Copy and paste the prompt into an AI chat\n2. Describe your goals in the conversation\n3. The AI will generate YAML — copy that output\n4. Come back and paste it on the Import page',
                      style: AppTypography.caption.copyWith(height: 1.7),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text('Next: Import YAML'),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Step 3: Done / go to import ────────────────────────────────────────────

class _Step3Done extends ConsumerWidget {
  final VoidCallback onBack;
  const _Step3Done({required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.accentBlueDim.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.5)),
            ),
            child: const Icon(Icons.upload_file_rounded, color: AppColors.accentBlue, size: 32),
          ),
          const SizedBox(height: 24),
          Text(
            'Ready to Import',
            style: AppTypography.pageTitle.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 12),
          Text(
            'You have your YAML from the AI. Go to the Import page to paste it and verify your goals.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ref.read(pageIndexProvider.notifier).state = 6;
              },
              child: const Text('Go to Import Page'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onBack,
              child: const Text('Start Over'),
            ),
          ),
        ],
      ),
    );
  }
}
