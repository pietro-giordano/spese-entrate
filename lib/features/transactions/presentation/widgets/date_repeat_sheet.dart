import 'package:flutter/material.dart';

import '../../../../core/dates.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_segmented.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../../domain/models/enums.dart';
import '../../../../domain/models/recurrence_rule.dart';
import '../../../../domain/services/recurrence.dart';
import '../../../recurring/presentation/recurrence_text.dart';
import '../../application/transaction_form_controller.dart';
import 'date_picker_sheet.dart';

/// Data e ripetizione scelte nel pannello.
typedef DateRepeatChoice = ({LocalDate date, RepeatSettings? repeat});

/// Pannello "Data e ripetizione" di Inserimento rapido. Restituisce la scelta confermata
/// (null se chiuso). La ripetizione si applica dalla data scelta.
Future<DateRepeatChoice?> showDateRepeatSheet(
  BuildContext context, {
  required LocalDate selected,
  required RepeatSettings? repeat,
  required LocalDate today,
  int weekStart = DateTime.monday,

  /// Segnaposto del nome della ricorrenza: il titolo che avrebbe senza nome (nota o categoria).
  String namePlaceholder = 'Es. Affitto',
}) {
  return AppBottomSheet.show<DateRepeatChoice>(
    context,
    title: 'Data e ripetizione',
    builder: (_) => _DateRepeatBody(
      initialDate: selected,
      initialRepeat: repeat,
      today: today,
      weekStart: weekStart,
      namePlaceholder: namePlaceholder,
    ),
  );
}

/// Preset dei chip "Ripeti"; null = "Mai".
const _presets = <(String, RecurrenceFrequency?)>[
  ('Mai', null),
  ('Ogni settimana', RecurrenceFrequency.weekly),
  ('Ogni mese', RecurrenceFrequency.monthly),
  ('Ogni anno', RecurrenceFrequency.yearly),
];

/// True se [repeat] è uno dei preset (intervallo 1, nessuna fine, non giornaliero).
bool _isPreset(RepeatSettings repeat) =>
    repeat.interval == 1 &&
    repeat.endDate == null &&
    repeat.maxCount == null &&
    repeat.frequency != RecurrenceFrequency.daily;

class _DateRepeatBody extends StatefulWidget {
  const _DateRepeatBody({
    required this.initialDate,
    required this.initialRepeat,
    required this.today,
    required this.weekStart,
    required this.namePlaceholder,
  });

  final LocalDate initialDate;
  final RepeatSettings? initialRepeat;
  final LocalDate today;
  final int weekStart;
  final String namePlaceholder;

  @override
  State<_DateRepeatBody> createState() => _DateRepeatBodyState();
}

class _DateRepeatBodyState extends State<_DateRepeatBody> {
  late LocalDate _date = widget.initialDate;
  late RepeatSettings? _repeat = widget.initialRepeat;

