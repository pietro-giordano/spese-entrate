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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TodayYesterdayChips(selected: _selected, today: widget.today, onPick: (d) => setState(() => _selected = d)),
        const SizedBox(height: AppSpacing.sm),
        MonthCalendar(
          selected: _selected,
          today: widget.today,
          weekStart: widget.weekStart,
          onPick: (d) => setState(() => _selected = d),
        ),
        const SizedBox(height: 14),
        FilledButton(onPressed: () => Navigator.pop(context, _selected), child: const Text('Conferma')),
      ],
    );
  }
}

/// Scorciatoie "Oggi" e "Ieri" sopra il calendario.
class TodayYesterdayChips extends StatelessWidget {
  const TodayYesterdayChips({super.key, required this.selected, required this.today, required this.onPick});

  final LocalDate selected;
  final LocalDate today;
  final ValueChanged<LocalDate> onPick;

  @override
  Widget build(BuildContext context) {
    final yesterday = today.addDays(-1);
    return Wrap(
      spacing: 6,
      children: [
        AppChip(label: 'Oggi', selected: selected == today, onTap: () => onPick(today)),
        AppChip(label: 'Ieri', selected: selected == yesterday, onTap: () => onPick(yesterday)),
      ],
    );
  }
}

/// Calendario di un mese con frecce: mostra il mese di [selected] e lo segue quando cambia.
class MonthCalendar extends StatefulWidget {
  const MonthCalendar({
    super.key,
    required this.selected,
    required this.today,
    required this.onPick,
    this.weekStart = DateTime.monday,
  });

  final LocalDate selected;
  final LocalDate today;
  final int weekStart;
  final ValueChanged<LocalDate> onPick;

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  /// Primo giorno del mese mostrato.
  late LocalDate _month = _monthOf(widget.selected);

  static const _weekdayInitials = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];

  static LocalDate _monthOf(LocalDate date) => LocalDate(date.year, date.month, 1);

  @override
  void didUpdateWidget(MonthCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // "Oggi" o "Ieri" possono portare a un altro mese.
    if (widget.selected != oldWidget.selected) _month = _monthOf(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final monthTitle = DateFormat.yMMMM('it_IT').format(_month.toDateTime());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                          selected: day == widget.selected,
                          isToday: day == widget.today,
                          onTap: () => widget.onPick(day),
                        ),
                ),
            ],
          ),
        ),
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
