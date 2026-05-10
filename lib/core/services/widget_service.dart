import 'dart:io';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';
import '../database/app_database.dart';

class WidgetService {
  static const String _androidWidgetName = 'NexusWidget';
  static const String _imageKey = 'nexus_widget_image';

  /// Renders the today's tasks widget to an image and updates the home screen.
  static Future<void> updateHomeWidget(List<TaskCompletion> todayCompletions, Map<String, Task> taskMap) async {
    try {
      final activeTasks = todayCompletions
          .where((c) => c.completedDate == null)
          .map((c) => taskMap[c.taskId])
          .whereType<Task>()
          .toList();

      // Render the widget to an image
      // We use a fixed size for the widget image (e.g. 512x512)
      final path = await HomeWidget.renderFlutterWidget(
        NexusWidgetUI(tasks: activeTasks),
        key: _imageKey,
        logicalSize: const Size(400, 400),
        pixelRatio: 2.0,
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
          width: 400,
          height: 400,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFF222222), width: 1),
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'NEXUS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                tasks.isEmpty ? 'ALL TASKS COMPLETED' : 'TODAY\'S FOCUS',
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: tasks.isEmpty
                    ? const Center(
                        child: Icon(Icons.done_all, color: Color(0xFF222222), size: 64),
                      )
                    : ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: tasks.length > 5 ? 5 : tasks.length,
                        separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          return Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF444444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  tasks[i].name.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
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
              if (tasks.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '+ ${tasks.length - 5} MORE',
                    style: const TextStyle(
                      color: Color(0xFF444444),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
