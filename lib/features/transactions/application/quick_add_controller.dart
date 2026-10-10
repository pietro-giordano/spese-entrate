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
import '../../../domain/models/transaction.dart';
import '../../../domain/models/wallet.dart';

part 'quick_add_controller.freezed.dart';
part 'quick_add_controller.g.dart';

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

@freezed
abstract class QuickAddState with _$QuickAddState {
  const factory QuickAddState({
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

    /// Allegati scelti, copiati nella cartella dell'app solo al salvataggio.
    @Default(<PickedAttachment>[]) List<PickedAttachment> attachments,

    /// Diventa true al primo tentativo di salvataggio: da lì si mostrano gli errori.
    @Default(false) bool showErrors,
    @Default(false) bool saving,
  }) = _QuickAddState;

  const QuickAddState._();

  bool get isTransfer => type == TransactionType.transfer;

  /// Portafoglio scelto a mano per spese ed entrate (null = usa il predefinito).
  String? get chosenWalletId => type == TransactionType.income ? incomeWalletId : expenseWalletId;

  bool get isAmountMissing => amountCents <= 0;

  /// La categoria è obbligatoria per spese ed entrate, assente nei trasferimenti.
  bool get isCategoryMissing => !isTransfer && categoryId == null;

  bool get canAddAttachment => attachments.length < maxAttachments;
}

/// Stato dell'inserimento rapido. [initialType] arriva dalla rotta (`/add?type=`).
/// Si auto-elimina quando la schermata si chiude, così ogni apertura riparte da zero.
@riverpod
class QuickAddController extends _$QuickAddController {
  @override
  QuickAddState build(TransactionType initialType) {
    return QuickAddState(type: initialType, date: ref.read(todayProvider));
  }

  void setType(TransactionType type) {
    if (type == state.type) return;
    // Le categorie sono diverse per spese ed entrate: la scelta si azzera.
    state = state.copyWith(type: type, categoryId: null);
  }

  void pressKey(String key) => state = state.copyWith(amountCents: applyKeypadKey(state.amountCents, key));

  void clearAmount() => state = state.copyWith(amountCents: 0);

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

  /// Aggiunge un allegato. Restituisce false se si è già al massimo.
  bool addAttachment(PickedAttachment file) {
    if (!state.canAddAttachment) return false;
    state = state.copyWith(attachments: [...state.attachments, file]);
    return true;
  }

  void removeAttachment(PickedAttachment file) {
    state = state.copyWith(attachments: [...state.attachments]..remove(file));
  }

  void setNote(String note) => state = state.copyWith(note: note);

  /// Salva il movimento. [walletId] è il portafoglio (l'origine per i trasferimenti) e
  /// [toWalletId] la destinazione, già risolti dalla schermata.
  /// Restituisce il movimento salvato, oppure null se i dati non sono validi.
  ///
  /// I file degli allegati vengono copiati prima di scrivere nel database; se la scrittura
  /// fallisce le copie vengono eliminate e l'errore viene rilanciato.
  Future<Transaction?> save({required String? walletId, String? toWalletId}) async {
    if (state.saving) return null;
    final walletsInvalid = walletId == null || (state.isTransfer && (toWalletId == null || toWalletId == walletId));
    if (state.isAmountMissing || state.isCategoryMissing || walletsInvalid) {
      state = state.copyWith(showErrors: true);
      return null;
    }

    final note = state.note.trim();
    final transaction = Transaction(
      id: newId(),
      type: state.type,
      amountCents: state.amountCents,
      date: state.date,
      walletId: walletId,
      toWalletId: state.isTransfer ? toWalletId : null,
      // I trasferimenti non hanno categoria né label.
      categoryId: state.isTransfer ? null : state.categoryId,
      labelIds: state.isTransfer ? const [] : state.labelIds.toList(),
      note: note.isEmpty ? null : note,
    );

    state = state.copyWith(saving: true);
    final storage = ref.read(attachmentStorageProvider);
    final stored = <Attachment>[];
    try {
      for (final file in state.attachments) {
        stored.add(await storage.store(transaction.id, file));
      }
      await ref.read(transactionRepositoryProvider).save(transaction, attachments: stored);
      return transaction;
    } catch (_) {
      await storage.delete(stored);
      rethrow;
    } finally {
      if (ref.mounted) state = state.copyWith(saving: false);
    }
  }
}
