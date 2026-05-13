import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/activity_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/nexus_logo.dart';

// ════════════════════════════════════════════════════════════════════════════
// PRODUCTIVITY PAGE — Refined Minimal Hub
// ════════════════════════════════════════════════════════════════════════════

final selectedActivityDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final usageDataProvider = FutureProvider<UsageData>((ref) async {
  final date = ref.watch(selectedActivityDateProvider);
  bool granted = await ActivityService.isPermissionGranted();
  if (!granted) throw Exception('Permission required');
  return ActivityService.fetchDailyStats(date);
});

class ProductivityPage extends ConsumerStatefulWidget {
  const ProductivityPage({super.key});

  @override
  ConsumerState<ProductivityPage> createState() => _ProductivityPageState();
}

class _ProductivityPageState extends ConsumerState<ProductivityPage> {
  @override
  Widget build(BuildContext context) {
    final usageAsync = ref.watch(usageDataProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Minimal Branding & Peek ──────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PRODUCTIVITY', style: AppTypography.sectionHeader.copyWith(letterSpacing: 8, fontSize: 10)),
                      const SizedBox(height: 12),
                      usageAsync.when(
                        data: (data) => _SummaryPeek(
                          screenTime: _formatTimeBrief(data.totalScreenTimeMs),
                          unlocks: data.unlockCount,
                        ),
                        loading: () => const Text('Calculating...', style: TextStyle(color: Colors.white10, fontSize: 10)),
                        error: (_, __) => const Text('Connect to Stats', style: TextStyle(color: Colors.white10, fontSize: 10)),
                      ),
                    ],
                  ),
                  const NexusLogo(size: 16, color: Colors.white10),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // ── Refined Typographic Hub ──────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                children: [
                  _HubItem(
                    title: 'FOCUS ENGINE',
                    subtitle: 'Multi-Model Session Timer',
                    icon: Icons.timer_sharp,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FocusTimerPage())),
                  ),
                  _HubItem(
                    title: 'DIGITAL PULSE',
                    subtitle: 'Usage Analytics & Trends',
                    icon: Icons.auto_graph_outlined,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScreenTimePage())),
                  ),
                  _HubItem(
                    title: 'DEEP WORK LOGS',
                    subtitle: 'History (Coming Soon)',
                    icon: Icons.history_sharp,
                    onTap: null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeBrief(int ms) {
    final duration = Duration(milliseconds: ms);
    if (duration.inHours > 0) return '${duration.inHours}H ${duration.inMinutes % 60}M';
    return '${duration.inMinutes}M';
  }
}

