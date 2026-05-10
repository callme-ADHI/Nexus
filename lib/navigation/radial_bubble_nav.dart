import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/providers.dart';

class RadialNavOverlay extends ConsumerStatefulWidget {
  const RadialNavOverlay({super.key});

  @override
  ConsumerState<RadialNavOverlay> createState() => _RadialNavOverlayState();
}

class _RadialNavOverlayState extends ConsumerState<RadialNavOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _expandAnim;

  bool _active = false;
  Offset _centerPos = Offset.zero;
  int _selectedIndex = -1;
  
  // To track the initial touch and ensure it's a hold
  Offset? _initialTouchPos;
  bool _timerActive = false;

  final List<_NavTarget> _targets = [
    _NavTarget(icon: Icons.home_outlined, label: 'DASHBOARD'),
    _NavTarget(icon: Icons.auto_graph_outlined, label: 'ANALYTICS'),
    _NavTarget(icon: Icons.checklist_outlined, label: 'TASKS'),
    _NavTarget(icon: Icons.speed_outlined, label: 'PROGRESS'),
    _NavTarget(icon: Icons.person_outline, label: 'PROFILE'),
    _NavTarget(icon: Icons.monitor_heart_outlined, label: 'ACTIVITY'),
    _NavTarget(icon: Icons.file_upload_outlined, label: 'IMPORT'),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnim = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _startTimer(Offset pos) {
    _initialTouchPos = pos;
    _timerActive = true;
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_timerActive && _initialTouchPos != null && !_active) {
        // Threshold met: Activate Nav
        final size = MediaQuery.of(context).size;
        setState(() {
          _active = true;
          _centerPos = Offset(size.width / 2, size.height - 40);
          _selectedIndex = -1;
        });
        _ctrl.forward();
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _cancelTimer() {
    _timerActive = false;
    _initialTouchPos = null;
  }

  void _handleGlobalPointerDown(PointerDownEvent event) {
    final size = MediaQuery.of(context).size;
    // Only start timer if in the bottom trigger zone
    if (event.position.dy > size.height - 80) {
      _startTimer(event.position);
    }
  }

  void _handleGlobalPointerMove(PointerMoveEvent event) {
    if (!_active) {
      // If moving too much during the initial hold, cancel it
      if (_initialTouchPos != null) {
        if ((event.position - _initialTouchPos!).distance > 20) {
          _cancelTimer();
        }
      }
      return;
    }

    // Nav is active: Track selection
    final delta = event.position - _centerPos;
    final dist = delta.distance;
    
    if (dist < 50) {
      if (_selectedIndex != -1) setState(() => _selectedIndex = -1);
      return;
    }

    double angle = math.atan2(delta.dy, delta.dx) * 180 / math.pi;
    angle = (angle + 360) % 360;

    const arcWidth = 160.0;
    const startAngle = 270.0 - (arcWidth / 2);
    const endAngle = 270.0 + (arcWidth / 2);

    int newIndex = -1;
    if (angle >= startAngle && angle <= endAngle) {
      final relativePos = (angle - startAngle) / arcWidth;
      newIndex = (relativePos * _targets.length).floor();
      newIndex = newIndex.clamp(0, _targets.length - 1);
    }

    if (newIndex != _selectedIndex) {
      setState(() => _selectedIndex = newIndex);
      HapticFeedback.selectionClick();
    }
  }

  void _handleGlobalPointerUp(PointerUpEvent event) {
    _cancelTimer();
    
    if (!_active) return;

    if (_selectedIndex != -1) {
      ref.read(pageIndexProvider.notifier).state = _selectedIndex;
    }

    _ctrl.reverse().then((_) {
      if (mounted) {
        setState(() {
          _active = false;
          _selectedIndex = -1;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      // The overlay is always there but only captures events when needed
      // behavior: HitTestBehavior.translucent allows underlying buttons to work
      child: Listener(
        onPointerDown: _handleGlobalPointerDown,
        onPointerMove: _handleGlobalPointerMove,
        onPointerUp: _handleGlobalPointerUp,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            if (_active) ...[
              // Dimmed backdrop
              FadeTransition(
                opacity: _ctrl,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.75),
                ),
              ),
              
              // Visual center hint
              Positioned(
                left: _centerPos.dx - 1,
                top: _centerPos.dy - 1,
                child: FadeTransition(
                  opacity: _ctrl,
                  child: Container(
                    width: 2,
                    height: 2,
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),

              // Nav Items Arc
              AnimatedBuilder(
                animation: _expandAnim,
                builder: (context, child) {
                  return Stack(
                    children: List.generate(_targets.length, (i) {
                      const arcRad = 160.0 * (math.pi / 180);
                      const startRad = (270.0 - 80.0) * (math.pi / 180);
                      final angle = startRad + (i + 0.5) * (arcRad / _targets.length);
                      
                      // Smooth spring-like expansion
                      final radius = 170.0 * _expandAnim.value;
                      final dx = radius * math.cos(angle);
                      final dy = radius * math.sin(angle);

                      final isSelected = _selectedIndex == i;
                      
                      return Positioned(
                        left: _centerPos.dx + dx - 25,
                        top: _centerPos.dy + dy - 25,
                        child: _NavItem(
                          target: _targets[i],
                          isSelected: isSelected,
                          expandValue: _expandAnim.value,
                        ),
                      );
                    }),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _NavTarget target;
  final bool isSelected;
  final double expandValue;

  const _NavItem({
    required this.target,
    required this.isSelected,
    required this.expandValue,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 200),
      scale: isSelected ? 1.25 : 1.0,
      curve: Curves.easeOutBack,
      child: Opacity(
        opacity: expandValue * (isSelected ? 1.0 : 0.6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              target.icon,
              color: Colors.white,
              size: 28,
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  target.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavTarget {
  final IconData icon;
  final String label;
  _NavTarget({required this.icon, required this.label});
}
