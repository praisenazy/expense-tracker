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
    Icons.credit_card_rounded,
    Icons.account_balance_rounded,
    Icons.volunteer_activism_rounded,
    Icons.emoji_events_rounded,

    // Food & drink
    Icons.restaurant_rounded,
    Icons.restaurant_menu_rounded,
    Icons.fastfood_rounded,
    Icons.local_pizza_rounded,
    Icons.lunch_dining_rounded,
    Icons.ramen_dining_rounded,
    Icons.bakery_dining_rounded,
    Icons.cookie_rounded,
    Icons.icecream_rounded,
    Icons.cake_rounded,
    Icons.local_cafe_rounded,
    Icons.coffee_rounded,
    Icons.local_bar_rounded,
    Icons.emoji_food_beverage_rounded,
    Icons.local_grocery_store_rounded,

    // Transport
    Icons.directions_bus_rounded,
    Icons.directions_car_rounded,
    Icons.local_taxi_rounded,
    Icons.two_wheeler_rounded,
    Icons.directions_bike_rounded,
    Icons.train_rounded,
    Icons.subway_rounded,
    Icons.local_gas_station_rounded,
    Icons.flight_rounded,
    Icons.hotel_rounded,
    Icons.luggage_rounded,
    Icons.beach_access_rounded,

    // Bills / home / utilities
    Icons.receipt_long_rounded,
    Icons.bolt_rounded,
    Icons.lightbulb_rounded,
    Icons.wifi_rounded,
    Icons.water_drop_rounded,
    Icons.phone_iphone_rounded,
    Icons.home_rounded,
    Icons.chair_rounded,
    Icons.local_laundry_service_rounded,
    Icons.cleaning_services_rounded,
    Icons.handyman_rounded,
    Icons.build_rounded,

    // Shopping / lifestyle
    Icons.shopping_bag_rounded,
    Icons.shopping_cart_rounded,
    Icons.checkroom_rounded,
    Icons.diamond_rounded,
    Icons.watch_rounded,
    Icons.spa_rounded,
    Icons.brush_rounded,
    Icons.palette_rounded,
    Icons.local_florist_rounded,

    // Entertainment / hobbies
    Icons.movie_rounded,
    Icons.sports_esports_rounded,
    Icons.videogame_asset_rounded,
    Icons.music_note_rounded,
    Icons.headphones_rounded,
    Icons.tv_rounded,
    Icons.camera_alt_rounded,
    Icons.sports_soccer_rounded,
    Icons.sports_basketball_rounded,
    Icons.sports_tennis_rounded,
    Icons.pool_rounded,
    Icons.fitness_center_rounded,
    Icons.park_rounded,

    // Health / family / education
    Icons.favorite_rounded,
    Icons.health_and_safety_rounded,
    Icons.medical_services_rounded,
    Icons.medication_rounded,
    Icons.vaccines_rounded,
    Icons.local_hospital_rounded,
    Icons.school_rounded,
    Icons.menu_book_rounded,
    Icons.child_care_rounded,
    Icons.pets_rounded,

    // General / work / tech
    Icons.computer_rounded,
    Icons.phone_android_rounded,
    Icons.church_rounded,
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
