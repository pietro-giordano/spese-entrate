import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/clock.dart';
import '../../../core/dates.dart';
import '../../../core/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/bottom_action_bar.dart';
import '../../../core/widgets/app_segmented.dart';
import '../../../core/widgets/choice_sheet.dart';
import '../../../core/widgets/fading_scroll_view.dart';
import '../../../core/widgets/screen_placeholder.dart';
import '../../../domain/models/app_settings.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/transaction.dart';
import '../../../domain/services/recurrence.dart';
import '../../recurring/application/recurring_providers.dart';
import '../../recurring/presentation/recurrence_text.dart';
import '../../settings/application/settings_providers.dart';
import '../application/transaction_detail_providers.dart';
import '../application/transaction_form_controller.dart';
import 'widgets/amount_keypad.dart';
import 'widgets/attachments_sheet.dart';
import 'widgets/date_picker_sheet.dart';
import 'widgets/date_repeat_sheet.dart';
import 'widgets/transaction_form.dart';

/// Inserimento rapido di una spesa, un'entrata o un trasferimento, aperto a schermo intero dal basso.
class QuickAddScreen extends StatelessWidget {
  const QuickAddScreen({super.key, required this.type, this.openRepeat = false});

  /// Tipo iniziale, scelto dal pulsante che ha aperto la schermata.
  final TransactionType type;

  /// Apre subito "Data e ripetizione" con "Ogni mese" (da "Nuova ricorrenza").
  final bool openRepeat;

  @override
  Widget build(BuildContext context) => _QuickAddForm(seed: TransactionFormSeed.create(type), openRepeat: openRepeat);
}

/// Conferma di un movimento `pending` (sezione "In arrivo"): Inserimento rapido già compilato.
class ConfirmTransactionScreen extends ConsumerWidget {
  const ConfirmTransactionScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(transactionDetailProvider(transactionId));
    final ruleId = detail.value?.transaction.recurrenceId;
    final rule = ruleId == null ? null : ref.watch(recurrenceRuleProvider(ruleId));
    if (detail.isLoading || (rule?.isLoading ?? false)) return const Scaffold(body: SizedBox.shrink());

    final tx = detail.value?.transaction;
    if (tx != null && canConfirmManually(tx, rule?.value)) {
      return _QuickAddForm(seed: TransactionFormSeed.confirm(tx));
    }
    return ScreenPlaceholder(
      title: 'Conferma',
      description: tx != null && !tx.isConfirmed
          ? 'Questo movimento è automatico: verrà registrato da solo il ${longDate(tx.date)}.'
          : 'Questo movimento è già stato confermato o non esiste più.',
    );
  }
}

class _QuickAddForm extends ConsumerStatefulWidget {
  const _QuickAddForm({required this.seed, this.openRepeat = false});

  final TransactionFormSeed seed;
  final bool openRepeat;

  @override
  ConsumerState<_QuickAddForm> createState() => _QuickAddFormState();
}

class _QuickAddFormState extends ConsumerState<_QuickAddForm> {
  late final _noteController = TextEditingController(text: ref.read(_provider).note);

  TransactionFormSeed get _seed => widget.seed;
  TransactionFormControllerProvider get _provider => transactionFormControllerProvider(_seed);

