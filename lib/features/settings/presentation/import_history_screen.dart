import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_list_row.dart';
import '../../../core/widgets/bottom_action_bar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/state_message.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/import_record.dart';
import '../application/settings_providers.dart';

/// "1 movimento" / "3 movimenti".
String _count(int n, String one, String many) => '$n ${n == 1 ? one : many}';

/// Impostazioni › Dati › Storico importazioni: data, file, conteggi e "Annulla importazione".
class ImportHistoryScreen extends ConsumerWidget {
  const ImportHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final historyAsync = ref.watch(importHistoryProvider);
    final history = historyAsync.value ?? const <ImportRecord>[];

    return Scaffold(
      bottomNavigationBar: BottomActionBar(
        child: FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          onPressed: () => context.push(AppRoutes.import),
          child: const Text('Importa da CSV'),
        ),
      ),
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
                      child: Text('Storico importazioni', style: textTheme.headlineMedium?.copyWith(fontSize: 22)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.xs, AppSpacing.screen, AppSpacing.xl),
                children: [
                  if (historyAsync.hasError && historyAsync.value == null)
                    StateMessage.error(what: 'lo storico', onRetry: () => ref.invalidate(importHistoryProvider))
                  else if (historyAsync.hasValue && history.isEmpty)
                    const StateMessage(
                      icon: Icons.upload_file_outlined,
                      title: 'Nessuna importazione',
                      message: 'I file CSV importati compariranno qui, con la possibilità di annullarli.',
                    )
                  else
                    AppListGroup(
                      children: [
                        for (final record in history)
                          AppListRow(
                            title: record.fileName,
                            subtitle: _subtitle(record),
                            value: record.isUndone ? 'Annullata' : null,
                            onTap: () => _openDetail(context, ref, record),
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

  static String _date(DateTime date) => DateFormat('d MMM y, HH:mm', 'it_IT').format(date.toLocal());

  static String _subtitle(ImportRecord r) =>
      '${_date(r.createdAt)} · ${_count(r.insertedCount, 'nuovo', 'nuovi')} · '
      '${_count(r.updatedCount, 'aggiornato', 'aggiornati')} · ${_count(r.skippedCount, 'saltato', 'saltati')}';

  Future<void> _openDetail(BuildContext context, WidgetRef ref, ImportRecord record) async {
    final undo = await AppBottomSheet.show<bool>(
      context,
      title: record.fileName,
      builder: (sheetContext) {
        final textTheme = Theme.of(sheetContext).textTheme;
        final colors = sheetContext.colors;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppListGroup(
              children: [
                AppListRow(title: 'Importato il', value: _date(record.createdAt)),
                AppListRow(title: 'Righe lette', value: '${record.rowCount}'),
                AppListRow(title: 'Movimenti nuovi', value: '${record.insertedCount}'),
                AppListRow(title: 'Movimenti aggiornati', value: '${record.updatedCount}'),
                AppListRow(title: 'Righe saltate', value: '${record.skippedCount}'),
                if (record.undoneAt case final undoneAt?) AppListRow(title: 'Annullata il', value: _date(undoneAt)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (!record.isUndone) ...[
              Text(
                'Annullando si eliminano i movimenti creati da questo import '
                '(${_count(record.insertedCount, 'movimento', 'movimenti')}).'
                '${record.updatedCount == 0 ? '' : ' Quelli aggiornati (${record.updatedCount}) restano come sono: '
                          'non si possono ripristinare.'}',
                style: textTheme.bodySmall?.copyWith(height: 1.45),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  foregroundColor: colors.danger,
                  side: BorderSide(color: colors.danger.withValues(alpha: 0.35)),
                ),
                onPressed: () => Navigator.pop(sheetContext, true),
                child: const Text('Annulla importazione'),
              ),
            ],
          ],
        );
      },
    );
    if (undo != true || !context.mounted) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Annullare l\'importazione?',
      message:
          'Verranno eliminati i movimenti creati da «${record.fileName}» '
          '(${_count(record.insertedCount, 'movimento', 'movimenti')}).'
          '${record.updatedCount == 0 ? '' : ' Quelli aggiornati (${record.updatedCount}) restano come sono.'}',
      confirmLabel: 'Annulla importazione',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final deleted = await ref.read(importRepositoryProvider).undo(record.id);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Importazione annullata: ${_count(deleted, 'movimento eliminato', 'movimenti eliminati')}'),
        ),
      );
    } on Exception {
      messenger.showSnackBar(const SnackBar(content: Text('Non è stato possibile annullare. Riprova.')));
    }
  }
}
