import 'dart:math' as math;
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../core/providers/providers.dart';
import '../shared/theme/app_theme.dart';

// ═══════════════════════════════════════════════════════
// CONFIG
// ═══════════════════════════════════════════════════════
const _kHoldMs    = 180;
const _kBubbleR   = 26.0; // radius
const _kArcR      = 130.0;
const _kIconCount = 7;
const _kArcSpan   = 150.0; // degrees

const _kNavIcons = <IconData>[
  Icons.home_rounded,
  Icons.hub_rounded,
  Icons.checklist_rounded,
  Icons.donut_large_rounded,
  Icons.person_rounded,
  Icons.auto_awesome_rounded,
  Icons.upload_file_rounded,
];

// ═══════════════════════════════════════════════════════
// OVERLAY
// ═══════════════════════════════════════════════════════
class RadialNavOverlay extends ConsumerStatefulWidget {
  const RadialNavOverlay({super.key});
  @override
  ConsumerState<RadialNavOverlay> createState() => _State();
}

class _State extends ConsumerState<RadialNavOverlay>
    with TickerProviderStateMixin {

  // position
  bool   _onRight = true;
  double _yFrac   = 0.72;

  // menu state
  bool _open = false;
  int? _hovered;

  // drag state for repositioning
  bool _isDraggingBubble = false;
  Offset? _pointerDownPos;

  // animations
  late final AnimationController _holdCtrl;
  late final AnimationController _menuCtrl;
  late final List<Animation<double>> _scaleAnims;
  late final List<Animation<double>> _opacityAnims;

  // idle pulse
  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulse;

  bool get _hapticsOn =>
      ref.read(profileProvider).value?.hapticsEnabled == 1;

  @override
  void initState() {
    super.initState();

    _holdCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _kHoldMs),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _openMenu();
        }
      });

    _menuCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _scaleAnims = List.generate(_kIconCount, (i) {
      final t0 = i * 0.07;
      final t1 = (t0 + 0.55).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _menuCtrl,
          curve: Interval(t0, t1, curve: Curves.easeOutBack),
        ),
      );
    });

    _opacityAnims = List.generate(_kIconCount, (i) {
      final t0 = i * 0.06;
      final t1 = (t0 + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _menuCtrl,
          curve: Interval(t0, t1, curve: Curves.easeOut),
        ),
      );
    });

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOutSine),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPos());
  }

  @override
  void dispose() {
    _holdCtrl.dispose();
    _menuCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Position ────────────────────────────────────────
  Future<void> _loadPos() async {
    try {
      final p = await ref.read(databaseProvider).getProfile();
      if (p != null && mounted) {
        setState(() {
          _onRight = p.bubbleSide == 'right';
          _yFrac   = p.bubbleYFrac.clamp(0.1, 0.9);
        });
      }
    } catch (_) {}
  }

  Future<void> _savePos() async {
    try {
      await ref.read(databaseProvider).updateProfile(UserProfilesCompanion(
        bubbleSide:  Value(_onRight ? 'right' : 'left'),
        bubbleYFrac: Value(_yFrac),
      ));
    } catch (_) {}
  }

  // ── Geometry ─────────────────────────────────────────
  Offset _bubbleCenter(Size sz) {
    final x = _onRight ? sz.width - _kBubbleR - 14 : _kBubbleR + 14;
    final y = (_yFrac * sz.height).clamp(_kBubbleR + 16.0, sz.height - _kBubbleR - 16.0);
    return Offset(x, y);
  }

  Offset _iconPos(int i, Offset bc, Size sz) {
    final step     = (_kArcSpan * math.pi / 180) / (_kIconCount - 1);
    final halfArc  = (_kArcSpan * math.pi / 180) / 2;
    final center   = _onRight ? math.pi : 0.0;
    final angle    = center - halfArc + i * step;
    var x = bc.dx + math.cos(angle) * _kArcR;
    var y = bc.dy + math.sin(angle) * _kArcR;
    x = x.clamp(34.0, sz.width  - 34.0);
    y = y.clamp(40.0, sz.height - 34.0);
    return Offset(x, y);
  }

  // ── Menu ─────────────────────────────────────────────
  void _openMenu() {
    if (_open) return;
    setState(() { _open = true; _hovered = null; });
    _pulseCtrl.stop();
    _menuCtrl.forward(from: 0);
    if (_hapticsOn) HapticFeedback.mediumImpact();
    if (_pointerDownPos != null) {
      _updateHover(_pointerDownPos!, MediaQuery.of(context).size);
    }
  }

  void _closeMenu({int? nav}) {
    if (!_open) return;
    final toNav = nav;
    setState(() { _open = false; _hovered = null; });
    _menuCtrl.animateTo(0,
        duration: const Duration(milliseconds: 160), curve: Curves.easeIn);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _pulseCtrl.repeat(reverse: true);
    });
    if (toNav != null) {
      Future.microtask(() {
        if (mounted) ref.read(pageIndexProvider.notifier).state = toNav;
      });
    }
  }

  void _updateHover(Offset pos, Size sz) {
    final bc = _bubbleCenter(sz);
    if ((pos - bc).distance < 50) {
      if (_hovered != null) setState(() => _hovered = null);
      return;
    }
    int? best;
    double bestD = 58.0;
    for (int i = 0; i < _kIconCount; i++) {
      final d = (pos - _iconPos(i, bc, sz)).distance;
      if (d < bestD) { bestD = d; best = i; }
    }
    if (best != _hovered) {
      setState(() => _hovered = best);
      if (best != null && _hapticsOn) HapticFeedback.selectionClick();
    }
  }

  // ── Gestures ─────────────────────────────────────────

  void _onPointerDown(PointerDownEvent e) {
    _pointerDownPos = e.position;
    _isDraggingBubble = false;
    _holdCtrl.forward(from: 0);
  }

  void _onPointerMove(PointerMoveEvent e) {
    _pointerDownPos = e.position;
    final sz = MediaQuery.of(context).size;

    if (_open) {
      // Menu is open, track hover
      _updateHover(e.position, sz);
    } else {
      // Menu is closed. If pointer moved significantly, cancel hold and start dragging
      if (_holdCtrl.isAnimating) {
        final d = e.delta.distance;
        if (d > 2.0) {
          _holdCtrl.reset();
          _isDraggingBubble = true;
          _pulseCtrl.stop();
        }
      }

      if (_isDraggingBubble) {
        setState(() {
          _yFrac = ((_yFrac * sz.height + e.delta.dy) / sz.height).clamp(0.08, 0.92);
          _onRight = e.position.dx > sz.width / 2;
        });
      }
    }
  }

  void _onPointerUp(PointerUpEvent e) {
    _holdCtrl.reset();
    if (_open) {
      _closeMenu(nav: _hovered);
    } else {
      if (_isDraggingBubble) {
        _isDraggingBubble = false;
        _savePos();
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted && !_open) _pulseCtrl.repeat(reverse: true);
        });
      } else {
        // Just a tap. We could toggle menu open/close here if we want.
        // For now, let's open the menu on tap as well, so it's not strictly hold-only.
        _openMenu();
      }
    }
    _pointerDownPos = null;
  }

  void _onPointerCancel(PointerCancelEvent e) {
    _holdCtrl.reset();
    if (_open) {
      _closeMenu();
    }
    _isDraggingBubble = false;
    _pointerDownPos = null;
  }

  // ── Build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final sz  = MediaQuery.of(context).size;
    final bc  = _bubbleCenter(sz);
    final cur = ref.watch(pageIndexProvider);

    return Stack(
      children: [
        // ── Open-menu layer (backdrop + icons) ──
        if (_open) ...[
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _menuCtrl,
              builder: (_, __) => Container(
                color: Colors.black.withValues(alpha: 0.50 * _menuCtrl.value),
              ),
            ),
          ),
          // We still keep a tap layer here so taps outside the menu close it
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeMenu,
            ),
          ),
          // Icons
          ...List.generate(_kIconCount, (i) => _buildIcon(i, bc, sz, cur)),
        ],

        // ── Bubble (Listener for hold/drag) ────────────────────────
        Positioned(
          left: bc.dx - _kBubbleR,
          top:  bc.dy - _kBubbleR,
          child: Listener(
            onPointerDown: _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: _onPointerUp,
            onPointerCancel: _onPointerCancel,
            behavior: HitTestBehavior.opaque,
            child: _Bubble(
              open: _open,
              pulseAnim: _pulse,
              menuAnim: _menuCtrl,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIcon(int i, Offset bc, Size sz, int cur) {
    final pos     = _iconPos(i, bc, sz);
    final active  = cur == i;
    final hovered = _hovered == i;

    return Positioned(
      left: pos.dx - 26,
      top:  pos.dy - 26,
      child: AnimatedBuilder(
        animation: _menuCtrl,
        builder: (_, __) => Opacity(
          opacity: _opacityAnims[i].value,
          child: Transform.scale(
            scale: _scaleAnims[i].value * (hovered ? 1.22 : 1.0),
            child: GestureDetector(
              onTap: () => _closeMenu(nav: i),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: active || hovered
                      ? AppColors.accentBlue.withValues(alpha: 0.16)
                      : Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active
                        ? AppColors.accentBlue
                        : hovered
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.white.withValues(alpha: 0.20),
                    width: active || hovered ? 1.5 : 1.0,
                  ),
                ),
                child: Icon(
                  _kNavIcons[i],
                  size: 22,
                  color: active
                      ? AppColors.accentBlue
                      : Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// BUBBLE — solid, no BackdropFilter (performance)
// ═══════════════════════════════════════════════════════
class _Bubble extends StatelessWidget {
  final bool open;
  final Animation<double> pulseAnim;
  final Animation<double> menuAnim;

  const _Bubble({
    required this.open,
    required this.pulseAnim,
    required this.menuAnim,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: open ? menuAnim : pulseAnim,
      builder: (_, __) {
        final scale       = open ? 1.0 : pulseAnim.value;
        final borderColor = open
            ? AppColors.accentBlue
            : const Color(0xFF2A2A2A);
        final bgColor     = open
            ? const Color(0xFF0E1929)
            : const Color(0xFF0D0D0D);

        return Transform.scale(
          scale: scale,
          child: Container(
            width:  _kBubbleR * 2,
            height: _kBubbleR * 2,
            decoration: BoxDecoration(
              color:  bgColor,
              shape:  BoxShape.circle,
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: open
                      ? AppColors.accentBlue.withValues(alpha: 0.30)
                      : Colors.white.withValues(alpha: 0.06),
                  blurRadius: 14,
                ),
              ],
            ),
            child: const Center(child: _Dots()),
          ),
        );
      },
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots();
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(14, 14), painter: _DotsPainter());
}

class _DotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;
    final cx = s.width / 2, cy = s.height / 2;
    canvas.drawCircle(Offset(cx, cy - 4.8), 2.0, p);
    canvas.drawCircle(Offset(cx - 4.5, cy + 2.4), 2.0, p);
    canvas.drawCircle(Offset(cx + 4.5, cy + 2.4), 2.0, p);
  }

  @override
  bool shouldRepaint(_DotsPainter _) => false;
}
