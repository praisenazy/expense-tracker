import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/default_categories.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../../data/models/transaction_type.dart';
import '../../providers/category_providers.dart';
import '../../providers/summary_providers.dart';
import '../../providers/transaction_providers.dart';
import '../categories/category_editor_screen.dart';
import '../categories/widgets/category_limit_sheet.dart';
import 'widgets/app_date_picker.dart';
import 'widgets/category_picker.dart';
import 'widgets/type_toggle.dart';

/// Screen for BOTH adding and editing a transaction.
///
/// Pass nothing -> "Add" mode. Pass an existing transaction -> "Edit" mode
/// (fields are pre-filled and Save updates that record).
class AddEditTransactionScreen extends ConsumerStatefulWidget {
  const AddEditTransactionScreen({super.key, this.existing});

  /// The transaction being edited, or null when adding a new one.
  final Transaction? existing;

  @override
  ConsumerState<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState
    extends ConsumerState<AddEditTransactionScreen> {
  // Accent colors that match the type toggle.
  static const Color _expenseColor = Color(0xFFEF5350);
  static const Color _incomeColor = Color(0xFF4285F4);

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  late TransactionType _type;
  String? _categoryId; // selected category (by id)
  late DateTime _date;

  bool get _isEditing => widget.existing != null;
  Color get _accent => _type.isIncome ? _incomeColor : _expenseColor;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;

    _amountController = TextEditingController(
      text: existing != null ? existing.amount.toString() : '',
    );
    _noteController = TextEditingController(text: existing?.note ?? '');
    _type = existing?.type ?? TransactionType.expense;
    _date = existing?.date ?? _defaultDateForNew();
    _categoryId = existing?.categoryId ?? _smartDefaultCategoryId(_type);
  }