  /// Nome della ricorrenza: resta anche cambiando la ripetizione, si applica alla conferma.
  late final _name = TextEditingController(text: widget.initialRepeat?.name ?? '');

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _customize() async {
    final custom = await showCustomRepeatSheet(
      context,
      initial: _repeat ?? const RepeatSettings(frequency: RecurrenceFrequency.monthly),
      start: _date,
      today: widget.today,
      weekStart: widget.weekStart,
    );
    if (custom != null) setState(() => _repeat = custom);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final repeat = _repeat;
    final isCustom = repeat != null && !_isPreset(repeat);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TodayYesterdayChips(selected: _date, today: widget.today, onPick: (d) => setState(() => _date = d)),
        const SizedBox(height: AppSpacing.sm),
        MonthCalendar(
          selected: _date,
          today: widget.today,
          weekStart: widget.weekStart,
          onPick: (d) => setState(() => _date = d),
        ),
        const SizedBox(height: AppSpacing.md),
        Divider(height: 1, color: colors.divider),
        const SizedBox(height: AppSpacing.md),
        const SectionLabel('Ripeti'),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final (label, frequency) in _presets)
              AppChip(
                label: label,
                selected: frequency == null ? repeat == null : !isCustom && repeat?.frequency == frequency,
                onTap: () => setState(
                  () => _repeat = frequency == null
                      ? null
                      : RepeatSettings(frequency: frequency, mode: repeat?.mode ?? RecurrenceMode.auto),
                ),
              ),
            AppChip(label: isCustom ? _customLabel(repeat) : 'Personalizza…', selected: isCustom, onTap: _customize),
          ],
        ),
        if (repeat != null) ...[
          const SizedBox(height: AppSpacing.md),
          AppSegmented<RecurrenceMode>(
            segments: const [
              AppSegment(value: RecurrenceMode.auto, label: 'Automatico'),
              AppSegment(value: RecurrenceMode.confirm, label: 'Da confermare'),
            ],
            selected: repeat.mode,
            onChanged: (mode) => setState(() => _repeat = repeat.copyWith(mode: mode)),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(_hint(repeat), style: textTheme.bodySmall?.copyWith(color: colors.neutral.onTint, height: 1.45)),
          const SizedBox(height: AppSpacing.md),
          const SectionLabel('Nome della ricorrenza'),
          const SizedBox(height: 6),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(hintText: widget.namePlaceholder),
          ),
          const SizedBox(height: 4),
          Text('Facoltativo: se lo lasci vuoto vale la nota, altrimenti la categoria.', style: textTheme.bodySmall),
        ],
        const SizedBox(height: 14),
        FilledButton(
          onPressed: () => Navigator.pop<DateRepeatChoice>(context, (
            date: _date,
            repeat: _repeat?.copyWith(name: _name.text.trim()),
          )),
          child: const Text('Conferma'),
        ),
      ],
    );
  }

  RecurrenceRule _draft(RepeatSettings repeat) => anchorRuleAt(
    RecurrenceRule(
      id: '',
      name: '',
      type: TransactionType.expense,
      amountCents: 1,
      walletId: '',
      frequency: repeat.frequency,
      interval: repeat.interval,
      startDate: _date,
      endDate: repeat.endDate,
      maxCount: repeat.maxCount,
      mode: repeat.mode,
    ),
    _date,
  );

  /// "Ogni 2 mesi · 6 volte" sul chip della ripetizione personalizzata.
  String _customLabel(RepeatSettings repeat) {
    final rule = _draft(repeat);
    final schedule = describeSchedule(rule).split(',').first;
    return [schedule, ?describeEnd(rule)].join(' · ');
  }

  String _hint(RepeatSettings repeat) {
    final rule = _draft(repeat);
    final next = occurrenceDates(rule).elementAtOrNull(1);
    final how = repeat.mode == RecurrenceMode.auto
        ? 'verrà registrato automaticamente'
        : 'comparirà in "In arrivo" da confermare';
    final when = next == null ? 'Nessun\'altra occorrenza' : 'Prossimo: ${shortDate(next, widget.today)} · $how';
    return '${describeSchedule(rule)}. $when. Puoi gestirlo in Impostazioni › Movimenti ricorrenti.';
  }
}

/// Sotto-pannello "Personalizza…": intervallo, frequenza e fine (mai, data o numero di volte).
Future<RepeatSettings?> showCustomRepeatSheet(
  BuildContext context, {
  required RepeatSettings initial,
  required LocalDate start,
  required LocalDate today,
  int weekStart = DateTime.monday,
}) {
  return AppBottomSheet.show<RepeatSettings>(
    context,
    title: 'Ripetizione personalizzata',
    builder: (_) => _CustomRepeatBody(initial: initial, start: start, today: today, weekStart: weekStart),
  );
}

enum _EndKind { never, date, count }

class _CustomRepeatBody extends StatefulWidget {
  const _CustomRepeatBody({required this.initial, required this.start, required this.today, required this.weekStart});

  final RepeatSettings initial;
  final LocalDate start;
  final LocalDate today;
  final int weekStart;

  @override
  State<_CustomRepeatBody> createState() => _CustomRepeatBodyState();
}

