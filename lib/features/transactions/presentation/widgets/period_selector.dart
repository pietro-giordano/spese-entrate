import 'package:flutter/material.dart';

import '../../../../core/dates.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_segmented.dart';
import '../period_labels.dart';

/// Selettore Giorno/Sett./Mese/Anno/Periodo.
class PeriodTypeSelector extends StatelessWidget {
  const PeriodTypeSelector({super.key, required this.selected, required this.onChanged});

  final PeriodType selected;
  final ValueChanged<PeriodType> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppSegmented<PeriodType>(
      segments: const [
        AppSegment(value: PeriodType.day, label: 'Giorno'),
        AppSegment(value: PeriodType.week, label: 'Sett.'),
        AppSegment(value: PeriodType.month, label: 'Mese'),
        AppSegment(value: PeriodType.year, label: 'Anno'),
        AppSegment(value: PeriodType.custom, label: 'Periodo'),
      ],
      selected: selected,
      onChanged: onChanged,
    );
  }
}

/// Titolo del periodo con le frecce indietro e avanti.
class PeriodNavigator extends StatelessWidget {
  const PeriodNavigator({super.key, required this.period, required this.today, required this.onShift});

  final Period period;
  final LocalDate today;

  /// −1 indietro, 1 avanti.
  final ValueChanged<int> onShift;

  @override
  Widget build(BuildContext context) {
    final title = periodTitle(period, today);
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          tooltip: 'Periodo precedente',
          onPressed: () => onShift(-1),
        ),
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 17),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          tooltip: 'Periodo successivo',
          onPressed: () => onShift(1),
        ),
      ],
    );
  }
}

/// Spazio standard tra selettore e frecce.
const periodSelectorGap = SizedBox(height: AppSpacing.xs);