  @override
  void initState() {
    super.initState();
    if (widget.openRepeat) {
      // Dopo il primo fotogramma: durante la costruzione non si può modificare lo stato del form.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(_provider.notifier).setRepeat(const RepeatSettings(frequency: RecurrenceFrequency.monthly));
        _pickDate();
      });
    }
  }

  /// Pannello della data: con la ripetizione per un movimento nuovo, solo la data in conferma.
  Future<void> _pickDate() async {
    final state = ref.read(_provider);
    final controller = ref.read(_provider.notifier);
    final today = ref.read(todayProvider);
    final weekStart = (ref.read(appSettingsProvider).value ?? const AppSettings()).weekStart;
    if (state.confirming) {
      final picked = await showDatePickerSheet(context, selected: state.date, today: today, weekStart: weekStart);
      if (picked != null) controller.setDate(picked);
      return;
    }
    final choice = await showDateRepeatSheet(
      context,
      selected: state.date,
      repeat: state.repeat,
      today: today,
      weekStart: weekStart,
      namePlaceholder: recurrenceTitleOf(
        note: state.note,
        categoryName: ref.read(categoriesProvider).value?.firstWhereOrNull((c) => c.id == state.categoryId)?.name,
        type: state.type,
      ),
    );
    if (choice == null) return;
    controller
      ..setDate(choice.date)
      ..setRepeat(choice.repeat);
  }

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
    final dateLabel = dateChipLabel(state.date, today);
    final repeats = state.repeat != null || (state.confirming && state.original?.recurrenceId != null);

    // Con la tastiera di sistema aperta (nota) il tastierino numerico si nasconde.
    final systemKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      // Tastierino e "Salva" in basso: restano sopra la barra di sistema e, con la tastiera
      // aperta (nota), sopra la tastiera.
      bottomNavigationBar: BottomActionBar(
        color: colors.background,
        showBorder: false,
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                  : () => state.isTransfer ? _save(wallets.fromId, toWalletId: wallets.toId) : _save(wallets.walletId),
              child: Text(
                '${state.confirming ? 'Conferma' : 'Salva'} ${switch (state.type) {
                  TransactionType.income => 'entrata',
                  TransactionType.transfer => 'trasferimento',
                  _ => 'spesa',
                }}',
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 14, AppSpacing.screen, 0),
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
                    semanticLabel: 'Data del movimento: $dateLabel${repeats ? ', si ripete' : ''}',
                    onTap: _pickDate,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 16, color: colors.text),
                      const SizedBox(width: 6),
                      Text(dateLabel, style: textTheme.labelMedium),
                      if (repeats) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.repeat_rounded, size: 14, color: colors.text),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TransactionTypeSelector(seed: _seed, size: AppSegmentedSize.large),
              // Sfuma ai bordi quando c'è altro da scorrere (liste espanse, schermi bassi).
              Expanded(
                child: FadingScrollView(
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

    // Ripetizione che parte nel passato: gli arretrati si registrano solo se l'utente lo conferma.
    final backlog = ref.read(_provider).backlogDates(ref.read(todayProvider));
    var skippedBacklog = const <LocalDate>[];
    if (backlog.isNotEmpty) {
      final registerBacklog = await _askBacklog(backlog);
      if (registerBacklog == null || !mounted) return;
      if (!registerBacklog) skippedBacklog = backlog;
    }

    final Transaction? saved;
    try {
      saved = await ref
          .read(_provider.notifier)
          .save(walletId: walletId, toWalletId: toWalletId, skippedBacklog: skippedBacklog);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Salvataggio non riuscito. Riprova.')));
      return;
    }
    if (saved == null || !mounted) return;

    context.pop();
    final amount = formatCents(saved.amountCents);
    final verb = ref.read(_provider).confirming ? 'confermat' : 'salvat';
    final message = switch (saved.type) {
      TransactionType.income => 'Entrata di $amount ${verb}a',
      TransactionType.transfer => 'Trasferimento di $amount ${verb}o',
      _ => 'Spesa di $amount ${verb}a',
    };
    // Il messenger è quello dell'app: la SnackBar resta visibile sulla schermata sotto.
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  /// Chiede se registrare le occorrenze passate: true sì, false solo da oggi, null annulla.
  Future<bool?> _askBacklog(List<LocalDate> backlog) {
    final today = ref.read(todayProvider);
    final mode = ref.read(_provider).repeat?.mode;
    final count = backlog.length;
    final range = count == 1
        ? 'il ${shortDate(backlog.single, today)}'
        : 'dal ${shortDate(backlog.first, today)} al ${shortDate(backlog.last, today)}';
    return showChoiceSheet<bool>(
      context,
      title: 'Occorrenze passate',
      selected: null,
      choices: [
        Choice(
          value: true,
          label: count == 1 ? 'Registra anche quella passata' : 'Registra anche le $count passate',
          subtitle: mode == RecurrenceMode.confirm ? '$range, da confermare in "In arrivo"' : range,
        ),
        const Choice(value: false, label: 'Solo da oggi in poi', subtitle: 'Le occorrenze passate restano saltate'),
      ],
      hint: 'La ripetizione parte da una data passata. Questo movimento si salva in ogni caso.',
    );
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
