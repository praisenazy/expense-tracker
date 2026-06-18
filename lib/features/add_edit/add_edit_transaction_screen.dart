import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/expense_category.dart';
import '../../data/models/transaction.dart';
import '../../data/models/transaction_type.dart';
import '../../providers/transaction_providers.dart';
import 'widgets/category_picker.dart';

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
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  // Local form state for the non-text inputs.
  late TransactionType _type;
  late ExpenseCategory _category;
  late DateTime _date;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;

    // Pre-fill from the existing transaction when editing, else sensible
    // defaults for a new one.
    _titleController = TextEditingController(text: existing?.title ?? '');
    _amountController = TextEditingController(
      text: existing != null ? existing.amount.toString() : '',
    );
    _noteController = TextEditingController(text: existing?.note ?? '');
    _type = existing?.type ?? TransactionType.expense;
    _category = existing?.category ?? ExpenseCategory.food;
    _date = existing?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    // Always dispose controllers to avoid memory leaks.
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
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

    final amount = double.parse(_amountController.text.trim());
    final note = _noteController.text.trim();

    final transaction = Transaction(
      // Keep the same id when editing so we update the right record;
      // generate a new one when adding.
      id: widget.existing?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      amount: amount,
      type: _type,
      category: _category,
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
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Expense'),
                  icon: Icon(Icons.arrow_upward_rounded),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Income'),
                  icon: Icon(Icons.arrow_downward_rounded),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (selection) =>
                  setState(() => _type = selection.first),
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

            // ---- Title ----
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Groceries',
              ),
              validator: (value) {
                if ((value?.trim() ?? '').isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: AppConstants.spaceL),

            // ---- Category ----
            Text('Category', style: theme.textTheme.labelLarge),
            const SizedBox(height: AppConstants.spaceS),
            CategoryPicker(
              selected: _category,
              onSelected: (category) => setState(() => _category = category),
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
            const SizedBox(height: AppConstants.spaceM),

            // ---- Note (optional) ----
            TextFormField(
              controller: _noteController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
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