class _SummaryPeek extends StatelessWidget {
  final String screenTime;
  final int unlocks;
  const _SummaryPeek({required this.screenTime, required this.unlocks});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PeekValue(label: 'TIME', value: screenTime),
        const SizedBox(width: 24),
        _PeekValue(label: 'UNLOCKS', value: '$unlocks'),
      ],
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
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 8, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w200, fontFamily: 'Inter')),
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
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 0.5)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white10, size: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// FOCUS TIMER PAGE — Circular Dial System
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

  // Dial State
  bool _isDialing = false;
  double _currentAngle = 0;
  double _startAngle = 0;
  late AnimationController _dialAnim;

  @override
  void initState() {
    super.initState();
    _dialAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dialAnim.dispose();
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
            _showComplete();
          }
        });
      }
    });
  }

  void _adjustTime(int minutes) {
    if (_isRunning) return;
    setState(() {
      _totalSeconds = (minutes * 60).clamp(60, 180 * 60);
      _secondsRemaining = _totalSeconds;
    });
    HapticFeedback.lightImpact();
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

  // ── Dial Algorithm ─────────────────────────────────────────────────────────

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

    // Handle wrap around
    if (delta > math.pi) delta -= 2 * math.pi;
    if (delta < -math.pi) delta += 2 * math.pi;

    // Speed Multiplier
    // The faster you move, the more time we add
    final double velocityFactor = (delta.abs() * 5.0).clamp(1.0, 10.0);
    final double sensitivity = 0.5 * velocityFactor;

    final int secondsDelta = (delta * (180 / math.pi) * sensitivity).round() * 10;
    
    if (secondsDelta != 0) {
      setState(() {
        _totalSeconds = (_totalSeconds + secondsDelta).clamp(60, 180 * 60);
        _secondsRemaining = _totalSeconds;
        _currentAngle = newAngle;
      });
      // Click haptic for every minute step
      if (_totalSeconds % 60 == 0) HapticFeedback.selectionClick();
    }
  }

  void _onDialEnd() {
    setState(() => _isDialing = false);
    _dialAnim.reverse();
    HapticFeedback.lightImpact();
  }

  double _calculateAngle(Offset localPos) {
    // Assuming 280x280 is the dial size
    final center = const Offset(140, 140);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;
    return math.atan2(dy, dx);
  }

  void _showComplete() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('SESSION COMPLETE', style: TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold)),
        content: const Text('Time to reset or take a break.', style: TextStyle(color: Colors.white38, fontSize: 12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('DISMISS')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Dial Shadow
          if (_isDialing)
            FadeIn(
              child: Container(color: Colors.black.withValues(alpha: 0.8)),
            ),

          SafeArea(
            child: Column(
              children: [
                // Top Control Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (!_isRunning && !_isDialing)
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white24, size: 20),
                          onPressed: () => Navigator.pop(context),
                        )
                      else
                        const SizedBox(width: 40),
                      
                      if (!_isDialing)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ModelBtn(model: TimerModel.digital, selected: _model == TimerModel.digital, icon: Icons.numbers_sharp, onTap: () => setState(() => _model = TimerModel.digital)),
                            _ModelBtn(model: TimerModel.analog, selected: _model == TimerModel.analog, icon: Icons.watch_later_outlined, onTap: () => setState(() => _model = TimerModel.analog)),
                            _ModelBtn(model: TimerModel.sand, selected: _model == TimerModel.sand, icon: Icons.hourglass_empty_sharp, onTap: () => setState(() => _model = TimerModel.sand)),
                          ],
                        )
                      else
                        const Text('ADJUSTING TIME', style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 4, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                const Spacer(),

                // Clock Core with Circular Dial Interaction
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Interactive Dial Ring (only visible/active when setting)
                      AnimatedBuilder(
                        animation: _dialAnim,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1.0 + (0.2 * _dialAnim.value),
                            child: Opacity(
                              opacity: _dialAnim.value,
                              child: Container(
                                width: 320,
                                height: 320,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                                  gradient: SweepGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withValues(alpha: 0.05),
                                      Colors.transparent
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                    transform: GradientRotation(_currentAngle),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Gesture Detector Area
                      GestureDetector(
                        onLongPressStart: (details) => _onDialStart(details.localPosition),
                        onLongPressMoveUpdate: (details) => _onDialUpdate(details.localPosition),
                        onLongPressEnd: (_) => _onDialEnd(),
                        onTap: _toggleTimer,
                        child: _buildClockView(),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Instructions
                if (!_isRunning && !_isDialing)
                  FadeIn(
                    child: const Padding(
                      padding: EdgeInsets.only(bottom: 24),
                      child: Text(
                        'HOLD CLOCK TO ROTATE & SET TIME',
                        style: TextStyle(color: Colors.white24, fontSize: 8, letterSpacing: 2, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                // Predefined Controls
                if (!_isRunning && !_isDialing)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 48),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [15, 25, 45, 60].map((m) => _FormalTimeBtn(
                        label: '${m}M',
                        selected: _totalSeconds == m * 60,
                        onTap: () => _adjustTime(m),
                      )).toList(),
                    ),
                  ),

                // Action
                if (!_isDialing)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 64),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isRunning || _secondsRemaining < _totalSeconds)
                          IconButton(icon: const Icon(Icons.refresh, color: Colors.white10), onPressed: _resetTimer)
                        else
                          const SizedBox(width: 48),
                        const SizedBox(width: 32),
                        _PrimaryActionBtn(isRunning: _isRunning, onTap: _toggleTimer),
                        const SizedBox(width: 32),
                        const SizedBox(width: 48),
                      ],
                    ),
                  )
                else
                  const SizedBox(height: 144),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClockView() {
    final progress = 1.0 - (_secondsRemaining / _totalSeconds);
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: switch (_model) {
        TimerModel.digital => _DigitalClock(seconds: _secondsRemaining),
        TimerModel.analog  => _AnalogClock(progress: progress),
        TimerModel.sand    => _SandTimer(progress: progress),
      },
    );
  }
}

