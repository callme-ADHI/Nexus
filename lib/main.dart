import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/providers.dart';
import 'core/services/notification_service.dart';
import 'core/services/scheduling_service.dart';
import 'features/home/home_page.dart';
import 'features/graph/graph_page.dart';
import 'features/tasks/tasks_page.dart';
import 'features/progress/progress_page.dart';
import 'features/profile/profile_page.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/productivity/productivity_page.dart';
import 'features/yaml_import/yaml_import_page.dart';
import 'navigation/radial_bubble_nav.dart';
import 'core/services/widget_service.dart';

import 'shared/theme/app_theme.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const ProviderScope(child: NexusApp()));
}

class NexusApp extends ConsumerWidget {
  const NexusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Nexus',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: SplashScreen(nextPage: const _AppBootstrap()),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// BOOTSTRAP
// ════════════════════════════════════════════════════════════════════════════

class _AppBootstrap extends ConsumerStatefulWidget {
  const _AppBootstrap();

  @override
  ConsumerState<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<_AppBootstrap>
    with WidgetsBindingObserver {
  bool _initialized = false;
  bool _onboardingDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _onResume();
  }

  Future<void> _initialize() async {
    try {
      final db = ref.read(databaseProvider);
      await db.ensureProfile();

      final profile = await db.getProfile();
      final done = profile?.onboardingDone == 1;

      if (mounted) {
        setState(() {
          _onboardingDone = done;
          _initialized = true;
        });
      }

      Future.microtask(() async {
        try {
          final sched = SchedulingService(db);
          await sched.generateCompletionWindow();
          if (mounted) {
            ref.invalidate(todayCompletionsProvider);
            ref.invalidate(missedCompletionsProvider);
            ref.invalidate(goalGraphProvider);
          }
        } catch (_) {}

        try {
          await NotificationService.initialize();
          await NotificationService.requestPermissions();
          await NotificationService.rescheduleAll(db);
        } catch (_) {}
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _onboardingDone = false;
          _initialized = true;
        });
      }
    }
  }

  Future<void> _onResume() async {
    final db = ref.read(databaseProvider);
    final sched = SchedulingService(db);
    await sched.generateCompletionWindow();
    await NotificationService.rescheduleAll(db);
    ref.invalidate(todayCompletionsProvider);
    ref.invalidate(missedCompletionsProvider);
    ref.invalidate(goalGraphProvider);
  }

  @override
  Widget build(BuildContext context) {
    // Sync Home Widget whenever today's tasks change
    ref.listen(widgetUpdateProvider, (prev, next) {
      if (next != null) {
        final (completions, tasks) = next;
        WidgetService.updateHomeWidget(completions, tasks);
      }
    });

    if (!_initialized) {

      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (!_onboardingDone) {
      return OnboardingPage(
        onComplete: () => setState(() => _onboardingDone = true),
      );
    }

    return const _MainShell();
  }
}

// ════════════════════════════════════════════════════════════════════════════
// MAIN SHELL — IndexedStack + RadialNavOverlay
// ════════════════════════════════════════════════════════════════════════════

class _MainShell extends ConsumerWidget {
  const _MainShell();

  static final List<Widget> _pages = [
    const HomePage(),
    const GraphPage(),
    const TasksPage(),
    const ProgressPage(),
    const ProfilePage(),
    const ProductivityPage(),
    const YamlImportPage(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageIndex = ref.watch(pageIndexProvider);

    return PopScope(
      canPop: pageIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (pageIndex != 0) {
          ref.read(pageIndexProvider.notifier).state = 0;
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            IndexedStack(
              index: pageIndex,
              children: _pages,
            ),
            const RadialNavOverlay(),
          ],
        ),
      ),
    );
  }
}
