import 'package:flutter/material.dart';

/// Scatters small colorful stars/sparkles tightly around [child] (e.g. an icon
/// preview circle) for a fun, celebratory look.
class SparkleDecoration extends StatelessWidget {
  const SparkleDecoration({
    super.key,
    required this.child,
    this.height = 130,
    this.width = 200,
  });

  final Widget child;
  final double height;
  final double width;

  // Positions are tuned so the sparkles hug the icon (kept off its center).
  static const List<_Spark> _sparks = [
    _Spark(left: 34, top: 12, color: Color(0xFF9C27B0), size: 13, star: true),
    _Spark(left: 18, top: 46, color: Color(0xFFF9A825), size: 8),
    _Spark(right: 34, top: 10, color: Color(0xFFEF5350), size: 12, star: true),
    _Spark(right: 20, top: 48, color: Color(0xFF66BB6A), size: 8),
    _Spark(left: 40, bottom: 14, color: Color(0xFF42A5F5), size: 10, star: true),
    _Spark(right: 42, bottom: 16, color: Color(0xFFEC407A), size: 8),
    _Spark(left: 8, top: 66, color: Color(0xFFFFB300), size: 7),
    _Spark(right: 8, top: 64, color: Color(0xFF7C4DFF), size: 8, star: true),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          for (final s in _sparks)
            Positioned(
              left: s.left,
              top: s.top,
              right: s.right,
              bottom: s.bottom,
              child: Icon(
                s.star ? Icons.star_rounded : Icons.circle,
                color: s.color,
                size: s.size,
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class _Spark {
  const _Spark({
    this.left,
    this.top,
    this.right,
    this.bottom,
    required this.color,
    required this.size,
    this.star = false,
  });

  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final Color color;
  final double size;
  final bool star;
}
