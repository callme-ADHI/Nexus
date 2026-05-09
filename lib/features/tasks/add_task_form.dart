import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../core/database/app_database.dart';
import '../../shared/theme/app_theme.dart';


class AddTaskForm extends ConsumerStatefulWidget {
  const AddTaskForm({super.key});

  @override
  ConsumerState<AddTaskForm> createState() => _AddTaskFormState();
}

class _AddTaskFormState extends ConsumerState<AddTaskForm> {
  final _nameCtrl = TextEditingController();
  final _formKey  = GlobalKey<FormState>();

  String? _selectedGoalId;
  String  _schedule  = 'daily';
  String? _scheduleOn;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  bool   _isActive = true;
  bool   _saving   = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allGoals = ref.watch(allGoalsProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.80,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Row(
                  children: [
                    Text('New Task', style: AppTypography.pageTitle.copyWith(fontSize: 18)),
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
                    // Goal picker (required)
                    _Label('Goal'),
                    const SizedBox(height: 6),
                    allGoals.when(
                      data: (goals) {
                        if (goals.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: AppRadius.card,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              'Create a goal first before adding tasks.',
                              style: AppTypography.caption,
                            ),
                          );
                        }
                        return _GoalPickerDropdown(
                          goals: goals,
                          value: _selectedGoalId,
                          onChanged: (v) => setState(() => _selectedGoalId = v),
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Task name
                    _Label('Task Name'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameCtrl,
                      style: AppTypography.body,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Morning run — 5km',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Task name is required' : null,
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Schedule
                    _Label('Schedule'),
                    const SizedBox(height: 8),
                    _SegmentedPicker<String>(
                      options: const ['daily', 'weekly', 'monthly'],
                      labels:  const ['Daily',  'Weekly',  'Monthly'],
                      value: _schedule,
                      onChanged: (v) => setState(() {
                        _schedule = v;
                        _scheduleOn = null;
                      }),
                    ),

                    if (_schedule == 'weekly') ...[
                      const SizedBox(height: AppSpacing.lg),
                      _Label('Day of Week'),
                      const SizedBox(height: 8),
                      _SegmentedPicker<String>(
                        options: const ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
                        labels:  const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                        value: _scheduleOn ?? 'monday',
                        onChanged: (v) => setState(() => _scheduleOn = v),
                      ),
                    ],

                    if (_schedule == 'monthly') ...[
                      const SizedBox(height: AppSpacing.lg),
                      _Label('Day of Month (1–28)'),
                      const SizedBox(height: 6),
                      TextFormField(
                        keyboardType: TextInputType.number,
                        style: AppTypography.body,
                        decoration: const InputDecoration(hintText: 'e.g. 1'),
                        validator: (v) {
                          if (_schedule != 'monthly') return null;
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 1 || n > 28) return 'Enter 1–28';
                          return null;
                        },
                        onChanged: (v) => _scheduleOn = v.trim(),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl),

                    // Reminder time
                    _Label('Reminder Time'),
                    const SizedBox(height: 6),
                    _TimePicker(
                      value: _reminderTime,
                      onChanged: (t) => setState(() => _reminderTime = t),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Active toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: AppRadius.card,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Active', style: AppTypography.cardTitle),
                                const SizedBox(height: 2),
                                Text('Schedule task immediately', style: AppTypography.caption),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isActive,
                            onChanged: (v) => setState(() => _isActive = v),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_saving || _selectedGoalId == null) ? null : _submit,
                        child: _saving
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Create Task'),
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
    if (_selectedGoalId == null) return;

    setState(() => _saving = true);

    final reminderStr =
        '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}';

    await ref.read(taskNotifierProvider.notifier).createTask(
      goalId: _selectedGoalId!,
      name: _nameCtrl.text.trim(),
      schedule: _schedule,
      scheduleOn: _scheduleOn,
      reminderTime: reminderStr,
      isActive: _isActive,
    );

    if (mounted) Navigator.pop(context);
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: AppTypography.sectionHeader,
      );
}

class _GoalPickerDropdown extends StatelessWidget {
  final List<Goal> goals;
  final String? value;
  final ValueChanged<String?> onChanged;
  const _GoalPickerDropdown({required this.goals, required this.value, required this.onChanged});

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
        hint: Text('Select a goal', style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
        items: goals.map((g) => DropdownMenuItem<String?>(
              value: g.id,
              child: Text(g.name, style: AppTypography.body, overflow: TextOverflow.ellipsis),
            )).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChanged;
  const _TimePicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final label =
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: value,
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
            const Icon(Icons.access_time_rounded, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Text(label, style: AppTypography.body),
          ],
        ),
      ),
    );
  }
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
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(options.length, (i) {
        final selected = options[i] == value;
        return GestureDetector(
          onTap: () => onChanged(options[i]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.accentBlue : AppColors.surfaceAlt,
              borderRadius: AppRadius.chip,
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
        );
      }),
    );
  }
}
