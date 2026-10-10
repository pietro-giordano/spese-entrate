import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/clock.dart';
import '../../../core/dates.dart';
import '../../../core/ids.dart';
import '../../../data/files/attachment_picker.dart';
import '../../../data/files/attachment_storage.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/attachment.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/recurrence_rule.dart';
import '../../../domain/models/transaction.dart';
import '../../../domain/models/app_settings.dart';
import '../../../domain/models/wallet.dart';
import '../../../domain/services/recurrence.dart';
import '../../recurring/application/recurring_providers.dart';
import '../../settings/application/settings_providers.dart';
import '../../wallets/application/wallet_providers.dart';

part 'transaction_form_controller.freezed.dart';
part 'transaction_form_controller.g.dart';

/// Tasti del tastierino: `'0'`…`'9'`, `'00'` e [backspaceKey].
const backspaceKey = 'back';

/// Importo massimo digitabile: 9 cifre, cioè € 9.999.999,99.
const maxKeypadCents = 999999999;

/// Applica un tasto all'importo in centesimi: le cifre entrano da destra
/// (6 → 0,06; 4 → 0,64; 2 → 6,42), il tasto cancella toglie l'ultima.
/// Un tasto che supererebbe [maxKeypadCents] viene ignorato.
int applyKeypadKey(int cents, String key) {
  if (key == backspaceKey) return cents ~/ 10;
  final next = key == '00' ? cents * 100 : cents * 10 + int.parse(key);
  return next > maxKeypadCents ? cents : next;
}

/// Portafoglio da usare: la scelta fatta in questa schermata, altrimenti il predefinito,
/// altrimenti il primo disponibile. Considera solo portafogli non archiviati.
String? resolveWalletId({required String? chosenId, required String? defaultId, required List<Wallet> wallets}) {
  final available = wallets.where((w) => !w.isArchived).map((w) => w.id).toList();
  if (chosenId != null && available.contains(chosenId)) return chosenId;
  if (defaultId != null && available.contains(defaultId)) return defaultId;
  return available.isEmpty ? null : available.first;
}

/// Portafogli di un trasferimento: l'origine come [resolveWalletId] (predefinito: quello delle spese),
/// la destinazione scelta se diversa dall'origine, altrimenti il primo portafoglio diverso.
/// `to` è null se esiste un solo portafoglio.
({String? from, String? to}) resolveTransferWallets({
  required String? chosenFrom,
  required String? chosenTo,
  required String? defaultFromId,
  required List<Wallet> wallets,
}) {
  final from = resolveWalletId(chosenId: chosenFrom, defaultId: defaultFromId, wallets: wallets);
  final available = wallets.where((w) => !w.isArchived && w.id != from).map((w) => w.id).toList();
  final to = chosenTo != null && available.contains(chosenTo) ? chosenTo : available.firstOrNull;
  return (from: from, to: to);
}

/// Punto di partenza del form: un nuovo movimento di un certo tipo,
/// un movimento esistente con i suoi allegati (Modifica movimento),
/// oppure un movimento `pending` da confermare (Conferma da "In arrivo").
@freezed
sealed class TransactionFormSeed with _$TransactionFormSeed {
  const factory TransactionFormSeed.create(TransactionType type) = CreateTransactionSeed;
  const factory TransactionFormSeed.edit(Transaction original, List<Attachment> attachments) = EditTransactionSeed;
  const factory TransactionFormSeed.confirm(Transaction pending) = ConfirmTransactionSeed;
}

/// Ripetizione scelta in Inserimento rapido ("Ripeti" nel pannello della data).
/// I giorni fissi (del mese, della settimana) si ricavano dalla data del movimento.
@freezed
abstract class RepeatSettings with _$RepeatSettings {
  const factory RepeatSettings({
    required RecurrenceFrequency frequency,
    @Default(1) int interval,
    LocalDate? endDate,
    int? maxCount,
    @Default(RecurrenceMode.auto) RecurrenceMode mode,
  }) = _RepeatSettings;
}

/// Portata di una modifica a un movimento ricorrente.
enum EditScope {
  /// Solo questo movimento; la regola non cambia.
  single,

