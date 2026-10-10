import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/clock.dart';
import '../../../core/ids.dart';
import '../../../core/money.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/screen_placeholder.dart';
import '../../../core/widgets/section_label.dart';
import '../../../data/files/attachment_picker.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/app_settings.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/transaction.dart';
import '../../settings/application/settings_providers.dart';
import '../application/transaction_detail_providers.dart';
import '../application/transaction_form_controller.dart';
import 'widgets/attachments_grid.dart';
import 'widgets/attachments_sheet.dart';
import 'widgets/date_picker_sheet.dart';
import 'widgets/delete_transaction_dialog.dart';
import 'widgets/transaction_form.dart';

/// Modifica movimento: carica il movimento e mostra il form.
class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(transactionDetailProvider(transactionId))) {
      AsyncValue(value: final detail?) => _EditTransactionForm(detail: detail),
      AsyncValue(isLoading: true) => const Scaffold(body: SizedBox.shrink()),
      _ => const ScreenPlaceholder(
        title: 'Movimento',
        description: 'Questo movimento non esiste più: potrebbe essere stato eliminato.',
      ),
    };
  }
}

class _EditTransactionForm extends ConsumerStatefulWidget {
  const _EditTransactionForm({required this.detail});

  final TransactionDetail detail;

  @override
  ConsumerState<_EditTransactionForm> createState() => _EditTransactionFormState();
}

class _EditTransactionFormState extends ConsumerState<_EditTransactionForm> {
  late final TransactionFormSeed _seed = TransactionFormSeed.edit(widget.detail.transaction, widget.detail.attachments);
  late final _amountController = TextEditingController(
    text: formatCents(widget.detail.transaction.amountCents, withSymbol: false),
  );
  late final _noteController = TextEditingController(text: widget.detail.transaction.note ?? '');

