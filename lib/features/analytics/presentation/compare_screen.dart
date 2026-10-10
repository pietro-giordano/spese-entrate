import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/clock.dart';
import '../../../core/dates.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_segmented.dart';
import '../../../domain/models/category.dart';
import '../../../domain/services/comparison.dart';
import '../../settings/application/settings_providers.dart';
import '../../transactions/presentation/period_labels.dart';
import '../../transactions/presentation/widgets/period_selector.dart';
import '../application/compare_providers.dart';
import 'widgets/compare_charts.dart';

/// Righe del confronto: per spese ed entrate una per categoria (dalla più grande nel primo periodo)
/// più il totale; per il saldo entrate, uscite e saldo.
List<CompareRow> buildCompareRows(List<ComparedPeriod> data, CompareMetric metric, Map<String, String> categoryNames) {
  List<int> values(int Function(ComparedPeriod p) pick) => [for (final p in data) pick(p)];

  if (metric == CompareMetric.balance) {
    return [
      CompareRow(
        name: 'Entrate',
        shortName: 'Entrate',
        values: values((p) => p.summary.incomeCents),
        higherIsBetter: true,
      ),
      CompareRow(name: 'Uscite', shortName: 'Uscite', values: values((p) => p.summary.expenseCents)),
      CompareRow(
        name: 'Saldo',
        shortName: 'Saldo',
        values: values((p) => p.summary.balanceCents),
        higherIsBetter: true,
        isTotal: true,
      ),
    ];
  }

  final ids = {for (final p in data) ...p.byCategory.keys}.toList()
    ..sort((a, b) {
      for (final p in data) {
        final byValue = (p.byCategory[b] ?? 0).compareTo(p.byCategory[a] ?? 0);
        if (byValue != 0) return byValue;
      }
      return 0;
    });
  final higherIsBetter = metric == CompareMetric.income;
  final rows = <CompareRow>[];
  for (final id in ids) {
    final name = categoryNames[id] ?? 'Senza categoria';
    rows.add(
      CompareRow(
        name: name,
        shortName: shortCategoryName(name),
        values: values((p) => p.byCategory[id] ?? 0),
        higherIsBetter: higherIsBetter,
      ),
    );
  }
  rows.add(
    CompareRow(
      name: 'Totale',
      shortName: 'Totale',
      values: values((p) => p.total(metric)),
      higherIsBetter: higherIsBetter,
      isTotal: true,
    ),
  );
  return rows;
}

/// Intestazione breve di un periodo nella tabella: "Set 26", "2026", "P2".
String shortPeriodLabel(Period period, int index) {
  switch (period.type) {
    case PeriodType.month:
      final text = DateFormat('MMM yy', 'it_IT').format(period.start.toDateTime());
      return text[0].toUpperCase() + text.substring(1);
    case PeriodType.year:
      return '${period.start.year}';
    default:
      return 'P${index + 1}';
  }
}

/// Tab Confronta: fino a 3 periodi, barre per categoria o linee cumulate, tabella delle variazioni.
class CompareScreen extends ConsumerWidget {
  const CompareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final state = ref.watch(compareControllerProvider);
    final controller = ref.read(compareControllerProvider.notifier);
    final data = ref.watch(comparisonProvider).value;
    final categoryNames = {for (final c in ref.watch(categoriesProvider).value ?? const <Category>[]) c.id: c.name};

    final rows = data == null ? const <CompareRow>[] : buildCompareRows(data, state.metric, categoryNames);
    // Nel grafico a barre: al massimo 6 categorie, senza la riga del totale.
    final chartRows = state.metric == CompareMetric.balance ? rows : rows.where((r) => !r.isTotal).take(6).toList();
    final metricName = switch (state.metric) {
      CompareMetric.expense => 'Spese',
      CompareMetric.income => 'Entrate',
      CompareMetric.balance => 'Saldo',
    };
    final chartTitle = state.chart == CompareChart.bars
        ? (state.metric == CompareMetric.balance ? 'Entrate, uscite e saldo (€)' : '$metricName per categoria (€)')
        : switch (state.metric) {
            CompareMetric.expense => 'Spesa cumulata, giorno per giorno (€)',
            CompareMetric.income => 'Entrate cumulate, giorno per giorno (€)',
            CompareMetric.balance => 'Saldo cumulato, giorno per giorno (€)',
          };

