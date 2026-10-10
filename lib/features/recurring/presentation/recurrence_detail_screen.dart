import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/clock.dart';
import '../../../core/dates.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_list_row.dart';
import '../../../core/widgets/app_switch.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/screen_placeholder.dart';
import '../../../core/widgets/section_label.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/label.dart';
import '../../../domain/models/recurrence_exception.dart';
import '../../../domain/models/recurrence_rule.dart';
import '../../../domain/models/transaction.dart';
import '../../../domain/models/wallet.dart';
import '../../../domain/services/recurrence.dart';
import '../../settings/application/settings_providers.dart';
import '../../wallets/application/wallet_providers.dart';
import '../application/recurring_providers.dart';
import 'recurrence_text.dart';
import 'widgets/recurrence_widgets.dart';

/// Quante occorrenze future mostrare in "Prossime occorrenze".
const _upcomingCount = 3;

/// Dettaglio ricorrenza: riepilogo, pausa, prossime occorrenze con le loro azioni,
/// movimenti già registrati ed eliminazione.
class RecurrenceDetailScreen extends ConsumerWidget {
  const RecurrenceDetailScreen({super.key, required this.recurrenceId});

  final String recurrenceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(recurrenceRuleProvider(recurrenceId))) {
      AsyncValue(value: final rule?) => _RecurrenceDetail(rule: rule),
      AsyncValue(isLoading: true) => const Scaffold(body: SizedBox.shrink()),
      AsyncValue(hasError: true) => const ScreenPlaceholder(
        title: 'Ricorrenza',
        description: 'Non è stato possibile caricare la ricorrenza. Torna indietro e riprova.',
      ),
      _ => const ScreenPlaceholder(title: 'Ricorrenza', description: 'Questa ricorrenza non esiste più.'),
    };
  }
}

/// Una riga di "Prossime occorrenze".
class _Occurrence {
  const _Occurrence({required this.date, this.transaction, this.skipped = false, this.deleted = false});

  /// Data originale dell'occorrenza.
  final LocalDate date;

  /// Movimento già creato (di solito `pending`), se c'è.
  final Transaction? transaction;
  final bool skipped;

  /// Il suo movimento è stato eliminato (es. dal form di modifica): non si rigenera.
  final bool deleted;

  /// Saltata o eliminata: niente azioni, data barrata.
  bool get isGone => skipped || deleted;
}

class _RecurrenceDetail extends ConsumerWidget {
  const _RecurrenceDetail({required this.rule});

