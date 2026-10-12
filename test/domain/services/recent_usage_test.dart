import 'package:flutter_test/flutter_test.dart';
import 'package:spese_entrate/core/dates.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/transaction.dart';
import 'package:spese_entrate/domain/services/recent_usage.dart';

void main() {
  final today = LocalDate(2026, 10, 10);
  var counter = 0;

  Transaction tx(
    String categoryId, {
    LocalDate? date,
    TransactionType type = TransactionType.expense,
    List<String> labels = const [],
    String? importBatchId,
    TransactionStatus status = TransactionStatus.confirmed,
  }) => Transaction(
    id: 't${counter++}',
    type: type,
    amountCents: 100,
    date: date ?? today,
    walletId: 'w',
    categoryId: categoryId,
    labelIds: labels,
    importBatchId: importBatchId,
    status: status,
  );

  group('utilizzi recenti', () {
    test('finestra di 90 giorni fino a oggi: il 90° giorno indietro conta, il 91° e il futuro no', () {
      final usage = recentUsage(
        [
          tx('a'),
          tx('a', date: today.addDays(-89)),
          tx('b', date: today.addDays(-90)),
          tx('c', date: today.addDays(1)),
        ],
        type: TransactionType.expense,
        today: today,
      );
      expect(usage.categories, {'a': 2});
    });

    test('lo storico importato e i movimenti da confermare non contano', () {
      final usage = recentUsage(
        [
          tx('a'),
          tx('b', importBatchId: 'import-1'),
          tx('b', importBatchId: 'import-1'),
          tx('c', status: TransactionStatus.pending),
        ],
        type: TransactionType.expense,
        today: today,
      );
      expect(usage.categories, {'a': 1});
    });

    test('spese ed entrate separate, anche per le label (una volta per movimento)', () {
      final txs = [
        tx('spesa', labels: ['casa', 'casa', 'auto']),
        tx('stipendio', type: TransactionType.income, labels: ['lavoro']),
      ];
      final expenses = recentUsage(txs, type: TransactionType.expense, today: today);
      final incomes = recentUsage(txs, type: TransactionType.income, today: today);
      expect(expenses.categories, {'spesa': 1});
      expect(expenses.labels, {'casa': 1, 'auto': 1});
      expect(incomes.categories, {'stipendio': 1});
      expect(incomes.labels, {'lavoro': 1});
    });
  });

  group('ordine della vista ridotta', () {
    const ids = ['a', 'b', 'c', 'd', 'e'];

    test('per utilizzi; a parità o senza dati, sort_order', () {
      expect(compactOrder(ids, usage: {'d': 3, 'b': 1, 'e': 1}, selected: {}), ['d', 'b', 'e', 'a', 'c']);
      expect(compactOrder(ids, usage: {}, selected: {}), ids);
    });

    test('le selezionate in testa, nel loro sort_order', () {
      expect(compactOrder(ids, usage: {'d': 3}, selected: {'e', 'c'}), ['c', 'e', 'd', 'a', 'b']);
    });

    test('vista ridotta: le prime N, più le selezionate oltre il limite; le nuove in fondo', () {
      final order = compactOrder(ids, usage: {'e': 2, 'd': 1}, selected: {});
      expect(compactVisible(order, ids: ids, selected: {}, limit: 3), ['e', 'd', 'a']);
      expect(compactVisible(order, ids: ids, selected: {'c'}, limit: 3), ['e', 'd', 'a', 'c']);
      // Una voce creata dopo (f) va in fondo; una eliminata (a) sparisce.
      expect(compactVisible(order, ids: ['b', 'c', 'd', 'e', 'f'], selected: {}, limit: 10), ['e', 'd', 'b', 'c', 'f']);
    });
  });
}
