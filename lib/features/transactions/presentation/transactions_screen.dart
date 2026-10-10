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
import '../../../core/widgets/app_list_row.dart';
import '../../../core/widgets/section_label.dart';
import '../../../domain/models/app_settings.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/label.dart';
import '../../../domain/models/statistics.dart';
import '../../../domain/services/statistics.dart';
import '../../../domain/services/transaction_list.dart';
import '../../settings/application/settings_providers.dart';
import '../../wallets/application/wallet_providers.dart';
import '../application/transaction_list_providers.dart';
import 'period_labels.dart';
import 'widgets/period_selector.dart';
import 'widgets/summary_card.dart';
import 'widgets/transaction_tile.dart';

/// Tab Movimenti (home): periodo, riepilogo e lista per giorno.
class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
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

    final walletsLabel = switch (filters.walletIds.length) {
      0 => 'Tutti i portafogli',
      1 => walletNames[filters.walletIds.single] ?? '1 portafoglio',
      final count => '$count portafogli',
    };

    return Scaffold(
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
                  Row(
                    children: [
                      Expanded(
                        child: Semantics(header: true, child: Text('Movimenti', style: textTheme.headlineLarge)),
                      ),
                      const AppIconButton(icon: Icons.search_rounded, tooltip: 'Cerca', onPressed: null),
                      const SizedBox(width: AppSpacing.sm),
                      AppIconButton(
                        icon: Icons.tune_rounded,
                        tooltip: filters.isActive ? 'Filtri, ${filters.activeCount} attivi' : 'Filtri',
                        badgeCount: filters.activeCount,
                        onPressed: () => context.push(AppRoutes.filters),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AppIconButton(
                        icon: Icons.person_outline_rounded,
                        tooltip: 'Profilo e impostazioni',
                        round: true,
                        onPressed: () => context.push(AppRoutes.settings),
                      ),
                    ],
                  ),
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
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.xs, AppSpacing.screen, AppSpacing.lg),
                children: [
                  SummaryCard(
                    summary: summary,
                    walletsLabel: walletsLabel,
                    onTapWallets: () => context.push(AppRoutes.filters),
                  ),
                  const SizedBox(height: AppSpacing.lg),
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
                      Text('Non è stato possibile caricare i movimenti.', style: textTheme.bodyMedium),
                    ],
                    _ => const <Widget>[],
                  },
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Padding(
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
                style: FilledButton.styleFrom(
                  backgroundColor: colors.income.fill,
                  foregroundColor: colors.income.onFill,
                ),
                onPressed: () => context.push(AppRoutes.add('income')),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Entrata'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
