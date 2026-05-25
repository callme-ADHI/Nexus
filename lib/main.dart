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
import 'features/manage/manage_page.dart';
import 'navigation/radial_bubble_nav.dart';
import 'core/services/widget_service.dart';
import 'package:home_widget/home_widget.dart';

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
    
    HomeWidget.widgetClicked.listen((Uri? uri) {
      if (uri != null) _handleDeepLink(uri);
    });

    _initialize();
  }

  void _handleDeepLink(Uri uri) {
    if (!mounted) return;
    if (uri.host == 'tasks') {
      ref.read(pageIndexProvider.notifier).state = 2; // TasksPage
    } else if (uri.host == 'productivity') {
      ref.read(pageIndexProvider.notifier).state = 3; // ProductivityPage
    }
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
      final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (uri != null) {
        _handleDeepLink(uri);
      }

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

        _updateProductivityWidget();
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

  Future<void> _updateProductivityWidget() async {
    try {
      final db = ref.read(databaseProvider);
      final today = DateTime.now();
      final startDate = today.subtract(const Duration(days: 27)); // 28 days
      final rangeStart = DateTime(startDate.year, startDate.month, startDate.day).millisecondsSinceEpoch;
      final rangeEnd = DateTime(today.year, today.month, today.day).millisecondsSinceEpoch;
      final caches = await db.getCachedScoresInRange(rangeStart, rangeEnd);
      await WidgetService.updateProductivityWidget(caches);
    } catch (_) {}
  }

  Future<void> _onResume() async {
    final db = ref.read(databaseProvider);
    final sched = SchedulingService(db);
    await sched.generateCompletionWindow();
    await NotificationService.rescheduleAll(db);
    ref.invalidate(todayCompletionsProvider);
    ref.invalidate(missedCompletionsProvider);
    ref.invalidate(goalGraphProvider);
    _updateProductivityWidget();
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
    const ProductivityPage(),
    const ProgressPage(),
    const ManagePage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageIndex = ref.watch(pageIndexProvider);
    final navActive = ref.watch(navActiveProvider);
    final profileAsync = ref.watch(profileProvider);

    final showBottomNav = profileAsync.maybeWhen(
      data: (p) => p?.navStyle == 'bottom',
      orElse: () => false,
    );

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
            IgnorePointer(
              ignoring: !showBottomNav && navActive,
              child: IndexedStack(
                index: pageIndex,
                children: _pages,
              ),
            ),
            if (!showBottomNav) const RadialNavOverlay(),
          ],
        ),
        bottomNavigationBar: showBottomNav
            ? _PremiumBottomNavBar(
                pageIndex: pageIndex,
                onTap: (index) {
                  ref.read(pageIndexProvider.notifier).state = index;
                },
              )
            : null,
      ),
    );
  }
}

class _PremiumBottomNavBar extends StatelessWidget {
  final int pageIndex;
  final ValueChanged<int> onTap;

  const _PremiumBottomNavBar({
    required this.pageIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (icon: Icons.home_outlined, activeIcon: Icons.home, label: 'DASHBOARD', page: 0),
      (icon: Icons.query_stats_outlined, activeIcon: Icons.query_stats, label: 'VISION', page: 1),
      (icon: Icons.auto_graph_outlined, activeIcon: Icons.auto_graph, label: 'PRODUCTIVITY', page: 3),
      (icon: Icons.speed_outlined, activeIcon: Icons.speed, label: 'PROGRESS', page: 4),
      (icon: Icons.person_outline, activeIcon: Icons.person, label: 'PROFILE', page: 6),
    ];

    return Container(
      height: 64 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
        ),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: tabs.map((tab) {
          final isSelected = pageIndex == tab.page;
          return Expanded(
            child: InkWell(
              onTap: () => onTap(tab.page),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 150),
                    scale: isSelected ? 1.15 : 1.0,
                    child: Icon(
                      isSelected ? tab.activeIcon : tab.icon,
                      color: isSelected ? Colors.white : Colors.white54,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tab.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 8,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                      letterSpacing: 1.1,
                      color: isSelected ? Colors.white : Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
