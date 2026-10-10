import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/clock.dart';
import '../../../core/dates.dart';
import '../../../core/ids.dart';
import '../../../core/money.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_list_row.dart';
import '../../../core/widgets/app_switch.dart';
import '../../../core/widgets/screen_placeholder.dart';
import '../../../core/widgets/section_label.dart';
import '../../../domain/models/app_settings.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/wallet.dart';
import '../../settings/application/settings_providers.dart';
import '../../transactions/presentation/widgets/date_picker_sheet.dart';
import '../application/wallet_providers.dart';
import 'widgets/wallet_visuals.dart';

/// Nuovo portafoglio ([walletId] null) o modifica di uno esistente.
class WalletFormScreen extends ConsumerWidget {
  const WalletFormScreen({super.key, this.walletId});

  final String? walletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (walletId == null) return const _WalletForm(initial: null);

    final overview = ref.watch(walletOverviewProvider(walletId!));
    return switch (overview) {
      AsyncValue(value: final initial?) => _WalletForm(initial: initial),
      AsyncValue(isLoading: true) => const Scaffold(body: SizedBox.shrink()),
      _ => const ScreenPlaceholder(title: 'Portafoglio', description: 'Questo portafoglio non esiste più.'),
    };
  }
}

class _WalletForm extends ConsumerStatefulWidget {
  const _WalletForm({required this.initial});

  /// Portafoglio da modificare; null per uno nuovo.
  final WalletOverview? initial;

  @override
  ConsumerState<_WalletForm> createState() => _WalletFormState();
}

class _WalletFormState extends ConsumerState<_WalletForm> {
  Wallet? get _original => widget.initial?.wallet;
  bool get _isNew => _original == null;

  late final _nameController = TextEditingController(text: _original?.name ?? '');
  late final _balanceController = TextEditingController(
    text: _original == null ? '' : formatCents(_original!.initialBalanceCents, withSymbol: false),
  );
  late WalletType _type = _original?.type ?? WalletType.checking;
  late LocalDate _date = _original?.initialBalanceDate ?? ref.read(todayProvider);
  late bool _defaultForExpenses = widget.initial?.isDefaultForExpenses ?? false;
  late bool _defaultForIncome = widget.initial?.isDefaultForIncome ?? false;
  late bool _includeInTotal = _original?.includeInTotal ?? true;
  var _showErrors = false;
  var _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  /// Saldo iniziale: vuoto vale zero; null se il testo non è un importo.
  int? get _initialBalance => _balanceController.text.trim().isEmpty ? 0 : parseCents(_balanceController.text);

  Future<void> _save(List<Wallet> wallets) async {
    final name = _nameController.text.trim();
    final initialBalance = _initialBalance;
    if (name.isEmpty || initialBalance == null) {
      setState(() => _showErrors = true);
      return;
    }

    final nextSortOrder = wallets.map((w) => w.sortOrder).fold(-1, (a, b) => a > b ? a : b) + 1;
    final wallet =
        (_original ?? Wallet(id: newId(), name: name, type: _type, initialBalanceDate: _date, sortOrder: nextSortOrder))
            .copyWith(
              name: name,
              type: _type,
              initialBalanceCents: initialBalance,
              initialBalanceDate: _date,
              includeInTotal: _includeInTotal,
            );

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(walletActionsProvider)
          .save(wallet, defaultForExpenses: _defaultForExpenses, defaultForIncome: _defaultForIncome);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;
    context.pop();
    messenger.showSnackBar(SnackBar(content: Text(_isNew ? 'Portafoglio creato' : 'Modifiche salvate')));
  }

  Future<void> _archive() async {
    final wallet = _original!;
    final actions = ref.read(walletActionsProvider);
    final messenger = ScaffoldMessenger.of(context);
    await actions.archive(wallet);
    if (!mounted) return;
    // Il dettaglio di un portafoglio archiviato non serve più: si torna alla lista.
    context.go(AppRoutes.wallets);
    messenger.showSnackBar(
      SnackBar(
        content: Text('"${wallet.name}" archiviato'),
        action: SnackBarAction(label: 'Annulla', onPressed: () => actions.unarchive(wallet)),
      ),
    );
  }

