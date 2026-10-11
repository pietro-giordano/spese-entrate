import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/dates.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_chip.dart';
import 'date_picker_sheet.dart';

/// Date "Dal"/"Al" e scorciatoie del periodo personalizzato.
class CustomPeriodFields extends StatelessWidget {
  const CustomPeriodFields({
    super.key,
    required this.period,
    required this.today,
    required this.weekStart,
    required this.onChanged,
  });

  final Period period;
  final LocalDate today;
  final int weekStart;
  final ValueChanged<Period> onChanged;

  @override
  Widget build(BuildContext context) {
    final presets = {
      'Ultimi 30 gg': Period.custom(today.addDays(-29), today),
      'Ultimi 3 mesi': Period.custom(today.addMonths(-3).addDays(1), today),
      'Da inizio anno': Period.custom(LocalDate(today.year, 1, 1), today),
    };

    Future<void> pick({required bool start}) async {
      final picked = await showDatePickerSheet(
        context,
        selected: start ? period.start : period.end,
        today: today,
        weekStart: weekStart,
      );
      if (picked == null) return;
      // Se le date si incrociano, l'altra si allinea a quella scelta.
      if (start) {
        onChanged(Period.custom(picked, picked.isAfter(period.end) ? picked : period.end));
      } else {
        onChanged(Period.custom(picked.isBefore(period.start) ? picked : period.start, picked));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _DateField(label: 'Dal', date: period.start, onTap: () => pick(start: true)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DateField(label: 'Al', date: period.end, onTap: () => pick(start: false)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: 6,
          children: [
            for (final MapEntry(key: label, value: preset) in presets.entries)
              AppChip(
                label: label,
                shape: AppChipShape.label,
                selected: preset == period,
                onTap: () => onChanged(preset),
              ),
          ],
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.date, required this.onTap});

  final String label;
  final LocalDate date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final value = DateFormat('dd/MM/yyyy', 'it_IT').format(date.toDateTime());
    final borderRadius = BorderRadius.circular(AppRadius.field);

    return Semantics(
      container: true,
      button: true,
      label: '$label $value',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.labelSmall?.copyWith(color: colors.textMuted)),
          const SizedBox(height: AppSpacing.xs),
          Material(
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius,
              side: BorderSide(color: colors.borderStrong),
            ),
            child: InkWell(
              borderRadius: borderRadius,
              onTap: onTap,
              child: SizedBox(
                height: 46,
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