  TransactionFormControllerProvider get _provider => transactionFormControllerProvider(_seed);
  Transaction get _original => widget.detail.transaction;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_provider);
    final controller = ref.read(_provider.notifier);
    final isDirty = controller.isDirty;
    final wallets = ref.watch(formWalletsProvider(_seed));
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final tone = formTone(context, state.type);
    final today = ref.watch(todayProvider);
    final settings = ref.watch(appSettingsProvider).value ?? const AppSettings();
    final timestamp = DateFormat('d MMM y, HH:mm', 'it_IT');

    return Scaffold(
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: AppSpacing.xl),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.md, AppSpacing.screen, 0),
            child: Row(
              children: [
                Tooltip(
                  message: 'Elimina movimento',
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      fixedSize: const Size.square(56),
                      minimumSize: const Size.square(56),
                      padding: EdgeInsets.zero,
                      foregroundColor: colors.danger,
                      side: BorderSide(color: colors.danger.withValues(alpha: 0.35)),
                    ),
                    onPressed: state.saving ? null : _delete,
                    child: const Icon(Icons.delete_outline_rounded, size: 22),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: tone.fill,
                      foregroundColor: tone.onFill,
                      minimumSize: const Size.fromHeight(56),
                    ),
                    // Attivo solo se qualcosa è cambiato.
                    onPressed: isDirty && !state.saving
                        ? () => state.isTransfer
                              ? _save(wallets.fromId, toWalletId: wallets.toId)
                              : _save(wallets.walletId)
                        : null,
                    child: const Text('Salva modifiche'),
                  ),
                ),
              ],
            ),
          ),
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
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text('Modifica movimento', textAlign: TextAlign.center, style: textTheme.titleMedium),
                    ),
                  ),
                  AppIconButton(
                    icon: Icons.copy_rounded,
                    // Si duplica il movimento salvato: con modifiche in sospeso il risultato confonderebbe.
                    tooltip: isDirty ? 'Salva le modifiche prima di duplicare' : 'Duplica movimento',
                    onPressed: isDirty || state.saving ? null : _duplicate,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.xs, AppSpacing.screen, AppSpacing.lg),
                children: [
                  TransactionTypeSelector(seed: _seed),
                  const SizedBox(height: 18),
                  _LabeledField(
                    label: 'Importo',
                    child: _AmountField(
                      controller: _amountController,
                      color: tone.text,
                      allowNegative: state.type == TransactionType.adjustment,
                      onChanged: (text) => controller.setAmount(parseCents(text) ?? 0),
                    ),
                  ),
                  if (state.showErrors && state.isAmountMissing) const FormErrorText('Inserisci un importo valido'),
                  const SizedBox(height: 18),
                  if (!state.isTransfer) ...[
                    _LabeledField(
                      label: 'Portafoglio',
                      child: _RowButton(
                        icon: Icons.account_balance_outlined,
                        text: wallets.nameOf(wallets.walletId),
                        semanticLabel: 'Portafoglio: ${wallets.nameOf(wallets.walletId)}',
                        onTap: () => pickFormWallet(context, ref, _seed),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  _LabeledField(
                    label: 'Data',
                    child: _RowButton(
                      icon: Icons.calendar_today_outlined,
                      text: _longDate(state.date.toDateTime()),
                      semanticLabel: 'Data: ${_longDate(state.date.toDateTime())}',
                      onTap: () async {
                        final picked = await showDatePickerSheet(
                          context,
                          selected: state.date,
                          today: today,
                          weekStart: settings.weekStart,
                        );
                        if (picked != null) controller.setDate(picked);
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  TransactionFormDetails(seed: _seed),
                  const SizedBox(height: 18),
                  _LabeledField(
                    label: 'Nota',
                    child: TextField(
                      controller: _noteController,
                      onChanged: controller.setNote,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(hintText: 'Nota (facoltativa)'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SectionLabel('Allegati', trailing: '${state.attachmentCount} di $maxAttachments'),
                  const SizedBox(height: AppSpacing.sm),
                  AttachmentsGrid(
                    items: [
                      for (final attachment in state.savedAttachments)
                        AttachmentGridItem(
                          name: attachment.localPath.split('/').last,
                          mimeType: attachment.mimeType,
                          onRemove: () => controller.removeSavedAttachment(attachment),
                        ),
                      for (final file in state.newAttachments)
                        AttachmentGridItem(
                          name: file.name,
                          mimeType: file.mimeType,
                          onRemove: () => controller.removeAttachment(file),
                        ),
                    ],
                    onAdd: state.canAddAttachment
                        ? () => showAttachmentsSheet(context, _provider, showThumbnails: false)
                        : null,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Creato il ${timestamp.format(widget.detail.createdAt.toLocal())} · '
                    'ultima modifica ${timestamp.format(widget.detail.updatedAt.toLocal())}',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _longDate(DateTime date) {
    final text = DateFormat('EEEE d MMMM y', 'it_IT').format(date);
    return text[0].toUpperCase() + text.substring(1);
  }

  Future<void> _save(String? walletId, {String? toWalletId}) async {
    final messenger = ScaffoldMessenger.of(context);
    final Transaction? saved;
    try {
      saved = await ref.read(_provider.notifier).save(walletId: walletId, toWalletId: toWalletId);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Salvataggio non riuscito. Riprova.')));
      return;
    }
    if (saved == null || !mounted) return;
    context.pop();
    messenger.showSnackBar(const SnackBar(content: Text('Modifiche salvate')));
  }

  /// Crea subito una copia del movimento salvato: nuovo ID, data di oggi, senza allegati.
  Future<void> _duplicate() async {
    final copy = _original.copyWith(
      id: newId(),
      date: ref.read(todayProvider),
      status: TransactionStatus.confirmed,
      // La copia non è un'occorrenza della ricorrenza.
      recurrenceId: null,
      occurrenceDate: null,
    );
    await ref.read(transactionRepositoryProvider).save(copy);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    context.pushReplacement(AppRoutes.transaction(copy.id));
    messenger.showSnackBar(const SnackBar(content: Text('Movimento duplicato')));
  }

  Future<void> _delete() async {
    final categories = ref.read(categoriesProvider).value ?? const <Category>[];
    final confirmed = await confirmDeleteTransaction(context, summary: _summary(categories));
    if (!confirmed || !mounted) return;

    // Il repository e il messenger vanno presi prima di chiudere: dopo il pop questo widget non c'è più.
    final repository = ref.read(transactionRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final id = _original.id;
    await repository.delete(id);
    if (!mounted) return;
    context.pop();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Movimento eliminato'),
        action: SnackBarAction(label: 'Annulla', onPressed: () => repository.restore(id)),
      ),
    );
  }

  /// "Esselunga · − € 64,20" per il dialog di conferma.
  String _summary(List<Category> categories) {
    final tx = _original;
    final title =
        tx.note ??
        categories.where((c) => c.id == tx.categoryId).map((c) => c.name).firstOrNull ??
        switch (tx.type) {
          TransactionType.transfer => 'Trasferimento',
          TransactionType.adjustment => 'Rettifica saldo',
          _ => 'Movimento',
        };
    final amount = switch (tx.type) {
      TransactionType.expense => '$minusSign ${formatCents(tx.amountCents)}',
      TransactionType.income => '+ ${formatCents(tx.amountCents)}',
      _ => formatCents(tx.amountCents),
    };
    return '$title · $amount';
  }
}

/// Titoletto maiuscolo sopra un campo.
class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [SectionLabel(label), const SizedBox(height: 6), child],
    );
  }
}

/// Campo importo: "€" e cifre grandi colorate per tipo.
class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.color,
    required this.allowNegative,
    required this.onChanged,
  });

  final TextEditingController controller;
  final Color color;
  final bool allowNegative;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    const tabular = [FontFeature.tabularFigures()];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderStrong),
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Text(
              '€',
              style: textTheme.headlineMedium?.copyWith(fontSize: 22, fontWeight: FontWeight.w700, color: color),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: TextInputType.numberWithOptions(decimal: true, signed: allowNegative),
              style: textTheme.headlineMedium?.copyWith(fontSize: 28, color: color, fontFeatures: tabular),
              // Il riquadro è il Container attorno: il campo non ha bordo né sfondo propri.
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
    );
  }
}

/// Riga toccabile a tutta larghezza (portafoglio, data) con chevron.
class _RowButton extends StatelessWidget {
  const _RowButton({required this.icon, required this.text, required this.semanticLabel, required this.onTap});

  final IconData icon;
  final String text;
  final String semanticLabel;
  final VoidCallback onTap;

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
          side: BorderSide(color: colors.borderStrong),
        ),
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: colors.text),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 20, color: colors.textMuted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
