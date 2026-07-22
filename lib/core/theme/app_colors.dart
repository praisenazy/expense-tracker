import 'package:flutter/material.dart';

/// Central color palette for the whole app.
///
/// A `Color` is written as 0xAARRGGBB:
///   - AA = alpha (opacity), FF = fully opaque
///   - RR GG BB = red, green, blue
/// Example: 0xFF4CAF50 = solid green.
class AppColors {
  AppColors._();

  // ---- Brand / accent ----
  // The "seed" color Flutter uses to generate the Material 3 color scheme.
  static const Color seed = Color(0xFF4C6FFF); // indigo-blue

  // ---- Semantic colors for money in/out ----
  static const Color income = Color(0xFF2E7D32); // green  = money in
  static const Color expense = Color(0xFFC62828); // red   = money out

  // ---- Default category colors ----
  static const Color food = Color(0xFFFF7043); // deep orange
  static const Color transport = Color(0xFF42A5F5); // blue
  static const Color bills = Color(0xFFAB47BC); // purple
  static const Color entertainment = Color(0xFFEC407A); // pink
  static const Color health = Color(0xFF26A69A); // teal
  static const Color others = Color(0xFF78909C); // blue-grey

  /// Colors a user can choose from when creating/editing a category.
  static const List<Color> palette = [
    Color(0xFFFF7043), // deep orange
    Color(0xFF42A5F5), // blue
    Color(0xFFAB47BC), // purple
    Color(0xFFEC407A), // pink
    Color(0xFF26A69A), // teal
    Color(0xFF78909C), // blue-grey
    Color(0xFF2E7D32), // green
    Color(0xFFF9A825), // amber
    Color(0xFF5C6BC0), // indigo
    Color(0xFFEF5350), // red
    Color(0xFF8D6E63), // brown
    Color(0xFF00ACC1), // cyan
    Color(0xFFCDDC39), // lime
  ];

  /// The "All Colors" grid (6 columns) shown on the category color picker.
  static const List<Color> allColors = [
    // reds → oranges → yellows
    Color(0xFFE24A3B), Color(0xFFF0673C), Color(0xFFF5883C),
    Color(0xFFF5A83C), Color(0xFFF0C33C), Color(0xFFF5D641),
    // greens
    Color(0xFF2E9E4F), Color(0xFF43A047), Color(0xFF5CB85C),
    Color(0xFF7CB342), Color(0xFF8BC34A), Color(0xFF9CCC65),
    // teals → blues
    Color(0xFF17A398), Color(0xFF26B0A8), Color(0xFF29B6C6),
    Color(0xFF3AA0D8), Color(0xFF4FA3E0), Color(0xFF5B8DEF),
    // purples
    Color(0xFF5C6BC0), Color(0xFF7C4DFF), Color(0xFF9B51E0),
    Color(0xFFAB47BC), Color(0xFFB94DD4), Color(0xFFC94DCC),
    // pinks / coral
    Color(0xFFE91E63), Color(0xFFF06292), Color(0xFFEC4899),
    Color(0xFFF48FB1), Color(0xFFE06C75), Color(0xFFE8825C),
    // browns / greys
    Color(0xFF5D4037), Color(0xFF795548), Color(0xFFA1887F),
    Color(0xFF9E9E9E), Color(0xFF37474F), Color(0xFFCFD8DC),
  ];

  /// Curated recommended palettes shown above the All Colors grid.
  static const List<ColorPalette> recommendedPalettes = [
    ColorPalette('Sunset', [
      Color(0xFFE24A3B), Color(0xFFF0673C), Color(0xFFF7B267),
      Color(0xFFF04E37), Color(0xFFF5883C), Color(0xFFF7D08A),
    ]),
    ColorPalette('Ocean', [
      Color(0xFF1565C0), Color(0xFF2196F3), Color(0xFF4FC3F7),
      Color(0xFF0D47A1), Color(0xFF42A5F5), Color(0xFF81D4FA),
    ]),
    ColorPalette('Forest', [
      Color(0xFF2E7D32), Color(0xFF43A047), Color(0xFF66BB6A),
      Color(0xFF1B5E20), Color(0xFF388E3C), Color(0xFFA5D6A7),
    ]),
    ColorPalette('Purple', [
      Color(0xFF5E35B1), Color(0xFF7C4DFF), Color(0xFFB388FF),
      Color(0xFF6A1B9A), Color(0xFF9C27B0), Color(0xFFE1BEE7),
    ]),
    ColorPalette('Berry', [
      Color(0xFFAD1457), Color(0xFFEC407A), Color(0xFFF06292),
      Color(0xFF880E4F), Color(0xFFD81B60), Color(0xFFF48FB1),
    ]),
  ];
}

/// A named set of colors shown as a "recommended palette" card.
class ColorPalette {
  const ColorPalette(this.name, this.colors);

  final String name;
  final List<Color> colors;
}
