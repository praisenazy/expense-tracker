import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction_type.dart';
import '../../providers/category_providers.dart';
import 'category_color_preview_screen.dart';
import 'widgets/color_wheel_picker.dart';
import 'widgets/sparkle_decoration.dart';

/// Create or edit a single category (name + icon + color) with a rich picker:
/// recommended palettes, an "all colors" grid, and a custom color wheel.
class CategoryEditorScreen extends ConsumerStatefulWidget {
  const CategoryEditorScreen({super.key, required this.kind, this.existing});

  final TransactionType kind;
  final Category? existing;

  @override
  ConsumerState<CategoryEditorScreen> createState() =>
      _CategoryEditorScreenState();
}

class _CategoryEditorScreenState extends ConsumerState<CategoryEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late int _iconCodePoint;
  late int _colorValue;

  bool _customTab = false;
  int? _selectedPaletteIndex;

  // Horizontal scroll of the recommended-palette row + the per-card stride
  // (card width + gap), so the pagination dots and "scroll into view" can track
  // which palette is active.
  final ScrollController _paletteScroll = ScrollController();
  double _paletteStride = 74;
  int _palettePage = 0;

  // True once the user taps an icon — stops name-based auto-suggestion from
  // overriding their choice.
  bool _iconManuallyPicked = false;

  // Gap between recommended-palette cards.
  static const double _palGap = 10;
  static const double _palPad = 8;

  bool get _isEditing => widget.existing != null;
  bool get _isIncome => (widget.existing?.kind ?? widget.kind).isIncome;
  Color get _color => Color(_colorValue);
  String get _emoji => String.fromCharCode(_iconCodePoint);

  /// The default icon set for this side (income vs expense).
  List<String> get _iconDefaults =>
      _isIncome ? AppIcons.incomeDefaults : AppIcons.expenseDefaults;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _iconCodePoint = existing?.iconCodePoint ??
        AppIcons.codePointOf(
          (widget.kind.isIncome
                  ? AppIcons.incomeDefaults
                  : AppIcons.expenseDefaults)
              .first,
        );
    _colorValue = existing?.colorValue ?? AppColors.allColors.first.toARGB32();
    // Editing keeps the saved icon; new categories auto-suggest from the name.
    _iconManuallyPicked = existing != null;
  }

  /// Called when the user taps any icon — locks in their choice.
  void _selectIcon(int codePoint) {
    setState(() {
      _iconCodePoint = codePoint;
      _iconManuallyPicked = true;
    });
  }

  /// As the name changes, auto-pick the top suggested icon (until the user
  /// manually chooses one).
  void _onNameChanged(String value) {
    setState(() {
      if (!_iconManuallyPicked) {
        final suggestions =
            AppIcons.suggest(value, count: 6, fallback: _iconDefaults);
        if (suggestions.isNotEmpty) {
          _iconCodePoint = AppIcons.codePointOf(suggestions.first);
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _paletteScroll.dispose();
    super.dispose();
  }

  void _pickColor(Color color, {int? paletteIndex}) {
    setState(() {
      _colorValue = color.toARGB32();
      _selectedPaletteIndex = paletteIndex;
      // Move the pagination dot to the chosen palette.
      if (paletteIndex != null) _palettePage = paletteIndex;
    });
    // Slide the chosen palette card into view so the movement is visible.
    if (paletteIndex != null && _paletteScroll.hasClients) {
      final target = (paletteIndex * _paletteStride).clamp(
        0.0,
        _paletteScroll.position.maxScrollExtent,
      );
      _paletteScroll.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Keeps the pagination dot in sync when the user scrolls the palette row
  /// by hand (rather than tapping a card).
  void _onPaletteScroll() {
    final page = (_paletteScroll.offset / _paletteStride).round().clamp(
      0,
      AppColors.recommendedPalettes.length - 1,
    );
    if (page != _palettePage) setState(() => _palettePage = page);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // For a NEW category, ask whether to keep it in the reusable list or just
    // use it once. Editing preserves the category's existing choice.
    var reusable = widget.existing?.reusable ?? true;
    if (!_isEditing) {
      final choice = await _askSaveToList();
      if (choice == null) return; // dismissed → don't save at all
      reusable = choice;
    }

    final category = Category(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      kind: widget.existing?.kind ?? widget.kind,
      iconCodePoint: _iconCodePoint,
      colorValue: _colorValue,
      reusable: reusable,
    );

    final notifier = ref.read(categoriesProvider.notifier);
    if (_isEditing) {
      await notifier.update(category);
    } else {
      await notifier.add(category);
    }
    if (mounted) Navigator.of(context).pop(category);
  }

  /// Asks whether to keep the new category for reuse (true), use it just once
  /// (false), or cancel (null) — as a bottom sheet.
  Future<bool?> _askSaveToList() {
    final name = _nameController.text.trim();
    final theme = Theme.of(context);
    final accent = _color; // the color the user picked for this category
    // Two-tone gradient in the category's own color family (like the image):
    // the picked color on the left, a hue-shifted sibling on the right.
    final accentHsl = HSLColor.fromColor(accent);
    final gradientEnd = accentHsl
        .withHue((accentHsl.hue + 35) % 360)
        .withLightness((accentHsl.lightness + 0.05).clamp(0.0, 1.0))
        .toColor();
    final gradient = LinearGradient(
      colors: [accent, gradientEnd],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bookmark badge with sparkles.
                SparkleDecoration(
                  height: 92,
                  child: Container(
                    width: 66,
                    height: 66,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.bookmark_rounded, color: accent, size: 30),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Save this category',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    children: [
                      const TextSpan(text: 'Save '),
                      TextSpan(
                        text: '“$name”',
                        style: TextStyle(
                          color: _color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const TextSpan(
                        text: ' to your categories for\nfuture use.',
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 10),
                // Just use once.
                TextButton(
                  onPressed: () => Navigator.of(sheetCtx).pop(false),
                  child: Text(
                    'Use once',
                    style: TextStyle(
                      color: accent,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Save to list (gradient button).
                Material(
                  color: Colors.transparent,
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.of(sheetCtx).pop(true),
                      child: Container(
                        height: 54,
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bookmark_rounded,
                                color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Save to list',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openPreview() async {
    if (!_formKey.currentState!.validate()) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CategoryColorPreviewScreen(
          name: _nameController.text,
          emoji: _emoji,
          color: _color,
        ),
      ),
    );
    if (saved == true) await _save();
  }

  Future<void> _showIconSheet() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          _IconPickerSheet(selectedCodePoint: _iconCodePoint, color: _color),
    );
    if (picked != null) _selectIcon(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(_isEditing ? 'Edit Category' : 'Add Category'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.spaceL,
            AppConstants.spaceS,
            AppConstants.spaceL,
            AppConstants.spaceXl,
          ),
          children: [
            // ---- Icon preview with sparkles + edit pencil ----
            Center(child: _iconPreview()),
            const SizedBox(height: AppConstants.spaceM),

            // ---- Name ----
            Text('Category name', style: theme.textTheme.labelLarge),
            const SizedBox(height: AppConstants.spaceS),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              onChanged: _onNameChanged,
              decoration: InputDecoration(
                hintText: (widget.existing?.kind ?? widget.kind).isIncome
                    ? 'e.g. Salary'
                    : 'e.g. Food',
                suffixIcon: const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Text('😊', style: TextStyle(fontSize: 20)),
                ),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
              ),
              validator: (value) =>
                  (value?.trim() ?? '').isEmpty ? 'Please enter a name' : null,
            ),
            const SizedBox(height: AppConstants.spaceL),

            // ---- Icon row ----
            Text('Icon', style: theme.textTheme.labelLarge),
            const SizedBox(height: AppConstants.spaceS),
            _iconRow(),
            const SizedBox(height: AppConstants.spaceL),

            // ---- Choose Color ----
            Row(
              children: [
                Text(
                  'Choose Color',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                const Text('🎨', style: TextStyle(fontSize: 18)),
              ],
            ),
            const SizedBox(height: AppConstants.spaceM),
            _tabBar(),
            const SizedBox(height: AppConstants.spaceL),

            if (_customTab) ..._customContent() else ..._palettesContent(),

            const SizedBox(height: AppConstants.spaceL),

            // ---- Bottom actions: explicit Cancel / Save (never auto-saves) ----
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.spaceM),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _color,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _save,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(
                      _isEditing ? 'Save Changes' : 'Save Category',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===== Icon preview =====
  Widget _iconPreview() {
    return SparkleDecoration(
      height: 130,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 92,
            height: 92,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.40),
              shape: BoxShape.circle,
            ),
            child: Text(_emoji, style: const TextStyle(fontSize: 44)),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: InkWell(
              onTap: _showIconSheet,
              customBorder: const CircleBorder(),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Icon(Icons.edit_rounded, size: 16, color: _color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== Icon row: 6 emoji suggested from the typed name (+ more) =====
  Widget _iconRow() {
    // Suggestions based on the category name; keep the selected emoji visible.
    final suggestions = AppIcons.suggest(
      _nameController.text,
      count: 6,
      fallback: _iconDefaults,
    );
    final shown = <String>[String.fromCharCode(_iconCodePoint)];
    for (final emoji in suggestions) {
      if (AppIcons.codePointOf(emoji) != _iconCodePoint && shown.length < 6) {
        shown.add(emoji);
      }
    }

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final emoji in shown) _iconCircle(emoji),
          _moreIconsButton(),
        ],
      ),
    );
  }

  Widget _iconCircle(String emoji) {
    final theme = Theme.of(context);
    final isSelected = AppIcons.codePointOf(emoji) == _iconCodePoint;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _selectIcon(AppIcons.codePointOf(emoji)),
        child: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? _color.withValues(alpha: 0.25)
                : theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? _color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 24)),
        ),
      ),
    );
  }

  Widget _moreIconsButton() {
    final theme = Theme.of(context);
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: _showIconSheet,
      child: Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.more_horiz_rounded),
      ),
    );
  }

  // ===== Tabs =====
  Widget _tabBar() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _tab(
            'Palettes',
            Icons.palette_rounded,
            !_customTab,
            () => setState(() => _customTab = false),
          ),
          _tab(
            'Custom',
            Icons.settings_rounded,
            _customTab,
            () => setState(() => _customTab = true),
          ),
        ],
      ),
    );
  }

  Widget _tab(String label, IconData icon, bool active, VoidCallback onTap) {
    final accent = _color; // follows the currently selected category color
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: active ? accent : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: active ? accent : Colors.grey.shade600,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== Palettes tab =====
  List<Widget> _palettesContent() {
    final theme = Theme.of(context);
    return [
      Text(
        'Recommended Palettes',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: AppConstants.spaceS),
      LayoutBuilder(
        builder: (context, constraints) {
          // Size cards so exactly 4 fit; the 5th scrolls into view.
          final cardW = ((constraints.maxWidth - _palGap * 3) / 4).clamp(
            64.0,
            100.0,
          );
          _paletteStride = cardW + _palGap;
          return SizedBox(
            height: 92,
            child: NotificationListener<ScrollNotification>(
              onNotification: (_) {
                _onPaletteScroll();
                return false;
              },
              child: ListView.separated(
                controller: _paletteScroll,
                scrollDirection: Axis.horizontal,
                itemCount: AppColors.recommendedPalettes.length,
                separatorBuilder: (_, _) => const SizedBox(width: _palGap),
                itemBuilder: (context, i) => _paletteCard(i, cardW),
              ),
            ),
          );
        },
      ),
      const SizedBox(height: AppConstants.spaceS),
      _dots(AppColors.recommendedPalettes.length),
      const SizedBox(height: AppConstants.spaceL),
      Text(
        'All Colors',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: AppConstants.spaceM),
      GridView.count(
        crossAxisCount: 6,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [for (final c in AppColors.allColors) _colorDot(c)],
      ),
    ];
  }

  Widget _paletteCard(int index, double width) {
    final palette = AppColors.recommendedPalettes[index];
    final selected = _selectedPaletteIndex == index;
    return GestureDetector(
      onTap: () => _pickColor(palette.colors.first, paletteIndex: index),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(_palPad),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? palette.colors.first
                : Colors.black.withValues(alpha: 0.08),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 2 rows × 3 fixed-size swatches (deterministic height).
            for (var r = 0; r < 2; r++) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var c = 0; c < 3; c++)
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: palette.colors[r * 3 + c],
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              if (r == 0) const SizedBox(height: 5),
            ],
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    palette.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 3),
                  Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: palette.colors.first,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dots(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            width: i == _palettePage ? 18 : 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: i == _palettePage
                  ? _color
                  : _color.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }

  Widget _colorDot(Color color) {
    final isSelected = color.toARGB32() == _colorValue;
    return GestureDetector(
      onTap: () => _pickColor(color),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.transparent,
                width: 3,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
        ),
      ),
    );
  }

  // ===== Custom tab =====
  List<Widget> _customContent() {
    final theme = Theme.of(context);
    return [
      ColorWheelPicker(
        initialColor: _color,
        onChanged: (c) => setState(() {
          _colorValue = c.toARGB32();
          _selectedPaletteIndex = null;
        }),
      ),
      const SizedBox(height: AppConstants.spaceL),
      Text('Preview', style: theme.textTheme.labelLarge),
      const SizedBox(height: AppConstants.spaceS),
      InkWell(
        onTap: _openPreview,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.spaceM),
          decoration: BoxDecoration(
            color: _color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                child: Text(_emoji, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: AppConstants.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _nameController.text.trim().isEmpty
                          ? 'Category'
                          : _nameController.text.trim(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to preview in app',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    ];
  }
}

/// Bottom sheet grid of all selectable icons.
class _IconPickerSheet extends StatelessWidget {
  const _IconPickerSheet({
    required this.selectedCodePoint,
    required this.color,
  });

  final int selectedCodePoint;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppConstants.spaceS),
            child: Text(
              'Choose icon',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 6,
              padding: const EdgeInsets.all(AppConstants.spaceM),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                for (final emoji in AppIcons.choices)
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () =>
                        Navigator.of(context).pop(AppIcons.codePointOf(emoji)),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppIcons.codePointOf(emoji) == selectedCodePoint
                            ? color.withValues(alpha: 0.18)
                            : theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              AppIcons.codePointOf(emoji) == selectedCodePoint
                              ? color
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
