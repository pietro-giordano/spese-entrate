import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/clock.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/money.dart';
import '../../../../core/widgets/dashed_border.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../../domain/models/category.dart';
import '../../../../domain/models/enums.dart';
import '../../../../domain/models/recurrence_rule.dart';
import '../../../../domain/models/transaction.dart';
import '../../../settings/application/settings_providers.dart';
import '../../../../domain/services/recurrence.dart';
import '../../application/recurring_providers.dart';
import '../recurrence_text.dart';
import 'recurrence_widgets.dart';

/// Sezione "In arrivo · prossimi 7 giorni" della home: i movimenti ricorrenti da confermare.
/// Non compare se non c'è nulla da confermare.
class UpcomingSection extends ConsumerWidget {
  const UpcomingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingTransactionsProvider).value ?? const [];
    if (upcoming.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;
    final rules = {
      for (final rule in ref.watch(recurrenceRulesProvider).value ?? const <RecurrenceRule>[]) rule.id: rule,
    };
    final categories = ref.watch(categoriesProvider).value ?? const <Category>[];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(child: SectionLabel('In arrivo · prossimi 7 giorni')),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: colors.income.text,
                  minimumSize: const Size(44, 32),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                ),
                onPressed: () => context.push(AppRoutes.recurring),
                child: const Text('Tutti'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          CustomPaint(
            foregroundPainter: DashedBorderPainter(color: colors.borderStrong, radius: 18),
            child: Material(
              color: colors.surface,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final (index, tx) in upcoming.indexed) ...[
                    if (index > 0) Divider(height: 1, indent: 14, endIndent: 14, color: colors.divider),
                    _UpcomingRow(
                      transaction: tx,
                      rule: rules[tx.recurrenceId],
                      title: switch (rules[tx.recurrenceId]) {
                        final rule? => recurrenceTitle(
                          rule,
                          categoryName: categories.firstWhereOrNull((c) => c.id == rule.categoryId)?.name,
                        ),
                        null =>
                          tx.note ?? categories.firstWhereOrNull((c) => c.id == tx.categoryId)?.name ?? 'Movimento',
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingRow extends ConsumerWidget {
  const _UpcomingRow({required this.transaction, required this.rule, required this.title});

  final Transaction transaction;
  final RecurrenceRule? rule;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final tx = transaction;
    final overdue = tx.date.isBefore(today);
    final when = tx.date == today ? 'oggi' : weekdayDate(tx.date, today);

    return InkWell(
      onTap: () => context.push(AppRoutes.transaction(tx.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            RecurrenceIcon(type: tx.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '$when · '),
                        if (overdue)
                          TextSpan(
                            text: 'scaduto · ',
                            style: TextStyle(color: colors.danger),
                          ),
                        TextSpan(text: _signedAmount(tx)),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textMuted,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (!canConfirmManually(tx, rule))
              // Automatica: si registra da sola alla data, niente conferma anticipata.
              Text(
                'Automatica · ${shortDate(tx.date, today)}',
                style: textTheme.labelSmall?.copyWith(color: colors.textMuted, fontWeight: FontWeight.w700),
              )
            else
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
                child: Semantics(label: 'Conferma $title', excludeSemantics: true, child: const Text('Conferma')),
              ),
          ],
        ),
      ),
    );
  }
}

/// "− € 64,00", "+ € 2.400,00" o "€ 500,00" (trasferimenti).
String _signedAmount(Transaction tx) => switch (tx.type) {
  TransactionType.expense => '$minusSign ${formatCents(tx.amountCents)}',
  TransactionType.income => '+ ${formatCents(tx.amountCents)}',
  _ => formatCents(tx.amountCents),
};