// ── Components ──────────────────────────────────────────────────────────────

class _ModelBtn extends StatelessWidget {
  final TimerModel model;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  const _ModelBtn({required this.model, required this.selected, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? Colors.white12 : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, color: selected ? Colors.white : Colors.white24, size: 16),
      ),
    );
  }
}

class _FormalTimeBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FormalTimeBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? Colors.white24 : Colors.transparent),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white24,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionBtn extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onTap;
  const _PrimaryActionBtn({required this.isRunning, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isRunning ? Colors.transparent : Colors.white,
          border: Border.all(color: Colors.white),
        ),
        child: Icon(
          isRunning ? Icons.pause : Icons.play_arrow,
          color: isRunning ? Colors.white : Colors.black,
          size: 28,
        ),
      ),
    );
  }
}

// ── Clock Models ─────────────────────────────────────────────────────────────

class _DigitalClock extends StatelessWidget {
  final int seconds;
  const _DigitalClock({required this.seconds});

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
            fontSize: 96,
            letterSpacing: -2,
            shadows: [
              Shadow(color: Colors.white.withValues(alpha: 0.3), blurRadius: 20),
            ],
          ),
        ),
        Text(
          'ACTIVE FOCUS',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.1), fontSize: 10, letterSpacing: 8, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _AnalogClock extends StatelessWidget {
  final double progress;
  const _AnalogClock({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 280,
      child: CustomPaint(
        painter: _AnalogClockPainter(progress: progress),
      ),
    );
  }
}

class _SandTimer extends StatelessWidget {
  final double progress;
  const _SandTimer({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 300,
      child: CustomPaint(
        painter: _SandTimerPainter(progress: progress),
      ),
    );
  }
}

// ── Painters ───────────────────────────────────────────────────────────────

class _AnalogClockPainter extends CustomPainter {
  final double progress;
  _AnalogClockPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Minimal Dial
    final dialPaint = Paint()..color = Colors.white12..style = PaintingStyle.stroke..strokeWidth = 0.5;
    canvas.drawCircle(center, radius, dialPaint);

    // Dots
    final dotPaint = Paint()..color = Colors.white24;
    for (int i = 0; i < 12; i++) {
      double angle = i * 30 * math.pi / 180;
      canvas.drawCircle(Offset(center.dx + (radius - 10) * math.cos(angle), center.dy + (radius - 10) * math.sin(angle)), 1, dotPaint);
    }

