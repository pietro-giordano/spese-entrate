import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/clock.dart';
import '../../../core/money.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_segmented.dart';
import '../../../core/widgets/section_label.dart';
import '../../../domain/models/app_settings.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/transaction.dart';
import '../../settings/application/settings_providers.dart';
import '../../wallets/application/wallet_providers.dart';
import '../application/quick_add_controller.dart';
import 'widgets/amount_keypad.dart';
import 'widgets/attachments_sheet.dart';
import 'widgets/date_picker_sheet.dart';
import 'widgets/transfer_wallets_card.dart';
import 'widgets/wallet_picker_sheet.dart';

/// Inserimento rapido di una spesa, un'entrata o un trasferimento, aperto a schermo intero dal basso.
class QuickAddScreen extends ConsumerStatefulWidget {
  const QuickAddScreen({super.key, required this.type});

  /// Tipo iniziale, scelto dal pulsante che ha aperto la schermata.
  final TransactionType type;

  @override
  ConsumerState<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends ConsumerState<QuickAddScreen> {
  final _noteController = TextEditingController();

  QuickAddControllerProvider get _provider => quickAddControllerProvider(widget.type);

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_provider);
    final controller = ref.read(_provider.notifier);
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final isIncome = state.type == TransactionType.income;
    final isTransfer = state.isTransfer;
    final tone = switch (state.type) {
      TransactionType.income => colors.income,
      TransactionType.transfer => colors.neutral,
      _ => colors.expense,
    };
    final today = ref.watch(todayProvider);

    final settings = ref.watch(appSettingsProvider).value ?? const AppSettings();
    final wallets = (ref.watch(walletsProvider).value ?? const []).where((w) => !w.isArchived).toList();
    final balances = ref.watch(walletBalancesProvider).value ?? const <String, int>{};
    String nameOf(String? id) => wallets.firstWhereOrNull((w) => w.id == id)?.name ?? 'Nessun portafoglio';

    final walletId = resolveWalletId(
      chosenId: state.chosenWalletId,
      defaultId: isIncome ? settings.defaultIncomeWalletId : settings.defaultExpenseWalletId,
      wallets: wallets,
    );
    final transfer = resolveTransferWallets(
      chosenFrom: state.fromWalletId,
      chosenTo: state.toWalletId,
      defaultFromId: settings.defaultExpenseWalletId,
      wallets: wallets,
    );
    final transferWalletsInvalid = transfer.from == null || transfer.to == null || transfer.from == transfer.to;

    final kind = isIncome ? CategoryKind.income : CategoryKind.expense;
    final categories = (ref.watch(categoriesProvider).value ?? const [])
        .where((c) => c.kind == kind && !c.isArchived)
        .toList();
    final labels = ref.watch(labelsProvider).value ?? const [];
    final dateLabel = dateChipLabel(state.date, today);

    Future<String?> pickWallet({
      required String title,
      required String? selectedId,
      String? otherId,
      String? otherLabel,
    }) {
      return showWalletPickerSheet(
        context,
        title: title,
        wallets: wallets,
        balances: balances,
        selectedId: selectedId,
        otherSelectedId: otherId,
        otherSelectedLabel: otherLabel,
        hint: isTransfer
            ? 'Scegli due portafogli diversi.'
            : 'Questa scelta vale solo per questo movimento. Il portafoglio predefinito si cambia in Impostazioni.',
      );
    }