  Future<void> _unarchive() async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(walletActionsProvider).unarchive(_original!);
    if (!mounted) return;
    context.pop();
    messenger.showSnackBar(const SnackBar(content: Text('Portafoglio ripristinato')));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final settings = ref.watch(appSettingsProvider).value ?? const AppSettings();
    final wallets = ref.watch(walletsProvider).value ?? const <Wallet>[];
    String currentDefault(String? id) =>
        'Ora: ${wallets.firstWhereOrNull((w) => w.id == id && w.id != _original?.id)?.name ?? 'nessuno'}';
    final isArchived = _original?.isArchived ?? false;

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
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
              onPressed: _saving ? null : () => _save(wallets),
              child: Text(_isNew ? 'Crea portafoglio' : 'Salva modifiche'),
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
                  AppIconButton(icon: Icons.close_rounded, tooltip: 'Chiudi', onPressed: () => context.pop()),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        _isNew ? 'Nuovo portafoglio' : 'Modifica portafoglio',
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.minTouchTarget),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.xs, AppSpacing.screen, AppSpacing.xl),
                children: [
                  const SectionLabel('Nome'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Es. Conto Banca, Portafoglio, Broker',
                      errorText: _showErrors && _nameController.text.trim().isEmpty ? 'Inserisci un nome' : null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionLabel('Tipo'),
                  const SizedBox(height: AppSpacing.sm),
                  _TypeGrid(selected: _type, onChanged: (type) => setState(() => _type = type)),
                  if (_type == WalletType.investment) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                      decoration: BoxDecoration(
                        color: colors.investments.tint,
                        borderRadius: BorderRadius.circular(AppRadius.field),
                      ),
                      child: Text(
                        'Il valore di un investimento cambia anche senza movimenti: aggiornalo dal dettaglio del '
                        'portafoglio con "Aggiorna saldo". Ti avviseremo se non lo aggiorni da più di 30 giorni.',
                        style: textTheme.bodySmall?.copyWith(color: colors.neutral.onTint, height: 1.45),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SectionLabel('Saldo iniziale'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _balanceController,
                              onChanged: (_) => setState(() {}),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                              decoration: InputDecoration(
                                hintText: '0,00',
                                prefixText: '€ ',
                                errorText: _showErrors && _initialBalance == null ? 'Importo non valido' : null,
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
                            const SectionLabel('Alla data'),
                            const SizedBox(height: 6),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
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
                              child: Text(dateChipLabel(_date, today)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionLabel('Uso'),
                  const SizedBox(height: AppSpacing.sm),
                  AppListGroup(
                    children: [
                      AppListRow(
                        title: 'Predefinito per le spese',
                        subtitle: _defaultForExpenses
                            ? 'Le nuove spese partiranno da qui'
                            : currentDefault(settings.defaultExpenseWalletId),
                        onTap: isArchived ? null : () => setState(() => _defaultForExpenses = !_defaultForExpenses),
                        trailing: AppSwitch(
                          value: _defaultForExpenses,
                          onChanged: isArchived ? null : (value) => setState(() => _defaultForExpenses = value),
                        ),
                      ),
                      AppListRow(
                        title: 'Predefinito per le entrate',
                        subtitle: _defaultForIncome
                            ? 'Le nuove entrate arriveranno qui'
                            : currentDefault(settings.defaultIncomeWalletId),
                        onTap: isArchived ? null : () => setState(() => _defaultForIncome = !_defaultForIncome),
                        trailing: AppSwitch(
                          value: _defaultForIncome,
                          onChanged: isArchived ? null : (value) => setState(() => _defaultForIncome = value),
                        ),
                      ),
                      AppListRow(
                        title: 'Includi nel patrimonio',
                        subtitle: 'Conta nel totale della schermata Portafogli',
                        onTap: () => setState(() => _includeInTotal = !_includeInTotal),
                        trailing: AppSwitch(
                          value: _includeInTotal,
                          onChanged: (value) => setState(() => _includeInTotal = value),
                        ),
                      ),
                    ],
                  ),
                  if (!_isNew) ...[
                    const SizedBox(height: AppSpacing.xl),
                    if (isArchived)
                      OutlinedButton(onPressed: _unarchive, child: const Text('Ripristina portafoglio'))
                    else ...[
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: colors.danger),
                        onPressed: _archive,
                        child: const Text('Archivia portafoglio'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Un portafoglio archiviato non compare tra le scelte e non conta nel patrimonio. '
                        'I suoi movimenti restano.',
                        style: textTheme.bodySmall?.copyWith(height: 1.45),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Griglia 3×2 dei tipi di portafoglio.
class _TypeGrid extends StatelessWidget {
  const _TypeGrid({required this.selected, required this.onChanged});

  final WalletType selected;
  final ValueChanged<WalletType> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const order = [
      WalletType.cash,
      WalletType.checking,
      WalletType.card,
      WalletType.savings,
      WalletType.investment,
      WalletType.other,
    ];

    Widget tile(WalletType type) {
      final isSelected = type == selected;
      final color = isSelected ? colors.text : colors.neutral.onTint;
      final borderRadius = BorderRadius.circular(14);
      return Semantics(
        container: true,
        button: true,
        selected: isSelected,
        inMutuallyExclusiveGroup: true,
        child: Material(
          color: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius,
            side: BorderSide(color: isSelected ? colors.text : colors.borderStrong, width: isSelected ? 2 : 1),
          ),
          child: InkWell(
            borderRadius: borderRadius,
            onTap: () => onChanged(type),
            child: SizedBox(
              height: 78,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(walletTypeIcon(type), size: 22, color: color),
                  const SizedBox(height: 6),
                  Text(walletTypeLabel(type), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var row = 0; row < 2; row++) ...[
          if (row > 0) const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (var col = 0; col < 3; col++) ...[
                if (col > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(child: tile(order[row * 3 + col])),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
