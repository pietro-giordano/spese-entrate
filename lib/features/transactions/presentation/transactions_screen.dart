import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/clock.dart';
import '../../../core/dates.dart';
import '../../../core/money.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/tab_header.dart';
import '../../../core/widgets/bottom_action_bar.dart';
import '../../../core/widgets/app_list_row.dart';
import '../../../core/widgets/section_label.dart';
import '../../../core/widgets/state_message.dart';
import '../../../domain/models/app_settings.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/label.dart';
import '../../../domain/models/statistics.dart';
import '../../../domain/services/statistics.dart';
import '../../../domain/services/transaction_list.dart';
import '../../recurring/presentation/widgets/upcoming_section.dart';
import '../../settings/application/settings_providers.dart';
import '../../wallets/application/wallet_providers.dart';
import '../application/transaction_list_providers.dart';
import '../application/search_providers.dart';
import '../application/transaction_providers.dart';
import 'period_labels.dart';
import 'widgets/period_selector.dart';
import 'widgets/summary_card.dart';
import 'widgets/transaction_tile.dart';

/// Tab Movimenti (home): periodo, riepilogo e lista per giorno.
class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final period = ref.watch(selectedPeriodProvider);
    final filters = ref.watch(activeFiltersProvider);
    final settings = ref.watch(appSettingsProvider).value ?? const AppSettings();

    final wallets = ref.watch(walletsProvider).value ?? const [];
    final walletNames = <String, String>{for (final w in wallets) w.id: w.name};
    final categoryNames = <String, String>{
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[]) c.id: c.name,
    };
    final labelNames = <String, String>{
      for (final l in ref.watch(labelsProvider).value ?? const <Label>[]) l.id: l.name,
    };

    final summary = ref.watch(visibleSummaryProvider).value ?? const PeriodSummary(incomeCents: 0, expenseCents: 0);
    final groupsAsync = ref.watch(visibleDayGroupsProvider);
    final search = ref.watch(transactionSearchProvider);

    final walletsLabel = switch (filters.walletIds.length) {
      0 => 'Tutti i portafogli',
      1 => walletNames[filters.walletIds.single] ?? '1 portafoglio',
      final count => '$count portafogli',
    };

    return PopScope(
      // Con la ricerca aperta, "indietro" la chiude invece di uscire.
      canPop: !search.open,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(transactionSearchProvider.notifier).close();
      },
      child: Scaffold(
        bottomNavigationBar: const _AddButtons(),
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.xl, AppSpacing.screen, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (search.open)
                      const _SearchHeader()
                    else
                      TabHeader(
                        title: 'Movimenti',
                        actions: [
                          AppIconButton(
                            icon: Icons.search_rounded,
                            tooltip: 'Cerca',
                            onPressed: ref.read(transactionSearchProvider.notifier).open,
                          ),
                          AppIconButton(
                            icon: Icons.tune_rounded,
                            tooltip: filters.isActive ? 'Filtri, ${filters.activeCount} attivi' : 'Filtri',
                            badgeCount: filters.activeCount,
                            onPressed: () => context.push(AppRoutes.filters),
                          ),
                        ],
                      ),
                    if (!search.open) ...[
                      const SizedBox(height: 14),
                      PeriodTypeSelector(
                        selected: period.type,
                        onChanged: (type) => ref
                            .read(selectedPeriodProvider.notifier)
                            .changeType(type, today: today, weekStart: settings.weekStart),
                      ),
                      periodSelectorGap,
                      PeriodNavigator(
                        period: period,
                        today: today,
                        onShift: ref.read(selectedPeriodProvider.notifier).shift,
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.xs,
                    AppSpacing.screen,
                    AppSpacing.lg,
                  ),
                  children: search.open
                      ? _searchContent(context, ref, search, today, walletNames, categoryNames, labelNames)
                      : [
                          SummaryCard(
                            summary: summary,
                            walletsLabel: walletsLabel,
                            onTapWallets: () => context.push(AppRoutes.filters),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const UpcomingSection(),
                          ...switch (groupsAsync) {
                            AsyncValue(value: final groups?) when groups.isEmpty => [
                              _EmptyState(
                                filtered: filters.isActive,
                                onResetFilters: ref.read(activeFiltersProvider.notifier).reset,
                              ),
                            ],
                            AsyncValue(value: final groups?) => [
                              for (final group in groups)
                                _DaySection(
                                  group: group,
                                  today: today,
                                  walletNames: walletNames,
                                  categoryNames: categoryNames,
                                  labelNames: labelNames,
                                ),
                            ],
                            AsyncValue(hasError: true) => [
                              StateMessage.error(
                                what: 'i movimenti',
                                onRetry: () => ref.invalidate(transactionsInRangeProvider(period.range)),
                              ),
                            ],
                            _ => const <Widget>[],
                          },
                        ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Contenuto con la ricerca aperta: suggerimento, risultati per giorno o nessun risultato.
  List<Widget> _searchContent(
    BuildContext context,
    WidgetRef ref,
    SearchState search,
    LocalDate today,
    Map<String, String> walletNames,
    Map<String, String> categoryNames,
    Map<String, String> labelNames,
  ) {
    final filters = ref.watch(activeFiltersProvider);
    if (search.query.trim().isEmpty) {
      return const [
        StateMessage(
          icon: Icons.search_rounded,
          title: 'Cerca in tutto lo storico',
          message: 'Scrivi una parola della nota, una categoria, una label, un portafoglio o un importo come 64,20.',
        ),
      ];
    }
    final groups = ref.watch(searchDayGroupsProvider);
    return switch (groups) {
      AsyncValue(value: final groups?) when groups.isEmpty => [
        StateMessage(
          icon: Icons.search_off_rounded,
          title: 'Nessun risultato per «${search.query.trim()}»',
          message: filters.isActive
              ? 'Prova con un\'altra parola o togli i filtri attivi.'
              : 'Prova con un\'altra parola, una parte del nome o un importo come 64 o 64,20.',
          actionLabel: filters.isActive ? 'Azzera filtri' : null,
          onAction: filters.isActive ? ref.read(activeFiltersProvider.notifier).reset : null,
        ),
      ],
      AsyncValue(value: final groups?) => [
        _SearchSummary(groups: groups, activeFilters: filters.activeCount),
        const SizedBox(height: AppSpacing.md),
        for (final group in groups)
          _DaySection(
            group: group,
            today: today,
            walletNames: walletNames,
            categoryNames: categoryNames,
            labelNames: labelNames,
          ),
      ],
      AsyncValue(hasError: true) => [
        StateMessage.error(what: 'i risultati', onRetry: () => ref.invalidate(searchResultsProvider)),
      ],
      _ => const <Widget>[],
    };
  }
}

/// Campo di ricerca nell'intestazione. Il testo arriva alla ricerca 300 ms dopo l'ultimo tasto.
class _SearchHeader extends ConsumerStatefulWidget {
  const _SearchHeader();

  @override
  ConsumerState<_SearchHeader> createState() => _SearchHeaderState();
}

class _SearchHeaderState extends ConsumerState<_SearchHeader> {
  static const debounce = Duration(milliseconds: 300);

  late final _controller = TextEditingController(text: ref.read(transactionSearchProvider).query);
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _timer?.cancel();
    _timer = Timer(debounce, () => ref.read(transactionSearchProvider.notifier).setQuery(text));
    setState(() {}); // mostra o nasconde la ✕ del campo
  }

  void _clear() {
    _timer?.cancel();
    _controller.clear();
    ref.read(transactionSearchProvider.notifier).setQuery('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            autofocus: true,
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Nota, categoria, label, importo…',
              prefixIcon: Icon(Icons.search_rounded, color: colors.textMuted),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Cancella il testo',
                      icon: const Icon(Icons.cancel_rounded, size: 20),
                      onPressed: _clear,
                    ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppIconButton(
          icon: Icons.close_rounded,
          tooltip: 'Chiudi ricerca',
          onPressed: ref.read(transactionSearchProvider.notifier).close,
        ),
      ],
    );
  }
}

/// "12 risultati · + € 1.581,30" e i filtri attivi, sopra i risultati.
class _SearchSummary extends StatelessWidget {
  const _SearchSummary({required this.groups, required this.activeFilters});

  final List<DayGroup> groups;
  final int activeFilters;

  @override
  Widget build(BuildContext context) {
    final count = groups.fold(0, (sum, g) => sum + g.transactions.length);
    final counted = groups.any((g) => g.transactions.any(countsInStatistics));
    final total = groups.fold(0, (sum, g) => sum + g.totalCents);
    final parts = [
      count == 1 ? '1 risultato' : '$count risultati',
      if (counted) total > 0 ? '+ ${formatCents(total)}' : formatCents(total),
      if (activeFilters > 0) activeFilters == 1 ? 'con 1 filtro' : 'con $activeFilters filtri',
    ];
    return Semantics(liveRegion: true, child: Text(parts.join(' · '), style: Theme.of(context).textTheme.titleSmall));
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.group,
    required this.today,
    required this.walletNames,
    required this.categoryNames,
    required this.labelNames,
  });

  final DayGroup group;
  final LocalDate today;
  final Map<String, String> walletNames;
  final Map<String, String> categoryNames;
  final Map<String, String> labelNames;

  @override
  Widget build(BuildContext context) {
    final total = group.totalCents;
    // Una giornata con soli trasferimenti o rettifiche non ha un totale da mostrare.
    final totalText = !group.transactions.any(countsInStatistics)
        ? null
        : total > 0
        ? '+ ${formatCents(total)}'
        : formatCents(total);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(dayTitle(group.date, today), trailing: totalText),
          const SizedBox(height: AppSpacing.sm),
          AppListGroup(
            children: [
              for (final tx in group.transactions)
                TransactionTile(
                  transaction: tx,
                  walletNames: walletNames,
                  categoryNames: categoryNames,
                  labelNames: labelNames,
                  onTap: () => context.push(AppRoutes.transaction(tx.id)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filtered, required this.onResetFilters});

  final bool filtered;
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl, horizontal: AppSpacing.lg),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 40, color: colors.textMuted),
          const SizedBox(height: AppSpacing.md),
          Text(
            filtered ? 'Nessun movimento con questi filtri' : 'Nessun movimento nel periodo',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            filtered
                ? 'Prova a cambiare periodo o ad azzerare i filtri.'
                : 'Aggiungi una spesa o un\'entrata con i pulsanti qui sotto.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
          ),
          if (filtered) ...[
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: onResetFilters,
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, AppSizes.minTouchTarget)),
              child: const Text('Azzera filtri'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pulsanti fissi "− Spesa" e "+ Entrata".
class _AddButtons extends StatelessWidget {
  const _AddButtons();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Sopra la barra delle tab, che ha già il suo spazio di sistema: qui l'inset è zero.
    return BottomActionBar(
      color: colors.background,
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 10, AppSpacing.screen, AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: colors.expense.fill,
                foregroundColor: colors.expense.onFill,
              ),
              onPressed: () => context.push(AppRoutes.add('expense')),
              icon: const Icon(Icons.remove_rounded),
              label: const Text('Spesa'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: colors.income.fill, foregroundColor: colors.income.onFill),
              onPressed: () => context.push(AppRoutes.add('income')),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Entrata'),
            ),
          ),
        ],
      ),
    );
  }
}
