import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_list_row.dart';
import '../../../core/widgets/bottom_action_bar.dart';
import '../../../core/widgets/choice_sheet.dart';
import '../../../core/widgets/section_label.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/label.dart';
import '../../../domain/models/wallet.dart';
import '../../../domain/services/csv_import.dart';
import '../../wallets/application/wallet_providers.dart';
import '../application/import_controller.dart';
import '../application/settings_providers.dart';

/// "Regali (spesa)" / "Regali (entrata)".
String _categoryTitle(UnknownCategory c) => '${c.name} (${c.kind == CategoryKind.expense ? 'spesa' : 'entrata'})';

/// "1 movimento" / "3 movimenti".
String _count(int n, String one, String many) => '$n ${n == 1 ? one : many}';

/// Colonne del CSV con la spiegazione mostrata nella schermata introduttiva.
const _columns = [
  ('data', 'AAAA-MM-GG oppure GG/MM/AAAA'),
  ('tipo', 'spesa, entrata, trasferimento o rettifica'),
  ('importo', 'es. 1.234,56 oppure 1234.56; la rettifica può essere negativa'),
  ('valuta', 'vuota oppure EUR'),
  ('portafoglio', 'nome del portafoglio (se manca può essere creato)'),
  ('portafoglio_destinazione', 'solo per i trasferimenti'),
  ('categoria', 'obbligatoria per spese ed entrate'),
  ('label', 'facoltative, separate da |'),
  ('nota', 'facoltativa'),
  ('id', 'vuoto per i movimenti nuovi; l\'id di un movimento esistente lo aggiorna'),
];

/// Impostazioni › Dati › Importa da CSV: introduzione, anteprima, abbinamenti, opzioni,
/// importazione e riepilogo. Niente viene salvato prima di "Importa".
class ImportScreen extends ConsumerWidget {
  const ImportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(importControllerProvider);
    final controller = ref.read(importControllerProvider.notifier);
    // Servono già caricati per il piano e gli abbinamenti.
    ref
      ..watch(walletsProvider)
      ..watch(categoriesProvider)
      ..watch(labelsProvider);
    final textTheme = Theme.of(context).textTheme;
    final running = state.step == ImportStep.running;

    void goBack() {
      if (running) return;
      if (state.step == ImportStep.done || !controller.back()) context.pop();
    }