class _CustomRepeatBodyState extends State<_CustomRepeatBody> {
  late RecurrenceFrequency _frequency = widget.initial.frequency;
  late int _interval = widget.initial.interval;
  late _EndKind _end = widget.initial.endDate != null
      ? _EndKind.date
      : widget.initial.maxCount != null
      ? _EndKind.count
      : _EndKind.never;
  late LocalDate _endDate = widget.initial.endDate ?? widget.start.addMonths(12);
  late int _count = widget.initial.maxCount ?? 12;

  static const _units = {
    RecurrenceFrequency.daily: ('Giorni', 'giorno', 'giorni'),
    RecurrenceFrequency.weekly: ('Settimane', 'settimana', 'settimane'),
    RecurrenceFrequency.monthly: ('Mesi', 'mese', 'mesi'),
    RecurrenceFrequency.yearly: ('Anni', 'anno', 'anni'),
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (_, singular, plural) = _units[_frequency]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSegmented<RecurrenceFrequency>(
          segments: [for (final MapEntry(:key, :value) in _units.entries) AppSegment(value: key, label: value.$1)],
          selected: _frequency,
          onChanged: (f) => setState(() => _frequency = f),
        ),
        const SizedBox(height: AppSpacing.md),
        _Stepper(
          label: _interval == 1 ? 'Ogni $singular' : 'Ogni $_interval $plural',
          value: _interval,
          min: 1,
          max: 99,
          onChanged: (v) => setState(() => _interval = v),
          decrementLabel: 'Intervallo più breve',
          incrementLabel: 'Intervallo più lungo',
        ),
        const SizedBox(height: AppSpacing.lg),
        const SectionLabel('Fine'),
        const SizedBox(height: AppSpacing.sm),
        AppSegmented<_EndKind>(
          segments: const [
            AppSegment(value: _EndKind.never, label: 'Mai'),
            AppSegment(value: _EndKind.date, label: 'Il giorno'),
            AppSegment(value: _EndKind.count, label: 'Dopo'),
          ],
          selected: _end,
          onChanged: (e) => setState(() => _end = e),
        ),
        const SizedBox(height: AppSpacing.md),
        switch (_end) {
          _EndKind.never => Text('Si ripete senza una fine.', style: textTheme.bodySmall),
          _EndKind.date => OutlinedButton.icon(
            icon: const Icon(Icons.event_outlined, size: 18),
            label: Text('Fino al ${longDate(_endDate)}'),
            onPressed: () async {
              final picked = await showDatePickerSheet(
                context,
                selected: _endDate,
                today: widget.today,
                weekStart: widget.weekStart,
              );
              if (picked != null) setState(() => _endDate = picked);
            },
          ),
          _EndKind.count => _Stepper(
            label: _count == 1 ? '1 volta' : '$_count volte',
            value: _count,
            min: 1,
            max: 999,
            onChanged: (v) => setState(() => _count = v),
            decrementLabel: 'Una volta in meno',
            incrementLabel: 'Una volta in più',
          ),
        },
        if (_end == _EndKind.date && _endDate.isBefore(widget.start)) ...[
          const SizedBox(height: AppSpacing.xs),
          Text('La fine deve venire dopo la data del movimento', style: textTheme.bodySmall),
        ],
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _end == _EndKind.date && _endDate.isBefore(widget.start)
              ? null
              : () => Navigator.pop(
                  context,
                  RepeatSettings(
                    frequency: _frequency,
                    interval: _interval,
                    endDate: _end == _EndKind.date ? _endDate : null,
                    maxCount: _end == _EndKind.count ? _count : null,
                    mode: widget.initial.mode,
                    name: widget.initial.name,
                  ),
                ),
          child: const Text('Applica'),
        ),
      ],
    );
  }
}

/// "−  Ogni 2 mesi  +": riga con un numero da aumentare o diminuire.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.decrementLabel,
    required this.incrementLabel,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String decrementLabel;
  final String incrementLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.outlined(
          tooltip: decrementLabel,
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_rounded),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ),
        IconButton.outlined(
          tooltip: incrementLabel,
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}
