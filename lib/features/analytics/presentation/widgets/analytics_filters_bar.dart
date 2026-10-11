import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_icon_button.dart';
import '../../../../domain/models/category.dart';
import '../../../../domain/models/label.dart';
import '../../../../domain/models/transaction_filters.dart';
import '../../../../domain/models/wallet.dart';
import '../../../settings/application/settings_providers.dart';
import '../../../wallets/application/wallet_providers.dart';
import '../../application/analytics_filters.dart';

/// Pulsante Filtri di Grafici o Confronta, con il numero di filtri attivi sull'icona.
class AnalyticsFiltersButton extends ConsumerWidget {
  const AnalyticsFiltersButton({super.key, required this.tab});

  final AnalyticsTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(analyticsFiltersProvider(tab)).activeCount;
    return AppIconButton(
      icon: Icons.tune_rounded,
      tooltip: count == 0 ? 'Filtri' : 'Filtri, $count attivi',
      badgeCount: count,
      onPressed: () => context.push(AppRoutes.filtersOf(tab.name)),
    );
  }
}

/// Filtri attivi di Grafici o Confronta, sotto l'intestazione: un chip rimovibile per voce
/// e "Azzera". Non occupa spazio se non c'è nessun filtro.
class AnalyticsFiltersBar extends ConsumerWidget {
  const AnalyticsFiltersBar({super.key, required this.tab});

  final AnalyticsTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(analyticsFiltersProvider(tab));
    if (!filters.isActive) return const SizedBox.shrink();
    final notifier = ref.read(analyticsFiltersProvider(tab).notifier);
    final wallets = ref.watch(walletsProvider).value ?? const <Wallet>[];
    final categories = ref.watch(categoriesProvider).value ?? const <Category>[];
    final labels = ref.watch(labelsProvider).value ?? const <Label>[];
    final colors = context.colors;

    // Un filtro su una voce poi eliminata resta rimovibile, con un nome generico.
    String walletName(String id) => wallets.firstWhereOrNull((w) => w.id == id)?.name ?? 'Portafoglio';
    String categoryName(String id) => categories.firstWhereOrNull((c) => c.id == id)?.name ?? 'Categoria';
    String labelName(String id) => labels.firstWhereOrNull((l) => l.id == id)?.name ?? 'label';

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Wrap(
        spacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final id in filters.walletIds)
            _RemovableChip(label: walletName(id), onRemove: () => notifier.removeWallet(id)),
          for (final id in filters.categoryIds)
            _RemovableChip(label: categoryName(id), onRemove: () => notifier.removeCategory(id)),
          for (final id in filters.labelIds)
            _RemovableChip(label: '#${labelName(id)}', onRemove: () => notifier.removeLabel(id)),
          if (filters.withoutLabels) _RemovableChip(label: 'Senza label', onRemove: notifier.removeWithoutLabels),
          if (filters.labelIds.length > 1 && filters.labelMatch == LabelMatch.all)
            Text('tutte le label', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.textMuted)),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: colors.expense.text,
              minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
            ),
            onPressed: notifier.reset,
            child: const Text('Azzera'),
          ),
        ],
      ),
    );
  }
}

/// Chip di un filtro attivo: tocco = rimuove il filtro. Area di tocco alta 44.
class _RemovableChip extends StatelessWidget {
  const _RemovableChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      button: true,
      label: 'Rimuovi filtro $label',
      excludeSemantics: true,
      child: InkWell(
        onTap: onRemove,
        borderRadius: BorderRadius.circular(AppSizes.minTouchTarget / 2),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          child: Center(
            widthFactor: 1,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
              decoration: BoxDecoration(
                color: colors.neutral.fill,
                borderRadius: BorderRadius.circular(AppRadius.labelChip),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelMedium?.copyWith(color: colors.neutral.onFill),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.close_rounded, size: 16, color: colors.neutral.onFill),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
