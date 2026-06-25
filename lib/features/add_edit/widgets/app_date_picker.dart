import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';

/// A clean white calendar popup that replaces the default Flutter date picker.
///
/// Uses a custom month grid (not Flutter's cramped CalendarDatePicker) so the
/// day cells are big, spacious, and fill the popup width.
///
/// Colors are driven by [accent] (red for Expense, blue for Income):
///  - the selected day's filled circle uses [accent]
///  - the full-width pill "OK" button uses [accent]
///  - today's date is highlighted with the app's primary color
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required Color accent,
}) {
  final appPrimary = Theme.of(context).colorScheme.primary;
  final firstDate = DateTime(2000);
  final lastDate = DateTime(2100);

  // Stretch close to the screen edges (~12px margin each side).
  final dialogWidth = MediaQuery.of(context).size.width - 24;

  return showDialog<DateTime>(
    context: context,
    builder: (context) {
      var selected = initialDate;

      return Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SizedBox(
          width: dialogWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fixed-height calendar box. Change this number to resize it.
              SizedBox(
                height: 260,
                child: _AppCalendar(
                  initialDate: initialDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  accent: accent,
                  todayColor: appPrimary,
                  onDateChanged: (date) => selected = date,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(selected),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Custom month calendar: big, spacious, full-width day cells.
class _AppCalendar extends StatefulWidget {
  const _AppCalendar({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.accent,
    required this.todayColor,
    required this.onDateChanged,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Color accent;
  final Color todayColor;
  final ValueChanged<DateTime> onDateChanged;

  @override
  State<_AppCalendar> createState() => _AppCalendarState();
}

class _AppCalendarState extends State<_AppCalendar> {
  late DateTime _month; // first day of the displayed month
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;
    _month = DateTime(widget.initialDate.year, widget.initialDate.month);
  }

  bool get _canPrev =>
      _month.isAfter(DateTime(widget.firstDate.year, widget.firstDate.month));
  bool get _canNext =>
      _month.isBefore(DateTime(widget.lastDate.year, widget.lastDate.month));

  void _prev() {
    if (_canPrev) {
      setState(() => _month = DateTime(_month.year, _month.month - 1));
    }
  }

  void _next() {
    if (_canNext) {
      setState(() => _month = DateTime(_month.year, _month.month + 1));
    }
  }

  void _select(DateTime date) {
    setState(() => _selected = date);
    widget.onDateChanged(date);
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(_month.year, _month.month);
    // Sunday-first calendar: how many blank cells before day 1.
    final leadingBlanks = DateTime(_month.year, _month.month, 1).weekday % 7;

    final cells = <int?>[
      ...List<int?>.filled(leadingBlanks, null),
      for (var d = 1; d <= daysInMonth; d++) d,
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    final weeks = <List<int?>>[
      for (var i = 0; i < cells.length; i += 7) cells.sublist(i, i + 7),
    ];

    return Column(
      children: [
        // ---- Month + navigation ----
        Row(
          children: [
            IconButton(
              onPressed: _canPrev ? _prev : null,
              icon: const Icon(Icons.chevron_left_rounded),
              color: Colors.black87,
            ),
            Expanded(
              child: Center(
                child: Text(
                  Formatters.monthYear(_month), // e.g. "June 2026"
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: _canNext ? _next : null,
              icon: const Icon(Icons.chevron_right_rounded),
              color: Colors.black87,
            ),
          ],
        ),
        // ---- Weekday header (small, light grey) ----
        Row(
          children: const ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black38,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 6),
        // ---- Day grid fills the remaining box height (equal rows) ----
        Expanded(
          child: Column(
            children: [
              for (final week in weeks)
                Expanded(child: Row(children: week.map(_cell).toList())),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cell(int? day) {
    if (day == null) return const Expanded(child: SizedBox.shrink());

    final date = DateTime(_month.year, _month.month, day);
    final isSelected = DateUtils.isSameDay(date, _selected);
    final isToday = DateUtils.isSameDay(date, DateTime.now());

    Color textColor;
    if (isSelected) {
      textColor = Colors.white;
    } else if (isToday) {
      textColor = widget.todayColor;
    } else {
      textColor = Colors.black87;
    }

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _select(date),
        child: Center(
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? widget.accent : null,
              border: (isToday && !isSelected)
                  ? Border.all(color: widget.todayColor, width: 1.5)
                  : null,
            ),
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 14,
                fontWeight: (isSelected || isToday)
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
