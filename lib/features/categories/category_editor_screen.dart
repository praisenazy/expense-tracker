import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction_type.dart';
import '../../providers/category_providers.dart';

/// Create or edit a single category (name + icon + color).
///
/// Pass [existing] to edit; pass only [kind] to create a new one of that side.
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

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _iconCodePoint = existing?.iconCodePoint ?? AppIcons.choices.first.codePoint;
    _colorValue = existing?.colorValue ?? AppColors.palette.first.toARGB32();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final category = Category(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      kind: widget.existing?.kind ?? widget.kind,
      iconCodePoint: _iconCodePoint,
      colorValue: _colorValue,
    );

    final notifier = ref.read(categoriesProvider.notifier);
    if (_isEditing) {
      await notifier.update(category);
    } else {
      await notifier.add(category);
    }

    // Return the saved category so the caller can auto-select it.
    if (mounted) Navigator.of(context).pop(category);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = Color(_colorValue);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Category' : 'New Category'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.spaceM),
          children: [
            // ---- Live preview ----
            Center(
              child: CircleAvatar(
                radius: 32,
                backgroundColor: selectedColor.withValues(alpha: 0.15),
                child: Icon(
                  AppIcons.fromCodePoint(_iconCodePoint),
                  color: selectedColor,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spaceL),

            // ---- Name ----
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Category name',
                hintText: 'e.g. Food',
              ),
              validator: (value) {
                if ((value?.trim() ?? '').isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: AppConstants.spaceL),

            // ---- Icon picker ----
            Text('Icon', style: theme.textTheme.labelLarge),
            const SizedBox(height: AppConstants.spaceS),
            Wrap(
              spacing: AppConstants.spaceS,
              runSpacing: AppConstants.spaceS,
              children: AppIcons.choices.map((icon) {
                final isSelected = icon.codePoint == _iconCodePoint;
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () =>
                      setState(() => _iconCodePoint = icon.codePoint),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? selectedColor.withValues(alpha: 0.18)
                          : theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? selectedColor
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected
                          ? selectedColor
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppConstants.spaceL),

            // ---- Color picker ----
            Text('Color', style: theme.textTheme.labelLarge),
            const SizedBox(height: AppConstants.spaceS),
            Wrap(
              spacing: AppConstants.spaceM,
              runSpacing: AppConstants.spaceM,
              children: AppColors.palette.map((color) {
                final value = color.toARGB32();
                final isSelected = value == _colorValue;
                return InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => setState(() => _colorValue = value),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.onSurface
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppConstants.spaceXl),

            // ---- Save ----
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: Text(_isEditing ? 'Save Changes' : 'Add Category'),
            ),
          ],
        ),
      ),
    );
  }
}
