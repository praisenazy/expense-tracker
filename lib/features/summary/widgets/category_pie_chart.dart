import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/category.dart';

/// Donut chart of expenses by category, with a legend.
///
/// Pure display: give it the category→amount map and it draws the slices using
/// each category's own color.
class CategoryPieChart extends StatelessWidget {
  const CategoryPieChart({super.key, required this.expenseByCategory});

  final Map<Category, double> expenseByCategory;

  @override
  Widget build(BuildContext context) {
    final total =
        expenseByCategory.values.fold<double>(0, (sum, v) => sum + v);

    // Sort categories biggest-first for a tidier legend.
    final entries = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 48, // makes it a donut
              sectionsSpace: 2,
              sections: entries.map((entry) {
                final percent = total == 0 ? 0.0 : (entry.value / total) * 100;
                return PieChartSectionData(
                  value: entry.value,
                  color: entry.key.color,
                  title: '${percent.toStringAsFixed(0)}%',
                  radius: 56,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: AppConstants.spaceL),
        // Legend
        ...entries.map((entry) {
          final percent = total == 0 ? 0.0 : (entry.value / total) * 100;
          return Padding(
            padding:
                const EdgeInsets.symmetric(vertical: AppConstants.spaceXs),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: entry.key.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: AppConstants.spaceS),
                Expanded(child: Text(entry.key.name)),
                Text(
                  '${Formatters.money(entry.value)}  (${percent.toStringAsFixed(0)}%)',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
