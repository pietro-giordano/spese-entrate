/// Ordine "più usate" di categorie e label nei form dei movimenti: logica pura.
library;

import '../../core/dates.dart';
import '../models/enums.dart';
import '../models/transaction.dart';

/// Quanto indietro si guarda per contare gli utilizzi.
const recentUsageDays = 90;

/// Utilizzi recenti di categorie e label, per un tipo di movimento (spese o entrate).
class RecentUsage {
  const RecentUsage({this.categories = const {}, this.labels = const {}});

  final Map<String, int> categories;
  final Map<String, int> labels;
}

/// Conta categorie e label dei movimenti di tipo [type] (spesa o entrata) con data negli ultimi
/// [recentUsageDays] giorni fino a [today] compreso. Contano solo i movimenti confermati inseriti
/// dall'utente: quelli importati (`importBatchId`) e quelli ancora da confermare no.
RecentUsage recentUsage(Iterable<Transaction> transactions, {required TransactionType type, required LocalDate today}) {
  final from = today.addDays(-(recentUsageDays - 1));
  final categories = <String, int>{};
  final labels = <String, int>{};
  for (final tx in transactions) {
    if (tx.type != type || !tx.isConfirmed || tx.importBatchId != null) continue;
    if (tx.date.isBefore(from) || tx.date.isAfter(today)) continue;
    if (tx.categoryId case final id?) categories[id] = (categories[id] ?? 0) + 1;
    for (final id in tx.labelIds.toSet()) {
      labels[id] = (labels[id] ?? 0) + 1;
    }
  }
  return RecentUsage(categories: categories, labels: labels);
}

/// Ordine della vista ridotta: prima le [selected] (nell'ordine di [ids]), poi le altre per
/// utilizzi decrescenti; a parità, o senza utilizzi, nell'ordine di [ids] (sort_order).
List<String> compactOrder(List<String> ids, {required Map<String, int> usage, required Set<String> selected}) {
  final position = {for (final (i, id) in ids.indexed) id: i};
  final chosen = [
    for (final id in ids)
      if (selected.contains(id)) id,
  ];
  final others =
      [
        for (final id in ids)
          if (!selected.contains(id)) id,
      ]..sort((a, b) {
        final byUsage = (usage[b] ?? 0).compareTo(usage[a] ?? 0);
        return byUsage != 0 ? byUsage : position[a]!.compareTo(position[b]!);
      });
  return [...chosen, ...others];
}

/// Voci della vista ridotta: le prime [limit] di [order], più le selezionate che fossero oltre
/// (le selezionate non si nascondono mai). [order] viene da [compactOrder] e resta fisso finché
/// la schermata è aperta; voci nuove (es. una categoria appena creata) vanno in fondo.
List<String> compactVisible(
  List<String> order, {
  required List<String> ids,
  required Set<String> selected,
  required int limit,
}) {
  final existing = ids.toSet();
  final ordered = [
    for (final id in order)
      if (existing.contains(id)) id,
    for (final id in ids)
      if (!order.contains(id)) id,
  ];
  final visible = ordered.take(limit).toList();
  for (final id in ordered.skip(limit)) {
    if (selected.contains(id)) visible.add(id);
  }
  return visible;
}
