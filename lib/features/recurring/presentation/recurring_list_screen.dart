import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/clock.dart';
import '../../../core/dates.dart';
import '../../../core/money.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_list_row.dart';
import '../../../core/widgets/dashed_border.dart';
import '../../../core/widgets/section_label.dart';
import '../../../core/widgets/state_message.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/recurrence_exception.dart';
import '../../../domain/models/recurrence_rule.dart';
import '../../../domain/models/transaction.dart';
import '../../../domain/models/wallet.dart';
import '../../../domain/services/recurrence.dart';
import '../../settings/application/settings_providers.dart';
import '../../transactions/application/transaction_providers.dart';
import '../../wallets/application/wallet_providers.dart';
import '../application/recurring_providers.dart';
import 'recurrence_text.dart';
import 'widgets/recurrence_widgets.dart';

/// Movimenti ricorrenti: totali fissi del mese e regole divise in attive, in pausa e concluse.
class RecurringListScreen extends ConsumerWidget {
  const RecurringListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final rulesAsync = ref.watch(recurrenceRulesProvider);
    final rules = rulesAsync.value ?? const <RecurrenceRule>[];
    final exceptions = ref.watch(recurrenceExceptionsProvider).value ?? const <RecurrenceException>[];
    final transactions = ref.watch(allTransactionsProvider).value ?? const <Transaction>[];
    final totals = ref.watch(recurringTotalsThisMonthProvider).value;
    final names = _Names(
      categories: {for (final c in ref.watch(categoriesProvider).value ?? const <Category>[]) c.id: c.name},
      wallets: {for (final w in ref.watch(walletsProvider).value ?? const <Wallet>[]) w.id: w.name},
    );

    final finished = rules.where((r) => !r.isPaused && isRuleFinished(r, today)).toList();
    final paused = rules.where((r) => r.isPaused).toList();
    final active = rules.where((r) => !r.isPaused && !finished.contains(r)).toList();
    final next = {for (final rule in active) rule.id: _nextDue(rule, exceptions, transactions, today)};
    // Le attive in ordine di prossima occorrenza, come nel mockup.
    active.sort((a, b) => (next[a.id] ?? today).compareTo(next[b.id] ?? today));