  final RecurrenceRule rule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final transactions = ref.watch(ruleTransactionsProvider(rule.id)).value ?? const <Transaction>[];
    final exceptions = (ref.watch(recurrenceExceptionsProvider).value ?? const <RecurrenceException>[])
        .where((e) => e.ruleId == rule.id)
        .map((e) => e.occurrenceDate)
        .toSet();
    final finished = isRuleFinished(rule, today);
    final history = transactions.where((tx) => tx.isConfirmed).sorted((a, b) => b.date.compareTo(a.date));
    final deleted = ref.watch(deletedOccurrencesProvider(rule.id)).value ?? const <LocalDate>{};
    final upcoming = _upcoming(transactions, exceptions, deleted, today);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 14, AppSpacing.screen, 10),
              child: Row(
                children: [
                  AppIconButton(icon: Icons.chevron_left_rounded, tooltip: 'Indietro', onPressed: () => context.pop()),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text('Ricorrenza', textAlign: TextAlign.center, style: textTheme.titleMedium),
                    ),
                  ),
                  // Bilancia il pulsante indietro: il titolo resta al centro.
                  const SizedBox(width: AppSizes.minTouchTarget),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.xs, AppSpacing.screen, AppSpacing.xxl),
                children: [
                  _SummaryCard(rule: rule, finished: finished),
                  if (!finished) ...[
                    const SizedBox(height: AppSpacing.lg),
                    const SectionLabel('Prossime occorrenze', indent: true),
                    const SizedBox(height: AppSpacing.sm),
                    AppListGroup(
                      children: [
                        for (final (index, occurrence) in upcoming.indexed)
                          _OccurrenceRow(
                            rule: rule,
                            occurrence: occurrence,
                            today: today,
                            // Come nel mockup: "Conferma" sulla prima da confermare.
                            showConfirm: index == upcoming.indexWhere(_isConfirmable),
                          ),
                      ],
                    ),
                  ],
                  if (history.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    const SectionLabel('Già registrate', indent: true),
                    const SizedBox(height: AppSpacing.sm),
                    AppListGroup(
                      children: [
                        for (final tx in history)
                          InkWell(
                            onTap: () => context.push(AppRoutes.transaction(tx.id)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _capitalized(longDate(tx.date)),
                                      style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  AmountText(
                                    tx.amountCents,
                                    kind: amountKindOf(tx.type),
                                    colored: tx.type == TransactionType.income,
                                    style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: colors.danger, minimumSize: const Size.fromHeight(48)),
                    onPressed: () => _delete(context, ref),
                    child: const Text('Elimina ricorrenza'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static bool _isConfirmable(_Occurrence o) => o.transaction != null && !o.transaction!.isConfirmed;

  /// `pending` scaduti, poi le prossime [_upcomingCount] occorrenze non ancora confermate
  /// (le saltate restano visibili, barrate).
  List<_Occurrence> _upcoming(
    List<Transaction> transactions,
    Set<LocalDate> skipped,
    Set<LocalDate> deleted,
    LocalDate today,
  ) {
    final bySlot = {for (final tx in transactions) tx.occurrenceDate: tx};
    final overdue = [
      for (final tx in transactions)
        if (!tx.isConfirmed && tx.occurrenceDate != null && tx.occurrenceDate!.isBefore(today))
          _Occurrence(date: tx.occurrenceDate!, transaction: tx),
    ].sorted((a, b) => a.date.compareTo(b.date));
    final next = occurrenceDates(rule)
        .skipWhile((d) => d.isBefore(today))
        .where((d) => !(bySlot[d]?.isConfirmed ?? false))
        .take(_upcomingCount)
        .map(
          (d) => _Occurrence(
            date: d,
            transaction: bySlot[d],
            skipped: skipped.contains(d),
            deleted: !skipped.contains(d) && deleted.contains(d),
          ),
        );
    return [...overdue, ...next];
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Eliminare la ricorrenza?',
      message:
          'I movimenti già registrati restano nei movimenti. Da ora non verranno più create nuove occorrenze '
          'e quelle ancora da confermare spariscono.',
      confirmLabel: 'Elimina',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(recurrenceActionsProvider).delete(rule.id);
    if (!context.mounted) return;
    context.pop();
    messenger.showSnackBar(SnackBar(content: Text('Ricorrenza «${rule.name}» eliminata')));
  }
}

String _capitalized(String text) => text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

class _SummaryCard extends ConsumerWidget {
  const _SummaryCard({required this.rule, required this.finished});

  final RecurrenceRule rule;
  final bool finished;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final category = (ref.watch(categoriesProvider).value ?? const <Category>[]).firstWhereOrNull(
      (c) => c.id == rule.categoryId,
    );
    final labels = {for (final l in ref.watch(labelsProvider).value ?? const <Label>[]) l.id: l.name};
    final wallets = {for (final w in ref.watch(walletsProvider).value ?? const <Wallet>[]) w.id: w.name};

    final (badge, tone) = switch (rule) {
      _ when rule.isPaused => ('In pausa', colors.neutral),
      _ when finished => ('Conclusa', colors.neutral),
      RecurrenceRule(mode: RecurrenceMode.confirm) => ('Da confermare', colors.expense),
      _ => ('Automatico', colors.neutral),
    };
    final kind = switch (rule.type) {
      TransactionType.income => 'Entrata',
      TransactionType.transfer => 'Trasferimento',
      _ => 'Spesa',
    };
    final tags = rule.labelIds.map((id) => labels[id]).nonNulls.map((name) => '#$name').join(' ');
    final meta = [kind, ?category?.name, if (tags.isNotEmpty) tags].join(' · ');
    final where = rule.type == TransactionType.transfer
        ? 'da ${wallets[rule.walletId] ?? '—'} a ${wallets[rule.toWalletId] ?? '—'}'
        : '${rule.type == TransactionType.income ? 'su' : 'da'} ${wallets[rule.walletId] ?? '—'}';
    final schedule = [describeSchedule(rule), ?describeEnd(rule), where].join(' · ');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RecurrenceBadge(label: badge, tone: tone),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(color: colors.textMuted, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(rule.name, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          AmountText(
            rule.amountCents,
            kind: amountKindOf(rule.type),
            colored: rule.type == TransactionType.income,
            style: textTheme.headlineMedium?.copyWith(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            schedule,
            style: textTheme.bodySmall?.copyWith(color: colors.neutral.onTint, fontWeight: FontWeight.w600),
          ),
          if (!finished) ...[
            const SizedBox(height: AppSpacing.md),
            Divider(height: 1, color: colors.divider),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Metti in pausa', style: textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        'Nessuna occorrenza verrà creata finché è in pausa. Alla ripresa quelle saltate non si recuperano.',
                        style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AppSwitch(
                  value: rule.isPaused,
                  semanticLabel: 'Metti in pausa',
                  onChanged: (paused) => ref.read(recurrenceActionsProvider).setPaused(rule.id, paused: paused),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _OccurrenceRow extends ConsumerWidget {
  const _OccurrenceRow({required this.rule, required this.occurrence, required this.today, required this.showConfirm});

  final RecurrenceRule rule;
  final _Occurrence occurrence;
  final LocalDate today;
  final bool showConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final tx = occurrence.transaction;
    final note = switch (occurrence) {
      _Occurrence(skipped: true) => 'Saltata',
      _Occurrence(deleted: true) => 'Eliminata',
      _ when rule.isPaused => 'In pausa',
      _Occurrence(transaction: final tx?) when !canConfirmManually(tx, rule) =>
        tx.date != occurrence.date
            ? 'Verrà registrata automaticamente il ${shortDate(tx.date, today)}'
            : 'Verrà registrata automaticamente',
      _Occurrence(transaction: _?) when occurrence.date.isBefore(today) => 'Da confermare · scaduta',
      _Occurrence(transaction: final tx?) when tx.date != occurrence.date =>
        'Da confermare · spostata al ${shortDate(tx.date, today)}',
      _Occurrence(transaction: _?) => 'Da confermare',
      _ when rule.mode == RecurrenceMode.auto => 'Verrà registrata automaticamente',
      _ => 'Verrà proposta da confermare',
    };
    final dateText = _capitalized(longDate(occurrence.date));

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateText,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      decoration: occurrence.isGone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(note, style: textTheme.bodySmall?.copyWith(color: colors.textMuted)),
                ],
              ),
            ),
            if (showConfirm && tx != null && !rule.isPaused && canConfirmManually(tx, rule))
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.neutral.fill,
                  foregroundColor: colors.neutral.onFill,
                  minimumSize: const Size(44, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                onPressed: () => context.push(AppRoutes.confirm(tx.id)),
                child: const Text('Conferma'),
              ),
            if (!occurrence.isGone)
              IconButton(
                tooltip: 'Opzioni per $dateText',
                icon: Icon(Icons.more_horiz_rounded, color: colors.neutral.onTint),
                onPressed: () => _openMenu(context, ref),
              )
            else
              const SizedBox(width: AppSizes.minTouchTarget),
          ],
        ),
      ),
    );
  }

  Future<void> _openMenu(BuildContext context, WidgetRef ref) async {
    final dayMonth = shortDate(occurrence.date, today);
    final action = await AppBottomSheet.show<_OccurrenceAction>(
      context,
      title: 'Occorrenza del $dayMonth',
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final action in _OccurrenceAction.values) ...[
            _ActionCard(action: action, onTap: () => Navigator.pop(sheetContext, action)),
            const SizedBox(height: 10),
          ],
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () => Navigator.pop(sheetContext),
            child: const Text('Annulla'),
          ),
        ],
      ),
    );
    if (action == null || !context.mounted) return;

    final actions = ref.read(recurrenceActionsProvider);
    final messenger = ScaffoldMessenger.of(context);
    switch (action) {
      case _OccurrenceAction.skip:
        await actions.skip(rule.id, occurrence.date);
        messenger.showSnackBar(SnackBar(content: Text('Occorrenza del $dayMonth saltata')));
      case _OccurrenceAction.editSingle || _OccurrenceAction.editFollowing:
        // Un'occorrenza futura non esiste ancora: si crea come `pending` per poterla modificare.
        final tx = await actions.occurrenceTransaction(rule.id, occurrence.date);
        if (tx == null || !context.mounted) return;
        context.push(
          action == _OccurrenceAction.editSingle ? AppRoutes.transaction(tx.id) : AppRoutes.transactionFollowing(tx.id),
        );
    }
  }
}

enum _OccurrenceAction {
  skip('Salta solo questa', 'Le successive restano invariate'),
  editSingle('Modifica solo questa', 'Es. importo o data diversi per questa volta'),
  editFollowing('Modifica questa e le successive', 'Quelle già registrate non cambiano');

  const _OccurrenceAction(this.title, this.subtitle);

  final String title;
  final String subtitle;
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action, required this.onTap});

  final _OccurrenceAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final borderRadius = BorderRadius.circular(14);
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action.title, style: textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(action.subtitle, style: textTheme.bodySmall?.copyWith(color: colors.textMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
