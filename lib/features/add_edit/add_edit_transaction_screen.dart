import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../../data/models/transaction_type.dart';
import '../../providers/category_providers.dart';
import '../../providers/transaction_providers.dart';
import '../categories/category_editor_screen.dart';
import '../categories/widgets/category_limit_sheet.dart';
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
    _date = existing?.date ?? DateTime.now();
    _categoryId = existing?.categoryId ?? _firstCategoryId();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// The first available category id, or null if none exist.
  String? _firstCategoryId() {
    final list = ref.read(categoriesProvider);
    return list.isEmpty ? null : list.first.id;
  }

  /// Keep the selection valid (e.g. after returning from the editor).
  void _ensureValidSelection() {
    final validIds = ref.read(categoriesProvider).map((c) => c.id).toSet();
    if (_categoryId == null || !validIds.contains(_categoryId)) {
      _categoryId = _firstCategoryId();
    }
  }

  /// Opens the editor to create a new category, then selects it. If at the
  /// limit, the user is first asked to delete one they added.
  Future<void> _openNewCategory() async {
    final atLimit =
        ref.read(categoriesProvider).length >= AppConstants.maxCategories;
    if (atLimit) {
      final madeRoom = await showCategoryLimitSheet(context);
      if (madeRoom != true || !mounted) return;
    }

    final created = await Navigator.of(context).push<Category>(
      MaterialPageRoute(builder: (_) => const CategoryEditorScreen()),
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
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

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categories = ref.watch(categoriesProvider);

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
              onChanged: (type) => setState(() => _type = type),
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

            // ---- Save (vibrant gradient button) ----
            _GradientButton(
              accent: _accent,
              label: _isEditing ? 'Save Changes' : 'Add Transaction',
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [accent, darker]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_rounded, color: Colors.white),
                const SizedBox(width: AppConstants.spaceS),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
