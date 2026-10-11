import 'package:flutter/material.dart';

import '../../../../core/money.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_list_row.dart';
import '../../../../domain/models/wallet.dart';

/// Apre il pannello di scelta del portafoglio e restituisce l'ID scelto (null se chiuso).
Future<String?> showWalletPickerSheet(
  BuildContext context, {
  required String title,
  required List<Wallet> wallets,
  required Map<String, int> balances,
  required String? selectedId,
  String hint = 'Questa scelta vale solo per questo movimento. Il portafoglio predefinito si cambia in Impostazioni.',

  /// Nel trasferimento: l'altro portafoglio già scelto, indicato accanto al saldo.
  String? otherSelectedId,
  String? otherSelectedLabel,
}) {
  return AppBottomSheet.show<String>(
    context,
    title: title,
    builder: (sheetContext) => Column(
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
                  subtitle: [
                    formatCents(balances[wallet.id] ?? wallet.initialBalanceCents),
                    if (wallet.id == otherSelectedId && otherSelectedLabel != null)
                      'già selezionato come $otherSelectedLabel',
                  ].join(' · '),
                  trailing: _RadioDot(selected: wallet.id == selectedId),
                  onTap: () => Navigator.pop(sheetContext, wallet.id),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(hint, style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(height: 1.45)),
      ],
    ),
  );
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
