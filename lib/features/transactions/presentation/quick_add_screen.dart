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
import '../../settings/application/settings_providers.dart';
import '../../wallets/application/wallet_providers.dart';
import '../application/quick_add_controller.dart';
import 'widgets/amount_keypad.dart';
import 'widgets/date_picker_sheet.dart';
import 'widgets/wallet_picker_sheet.dart';

/// Inserimento rapido di una spesa o di un'entrata, aperto a schermo intero dal basso.
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
    final isIncome = state.type == TransactionType.income;
    final tone = isIncome ? colors.income : colors.expense;
    final today = ref.watch(todayProvider);

    final settings = ref.watch(appSettingsProvider).value ?? const AppSettings();
    final wallets = (ref.watch(walletsProvider).value ?? const []).where((w) => !w.isArchived).toList();
    final walletId = resolveWalletId(
      chosenId: state.chosenWalletId,
      defaultId: isIncome ? settings.defaultIncomeWalletId : settings.defaultExpenseWalletId,
      wallets: wallets,
    );
    final kind = isIncome ? CategoryKind.income : CategoryKind.expense;
    final categories = (ref.watch(categoriesProvider).value ?? const [])
        .where((c) => c.kind == kind && !c.isArchived)
        .toList();
    final labels = ref.watch(labelsProvider).value ?? const [];
    final walletName = wallets.firstWhereOrNull((w) => w.id == walletId)?.name ?? 'Nessun portafoglio';
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
                    child: _HeaderChip(
                      semanticLabel: 'Portafoglio: $walletName',
                      onTap: wallets.isEmpty
                          ? null
                          : () async {
                              final picked = await showWalletPickerSheet(
                                context,
                                title: isIncome ? 'Ricevi su' : 'Paga da',
                                wallets: wallets,
                                balances: ref.read(walletBalancesProvider).value ?? const {},
                                selectedId: walletId,
                              );
                              if (picked != null) controller.chooseWallet(picked);
                            },
                      children: [
                        Text(
                          isIncome ? 'su' : 'da',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: colors.textMuted, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            walletName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium,
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
                      Text(dateLabel, style: Theme.of(context).textTheme.labelMedium),
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
                ],
                selected: state.type,
                onChanged: controller.setType,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  children: [
                    _AmountDisplay(cents: state.amountCents, isIncome: isIncome, color: tone.text),
                    if (state.showErrors && state.isAmountMissing) const _ErrorText('Inserisci un importo'),
                    const SizedBox(height: AppSpacing.md),
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
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _noteController,
                      onChanged: controller.setNote,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(hintText: 'Nota (facoltativa)'),
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
                  textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 17),
                ),
                onPressed: state.saving ? null : () => _save(walletId),
                child: Text(isIncome ? 'Salva entrata' : 'Salva spesa'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save(String? walletId) async {
    final messenger = ScaffoldMessenger.of(context);
    if (walletId == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Crea prima un portafoglio')));
      return;
    }

    final saved = await ref.read(_provider.notifier).save(walletId: walletId);
    if (saved == null || !mounted) return;

    context.pop();
    final what = saved.type == TransactionType.income ? 'Entrata' : 'Spesa';
    // Il messenger è quello dell'app: la SnackBar resta visibile sulla schermata sotto.
    messenger.showSnackBar(SnackBar(content: Text('$what di ${formatCents(saved.amountCents)} salvata')));
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

/// Importo grande colorato per tipo: "− € 64,20".
class _AmountDisplay extends StatelessWidget {
  const _AmountDisplay({required this.cents, required this.isIncome, required this.color});

  final int cents;
  final bool isIncome;
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
              '${isIncome ? '+' : minusSign} €',
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