    return PopScope(
      // Indietro torna al passo precedente; durante l'importazione non si esce.
      canPop: state.step == ImportStep.intro || state.step == ImportStep.done,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) goBack();
      },
      child: Scaffold(
        bottomNavigationBar: _BottomAction(state: state),
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 14, AppSpacing.screen, 10),
                child: Row(
                  children: [
                    AppIconButton(
                      icon: Icons.chevron_left_rounded,
                      tooltip: 'Indietro',
                      onPressed: running ? null : goBack,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text('Importa da CSV', style: textTheme.headlineMedium?.copyWith(fontSize: 22)),
                      ),
                    ),
                    if (_stepNumber(state.step) case final n?)
                      Text('$n di 4', style: textTheme.labelMedium?.copyWith(color: context.colors.textMuted)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.xs, AppSpacing.screen, AppSpacing.xl),
                  children: [
                    // In cima: un errore deve vedersi subito, anche con una pagina lunga.
                    if (state.errorMessage case final message?) ...[
                      _Notice(message: message, danger: true),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    ...switch (state.step) {
                      ImportStep.intro => _intro(context, ref),
                      ImportStep.preview => _preview(context, state),
                      ImportStep.matching => _matching(context, ref, state),
                      ImportStep.options => _options(context, ref, state),
                      ImportStep.running => _running(context, state),
                      ImportStep.done => _done(context, state),
                    },
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static int? _stepNumber(ImportStep step) => switch (step) {
    ImportStep.preview => 1,
    ImportStep.matching => 2,
    ImportStep.options => 3,
    ImportStep.running => 4,
    _ => null,
  };

  List<Widget> _intro(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return [
      Text(
        'Importa movimenti da un file CSV, ad esempio preparato con il modello o esportato da questa app. '
        'Prima di salvare vedrai un\'anteprima: niente cambia finché non confermi.',
        style: textTheme.bodyMedium?.copyWith(height: 1.45),
      ),
      const SizedBox(height: AppSpacing.lg),
      const SectionLabel('Colonne, in quest\'ordine', indent: true),
      const SizedBox(height: AppSpacing.sm),
      AppListGroup(
        children: [for (final (name, description) in _columns) AppListRow(title: name, subtitle: description)],
      ),
      const SizedBox(height: AppSpacing.md),
      Text(
        'Separatore ; oppure , · prima riga con le intestazioni esatte · righe con errori saltate, '
        'mai importate a metà.',
        style: textTheme.bodySmall?.copyWith(height: 1.45),
      ),
      const SizedBox(height: AppSpacing.lg),
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
        icon: const Icon(Icons.download_rounded, size: 20),
        label: const Text('Scarica modello'),
        onPressed: ref.read(importControllerProvider.notifier).downloadTemplate,
      ),
    ];
  }

  List<Widget> _preview(BuildContext context, ImportFlowState state) {
    final plan = state.plan;
    if (plan == null) return const [];
    final textTheme = Theme.of(context).textTheme;
    if (plan.isUnreadable) {
      return [
        Text(state.fileName ?? '', style: textTheme.titleSmall),
        const SizedBox(height: AppSpacing.md),
        _Notice(message: 'Il file non si può importare. ${plan.errors.first.message}.', danger: true),
      ];
    }
    final updates = plan.updates.length;
    return [
      Text(state.fileName ?? '', style: textTheme.titleSmall),
      const SizedBox(height: AppSpacing.md),
      Row(
        children: [
          Expanded(
            child: _Stat(value: plan.rows.length, label: 'righe pronte'),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Stat(value: plan.skippedRowCount, label: 'con errori (saltate)'),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Stat(value: plan.warnings.length, label: 'avvisi'),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      Text(
        '${_count(plan.inserts.length, 'movimento nuovo', 'movimenti nuovi')} · '
        '${updates == 1 ? '1 aggiorna un movimento esistente' : '$updates aggiornano movimenti esistenti'}',
        style: textTheme.bodyMedium,
      ),
      if (updates > 0) ...[const SizedBox(height: AppSpacing.md), _UpdatesWarning(count: updates)],
      if (plan.unknownLabels.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.md),
        _Notice(message: 'Verranno create le label ${plan.unknownLabels.map((l) => '#$l').join(', ')}.'),
      ],
      if (plan.errors.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.lg),
        _IssueList(title: 'Errori', issues: plan.errors),
      ],
      if (plan.warnings.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.lg),
        _IssueList(title: 'Avvisi', issues: plan.warnings),
      ],
    ];
  }

  List<Widget> _matching(BuildContext context, WidgetRef ref, ImportFlowState state) {
    final plan = state.plan!;
    final controller = ref.read(importControllerProvider.notifier);
    final wallets = walletsForMatching(ref.watch(walletsProvider).value ?? const <Wallet>[]);
    final categories = ref.watch(categoriesProvider).value ?? const <Category>[];

    Future<void> pickWallet(String name) async {
      final chosen = await showChoiceSheet<String>(
        context,
        title: 'Portafoglio «$name»',
        selected: state.choices.walletMatches[name] ?? '',
        choices: [
          Choice(value: '', label: 'Crea nuovo', subtitle: 'Portafoglio «$name» di tipo Altro, saldo iniziale 0'),
          for (final w in wallets) Choice(value: w.id, label: 'Abbina a ${w.name}'),
        ],
      );
      if (chosen != null) controller.matchWallet(name, chosen.isEmpty ? null : chosen);
    }

    Future<void> pickCategory(UnknownCategory unknown) async {
      final chosen = await showChoiceSheet<String>(
        context,
        title: 'Categoria ${_categoryTitle(unknown)}',
        selected: state.choices.categoryMatches[unknown] ?? '',
        choices: [
          Choice(
            value: '',
            label: 'Crea nuova',
            subtitle: unknown.kind == CategoryKind.expense
                ? 'Categoria di spesa «${unknown.name}»'
                : 'Categoria di entrata «${unknown.name}»',
          ),
          for (final c in categoriesForMatching(categories, unknown)) Choice(value: c.id, label: 'Abbina a ${c.name}'),
        ],
      );
      if (chosen != null) controller.matchCategory(unknown, chosen.isEmpty ? null : chosen);
    }

    String status(String? matchId, String Function(String id) nameOf, String createdText) =>
        matchId == null ? createdText : 'Abbinato a ${nameOf(matchId)}';

    return [
      Text(
        'Questi nomi non esistono ancora. Per ognuno scegli se crearlo o abbinarlo a uno esistente.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
      ),
      if (plan.unknownWallets.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.lg),
        const SectionLabel('Portafogli', indent: true),
        const SizedBox(height: AppSpacing.sm),
        AppListGroup(
          children: [
            for (final name in plan.unknownWallets)
              AppListRow(
                title: name,
                subtitle: status(
                  state.choices.walletMatches[name],
                  (id) => wallets.firstWhereOrNull((w) => w.id == id)?.name ?? '?',
                  'Verrà creato',
                ),
                onTap: () => pickWallet(name),
              ),
          ],
        ),
      ],
      // Nome + tipo: "Regali (spesa)" e "Regali (entrata)" sono due categorie distinte.
      if (plan.unknownCategories.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.lg),
        const SectionLabel('Categorie', indent: true),
        const SizedBox(height: AppSpacing.sm),
        AppListGroup(
          children: [
            for (final unknown in plan.unknownCategories)
              AppListRow(
                title: _categoryTitle(unknown),
                subtitle: status(
                  state.choices.categoryMatches[unknown],
                  (id) => categories.firstWhereOrNull((c) => c.id == id)?.name ?? '?',
                  unknown.kind == CategoryKind.expense
                      ? 'Verrà creata come categoria di spesa'
                      : 'Verrà creata come categoria di entrata',
                ),
                onTap: () => pickCategory(unknown),
              ),
          ],
        ),
      ],
    ];
  }

  List<Widget> _options(BuildContext context, WidgetRef ref, ImportFlowState state) {
    final plan = state.plan!;
    final controller = ref.read(importControllerProvider.notifier);
    final wallets = walletsForMatching(ref.watch(walletsProvider).value ?? const <Wallet>[]);
    final labels = ref.watch(labelsProvider).value ?? const <Label>[];
    final textTheme = Theme.of(context).textTheme;
    final fallback = wallets.firstWhereOrNull((w) => w.id == state.fallbackWalletId);
    final missingWallet = plan.errors.where((e) => e.message.startsWith('portafoglio mancante')).length;
    final extra = state.choices.extraLabel;

    Future<void> pickFallback() async {
      final chosen = await showChoiceSheet<String>(
        context,
        title: 'Righe senza portafoglio',
        selected: state.fallbackWalletId ?? '',
        choices: [
          const Choice(value: '', label: 'Nessuno', subtitle: 'Le righe senza portafoglio vengono saltate'),
          for (final w in wallets) Choice(value: w.id, label: w.name),
        ],
      );
      if (chosen != null) await controller.setFallbackWallet(chosen.isEmpty ? null : chosen);
    }

    return [
      const SectionLabel('Opzioni', indent: true),
      const SizedBox(height: AppSpacing.sm),
      AppListGroup(
        children: [
          AppListRow(
            title: 'Portafoglio se la colonna è vuota',
            subtitle: missingWallet > 0
                ? '${_count(missingWallet, 'riga', 'righe')} senza portafoglio'
                : 'Usato per le righe senza portafoglio',
            value: fallback?.name ?? 'Nessuno',
            onTap: pickFallback,
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      const SectionLabel('Label aggiuntiva', indent: true),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        initialValue: extra,
        onChanged: controller.setExtraLabel,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(hintText: 'es. import-ottobre (facoltativa)'),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        extra == null
            ? 'Aggiunta a tutte le spese e le entrate importate.'
            : labelExists(labels, extra)
            ? 'Aggiunta a tutte le spese e le entrate importate.'
            : 'Aggiunta a tutte le spese e le entrate importate. La label #$extra verrà creata.',
        style: textTheme.bodySmall,
      ),
      const SizedBox(height: AppSpacing.lg),
      const SectionLabel('Riepilogo', indent: true),
      const SizedBox(height: AppSpacing.sm),
      AppListGroup(
        children: [
          AppListRow(title: 'Movimenti nuovi', value: '${plan.inserts.length}'),
          AppListRow(title: 'Movimenti esistenti aggiornati', value: '${plan.updates.length}'),
          AppListRow(title: 'Righe saltate per errori', value: '${plan.skippedRowCount}'),
        ],
      ),
      if (plan.updates.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.md),
        _UpdatesWarning(count: plan.updates.length),
      ],
    ];
  }

  List<Widget> _running(BuildContext context, ImportFlowState state) {
    final textTheme = Theme.of(context).textTheme;
    final total = state.progressTotal;
    return [
      const SizedBox(height: AppSpacing.xxl),
      Text('Importazione in corso…', textAlign: TextAlign.center, style: textTheme.titleMedium),
      const SizedBox(height: AppSpacing.lg),
      Semantics(
        label: 'Importati ${state.progressDone} di $total',
        child: LinearProgressIndicator(value: total == 0 ? null : state.progressDone / total, minHeight: 8),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text('${state.progressDone} di $total', textAlign: TextAlign.center, style: textTheme.bodySmall),
      const SizedBox(height: AppSpacing.lg),
      Text(
        'Tutto avviene in un\'unica operazione: se si interrompe, non viene importato nulla.',
        textAlign: TextAlign.center,
        style: textTheme.bodySmall?.copyWith(height: 1.45),
      ),
    ];
  }

  List<Widget> _done(BuildContext context, ImportFlowState state) {
    final summary = state.summary;
    if (summary == null) return const [];
    final colors = context.colors;
    return [
      const SizedBox(height: AppSpacing.lg),
      ExcludeSemantics(child: Icon(Icons.check_circle_outline_rounded, size: 48, color: colors.income.text)),
      const SizedBox(height: AppSpacing.md),
      Text('Importazione completata', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSpacing.lg),
      AppListGroup(
        children: [
          AppListRow(title: 'Movimenti nuovi', value: '${summary.inserted}'),
          AppListRow(title: 'Movimenti aggiornati', value: '${summary.updated}'),
          AppListRow(title: 'Righe saltate', value: '${summary.skipped}'),
          if (summary.newWallets > 0) AppListRow(title: 'Portafogli creati', value: '${summary.newWallets}'),
          if (summary.newCategories > 0) AppListRow(title: 'Categorie create', value: '${summary.newCategories}'),
          if (summary.newLabels > 0) AppListRow(title: 'Label create', value: '${summary.newLabels}'),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      TextButton(
        style: TextButton.styleFrom(minimumSize: const Size.fromHeight(AppSizes.minTouchTarget)),
        onPressed: () => context.pushReplacement(AppRoutes.imports),
        child: const Text('Storico importazioni'),
      ),
    ];
  }
}

/// Pulsante principale in basso, diverso per ogni passo.
class _BottomAction extends ConsumerWidget {
  const _BottomAction({required this.state});

  final ImportFlowState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(importControllerProvider.notifier);
    final plan = state.plan;
    final (String label, VoidCallback? onPressed) = switch (state.step) {
      ImportStep.intro => ('Scegli file', state.busy ? null : controller.pickFile),
      ImportStep.preview when plan == null || plan.isUnreadable || plan.rows.isEmpty => (
        'Scegli un altro file',
        controller.pickFile,
      ),
      ImportStep.preview || ImportStep.matching => ('Continua', controller.next),
      ImportStep.options => (
        plan!.rows.length == 1 ? 'Importa 1 movimento' : 'Importa ${plan.rows.length} movimenti',
        plan.rows.isEmpty || state.busy ? null : controller.run,
      ),
      ImportStep.running => ('Importazione in corso…', null),
      ImportStep.done => ('Vai ai movimenti', () => context.go(AppRoutes.transactions)),
    };
    return BottomActionBar(
      child: FilledButton(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: '$value $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$value', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            Text(label, style: textTheme.labelSmall?.copyWith(color: colors.textMuted)),
          ],
        ),
      ),
    );
  }
}

/// Avviso in evidenza: gli aggiornamenti non si annullano con "Annulla importazione".
class _UpdatesWarning extends StatelessWidget {
  const _UpdatesWarning({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => _Notice(
    danger: true,
    message: count == 1
        ? '1 movimento esistente verrà aggiornato con i dati del file. Annullando l\'importazione '
              'non tornerà com\'era: si cancellano solo i movimenti nuovi.'
        : '$count movimenti esistenti verranno aggiornati con i dati del file. Annullando l\'importazione '
              'non torneranno com\'erano: si cancellano solo i movimenti nuovi.',
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, this.danger = false});

  final String message;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tone = danger ? colors.expense : colors.neutral;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: tone.tint, borderRadius: BorderRadius.circular(AppRadius.field)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(
              danger ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
              size: 20,
              color: tone.onTint,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tone.onTint, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

/// Errori o avvisi con il numero di riga, chiusi di base: si aprono toccando il titolo.
class _IssueList extends StatefulWidget {
  const _IssueList({required this.title, required this.issues});

  final String title;
  final List<ImportIssue> issues;

  @override
  State<_IssueList> createState() => _IssueListState();
}

class _IssueListState extends State<_IssueList> {
  var _open = false;

  /// Oltre questo numero si mostra solo il conteggio di quelli nascosti.
  static const _maxShown = 200;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final shown = widget.issues.take(_maxShown).toList();
    return AppListGroup(
      children: [
        AppListRow(
          title: '${widget.title} (${widget.issues.length})',
          trailing: Icon(
            _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            color: colors.textMuted,
            semanticLabel: _open ? 'Chiudi' : 'Apri',
          ),
          onTap: () => setState(() => _open = !_open),
        ),
        if (_open) ...[
          for (final issue in shown)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 72,
                    child: Text(
                      'Riga ${issue.line}',
                      style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Expanded(child: Text(issue.message, style: textTheme.bodySmall?.copyWith(height: 1.4))),
                ],
              ),
            ),
          if (widget.issues.length > shown.length)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text('… e altri ${widget.issues.length - shown.length}', style: textTheme.bodySmall),
            ),
        ],
      ],
    );
  }
}
