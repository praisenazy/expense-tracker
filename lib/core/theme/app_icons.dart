import 'package:flutter/material.dart';

/// Curated set of icons users can pick for a category.
///
/// IMPORTANT: categories store their icon as a number (codePoint) and we
/// rebuild the IconData at runtime. Flutter strips ("tree-shakes") icons it
/// doesn't see referenced as const in code, which would make rebuilt icons
/// show as empty boxes. Listing every choice here as a const IconData — and
/// rendering them in the picker — keeps them in the build so they always show.
class AppIcons {
  AppIcons._();

  /// Used when a category's stored icon can't be found.
  static const IconData fallback = Icons.category_rounded;

  /// All selectable icons (income sources + expense types + general).
  static const List<IconData> choices = [
    // Money / income
    Icons.payments_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.card_giftcard_rounded,
    Icons.trending_up_rounded,
    Icons.work_rounded,
    Icons.storefront_rounded,
    Icons.laptop_mac_rounded,
    Icons.handshake_rounded,
    Icons.attach_money_rounded,
    Icons.savings_rounded,
    Icons.real_estate_agent_rounded,
    Icons.redeem_rounded,
    // Expenses / life
    Icons.restaurant_rounded,
    Icons.local_cafe_rounded,
    Icons.directions_bus_rounded,
    Icons.local_gas_station_rounded,
    Icons.receipt_long_rounded,
    Icons.bolt_rounded,
    Icons.movie_rounded,
    Icons.sports_esports_rounded,
    Icons.favorite_rounded,
    Icons.medical_services_rounded,
    Icons.shopping_cart_rounded,
    Icons.checkroom_rounded,
    Icons.home_rounded,
    Icons.school_rounded,
    Icons.flight_rounded,
    Icons.pets_rounded,
    Icons.phone_iphone_rounded,
    Icons.fitness_center_rounded,
    Icons.child_care_rounded,
    Icons.category_rounded,
  ];

  /// Rebuilds an IconData from a stored codePoint, falling back if unknown.
  static IconData fromCodePoint(int codePoint) {
    for (final icon in choices) {
      if (icon.codePoint == codePoint) return icon;
    }
    return fallback;
  }
}
