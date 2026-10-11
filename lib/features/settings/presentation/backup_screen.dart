import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/clock.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/bottom_action_bar.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_list_row.dart';
import '../../../core/widgets/section_label.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/label.dart';
import '../../../domain/models/transaction.dart';
import '../../../domain/models/wallet.dart';
import '../../transactions/application/transaction_list_providers.dart';
import '../../transactions/presentation/period_labels.dart';
import '../../wallets/application/wallet_providers.dart';
import '../application/csv_exporter.dart';
import '../application/settings_providers.dart';

/// Backup ed esportazione. Per ora c'è l'export CSV; backup e ripristino arriveranno più avanti.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  var _exporting = false;

  Future<void> _export(List<Transaction> transactions) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _exporting = true);
    try {
      await ref
          .read(csvExporterProvider)
          .exportAndShare(
            transactions: transactions,
            range: ref.read(selectedPeriodProvider).range,
            walletNames: {for (final w in ref.read(walletsProvider).value ?? const <Wallet>[]) w.id: w.name},
            categoryNames: {for (final c in ref.read(categoriesProvider).value ?? const <Category>[]) c.id: c.name},
            labelNames: {for (final l in ref.read(labelsProvider).value ?? const <Label>[]) l.id: l.name},
          );
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Esportazione non riuscita. Riprova.')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final period = ref.watch(selectedPeriodProvider);
    final filters = ref.watch(activeFiltersProvider);
    final transactions = ref.watch(visibleTransactionsProvider).value;
    // Servono già caricati per i nomi nel file.
    ref
      ..watch(walletsProvider)
      ..watch(categoriesProvider)
      ..watch(labelsProvider);
    final count = transactions?.length ?? 0;

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
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text('Backup ed esportazione', style: textTheme.headlineMedium?.copyWith(fontSize: 22)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  6,
                  AppSpacing.screen,
                  AppSpacing.xxl + bottomSystemInset(context),
                ),
                children: [
                  const SectionLabel('Esporta CSV', indent: true),
                  const SizedBox(height: AppSpacing.sm),
                  AppListGroup(
                    children: [
                      AppListRow(
                        title: 'Periodo',
                        value: periodTitle(period, ref.watch(todayProvider)),
                        onTap: () => context.push(AppRoutes.filters),
                      ),
                      AppListRow(
                        title: 'Filtri',
                        value: filters.isActive ? '${filters.activeCount} attivi' : 'Nessuno',
                        onTap: () => context.push(AppRoutes.filters),
                      ),
                      const AppListRow(title: 'Formato', value: 'Excel (separatore ;)'),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            backgroundColor: colors.income.fill,
                            foregroundColor: colors.income.onFill,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: transactions == null || count == 0 || _exporting
                              ? null
                              : () => _export(transactions),
                          icon: const Icon(Icons.ios_share_rounded, size: 20),
                          label: Text(count == 1 ? 'Esporta 1 movimento' : 'Esporta $count movimenti'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    count == 0
                        ? 'Nessun movimento con il periodo e i filtri scelti.'
                        : 'Si esportano i movimenti confermati del periodo e dei filtri della lista Movimenti. '
                              '"Esporta" apre il menu di condivisione del telefono: puoi salvare il file, '
                              'mandarlo per mail o caricarlo su Drive.',
                    style: textTheme.bodySmall?.copyWith(height: 1.45),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  const SectionLabel('Backup', indent: true),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Il backup automatico su Google Drive e il ripristino arriveranno in una prossima versione. '
                    'Per ora i dati restano solo su questo telefono.',
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
