import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/clock.dart';
import '../../../core/money.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_list_row.dart';
import '../../../core/widgets/app_segmented.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/label.dart';
import '../../../domain/models/statistics.dart';
import '../../../domain/models/transaction_filters.dart';
import '../../settings/application/settings_providers.dart';
import '../../transactions/application/transaction_list_providers.dart';
import '../../transactions/application/transaction_providers.dart';
import '../../transactions/presentation/period_labels.dart';
import '../application/charts_providers.dart';
import '../application/statistics_providers.dart';

enum _Grouping { category, label }

/// Tab Grafici: spese o entrate del mese per categoria o per label.
class ChartsScreen extends ConsumerStatefulWidget {
  const ChartsScreen({super.key});

  @override
  ConsumerState<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends ConsumerState<ChartsScreen> {
  var _kind = CategoryKind.expense;
  var _grouping = _Grouping.category;

  /// Apre la lista Movimenti sul periodo del grafico, filtrata sulla voce toccata.
  /// [id] null è la voce "Senza label".
  void _openFilteredList(String? id) {
    final period = ref.read(chartsPeriodProvider);
    ref.read(selectedPeriodProvider.notifier).set(period);
    ref
        .read(activeFiltersProvider.notifier)
        .apply(
          TransactionFilters(
            type: _kind == CategoryKind.expense ? TypeFilter.expense : TypeFilter.income,
            categoryIds: _grouping == _Grouping.category && id != null ? {id} : const {},
            labelIds: _grouping == _Grouping.label && id != null ? {id} : const {},
            withoutLabels: _grouping == _Grouping.label && id == null,
          ),
        );
    context.go(AppRoutes.transactions);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final period = ref.watch(chartsPeriodProvider);
    final summary = ref.watch(periodSummaryProvider(period.range)).value;
    final items =
        (_grouping == _Grouping.category
                ? ref.watch(categoryBreakdownProvider(period.range, _kind))
                : ref.watch(labelBreakdownProvider(period.range, _kind)))
            .value ??
        const <BreakdownItem>[];

    final categories = {for (final c in ref.watch(categoriesProvider).value ?? const <Category>[]) c.id: c};
    final labels = {for (final l in ref.watch(labelsProvider).value ?? const <Label>[]) l.id: l};
    final entries = [
      for (final item in items)
        (
          item: item,
          name: _grouping == _Grouping.category
              ? (categories[item.id]?.name ?? 'Senza categoria')
              : (item.id == null ? 'Senza label' : '#${labels[item.id]?.name ?? '?'}'),
          // Il colore viene dalla categoria o dalla label; se manca (o è "Senza label"), grigio del tema.
          color: switch (_grouping) {
            _ when item.id == null => colors.textMuted,
            _Grouping.category => categories[item.id] == null ? colors.textMuted : Color(categories[item.id]!.color),
            _Grouping.label => labels[item.id] == null ? colors.textMuted : Color(labels[item.id]!.color),
          },
        ),
    ];
    final total = summary == null ? 0 : (_kind == CategoryKind.expense ? summary.expenseCents : summary.incomeCents);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.xl, AppSpacing.screen, AppSpacing.lg),
          children: [
            Semantics(header: true, child: Text('Grafici', style: textTheme.headlineLarge)),
            const SizedBox(height: 14),
            _MonthNavigator(title: periodTitle(period, today), onShift: ref.read(chartsPeriodProvider.notifier).shift),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: AppSegmented<CategoryKind>(
                    segments: const [
                      AppSegment(value: CategoryKind.expense, label: 'Spese'),
                      AppSegment(value: CategoryKind.income, label: 'Entrate'),
                    ],
                    selected: _kind,
                    onChanged: (kind) => setState(() => _kind = kind),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppSegmented<_Grouping>(
                    segments: const [
                      AppSegment(value: _Grouping.category, label: 'Categoria'),
                      AppSegment(value: _Grouping.label, label: 'Label'),
                    ],
                    selected: _grouping,
                    onChanged: (grouping) => setState(() => _grouping = grouping),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Card(
              child: Column(
                children: [
                  _Donut(
                    sections: [for (final e in entries) (value: e.item.totalCents, color: e.color)],
                    centerLabel: _kind == CategoryKind.expense ? 'Totale spese' : 'Totale entrate',
                    total: total,
                  ),
                  if (_grouping == _Grouping.label && entries.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Un movimento con più label conta in ognuna: le percentuali sono calcolate sulla somma delle label.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(color: colors.neutral.onTint, height: 1.45),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  _kind == CategoryKind.expense
                      ? 'Nessuna spesa in questo periodo.'
                      : 'Nessuna entrata in questo periodo.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
                ),
              )
            else
              AppListGroup(
                children: [
                  for (final e in entries)
                    _LegendRow(
                      name: e.name,
                      color: e.color,
                      share: e.item.share,
                      cents: e.item.totalCents,
                      relativeWidth: e.item.totalCents / entries.first.item.totalCents,
                      onTap: () => _openFilteredList(e.item.id),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      ),
      child: child,
    );
  }
}

/// Mese con le frecce, in una card bianca come nel mockup.
class _MonthNavigator extends StatelessWidget {
  const _MonthNavigator({required this.title, required this.onShift});

  final String title;
  final ValueChanged<int> onShift;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Mese precedente',
            onPressed: () => onShift(-1),
          ),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: 'Mese successivo',
            onPressed: () => onShift(1),
          ),
        ],
      ),
    );
  }
}

