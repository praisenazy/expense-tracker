/// Emoji used as category "icons". They are stored on a category as a single
/// Unicode code point (int) and rebuilt with `String.fromCharCode`.
///
/// Only SINGLE-code-point emoji are listed here so they round-trip cleanly
/// through the stored code point (no variation selectors / ZWJ sequences).
///
/// Each entry is `(emoji, group, keywords)`. The [group] lets the suggester
/// fill the remaining slots with *related* emoji: typing "chocolate" surfaces
/// 🍫 first, then the rest of the sweets group (🍪🍬🍭🧁🍰…) — never a random
/// burger. Keywords are what a typed category name is matched against.
class AppIcons {
  AppIcons._();

  /// Shown when a category's stored emoji can't be resolved.
  static const String fallback = '📦';

  /// The code point of an emoji (for storing on a category).
  static int codePointOf(String emoji) => emoji.runes.first;

  /// The full emoji catalogue: `(emoji, group, keywords)`.
  static const List<(String, String, List<String>)> _catalogue = [
    // ---- Food (meals) ----
    ('🍔', 'food', ['food', 'burger', 'hamburger', 'eat', 'meal', 'lunch', 'dinner', 'fastfood']),
    ('🍕', 'food', ['pizza', 'food', 'italian', 'slice']),
    ('🍟', 'food', ['fries', 'chips', 'fastfood', 'snack', 'food']),
    ('🌭', 'food', ['hotdog', 'sausage', 'food', 'fastfood']),
    ('🥪', 'food', ['sandwich', 'sub', 'food', 'lunch']),
    ('🌮', 'food', ['taco', 'mexican', 'food']),
    ('🌯', 'food', ['burrito', 'wrap', 'mexican', 'food']),
    ('🥙', 'food', ['shawarma', 'kebab', 'pita', 'wrap', 'food']),
    ('🍝', 'food', ['pasta', 'spaghetti', 'noodles', 'food', 'italian']),
    ('🍜', 'food', ['noodles', 'ramen', 'soup', 'food']),
    ('🍲', 'food', ['soup', 'stew', 'pot', 'food']),
    ('🍛', 'food', ['curry', 'rice', 'food']),
    ('🍚', 'food', ['rice', 'food', 'jollof']),
    ('🍣', 'food', ['sushi', 'food', 'japanese']),
    ('🍱', 'food', ['bento', 'lunch', 'food', 'japanese']),
    ('🍤', 'food', ['shrimp', 'prawn', 'seafood', 'food']),
    ('🥘', 'food', ['paella', 'food', 'pan', 'stew']),
    ('🥗', 'food', ['salad', 'healthy', 'food', 'veg', 'vegetables']),
    ('🍳', 'food', ['egg', 'breakfast', 'fry', 'food']),
    ('🥞', 'food', ['pancakes', 'breakfast', 'food']),
    ('🧇', 'food', ['waffle', 'breakfast', 'food']),
    ('🥓', 'food', ['bacon', 'meat', 'breakfast', 'food']),
    ('🍗', 'food', ['chicken', 'meat', 'poultry', 'food']),
    ('🥩', 'food', ['meat', 'steak', 'beef', 'food', 'protein']),
    ('🧀', 'food', ['cheese', 'dairy', 'food']),
    ('🥚', 'food', ['egg', 'eggs', 'food']),
    ('🍞', 'food', ['bread', 'loaf', 'bakery', 'food']),
    ('🥖', 'food', ['baguette', 'bread', 'bakery', 'food']),
    ('🥐', 'food', ['croissant', 'pastry', 'bakery', 'breakfast', 'food']),
    ('🥨', 'food', ['pretzel', 'snack', 'food']),
    ('🌽', 'food', ['corn', 'maize', 'vegetable', 'food']),
    ('🥕', 'food', ['carrot', 'vegetable', 'food', 'veg']),
    ('🥔', 'food', ['potato', 'vegetable', 'food']),
    ('🍄', 'food', ['mushroom', 'food']),
    ('🥜', 'food', ['peanut', 'nuts', 'groundnut', 'food']),

    // ---- Sweets & desserts ----
    ('🍫', 'sweets', ['chocolate', 'choc', 'cocoa', 'candy', 'sweet', 'dessert', 'food']),
    ('🍪', 'sweets', ['cookie', 'biscuit', 'sweet', 'snack', 'dessert', 'food']),
    ('🍬', 'sweets', ['candy', 'sweet', 'sweets', 'dessert']),
    ('🍭', 'sweets', ['lollipop', 'candy', 'sweet', 'sweets']),
    ('🧁', 'sweets', ['cupcake', 'muffin', 'cake', 'sweet', 'dessert']),
    ('🍰', 'sweets', ['cake', 'dessert', 'sweet', 'slice']),
    ('🎂', 'sweets', ['birthday', 'cake', 'celebration', 'dessert']),
    ('🍩', 'sweets', ['donut', 'doughnut', 'dessert', 'snack', 'sweet']),
    ('🍦', 'sweets', ['icecream', 'ice cream', 'dessert', 'cone', 'sweet']),
    ('🍨', 'sweets', ['icecream', 'ice cream', 'dessert', 'sweet']),
    ('🍧', 'sweets', ['shaved ice', 'dessert', 'icecream', 'sweet']),
    ('🥧', 'sweets', ['pie', 'dessert', 'sweet', 'food']),
    ('🍮', 'sweets', ['pudding', 'custard', 'dessert', 'sweet']),
    ('🍯', 'sweets', ['honey', 'sweet', 'jar']),
    ('🍿', 'sweets', ['popcorn', 'snack', 'movie', 'cinema']),

    // ---- Fruit ----
    ('🍎', 'fruit', ['apple', 'fruit', 'food', 'healthy']),
    ('🍌', 'fruit', ['banana', 'fruit', 'food']),
    ('🍊', 'fruit', ['orange', 'citrus', 'fruit', 'food']),
    ('🍋', 'fruit', ['lemon', 'lime', 'citrus', 'fruit']),
    ('🍉', 'fruit', ['watermelon', 'melon', 'fruit', 'food']),
    ('🍇', 'fruit', ['grapes', 'fruit', 'food']),
    ('🍓', 'fruit', ['strawberry', 'berry', 'fruit', 'food']),
    ('🍒', 'fruit', ['cherry', 'cherries', 'fruit', 'food']),
    ('🍑', 'fruit', ['peach', 'fruit', 'food']),
    ('🥭', 'fruit', ['mango', 'fruit', 'food']),
    ('🍍', 'fruit', ['pineapple', 'fruit', 'food']),
    ('🥥', 'fruit', ['coconut', 'fruit', 'food']),
    ('🥑', 'fruit', ['avocado', 'fruit', 'healthy', 'food']),

    // ---- Drinks ----
    ('☕', 'drink', ['coffee', 'cafe', 'tea', 'drink', 'espresso']),
    ('🍵', 'drink', ['tea', 'matcha', 'drink']),
    ('🥤', 'drink', ['drink', 'soda', 'juice', 'cup', 'softdrink']),
    ('🧃', 'drink', ['juice', 'box', 'drink']),
    ('🍺', 'drink', ['beer', 'bar', 'drink', 'alcohol', 'pub']),
    ('🍷', 'drink', ['wine', 'drink', 'alcohol']),
    ('🍸', 'drink', ['cocktail', 'drink', 'alcohol', 'bar']),
    ('🍹', 'drink', ['cocktail', 'tropical', 'drink', 'bar']),
    ('🥂', 'drink', ['champagne', 'cheers', 'celebration', 'drink']),
    ('🍾', 'drink', ['champagne', 'bottle', 'celebration', 'drink']),
    ('🥛', 'drink', ['milk', 'drink', 'dairy']),
    ('🧉', 'drink', ['mate', 'drink']),

    // ---- Groceries / shopping ----
    ('🛒', 'shopping', ['groceries', 'grocery', 'shopping', 'supermarket', 'cart']),
    ('👜', 'shopping', ['bag', 'handbag', 'shopping', 'buy', 'purse']),
    ('🎀', 'shopping', ['gift', 'bow', 'wrap']),
    ('🏬', 'shopping', ['mall', 'store', 'shopping', 'department']),
    ('🏪', 'shopping', ['store', 'shop', 'convenience', 'market', 'sell']),

    // ---- Fashion & beauty ----
    ('👕', 'fashion', ['clothes', 'clothing', 'fashion', 'shirt', 'wear', 'tshirt']),
    ('👗', 'fashion', ['dress', 'fashion', 'clothes', 'wear']),
    ('👖', 'fashion', ['jeans', 'trousers', 'pants', 'clothes']),
    ('👟', 'fashion', ['shoes', 'sneakers', 'footwear', 'trainers']),
    ('👠', 'fashion', ['heels', 'shoes', 'fashion']),
    ('🧥', 'fashion', ['coat', 'jacket', 'clothes', 'fashion']),
    ('🧢', 'fashion', ['cap', 'hat', 'clothes']),
    ('👓', 'fashion', ['glasses', 'eyewear', 'spectacles']),
    ('💍', 'fashion', ['ring', 'jewelry', 'wedding', 'diamond']),
    ('⌚', 'fashion', ['watch', 'clock', 'accessory']),
    ('💄', 'beauty', ['makeup', 'beauty', 'cosmetics', 'lipstick']),
    ('💅', 'beauty', ['nails', 'manicure', 'beauty', 'salon']),
    ('💇', 'beauty', ['haircut', 'hair', 'salon', 'barber', 'beauty']),
    ('🧴', 'beauty', ['lotion', 'skincare', 'beauty', 'cream']),
    ('🧼', 'beauty', ['soap', 'toiletries', 'hygiene']),

    // ---- Transport ----
    ('🚗', 'transport', ['car', 'transport', 'drive', 'ride', 'vehicle', 'auto']),
    ('🚕', 'transport', ['taxi', 'cab', 'uber', 'bolt', 'ride']),
    ('🚙', 'transport', ['suv', 'car', 'jeep', 'transport']),
    ('🚌', 'transport', ['bus', 'transport', 'commute']),
    ('🚎', 'transport', ['bus', 'trolley', 'transport']),
    ('🚐', 'transport', ['van', 'shuttle', 'transport']),
    ('🚚', 'transport', ['truck', 'delivery', 'transport', 'moving']),
    ('🛵', 'transport', ['scooter', 'okada', 'delivery', 'ride', 'moped', 'motorcycle', 'bike']),
    ('🚲', 'transport', ['bike', 'bicycle', 'cycling', 'ride']),
    ('🚆', 'transport', ['train', 'transport', 'rail', 'commute']),
    ('🚇', 'transport', ['metro', 'subway', 'train', 'transport']),
    ('⛽', 'transport', ['fuel', 'gas', 'petrol', 'diesel', 'car']),
    ('🛫', 'travel', ['flight', 'plane', 'travel', 'trip', 'airplane', 'airfare', 'departure']),
    ('🚢', 'travel', ['ship', 'boat', 'cruise', 'travel', 'ferry']),
    ('⛵', 'travel', ['boat', 'sail', 'travel']),

    // ---- Travel / leisure ----
    ('🏨', 'travel', ['hotel', 'stay', 'travel', 'accommodation', 'lodging']),
    ('🧳', 'travel', ['luggage', 'travel', 'trip', 'vacation', 'suitcase']),
    ('🌴', 'travel', ['vacation', 'holiday', 'beach', 'travel', 'palm', 'island']),
    ('🌍', 'travel', ['world', 'travel', 'trip', 'abroad', 'globe', 'map']),
    ('⛺', 'travel', ['camping', 'camp', 'outdoor', 'tent']),
    ('🎡', 'travel', ['fair', 'amusement', 'park', 'fun']),

    // ---- Home / bills / utilities ----
    ('🏠', 'home', ['home', 'house', 'rent', 'mortgage', 'housing']),
    ('🏡', 'home', ['home', 'house', 'rent', 'housing']),
    ('🪑', 'home', ['furniture', 'chair', 'sofa', 'couch', 'bed', 'home', 'decor']),
    ('🧾', 'bills', ['bill', 'bills', 'receipt', 'invoice', 'tax']),
    ('⚡', 'bills', ['electricity', 'power', 'energy', 'bill', 'nepa']),
    ('💡', 'bills', ['light', 'electricity', 'bulb', 'power']),
    ('📶', 'bills', ['wifi', 'internet', 'data', 'signal', 'network']),
    ('🌐', 'bills', ['internet', 'web', 'data', 'network']),
    ('💧', 'bills', ['water', 'bill', 'utility']),
    ('🚿', 'bills', ['shower', 'water', 'plumbing', 'bathroom']),
    ('📱', 'bills', ['phone', 'mobile', 'airtime', 'call', 'recharge', 'telephone']),
    ('🔥', 'bills', ['gas', 'heating', 'fire', 'cooking']),
    ('🧺', 'home', ['laundry', 'washing', 'clothes', 'basket']),
    ('🧹', 'home', ['cleaning', 'clean', 'housekeeping', 'broom']),
    ('🧽', 'home', ['cleaning', 'sponge', 'clean']),
    ('🔧', 'home', ['repair', 'tools', 'fix', 'maintenance', 'wrench']),
    ('🔨', 'home', ['hammer', 'repair', 'tools', 'fix', 'diy']),
    ('🪛', 'home', ['screwdriver', 'repair', 'tools', 'fix']),
    ('🔌', 'home', ['plug', 'electricity', 'charge', 'power']),
    ('🪴', 'home', ['plant', 'home', 'garden', 'decor']),

    // ---- Entertainment / hobbies ----
    ('🎬', 'entertainment', ['movie', 'cinema', 'film', 'entertainment']),
    ('🎥', 'entertainment', ['movie', 'camera', 'film', 'video']),
    ('🎮', 'entertainment', ['game', 'gaming', 'games', 'console', 'arcade']),
    ('🎵', 'entertainment', ['music', 'song', 'audio', 'note']),
    ('🎶', 'entertainment', ['music', 'songs', 'audio']),
    ('🎧', 'entertainment', ['music', 'headphones', 'podcast', 'audio']),
    ('📺', 'entertainment', ['tv', 'television', 'netflix', 'streaming', 'subscription']),
    ('🎫', 'entertainment', ['ticket', 'event', 'concert', 'show']),
    ('🎭', 'entertainment', ['theatre', 'theater', 'drama', 'show']),
    ('🎨', 'entertainment', ['art', 'paint', 'design', 'hobby', 'drawing']),
    ('🎸', 'entertainment', ['guitar', 'music', 'instrument', 'band']),
    ('🎹', 'entertainment', ['piano', 'keyboard', 'music', 'instrument']),
    ('🎤', 'entertainment', ['karaoke', 'mic', 'music', 'singing', 'concert']),
    ('🎲', 'entertainment', ['dice', 'game', 'board', 'gambling']),
    ('📷', 'entertainment', ['camera', 'photo', 'photography', 'pictures']),
    ('🎳', 'entertainment', ['bowling', 'game', 'fun']),

    // ---- Sports & fitness ----
    ('⚽', 'sports', ['football', 'soccer', 'sport', 'sports']),
    ('🏀', 'sports', ['basketball', 'sport', 'sports']),
    ('🏈', 'sports', ['football', 'american', 'sport', 'sports']),
    ('🎾', 'sports', ['tennis', 'sport', 'sports']),
    ('🏐', 'sports', ['volleyball', 'sport', 'sports']),
    ('🏓', 'sports', ['pingpong', 'tabletennis', 'sport', 'sports']),
    ('🏸', 'sports', ['badminton', 'sport', 'sports']),
    ('🥊', 'sports', ['boxing', 'gloves', 'sport', 'fight']),
    ('⛳', 'sports', ['golf', 'sport', 'sports']),
    ('🎯', 'sports', ['darts', 'target', 'goal', 'aim']),
    ('💪', 'fitness', ['gym', 'weights', 'workout', 'fitness', 'lifting', 'muscle', 'strength']),
    ('🤸', 'fitness', ['gym', 'fitness', 'workout', 'exercise', 'gymnastics']),
    ('🧘', 'fitness', ['yoga', 'wellness', 'meditation', 'relax', 'mindfulness']),
    ('🏊', 'fitness', ['swim', 'swimming', 'pool', 'sport']),
    ('🚴', 'fitness', ['cycling', 'bike', 'spin', 'fitness']),
    ('🏃', 'fitness', ['running', 'run', 'jog', 'fitness', 'exercise']),

    // ---- Health / medical ----
    ('💗', 'health', ['health', 'love', 'heart', 'care', 'wellbeing']),
    ('🏥', 'health', ['hospital', 'medical', 'health', 'clinic']),
    ('💊', 'health', ['medicine', 'pharmacy', 'drugs', 'pills', 'medication']),
    ('💉', 'health', ['vaccine', 'injection', 'medical', 'health', 'shot']),
    ('🩺', 'health', ['doctor', 'checkup', 'medical', 'health', 'stethoscope']),
    ('🦷', 'health', ['dentist', 'tooth', 'dental', 'health']),
    ('🩹', 'health', ['bandage', 'firstaid', 'health', 'care']),

    // ---- Education / kids / pets ----
    ('🎓', 'education', ['school', 'education', 'tuition', 'study', 'college', 'graduation']),
    ('📚', 'education', ['books', 'study', 'education', 'reading', 'school']),
    ('📖', 'education', ['book', 'reading', 'study']),
    ('📝', 'education', ['pencil', 'pen', 'writing', 'school', 'stationery', 'notes', 'exam']),
    ('🎒', 'education', ['backpack', 'school', 'bag', 'student']),
    ('🧮', 'education', ['abacus', 'math', 'calculation', 'school']),
    ('🍼', 'kids', ['baby', 'kids', 'child', 'children', 'bottle']),
    ('🧸', 'kids', ['toy', 'kids', 'children', 'teddy']),
    ('🪁', 'kids', ['kite', 'kids', 'play', 'fun']),
    ('👶', 'kids', ['baby', 'infant', 'child', 'kids']),
    ('🐶', 'pets', ['dog', 'pet', 'pets', 'animal', 'puppy']),
    ('🐱', 'pets', ['cat', 'pet', 'pets', 'animal', 'kitten']),
    ('🐟', 'pets', ['fish', 'pet', 'aquarium', 'animal']),
    ('🐾', 'pets', ['paw', 'pet', 'pets', 'animal', 'vet']),

    // ---- Money / income / work ----
    ('💰', 'money', ['salary', 'income', 'money', 'pay', 'cash', 'wage', 'moneybag']),
    ('💵', 'money', ['cash', 'money', 'income', 'dollar', 'notes']),
    ('💸', 'money', ['spending', 'money', 'expense', 'cash', 'flying']),
    ('💳', 'money', ['card', 'credit', 'debit', 'payment', 'atm']),
    ('🏦', 'money', ['bank', 'banking', 'savings', 'account']),
    ('🏧', 'money', ['atm', 'cash', 'withdraw', 'bank']),
    ('📈', 'money', ['invest', 'investment', 'stocks', 'trading', 'crypto', 'profit', 'growth']),
    ('📉', 'money', ['loss', 'stocks', 'trading', 'decline']),
    ('🪙', 'money', ['coin', 'savings', 'crypto', 'money', 'change']),
    ('💎', 'money', ['diamond', 'valuable', 'asset', 'wealth']),
    ('🧾', 'money', ['receipt', 'expense', 'bill', 'invoice']),
    ('💼', 'work', ['work', 'job', 'business', 'office', 'briefcase', 'salary']),
    ('💻', 'work', ['laptop', 'computer', 'tech', 'content', 'freelance', 'work', 'pc']),
    ('📊', 'work', ['chart', 'report', 'business', 'analytics', 'stats']),
    ('🤝', 'work', ['deal', 'affiliate', 'partner', 'commission', 'handshake']),
    ('🚀', 'work', ['startup', 'launch', 'business', 'growth', 'rocket']),

    // ---- Gifts / giving / misc ----
    ('🎁', 'gift', ['gift', 'present', 'reward', 'birthday']),
    ('🎉', 'gift', ['party', 'celebration', 'fun', 'event']),
    ('🌸', 'gift', ['flower', 'flowers', 'plant', 'gift']),
    ('💐', 'gift', ['bouquet', 'flowers', 'gift']),
    ('⛪', 'misc', ['church', 'religion', 'tithe', 'offering', 'donation']),
    ('🕌', 'misc', ['mosque', 'religion', 'offering', 'donation']),
    ('🤲', 'misc', ['charity', 'donation', 'giving', 'help', 'alms']),
    ('📦', 'misc', ['package', 'delivery', 'shipping', 'box', 'parcel']),
    ('📮', 'misc', ['post', 'mail', 'delivery']),
    ('⭐', 'misc', ['star', 'favourite', 'other', 'general']),
  ];

