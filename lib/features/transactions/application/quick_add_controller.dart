import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/clock.dart';
import '../../../core/dates.dart';
import '../../../core/ids.dart';
import '../../../data/repositories/repository_providers.dart';
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
    @Default('') String note,

    /// Diventa true al primo tentativo di salvataggio: da lì si mostrano gli errori.
    @Default(false) bool showErrors,
    @Default(false) bool saving,
  }) = _QuickAddState;

  const QuickAddState._();

  String? get chosenWalletId => type == TransactionType.income ? incomeWalletId : expenseWalletId;

  bool get isAmountMissing => amountCents <= 0;
  bool get isCategoryMissing => categoryId == null;
  bool get isValid => !isAmountMissing && !isCategoryMissing;
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

  void setNote(String note) => state = state.copyWith(note: note);

  /// Salva nel portafoglio [walletId] (già risolto dalla schermata con [resolveWalletId]).
  /// Restituisce il movimento salvato, oppure null se i dati non sono validi.
  Future<Transaction?> save({required String walletId}) async {
    if (state.saving) return null;
    if (!state.isValid) {
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
      categoryId: state.categoryId,
      note: note.isEmpty ? null : note,
      labelIds: state.labelIds.toList(),
    );

    state = state.copyWith(saving: true);
    try {
      await ref.read(transactionRepositoryProvider).save(transaction);
      return transaction;
    } finally {
      if (ref.mounted) state = state.copyWith(saving: false);
    }
  }
}
