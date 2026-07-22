import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A custom (dependency-free) HSL color picker: a hue ring with a
/// saturation/lightness square in the middle, plus Hue / Saturation / Lightness
/// gradient sliders and a HEX field. Reports the chosen color via [onChanged].
class ColorWheelPicker extends StatefulWidget {
  const ColorWheelPicker({
    super.key,
    required this.initialColor,
    required this.onChanged,
  });

  final Color initialColor;
  final ValueChanged<Color> onChanged;

  @override
  State<ColorWheelPicker> createState() => _ColorWheelPickerState();
}

class _ColorWheelPickerState extends State<ColorWheelPicker> {
  late HSLColor _hsl;

  static const double _wheelSize = 168;
  static const double _ringThickness = 16;
  static const double _squareSide = 92;

  // Drives the little animated "Copied!" badge over the HEX row.
  bool _showCopied = false;
  int _copyToken = 0;

  @override
  void initState() {
    super.initState();
    _hsl = HSLColor.fromColor(widget.initialColor);
  }

  Color get _color => _hsl.toColor();

  void _copyHex(String hex) {
    Clipboard.setData(ClipboardData(text: hex));
    final token = ++_copyToken;
    setState(() => _showCopied = true);
    // Auto-hide, but only if a newer copy hasn't replaced this one.
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && token == _copyToken) {
        setState(() => _showCopied = false);
      }
    });
  }

  void _emit() => widget.onChanged(_color);

  void _setHue(double hue) {
    setState(() => _hsl = _hsl.withHue(hue.clamp(0, 360)));
    _emit();
  }

  void _setSatLight(double s, double l) {
    setState(() => _hsl =
        _hsl.withSaturation(s.clamp(0, 1)).withLightness(l.clamp(0, 1)));
    _emit();
  }

  // ---- Wheel gesture: decide ring (hue) vs square (sat/light) ----
  void _onWheelPan(Offset local) {
    const center = Offset(_wheelSize / 2, _wheelSize / 2);
    final v = local - center;
    const half = _squareSide / 2;

    if (v.dx.abs() <= half && v.dy.abs() <= half) {
      final s = (v.dx + half) / _squareSide;
      final l = 1 - (v.dy + half) / _squareSide;
      _setSatLight(s, l);
      return;
    }
    var deg = math.atan2(v.dy, v.dx) * 180 / math.pi;
    if (deg < 0) deg += 360;
    _setHue(deg);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hueColor = HSLColor.fromAHSL(1, _hsl.hue, 1, 0.5).toColor();
    final ringRadius = (_wheelSize - _ringThickness) / 2;
    final thumbAngle = _hsl.hue * math.pi / 180;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ---- Hue ring + SL square ----
            GestureDetector(
              onPanDown: (d) => _onWheelPan(d.localPosition),
              onPanUpdate: (d) => _onWheelPan(d.localPosition),
              child: SizedBox(
                width: _wheelSize,
                height: _wheelSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(_wheelSize, _wheelSize),
                      painter: _HueRingPainter(_ringThickness),
                    ),
                    // Hue thumb on the ring.
                    Positioned(
                      left: _wheelSize / 2 +
                          ringRadius * math.cos(thumbAngle) -
                          9,
                      top: _wheelSize / 2 +
                          ringRadius * math.sin(thumbAngle) -
                          9,
                      child: _thumb(hueColor),
                    ),
                    // Saturation / lightness square.
                    SizedBox(
                      width: _squareSide,
                      height: _squareSide,
                      child: Stack(
                        children: [
                          // Fill the 92×92 slot — a childless DecoratedBox under
                          // a Stack's loose constraints would otherwise be 0×0.
                          Positioned.fill(child: _slSquare(hueColor)),
                          Positioned(
                            left: _hsl.saturation * _squareSide - 8,
                            top: (1 - _hsl.lightness) * _squareSide - 8,
                            child: _thumb(_color, small: true),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // ---- Sliders ----
            Expanded(
              child: Column(
                children: [
                  _labeledSlider(
                    'Hue',
                    '${_hsl.hue.round()}°',
                    _hsl.hue / 360,
                    const [
                      Color(0xFFFF0000),
                      Color(0xFFFFFF00),
                      Color(0xFF00FF00),
                      Color(0xFF00FFFF),
                      Color(0xFF0000FF),
                      Color(0xFFFF00FF),
                      Color(0xFFFF0000),
                    ],
                    (v) => _setHue(v * 360),
                  ),
                  const SizedBox(height: 12),
                  _labeledSlider(
                    'Saturation',
                    '${(_hsl.saturation * 100).round()}%',
                    _hsl.saturation,
                    [
                      HSLColor.fromAHSL(1, _hsl.hue, 0, 0.5).toColor(),
                      HSLColor.fromAHSL(1, _hsl.hue, 1, 0.5).toColor(),
                    ],
                    (v) => _setSatLight(v, _hsl.lightness),
                  ),
                  const SizedBox(height: 12),
                  _labeledSlider(
                    'Lightness',
                    '${(_hsl.lightness * 100).round()}%',
                    _hsl.lightness,
                    [
                      Colors.black,
                      HSLColor.fromAHSL(1, _hsl.hue, _hsl.saturation, 0.5)
                          .toColor(),
                      Colors.white,
                    ],
                    (v) => _setSatLight(_hsl.saturation, v),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // ---- HEX ----
        _hexRow(theme),
      ],
    );
  }

  Widget _thumb(Color color, {bool small = false}) {
    final size = small ? 16.0 : 18.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4),
        ],
      ),
    );
  }

  Widget _slSquare(Color hueColor) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [const Color(0xFF808080), hueColor],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.transparent, Colors.black],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _labeledSlider(
    String label,
    String value,
    double fraction,
    List<Color> gradient,
    ValueChanged<double> onChanged,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            Text(value,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 4),
        _GradientSlider(
          fraction: fraction,
          gradient: gradient,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _hexRow(ThemeData theme) {
    final hex = '#${_color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color:
                theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Text('HEX', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  hex,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              InkWell(
                onTap: () => _copyHex(hex),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.copy_rounded, size: 18),
                ),
              ),
            ],
          ),
        ),
        // The animated "Copied!" badge floats just above the copy button.
        if (_showCopied)
          Positioned(
            top: -22,
            right: 0,
            child: _CopiedToast(key: ValueKey(_copyToken), color: _color),
          ),
      ],
    );
  }
}

