import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/money.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../domain/models/enums.dart';
import '../../../../domain/models/transaction.dart';

/// Riga di un movimento nella lista.
///
/// Spese: importo in colore testo con "−". Entrate: colore entrata con "+".
/// Trasferimenti e rettifiche: stile neutro, icona su sfondo grigio.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.walletNames,
    required this.categoryNames,
    required this.labelNames,
    required this.onTap,
    this.walletId,
  });

  /// Con un portafoglio, la riga è vista "da lì" (dettaglio portafoglio): data nel sottotitolo,
  /// trasferimenti come "da / verso" con il segno, rettifiche come aggiornamento del saldo.
  final String? walletId;

  final Transaction transaction;
  final Map<String, String> walletNames;
  final Map<String, String> categoryNames;
  final Map<String, String> labelNames;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final tx = transaction;
    final wallet = walletNames[tx.walletId] ?? '—';
    final category = categoryNames[tx.categoryId];

    final incoming = tx.toWalletId != null && tx.toWalletId == walletId;
    final (String title, String baseSubtitle) = switch (tx.type) {
      TransactionType.transfer when walletId != null => (
        tx.note ?? 'Trasferimento',
        incoming ? 'da $wallet' : 'verso ${walletNames[tx.toWalletId] ?? '—'}',
      ),
      TransactionType.transfer => (tx.note ?? 'Trasferimento', '$wallet → ${walletNames[tx.toWalletId] ?? '—'}'),
      TransactionType.adjustment => (
        tx.note ?? 'Rettifica di valore',
        walletId != null ? 'aggiornamento saldo' : wallet,
      ),
      _ when walletId != null => (tx.note ?? category ?? 'Senza categoria', tx.note != null ? (category ?? '') : ''),
      _ when tx.note != null => (tx.note!, '${category ?? 'Senza categoria'} · $wallet'),
      _ => (category ?? 'Senza categoria', wallet),
    };
    final subtitle = walletId == null
        ? baseSubtitle
        : [
            DateFormat('d MMM', 'it_IT').format(tx.date.toDateTime()),
            baseSubtitle,
          ].where((p) => p.isNotEmpty).join(' · ');
    final tags = compactLabelTags(tx.labelIds.map((id) => labelNames[id]).nonNulls.toList());

    final amountStyle = textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w800,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final (String amount, Color amountColor) = switch (tx.type) {
      TransactionType.expense => ('$minusSign ${formatCents(tx.amountCents)}', colors.text),
      TransactionType.income => ('+ ${formatCents(tx.amountCents)}', colors.income.text),
      TransactionType.transfer when walletId != null => (
        incoming ? '+ ${formatCents(tx.amountCents)}' : '$minusSign ${formatCents(tx.amountCents)}',
        colors.text,
      ),
      TransactionType.transfer => (formatCents(tx.amountCents), colors.textMuted),
      TransactionType.adjustment => (
        tx.amountCents > 0 ? '+ ${formatCents(tx.amountCents)}' : formatCents(tx.amountCents),
        walletId != null ? colors.text : colors.textMuted,
      ),
    };

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
        child: Row(
          children: [
            _Icon(transaction: tx, category: category),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      text: subtitle,
                      children: [
                        if (tags.isNotEmpty)
                          TextSpan(
                            text: ' $tags',
                            style: TextStyle(color: colors.income.onTint),
                          ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(amount, style: amountStyle?.copyWith(color: amountColor)),
          ],
        ),
      ),
    );
  }
}

class _Icon extends StatelessWidget {
  const _Icon({required this.transaction, required this.category});

  final Transaction transaction;
  final String? category;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (Color background, Color foreground) = switch (transaction.type) {
      TransactionType.expense => (colors.expense.tint, colors.expense.onTint),
      TransactionType.income => (colors.income.tint, colors.income.onTint),
      _ => (colors.track, colors.neutral.onTint),
    };
    final Widget content = switch (transaction.type) {
      TransactionType.transfer => Icon(Icons.swap_horiz_rounded, size: 20, color: foreground),
      TransactionType.adjustment => Icon(Icons.tune_rounded, size: 18, color: foreground),
      _ => Text(
        (category ?? '?').characters.first.toUpperCase(),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800, color: foreground),
      ),
    };

    return ExcludeSemantics(
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.field)),
        child: content,
      ),
    );
  }
}

/// Label in una riga di lista: le prime [max], poi "+N" per le altre ("#casa #auto +2").
/// Nei dettagli invece si mostrano tutte (vedi `LabelTags`).
String compactLabelTags(List<String> names, {int max = 2}) =>
    [for (final name in names.take(max)) '#$name', if (names.length > max) '+${names.length - max}'].join(' ');
