import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/clock.dart';
import '../../../core/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_segmented.dart';
import '../../../domain/models/app_settings.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/transaction.dart';
import '../../settings/application/settings_providers.dart';
import '../application/transaction_form_controller.dart';
import 'widgets/amount_keypad.dart';
import 'widgets/attachments_sheet.dart';
import 'widgets/date_picker_sheet.dart';
import 'widgets/transaction_form.dart';

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

  TransactionFormSeed get _seed => TransactionFormSeed.create(widget.type);
  TransactionFormControllerProvider get _provider => transactionFormControllerProvider(_seed);

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_provider);
    final controller = ref.read(_provider.notifier);
    final wallets = ref.watch(formWalletsProvider(_seed));
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final isIncome = state.type == TransactionType.income;
    final tone = formTone(context, state.type);
    final today = ref.watch(todayProvider);
    final settings = ref.watch(appSettingsProvider).value ?? const AppSettings();
    final dateLabel = dateChipLabel(state.date, today);

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
                    child: state.isTransfer
                        ? Text('Trasferimento', textAlign: TextAlign.center, style: textTheme.titleMedium)
                        : _HeaderChip(
                            semanticLabel: 'Portafoglio: ${wallets.nameOf(wallets.walletId)}',
                            onTap: wallets.available.isEmpty ? null : () => pickFormWallet(context, ref, _seed),
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
                                  wallets.nameOf(wallets.walletId),
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
              TransactionTypeSelector(seed: _seed, size: AppSegmentedSize.large),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  children: [
                    _AmountDisplay(
                      cents: state.amountCents,
                      sign: switch (state.type) {
                        TransactionType.income => '+',
                        TransactionType.expense => minusSign,
                        _ => '',
                      },
                      color: tone.text,
                    ),
                    if (state.showErrors && state.isAmountMissing) const FormErrorText('Inserisci un importo'),
                    const SizedBox(height: AppSpacing.md),
                    TransactionFormDetails(seed: _seed),
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
                        if (state.newAttachments.isNotEmpty) ...[
                          const SizedBox(width: AppSpacing.sm),
                          _AttachmentsCountButton(
                            count: state.newAttachments.length,
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
                    : () =>
                          state.isTransfer ? _save(wallets.fromId, toWalletId: wallets.toId) : _save(wallets.walletId),
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
