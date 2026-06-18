import 'package:intl/intl.dart';

/// Helpers that turn raw values into nicely formatted display strings.
///
/// Defined ONCE here so the whole app shows money and dates the same way.
/// Change the currency symbol or date style in this single file.
class Formatters {
  Formatters._();

  // Built once and reused (cheaper than recreating on every call).

  /// Money in Nigerian Naira, e.g. 2500.5 -> "₦2,500.50".
  static final NumberFormat _currency = NumberFormat.currency(
    symbol: '₦',
    decimalDigits: 2,
  );

  /// Compact money without decimals, e.g. 2500 -> "₦2,500" (used on charts).
  static final NumberFormat _currencyCompact = NumberFormat.currency(
    symbol: '₦',
    decimalDigits: 0,
  );

  static final DateFormat _dayMonthYear = DateFormat('d MMM yyyy'); // 17 Jun 2026
  static final DateFormat _monthYear = DateFormat('MMMM yyyy'); //    June 2026
  static final DateFormat _shortMonth = DateFormat('MMM'); //         Jun

  /// "₦2,500.50"
  static String money(double amount) => _currency.format(amount);

  /// "₦2,500" — no decimals, good for chart labels.
  static String moneyCompact(double amount) => _currencyCompact.format(amount);

  /// "17 Jun 2026"
  static String date(DateTime date) => _dayMonthYear.format(date);

  /// "June 2026" — for the summary screen's month header.
  static String monthYear(DateTime date) => _monthYear.format(date);

  /// "Jun" — for bar-chart axis labels.
  static String shortMonth(DateTime date) => _shortMonth.format(date);
}
