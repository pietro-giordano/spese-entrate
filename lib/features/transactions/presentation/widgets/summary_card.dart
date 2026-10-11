import 'package:flutter/material.dart';

import '../../../../core/money.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../domain/models/statistics.dart';
import '../../../wallets/presentation/widgets/balance_text.dart';

/// Card del riepilogo: saldo, entrate, uscite e quota spesa delle entrate.
class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.summary, required this.walletsLabel, required this.onTapWallets});

  final PeriodSummary summary;

  /// "Tutti i portafogli", il nome del portafoglio filtrato o "2 portafogli".
  final String walletsLabel;
  final VoidCallback onTapWallets;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final balance = summary.balanceCents;
    final ratio = summary.spentRatio;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Saldo del periodo',
                  style: textTheme.labelMedium?.copyWith(color: colors.textMuted, fontWeight: FontWeight.w600),
                ),
              ),
              _WalletsChip(label: walletsLabel, onTap: onTapWallets),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: BalanceText(
              balance,
              format: (cents) => cents > 0 ? '+ ${formatCents(cents)}' : formatCents(cents),
              style: textTheme.displaySmall?.copyWith(
                fontSize: 34,
                letterSpacing: -0.7,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Entrate',
                  dotColor: colors.income.fill,
                  amountColor: colors.income.text,
                  cents: summary.incomeCents,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _Metric(
                  label: 'Uscite',
                  dotColor: colors.expense.fill,
                  amountColor: colors.expense.text,
                  cents: summary.expenseCents,
                ),
              ),
            ],
          ),
          if (ratio != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 8,
                color: colors.income.tint,
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: ratio.clamp(0, 1).toDouble(),
                  child: Container(color: colors.expense.fill),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text('Hai speso il ${(ratio * 100).round()}% delle entrate', style: textTheme.bodySmall),
          ] else if (summary.expenseCents > 0) ...[
            const SizedBox(height: 14),
            Text('Nessuna entrata nel periodo', style: textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.dotColor, required this.amountColor, required this.cents});

  final String label;
  final Color dotColor;
  final Color amountColor;
  final int cents;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: textTheme.labelMedium?.copyWith(color: context.colors.textMuted, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            formatCents(cents),
            style: textTheme.titleLarge?.copyWith(
              color: amountColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

class _WalletsChip extends StatelessWidget {
  const _WalletsChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      container: true,
      button: true,
      label: '$label, cambia filtro portafogli',
      excludeSemantics: true,
      // 30 px visibili, area toccabile di 44.
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: AppSizes.minTouchTarget,
          child: Center(
            child: Container(
              height: 30,
              padding: const EdgeInsets.only(left: 10, right: 6),
              decoration: BoxDecoration(color: colors.neutral.tint, borderRadius: BorderRadius.circular(15)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.text),
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: colors.text),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
