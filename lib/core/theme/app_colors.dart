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

  // ---- One fixed color per spending category ----
  // Used by the icon on each row, the category picker, AND the pie chart,
  // so a category always looks the same everywhere.
  static const Color food = Color(0xFFFF7043); // deep orange
  static const Color transport = Color(0xFF42A5F5); // blue
  static const Color bills = Color(0xFFAB47BC); // purple
  static const Color entertainment = Color(0xFFEC407A); // pink
  static const Color health = Color(0xFF26A69A); // teal
  static const Color others = Color(0xFF78909C); // blue-grey
}