    // Con la tastiera di sistema aperta (nota) il tastierino numerico si nasconde.
    final systemKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 14, AppSpacing.screen, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  AppIconButton(icon: Icons.close_rounded, tooltip: 'Chiudi', onPressed: () => context.pop()),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: isTransfer
                        ? Text('Trasferimento', textAlign: TextAlign.center, style: textTheme.titleMedium)
                        : _HeaderChip(
                            semanticLabel: 'Portafoglio: ${nameOf(walletId)}',
                            onTap: wallets.isEmpty
                                ? null
                                : () async {
                                    final picked = await pickWallet(
                                      title: isIncome ? 'Ricevi su' : 'Paga da',
                                      selectedId: walletId,
                                    );
                                    if (picked != null) controller.chooseWallet(picked);
                                  },
                            children: [
                              Text(
                                isIncome ? 'su' : 'da',
                                style: textTheme.labelMedium?.copyWith(
                                  color: colors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  nameOf(walletId),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.labelMedium,
                                ),
                              ),
                              Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: colors.text),
                            ],
                          ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _HeaderChip(
                    semanticLabel: 'Data del movimento: $dateLabel',
                    onTap: () async {
                      final picked = await showDatePickerSheet(
                        context,
                        selected: state.date,
                        today: today,
                        weekStart: settings.weekStart,
                      );
                      if (picked != null) controller.setDate(picked);
                    },
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 16, color: colors.text),
                      const SizedBox(width: 6),
                      Text(dateLabel, style: textTheme.labelMedium),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppSegmented<TransactionType>(
                size: AppSegmentedSize.large,
                segments: [
                  AppSegment(value: TransactionType.expense, label: 'Spesa', selectedTone: colors.expense),
                  AppSegment(value: TransactionType.income, label: 'Entrata', selectedTone: colors.income),
                  AppSegment(value: TransactionType.transfer, label: 'Trasferimento', selectedTone: colors.neutral),
                ],
                selected: state.type,
                onChanged: controller.setType,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  children: [
                    _AmountDisplay(
                      cents: state.amountCents,
                      sign: switch (state.type) {
                        TransactionType.income => '+',
                        TransactionType.transfer => '',
                        _ => minusSign,
                      },
                      color: tone.text,
                    ),
                    if (state.showErrors && state.isAmountMissing) const _ErrorText('Inserisci un importo'),
                    const SizedBox(height: AppSpacing.md),
                    if (isTransfer) ...[
                      TransferWalletsCard(
                        fromName: nameOf(transfer.from),
                        fromBalanceCents: balances[transfer.from],
                        toName: transfer.to == null ? 'Nessun altro portafoglio' : nameOf(transfer.to),
                        toBalanceCents: balances[transfer.to],
                        onTapFrom: () async {
                          final picked = await pickWallet(
                            title: 'Trasferisci da',
                            selectedId: transfer.from,
                            otherId: transfer.to,
                            otherLabel: 'destinazione',
                          );
                          if (picked != null) {
                            controller.chooseTransferSource(picked, from: transfer.from, to: transfer.to);
                          }
                        },
                        onTapTo: () async {
                          final picked = await pickWallet(
                            title: 'Trasferisci a',
                            selectedId: transfer.to,
                            otherId: transfer.from,
                            otherLabel: 'origine',
                          );
                          if (picked != null) {
                            controller.chooseTransferDestination(picked, from: transfer.from, to: transfer.to);
                          }
                        },
                        onSwap: transfer.to == null
                            ? null
                            : () => controller.swapTransferWallets(from: transfer.from, to: transfer.to),
                      ),
                      if (state.showErrors && transferWalletsInvalid) const _ErrorText('Scegli due portafogli diversi'),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'I trasferimenti non contano come spese o entrate nei grafici.',
                        style: textTheme.bodySmall?.copyWith(height: 1.45),
                      ),
                    ] else ...[
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
                      if (state.showErrors && state.isCategoryMissing) const _ErrorText('Scegli una categoria'),
                      const SizedBox(height: AppSpacing.sm),
                      const SectionLabel('Label · anche più di una'),
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
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _noteController,
                            onChanged: controller.setNote,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(hintText: 'Nota (facoltativa)'),
                          ),
                        ),
                        if (state.attachments.isNotEmpty) ...[
                          const SizedBox(width: AppSpacing.sm),
                          _AttachmentsCountButton(
                            count: state.attachments.length,
                            onTap: () => showAttachmentsSheet(context, _provider),
                          ),
                        ],
                        const SizedBox(width: AppSpacing.sm),
                        AppIconButton(
                          icon: Icons.attach_file_rounded,
                          tooltip: 'Allega foto o file',
                          onPressed: () => showAttachmentsSheet(context, _provider),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!systemKeyboardOpen) ...[
                AmountKeypad(onKey: controller.pressKey, onClear: controller.clearAmount),
                const SizedBox(height: AppSpacing.md),
              ],
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: tone.fill,
                  foregroundColor: tone.onFill,
                  minimumSize: const Size.fromHeight(56),
                  // Parte dallo stile del tema: un TextStyle nuovo perderebbe il font Manrope.
                  textStyle: textTheme.titleMedium?.copyWith(fontSize: 17),
                ),
                onPressed: state.saving
                    ? null
                    : () => isTransfer ? _save(transfer.from, toWalletId: transfer.to) : _save(walletId),
                child: Text(switch (state.type) {
                  TransactionType.income => 'Salva entrata',
                  TransactionType.transfer => 'Salva trasferimento',
                  _ => 'Salva spesa',
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save(String? walletId, {String? toWalletId}) async {
    final messenger = ScaffoldMessenger.of(context);
    if (walletId == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Crea prima un portafoglio')));
      return;
    }

    final Transaction? saved;
    try {
      saved = await ref.read(_provider.notifier).save(walletId: walletId, toWalletId: toWalletId);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Salvataggio non riuscito. Riprova.')));
      return;
    }
    if (saved == null || !mounted) return;

    context.pop();
    final amount = formatCents(saved.amountCents);
    final message = switch (saved.type) {
      TransactionType.income => 'Entrata di $amount salvata',
      TransactionType.transfer => 'Trasferimento di $amount salvato',
      _ => 'Spesa di $amount salvata',
    };
    // Il messenger è quello dell'app: la SnackBar resta visibile sulla schermata sotto.
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Miniatura con il numero di allegati, accanto alla nota.
class _AttachmentsCountButton extends StatelessWidget {
  const _AttachmentsCountButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderRadius = BorderRadius.circular(10);

    return Semantics(
      container: true,
      button: true,
      label: count == 1 ? '1 allegato, apri' : '$count allegati, apri',
      excludeSemantics: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: colors.track,
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius,
              side: BorderSide(color: colors.borderStrong),
            ),
            child: InkWell(
              borderRadius: borderRadius,
              onTap: onTap,
              child: SizedBox.square(
                dimension: AppSizes.minTouchTarget,
                child: Icon(Icons.image_outlined, size: 20, color: colors.neutral.onTint),
              ),
            ),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: IgnorePointer(
              child: Container(
                constraints: const BoxConstraints(minWidth: 20),
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: colors.neutral.fill, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  '$count',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: colors.neutral.onFill, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip dell'header (portafoglio, data): 44 px di altezza, bordo e angoli da 14.
class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.semanticLabel, required this.onTap, required this.children});

  final String semanticLabel;
  final VoidCallback? onTap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderRadius = BorderRadius.circular(14);

    return Semantics(
      container: true,
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: colors.border),
        ),
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: SizedBox(
            height: AppSizes.minTouchTarget,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(mainAxisSize: MainAxisSize.min, children: children),
            ),
          ),
        ),
      ),
    );
  }
}

/// Importo grande colorato per tipo: "− € 64,20", "+ € 64,20" o "€ 64,20".
class _AmountDisplay extends StatelessWidget {
  const _AmountDisplay({required this.cents, required this.sign, required this.color});

  final int cents;

  /// "−" per le spese, "+" per le entrate, vuoto per i trasferimenti.
  final String sign;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const tabular = [FontFeature.tabularFigures()];

    return Semantics(
      label: 'Importo ${formatCents(cents)}',
      liveRegion: true,
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              sign.isEmpty ? '€' : '$sign €',
              style: textTheme.headlineMedium?.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: color,
                fontFeatures: tabular,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              formatCents(cents, withSymbol: false),
              style: textTheme.displaySmall?.copyWith(color: color, fontFeatures: tabular),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Semantics(
        liveRegion: true,
        child: Text(
          message,
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: context.colors.danger),
        ),
      ),
    );
  }
}
