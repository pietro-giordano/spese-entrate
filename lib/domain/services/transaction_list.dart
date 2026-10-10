/// Filtri e raggruppamento della lista movimenti.
library;

import '../../core/dates.dart';
import '../models/enums.dart';
import '../models/transaction.dart';
import '../models/transaction_filters.dart';
import 'statistics.dart';

/// True se [tx] passa i [filters].
///
/// - Portafogli: conta il portafoglio del movimento e, per i trasferimenti, anche la destinazione.
/// - Spese ed entrate seguono il filtro per tipo.
/// - I trasferimenti dipendono dall'interruttore; le rettifiche compaiono solo con tipo "Tutti".
///   Entrambi non hanno categoria né label, quindi spariscono se quei filtri sono attivi.
bool matchesFilters(Transaction tx, TransactionFilters filters) {
  if (filters.walletIds.isNotEmpty &&
      !filters.walletIds.contains(tx.walletId) &&
      !(tx.toWalletId != null && filters.walletIds.contains(tx.toWalletId))) {
    return false;
  }

  final hasCategoryOrLabelFilter = filters.categoryIds.isNotEmpty || filters.labelIds.isNotEmpty;
  switch (tx.type) {
    case TransactionType.transfer:
      return filters.showTransfers && !hasCategoryOrLabelFilter;
    case TransactionType.adjustment:
      return filters.type == TypeFilter.all && !hasCategoryOrLabelFilter;
    case TransactionType.expense when filters.type == TypeFilter.income:
    case TransactionType.income when filters.type == TypeFilter.expense:
      return false;
    case TransactionType.expense:
    case TransactionType.income:
      break;
  }

  if (filters.categoryIds.isNotEmpty && !filters.categoryIds.contains(tx.categoryId)) return false;

  if (filters.labelIds.isNotEmpty) {
    final labels = tx.labelIds.toSet();
    return switch (filters.labelMatch) {
      LabelMatch.any => labels.any(filters.labelIds.contains),
      LabelMatch.all => labels.containsAll(filters.labelIds),
    };
  }
  return true;
}

/// Movimenti di una giornata con il loro totale (entrate − spese confermate).
class DayGroup {
  const DayGroup({required this.date, required this.transactions, required this.totalCents});

  final LocalDate date;
  final List<Transaction> transactions;
  final int totalCents;
}

/// Raggruppa per giorno, dal più recente, mantenendo l'ordine dei movimenti nella giornata.
/// Il totale segue le regole delle statistiche: trasferimenti e rettifiche non contano.
List<DayGroup> groupByDay(Iterable<Transaction> transactions) {
  final byDate = <LocalDate, List<Transaction>>{};
  for (final tx in transactions) {
    byDate.putIfAbsent(tx.date, () => []).add(tx);
  }
  final dates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final date in dates)
      DayGroup(
        date: date,
        transactions: byDate[date]!,
        totalCents: byDate[date]!
            .where(countsInStatistics)
            .fold(0, (sum, tx) => tx.type == TransactionType.income ? sum + tx.amountCents : sum - tx.amountCents),
      ),
  ];
}