  /// Default date for a NEW transaction: today when viewing the current month,
  /// otherwise a day in the month the user is currently browsing — so adding
  /// while viewing a past month lands the entry in that month (still editable).
  DateTime _defaultDateForNew() {
    final now = DateTime.now();
    final selected = ref.read(selectedMonthProvider); // first day of that month
    if (selected.year == now.year && selected.month == now.month) return now;
    // Keep today's day-of-month, clamped to the selected month's length.
    final lastDay = DateTime(selected.year, selected.month + 1, 0).day;
    return DateTime(selected.year, selected.month, now.day.clamp(1, lastDay));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// A smart default category for a kind: the one the user picks most often
  /// (a good default that most users won't need to change), falling back to the
  /// first available, or null if none exist.
  String? _smartDefaultCategoryId(TransactionType kind) {
    final validIds =
        ref.read(categoriesByKindProvider(kind)).map((c) => c.id).toList();
    if (validIds.isEmpty) return null;

    final counts = <String, int>{};
    for (final t in ref.read(transactionsProvider)) {
      if (t.type == kind && validIds.contains(t.categoryId)) {
        counts[t.categoryId] = (counts[t.categoryId] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return validIds.first;
    final ranked = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ranked.first.key;
  }

  /// Keep the selection valid for the current type (after switching
  /// income/expense, or returning from the editor).
  void _ensureValidSelection() {
    final validIds =
        ref.read(categoriesByKindProvider(_type)).map((c) => c.id).toSet();
    if (_categoryId == null || !validIds.contains(_categoryId)) {
      _categoryId = _smartDefaultCategoryId(_type);
    }
  }

  /// The current net balance across all transactions (income − expense).
  double _netBalance() {
    var net = 0.0;
    for (final t in ref.read(transactionsProvider)) {
      net += t.type.isIncome ? t.amount : -t.amount;
    }
    return net;
  }

  /// The parsed amount currently typed, or null if empty/invalid.
  double? get _typedAmount {
    final parsed = double.tryParse(_amountController.text.trim());
    return (parsed != null && parsed > 0) ? parsed : null;
  }

  /// Up to [max] recent, distinct, non-empty notes to offer as quick chips.
  List<String> _recentNotes({int max = 3}) {
    final seen = <String>{};
    final result = <String>[];
    for (final t in ref.read(transactionsProvider)) {
      final note = t.note?.trim() ?? '';
      final key = note.toLowerCase();
      if (note.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      result.add(note);
      if (result.length >= max) break;
    }
    return result;
  }

  /// Formats an int as a Naira amount with thousands separators, e.g. ₦1,000.
  String _naira(int value) => '₦${value.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (m) => ',',
      )}';

  /// Save button label: shows the amount + type when a valid amount is typed.
  String _saveLabel() {
    final amount = _typedAmount;
    final verb = _isEditing ? 'Update' : 'Save';
    if (amount == null) {
      return _isEditing ? 'Save Changes' : 'Save Transaction';
    }
    final kind = _type.isIncome ? 'Income' : 'Expense';
    return '$verb ${Formatters.money(amount)} $kind';
  }

  /// Tap-to-fill common amounts — faster repeat entry, less friction.
  Widget _quickAmountChips(ThemeData theme) {
    const amounts = [500, 1000, 2000, 5000];
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final a in amounts) _quickChip(a, theme),
        ],
      ),
    );
  }

  Widget _quickChip(int amount, ThemeData theme) {
    final selected = _typedAmount == amount.toDouble();
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() {
          _amountController.text = amount.toString();
          _amountController.selection = TextSelection.collapsed(
            offset: _amountController.text.length,
          );
        }),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected
                ? _accent.withValues(alpha: 0.15)
                : theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? _accent : Colors.transparent,
            ),
          ),
          child: Text(
            _naira(amount),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? _accent : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  /// "Balance after this: ₦X" — instant feedback on how the entry affects the
  /// wallet (transparency + control). Only shown once a valid amount is typed.
  Widget _balanceAfterLine(ThemeData theme) {
    final amount = _typedAmount;
    if (amount == null) return const SizedBox.shrink();

    // When editing, remove the existing entry from the net first so the preview
    // reflects the *edited* value, not a double count.
    var net = _netBalance();
    final existing = widget.existing;
    if (existing != null) {
      net -= existing.type.isIncome ? existing.amount : -existing.amount;
    }
    final after = net + (_type.isIncome ? amount : -amount);
    final negative = after < 0;

    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 6),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 6),
          Text(
            'Balance after this: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          Text(
            '${negative ? '-' : ''}${Formatters.money(after.abs())}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: negative
                  ? _expenseColor
                  : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// Recent notes offered as tappable chips (recognition over recall). Hidden
  /// once the user starts typing their own note.
  Widget _noteSuggestions(ThemeData theme) {
    if (_noteController.text.trim().isNotEmpty) {
      return const SizedBox.shrink();
    }
    final notes = _recentNotes();
    if (notes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.spaceS, left: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [for (final n in notes) _suggestChip(n, theme)],
      ),
    );
  }

  Widget _suggestChip(String note, ThemeData theme) {
    return GestureDetector(
      onTap: () => setState(() {
        _noteController.text = note;
        _noteController.selection = TextSelection.collapsed(
          offset: _noteController.text.length,
        );
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_rounded,
              size: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 5),
            Text(
              note,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the editor to create a new category, then selects it. If this side
  /// is at the limit, the user is first asked to delete one they added.
  Future<void> _openNewCategory() async {
    final atLimit = ref.read(categoriesByKindProvider(_type)).length >=
        AppConstants.maxCategoriesPerKind;
    if (atLimit) {
      final madeRoom = await showCategoryLimitSheet(context, _type);
      if (madeRoom != true || !mounted) return;
    }

    final created = await Navigator.of(context).push<Category>(
      MaterialPageRoute(builder: (_) => CategoryEditorScreen(kind: _type)),
    );
    if (!mounted) return;
    setState(() {
      if (created != null) {
        _categoryId = created.id;
      } else {
        _ensureValidSelection();
      }
    });
  }

  /// Long-press a category chip to edit or delete it. Only the user's own
  /// (custom) categories can be changed — the built-in defaults are locked.
  Future<void> _onCategoryLongPress(Category category) async {
    if (isDefaultCategory(category)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Default categories can't be edited or deleted."),
        ),
      );
      return;
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: category.color.withValues(alpha: 0.25),
                child: Text(category.emoji, style: const TextStyle(fontSize: 18)),
              ),
              title: Text(
                category.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Edit'),
              onTap: () => Navigator.of(sheetContext).pop('edit'),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: Theme.of(sheetContext).colorScheme.error,
              ),
              title: Text(
                'Delete',
                style: TextStyle(
                  color: Theme.of(sheetContext).colorScheme.error,
                ),
              ),
              onTap: () => Navigator.of(sheetContext).pop('delete'),
            ),
            const SizedBox(height: AppConstants.spaceS),
          ],
        ),
      ),
    );
    if (!mounted) return;

    if (action == 'edit') {
      final updated = await Navigator.of(context).push<Category>(
        MaterialPageRoute(
          builder: (_) => CategoryEditorScreen(
            kind: category.kind,
            existing: category,
          ),
        ),
      );
      if (!mounted) return;
      setState(() {
        if (updated != null) _categoryId = updated.id;
        _ensureValidSelection();
      });
    } else if (action == 'delete') {
      await _deleteCategory(category);
    }
  }

  Future<void> _deleteCategory(Category category) async {
    // Never orphan transactions: block deleting a category that's in use.
    final inUse = ref
        .read(transactionsProvider)
        .where((t) => t.categoryId == category.id)
        .length;
    if (inUse > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Can't delete \"${category.name}\" — it's used by $inUse "
            "transaction${inUse == 1 ? '' : 's'}.",
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text('"${category.name}" will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref.read(categoriesProvider.notifier).remove(category.id);
    if (!mounted) return;
    setState(_ensureValidSelection);
  }

  Future<void> _pickDate() async {
    final picked = await showAppDatePicker(
      context: context,
      initialDate: _date,
      accent: _accent, // red for Expense, blue for Income
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    final amount = double.parse(_amountController.text.trim());
    final note = _noteController.text.trim();

    final transaction = Transaction(
      id: widget.existing?.id ?? const Uuid().v4(),
      amount: amount,
      type: _type,
      categoryId: _categoryId!,
      date: _date,
      note: note.isEmpty ? null : note,
    );

    final notifier = ref.read(transactionsProvider.notifier);
    if (_isEditing) {
      await notifier.update(transaction);
    } else {
      await notifier.add(transaction);
    }

    HapticFeedback.mediumImpact(); // a satisfying confirmation tap
    if (mounted) Navigator.of(context).pop(transaction);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // The reusable categories for the current side, plus the selected one even
    // if it's a "use once" category (so it still shows on its transaction).
    final categories = [...ref.watch(categoriesByKindProvider(_type))];
    if (_categoryId != null && categories.every((c) => c.id != _categoryId)) {
      final selected = ref.watch(categoryByIdProvider)[_categoryId];
      if (selected != null) categories.add(selected);
    }

    return Scaffold(
      backgroundColor: isDark ? null : const Color(0xFFF4F5FA),
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'),
        // Light bar with dark title/icons.
        backgroundColor: isDark ? null : Colors.white,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        // Thin iOS-style back chevron instead of the thick Android arrow.
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.spaceL),
          children: [
            // ---- Income / Expense sliding toggle ----
            TypeToggle(
              value: _type,
              onChanged: (type) => setState(() {
                _type = type;
                _ensureValidSelection(); // chips differ per side
              }),
            ),
            const SizedBox(height: AppConstants.spaceL),

            // ---- Amount (big, with wallet icon) ----
            _Card(
              isDark: isDark,
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: _accent,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spaceM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amount',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'),
                            ),
                          ],
                          // Rebuild so the quick chips, balance preview and Save
                          // button label update live as the amount changes.
                          onChanged: (_) => setState(() {}),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            hintText: '0.00',
                            prefixText: '₦ ',
                            prefixStyle: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: _accent,
                            ),
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) return 'Please enter an amount';
                            final parsed = double.tryParse(text);
                            if (parsed == null) return 'Enter a valid number';
                            if (parsed <= 0) {
                              return 'Amount must be greater than zero';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ---- Quick amounts + "balance after this" preview ----
            const SizedBox(height: AppConstants.spaceS),
            _quickAmountChips(theme),
            _balanceAfterLine(theme),
            const SizedBox(height: AppConstants.spaceM),

            // ---- Note (with note icon) ----
            _Card(
              isDark: isDark,
              child: Row(
                children: [
                  Icon(
                    Icons.sticky_note_2_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: AppConstants.spaceM),
                  Expanded(
                    child: TextFormField(
                      controller: _noteController,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        hintText: 'Note something...',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _noteSuggestions(theme),
            const SizedBox(height: AppConstants.spaceL),

            // ---- Category ----
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: AppConstants.spaceS),
              child: Text(
                'Category',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            CategoryPicker(
              categories: categories,
              selectedId: _categoryId,
              onSelected: (id) => setState(() => _categoryId = id),
              onEditPressed: _openNewCategory,
              onLongPress: _onCategoryLongPress,
            ),
            const SizedBox(height: AppConstants.spaceL),

            // ---- Date ----
            _Card(
              isDark: isDark,
              onTap: _pickDate,
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: AppConstants.spaceM),
                  Text(
                    Formatters.date(_date),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spaceXl),

            // ---- Save (vibrant gradient button) — shows the amount + type so
            //      the number does the convincing (specificity is trust). ----
            _GradientButton(
              accent: _accent,
              label: _saveLabel(),
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }
}

/// A soft rounded card with a subtle shadow, used to group each field.
class _Card extends StatelessWidget {
  const _Card({required this.child, required this.isDark, this.onTap});

  final Widget child;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spaceM),
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: child,
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      child: content,
    );
  }
}

/// Full-width vibrant gradient button that matches the selected type color.
class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.accent,
    required this.label,
    required this.onTap,
  });

  final Color accent;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Slightly darker second stop for a richer gradient.
    final darker = Color.lerp(accent, Colors.black, 0.18)!;

    return DecoratedBox(
      // Soft shadow that follows the pill shape. The negative spread tucks it
      // under the button so it reads as a gentle glow, not a hard rectangle.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.30),
            blurRadius: 18,
            spreadRadius: -4,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28), // fully rounded pill
          child: Ink(
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [accent, darker]),
              borderRadius: BorderRadius.circular(28), // fully rounded pill
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
