import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/nexus_logo.dart';

// ════════════════════════════════════════════════════════════════════════════
// PRODUCTIVITY PAGE — Ultra-Premium Hub
// ════════════════════════════════════════════════════════════════════════════



class ProductivityPage extends ConsumerStatefulWidget {
  const ProductivityPage({super.key});

  @override
  ConsumerState<ProductivityPage> createState() => _ProductivityPageState();
}

class _ProductivityPageState extends ConsumerState<ProductivityPage> {
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Premium Branding & Stats Peek ───────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeIn(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PRODUCTIVITY', style: AppTypography.sectionHeader.copyWith(letterSpacing: 10, fontSize: 10, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 12),
                        Text('ENGINE STATUS: OPTIMIZED', style: AppTypography.caption.copyWith(fontSize: 8, letterSpacing: 1, color: Colors.white24)),
                      ],
                    ),
                  ),
                  const NexusLogo(size: 18, color: Colors.white12),
                ],
              ),
            ),

            const SizedBox(height: 60),

            // ── Minimal High-End Hub ──────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                physics: const BouncingScrollPhysics(),
                children: [
                  _HubItem(
                    title: 'FOCUS ENGINE',
                    subtitle: 'High-Fidelity Session Timer',
                    icon: Icons.timer_sharp,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FocusTimerPage())),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}



class _PeekValue extends StatelessWidget {
  final String label;
  final String value;
  const _PeekValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 7, letterSpacing: 2, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w300, fontFamily: 'Inter')),
      ],
    );
  }
}

class _HubItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const _HubItem({required this.title, required this.subtitle, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.3 : 1.0,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white10,
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 40),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(width: 40),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 3)),
                    const SizedBox(height: 6),
                    Text(subtitle, style: const TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 0.8)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white10, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// FOCUS TIMER PAGE — Multi-Layer Animation Engine
// ════════════════════════════════════════════════════════════════════════════

enum TimerModel { digital, analog, sand }

class FocusTimerPage extends StatefulWidget {
  const FocusTimerPage({super.key});

  @override
  State<FocusTimerPage> createState() => _FocusTimerPageState();
}

class _FocusTimerPageState extends State<FocusTimerPage> with TickerProviderStateMixin {
  int _secondsRemaining = 25 * 60;
  int _totalSeconds = 25 * 60;
  bool _isRunning = false;
  Timer? _timer;
  TimerModel _model = TimerModel.digital;
  
  final AudioPlayer _audio = AudioPlayer();

  // Dial State
  bool _isDialing = false;
  double _currentAngle = 0;
  double _startAngle = 0;
  
  // Animation Controllers
  late AnimationController _dialAnim;
  late AnimationController _glowAnim;
  late AnimationController _smoothTicker;

