import 'package:flutter/material.dart';

import '../../../../core/money.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../domain/models/wallet.dart';
import 'wallet_visuals.dart';

/// Patrimonio totale con la barra divisa per gruppi e la legenda.
class NetWorthCard extends StatelessWidget {
  const NetWorthCard({super.key, required this.totalCents, required this.groupTotals});

  final int totalCents;

  /// Totale di ogni gruppo presente (solo portafogli inclusi nel patrimonio).
  final Map<WalletGroup, int> groupTotals;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    // La barra mostra solo le quote positive (una carta in rosso non ha una "fetta").
    final positive = {
      for (final e in groupTotals.entries)
        if (e.value > 0) e.key: e.value,
    };
    final positiveSum = positive.values.fold(0, (a, b) => a + b);

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
          Text(
            'Patrimonio totale',
            style: textTheme.labelMedium?.copyWith(color: colors.textMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatCents(totalCents),
              style: textTheme.displaySmall?.copyWith(
                fontSize: 34,
                letterSpacing: -0.7,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (positiveSum > 0) ...[
            const SizedBox(height: 14),
            ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: SizedBox(
                  height: 10,
                  child: Row(
                    // Senza stretch le fette (ColoredBox senza figlio) avrebbero altezza zero.
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (index, MapEntry(key: group, value: total)) in positive.entries.indexed) ...[
                        if (index > 0) const SizedBox(width: 2),
                        Expanded(
                          flex: (total * 1000 ~/ positiveSum).clamp(1, 1000),
                          child: ColoredBox(color: walletGroupTone(context, group).fill),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          for (final MapEntry(key: group, value: total) in groupTotals.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: walletGroupTone(context, group).fill,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      walletGroupLabel(group),
                      style: textTheme.labelMedium?.copyWith(color: colors.neutral.onTint, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    formatCents(total),
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
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
