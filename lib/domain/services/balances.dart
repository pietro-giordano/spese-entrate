/// Saldi dei portafogli, calcolati sempre dalle righe (mai salvati).
///
/// Le funzioni ricevono movimenti già privati dei cancellati (lo fanno i repository).
library;

import '../../core/dates.dart';
import '../models/enums.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';

/// Giorni oltre i quali un portafoglio mostra il badge "Da aggiornare".
const staleAfterDays = 30;

/// Effetto di un movimento sul saldo di [walletId], in centesimi con segno.
/// I movimenti `pending` non contano.
int balanceEffect(Transaction tx, String walletId) {
  if (!tx.isConfirmed) return 0;

  return switch (tx.type) {
    TransactionType.income when tx.walletId == walletId => tx.amountCents,
    TransactionType.expense when tx.walletId == walletId => -tx.amountCents,
    TransactionType.adjustment when tx.walletId == walletId => tx.amountCents,
    TransactionType.transfer when tx.walletId == walletId => -tx.amountCents,
    TransactionType.transfer when tx.toWalletId == walletId => tx.amountCents,
    _ => 0,
  };
}

/// Saldo di [wallet]: saldo iniziale + entrate − spese − trasferimenti in uscita
/// + trasferimenti in entrata + rettifiche. Con [upTo] considera solo i movimenti
/// fino a quella data inclusa.
int walletBalance(Wallet wallet, Iterable<Transaction> transactions, {LocalDate? upTo}) {
  var balance = wallet.initialBalanceCents;
  for (final tx in transactions) {
    if (upTo != null && tx.date.isAfter(upTo)) continue;
    balance += balanceEffect(tx, wallet.id);
  }
  return balance;
}

/// Saldi di tutti i [wallets], indicizzati per ID, in un solo passaggio sui movimenti.
Map<String, int> walletBalances(Iterable<Wallet> wallets, Iterable<Transaction> transactions) {
  final balances = {for (final wallet in wallets) wallet.id: wallet.initialBalanceCents};
  for (final tx in transactions) {
    if (balances.containsKey(tx.walletId)) {
      balances[tx.walletId] = balances[tx.walletId]! + balanceEffect(tx, tx.walletId);
    }
    final to = tx.toWalletId;
    if (to != null && to != tx.walletId && balances.containsKey(to)) {
      balances[to] = balances[to]! + balanceEffect(tx, to);
    }
  }
  return balances;
}

/// Patrimonio totale: somma dei saldi dei portafogli inclusi nel totale e non archiviati.
int netWorth(Iterable<Wallet> wallets, Map<String, int> balances) {
  var total = 0;
  for (final wallet in wallets) {
    if (wallet.includeInTotal && !wallet.isArchived) {
      total += balances[wallet.id] ?? 0;
    }
  }
  return total;
}

/// Ultimo aggiornamento: la data più recente tra saldo iniziale, ultima verifica con
/// "Aggiorna saldo" ([Wallet.lastBalanceVerifiedDate]) e ultima rettifica confermata.
///
/// La verifica è separata dal movimento: conta anche quando la differenza era zero
/// o è stata registrata come entrata/spesa. Una rettifica resta comunque una verifica.
LocalDate lastUpdate(Wallet wallet, Iterable<Transaction> transactions) {
  var latest = wallet.initialBalanceDate;
  final verified = wallet.lastBalanceVerifiedDate;
  if (verified != null && verified.isAfter(latest)) latest = verified;
  for (final tx in transactions) {
    if (tx.type == TransactionType.adjustment &&
        tx.isConfirmed &&
        tx.walletId == wallet.id &&
        tx.date.isAfter(latest)) {
      latest = tx.date;
    }
  }
  return latest;
}

/// Il portafoglio con la verifica del saldo registrata a [date]. Non torna mai indietro:
/// verificare una data passata non cancella una verifica più recente.
Wallet markBalanceVerified(Wallet wallet, LocalDate date) {
  final current = wallet.lastBalanceVerifiedDate;
  if (current != null && !date.isAfter(current)) return wallet;
  return wallet.copyWith(lastBalanceVerifiedDate: date);
}

/// True se l'ultimo aggiornamento è più vecchio di [staleAfterDays] giorni rispetto a [today].
bool needsUpdate(Wallet wallet, Iterable<Transaction> transactions, LocalDate today) {
  return lastUpdate(wallet, transactions).daysUntil(today) > staleAfterDays;
}

/// Saldo a fine mese per gli ultimi [months] mesi, dal più vecchio; l'ultimo punto è il saldo
/// di [today] (mese in corso).
///
/// Ogni punto conta solo i movimenti con data fino a quel giorno: una rettifica di oggi non tocca
/// i mesi precedenti, un movimento retrodatato sposta i saldi dal suo mese in poi.
/// I mesi chiusi prima della data del saldo iniziale non ci sono (il portafoglio non esisteva).
List<({LocalDate date, int balanceCents})> monthlyBalances(
  Wallet wallet,
  Iterable<Transaction> transactions,
  LocalDate today, {
  int months = 6,
}) {
  final currentMonth = LocalDate(today.year, today.month, 1);
  final points = <({LocalDate date, int balanceCents})>[];
  for (var i = months - 1; i >= 0; i--) {
    final month = currentMonth.addMonths(-i);
    final end = i == 0 ? today : LocalDate(month.year, month.month, LocalDate.daysInMonth(month.year, month.month));
    if (end.isBefore(wallet.initialBalanceDate)) continue;
    points.add((date: end, balanceCents: walletBalance(wallet, transactions, upTo: end)));
  }
  return points;
}

/// Come registrare la differenza in "Aggiorna saldo".
enum BalanceUpdateMode {
  /// Rettifica di valore: cambia il saldo ma non conta come entrata o spesa.
  adjustment,

  /// Entrata (differenza positiva) o spesa (negativa) con categoria: conta nelle statistiche.
  movement,
}

/// Movimento che porta il saldo di [wallet] a [newBalanceCents] alla data [date],
/// oppure null se il saldo a quella data coincide già (non serve nessun movimento).
///
/// La differenza si calcola sul saldo a quella data. In modalità [BalanceUpdateMode.movement]
/// serve [categoryId] (di entrata o di spesa secondo il segno della differenza).
Transaction? balanceUpdateTransaction({
  required String id,
  required Wallet wallet,
  required Iterable<Transaction> transactions,
  required int newBalanceCents,
  required LocalDate date,
  required BalanceUpdateMode mode,
  String? categoryId,
}) {
  final difference = newBalanceCents - walletBalance(wallet, transactions, upTo: date);
  if (difference == 0) return null;
  if (mode == BalanceUpdateMode.adjustment) {
    return Transaction(
      id: id,
      type: TransactionType.adjustment,
      amountCents: difference,
      currency: wallet.currency,
      date: date,
      walletId: wallet.id,
    );
  }
  if (categoryId == null) {
    throw ArgumentError.notNull('categoryId');
  }
  return Transaction(
    id: id,
    type: difference > 0 ? TransactionType.income : TransactionType.expense,
    amountCents: difference.abs(),
    currency: wallet.currency,
    date: date,
    walletId: wallet.id,
    categoryId: categoryId,
    note: 'Aggiornamento saldo',
  );
}
