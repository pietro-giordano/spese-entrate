import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/clock.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/bottom_action_bar.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_list_row.dart';
import '../../../core/widgets/screen_placeholder.dart';
import '../../../core/widgets/section_label.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/label.dart';
import '../../../domain/models/wallet.dart';
import '../../settings/application/settings_providers.dart';
import '../../transactions/presentation/widgets/transaction_tile.dart';
import '../application/wallet_providers.dart';
import '../application/balance_visibility.dart';
import 'widgets/balance_chart.dart';
import 'widgets/balance_text.dart';
import 'widgets/update_balance_sheet.dart';
import 'widgets/wallet_visuals.dart';

/// Dettaglio portafoglio: saldo, "Aggiorna saldo", andamento e movimenti.
class WalletDetailScreen extends ConsumerWidget {
  const WalletDetailScreen({super.key, required this.walletId});

  final String walletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(walletOverviewProvider(walletId));
    final overview = overviewAsync.value;
    if (overview == null) {
      return switch (overviewAsync) {
        AsyncValue(isLoading: true) => const Scaffold(body: SizedBox.shrink()),
        AsyncValue(hasError: true) => const ScreenPlaceholder(
          title: 'Portafoglio',
          description: 'Non è stato possibile caricare il portafoglio. Torna indietro e riprova.',
        ),
        _ => const ScreenPlaceholder(title: 'Portafoglio', description: 'Questo portafoglio non esiste più.'),
      };
    }

    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final wallet = overview.wallet;
    final tone = walletGroupTone(context, wallet.type.group);
    final today = ref.watch(todayProvider);
    final history = ref.watch(walletBalanceHistoryProvider(walletId)).value ?? const [];
    final balancesHidden = ref.watch(balancesHiddenProvider);
    final transactions = ref.watch(walletTransactionsProvider(walletId)).value ?? const [];
    final walletNames = {for (final w in ref.watch(walletsProvider).value ?? const <Wallet>[]) w.id: w.name};
    final categoryNames = {for (final c in ref.watch(categoriesProvider).value ?? const <Category>[]) c.id: c.name};
    final labelNames = {for (final l in ref.watch(labelsProvider).value ?? const <Label>[]) l.id: l.name};

    final updatedText = overview.lastUpdate == today
        ? 'Aggiornato oggi'
        : 'Aggiornato il ${DateFormat('d MMM y', 'it_IT').format(overview.lastUpdate.toDateTime())}';

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
                      // Il nome va a capo invece di troncarsi.
                      child: Text(wallet.name, textAlign: TextAlign.center, style: textTheme.titleMedium),
                    ),
                  ),
                  AppIconButton(
                    icon: Icons.edit_outlined,
                    tooltip: 'Modifica portafoglio',
                    onPressed: () => context.push(AppRoutes.editWallet(walletId)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.xs,
                  AppSpacing.screen,
                  AppSpacing.xl + bottomSystemInset(context),
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border.all(color: colors.border),
                      borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            WalletBadge(text: walletGroupLabel(wallet.type.group), tone: tone),
                            Text(
                              wallet.isArchived
                                  ? 'Archiviato'
                                  : wallet.includeInTotal
                                  ? 'Incluso nel patrimonio'
                                  : 'Escluso dal patrimonio',
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Saldo',
                          style: textTheme.labelMedium?.copyWith(color: colors.textMuted, fontWeight: FontWeight.w600),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: BalanceText(
                            overview.balanceCents,
                            style: textTheme.displaySmall?.copyWith(
                              fontSize: 34,
                              letterSpacing: -0.7,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        Wrap(
                          spacing: AppSpacing.sm,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              updatedText,
                              style: textTheme.labelMedium?.copyWith(
                                color: colors.neutral.onTint,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (overview.needsUpdate) WalletBadge(text: 'Da aggiornare', tone: colors.expense),
                          ],
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            textStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final saved = await showUpdateBalanceSheet(context, wallet);
                            if (saved == true) {
                              messenger.showSnackBar(const SnackBar(content: Text('Saldo aggiornato')));
                            }
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 20),
                          label: const Text('Aggiorna saldo'),
                        ),
                      ],
                    ),
                  ),
                  if (history.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    // Con i saldi nascosti anche la forma della linea direbbe troppo: niente grafico.
                    if (balancesHidden)
                      Text(
                        'Mostra i saldi per visualizzare l\'andamento',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
                      )
                    else
                      BalanceChart(points: history, color: tone.text),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  const SectionLabel('Movimenti di questo portafoglio'),
                  const SizedBox(height: AppSpacing.sm),
                  if (transactions.isEmpty)
                    Text('Ancora nessun movimento.', style: textTheme.bodyMedium?.copyWith(color: colors.textMuted))
                  else
                    AppListGroup(
                      children: [
                        for (final tx in transactions)
                          TransactionTile(
                            transaction: tx,
                            walletId: walletId,
                            walletNames: walletNames,
                            categoryNames: categoryNames,
                            labelNames: labelNames,
                            onTap: () => context.push(AppRoutes.transaction(tx.id)),
                          ),
                      ],
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
