import 'package:flutter/material.dart';

import '../../../../core/dates.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../application/wallet_providers.dart';
import 'balance_text.dart';
import 'wallet_visuals.dart';

/// Riga di un portafoglio: icona, nome, ultimo aggiornamento con i badge, saldo.
class WalletRow extends StatelessWidget {
  const WalletRow({super.key, required this.overview, required this.today, required this.onTap});

  final WalletOverview overview;
  final LocalDate today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final wallet = overview.wallet;

    final defaultLabel = switch ((overview.isDefaultForExpenses, overview.isDefaultForIncome)) {
      (true, true) => 'Predefinito spese ed entrate',
      (true, false) => 'Predefinito spese',
      (false, true) => 'Predefinito entrate',
      _ => null,
    };

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
        child: Row(
          children: [
            WalletIcon(type: wallet.type, muted: wallet.isArchived),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(wallet.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.titleSmall),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        wallet.isArchived ? 'Archiviato' : lastUpdateLabel(overview.lastUpdate, today),
                        style: textTheme.bodySmall,
                      ),
                      if (defaultLabel != null) WalletBadge(text: defaultLabel, tone: colors.liquidity),
                      if (overview.needsUpdate && !wallet.isArchived)
                        WalletBadge(text: 'Da aggiornare', tone: colors.expense),
                      if (!wallet.includeInTotal && !wallet.isArchived)
                        WalletBadge(text: 'Escluso dal patrimonio', tone: colors.neutral),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            BalanceText(
              overview.balanceCents,
              textAlign: TextAlign.end,
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: wallet.isArchived ? colors.textMuted : colors.text,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