  /// Questo movimento e i successivi: la regola si divide.
  following,
}

@freezed
abstract class TransactionFormState with _$TransactionFormState {
  const factory TransactionFormState({
    required TransactionType type,
    required LocalDate date,
    @Default(0) int amountCents,
    String? categoryId,
    @Default(<String>{}) Set<String> labelIds,

    /// Portafogli scelti a mano, uno per tipo (null = usa il predefinito).
    String? expenseWalletId,
    String? incomeWalletId,

    /// Portafogli scelti a mano per il trasferimento.
    String? fromWalletId,
    String? toWalletId,
    @Default('') String note,

    /// Allegati già salvati (solo in modifica), esclusi quelli tolti.
    @Default(<Attachment>[]) List<Attachment> savedAttachments,

    /// Allegati salvati che l'utente ha tolto: al salvataggio vengono cancellati logicamente.
    @Default(<Attachment>[]) List<Attachment> removedAttachments,

    /// Allegati nuovi, copiati nella cartella dell'app solo al salvataggio.
    @Default(<PickedAttachment>[]) List<PickedAttachment> newAttachments,

    /// Movimento di partenza in modifica; null per un movimento nuovo.
    Transaction? original,

    /// Ripetizione del movimento nuovo (null = non si ripete).
    RepeatSettings? repeat,

    /// True quando si conferma un `pending`: il salvataggio lo porta a `confirmed`.
    @Default(false) bool confirming,

    /// True finché l'importo è quello proposto (conferma): il primo tasto lo sostituisce.
    @Default(false) bool amountIsSuggestion,

    /// Diventa true al primo tentativo di salvataggio: da lì si mostrano gli errori.
    @Default(false) bool showErrors,
    @Default(false) bool saving,
  }) = _TransactionFormState;

  const TransactionFormState._();

  bool get isEditing => original != null && !confirming;
  bool get isTransfer => type == TransactionType.transfer;

  /// Portafoglio scelto a mano per spese ed entrate (null = usa il predefinito).
  String? get chosenWalletId => type == TransactionType.income ? incomeWalletId : expenseWalletId;

  /// Le rettifiche hanno segno; tutti gli altri movimenti devono essere > 0.
  bool get isAmountMissing => type == TransactionType.adjustment ? amountCents == 0 : amountCents <= 0;

  /// La categoria è obbligatoria solo per spese ed entrate.
  bool get isCategoryMissing =>
      (type == TransactionType.expense || type == TransactionType.income) && categoryId == null;

  int get attachmentCount => savedAttachments.length + newAttachments.length;
  bool get canAddAttachment => attachmentCount < maxAttachments;

  /// Regola che si creerebbe con la ripetizione scelta: servono solo le date.
  RecurrenceRule? get draftRule => switch (repeat) {
    final repeat? when original == null => anchorRuleAt(
      RecurrenceRule(
        id: '',
        name: '',
        type: type,
        amountCents: 1,
        walletId: '',
        frequency: repeat.frequency,
        interval: repeat.interval,
        startDate: date,
        endDate: repeat.endDate,
        maxCount: repeat.maxCount,
        mode: repeat.mode,
      ),
      date,
    ),
    _ => null,
  };

  /// Occorrenze arretrate di una ripetizione che parte nel passato: dopo la prima (questo
  /// movimento) e prima di [today]. Vanno confermate dall'utente prima di registrarle.
  List<LocalDate> backlogDates(LocalDate today) => switch (draftRule) {
    final rule? => occurrencesBetween(rule, date.addDays(1), today.addDays(-1)),
    null => const [],
  };
}

/// Stato del form di un movimento, condiviso da Inserimento rapido e Modifica movimento.
/// Si auto-elimina quando la schermata si chiude, così ogni apertura riparte da zero.
@riverpod
class TransactionFormController extends _$TransactionFormController {
  /// Valori di partenza, per capire se qualcosa è cambiato.
  late TransactionFormState _initial;