    final monthName = DateFormat.MMMM('it_IT').format(today.toDateTime());

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 14, AppSpacing.screen, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      AppIconButton(
                        icon: Icons.chevron_left_rounded,
                        tooltip: 'Indietro',
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text('Movimenti ricorrenti', style: textTheme.headlineMedium?.copyWith(fontSize: 22)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Le due card alte uguali anche quando solo una mostra la media.
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _TotalCard(
                            label: 'Uscite fisse a $monthName',
                            cents: totals?.expenseInMonth ?? 0,
                            color: colors.expense.text,
                            average: totals != null && totals.expenseHasNonMonthly
                                ? totals.expenseMonthlyAverage
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TotalCard(
                            label: 'Entrate fisse a $monthName',
                            cents: totals?.incomeInMonth ?? 0,
                            color: colors.income.text,
                            average: totals != null && totals.incomeHasNonMonthly ? totals.incomeMonthlyAverage : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.xs, AppSpacing.screen, AppSpacing.xxl),
                children: [
                  if (rulesAsync.hasError && rulesAsync.value == null)
                    StateMessage.error(what: 'le ricorrenze', onRetry: () => ref.invalidate(recurrenceRulesProvider))
                  else if (rulesAsync.hasValue && rules.isEmpty) ...[
                    Text('Nessun movimento ricorrente.', style: textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Affitto, abbonamenti, stipendio: crea una ricorrenza e i movimenti si registrano da soli '
                      'o compaiono in "In arrivo" da confermare.',
                      style: textTheme.bodySmall?.copyWith(height: 1.45),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  for (final (title, group) in [('Attive', active), ('In pausa', paused), ('Concluse', finished)])
                    if (group.isNotEmpty) ...[
                      SectionLabel(title, indent: true),
                      const SizedBox(height: AppSpacing.sm),
                      AppListGroup(
                        children: [
                          for (final rule in group)
                            _RuleRow(rule: rule, names: names, nextDue: next[rule.id], today: today),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  _NewRecurrenceButton(onTap: () => context.push(AppRoutes.add('expense', repeat: true))),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Le ricorrenze si creano anche dall\'inserimento rapido, con "Ripeti" nel pannello della data.',
                    style: textTheme.bodySmall?.copyWith(height: 1.45),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Prossima occorrenza ancora da registrare: da oggi in poi, non saltata e non già confermata.
LocalDate? _nextDue(
  RecurrenceRule rule,
  List<RecurrenceException> exceptions,
  List<Transaction> transactions,
  LocalDate today,
) {
  final skipped = {for (final e in exceptions.where((e) => e.ruleId == rule.id)) e.occurrenceDate};
  final confirmed = {
    for (final tx in transactions)
      if (tx.recurrenceId == rule.id && tx.isConfirmed) tx.occurrenceDate,
  };
  return occurrenceDates(rule)
      .skipWhile((d) => d.isBefore(today))
      .firstWhereOrNull((d) => !skipped.contains(d) && !confirmed.contains(d));
}

class _Names {
  const _Names({required this.categories, required this.wallets});

  final Map<String, String> categories;
  final Map<String, String> wallets;

  /// "Casa" per spese ed entrate, "Conto corrente → ETF" per i trasferimenti.
  String detailOf(RecurrenceRule rule) => rule.type == TransactionType.transfer
      ? '${wallets[rule.walletId] ?? '—'} → ${wallets[rule.toWalletId] ?? '—'}'
      : categories[rule.categoryId] ?? '—';
}

/// Card di un totale: effettivo del mese e, se ci sono regole non mensili, la media prevista.
class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.label, required this.cents, required this.color, this.average});

  final String label;
  final int cents;
  final Color color;
  final int? average;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(color: colors.textMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: AmountText(
              cents,
              style: textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w800),
            ),
          ),
          if (average != null) ...[
            const SizedBox(height: 4),
            Text(
              'Media mensile prevista ${formatCents(average!)}',
              style: textTheme.labelSmall?.copyWith(color: colors.textMuted, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.rule, required this.names, required this.nextDue, required this.today});

  final RecurrenceRule rule;
  final _Names names;
  final LocalDate? nextDue;
  final LocalDate today;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final finished = !rule.isPaused && isRuleFinished(rule, today);
    final (badge, badgeTone) = switch (rule) {
      _ when rule.isPaused => ('In pausa', colors.neutral),
      _ when finished => ('Conclusa', colors.neutral),
      RecurrenceRule(mode: RecurrenceMode.confirm) => ('Da confermare', colors.expense),
      _ => ('Automatico', colors.neutral),
    };
    final status = switch (rule) {
      _ when rule.isPaused => 'In pausa dal ${shortDate(LocalDate.fromDateTime(rule.pausedAt!.toLocal()), today)}',
      _ when finished => switch (previousOccurrence(rule, today)) {
        final last? => 'Ultima: ${shortDate(last, today)}',
        null => 'Nessuna occorrenza',
      },
      _ => switch (nextDue) {
        final next? when next == today => 'Prossima: oggi',
        final next? => 'Prossima: ${shortDate(next, today)}',
        null => 'Nessuna in programma',
      },
    };

    return Opacity(
      opacity: rule.isPaused || finished ? 0.7 : 1,
      child: InkWell(
        onTap: () => context.push(AppRoutes.recurrence(rule.id)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              RecurrenceIcon(type: rule.type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rule.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.titleSmall),
                    const SizedBox(height: 3),
                    Text(
                      '${describeSchedule(rule)} · ${names.detailOf(rule)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(color: colors.textMuted, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    // Wrap: con testi grandi lo stato va a capo invece di uscire dalla riga.
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        RecurrenceBadge(label: badge, tone: badgeTone),
                        Text(status, style: textTheme.labelSmall?.copyWith(color: colors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AmountText(
                rule.amountCents,
                kind: amountKindOf(rule.type),
                colored: rule.type == TransactionType.income,
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "+ Nuova ricorrenza" con bordo tratteggiato.
class _NewRecurrenceButton extends StatelessWidget {
  const _NewRecurrenceButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return CustomPaint(
      foregroundPainter: DashedBorderPainter(color: colors.textMuted, radius: 16),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
            height: 52,
            child: Center(
              child: Text(
                '+ Nuova ricorrenza',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
