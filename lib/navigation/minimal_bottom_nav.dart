import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../core/providers/providers.dart';

class MinimalBottomNav extends ConsumerStatefulWidget {
  const MinimalBottomNav({super.key});

  @override
  ConsumerState<MinimalBottomNav> createState() => _MinimalBottomNavState();
}

class _MinimalBottomNavState extends ConsumerState<MinimalBottomNav> {
  // Professional, minimal icons
  final List<IconData> _icons = [
    Icons.home_filled,            // Home
    Icons.account_tree_outlined,  // Graph
    Icons.format_list_bulleted,   // Tasks
    Icons.analytics_outlined,     // Progress
    Icons.person_outline,         // Profile
    Icons.auto_awesome_outlined,  // AI Prompt
    Icons.upload_file_outlined,   // YAML Import
  ];

  @override
  Widget build(BuildContext context) {
    final curIndex = ref.watch(pageIndexProvider);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.95), // Pitch black, slightly translucent
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_icons.length, (index) {
            final isActive = curIndex == index;
            
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(pageIndexProvider.notifier).state = index;
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedTheme(
                      data: ThemeData(
                        iconTheme: IconThemeData(
                          color: isActive ? Colors.white : const Color(0xFF555555),
                          size: isActive ? 24 : 22,
                        ),
                      ),
                      child: Icon(_icons[index]),
                    ),
                    const SizedBox(height: 4),
                    // Minimal indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      height: 2,
                      width: isActive ? 16 : 0,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