  /// Every selectable emoji (derived from the catalogue).
  static final List<String> choices = [
    for (final (emoji, _, _) in _catalogue) emoji,
  ];

  /// Default icon row shown for an EXPENSE category before the user types a
  /// name (spending-related).
  static const List<String> expenseDefaults = [
    '🍔', '🛒', '🚗', '🏠', '💗', '🎬',
  ];

  /// Default icon row shown for an INCOME category before the user types a
  /// name (earning-related), so the two sides start from different icons.
  static const List<String> incomeDefaults = [
    '💰', '💵', '📈', '💼', '🏦', '🎁',
  ];

  /// Suggests up to [count] emoji that best match a category [query] name.
  ///
  /// Strategy:
  ///  1. Score every emoji by how well its keywords match the typed words.
  ///  2. Return the highest-scoring matches first.
  ///  3. Fill the remaining slots with emoji from the *same group* as the best
  ///     match (so "chocolate" → 🍫 then the rest of the sweets), then finally
  ///     from the general catalogue if still short.
  ///
  /// [fallback] is the set used when the query is empty (or matches nothing) —
  /// pass [incomeDefaults]/[expenseDefaults] so each side starts differently.
  static List<String> suggest(
    String query, {
    int count = 6,
    List<String>? fallback,
  }) {
    final base = fallback ?? choices;
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return base.take(count).toList();

    // Split the name into words so "ice cream run" matches on any word.
    final words = q.split(RegExp(r'[^a-z0-9]+')).where((w) => w.isNotEmpty);

    final scored = <(String, String, int)>[]; // (emoji, group, score)
    for (final (emoji, group, keywords) in _catalogue) {
      var best = 0;
      for (final keyword in keywords) {
        for (final w in words) {
          best = _score(w, keyword) > best ? _score(w, keyword) : best;
        }
        // Also match the whole query against multi-word keywords.
        final whole = _score(q, keyword);
        if (whole > best) best = whole;
      }
      if (best > 0) scored.add((emoji, group, best));
    }
    // Highest score first; ties keep catalogue order (stable).
    scored.sort((a, b) => b.$3.compareTo(a.$3));

    final result = <String>[];
    for (final (emoji, _, _) in scored) {
      if (!result.contains(emoji)) result.add(emoji);
      if (result.length >= count) return result;
    }

    // Fill from the best match's group so the row stays topically related.
    if (scored.isNotEmpty) {
      final topGroup = scored.first.$2;
      for (final (emoji, group, _) in _catalogue) {
        if (result.length >= count) break;
        if (group == topGroup && !result.contains(emoji)) result.add(emoji);
      }
    }

    // Pad from the side-appropriate defaults, then the general catalogue.
    for (final emoji in [...base, ...choices]) {
      if (result.length >= count) break;
      if (!result.contains(emoji)) result.add(emoji);
    }
    return result.take(count).toList();
  }

  /// How strongly a single typed [word] matches a [keyword]. Handles simple
  /// plurals ("cookies" → "cookie") and prefix typing ("choc" → "chocolate").
  static int _score(String word, String keyword) {
    if (word.isEmpty) return 0;
    final w = word.endsWith('s') && word.length > 3
        ? word.substring(0, word.length - 1)
        : word;

    if (word == keyword || w == keyword) return 4; // exact
    if (word.length >= 3 && keyword.startsWith(word)) return 3; // "choc" → chocolate
    if (w.length >= 3 && keyword.startsWith(w)) return 3;
    if (keyword.length >= 3 && word.startsWith(keyword)) return 3;
    if (word.length >= 4 && keyword.contains(word)) return 2; // substring
    if (keyword.length >= 4 && word.contains(keyword)) return 2;
    return 0;
  }
}
