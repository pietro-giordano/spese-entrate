import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/clock.dart';
import '../../../core/ids.dart';
import '../../../data/files/csv_files.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/label.dart';
import '../../../domain/models/wallet.dart';
import '../../../domain/services/csv_import.dart';
import '../../../domain/services/import_operations.dart';
import '../../wallets/application/wallet_providers.dart';
import 'settings_providers.dart';

part 'import_controller.freezed.dart';
part 'import_controller.g.dart';

/// Passi del flusso "Importa da CSV".
enum ImportStep { intro, preview, matching, options, running, done }

/// Esito di un import concluso.
class ImportSummary {
  const ImportSummary({
    required this.importId,
    required this.inserted,
    required this.updated,
    required this.skipped,
    required this.newWallets,
    required this.newCategories,
    required this.newLabels,
  });

  final String importId;
  final int inserted;
  final int updated;

  /// Righe saltate: con errori nel file o scartate dalle scelte fatte.
  final int skipped;
  final int newWallets;
  final int newCategories;
  final int newLabels;
}

@freezed
abstract class ImportFlowState with _$ImportFlowState {
  const factory ImportFlowState({
    @Default(ImportStep.intro) ImportStep step,
    String? fileName,
    String? content,
    ImportPlan? plan,
    @Default(ImportChoices()) ImportChoices choices,

    /// Portafoglio per le righe con la colonna vuota (null = quelle righe sono errori).
    String? fallbackWalletId,
    @Default(0) int progressDone,
    @Default(0) int progressTotal,
    ImportSummary? summary,

    /// Messaggio per l'utente quando qualcosa va storto (file illeggibile, import fallito).
    String? errorMessage,
    @Default(false) bool busy,
  }) = _ImportFlowState;

  const ImportFlowState._();

  /// Ci sono portafogli o categorie sconosciuti da creare o abbinare.
  bool get needsMatching => plan != null && (plan!.unknownWallets.isNotEmpty || plan!.unknownCategories.isNotEmpty);
}

/// Flusso "Importa da CSV": scelta del file, anteprima, abbinamenti, opzioni, importazione.
/// Si auto-elimina quando la schermata si chiude.
@riverpod
class ImportController extends _$ImportController {
  @override
  ImportFlowState build() => const ImportFlowState();

  /// Condivide il modello CSV (intestazioni e 3 righe di esempio).
  Future<void> downloadTemplate() async {
    try {
      await ref.read(csvFilesProvider).shareTemplate(csvImportTemplate(today: ref.read(todayProvider)));
    } on Exception {
      state = state.copyWith(errorMessage: 'Non è stato possibile condividere il modello. Riprova.');
    }
  }

  /// Sceglie il file e prepara l'anteprima.
  Future<void> pickFile() async {
    state = state.copyWith(errorMessage: null);
    final PickedCsv? picked;
    try {
      picked = await ref.read(csvFilesProvider).pickCsv();
    } on Exception {
      state = state.copyWith(errorMessage: 'Non è stato possibile leggere il file. Riprova.');
      return;
    }
    if (picked == null || !ref.mounted) return;
    if (!picked.name.toLowerCase().endsWith('.csv')) {
      state = state.copyWith(errorMessage: '«${picked.name}» non è un file .csv');
      return;
    }
    state = state.copyWith(
      fileName: picked.name,
      content: picked.content,
      choices: const ImportChoices(),
      fallbackWalletId: null,
    );
    await _replan();
    if (ref.mounted) state = state.copyWith(step: ImportStep.preview);
  }

  /// Rifà il piano con il file e le opzioni attuali (veloce anche con migliaia di righe).
  Future<void> _replan() async {
    final content = state.content;
    if (content == null) return;
    state = state.copyWith(busy: true);
    final wallets = await ref.read(walletsProvider.future);
    final categories = await ref.read(categoriesProvider.future);
    final labels = await ref.read(labelsProvider.future);
    final ids = await ref.read(importRepositoryProvider).transactionIds();
    if (!ref.mounted) return;
    final plan = planCsvImport(
      content,
      wallets: wallets,
      categories: categories,
      labels: labels,
      activeIds: ids.active,
      deletedIds: ids.deleted,
      fallbackWallet: wallets.firstWhereOrNull((w) => w.id == state.fallbackWalletId),
    );
    // Gli abbinamenti valgono solo per i nomi ancora sconosciuti.
    final choices = state.choices.copyWith(
      walletMatches: {
        for (final MapEntry(:key, :value) in state.choices.walletMatches.entries)
          if (plan.unknownWallets.contains(key)) key: value,
      },
      categoryMatches: {
        for (final MapEntry(:key, :value) in state.choices.categoryMatches.entries)
          if (plan.unknownCategories.contains(key)) key: value,
      },
    );
    state = state.copyWith(plan: plan, choices: choices, busy: false);
  }