  @override
  TransactionFormState build(TransactionFormSeed seed) {
    _initial = switch (seed) {
      CreateTransactionSeed(:final type) => TransactionFormState(type: type, date: ref.read(todayProvider)),
      EditTransactionSeed(:final original, :final attachments) => _fromTransaction(original, attachments),
      ConfirmTransactionSeed(:final pending) => _fromTransaction(
        pending,
        const [],
      ).copyWith(confirming: true, amountIsSuggestion: true),
    };
    return _initial;
  }

  static TransactionFormState _fromTransaction(Transaction original, List<Attachment> attachments) =>
      TransactionFormState(
        type: original.type,
        date: original.date,
        amountCents: original.amountCents,
        categoryId: original.categoryId,
        labelIds: original.labelIds.toSet(),
        expenseWalletId: original.type == TransactionType.income ? null : original.walletId,
        incomeWalletId: original.type == TransactionType.income ? original.walletId : null,
        fromWalletId: original.type == TransactionType.transfer ? original.walletId : null,
        toWalletId: original.toWalletId,
        note: original.note ?? '',
        savedAttachments: attachments,
        original: original,
      );

  /// True se qualche campo è diverso da quello di partenza (abilita "Salva" in modifica).
  bool get isDirty => !_sameValues(state, _initial);

  static const _labels = SetEquality<String>();

  static bool _sameValues(TransactionFormState a, TransactionFormState b) =>
      a.type == b.type &&
      a.date == b.date &&
      a.amountCents == b.amountCents &&
      a.categoryId == b.categoryId &&
      _labels.equals(a.labelIds, b.labelIds) &&
      a.expenseWalletId == b.expenseWalletId &&
      a.incomeWalletId == b.incomeWalletId &&
      a.fromWalletId == b.fromWalletId &&
      a.toWalletId == b.toWalletId &&
      a.note.trim() == b.note.trim() &&
      a.newAttachments.isEmpty &&
      a.removedAttachments.isEmpty;

  void setType(TransactionType type) {
    if (type == state.type) return;
    // Le categorie sono diverse per spese ed entrate: la scelta si azzera.
    state = state.copyWith(type: type, categoryId: null);
  }

  /// Con un importo proposto (conferma) il primo tasto riparte da zero: si scrive l'importo vero.
  void pressKey(String key) => state = state.copyWith(
    amountCents: applyKeypadKey(state.amountIsSuggestion ? 0 : state.amountCents, key),
    amountIsSuggestion: false,
  );

  void clearAmount() => state = state.copyWith(amountCents: 0, amountIsSuggestion: false);

  void setRepeat(RepeatSettings? repeat) => state = state.copyWith(repeat: repeat);

  /// Importo scritto a mano (Modifica movimento); 0 se il testo non è valido.
  void setAmount(int cents) => state = state.copyWith(amountCents: cents);
  void selectCategory(String categoryId) => state = state.copyWith(categoryId: categoryId);

  void toggleLabel(String labelId) {
    final labels = {...state.labelIds};
    if (!labels.remove(labelId)) labels.add(labelId);
    state = state.copyWith(labelIds: labels);
  }

  void setDate(LocalDate date) => state = state.copyWith(date: date);

  void chooseWallet(String walletId) {
    state = state.type == TransactionType.income
        ? state.copyWith(incomeWalletId: walletId)
        : state.copyWith(expenseWalletId: walletId);
  }

  /// Sceglie l'origine del trasferimento. Se è l'attuale destinazione, i due si scambiano.
  /// [from] e [to] sono i portafogli mostrati ora (già risolti con [resolveTransferWallets]).
  void chooseTransferSource(String walletId, {required String? from, required String? to}) {
    state = state.copyWith(fromWalletId: walletId, toWalletId: walletId == to ? from : to);
  }

  /// Sceglie la destinazione del trasferimento. Se è l'attuale origine, i due si scambiano.
  void chooseTransferDestination(String walletId, {required String? from, required String? to}) {
    state = state.copyWith(toWalletId: walletId, fromWalletId: walletId == from ? to : from);
  }

  void swapTransferWallets({required String? from, required String? to}) {
    state = state.copyWith(fromWalletId: to, toWalletId: from);
  }

