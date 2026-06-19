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
  // Key used to trigger and read form validation.
  final _formKey = GlobalKey<FormState>();

  // Controllers hold the text typed into the fields.
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  // Local form state for the non-text inputs.
  late TransactionType _type;
  String? _categoryId; // selected category (by id)
  late DateTime _date;

  bool get _isEditing => widget.existing != null;

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

    // Pre-select the existing category, else the first one of this type.
    _categoryId = existing?.categoryId ?? _firstCategoryIdFor(_type);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// The first available category id for a kind, or null if none exist.
  String? _firstCategoryIdFor(TransactionType kind) {
    final list = ref.read(categoriesByKindProvider(kind));
    return list.isEmpty ? null : list.first.id;
  }

  /// Keep the selection valid for the current type (e.g. after switching
  /// income/expense, or returning from Manage Categories).
  void _ensureValidSelection() {
    final validIds =
        ref.read(categoriesByKindProvider(_type)).map((c) => c.id).toSet();
    if (_categoryId == null || !validIds.contains(_categoryId)) {
      _categoryId = _firstCategoryIdFor(_type);
    }
  }

  void _onTypeChanged(TransactionType newType) {
    setState(() {
      _type = newType;
      _ensureValidSelection();
    });
  }

  /// Opens the editor to create a brand-new category/source, then selects it.
  ///
  /// If this side already has the maximum number of categories, the user is
  /// first asked to delete one they added to make room.
  Future<void> _openNewCategory() async {
    final atLimit = ref.read(categoriesByKindProvider(_type)).length >=
        AppConstants.maxCategoriesPerKind;
    if (atLimit) {
      final madeRoom = await showCategoryLimitSheet(context, _type);
      if (madeRoom != true || !mounted) return;
    }

    final created = await Navigator.of(context).push<Category>(
      MaterialPageRoute(
        builder: (_) => CategoryEditorScreen(kind: _type),
      ),
    );
    if (!mounted) return;
    setState(() {
      if (created != null) {
        _categoryId = created.id; // auto-select the one just created
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
    // Run all field validators; stop if any fails.
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
      // Keep the same id when editing so we update the right record;
      // generate a new one when adding.
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
    // Categories for the currently-selected side (income or expense).
    final categories = ref.watch(categoriesByKindProvider(_type));

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.spaceM),
          children: [
            // ---- Income / Expense toggle ----
            TypeToggle(
              value: _type,
              onChanged: _onTypeChanged,
            ),
            const SizedBox(height: AppConstants.spaceL),

            // ---- Amount ----
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              // Allow only digits and a single decimal point.
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₦ ',
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'Please enter an amount';
                final parsed = double.tryParse(text);
                if (parsed == null) return 'Enter a valid number';
                if (parsed <= 0) return 'Amount must be greater than zero';
                return null;
              },
            ),
            const SizedBox(height: AppConstants.spaceM),

            // ---- Note (the transaction's description; optional) ----
            TextFormField(
              controller: _noteController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Note something...',
              ),
            ),
            const SizedBox(height: AppConstants.spaceL),

            // ---- Category (income source or expense type) ----
            Text(
              _type.isIncome ? 'Source' : 'Category',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: AppConstants.spaceS),
            CategoryPicker(
              categories: categories,
              selectedId: _categoryId,
              onSelected: (id) => setState(() => _categoryId = id),
              onEditPressed: _openNewCategory,
            ),
            const SizedBox(height: AppConstants.spaceL),

            // ---- Date ----
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  prefixIcon: Icon(Icons.calendar_today_rounded),
                ),
                child: Text(Formatters.date(_date)),
              ),
            ),
            const SizedBox(height: AppConstants.spaceXl),

            // ---- Save ----
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: Text(_isEditing ? 'Save Changes' : 'Add Transaction'),
            ),
          ],
        ),
      ),
    );
  }
}
