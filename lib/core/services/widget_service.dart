import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../database/app_database.dart';
import '../../shared/widgets/nexus_logo.dart';

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

      final lastUpdated = DateFormat('HH:mm').format(DateTime.now());

      final path = await HomeWidget.renderFlutterWidget(
        NexusWidgetUI(tasks: activeTasks, lastUpdated: lastUpdated),
        key: _imageKey,
        logicalSize: const Size(600, 600),
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
  final String lastUpdated;

  const NexusWidgetUI({super.key, required this.tasks, required this.lastUpdated});

  @override
  Widget build(BuildContext context) {
    // We avoid Material/Scaffold/View here as they can cause 'View.of()' errors
    // during background/off-screen rendering.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(size: Size(600, 600), devicePixelRatio: 3.0),
        child: Container(
          width: 600,
          height: 600,
          color: Colors.black,
          padding: const EdgeInsets.all(48),
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Inter',
              fontSize: 16,
              decoration: TextDecoration.none,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const NexusLogo(size: 22, color: Colors.white),
                        const SizedBox(width: 16),
                        const Text(
                          'NEXUS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      lastUpdated,
                      style: const TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 56),
                
                // Section Title
                const Text(
                  'DAILY OBJECTIVES',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Task Items
                Expanded(
                  child: tasks.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('★', style: TextStyle(color: Color(0xFF111111), fontSize: 64)),
                              SizedBox(height: 16),
                              Text(
                                'ALL TASKS COMPLETED',
                                style: TextStyle(color: Color(0xFF222222), fontSize: 10, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: tasks.take(7).map((task) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      color: Colors.white24,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Text(
                                      task.name.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
                
                // Footer
                if (tasks.length > 7)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      '+ ${tasks.length - 7} MORE PENDING',
                      style: const TextStyle(
                        color: Color(0xFF444444),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  
                const SizedBox(height: 16),
                // Design Accent
                Container(
                  height: 2,
                  width: 40,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