  /// Aggiunge un allegato nuovo. Restituisce false se si è già al massimo.
  bool addAttachment(PickedAttachment file) {
    if (!state.canAddAttachment) return false;
    state = state.copyWith(newAttachments: [...state.newAttachments, file]);
    return true;
  }

  void removeAttachment(PickedAttachment file) {
    state = state.copyWith(newAttachments: [...state.newAttachments]..remove(file));
  }

  /// Toglie un allegato già salvato: verrà cancellato (logicamente) al salvataggio.
  void removeSavedAttachment(Attachment attachment) {
    state = state.copyWith(
      savedAttachments: [...state.savedAttachments]..remove(attachment),
      removedAttachments: [...state.removedAttachments, attachment],
    );
  }

  void setNote(String note) => state = state.copyWith(note: note);

  /// Salva il movimento: nuovo, oppure lo stesso ID se in modifica.
  /// [walletId] è il portafoglio (l'origine per i trasferimenti) e [toWalletId] la destinazione,
  /// già risolti dalla schermata. Restituisce il movimento salvato, o null se i dati non sono validi.
  ///
  /// - Con una ripetizione crea anche la regola, con questo movimento come prima occorrenza;
  ///   [skippedBacklog] sono le occorrenze arretrate che l'utente non vuole registrare.
  /// - In conferma il movimento diventa `confirmed`.
  /// - Con [EditScope.following] la regola si divide dalla data originale dell'occorrenza
  ///   (vedi `RecurrenceRepository.split`); può lanciare `SplitDateException`.
  ///
  /// Tutte le scritture sono un'unica transazione. I file nuovi vengono copiati prima;
  /// se la scrittura fallisce le copie vengono eliminate e l'errore viene rilanciato.
  Future<Transaction?> save({
    required String? walletId,
    String? toWalletId,
    EditScope scope = EditScope.single,
    List<LocalDate> skippedBacklog = const [],
  }) async {
    if (state.saving) return null;
    final walletsInvalid = walletId == null || (state.isTransfer && (toWalletId == null || toWalletId == walletId));
    if (state.isAmountMissing || state.isCategoryMissing || walletsInvalid) {
      state = state.copyWith(showErrors: true);
      return null;
    }

    final note = state.note.trim();
    final hasCategory = state.type == TransactionType.expense || state.type == TransactionType.income;
    // In modifica si parte dall'originale: stato, ricorrenza e occorrenza restano.
    final base =
        state.original ??
        Transaction(id: newId(), type: state.type, amountCents: 0, date: state.date, walletId: walletId);
    var transaction = base.copyWith(
      status: state.confirming ? TransactionStatus.confirmed : base.status,
      type: state.type,
      amountCents: state.amountCents,
      date: state.date,
      walletId: walletId,
      toWalletId: state.isTransfer ? toWalletId : null,
      // Trasferimenti e rettifiche non hanno categoria né label.
      categoryId: hasCategory ? state.categoryId : null,
      labelIds: hasCategory ? state.labelIds.toList() : const [],
      note: note.isEmpty ? null : note,
    );

    state = state.copyWith(saving: true);
    final storage = ref.read(attachmentStorageProvider);
    final stored = <Attachment>[];
    final recurrences = ref.read(recurrenceRepositoryProvider);
    final generator = ref.read(recurrenceGeneratorProvider);
    final draftRule = state.draftRule;
    final ruleName = _ruleName(transaction);
    try {
      for (final file in state.newAttachments) {
        stored.add(await storage.store(transaction.id, file));
      }
      await ref.read(atomicWritesProvider).run(() async {
        if (draftRule != null) {
          final rule = _ruleFrom(draftRule.copyWith(id: newId(), name: ruleName), transaction);
          await recurrences.save(rule, skippedDates: skippedBacklog);
          transaction = transaction.copyWith(recurrenceId: rule.id, occurrenceDate: rule.startDate);
        }
        if (scope == EditScope.following) transaction = await _splitRule(transaction);
        await ref
            .read(transactionRepositoryProvider)
            .save(
              transaction,
              attachments: stored,
              removedAttachmentIds: [for (final attachment in state.removedAttachments) attachment.id],
            );
      });
      // Le occorrenze successive (o arretrate accettate) della regola nuova.
      if (draftRule != null || scope == EditScope.following) await generator.run();
      return transaction;
    } catch (_) {
      await storage.delete(stored);
      rethrow;
    } finally {
      if (ref.mounted) state = state.copyWith(saving: false);
    }
  }

