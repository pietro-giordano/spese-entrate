import 'package:flutter_test/flutter_test.dart';
import 'package:spese_entrate/core/dates.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/transaction.dart';
import 'package:spese_entrate/domain/models/transaction_filters.dart';
import 'package:spese_entrate/domain/services/comparison.dart';
import 'package:spese_entrate/domain/services/statistics.dart';
import 'package:spese_entrate/domain/services/transaction_list.dart';

import 'transaction_list_test.dart' show tx;

/// Filtri di Grafici e Confronta applicati ai calcoli (torte, totali, barre, linee).
void main() {
  final october = DateRange(LocalDate(2026, 10, 1), LocalDate(2026, 10, 31));
  final groceriesCc = tx(TransactionType.expense, cents: 5000, walletId: 'cc', categoryId: 'food', labelIds: ['home']);
  final groceriesCash = tx(TransactionType.expense, cents: 2000, walletId: 'cash', categoryId: 'food');
  final trip = tx(
    TransactionType.expense,
    cents: 30000,
    walletId: 'cc',
    categoryId: 'travel',
    labelIds: ['home', 'holiday'],
  );
  final salary = tx(TransactionType.income, cents: 200000, walletId: 'cc', categoryId: 'salary');
  final transfer = tx(TransactionType.transfer, cents: 10000, walletId: 'cc', toWalletId: 'cash');
  final pending = tx(
    TransactionType.expense,
    cents: 999,
    walletId: 'cc',
    categoryId: 'food',
    status: TransactionStatus.pending,
  );
  final all = [groceriesCc, groceriesCash, trip, salary, transfer, pending];

  List<String> ids(List<Transaction> list) => [for (final t in list) t.id];

  group('filterForAnalytics', () {
    test('senza filtri non toglie nulla', () {
      expect(filterForAnalytics(all, const TransactionFilters()), all);
    });

    test('portafoglio: spese ed entrate del portafoglio scelto', () {
      final result = filterForAnalytics(all, const TransactionFilters(walletIds: {'cash'}));
      expect(ids(result), containsAll([groceriesCash.id]));
      expect(result, isNot(contains(groceriesCc)));
      expect(summarize(result, october).expenseCents, 2000);
    });

    test('categorie e label (almeno una / tutte / senza label)', () {
      expect(ids(filterForAnalytics(all, const TransactionFilters(categoryIds: {'food'}))), [
        groceriesCc.id,
        groceriesCash.id,
        pending.id,
      ]);
      expect(ids(filterForAnalytics(all, const TransactionFilters(labelIds: {'home', 'holiday'}))), [
        groceriesCc.id,
        trip.id,
      ]);
      expect(
        ids(
          filterForAnalytics(all, const TransactionFilters(labelIds: {'home', 'holiday'}, labelMatch: LabelMatch.all)),
        ),
        [trip.id],
      );
      expect(
        filterForAnalytics(
          all,
          const TransactionFilters(withoutLabels: true),
        ).where((t) => t.type == TransactionType.expense),
        [groceriesCash, pending],
      );
    });

    test('tipo e "mostra trasferimenti" non contano: li sceglie il grafico', () {
      final ignored = filterForAnalytics(all, const TransactionFilters(type: TypeFilter.income, showTransfers: false));
      expect(ignored, all);
      expect(
        analyticsScope(const TransactionFilters(type: TypeFilter.expense, showTransfers: false)),
        const TransactionFilters(),
      );
    });
  });

  group('calcoli filtrati', () {
    const currentAccountSpending = TransactionFilters(walletIds: {'cc'}, categoryIds: {'food', 'travel'});

    test('torta per categoria e totale al centro', () {
      final filtered = filterForAnalytics(all, currentAccountSpending);
      final byCategory = breakdownByCategory(filtered, october, CategoryKind.expense);
      expect({for (final i in byCategory) i.id: i.totalCents}, {'travel': 30000, 'food': 5000});
      expect(summarize(filtered, october).expenseCents, 35000, reason: 'il pending non conta');
      expect(summarize(filtered, october).incomeCents, 0, reason: 'lo stipendio è fuori dalle categorie scelte');
    });

    test('torta per label con filtro su una label: un movimento conta in ogni sua label', () {
      final filtered = filterForAnalytics(all, const TransactionFilters(labelIds: {'holiday'}));
      final byLabel = breakdownByLabel(filtered, october, CategoryKind.expense);
      expect({for (final i in byLabel) i.id: i.totalCents}, {'home': 30000, 'holiday': 30000});
    });

    test('barre, linee e variazioni del confronto', () {
      final filtered = filterForAnalytics(all, const TransactionFilters(walletIds: {'cash'}));
      expect(metricTotal(filtered, october, CompareMetric.expense), 2000);
      expect(metricTotal(filtered, october, CompareMetric.balance), -2000);
      expect(cumulativeByDay(filtered, october, CompareMetric.expense).last, 2000);
      expect(metricTotal(all, october, CompareMetric.expense), 37000, reason: 'senza filtri');
    });
  });

  group('sliceFilters (tap su una fetta)', () {
    const chart = TransactionFilters(
      walletIds: {'cc'},
      categoryIds: {'food', 'travel'},
      labelIds: {'home'},
      labelMatch: LabelMatch.all,
    );

    test('categoria toccata: tipo, la categoria e il resto dei filtri del grafico', () {
      final filters = sliceFilters(chart, kind: CategoryKind.expense, byLabel: false, id: 'food');
      expect(filters.type, TypeFilter.expense);
      expect(filters.categoryIds, {'food'});
      expect(filters.walletIds, {'cc'});
      expect(filters.labelIds, {'home'});
      expect(filters.showTransfers, isTrue);
    });

    test('label toccata: tipo, la label (almeno una) e portafogli e categorie del grafico', () {
      final filters = sliceFilters(chart, kind: CategoryKind.income, byLabel: true, id: 'holiday');
      expect(filters.type, TypeFilter.income);
      expect(filters.labelIds, {'holiday'});
      expect(filters.labelMatch, LabelMatch.any);
      expect(filters.withoutLabels, isFalse);
      expect(filters.categoryIds, {'food', 'travel'});
    });

    test('"Senza label" toccata', () {
      final filters = sliceFilters(chart, kind: CategoryKind.expense, byLabel: true, id: null);
      expect(filters.labelIds, isEmpty);
      expect(filters.withoutLabels, isTrue);
    });

    test('i movimenti della lista sono quelli della fetta', () {
      const chartFilters = TransactionFilters(walletIds: {'cc'});
      final chartTx = filterForAnalytics(all, chartFilters);
      final slice = breakdownByCategory(chartTx, october, CategoryKind.expense).firstWhere((i) => i.id == 'food');
      final list = all.where(
        (t) =>
            t.isConfirmed &&
            matchesFilters(t, sliceFilters(chartFilters, kind: CategoryKind.expense, byLabel: false, id: 'food')),
      );
      expect(list.fold(0, (sum, t) => sum + t.amountCents), slice.totalCents);
    });
  });
}
