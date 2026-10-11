import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/clock.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/tab_header.dart';
import '../../../core/widgets/app_list_row.dart';
import '../../../core/widgets/section_label.dart';
import '../../../core/widgets/state_message.dart';
import '../../../domain/models/wallet.dart';
import '../application/balance_visibility.dart';
import '../application/wallet_providers.dart';
import 'widgets/balance_text.dart';
import 'widgets/net_worth_card.dart';
import 'widgets/wallet_row.dart';
import 'widgets/wallet_visuals.dart';

/// Tab Portafogli: patrimonio per gruppo e portafogli raggruppati.
class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final overviewsAsync = ref.watch(walletOverviewsProvider);
    final balancesHidden = ref.watch(balancesHiddenProvider);
    final overviews = overviewsAsync.value ?? const <WalletOverview>[];

    final active = overviews.where((o) => !o.wallet.isArchived).toList();
    final archived = overviews.where((o) => o.wallet.isArchived).toList();
    final included = active.where((o) => o.countsInNetWorth);
    final byGroup = {
      for (final group in WalletGroup.values) group: active.where((o) => o.wallet.type.group == group).toList(),
    }..removeWhere((_, list) => list.isEmpty);
    int sum(Iterable<WalletOverview> list) => list.fold(0, (total, o) => total + o.balanceCents);
    final groupTotals = {
      for (final group in byGroup.keys) group: sum(included.where((o) => o.wallet.type.group == group)),
    };

    Widget section(String title, int? totalCents, List<WalletOverview> list) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(title, trailingWidget: totalCents == null ? null : BalanceText(totalCents)),
          const SizedBox(height: AppSpacing.sm),
          AppListGroup(
            children: [
              for (final overview in list)
                WalletRow(
                  overview: overview,
                  today: today,
                  onTap: () => context.push(AppRoutes.wallet(overview.wallet.id)),
                ),
            ],
          ),
        ],
      ),
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.xl, AppSpacing.screen, AppSpacing.xl),
          children: [
            TabHeader(
              title: 'Portafogli',
              actions: [
                AppIconButton(
                  icon: balancesHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  tooltip: balancesHidden ? 'Mostra saldi' : 'Nascondi saldi',
                  onPressed: () => ref.read(balancesHiddenProvider.notifier).toggle(),
                ),
                AppIconButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Nuovo portafoglio',
                  onPressed: () => context.push(AppRoutes.newWallet),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (overviewsAsync.hasError && overviewsAsync.value == null)
              StateMessage.error(what: 'i portafogli', onRetry: () => ref.invalidate(walletOverviewsProvider))
            else if (overviewsAsync.hasValue && overviews.isEmpty)
              StateMessage(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Nessun portafoglio',
                message: 'Aggiungi un conto, i contanti o una carta per iniziare a registrare i movimenti.',
                actionLabel: 'Nuovo portafoglio',
                onAction: () => context.push(AppRoutes.newWallet),
              )
            else ...[
              NetWorthCard(totalCents: sum(included), groupTotals: groupTotals),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  textStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                onPressed: active.length < 2 ? null : () => context.push(AppRoutes.add('transfer')),
                icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                label: const Text('Trasferisci tra portafogli'),
              ),
              for (final MapEntry(key: group, value: list) in byGroup.entries)
                section(walletGroupLabel(group), groupTotals[group]!, list),
              if (archived.isNotEmpty) section('Archiviati', null, archived),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text(
              'I trasferimenti spostano denaro tra portafogli: non contano come entrate o spese nei grafici.',
              style: textTheme.bodySmall?.copyWith(height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
