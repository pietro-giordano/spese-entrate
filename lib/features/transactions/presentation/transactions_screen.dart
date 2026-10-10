import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/screen_placeholder.dart';

/// Tab Movimenti (home).
class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenPlaceholder(
      title: 'Movimenti',
      leading: PlaceholderLeading.none,
      description: 'Riepilogo del periodo e lista dei movimenti.',
      links: {'Movimento di esempio': AppRoutes.transaction('esempio')},
      headerActions: [
        const AppIconButton(icon: Icons.search_rounded, tooltip: 'Cerca', onPressed: null),
        AppIconButton(icon: Icons.tune_rounded, tooltip: 'Filtri', onPressed: () => context.push(AppRoutes.filters)),
        AppIconButton(
          icon: Icons.person_outline_rounded,
          tooltip: 'Profilo e impostazioni',
          round: true,
          onPressed: () => context.push(AppRoutes.settings),
        ),
      ],
      bottomBar: const _AddButtons(),
    );
  }
}

/// Pulsanti fissi "− Spesa" e "+ Entrata".
class _AddButtons extends StatelessWidget {
  const _AddButtons();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 10, AppSpacing.screen, AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.expense.fill,
                  foregroundColor: colors.expense.onFill,
                ),
                onPressed: () => context.push(AppRoutes.add('expense')),
                icon: const Icon(Icons.remove_rounded),
                label: const Text('Spesa'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.income.fill,
                  foregroundColor: colors.income.onFill,
                ),
                onPressed: () => context.push(AppRoutes.add('income')),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Entrata'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
