import 'package:flutter_test/flutter_test.dart';
import 'package:spese_entrate/core/dates.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/transaction.dart';
import 'package:spese_entrate/domain/models/transaction_filters.dart';
import 'package:spese_entrate/domain/services/transaction_search.dart';

void main() {
  const names = SearchNames(
    wallets: {'cc': 'Conto corrente', 'cash': 'Contanti'},
    categories: {'food': 'Spesa alimentare', 'bar': 'Caffè e bar', 'salary': 'Stipendio'},
    labels: {'home': 'casa', 'trip': 'Vacanze in Perù'},
  );

  Transaction tx(
    String id, {
    TransactionType type = TransactionType.expense,
    int cents = 1000,
    String wallet = 'cc',
    String? toWallet,
    String? category = 'food',
    List<String> labels = const [],
    String? note,
    TransactionStatus status = TransactionStatus.confirmed,
    LocalDate? date,
  }) => Transaction(
    id: id,
    type: type,
    status: status,
    amountCents: cents,
    date: date ?? LocalDate(2026, 10, 3),
    walletId: wallet,
    toWalletId: toWallet,
    categoryId: type == TransactionType.transfer ? null : category,
    labelIds: labels,
    note: note,
  );

  final all = [
    tx('esselunga', cents: 6420, note: 'Esselunga di via Roma', labels: ['home']),
    tx('caffe', cents: 150, category: 'bar', wallet: 'cash', note: 'Caffè al bar'),
    tx('stipendio', type: TransactionType.income, cents: 240000, category: 'salary'),
    tx('cusco', cents: 6400, labels: ['trip'], note: 'Ostello'),
    tx('prelievo', type: TransactionType.transfer, cents: 5000, toWallet: 'cash', note: 'Prelievo'),
    tx('rettifica', type: TransactionType.adjustment, cents: -6420, category: null),
    tx('pending', cents: 6420, status: TransactionStatus.pending, note: 'Esselunga futura'),
  ];

  List<String> search(String text, {TransactionFilters filters = const TransactionFilters()}) => [
    for (final t in searchTransactions(all, SearchQuery(text), names: names, filters: filters)) t.id,
  ];

  group('testo', () {
    test('nella nota, senza distinzione di maiuscole', () {
      expect(search('ESSELUNGA'), ['esselunga']);
      expect(search('roma'), ['esselunga']);
    });

    test('senza distinzione di accenti, in entrambi i versi', () {
      expect(search('caffe'), ['caffe']);
      expect(search('CAFFÈ'), ['caffe']);
      expect(search('peru'), ['cusco']);
      expect(foldForSearch('Àèìòù Ç Ñ'), 'aeiou c n');
    });

    test('nel nome della categoria, delle label e dei portafogli (anche la destinazione)', () {
      expect(search('alimentare'), ['esselunga', 'cusco']);
      expect(search('stipendio'), ['stipendio']);
      expect(search('casa'), ['esselunga']);
      expect(search('vacanze'), ['cusco']);
      expect(search('contanti'), ['caffe', 'prelievo']);
    });

    test('più parole: devono esserci tutte, in campi anche diversi', () {
      expect(search('esselunga casa'), ['esselunga']);
      expect(search('esselunga vacanze'), isEmpty);
      expect(search('  ostello   peru  '), ['cusco']);
    });

    test('ricerca vuota: nessun risultato', () {
      expect(search(''), isEmpty);
      expect(search('   '), isEmpty);
      expect(SearchQuery('  ').isEmpty, isTrue);
    });
  });

  group('importo', () {
    test('"64,20" o "64.20": importo esatto (anche la rettifica negativa)', () {
      expect(search('64,20'), ['esselunga', 'rettifica']);
      expect(search('64.20'), ['esselunga', 'rettifica']);
      expect(search('64,2'), ['esselunga', 'rettifica']);
    });

    test('"64": gli importi da 64,00 a 64,99', () {
      expect(search('64'), ['esselunga', 'cusco', 'rettifica']);
      expect(search('2.400'), ['stipendio']);
      expect(search('2400'), ['stipendio']);
    });

    test('importo e parola insieme', () {
      expect(search('64 ostello'), ['cusco']);
      expect(search('1,50 caffe'), ['caffe']);
    });
  });

  group('regole della lista', () {
    test('tutto lo storico: anche movimenti di anni passati', () {
      final old = [...all, tx('vecchio', note: 'Esselunga 2019', date: LocalDate(2019, 1, 5))];
      final ids = searchTransactions(old, SearchQuery('esselunga'), names: names).map((t) => t.id);
      expect(ids, ['esselunga', 'vecchio']);
    });

    test('i pending non compaiono (sono in "In arrivo")', () {
      expect(search('futura'), isEmpty);
    });

    test('con i filtri attivi applicati', () {
      expect(search('64', filters: const TransactionFilters(type: TypeFilter.income)), isEmpty);
      expect(search('contanti', filters: const TransactionFilters(showTransfers: false)), ['caffe']);
      expect(search('alimentare', filters: const TransactionFilters(labelIds: {'trip'})), ['cusco']);
    });
  });

  test('10.000 movimenti: una ricerca resta veloce senza indice FTS', () {
    final many = [
      for (var i = 0; i < 10000; i++)
        tx(
          't$i',
          cents: 100 + i,
          category: i.isEven ? 'food' : 'bar',
          labels: i % 3 == 0 ? const ['home'] : const [],
          note: i % 1000 == 0 ? 'Farmacia centrale $i' : 'Movimento numero $i',
        ),
    ];
    final watch = Stopwatch()..start();
    final results = searchTransactions(many, SearchQuery('farmacìa'), names: names);
    final byAmount = searchTransactions(many, SearchQuery('64,20'), names: names);
    final twoWords = searchTransactions(many, SearchQuery('caffe casa'), names: names);
    watch.stop();
    expect(results, hasLength(10));
    expect(byAmount.single.amountCents, 6420);
    expect(twoWords, hasLength(1667));
    expect(watch.elapsedMilliseconds, lessThan(500), reason: '3 ricerche in ${watch.elapsedMilliseconds} ms');
  });
}
