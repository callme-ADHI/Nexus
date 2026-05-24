import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/models/models.dart';
import '../../core/services/productivity_service.dart';
import '../../core/providers/providers.dart';
import 'productivity_providers.dart';
import 'package:drift/drift.dart' as drift;

class EditActivityDialog extends ConsumerStatefulWidget {
  final ActivityLog activity;
  const EditActivityDialog({super.key, required this.activity});

  @override
  ConsumerState<EditActivityDialog> createState() => _EditActivityDialogState();
}

class _EditActivityDialogState extends ConsumerState<EditActivityDialog> {
  late TextEditingController _nameCtrl;
  late String _selectedCategory;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  final List<String> _cats = ['deep_work', 'exercise', 'learning', 'goal_tasks', 'social', 'routine', 'leisure', 'sleep'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.activity.name);
    _selectedCategory = widget.activity.category;
    final sDt = DateTime.fromMillisecondsSinceEpoch(widget.activity.startTime);
    final eDt = DateTime.fromMillisecondsSinceEpoch(widget.activity.endTime);
    _startTime = TimeOfDay(hour: sDt.hour, minute: sDt.minute);
    _endTime = TimeOfDay(hour: eDt.hour, minute: eDt.minute);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFF7C6AF7), surface: Color(0xFF111111))),
        child: child!,
      ),
    );
    if (picked != null) setState(() => isStart ? _startTime = picked : _endTime = picked);
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    
    final db = ref.read(databaseProvider);
    final baseDt = DateTime.fromMillisecondsSinceEpoch(widget.activity.date);
    final startMs = baseDt.add(Duration(hours: _startTime.hour, minutes: _startTime.minute)).millisecondsSinceEpoch;
    int endMs = baseDt.add(Duration(hours: _endTime.hour, minutes: _endTime.minute)).millisecondsSinceEpoch;
    if (endMs <= startMs) endMs += 86400000;

    // Check overlap with other activities
    final activities = await db.getActivitiesForDate(widget.activity.date);
    for (final a in activities) {
      if (a.id == widget.activity.id) continue;
      if (startMs < a.endTime && endMs > a.startTime) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot save: Overlaps with activity "${a.name}"'),
              backgroundColor: const Color(0xFFE74C3C),
            ),
          );
        }
        return;
      }
    }

    // Check overlap with sleep log
    final sleep = await db.getSleepForDate(widget.activity.date);
    if (sleep != null && _selectedCategory != 'sleep') {
      if (startMs < sleep.wakeTime && endMs > sleep.sleepTime) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot save: Overlaps with Sleep log'),
              backgroundColor: Color(0xFFE74C3C),
            ),
          );
        }
        return;
      }
    }

    await db.updateActivity(ActivityLogsCompanion(
      id: drift.Value(widget.activity.id),
      name: drift.Value(_nameCtrl.text.trim()),
      category: drift.Value(_selectedCategory),
      startTime: drift.Value(startMs),
      endTime: drift.Value(endMs),
    ));
    await db.invalidateCache(widget.activity.date);
    await ProductivityService.ensureScore(db, widget.activity.date);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0A0A0A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF1E1E1E))),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('EDIT ACTIVITY', style: TextStyle(color: Color(0xFF3A3A50), fontSize: 11, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Activity name',
                hintStyle: TextStyle(color: Color(0xFF3A3A50)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1E1E1E))),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF7C6AF7))),
              ),
            ),
            const SizedBox(height: 24),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _cats.map((c) {
                  final cat = ActivityCategory.fromKey(c);
                  final isSel = _selectedCategory == c;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = c),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSel ? cat.color.withOpacity(0.2) : Colors.transparent,
                        border: Border.all(color: isSel ? cat.color : const Color(0xFF1E1E1E)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(cat.label, style: TextStyle(color: isSel ? cat.color : const Color(0xFF666680), fontSize: 12)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _pickTime(true),
                  child: Text('${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.white, fontSize: 16)),
                ),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('→', style: TextStyle(color: Color(0xFF3A3A50)))),
                GestureDetector(
                  onTap: () => _pickTime(false),
                  child: Text('${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Color(0xFF666680)))),
                const SizedBox(width: 8),
                TextButton(onPressed: _save, child: const Text('Save', style: TextStyle(color: Color(0xFF7C6AF7)))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