  /// Passo successivo: gli abbinamenti solo se ci sono nomi sconosciuti.
  void next() {
    state = state.copyWith(
      errorMessage: null,
      step: switch (state.step) {
        ImportStep.intro => ImportStep.intro,
        ImportStep.preview => state.needsMatching ? ImportStep.matching : ImportStep.options,
        ImportStep.matching => ImportStep.options,
        final step => step,
      },
    );
  }

  /// Passo precedente. Restituisce false se si è all'inizio (la schermata si chiude).
  bool back() {
    final previous = switch (state.step) {
      ImportStep.preview => ImportStep.intro,
      ImportStep.matching => ImportStep.preview,
      ImportStep.options => state.needsMatching ? ImportStep.matching : ImportStep.preview,
      _ => null,
    };
    if (previous == null) return false;
    state = state.copyWith(step: previous, errorMessage: null);
    return true;
  }

  /// [walletId] null = "Crea nuovo".
  void matchWallet(String name, String? walletId) {
    final matches = {...state.choices.walletMatches}..remove(name);
    if (walletId != null) matches[name] = walletId;
    state = state.copyWith(choices: state.choices.copyWith(walletMatches: matches));
  }

  /// [categoryId] null = "Crea nuova".
  void matchCategory(UnknownCategory category, String? categoryId) {
    final matches = {...state.choices.categoryMatches}..remove(category);
    if (categoryId != null) matches[category] = categoryId;
    state = state.copyWith(choices: state.choices.copyWith(categoryMatches: matches));
  }

  Future<void> setFallbackWallet(String? walletId) async {
    state = state.copyWith(fallbackWalletId: walletId);
    await _replan();
  }

  void setExtraLabel(String name) {
    final trimmed = name.trim();
    state = state.copyWith(choices: state.choices.copyWith(extraLabel: () => trimmed.isEmpty ? null : trimmed));
  }

  /// Importa in un'unica transazione, a blocchi, con l'avanzamento; poi il riepilogo.
  Future<void> run() async {
    final plan = state.plan;
    if (plan == null || plan.rows.isEmpty || state.step == ImportStep.running) return;
    state = state.copyWith(
      step: ImportStep.running,
      progressDone: 0,
      progressTotal: plan.rows.length,
      errorMessage: null,
    );

    final repository = ref.read(importRepositoryProvider);
    try {
      final wallets = await ref.read(walletsProvider.future);
      final categories = await ref.read(categoriesProvider.future);
      final labels = await ref.read(labelsProvider.future);
      final importId = newId();
      final operations = buildImportOperations(
        plan: plan,
        choices: state.choices,
        batchId: importId,
        wallets: wallets,
        categories: categories,
        labels: labels,
        existing: await repository.transactionsByIds({for (final row in plan.updates) row.id}),
        today: ref.read(todayProvider),
        newId: newId,
      );
      await repository.execute(
        id: importId,
        fileName: state.fileName ?? 'import.csv',
        rowCount: plan.readRowCount,
        operations: operations,
        onProgress: (done, total) {
          if (ref.mounted) state = state.copyWith(progressDone: done, progressTotal: total);
        },
      );
      if (!ref.mounted) return;
      state = state.copyWith(
        step: ImportStep.done,
        summary: ImportSummary(
          importId: importId,
          inserted: operations.inserts.length,
          updated: operations.updates.length,
          skipped: plan.skippedRowCount + operations.skipped.length,
          newWallets: operations.newWallets.length,
          newCategories: operations.newCategories.length,
          newLabels: operations.newLabels.length,
        ),
      );
    } catch (_) {
      // Tutto in una transazione: se qualcosa va storto non è stato importato nulla.
      if (ref.mounted) {
        state = state.copyWith(
          step: ImportStep.options,
          errorMessage: 'Importazione non riuscita: non è stato importato nulla. Riprova.',
        );
      }
    }
  }
}

/// Portafogli tra cui scegliere negli abbinamenti e nelle opzioni (non archiviati).
List<Wallet> walletsForMatching(List<Wallet> wallets) => [
  for (final w in wallets)
    if (!w.isArchived) w,
];

/// Categorie abbinabili a una sconosciuta: stesso tipo, non archiviate.
List<Category> categoriesForMatching(List<Category> categories, UnknownCategory unknown) => [
  for (final c in categories)
    if (!c.isArchived && c.kind == unknown.kind) c,
];

/// La label aggiuntiva esiste già? (per dire "verrà creata").
bool labelExists(List<Label> labels, String name) =>
    labels.any((l) => l.name.toLowerCase() == name.trim().toLowerCase());
