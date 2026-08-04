import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/user_provider.dart';
import '../onboarding/onboarding_screen.dart';
import '../root/root_screen.dart';

/// Animated splash / loading screen shown on launch: a glowing rotating ring,
/// a progress bar that fills 0→100% over 3 seconds, then routes to onboarding
/// (first run) or Home.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  static const Color _bg = Color(0xFF0A0E1A);
  static const Color _blue = Color(0xFF3B82F6);
  static const Color _teal = Color(0xFF22D3EE);
  static const Color _green = Color(0xFF34D399);

  late final AnimationController _spin; // continuous ring rotation
  late final AnimationController _wave; // bottom wave motion
  late final AnimationController _progress; // 0→100% over 3s
  late final AnimationController _heart; // logo heartbeat
  late final Animation<double> _beat; // lub-dub pulse curve

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    // Heartbeat: a quick "lub-dub" pump, then a short rest — repeating.
    _heart = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
    _beat = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.18)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.18, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.10)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 8,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.10, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 8,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 64),
    ]).animate(_heart);

    _progress.addStatusListener((status) {
      if (status == AnimationStatus.completed) _goHome();
    });
  }

  void _goHome() {
    if (!mounted) return;
    // First run → onboarding; afterwards → straight to Home.
    final onboarded = ref.read(onboardingCompleteProvider);
    final Widget destination =
        onboarded ? const RootScreen() : const OnboardingScreen();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => destination,
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _spin.dispose();
    _wave.dispose();
    _progress.dispose();
    _heart.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Glowing wave lines across the middle (behind the spinner).
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _wave,
              builder: (context, _) => CustomPaint(
                painter: _WavePainter(phase: _wave.value, color: _blue),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // ---- App icon badge (heartbeat + coin sparkles) ----
                  _heartbeatBadge(),
                  const SizedBox(height: 20),

                  // ---- App name ----
                  const Text(
                    'Expense',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      colors: [_green, _teal],
                    ).createShader(rect),
                    child: const Text(
                      'Tracker',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Take control of your money',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 14,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ---- Spinning ring ----
                  SizedBox(
                    width: 168,
                    height: 168,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        RotationTransition(
                          turns: _spin,
                          child: CustomPaint(
                            size: const Size(168, 168),
                            painter: _RingPainter(
                              colors: const [_blue, _teal, _green],
                            ),
                          ),
                        ),
                        Text(
                          'Loading…',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 3),

                  // ---- Bottom progress ----
                  Text(
                    'Analyzing your financial world…',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AnimatedBuilder(
                    animation: _progress,
                    builder: (context, _) {
                      final value = _progress.value;
                      return Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: value,
                              minHeight: 8,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.08),
                              valueColor:
                                  const AlwaysStoppedAnimation(_green),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${(value * 100).round()}%',
                            style: const TextStyle(
                              color: _green,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientIcon(IconData icon, {required double size}) {
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        colors: [_blue, _green],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(rect),
      child: Icon(icon, size: size, color: Colors.white),
    );
  }

  /// The logo badge, pumping like a heartbeat.
  Widget _heartbeatBadge() {
    return ScaleTransition(scale: _beat, child: _badge());
  }

  Widget _badge() {
    return Container(
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF121A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _teal.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(color: _teal.withValues(alpha: 0.25), blurRadius: 20),
        ],
      ),
      child: _gradientIcon(Icons.insights_rounded, size: 40),
    );
  }
}

/// Draws the glowing rotating spinner ring (an ~80% arc with a blue→green
/// sweep gradient plus an outer glow).
class _RingPainter extends CustomPainter {
  _RingPainter({required this.colors});

  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const stroke = 9.0;
    final radius = size.width / 2 - stroke;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = -math.pi / 2;
    const sweep = math.pi * 1.6; // ~80% of the circle, leaving a gap

    final shader = SweepGradient(
      startAngle: start,
      endAngle: start + 2 * math.pi,
      colors: [...colors, colors.first],
      transform: const GradientRotation(-math.pi / 2),
    ).createShader(rect);

    // Outer glow.
    final glow = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke + 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawArc(rect, start, sweep, false, glow);

    // Crisp ring.
    final ring = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, sweep, false, ring);
  }

  @override
  bool shouldRepaint(_RingPainter old) => false;
}

/// Subtle glowing sine waves along the bottom.
class _WavePainter extends CustomPainter {
  _WavePainter({required this.phase, required this.color});

  final double phase; // 0..1
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 3; i++) {
      final path = Path();
      final amp = 14.0 + i * 6;
      // Cluster the waves around the vertical middle of the screen.
      final yBase = size.height * (0.46 + i * 0.07);
      final shift = phase * 2 * math.pi + i * 0.8;
      for (double x = 0; x <= size.width; x += 6) {
        final y = yBase +
            math.sin((x / size.width * 2 * math.pi) + shift) * amp;
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: 0.16 - i * 0.03)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.phase != phase;
}
