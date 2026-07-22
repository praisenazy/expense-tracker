import 'package:flutter_test/flutter_test.dart';
import 'package:my_project/core/theme/app_icons.dart';

void main() {
  test('every catalogue emoji is a single code point', () {
    for (final emoji in AppIcons.choices) {
      expect(emoji.runes.length, 1, reason: 'multi-codepoint emoji: $emoji');
    }
  });

  test('typing "chocolate" suggests chocolate then related sweets', () {
    final s = AppIcons.suggest('chocolate');
    expect(s.first, '🍫');
    expect(s.length, 6);
    // The rest should be topically related (sweets), not a random burger.
    expect(s.contains('🍔'), isFalse);
  });

  test('typing "cookie" surfaces the cookie emoji', () {
    expect(AppIcons.suggest('cookie').first, '🍪');
  });

  test('prefix + plural matching works', () {
    expect(AppIcons.suggest('choc').first, '🍫'); // prefix
    expect(AppIcons.suggest('cookies').first, '🍪'); // plural
  });

  test('cooking ingredients now resolve', () {
    expect(AppIcons.suggest('onions').first, '🧅');
    expect(AppIcons.suggest('pepper').first, '🫑');
    expect(AppIcons.suggest('tomato').first, '🍅');
    expect(AppIcons.suggest('beans').first, '🫘');
  });
}