/// A small "Copied!" badge that pops in with a bouncy scale and twinkling
/// sparkles — a bit of delight when the user copies the HEX color.
class _CopiedToast extends StatefulWidget {
  const _CopiedToast({super.key, required this.color});

  final Color color;

  @override
  State<_CopiedToast> createState() => _CopiedToastState();
}

class _CopiedToastState extends State<_CopiedToast>
    with TickerProviderStateMixin {
  late final AnimationController _in; // one-shot entrance
  late final AnimationController _twinkle; // looping sparkle shimmer

  @override
  void initState() {
    super.initState();
    _in = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _twinkle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _in.dispose();
    _twinkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pick a readable foreground for whatever category color is behind it.
    final onColor =
        ThemeData.estimateBrightnessForColor(widget.color) == Brightness.dark
            ? Colors.white
            : Colors.black87;

    return FadeTransition(
      opacity: CurvedAnimation(parent: _in, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: CurvedAnimation(parent: _in, curve: Curves.elasticOut),
        alignment: Alignment.bottomRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.5),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sparkle(onColor, phase: 0),
              const SizedBox(width: 6),
              Text(
                'Copied!',
                style: TextStyle(
                  color: onColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              _sparkle(onColor, phase: 0.5),
            ],
          ),
        ),
      ),
    );
  }

  /// A sparkle that twinkles — scales up/down and slowly rotates. [phase]
  /// offsets the two sparkles so they shimmer out of sync.
  Widget _sparkle(Color color, {required double phase}) {
    return AnimatedBuilder(
      animation: _twinkle,
      builder: (context, child) {
        final t = (_twinkle.value + phase) % 1.0;
        final scale = 0.65 + 0.35 * (0.5 + 0.5 * math.sin(t * 2 * math.pi));
        return Transform.rotate(
          angle: t * 2 * math.pi,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Icon(Icons.auto_awesome_rounded, size: 14, color: color),
    );
  }
}

/// A slider that shows a gradient track with a round thumb.
class _GradientSlider extends StatelessWidget {
  const _GradientSlider({
    required this.fraction,
    required this.gradient,
    required this.onChanged,
  });

  final double fraction;
  final List<Color> gradient;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        void update(double dx) => onChanged((dx / width).clamp(0.0, 1.0));
        return GestureDetector(
          onPanDown: (d) => update(d.localPosition.dx),
          onPanUpdate: (d) => update(d.localPosition.dx),
          child: SizedBox(
            height: 20,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(colors: gradient),
                  ),
                ),
                Positioned(
                  left: (fraction * width - 9).clamp(0.0, width - 18),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.15),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Paints the rainbow hue ring.
class _HueRingPainter extends CustomPainter {
  _HueRingPainter(this.thickness);

  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - thickness) / 2;
    final sweep = SweepGradient(
      colors: [
        for (int h = 0; h <= 360; h += 30)
          HSVColor.fromAHSV(1, h.toDouble() % 360, 1, 1).toColor(),
      ],
    );
    final paint = Paint()
      ..shader = sweep.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_HueRingPainter old) => old.thickness != thickness;
}
