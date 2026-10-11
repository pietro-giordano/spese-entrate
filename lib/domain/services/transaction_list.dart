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
///   Entrambi non hanno categoria né label, quindi spariscono se quei filtri sono attivi
///   (anche con "Senza label": per loro le label non si applicano).
bool matchesFilters(Transaction tx, TransactionFilters filters) {
  if (filters.walletIds.isNotEmpty &&
      !filters.walletIds.contains(tx.walletId) &&
      !(tx.toWalletId != null && filters.walletIds.contains(tx.toWalletId))) {
    return false;
  }

  final hasCategoryOrLabelFilter = filters.categoryIds.isNotEmpty || filters.hasLabelFilter;
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

  if (filters.hasLabelFilter) return matchesLabelFilter(tx.labelIds.toSet(), filters);
  return true;
}

/// Filtri di Grafici e Confronta: contano solo portafogli, categorie e label (con «almeno una» o
/// «tutte»). Tipo e trasferimenti si ignorano: le statistiche contano già solo spese ed entrate
/// confermate, e il tipo lo sceglie il grafico (Spese/Entrate).
TransactionFilters analyticsScope(TransactionFilters filters) =>
    filters.copyWith(type: TypeFilter.all, showTransfers: true);

/// Movimenti che passano i filtri di Grafici e Confronta (vedi [analyticsScope]).
/// Si applica prima di ogni calcolo: torte, barre, linee cumulate e tabella delle variazioni.
List<Transaction> filterForAnalytics(Iterable<Transaction> transactions, TransactionFilters filters) {
  final scoped = analyticsScope(filters);
  return [
    for (final tx in transactions)
      if (matchesFilters(tx, scoped)) tx,
  ];
}

/// Filtri della lista Movimenti per una fetta toccata in Grafici: tipo del grafico ([kind]),
/// voce toccata ([id] è una categoria o, con [byLabel], una label; null = "Senza label") e i
/// filtri del grafico ([chart]). La voce sostituisce i filtri della sua stessa dimensione:
/// con una categoria toccata restano portafogli e label del grafico, con una label restano
/// portafogli e categorie.
TransactionFilters sliceFilters(
  TransactionFilters chart, {
  required CategoryKind kind,
  required bool byLabel,
  required String? id,
}) {
  final base = analyticsScope(chart)
      .copyWith(type: kind == CategoryKind.expense ? TypeFilter.expense : TypeFilter.income);
  return byLabel
      ? base.copyWith(labelIds: {?id}, withoutLabels: id == null, labelMatch: LabelMatch.any)
      : base.copyWith(categoryIds: {?id});
}

/// Condizione sulle label di un movimento.
///
/// - "Almeno una": il movimento ha una delle label scelte, oppure non ne ha nessuna se è
///   selezionato "Senza label".
/// - "Tutte": il movimento ha tutte le label scelte. "Senza label" da solo vuol dire nessuna label;
///   insieme ad altre label nessun movimento può soddisfarlo (la schermata Filtri lo evita).
bool matchesLabelFilter(Set<String> labels, TransactionFilters filters) {
  final selected = filters.labelIds;
  return switch (filters.labelMatch) {
    LabelMatch.any => labels.any(selected.contains) || (filters.withoutLabels && labels.isEmpty),
    LabelMatch.all when filters.withoutLabels => selected.isEmpty && labels.isEmpty,
    LabelMatch.all => labels.containsAll(selected),
  };
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
