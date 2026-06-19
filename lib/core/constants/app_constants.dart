/// App-wide constants: Hive identifiers, spacing, and Hive type IDs.
///
/// Keeping these in one place avoids "magic strings"/numbers scattered around
/// the code. If you ever rename a box or change spacing, you do it here once.
class AppConstants {
  AppConstants._(); // private constructor: this class is never instantiated.

  // ---- Hive box names (think of a "box" like a table/collection) ----
  static const String transactionsBox = 'transactions_box';
  static const String categoriesBox = 'categories_box';
  static const String settingsBox = 'settings_box';

  // ---- Keys used inside the settings box ----
  static const String themeModeKey = 'theme_mode';
  static const String removedLegacyOthersKey = 'removed_legacy_others_v1';

  // ---- Hive type IDs (each @HiveType model needs a UNIQUE id) ----
  // Never reuse or reorder these once data has been saved on a device.
  static const int transactionTypeId = 0;
  static const int transactionTypeEnumId = 1;
  static const int categoryTypeId = 3;

  // ---- Spacing scale (consistent padding/margins across the UI) ----
  static const double spaceXs = 4;
  static const double spaceS = 8;
  static const double spaceM = 16;
  static const double spaceL = 24;
  static const double spaceXl = 32;

  static const double cardRadius = 16;

  /// Max categories allowed. At this limit the user must delete one they added
  /// before creating a new one.
  static const int maxCategories = 12;
}
