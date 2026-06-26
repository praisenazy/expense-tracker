import 'dart:ui';

import 'package:flutter/material.dart';

/// Floating pill navigation bar with a "liquid glass" lens that follows the
/// finger while swiping/holding to switch tabs, then settles back.
///
/// Slots: 0 = Home, 1 = Add (+, center), 2 = Summary.
/// [currentIndex] is the page index (0 = Home, 1 = Summary).
class LiquidGlassNavBar extends StatefulWidget {
  const LiquidGlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onAddPressed,
    required this.primary,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onAddPressed;
  final Color primary;

  @override
  State<LiquidGlassNavBar> createState() => _LiquidGlassNavBarState();
}

class _LiquidGlassNavBarState extends State<LiquidGlassNavBar> {
  static const double _barHeight = 66;
  static const double _lensRadius = 28;

  // Local x of the glass lens while the user is interacting; null when idle.
  double? _lensX;

  int _slotForX(double x, double width) =>
      (x / (width / 3)).floor().clamp(0, 2);

  // Maps a slot to the page index, or null for the center "+" slot.
  int? _pageForSlot(int slot) => slot == 0 ? 0 : (slot == 2 ? 1 : null);

  void _onTap(double x, double width) {
    final slot = _slotForX(x, width);
    final page = _pageForSlot(slot);
    if (page != null) {
      widget.onTabSelected(page);
    } else {
      widget.onAddPressed();
    }
  }

  void _endInteraction(double width) {
    final x = _lensX;
    setState(() => _lensX = null);
    if (x == null) return;
    // A swipe/hold only switches between the two tabs (ignores the + slot).
    final page = _pageForSlot(_slotForX(x, width));
    if (page != null) widget.onTabSelected(page);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(48, 0, 48, 4),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => _onTap(d.localPosition.dx, width),
              onHorizontalDragStart: (d) =>
                  setState(() => _lensX = d.localPosition.dx.clamp(0.0, width)),
              onHorizontalDragUpdate: (d) =>
                  setState(() => _lensX = d.localPosition.dx.clamp(0.0, width)),
              onHorizontalDragEnd: (_) => _endInteraction(width),
              onLongPressStart: (d) =>
                  setState(() => _lensX = d.localPosition.dx.clamp(0.0, width)),
              onLongPressMoveUpdate: (d) =>
                  setState(() => _lensX = d.localPosition.dx.clamp(0.0, width)),
              onLongPressEnd: (_) => _endInteraction(width),
              child: SizedBox(
                height: _barHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _buildPill(),
                    if (_lensX != null) _buildLens(_lensX!, width),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPill() {
    return Container(
      height: _barHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 30,
            spreadRadius: 1,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTab(slot: 0, icon: Icons.home_rounded, label: 'Home'),
          ),
          Expanded(child: _buildAddButton()),
          Expanded(
            child: _buildTab(
              slot: 2,
              icon: Icons.pie_chart_rounded,
              label: 'Summary',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required int slot,
    required IconData icon,
    required String label,
  }) {
    final isActive = _pageForSlot(slot) == widget.currentIndex;
    final color = isActive ? widget.primary : Colors.black54;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isActive
            ? widget.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Center(
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: widget.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.primary.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
      ),
    );
  }

  /// The frosted "liquid glass" bubble that magnifies the hovered slot's icon.
  Widget _buildLens(double x, double width) {
    final slot = _slotForX(x, width);
    final icon = switch (slot) {
      0 => Icons.home_rounded,
      2 => Icons.pie_chart_rounded,
      _ => Icons.add_rounded,
    };
    final left = (x - _lensRadius).clamp(0.0, width - 2 * _lensRadius);

    return Positioned(
      left: left,
      top: _barHeight / 2 - _lensRadius,
      child: IgnorePointer(
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 2 * _lensRadius,
              height: 2 * _lensRadius,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Glossy glass highlight.
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.6),
                    Colors.white.withValues(alpha: 0.18),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.7),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              // Magnified icon inside the lens.
              child: Center(child: Icon(icon, size: 26, color: widget.primary)),
            ),
          ),
        ),
      ),
    );
  }
}