    const presets = {
      ComparePreset.lastThreeMonths: 'Ultimi 3 mesi',
      ComparePreset.monthVsLastYear: 'Mese vs anno prec.',
      ComparePreset.yearVsYear: 'Anno vs anno',
      ComparePreset.custom: 'Personalizzato',
    };

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.xl, AppSpacing.screen, AppSpacing.lg),
          children: [
            Semantics(header: true, child: Text('Confronta', style: textTheme.headlineLarge)),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final MapEntry(key: preset, value: label) in presets.entries) ...[
                    AppChip(
                      label: label,
                      selected: state.preset == preset,
                      onTap: () => controller.applyPreset(preset),
                    ),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final (i, period) in state.periods.indexed)
                  _PeriodChip(
                    name: periodTitle(period, today),
                    color: seriesColor(context, i),
                    onRemove: state.periods.length > 1 ? () => controller.removePeriod(period) : null,
                  ),
                if (state.canAddPeriod)
                  AppChip(
                    label: '+ Periodo',
                    shape: AppChipShape.label,
                    dashed: true,
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final period = await _showAddPeriodSheet(context, today);
                      if (period != null && !controller.addPeriod(period)) {
                        messenger.showSnackBar(const SnackBar(content: Text('Questo periodo è già nel confronto')));
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppSegmented<CompareMetric>(
                    segments: const [
                      AppSegment(value: CompareMetric.expense, label: 'Spese'),
                      AppSegment(value: CompareMetric.income, label: 'Entr.'),
                      AppSegment(value: CompareMetric.balance, label: 'Saldo'),
                    ],
                    selected: state.metric,
                    onChanged: controller.setMetric,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppSegmented<CompareChart>(
                    segments: const [
                      AppSegment(value: CompareChart.bars, label: 'Barre'),
                      AppSegment(value: CompareChart.lines, label: 'Linee'),
                    ],
                    selected: state.chart,
                    onChanged: controller.setChart,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(14, AppSpacing.lg, 14, 14),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(AppRadius.cardLarge),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(chartTitle, style: textTheme.labelMedium?.copyWith(color: colors.textMuted)),
                  const SizedBox(height: 10),
                  if (data == null)
                    const SizedBox(height: 190)
                  else if (chartRows.isEmpty || rows.every((r) => r.values.every((v) => v == 0)))
                    SizedBox(
                      height: 120,
                      child: Center(
                        child: Text(
                          'Nessun movimento nei periodi scelti.',
                          style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
                        ),
                      ),
                    )
                  else
                    Semantics(
                      label: '$chartTitle. I valori sono nella tabella qui sotto.',
                      excludeSemantics: true,
                      child: state.chart == CompareChart.bars
                          ? CompareBarChart(rows: chartRows)
                          : CompareLineChart(series: [for (final p in data) p.cumulative]),
                    ),
                ],
              ),
            ),
            _CaveatsNote(caveats: comparisonCaveats(state.periods, today), today: today),
            const SizedBox(height: 14),
            if (rows.isNotEmpty)
              CompareTable(
                firstColumn: state.metric == CompareMetric.balance ? 'Voce' : 'Categoria',
                periodLabels: [for (final (i, p) in state.periods.indexed) shortPeriodLabel(p, i)],
                rows: rows,
              ),
            if (state.periods.length >= 2) ...[
              const SizedBox(height: AppSpacing.sm),
              Text('Δ: variazione del primo periodo rispetto al secondo.', style: textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

/// Periodo confrontato: colore, nome e rimozione.
class _PeriodChip extends StatelessWidget {
  const _PeriodChip({required this.name, required this.color, required this.onRemove});

  final String name;
  final Color color;

  /// Null quando è l'unico periodo (non si può togliere).
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: AppSizes.minTouchTarget,
      padding: EdgeInsets.only(left: 10, right: onRemove == null ? 12 : 0),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(name, style: Theme.of(context).textTheme.labelMedium),
          if (onRemove != null)
            // Più stretto di un IconButton (48 px), così due periodi stanno su una riga; alto 44 per il tocco.
            Tooltip(
              message: 'Rimuovi $name',
              child: InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(AppRadius.field),
                child: SizedBox(
                  width: 36,
                  height: AppSizes.minTouchTarget,
                  child: Icon(Icons.close_rounded, size: 16, color: colors.textMuted),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Pannello per scegliere un periodo da aggiungere al confronto.
Future<Period?> _showAddPeriodSheet(BuildContext context, LocalDate today) {
  return AppBottomSheet.show<Period>(
    context,
    title: 'Aggiungi periodo',
    builder: (_) => _AddPeriodBody(today: today),
  );
}

class _AddPeriodBody extends StatefulWidget {
  const _AddPeriodBody({required this.today});

  final LocalDate today;

  @override
  State<_AddPeriodBody> createState() => _AddPeriodBodyState();
}

class _AddPeriodBodyState extends State<_AddPeriodBody> {
  late Period _period = Period.containing(PeriodType.month, widget.today);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSegmented<PeriodType>(
          segments: const [
            AppSegment(value: PeriodType.week, label: 'Sett.'),
            AppSegment(value: PeriodType.month, label: 'Mese'),
            AppSegment(value: PeriodType.year, label: 'Anno'),
          ],
          selected: _period.type,
          onChanged: (type) => setState(() => _period = Period.containing(type, _period.start)),
        ),
        const SizedBox(height: AppSpacing.sm),
        PeriodNavigator(
          period: _period,
          today: widget.today,
          onShift: (steps) => setState(() => _period = _period.shift(steps)),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(onPressed: () => Navigator.pop(context, _period), child: const Text('Aggiungi')),
      ],
    );
  }
}

/// Avviso discreto quando i periodi non sono omogenei (durate diverse o non ancora finiti).
class _CaveatsNote extends StatelessWidget {
  const _CaveatsNote({required this.caveats, required this.today});

  final ComparisonCaveats caveats;
  final LocalDate today;

  @override
  Widget build(BuildContext context) {
    if (!caveats.any) return const SizedBox.shrink();
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    final inProgress = [for (final period in caveats.inProgress) periodTitle(period, today)];
    final parts = [
      if (inProgress.length == 1) '${inProgress.single} non è ancora concluso.',
      if (inProgress.length > 1) '${inProgress.join(' e ')} non sono ancora conclusi.',
      if (caveats.differentLengths) 'I periodi hanno durate diverse.',
      'Il confronto usa importi assoluti, senza normalizzare per giorno.',
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline_rounded, size: 16, color: colors.textMuted),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(parts.join(' '), style: textTheme.bodySmall?.copyWith(height: 1.45))),
        ],
      ),
    );
  }
}
