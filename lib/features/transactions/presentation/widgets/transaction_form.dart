import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_segmented.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../../domain/models/category.dart';
import '../../../../domain/models/enums.dart';
import '../../../settings/application/settings_providers.dart';
import '../../../wallets/application/wallet_providers.dart';
import '../../application/transaction_form_controller.dart';
import 'transfer_wallets_card.dart';
import 'wallet_picker_sheet.dart';

// Parti del form di un movimento condivise da Inserimento rapido e Modifica movimento.
// Ogni schermata le dispone a modo suo; stato e logica stanno in TransactionFormController.

/// Colore del tipo di movimento (pulsante salva, importo, categoria selezionata).
ColorTone formTone(BuildContext context, TransactionType type) => switch (type) {
  TransactionType.income => context.colors.income,
  TransactionType.expense => context.colors.expense,
  _ => context.colors.neutral,
};

/// Segmented Spesa / Entrata / Trasferimento. Le rettifiche non lo mostrano.
class TransactionTypeSelector extends ConsumerWidget {
  const TransactionTypeSelector({super.key, required this.seed, this.size = AppSegmentedSize.regular});

  final TransactionFormSeed seed;
  final AppSegmentedSize size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ref.watch(transactionFormControllerProvider(seed).select((s) => s.type));
    if (type == TransactionType.adjustment) return const SizedBox.shrink();
    final colors = context.colors;

    return AppSegmented<TransactionType>(
      size: size,
      segments: [
        AppSegment(value: TransactionType.expense, label: 'Spesa', selectedTone: colors.expense),
        AppSegment(value: TransactionType.income, label: 'Entrata', selectedTone: colors.income),
        AppSegment(value: TransactionType.transfer, label: 'Trasferimento', selectedTone: colors.neutral),
      ],
      selected: type,
      onChanged: ref.read(transactionFormControllerProvider(seed).notifier).setType,
    );
  }
}

/// Per spese ed entrate: categorie del tipo e label. Per i trasferimenti: scheda Da/A.
/// Le rettifiche non hanno né l'una né l'altra.
class TransactionFormDetails extends ConsumerWidget {
  const TransactionFormDetails({super.key, required this.seed});

  final TransactionFormSeed seed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transactionFormControllerProvider(seed));
    return switch (state.type) {
      TransactionType.transfer => _TransferSection(seed: seed),
      TransactionType.adjustment => const SizedBox.shrink(),
      _ => _CategoriesAndLabels(seed: seed),
    };
  }
}

class _CategoriesAndLabels extends ConsumerWidget {
  const _CategoriesAndLabels({required this.seed});

  final TransactionFormSeed seed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transactionFormControllerProvider(seed));
    final controller = ref.read(transactionFormControllerProvider(seed).notifier);
    final kind = state.type == TransactionType.income ? CategoryKind.income : CategoryKind.expense;
    final categories = (ref.watch(categoriesProvider).value ?? const <Category>[])
        // Una categoria archiviata resta visibile se è quella già scelta.
        .where((c) => c.kind == kind && (!c.isArchived || c.id == state.categoryId))
        .toList();
    final labels = ref.watch(labelsProvider).value ?? const [];
    final tone = formTone(context, state.type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Categoria'),
        Wrap(
          spacing: 6,
          children: [
            for (final category in categories)
              AppChip(
                label: category.name,
                selected: category.id == state.categoryId,
                selectedTone: tone,
                onTap: () => controller.selectCategory(category.id),
              ),
          ],
        ),
        if (state.showErrors && state.isCategoryMissing) const FormErrorText('Scegli una categoria'),
        const SizedBox(height: AppSpacing.sm),
        SectionLabel(state.isEditing ? 'Label' : 'Label · anche più di una'),
        Wrap(
          spacing: 6,
          children: [
            for (final label in labels)
              AppChip(
                label: '#${label.name}',
                shape: AppChipShape.label,
                selected: state.labelIds.contains(label.id),
                onTap: () => controller.toggleLabel(label.id),
              ),
            AppChip(
              label: '+ Gestisci',
              shape: AppChipShape.label,
              dashed: true,
              onTap: () => context.push(AppRoutes.categories),
            ),
          ],
        ),
      ],
    );
  }
}

class _TransferSection extends ConsumerWidget {
  const _TransferSection({required this.seed});

  final TransactionFormSeed seed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transactionFormControllerProvider(seed));
    final controller = ref.read(transactionFormControllerProvider(seed).notifier);
    final wallets = ref.watch(formWalletsProvider(seed));
    final balances = ref.watch(walletBalancesProvider).value ?? const <String, int>{};

    Future<String?> pick(String title, String? selectedId, String? otherId, String otherLabel) {
      return showWalletPickerSheet(
        context,
        title: title,
        wallets: wallets.available,
        balances: balances,
        selectedId: selectedId,
        otherSelectedId: otherId,
        otherSelectedLabel: otherLabel,
        hint: 'Scegli due portafogli diversi.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TransferWalletsCard(
          fromName: wallets.nameOf(wallets.fromId),
          fromBalanceCents: balances[wallets.fromId],
          toName: wallets.toId == null ? 'Nessun altro portafoglio' : wallets.nameOf(wallets.toId),
          toBalanceCents: balances[wallets.toId],
          onTapFrom: () async {
            final picked = await pick('Trasferisci da', wallets.fromId, wallets.toId, 'destinazione');
            if (picked != null) controller.chooseTransferSource(picked, from: wallets.fromId, to: wallets.toId);
          },
          onTapTo: () async {
            final picked = await pick('Trasferisci a', wallets.toId, wallets.fromId, 'origine');
            if (picked != null) controller.chooseTransferDestination(picked, from: wallets.fromId, to: wallets.toId);
          },
          onSwap: wallets.toId == null
              ? null
              : () => controller.swapTransferWallets(from: wallets.fromId, to: wallets.toId),
        ),
        if (state.showErrors && wallets.transferInvalid) const FormErrorText('Scegli due portafogli diversi'),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'I trasferimenti non contano come spese o entrate nei grafici.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.45),
        ),
      ],
    );
  }
}

/// Apre la scelta del portafoglio per spese ed entrate e salva la scelta nel form.
Future<void> pickFormWallet(BuildContext context, WidgetRef ref, TransactionFormSeed seed) async {
  final state = ref.read(transactionFormControllerProvider(seed));
  final wallets = ref.read(formWalletsProvider(seed));
  final picked = await showWalletPickerSheet(
    context,
    title: state.type == TransactionType.income ? 'Ricevi su' : 'Paga da',
    wallets: wallets.available,
    balances: ref.read(walletBalancesProvider).value ?? const {},
    selectedId: wallets.walletId,
    hint: state.isEditing
        ? 'Il movimento verrà spostato nel portafoglio scelto.'
        : 'Questa scelta vale solo per questo movimento. Il portafoglio predefinito si cambia in Impostazioni.',
  );
  if (picked != null) ref.read(transactionFormControllerProvider(seed).notifier).chooseWallet(picked);
}

/// Messaggio di errore sotto un campo, annunciato dallo screen reader.
class FormErrorText extends StatelessWidget {
  const FormErrorText(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Semantics(
        liveRegion: true,
        child: Text(message, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: context.colors.danger)),
      ),
    );
  }
}