    // Progress Arc
    final progressPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, 2 * math.pi * progress, false, progressPaint);

    // Minimalist Hand
    final handPaint = Paint()..color = Colors.white..strokeWidth = 1;
    double handAngle = (2 * math.pi * progress) - (math.pi / 2);
    canvas.drawLine(center, Offset(center.dx + (radius - 30) * math.cos(handAngle), center.dy + (radius - 30) * math.sin(handAngle)), handPaint);
    canvas.drawCircle(center, 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SandTimerPainter extends CustomPainter {
  final double progress;
  _SandTimerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    
    final framePaint = Paint()..color = Colors.white24..style = PaintingStyle.stroke..strokeWidth = 1;
    final sandPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;

    // Hourglass Glass (Vintage Curves)
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..quadraticBezierTo(w * 0.9, h * 0.4, w * 0.5, h * 0.5)
      ..quadraticBezierTo(w * 0.1, h * 0.6, 0, h)
      ..lineTo(w, h)
      ..quadraticBezierTo(w * 0.9, h * 0.6, w * 0.5, h * 0.5)
      ..quadraticBezierTo(w * 0.1, h * 0.4, 0, 0);
    canvas.drawPath(path, framePaint);

    // Top Sand (Decreasing Conical)
    if (progress < 1.0) {
      final topSandPath = Path()
        ..moveTo(w * 0.05 + (w * 0.45 * progress), h * 0.45 * progress)
        ..lineTo(w * 0.95 - (w * 0.45 * progress), h * 0.45 * progress)
        ..quadraticBezierTo(w * 0.8, h * 0.4, w * 0.5, h * 0.5)
        ..quadraticBezierTo(w * 0.2, h * 0.4, w * 0.05 + (w * 0.45 * progress), h * 0.45 * progress);
      canvas.drawPath(topSandPath, sandPaint);
    }

    // Bottom Sand (Increasing Conical Pile)
    final bottomSandPath = Path()
      ..moveTo(w * 0.5, h - (h * 0.45 * progress))
      ..quadraticBezierTo(w * 0.1, h - 5, 0, h)
      ..lineTo(w, h)
      ..quadraticBezierTo(w * 0.9, h - 5, w * 0.5, h - (h * 0.45 * progress));
    canvas.drawPath(bottomSandPath, sandPaint);

    // Flowing Sand Line
    if (progress > 0 && progress < 1.0) {
      canvas.drawLine(Offset(w * 0.5, h * 0.5), Offset(w * 0.5, h - (h * 0.45 * progress)), Paint()..color = Colors.white.withValues(alpha: 0.5)..strokeWidth = 1);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ── Shared Activities Page (Pasted and Refined) ──────────────────────────────

class ScreenTimePage extends ConsumerWidget {
  const ScreenTimePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageAsync = ref.watch(usageDataProvider);
    final selectedDate = ref.watch(selectedActivityDateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text('SCREEN TIME', style: AppTypography.sectionHeader.copyWith(letterSpacing: 2)),
        centerTitle: true,
        actions: [
          _DateNavigator(selectedDate: selectedDate, onChanged: (d) => ref.read(selectedActivityDateProvider.notifier).state = d),
          const SizedBox(width: 12),
        ],
      ),
      body: usageAsync.when(
        data: (data) => data.totalScreenTimeMs == 0 && data.appUsage.isEmpty
            ? _EmptyState(date: selectedDate)
            : _ActivityContent(data: data, date: selectedDate),
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (err, _) {
          if (err.toString().contains('Permission required')) return _PermissionGate();
          return Center(child: Text('No data for this day', style: AppTypography.caption));
        },
      ),
    );
  }
}

class _DateNavigator extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;
  const _DateNavigator({required this.selectedDate, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(selectedDate, DateTime.now());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.card, border: Border.all(color: AppColors.border)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left, size: 18, color: Colors.white), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => onChanged(selectedDate.subtract(const Duration(days: 1)))),
          const SizedBox(width: 8),
          Text(isToday ? 'TODAY' : DateFormat('MMM dd').format(selectedDate).toUpperCase(), style: AppTypography.cardTitle.copyWith(fontSize: 11, letterSpacing: 1)),
          const SizedBox(width: 8),
          IconButton(icon: Icon(Icons.chevron_right, size: 18, color: isToday ? Colors.white24 : Colors.white), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: isToday ? null : () => onChanged(selectedDate.add(const Duration(days: 1)))),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final DateTime date;
  const _EmptyState({required this.date});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text('NO ACTIVITY LOGGED', style: AppTypography.sectionHeader.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(DateFormat('EEEE, MMMM dd').format(date), style: AppTypography.caption),
        ],
      ),
    );
  }
}

class _PermissionGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_clock_outlined, size: 64, color: AppColors.accentSecondary),
          const SizedBox(height: 24),
          Text('Usage Access Required', style: AppTypography.pageTitle),
          const SizedBox(height: 12),
          Text('To monitor screen time and activity, Nexus needs "Usage Access" permission from Android settings.', textAlign: TextAlign.center, style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          ElevatedButton(onPressed: () => ActivityService.grantPermission(), child: const Text('Open Settings')),
        ],
      ),
    );
  }
}

