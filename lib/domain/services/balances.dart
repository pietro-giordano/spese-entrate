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

/// Ultimo aggiornamento: data dell'ultima rettifica confermata, altrimenti la data del saldo iniziale.
LocalDate lastUpdate(Wallet wallet, Iterable<Transaction> transactions) {
  var latest = wallet.initialBalanceDate;
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

/// True se l'ultimo aggiornamento è più vecchio di [staleAfterDays] giorni rispetto a [today].
bool needsUpdate(Wallet wallet, Iterable<Transaction> transactions, LocalDate today) {
  return lastUpdate(wallet, transactions).daysUntil(today) > staleAfterDays;
}
