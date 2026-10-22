import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_list_row.dart';
import '../../../../domain/models/wallet.dart';
import '../../../wallets/application/wallet_providers.dart';
import '../../../wallets/presentation/widgets/balance_text.dart';

/// Apre il pannello di scelta del portafoglio e restituisce l'ID scelto (null se chiuso).
///
/// I saldi li legge il pannello stesso da [walletBalancesProvider], la stessa fonte di Portafogli e
/// del dettaglio: osservandolo lo tiene vivo e si aggiorna se i movimenti cambiano mentre è aperto.
Future<String?> showWalletPickerSheet(
  BuildContext context, {
  required String title,
  required List<Wallet> wallets,
  required String? selectedId,
  String hint = 'Questa scelta vale solo per questo movimento. Il portafoglio predefinito si cambia in Impostazioni.',

  /// Nel trasferimento: l'altro portafoglio già scelto, indicato accanto al saldo.
  String? otherSelectedId,
  String? otherSelectedLabel,
}) {
  return AppBottomSheet.show<String>(
    context,
    title: title,
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        // Finché i saldi non sono pronti non se ne mostra nessuno (mai un valore sbagliato).
        final balances = ref.watch(walletBalancesProvider).value;
        return _PickerBody(
          wallets: wallets,
          balances: balances,
          selectedId: selectedId,
          otherSelectedId: otherSelectedId,
          otherSelectedLabel: otherSelectedLabel,
          hint: hint,
          onPick: (id) => Navigator.pop(sheetContext, id),
        );
      },
    ),
  );
}

class _PickerBody extends StatelessWidget {
  const _PickerBody({
    required this.wallets,
    required this.balances,
    required this.selectedId,
    required this.otherSelectedId,
    required this.otherSelectedLabel,
    required this.hint,
    required this.onPick,
  });

  final List<Wallet> wallets;
  final Map<String, int>? balances;
  final String? selectedId;
  final String? otherSelectedId;
  final String? otherSelectedLabel;
  final String hint;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppListGroup(
          children: [
            for (final wallet in wallets)
              Semantics(
                inMutuallyExclusiveGroup: true,
                checked: wallet.id == selectedId,
                child: AppListRow(
                  title: wallet.name,
                  subtitleWidget: Wrap(
                    children: [
                      if (balances?[wallet.id] case final balance?) BalanceText(balance),
                      if (wallet.id == otherSelectedId && otherSelectedLabel != null)
                        Text('${balances == null ? '' : ' · '}già selezionato come $otherSelectedLabel'),
                    ],
                  ),
                  trailing: _RadioDot(selected: wallet.id == selectedId),
                  onTap: () => onPick(wallet.id),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(hint, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.45)),
      ],
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surface,
        border: Border.all(color: selected ? colors.text : colors.textMuted, width: selected ? 6 : 2),
      ),
    );
  }
}
