import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../models/models.dart';
import '../database/app_database.dart';

class WidgetService {
  static const String _androidWidgetName = 'NexusWidget';
  static const String _imageKey = 'nexus_widget_image';

  /// Renders the today's tasks widget to an image and updates the home screen.
  static Future<void> updateHomeWidget(List<TaskCompletion> todayCompletions, List<Task> allTasks) async {
    try {
      final taskMap = {for (final t in allTasks) t.id: t};
      final activeTasks = todayCompletions
          .where((c) => c.completedDate == null)
          .map((c) => taskMap[c.taskId])
          .whereType<Task>()
          .toList();

      // Render with higher resolution for better size flexibility on high-DPI screens
      // 512 logical pixels at 3.0 pixel ratio = 1536 physical pixels
      final path = await HomeWidget.renderFlutterWidget(
        NexusWidgetUI(tasks: activeTasks),
        key: _imageKey,
        logicalSize: const Size(512, 512),
        pixelRatio: 3.0,
      );

      if (path != null) {
        await HomeWidget.saveWidgetData<String>(_imageKey, path);
        await HomeWidget.updateWidget(
          name: _androidWidgetName,
          androidName: _androidWidgetName,
        );
      }
    } catch (e) {
      debugPrint('Widget update failed: $e');
    }
  }
}

class NexusWidgetUI extends StatelessWidget {
  final List<Task> tasks;

  const NexusWidgetUI({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: 512,
          height: 512,
          color: Colors.black,
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Text(
                    'NEXUS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              
              // Status Label
              Text(
                tasks.isEmpty ? 'STATUS: CLEAR' : 'TODAY\'S OBJECTIVES',
                style: const TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 24),
              
              // Tasks List
              Expanded(
                child: tasks.isEmpty
                    ? const Center(
                        child: Opacity(
                          opacity: 0.1,
                          child: Icon(Icons.check_circle_outline, color: Colors.white, size: 120),
                        ),
                      )
                    : ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: tasks.length > 8 ? 8 : tasks.length,
                        separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                        itemBuilder: (ctx, i) {
                          return Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF333333),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  tasks[i].name.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0.5,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
              
              // Footer / Overflow
              if (tasks.length > 8)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    '+ ${tasks.length - 8} ADDITIONAL TASKS',
                    style: const TextStyle(
                      color: Color(0xFF444444),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                
              const SizedBox(height: 12),
              // Bottom divider for formal look
              Container(
                height: 1,
                width: 60,
                color: const Color(0xFF222222),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
