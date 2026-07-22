import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import 'widgets/sparkle_decoration.dart';

/// Full-screen preview of how a category looks with the chosen icon + color.
/// Returns true if the user taps "Save Category".
class CategoryColorPreviewScreen extends StatelessWidget {
  const CategoryColorPreviewScreen({
    super.key,
    required this.name,
    required this.emoji,
    required this.color,
  });

  final String name;
  final String emoji;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = name.trim().isEmpty ? 'Category' : name.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spaceL),
          child: Column(
            children: [
              const SizedBox(height: AppConstants.spaceM),
              // Big icon + sparkles.
              SparkleDecoration(
                height: 160,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 54)),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spaceM),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    displayName,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.edit_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                ],
              ),
              const SizedBox(height: AppConstants.spaceL),

              // "This color will be used for X category"
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.spaceM),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'This color will be used for',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: displayName,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const TextSpan(text: '  category'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spaceM),

              // Sample transactions.
              _sampleRow(displayName, emoji, color, 'Today, 8:30 AM', '-₦120.50'),
              const Divider(height: 1),
              _sampleRow('Transport', '🚗', const Color(0xFF43A047),
                  'Yesterday, 6:20 PM', '-₦45.00'),
              const Divider(height: 1),
              _sampleRow('Shopping', '👜', const Color(0xFF7C4DFF),
                  '2 May, 3:15 PM', '-₦85.20'),

              const Spacer(),
              // Save.
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Save Category',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: AppConstants.spaceS),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sampleRow(
    String title,
    String emoji,
    Color color,
    String time,
    String amount,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.25),
        child: Text(emoji, style: const TextStyle(fontSize: 18)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(time),
      trailing: Text(
        amount,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}
