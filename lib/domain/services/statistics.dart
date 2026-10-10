/// Statistiche: riepiloghi e dati dei grafici.
///
/// Contano solo `expense` e `income` confermati: trasferimenti, rettifiche e
/// movimenti `pending` non sono mai spese o entrate.
library;

import '../../core/dates.dart';
import '../models/enums.dart';
import '../models/statistics.dart';
import '../models/transaction.dart';

/// True se [tx] entra nelle statistiche.
bool countsInStatistics(Transaction tx) =>
    tx.isConfirmed && (tx.type == TransactionType.expense || tx.type == TransactionType.income);

TransactionType _typeFor(CategoryKind kind) =>
    kind == CategoryKind.expense ? TransactionType.expense : TransactionType.income;

Iterable<Transaction> _counted(Iterable<Transaction> transactions, DateRange range) =>
    transactions.where((tx) => countsInStatistics(tx) && range.contains(tx.date));

/// Entrate e uscite dei movimenti con data in [range].
PeriodSummary summarize(Iterable<Transaction> transactions, DateRange range) {
  var income = 0;
  var expense = 0;
  for (final tx in _counted(transactions, range)) {
    if (tx.type == TransactionType.income) {
      income += tx.amountCents;
    } else {
      expense += tx.amountCents;
    }
  }
  return PeriodSummary(incomeCents: income, expenseCents: expense);
}

/// Totali per categoria delle spese o delle entrate ([kind]) in [range],
/// dal più grande al più piccolo.
List<BreakdownItem> breakdownByCategory(Iterable<Transaction> transactions, DateRange range, CategoryKind kind) {
  final type = _typeFor(kind);
  final totals = <String?, int>{};
  for (final tx in _counted(transactions, range)) {
    if (tx.type != type) continue;
    totals[tx.categoryId] = (totals[tx.categoryId] ?? 0) + tx.amountCents;
  }
  return _toItems(totals);
}

/// Totali per label. Un movimento con più label conta in ciascuna; quelli senza label
/// finiscono nella voce con `id == null` ("Senza label"). Le quote sono sulla somma delle voci.
List<BreakdownItem> breakdownByLabel(Iterable<Transaction> transactions, DateRange range, CategoryKind kind) {
  final type = _typeFor(kind);
  final totals = <String?, int>{};
  for (final tx in _counted(transactions, range)) {
    if (tx.type != type) continue;
    final Iterable<String?> labels = tx.labelIds.isEmpty ? const [null] : tx.labelIds.toSet();
    for (final labelId in labels) {
      totals[labelId] = (totals[labelId] ?? 0) + tx.amountCents;
    }
  }
  return _toItems(totals);
}

List<BreakdownItem> _toItems(Map<String?, int> totals) {
  final sum = totals.values.fold(0, (a, b) => a + b);
  final items = [
    for (final MapEntry(key: id, value: total) in totals.entries)
      BreakdownItem(id: id, totalCents: total, share: sum == 0 ? 0 : total / sum),
  ];
  items.sort((a, b) => b.totalCents.compareTo(a.totalCents));
  return items;
}
