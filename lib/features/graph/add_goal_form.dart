import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/providers.dart';
import '../../shared/theme/app_theme.dart';

class AddGoalForm extends ConsumerStatefulWidget {
  const AddGoalForm({super.key});

  @override
  ConsumerState<AddGoalForm> createState() => _AddGoalFormState();
}

class _AddGoalFormState extends ConsumerState<AddGoalForm> {
  final _nameCtrl = TextEditingController();
  final _aimCtrl  = TextEditingController();
  final _formKey  = GlobalKey<FormState>();

  String _timeframe = 'month';
  DateTime _deadline = DateTime.now().add(const Duration(days: 30));
  int _weight = 1;
  String? _parentId;
  List<String> _dependsOn = [];
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _aimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allGoals = ref.watch(allGoalsProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.sheet,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: AppRadius.chip,
                ),
              ),
              const SizedBox(height: 16),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Row(
                  children: [
                    Text('New Goal', style: AppTypography.pageTitle.copyWith(fontSize: 18)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Cancel', style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Divider(color: AppColors.border, height: 1),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  children: [
                    // Name
                    _Label('Goal Name'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameCtrl,
                      autofocus: true,
                      style: AppTypography.body,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Run a marathon',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Aim
                    _Label('Goal Aim (optional)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _aimCtrl,
                      style: AppTypography.body,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Why do you want to achieve this?',
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Timeframe
                    _Label('Timeframe'),
                    const SizedBox(height: 8),
                    _SegmentedPicker<String>(
                      options: const ['day', 'week', 'month', 'year'],
                      labels: const ['Day', 'Week', 'Month', 'Year'],
                      value: _timeframe,
                      onChanged: (v) => setState(() => _timeframe = v),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Deadline
                    _Label('Deadline'),
                    const SizedBox(height: 6),
                    _DatePicker(
                      value: _deadline,
                      onChanged: (d) => setState(() => _deadline = d),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Weight
                    _Label('Priority Weight  $_weight / 10'),
                    const SizedBox(height: 4),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppColors.accentBlue,
                        inactiveTrackColor: AppColors.border,
                        thumbColor: AppColors.accentBlue,
                        overlayColor: AppColors.accentBlue.withValues(alpha: 0.12),
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                      ),
                      child: Slider(
                        min: 1,
                        max: 10,
                        divisions: 9,
                        value: _weight.toDouble(),
                        onChanged: (v) => setState(() => _weight = v.round()),
                      ),
                    ),

                    // Parent goal
                    allGoals.when(
                      data: (goals) {
                        if (goals.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppSpacing.xl),
                            _Label('Parent Goal (optional)'),
                            const SizedBox(height: 6),
                            _GoalDropdown(
                              goals: goals,
                              value: _parentId,
                              hintText: 'None — top-level goal',
                              onChanged: (v) => setState(() => _parentId = v),
                            ),

                            const SizedBox(height: AppSpacing.xl),
                            _Label('Depends On (optional)'),
                            const SizedBox(height: 6),
                            _GoalMultiSelect(
                              goals: goals.where((g) => g.id != _parentId).toList(),
                              selected: _dependsOn,
                              onChanged: (v) => setState(() => _dependsOn = v),
                            ),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 32),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _submit,
                        child: _saving
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Create Goal'),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final id = const Uuid().v4().replaceAll('-', '_').substring(0, 12);

    await ref.read(goalNotifierProvider.notifier).createGoal(
      id: id,
      parentId: _parentId,
      name: _nameCtrl.text.trim(),
      aim: _aimCtrl.text.trim().isEmpty ? null : _aimCtrl.text.trim(),
      timeframe: _timeframe,
      deadline: _deadline,
      weight: _weight,
      dependsOn: _dependsOn,
    );

    if (mounted) Navigator.pop(context);
  }
}

// ── Shared form helpers ────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: AppTypography.sectionHeader,
      );
}

class _SegmentedPicker<T> extends StatelessWidget {
  final List<T> options;
  final List<String> labels;
  final T value;
  final ValueChanged<T> onChanged;

  const _SegmentedPicker({
    required this.options,
    required this.labels,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(options.length, (i) {
        final selected = options[i] == value;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(options[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(right: i < options.length - 1 ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.accentBlue : AppColors.surfaceAlt,
                borderRadius: AppRadius.button,
                border: Border.all(
                  color: selected ? AppColors.accentBlue : AppColors.border,
                ),
              ),
              child: Text(
                labels[i],
                style: AppTypography.badge.copyWith(
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _DatePicker extends StatelessWidget {
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  const _DatePicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 3650)),
          builder: (ctx, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.accentBlue,
                surface: AppColors.surface,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: AppRadius.input,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Text(
              DateFormat('d MMM yyyy').format(value),
              style: AppTypography.body,
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalDropdown extends StatelessWidget {
  final List<Goal> goals;
  final String? value;
  final String hintText;
  final ValueChanged<String?> onChanged;

  const _GoalDropdown({
    required this.goals,
    required this.value,
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.input,
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButton<String?>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: AppColors.surface,
        style: AppTypography.body,
        hint: Text(hintText, style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
        items: [
          DropdownMenuItem<String?>(
            value: null,
            child: Text(hintText, style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
          ),
          ...goals.map((g) => DropdownMenuItem<String?>(
                value: g.id,
                child: Text(g.name, style: AppTypography.body, overflow: TextOverflow.ellipsis),
              )),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _GoalMultiSelect extends StatelessWidget {
  final List<Goal> goals;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const _GoalMultiSelect({
    required this.goals,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return Text('No other goals to select.', style: AppTypography.caption);
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: goals.map((g) {
        final isSelected = selected.contains(g.id);
        return GestureDetector(
          onTap: () {
            final updated = List<String>.from(selected);
            if (isSelected) {
              updated.remove(g.id);
            } else {
              updated.add(g.id);
            }
            onChanged(updated);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accentBlueDim : AppColors.surfaceAlt,
              borderRadius: AppRadius.chip,
              border: Border.all(
                color: isSelected ? AppColors.accentBlue : AppColors.border,
              ),
            ),
            child: Text(
              g.name,
              style: AppTypography.caption.copyWith(
                color: isSelected ? AppColors.accentBlue : AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }).toList(),
    );
  }
}