  @override
  void initState() {
    super.initState();
    _dialAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _glowAnim = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _smoothTicker = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dialAnim.dispose();
    _glowAnim.dispose();
    _smoothTicker.dispose();
    _audio.dispose();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleTimer() {
    setState(() {
      if (_isRunning) {
        _timer?.cancel();
        _isRunning = false;
        WakelockPlus.disable();
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      } else {
        _isRunning = true;
        WakelockPlus.enable();
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_secondsRemaining > 0) {
            setState(() => _secondsRemaining--);
          } else {
            _timer?.cancel();
            setState(() => _isRunning = false);
            WakelockPlus.disable();
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
            _onComplete();
          }
        });
      }
    });
  }

  void _onComplete() async {
    HapticFeedback.heavyImpact();
    // Try playing a formal system sound
    try {
      await _audio.play(AssetSource('sounds/complete.mp3')); // If exists
    } catch (_) {
      // Fallback: Just vibration + dialog
    }
    
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _CompletionOverlay(onClose: () => Navigator.pop(context)),
      );
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = _totalSeconds;
      _isRunning = false;
    });
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _adjustTime(int minutes) {
    if (_isRunning) return;
    setState(() {
      _totalSeconds = (minutes * 60).clamp(60, 180 * 60);
      _secondsRemaining = _totalSeconds;
    });
    HapticFeedback.lightImpact();
  }

  // ── Dial Logic ─────────────────────────────────────────────────────────────

  void _onDialStart(Offset localPos) {
    if (_isRunning) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _isDialing = true;
      _startAngle = _calculateAngle(localPos);
      _currentAngle = _startAngle;
    });
    _dialAnim.forward();
  }

  void _onDialUpdate(Offset localPos) {
    if (!_isDialing) return;
    
    final newAngle = _calculateAngle(localPos);
    double delta = newAngle - _currentAngle;

    if (delta > math.pi) delta -= 2 * math.pi;
    if (delta < -math.pi) delta += 2 * math.pi;

    final double velocityFactor = (delta.abs() * 8.0).clamp(1.0, 15.0);
    final int secondsDelta = (delta * (180 / math.pi) * 0.4 * velocityFactor).round() * 10;
    
    if (secondsDelta != 0) {
      setState(() {
        _totalSeconds = (_totalSeconds + secondsDelta).clamp(60, 180 * 60);
        _secondsRemaining = _totalSeconds;
        _currentAngle = newAngle;
      });
      if (_totalSeconds % 60 == 0) HapticFeedback.selectionClick();
    }
  }

  void _onDialEnd() {
    setState(() => _isDialing = false);
    _dialAnim.reverse();
    HapticFeedback.lightImpact();
  }

  double _calculateAngle(Offset localPos) {
    const center = Offset(140, 140);
    return math.atan2(localPos.dy - center.dy, localPos.dx - center.dx);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Dial Shadow
          if (_isDialing)
            FadeIn(child: Container(color: Colors.black87)),

          SafeArea(
            child: Column(
              children: [
                // Top Navigation
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (!_isRunning && !_isDialing)
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white24, size: 18),
                          onPressed: () => Navigator.pop(context),
                        )
                      else
                        const SizedBox(width: 48),
                      
                      if (!_isDialing)
                        _SegmentedModelPicker(
                          selected: _model,
                          onChanged: (m) => setState(() => _model = m),
                        )
                      else
                        Text('ROTATE TO SET', style: GoogleFonts.inter(color: Colors.white38, fontSize: 8, letterSpacing: 4, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),

                const Spacer(),

                // Clock Core
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Dial Glow Effect
                      AnimatedBuilder(
                        animation: _dialAnim,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _dialAnim.value,
                            child: Transform.scale(
                              scale: 0.8 + (0.4 * _dialAnim.value),
                              child: Container(
                                width: 340, height: 340,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                                  gradient: SweepGradient(
                                    colors: [Colors.transparent, Colors.white.withValues(alpha: 0.08), Colors.transparent],
                                    transform: GradientRotation(_currentAngle),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Interaction Zone
                      GestureDetector(
                        onLongPressStart: (details) => _onDialStart(details.localPosition),
                        onLongPressMoveUpdate: (details) => _onDialUpdate(details.localPosition),
                        onLongPressEnd: (_) => _onDialEnd(),
                        onTap: _toggleTimer,
                        behavior: HitTestBehavior.opaque,
                        child: _buildClockView(),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Controls
                if (!_isRunning && !_isDialing)
                  Column(
                    children: [
                      FadeIn(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 32),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [15, 25, 45, 60].map((m) => _PresetBtn(
                              label: '$m',
                              selected: _totalSeconds == m * 60,
                              onTap: () => _adjustTime(m),
                            )).toList(),
                          ),
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.only(bottom: 64),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_secondsRemaining < _totalSeconds)
                              _CircularActionBtn(icon: Icons.refresh, onTap: _resetTimer)
                            else
                              const SizedBox(width: 56),
                            const SizedBox(width: 40),
                            _MainActionBtn(isRunning: _isRunning, onTap: _toggleTimer),
                            const SizedBox(width: 40),
                            const SizedBox(width: 56),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  const SizedBox(height: 180),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClockView() {
    final double subsecond = _isRunning ? _smoothTicker.value : 0;
    final progress = 1.0 - ((_secondsRemaining - subsecond) / _totalSeconds).clamp(0.0, 1.0);
    
    return RepaintBoundary(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: switch (_model) {
          TimerModel.digital => _DigitalView(seconds: _secondsRemaining, isRunning: _isRunning, glow: _glowAnim.value),
          TimerModel.analog  => _AnalogView(progress: progress),
          TimerModel.sand    => _SandView(progress: progress, isRunning: _isRunning),
        },
      ),
    );
  }
}

// ── Components ──────────────────────────────────────────────────────────────

class _SegmentedModelPicker extends StatelessWidget {
  final TimerModel selected;
  final ValueChanged<TimerModel> onChanged;
  const _SegmentedModelPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(30)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: TimerModel.values.map((m) {
          final isSel = selected == m;
          return GestureDetector(
            onTap: () => onChanged(m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: isSel ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(20)),
              child: Icon(
                m == TimerModel.digital ? Icons.numbers : m == TimerModel.analog ? Icons.watch_later_outlined : Icons.hourglass_empty,
                size: 14, color: isSel ? Colors.black : Colors.white24,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PresetBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PresetBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 10),
        width: 48, height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: selected ? Colors.white : Colors.white10),
          color: selected ? Colors.white : Colors.transparent,
        ),
        child: Center(
          child: Text(label, style: TextStyle(color: selected ? Colors.black : Colors.white24, fontSize: 12, fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }
}

class _MainActionBtn extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onTap;
  const _MainActionBtn({required this.isRunning, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isRunning ? Colors.transparent : Colors.white,
          border: Border.all(color: Colors.white),
        ),
        child: Icon(isRunning ? Icons.pause : Icons.play_arrow, color: isRunning ? Colors.white : Colors.black, size: 32),
      ),
    );
  }
}

class _CircularActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircularActionBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => IconButton(icon: Icon(icon, color: Colors.white24, size: 24), onPressed: onTap);
}

// ── Views ──────────────────────────────────────────────────────────────────

class _DigitalView extends StatelessWidget {
  final int seconds;
  final bool isRunning;
  final double glow;
  const _DigitalView({required this.seconds, required this.isRunning, required this.glow});

  @override
  Widget build(BuildContext context) {
    final m = (seconds / 60).floor();
    final s = seconds % 60;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
          style: GoogleFonts.shareTechMono(
            color: Colors.white,
            fontSize: 104,
            letterSpacing: -4,
            shadows: [
              if (isRunning) Shadow(color: Colors.white.withValues(alpha: 0.2 * glow), blurRadius: 30),
            ],
          ),
        ),
        Text('ENGINE ACTIVE', style: GoogleFonts.inter(color: Colors.white10, fontSize: 8, letterSpacing: 8, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _AnalogView extends StatelessWidget {
  final double progress;
  const _AnalogView({required this.progress});
  @override
  Widget build(BuildContext context) => SizedBox(width: 280, height: 280, child: CustomPaint(painter: _AnalogPainter(progress: progress)));
}

class _SandView extends StatefulWidget {
  final double progress;
  final bool isRunning;
  const _SandView({required this.progress, required this.isRunning});
  @override
  State<_SandView> createState() => _SandViewState();
}

class _SandViewState extends State<_SandView> with SingleTickerProviderStateMixin {
  late AnimationController _particles;
  @override
  void initState() {
    super.initState();
    _particles = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  }
  @override
  void dispose() { _particles.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 200, height: 320, 
    child: AnimatedBuilder(
      animation: _particles,
      builder: (context, child) => CustomPaint(painter: _SandPainter(progress: widget.progress, time: _particles.value, isRunning: widget.isRunning))
    ),
  );
}

// ── Painters ───────────────────────────────────────────────────────────────

class _AnalogPainter extends CustomPainter {
  final double progress;
  _AnalogPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    final paint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1;
    
    // Smooth Arc
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, 2 * math.pi * progress, false, paint);
    
    // Tick marks
    for (int i = 0; i < 60; i++) {
      final angle = i * 6 * math.pi / 180;
      final isHour = i % 5 == 0;
      final p1 = Offset(center.dx + (radius - (isHour ? 15 : 5)) * math.cos(angle), center.dy + (radius - (isHour ? 15 : 5)) * math.sin(angle));
      final p2 = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
      canvas.drawLine(p1, p2, Paint()..color = isHour ? Colors.white30 : Colors.white10..strokeWidth = 1);
    }

    // Smooth Hand
    final handAngle = (2 * math.pi * progress) - (math.pi / 2);
    canvas.drawLine(center, Offset(center.dx + (radius - 40) * math.cos(handAngle), center.dy + (radius - 40) * math.sin(handAngle)), Paint()..color = Colors.white..strokeWidth = 1.5);
    canvas.drawCircle(center, 3, Paint()..color = Colors.white);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SandPainter extends CustomPainter {
  final double progress;
  final double time;
  final bool isRunning;
  _SandPainter({required this.progress, required this.time, required this.isRunning});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    
    final path = Path()
      ..moveTo(0, 0)..lineTo(w, 0)
      ..quadraticBezierTo(w * 0.9, h * 0.4, w * 0.5, h * 0.5)
      ..quadraticBezierTo(w * 0.1, h * 0.6, 0, h)..lineTo(w, h)
      ..quadraticBezierTo(w * 0.9, h * 0.6, w * 0.5, h * 0.5)
      ..quadraticBezierTo(w * 0.1, h * 0.4, 0, 0);
    canvas.drawPath(path, Paint()..color = Colors.white10..style = PaintingStyle.stroke);

    final sand = Paint()..color = Colors.white..style = PaintingStyle.fill;

    // Top sand level
    if (progress < 1.0) {
      final topH = h * 0.45 * (1 - progress);
      final topW = w * 0.9 * (1 - progress);
      final topPath = Path()
        ..moveTo(w * 0.5 - topW / 2, h * 0.5 - topH)
        ..lineTo(w * 0.5 + topW / 2, h * 0.5 - topH)
        ..quadraticBezierTo(w * 0.5 + topW / 2, h * 0.5, w * 0.5, h * 0.5)
        ..quadraticBezierTo(w * 0.5 - topW / 2, h * 0.5, w * 0.5 - topW / 2, h * 0.5 - topH);
      canvas.drawPath(topPath, sand);
    }

    // Bottom sand pile
    final bottomH = h * 0.45 * progress;
    final bottomW = w * 0.9 * progress;
    final bottomPath = Path()
      ..moveTo(w * 0.5, h * 0.5 + (h * 0.5 - bottomH))
      ..quadraticBezierTo(w * 0.5 - bottomW / 2, h, 0, h)..lineTo(w, h)
      ..quadraticBezierTo(w * 0.5 + bottomW / 2, h, w * 0.5, h * 0.5 + (h * 0.5 - bottomH));
    canvas.drawPath(bottomPath, sand);

    // Falling particles
    if (isRunning && progress < 1.0) {
      for (int i = 0; i < 5; i++) {
        final double py = h * 0.5 + (h * 0.5 * ((time + i / 5) % 1.0));
        if (py < h - 5) canvas.drawCircle(Offset(w * 0.5, py), 1, sand);
      }
      canvas.drawLine(Offset(w * 0.5, h * 0.5), Offset(w * 0.5, h - 5), Paint()..color = Colors.white24);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ── Overlay ────────────────────────────────────────────────────────────────

class _CompletionOverlay extends StatelessWidget {
  final VoidCallback onClose;
  const _CompletionOverlay({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.9),
      child: Center(
        child: FadeIn(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const NexusLogo(size: 64, color: Colors.white),
              const SizedBox(height: 48),
              Text('FOCUS SESSION COMPLETE', style: GoogleFonts.inter(color: Colors.white, fontSize: 14, letterSpacing: 6, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              const Text('YOU HAVE EARNED YOUR REST', style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2)),
              const SizedBox(height: 64),
              GestureDetector(
                onTap: onClose,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  decoration: BoxDecoration(border: Border.all(color: Colors.white10), borderRadius: BorderRadius.circular(30)),
                  child: const Text('DISMISS', style: TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 4, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




class FadeIn extends StatefulWidget {
  final Widget child; final Duration duration;
  const FadeIn({super.key, required this.child, this.duration = const Duration(milliseconds: 600)});
  @override
  State<FadeIn> createState() => _FadeInState();
}
class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late AnimationController _c; late Animation<double> _o;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: widget.duration); _o = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut)); _c.forward(); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _o, child: widget.child);
}