  /// Nome della regola: la nota, altrimenti la categoria, altrimenti il tipo.
  String _ruleName(Transaction tx) {
    final category = ref.read(categoriesProvider).value?.firstWhereOrNull((c) => c.id == tx.categoryId);
    return tx.note ?? category?.name ?? (tx.type == TransactionType.transfer ? 'Trasferimento' : 'Ricorrenza');
  }

  /// [rule] con i valori del movimento (importo, portafogli, categoria, label, nota),
  /// che parte dalla data del movimento.
  RecurrenceRule _ruleFrom(RecurrenceRule rule, Transaction tx) => anchorRuleAt(
    rule.copyWith(
      type: tx.type,
      amountCents: tx.amountCents,
      currency: tx.currency,
      walletId: tx.walletId,
      toWalletId: tx.toWalletId,
      categoryId: tx.categoryId,
      labelIds: tx.labelIds,
      note: tx.note,
    ),
    tx.date,
  );

  /// "Questa e le successive": la regola di [tx] finisce prima della sua data originale
  /// e ne nasce una nuova dalla data del form. Restituisce [tx] spostato sulla regola nuova.
  Future<Transaction> _splitRule(Transaction tx) async {
    final ruleId = tx.recurrenceId;
    final boundary = state.original?.occurrenceDate;
    final repository = ref.read(recurrenceRepositoryProvider);
    final old = ruleId == null ? null : await repository.getById(ruleId);
    if (old == null || boundary == null) throw StateError('Il movimento non fa parte di una ricorrenza attiva');
    final next = _ruleFrom(old.copyWith(id: newId()), tx);
    final saved = await repository.split(old.id, boundary: boundary, next: next);
    return tx.copyWith(recurrenceId: saved.id, occurrenceDate: saved.startDate);
  }
}

/// Portafogli effettivi del form, già risolti con predefiniti e scelte dell'utente.
class FormWallets {
  const FormWallets({required this.available, required this.walletId, required this.fromId, required this.toId});

  /// Portafogli tra cui scegliere (non archiviati, più quelli del movimento in modifica).
  final List<Wallet> available;

  /// Portafoglio di spese ed entrate.
  final String? walletId;

  /// Origine e destinazione del trasferimento.
  final String? fromId;
  final String? toId;

  bool get transferInvalid => fromId == null || toId == null || fromId == toId;

  String nameOf(String? id) => available.firstWhereOrNull((w) => w.id == id)?.name ?? 'Nessun portafoglio';
}

@riverpod
FormWallets formWallets(Ref ref, TransactionFormSeed seed) {
  final state = ref.watch(transactionFormControllerProvider(seed));
  final settings = ref.watch(appSettingsProvider).value ?? const AppSettings();
  final original = state.original;
  // Un movimento vecchio può usare un portafoglio poi archiviato: resta selezionabile.
  final available = [
    for (final wallet in ref.watch(walletsProvider).value ?? const <Wallet>[])
      if (!wallet.isArchived || wallet.id == original?.walletId || wallet.id == original?.toWalletId)
        wallet.copyWith(archivedAt: null),
  ];

  final isIncome = state.type == TransactionType.income;
  final transfer = resolveTransferWallets(
    chosenFrom: state.fromWalletId,
    chosenTo: state.toWalletId,
    defaultFromId: settings.defaultExpenseWalletId,
    wallets: available,
  );
  return FormWallets(
    available: available,
    walletId: resolveWalletId(
      chosenId: state.chosenWalletId,
      defaultId: isIncome ? settings.defaultIncomeWalletId : settings.defaultExpenseWalletId,
      wallets: available,
    ),
    fromId: transfer.from,
    toId: transfer.to,
  );
}
