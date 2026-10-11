import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/clock.dart';
import '../../../core/dates.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/bottom_action_bar.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_filter_chip.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_segmented.dart';
import '../../../core/widgets/app_switch.dart';
import '../../../core/widgets/section_label.dart';
import '../../../domain/models/app_settings.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/transaction_filters.dart';
import '../../../domain/services/transaction_list.dart';
import '../../analytics/application/analytics_filters.dart';
import '../../settings/application/settings_providers.dart';
import '../../wallets/application/wallet_providers.dart';
import '../application/filters_scope.dart';
import '../application/transaction_list_providers.dart';
import 'widgets/custom_period_fields.dart';
import 'widgets/period_selector.dart';

/// Filtri di una tab: Movimenti (tutte le sezioni), Grafici o Confronta (solo portafogli,
/// categorie e label), secondo [scope]. Ogni tab ha il suo stato. Le modifiche restano in una
/// bozza finché non si tocca "Applica filtri"; chiudere con la ✕ le scarta.
class FiltersScreen extends ConsumerStatefulWidget {
  const FiltersScreen({super.key, this.scope = FiltersScope.transactions});

  final FiltersScope scope;

  @override
  ConsumerState<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends ConsumerState<FiltersScreen> {
  late TransactionFilters _filters = switch (widget.scope) {
    FiltersScope.transactions => ref.read(activeFiltersProvider),
    FiltersScope.charts => ref.read(analyticsFiltersProvider(AnalyticsTab.charts)),
    FiltersScope.compare => ref.read(analyticsFiltersProvider(AnalyticsTab.compare)),
  };
  late Period _period = ref.read(selectedPeriodProvider);

  bool get _analytics => widget.scope.isAnalytics;

  void _update(TransactionFilters filters) => setState(() => _filters = filters);

  /// Il periodo si azzera solo in Movimenti: Grafici e Confronta hanno il loro selettore.
  void _reset(LocalDate today) {
    setState(() {
      _filters = const TransactionFilters();
      if (!_analytics) _period = Period.containing(PeriodType.month, today);
    });
  }

  void _apply() {
    switch (widget.scope) {
      case FiltersScope.transactions:
        ref.read(activeFiltersProvider.notifier).apply(_filters);
        ref.read(selectedPeriodProvider.notifier).set(_period);
      case FiltersScope.charts:
        ref.read(analyticsFiltersProvider(AnalyticsTab.charts).notifier).apply(analyticsScope(_filters));
      case FiltersScope.compare:
        ref.read(analyticsFiltersProvider(AnalyticsTab.compare).notifier).apply(analyticsScope(_filters));
    }
    context.pop();
  }

  /// Cambiando tipo si tolgono le categorie dell'altro tipo, che non avrebbero effetto.
  void _setType(TypeFilter type, List<Category> categories) {
    final allowed = {
      for (final c in categories)
        if (type == TypeFilter.all || c.kind.name == type.name) c.id,
    };
    _update(
      _filters.copyWith(
        type: type,
        categoryIds: _filters.categoryIds.intersection(allowed),
        excludedCategoryIds: _filters.excludedCategoryIds.intersection(allowed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final settings = ref.watch(appSettingsProvider).value ?? const AppSettings();
    final wallets = (ref.watch(walletsProvider).value ?? const []).where((w) => !w.isArchived).toList();
    final categories = (ref.watch(categoriesProvider).value ?? const <Category>[]).where((c) => !c.isArchived).toList();
    final labels = ref.watch(labelsProvider).value ?? const [];

    final expenseCategories = categories.where((c) => c.kind == CategoryKind.expense).toList();
    final incomeCategories = categories.where((c) => c.kind == CategoryKind.income).toList();

    Widget categoryChips(List<Category> list) => Wrap(
      spacing: 6,
      children: [
        for (final category in list)
          AppFilterChip(
            label: category.name,
            mode: _mode(_filters.categoryState(category.id)),
            onTap: () => _update(_filters.cycleCategory(category.id)),
          ),
      ],
    );

    return Scaffold(
      bottomNavigationBar: BottomActionBar(
        child: FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          onPressed: _apply,
          child: const Text('Applica filtri'),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 14, AppSpacing.screen, 10),
              child: Row(
                children: [
                  AppIconButton(icon: Icons.close_rounded, tooltip: 'Chiudi', onPressed: () => context.pop()),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text('Filtri', textAlign: TextAlign.center, style: textTheme.titleLarge),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: colors.expense.text),
                    onPressed: () => _reset(today),
                    child: const Text('Azzera'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 6, AppSpacing.screen, AppSpacing.xl),
                children: [
                  Text(
                    'Tocca un portafoglio, una categoria o una label una volta per includerlo (✓), '
                    'due per escluderlo (✕), tre per togliere il filtro. Un\'esclusione vince sempre.',
                    style: textTheme.bodySmall?.copyWith(height: 1.45),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_analytics) ...[
                    Text(
                      widget.scope == FiltersScope.charts
                          ? 'Valgono solo per i grafici. Periodo e Spese/Entrate si scelgono nella tab.'
                          : 'Valgono solo per il confronto. Periodi e grandezza si scelgono nella tab.',
                      style: textTheme.bodySmall?.copyWith(height: 1.45),
                    ),
                    const SizedBox(height: 18),
                  ] else ...[
                    const SectionLabel('Tipo'),
                    const SizedBox(height: 10),
                    AppSegmented<TypeFilter>(
                      segments: const [
                        AppSegment(value: TypeFilter.all, label: 'Tutti'),
                        AppSegment(value: TypeFilter.expense, label: 'Spese'),
                        AppSegment(value: TypeFilter.income, label: 'Entrate'),
                      ],
                      selected: _filters.type,
                      onChanged: (type) => _setType(type, categories),
                    ),
                    const SizedBox(height: 22),
                    const SectionLabel('Periodo'),
                    const SizedBox(height: 10),
                    PeriodTypeSelector(
                      selected: _period.type,
                      onChanged: (type) => setState(
                        () => _period = changePeriodType(_period, type, today: today, weekStart: settings.weekStart),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_period.type == PeriodType.custom)
                      CustomPeriodFields(
                        period: _period,
                        today: today,
                        weekStart: settings.weekStart,
                        onChanged: (period) => setState(() => _period = period),
                      )
                    else
                      PeriodNavigator(
                        period: _period,
                        today: today,
                        onShift: (steps) => setState(() => _period = _period.shift(steps)),
                      ),
                    const SizedBox(height: 22),
                  ],
                  SectionLabel(
                    'Portafogli',
                    trailing: _selectedLabel(
                      _filters.walletIds.length,
                      _filters.excludedWalletIds.length,
                      feminine: false,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final wallet in wallets)
                        AppFilterChip(
                          label: wallet.name,
                          mode: _mode(_filters.walletState(wallet.id)),
                          onTap: () => _update(_filters.cycleWallet(wallet.id)),
                        ),
                    ],
                  ),
                  if (!_analytics) ...[
                    const SizedBox(height: AppSpacing.xs),
                    MergeSemantics(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Mostra anche i trasferimenti tra portafogli',
                              style: textTheme.labelMedium?.copyWith(
                                color: colors.neutral.onTint,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          AppSwitch(
                            value: _filters.showTransfers,
                            onChanged: (value) => _update(_filters.copyWith(showTransfers: value)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  SectionLabel(
                    'Categorie',
                    trailing: _selectedLabel(
                      _filters.categoryIds.length,
                      _filters.excludedCategoryIds.length,
                      feminine: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (_filters.type == TypeFilter.all) ...[
                    Text('Spese', style: textTheme.labelSmall?.copyWith(color: colors.textMuted)),
                    categoryChips(expenseCategories),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Entrate', style: textTheme.labelSmall?.copyWith(color: colors.textMuted)),
                    categoryChips(incomeCategories),
                  ] else
                    categoryChips(_filters.type == TypeFilter.expense ? expenseCategories : incomeCategories),
                  const SizedBox(height: 22),
                  SectionLabel(
                    'Label',
                    trailing: _selectedLabel(
                      _filters.labelIds.length + (_filters.withoutLabels ? 1 : 0),
                      _filters.excludedLabelIds.length + (_filters.excludeWithoutLabels ? 1 : 0),
                      feminine: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final label in labels)
                        AppFilterChip(
                          label: '#${label.name}',
                          shape: AppChipShape.label,
                          mode: _mode(_filters.labelState(label.id)),
                          onTap: () => _update(_filters.cycleLabel(label.id)),
                        ),
                      AppFilterChip(
                        label: 'Senza label',
                        shape: AppChipShape.label,
                        mode: _mode(_filters.withoutLabelsState),
                        onTap: () => _update(_filters.cycleWithoutLabels()),
                      ),
                    ],
                  ),
                  if (labels.isEmpty)
                    Text('Non hai ancora creato label.', style: textTheme.bodySmall)
                  else ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Con più label selezionate, mostra i movimenti che hanno:',
                      style: textTheme.labelMedium?.copyWith(color: colors.neutral.onTint, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    AppSegmented<LabelMatch>(
                      segments: const [
                        AppSegment(value: LabelMatch.any, label: 'Almeno una'),
                        AppSegment(value: LabelMatch.all, label: 'Tutte'),
                      ],
                      selected: _filters.labelMatch,
                      onChanged: (match) => _update(_filters.copyWith(labelMatch: match)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '«Almeno una» e «Tutte» valgono per le label incluse. «Senza label» incluso aggiunge i '
                      'movimenti senza label; escluso li toglie.',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static AppFilterChipMode _mode(FilterChipState state) => switch (state) {
    FilterChipState.neutral => AppFilterChipMode.neutral,
    FilterChipState.included => AppFilterChipMode.included,
    FilterChipState.excluded => AppFilterChipMode.excluded,
  };

  /// "1 incluso", "2 incluse · 1 esclusa"… null se non c'è nessun filtro nella sezione.
  String? _selectedLabel(int included, int excluded, {required bool feminine}) {
    String part(int count, String stem) {
      final ending = feminine ? (count == 1 ? 'a' : 'e') : (count == 1 ? 'o' : 'i');
      return '$count $stem$ending';
    }

    final parts = [if (included > 0) part(included, 'inclus'), if (excluded > 0) part(excluded, 'esclus')];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}