/// Ciambella con il totale al centro.
class _Donut extends StatelessWidget {
  const _Donut({required this.sections, required this.centerLabel, required this.total});

  final List<({int value, Color color})> sections;
  final String centerLabel;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return SizedBox.square(
      dimension: 208,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ExcludeSemantics(
            child: PieChart(
              PieChartData(
                startDegreeOffset: -90,
                sectionsSpace: sections.length > 1 ? 2 : 0,
                centerSpaceRadius: 68,
                pieTouchData: PieTouchData(enabled: false),
                sections: sections.isEmpty
                    // Anello grigio quando non ci sono dati.
                    ? [PieChartSectionData(value: 1, color: colors.track, radius: 36, showTitle: false)]
                    : [
                        for (final s in sections)
                          PieChartSectionData(value: s.value.toDouble(), color: s.color, radius: 36, showTitle: false),
                      ],
              ),
            ),
          ),
          MergeSemantics(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(centerLabel, style: textTheme.labelSmall?.copyWith(color: colors.textMuted)),
                const SizedBox(height: 2),
                Text(
                  formatCents(total),
                  style: textTheme.titleLarge?.copyWith(
                    fontSize: 22,
                    letterSpacing: -0.4,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Voce della legenda: colore, nome, percentuale, importo e barra proporzionale alla voce più grande.
class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.name,
    required this.color,
    required this.share,
    required this.cents,
    required this.relativeWidth,
    required this.onTap,
  });

  final String name;
  final Color color;
  final double share;
  final int cents;
  final double relativeWidth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final percent = '${NumberFormat('0.0', 'it_IT').format(share * 100)}%';
    const tabular = [FontFeature.tabularFigures()];

    return Semantics(
      container: true,
      button: onTap != null,
      label: '$name, $percent, ${formatCents(cents)}${onTap != null ? ', mostra i movimenti' : ''}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    percent,
                    style: textTheme.labelMedium?.copyWith(color: colors.textMuted, fontFeatures: tabular),
                  ),
                  SizedBox(
                    width: 104,
                    child: Text(
                      formatCents(cents),
                      textAlign: TextAlign.right,
                      style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800, fontFeatures: tabular),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Container(
                  height: 4,
                  color: colors.divider,
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: relativeWidth.clamp(0, 1).toDouble(),
                    child: Container(color: color),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
