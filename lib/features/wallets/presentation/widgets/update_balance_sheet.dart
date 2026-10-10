import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/clock.dart';
import '../../../../core/dates.dart';
import '../../../../core/money.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../../domain/models/app_settings.dart';
import '../../../../domain/models/category.dart';
import '../../../../domain/models/enums.dart';
import '../../../../domain/models/transaction.dart';
import '../../../../domain/models/wallet.dart';
import '../../../../domain/services/balances.dart';
import '../../../settings/application/settings_providers.dart';
import '../../../transactions/presentation/widgets/date_picker_sheet.dart';
import '../../application/wallet_providers.dart';

/// Apre "Aggiorna saldo". Restituisce il movimento registrato, o null se chiuso senza salvare.
Future<Transaction?> showUpdateBalanceSheet(BuildContext context, Wallet wallet) {
  return AppBottomSheet.show<Transaction>(
    context,
    title: 'Aggiorna saldo',
    titleTrailing: Builder(
      builder: (context) =>
          IconButton(icon: const Icon(Icons.close_rounded), tooltip: 'Chiudi', onPressed: () => Navigator.pop(context)),
    ),
    builder: (_) => _UpdateBalanceBody(wallet: wallet),
  );
}

class _UpdateBalanceBody extends ConsumerStatefulWidget {
  const _UpdateBalanceBody({required this.wallet});

  final Wallet wallet;

  @override
  ConsumerState<_UpdateBalanceBody> createState() => _UpdateBalanceBodyState();
}

class _UpdateBalanceBodyState extends ConsumerState<_UpdateBalanceBody> {
  late LocalDate _date = ref.read(todayProvider);
  late final _balanceController = TextEditingController(
    text: formatCents(
      walletBalance(widget.wallet, ref.read(walletTransactionsProvider(widget.wallet.id)).value ?? const []),
      withSymbol: false,
    ),
  );
  var _mode = BalanceUpdateMode.adjustment;
  String? _categoryId;
  var _showErrors = false;
  var _saving = false;

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save({required int? newBalance, required int difference}) async {
    final needsCategory = _mode == BalanceUpdateMode.movement && difference != 0;
    if (newBalance == null || (needsCategory && _categoryId == null)) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() => _saving = true);
    try {
      final transaction = await ref
          .read(walletActionsProvider)
          .updateBalance(
            wallet: widget.wallet,
            newBalanceCents: newBalance,
            date: _date,
            mode: _mode,
            categoryId: needsCategory ? _categoryId : null,
          );
      if (mounted) Navigator.pop(context, transaction);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final settings = ref.watch(appSettingsProvider).value ?? const AppSettings();
    final transactions = ref.watch(walletTransactionsProvider(widget.wallet.id)).value ?? const [];

    final recorded = walletBalance(widget.wallet, transactions, upTo: _date);
    final newBalance = parseCents(_balanceController.text);
    final difference = (newBalance ?? recorded) - recorded;
    final kind = difference > 0 ? CategoryKind.income : CategoryKind.expense;
    final categories = (ref.watch(categoriesProvider).value ?? const <Category>[])
        .where((c) => c.kind == kind && !c.isArchived)
        .toList();
    final dateLabel = dateChipLabel(_date, today);

    final differenceText = difference > 0 ? '+ ${formatCents(difference)}' : formatCents(difference);
    final differenceColor = switch (difference) {
      > 0 => colors.savings.text,
      < 0 => colors.danger,
      _ => colors.textMuted,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Saldo registrato: ${formatCents(recorded)} · ${dateLabel.toLowerCase()}',
          style: textTheme.labelMedium?.copyWith(color: colors.neutral.onTint, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Nuovo saldo', style: textTheme.labelSmall?.copyWith(color: colors.textMuted)),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.field),
                      border: Border.all(color: colors.text, width: 2),
                    ),
                    child: Row(
                      children: [
                        Text('€', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextField(
                            controller: _balanceController,
                            autofocus: true,
                            onChanged: (_) => setState(() {}),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            style: textTheme.titleLarge?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                            decoration: const InputDecoration(
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                              hintText: '0,00',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Alla data', style: textTheme.labelSmall?.copyWith(color: colors.textMuted)),
                  const SizedBox(height: AppSpacing.xs),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                      textStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    onPressed: () async {
                      final picked = await showDatePickerSheet(
                        context,
                        selected: _date,
                        today: today,
                        weekStart: settings.weekStart,
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                    child: Text(dateLabel, semanticsLabel: 'Alla data: $dateLabel'),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_showErrors && newBalance == null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text('Inserisci un saldo valido', style: textTheme.labelMedium?.copyWith(color: colors.danger)),
        ],
        const SizedBox(height: 14),
        MergeSemantics(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
            decoration: BoxDecoration(color: colors.neutral.tint, borderRadius: BorderRadius.circular(AppRadius.field)),
            child: Row(
              children: [
                Expanded(
                  child: Text('Differenza', style: textTheme.labelMedium?.copyWith(color: colors.neutral.onTint)),
                ),
                Text(
                  differenceText,
                  style: textTheme.titleMedium?.copyWith(
                    color: differenceColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const SectionLabel('Come registrare la differenza'),
        const SizedBox(height: AppSpacing.sm),
        _ModeOption(
          title: 'Rettifica di valore',
          subtitle:
              'Consigliato per investimenti e conteggi di cassa: aggiorna il saldo senza contare come entrata o spesa.',
          selected: _mode == BalanceUpdateMode.adjustment,
          onTap: () => setState(() => _mode = BalanceUpdateMode.adjustment),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ModeOption(
          title: 'Registra come entrata o spesa',
          subtitle: 'Crea un movimento con la differenza, che comparirà nei grafici e nei totali.',
          selected: _mode == BalanceUpdateMode.movement,
          onTap: () => setState(() => _mode = BalanceUpdateMode.movement),
        ),
        if (_mode == BalanceUpdateMode.movement && difference != 0) ...[
          const SizedBox(height: 14),
          SectionLabel(difference > 0 ? 'Categoria dell\'entrata' : 'Categoria della spesa'),
          Wrap(
            spacing: 6,
            children: [
              for (final category in categories)
                AppChip(
                  label: category.name,
                  selected: category.id == _categoryId,
                  selectedTone: difference > 0 ? colors.income : colors.expense,
                  onTap: () => setState(() => _categoryId = category.id),
                ),
            ],
          ),
          if (_showErrors && _categoryId == null)
            Text('Scegli una categoria', style: textTheme.labelMedium?.copyWith(color: colors.danger)),
        ],
        if (difference == 0 && newBalance != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text('Il saldo coincide: verrà registrata solo la data di controllo.', style: textTheme.bodySmall),
        ],
        const SizedBox(height: 18),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
          onPressed: _saving ? null : () => _save(newBalance: newBalance, difference: difference),
          child: const Text('Salva aggiornamento'),
        ),
      ],
    );
  }
}

/// Opzione a scelta singola con titolo e spiegazione.
class _ModeOption extends StatelessWidget {
  const _ModeOption({required this.title, required this.subtitle, required this.selected, required this.onTap});

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final borderRadius = BorderRadius.circular(14);

    return Semantics(
      container: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: selected ? colors.text : colors.borderStrong, width: selected ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.surface,
                    border: Border.all(color: selected ? colors.text : colors.textMuted, width: selected ? 6 : 2),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: textTheme.bodySmall?.copyWith(color: colors.neutral.onTint, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