class _ActivityContent extends StatelessWidget {
  final UsageData data;
  final DateTime date;
  const _ActivityContent({required this.data, required this.date});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      children: [
        const SizedBox(height: 20),
        Center(child: _ScreenTimeRing(timeMs: data.totalScreenTimeMs)),
        const SizedBox(height: 40),
        Row(
          children: [
            Expanded(child: _SmallStatCard(label: 'Unlocks', value: '${data.unlockCount}', icon: Icons.lock_open_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _SmallStatCard(label: 'App Usage', value: _formatTimeBrief(data.appUsage.values.fold(0, (a, b) => a + b)), icon: Icons.apps_rounded)),
          ],
        ),
        const SizedBox(height: 40),
        Text('TOP APPLICATIONS', style: AppTypography.sectionHeader),
        const SizedBox(height: 16),
        ..._buildAppList(data),
        const SizedBox(height: 120),
      ],
    );
  }
  List<Widget> _buildAppList(UsageData data) {
    final sortedApps = data.appUsage.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final filteredApps = sortedApps.where((e) => e.value > 60000).toList();
    if (filteredApps.isEmpty) return [Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Center(child: Text('Less than 1m in apps', style: AppTypography.caption)))];
    return filteredApps.map((app) {
      final pct = data.totalScreenTimeMs > 0 ? app.value / data.totalScreenTimeMs : 0.0;
      return _AppUsageTile(name: app.key.split('.').last.toUpperCase(), timeMs: app.value, pct: pct);
    }).toList();
  }
  String _formatTimeBrief(int ms) {
    final duration = Duration(milliseconds: ms);
    if (duration.inHours > 0) return '${duration.inHours}h ${duration.inMinutes % 60}m';
    return '${duration.inMinutes}m';
  }
}

class _ScreenTimeRing extends StatelessWidget {
  final int timeMs;
  const _ScreenTimeRing({required this.timeMs});
  @override
  Widget build(BuildContext context) {
    final duration = Duration(milliseconds: timeMs);
    final h = duration.inHours;
    final m = duration.inMinutes % 60;
    return Container(
      width: 220, height: 220,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.border, width: 1)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(value: 1.0, strokeWidth: 2, color: Colors.white.withValues(alpha: 0.05)),
          SizedBox(width: 200, height: 200, child: CircularProgressIndicator(value: (timeMs / (12 * 3600 * 1000)).clamp(0.0, 1.0), strokeWidth: 4, color: AppColors.accentSecondary, strokeCap: StrokeCap.round)),
          Column(mainAxisSize: MainAxisSize.min, children: [Text('$h', style: AppTypography.progressPct.copyWith(fontSize: 48)), Text('HOURS $m MIN', style: AppTypography.caption.copyWith(letterSpacing: 2)), const SizedBox(height: 4), Text('TOTAL SCREEN TIME', style: AppTypography.caption.copyWith(fontSize: 8, color: AppColors.textSecondary))]),
        ],
      ),
    );
  }
}

class _SmallStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _SmallStatCard({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.card, border: Border.all(color: AppColors.border)), child: Row(children: [Icon(icon, size: 18, color: AppColors.textSecondary), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: AppTypography.cardTitle), Text(label, style: AppTypography.caption.copyWith(fontSize: 9))])]));
  }
}

class _AppUsageTile extends StatelessWidget {
  final String name;
  final int timeMs;
  final double pct;
  const _AppUsageTile({required this.name, required this.timeMs, required this.pct});
  @override
  Widget build(BuildContext context) {
    final duration = Duration(milliseconds: timeMs);
    final timeStr = duration.inHours > 0 ? '${duration.inHours}h ${duration.inMinutes % 60}m' : '${duration.inMinutes}m';
    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: AppRadius.card), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(name, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600, fontSize: 13)), Text(timeStr, style: AppTypography.cardTitle.copyWith(fontSize: 13, color: AppColors.accentSecondary))]), const SizedBox(height: 12), ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: pct.clamp(0.0, 1.0), minHeight: 2, backgroundColor: Colors.white.withValues(alpha: 0.05), color: Colors.white.withValues(alpha: 0.3)))]));
  }
}

class FadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  const FadeIn({super.key, required this.child, this.duration = const Duration(milliseconds: 500)});
  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _ctrl.forward();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _opacity, child: widget.child);
}
