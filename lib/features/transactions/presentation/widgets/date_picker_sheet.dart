import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/dates.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_chip.dart';

/// Etichetta della data per il chip: "Oggi", "Ieri", "3 ott" o "3 ott 2025".
String dateChipLabel(LocalDate date, LocalDate today) {
  if (date == today) return 'Oggi';
  if (date == today.addDays(-1)) return 'Ieri';
  final pattern = date.year == today.year ? 'd MMM' : 'd MMM y';
  return DateFormat(pattern, 'it_IT').format(date.toDateTime());
}

/// Apre il pannello della data e restituisce la data confermata (null se chiuso).
Future<LocalDate?> showDatePickerSheet(
  BuildContext context, {
  required LocalDate selected,
  required LocalDate today,
  int weekStart = DateTime.monday,
}) {
  return AppBottomSheet.show<LocalDate>(
    context,
    title: 'Data',
    builder: (_) => _DatePickerBody(initial: selected, today: today, weekStart: weekStart),
  );
}

class _DatePickerBody extends StatefulWidget {
  const _DatePickerBody({required this.initial, required this.today, required this.weekStart});

  final LocalDate initial;
  final LocalDate today;
  final int weekStart;

  @override
  State<_DatePickerBody> createState() => _DatePickerBodyState();
}

class _DatePickerBodyState extends State<_DatePickerBody> {
  late LocalDate _selected = widget.initial;

  /// Primo giorno del mese mostrato.
  late LocalDate _month = LocalDate(widget.initial.year, widget.initial.month, 1);

  static const _weekdayInitials = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];

  void _pick(LocalDate date) {
    setState(() {
      _selected = date;
      _month = LocalDate(date.year, date.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final yesterday = widget.today.addDays(-1);
    final monthTitle = DateFormat.yMMMM('it_IT').format(_month.toDateTime());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 6,
          children: [
            AppChip(label: 'Oggi', selected: _selected == widget.today, onTap: () => _pick(widget.today)),
            AppChip(label: 'Ieri', selected: _selected == yesterday, onTap: () => _pick(yesterday)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              tooltip: 'Mese precedente',
              onPressed: () => setState(() => _month = _month.addMonths(-1)),
            ),
            Expanded(
              child: Text(
                monthTitle[0].toUpperCase() + monthTitle.substring(1),
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              tooltip: 'Mese successivo',
              onPressed: () => setState(() => _month = _month.addMonths(1)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Text(
                  _weekdayInitials[(widget.weekStart - 1 + i) % 7],
                  textAlign: TextAlign.center,
                  style: textTheme.labelSmall?.copyWith(color: colors.textMuted, fontWeight: FontWeight.w800),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ..._weeks().map(
          (week) => Row(
            children: [
              for (final day in week)
                Expanded(
                  child: day == null
                      ? const SizedBox(height: 44)
                      : _DayCell(
                          date: day,
                          selected: day == _selected,
                          isToday: day == widget.today,
                          onTap: () => _pick(day),
                        ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        FilledButton(onPressed: () => Navigator.pop(context, _selected), child: const Text('Conferma')),
      ],
    );
  }

  /// Settimane del mese mostrato; null = casella vuota prima del giorno 1 o dopo l'ultimo.
  List<List<LocalDate?>> _weeks() {
    final leading = (_month.weekday - widget.weekStart + 7) % 7;
    final days = LocalDate.daysInMonth(_month.year, _month.month);
    final cells = <LocalDate?>[
      for (var i = 0; i < leading; i++) null,
      for (var day = 1; day <= days; day++) LocalDate(_month.year, _month.month, day),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return [for (var i = 0; i < cells.length; i += 7) cells.sublist(i, i + 7)];
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.date, required this.selected, required this.isToday, required this.onTap});

  final LocalDate date;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = DateFormat.yMMMMd('it_IT').format(date.toDateTime());

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: isToday ? '$label, oggi' : label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 44,
          child: Center(
            child: Container(
              height: 36,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? colors.neutral.fill : null,
                borderRadius: BorderRadius.circular(10),
                border: isToday && !selected ? Border.all(color: colors.text, width: 2) : null,
              ),
              child: Text(
                '${date.day}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? colors.neutral.onFill : colors.text,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
