import 'package:flutter_test/flutter_test.dart';
import 'package:spese_entrate/core/dates.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/statistics.dart';
import 'package:spese_entrate/domain/models/transaction.dart';
import 'package:spese_entrate/domain/services/statistics.dart';

final october = Period.containing(PeriodType.month, LocalDate(2026, 10, 1)).range;

var _seq = 0;

Transaction tx(
  TransactionType type,
  int amountCents, {
  String? categoryId,
  List<String> labelIds = const [],
  TransactionStatus status = TransactionStatus.confirmed,
  LocalDate? date,
}) {
  return Transaction(
    id: 't${_seq++}',
    type: type,
    status: status,
    amountCents: amountCents,
    date: date ?? LocalDate(2026, 10, 15),
    walletId: 'cc',
    toWalletId: type == TransactionType.transfer ? 'cash' : null,
    categoryId: categoryId,
    labelIds: labelIds,
  );
}

final transactions = [
  tx(TransactionType.income, 200000, categoryId: 'salary'),
  tx(TransactionType.expense, 30000, categoryId: 'groceries', labelIds: ['home']),
  tx(TransactionType.expense, 10000, categoryId: 'restaurants', labelIds: ['home', 'holiday']),
  tx(TransactionType.expense, 5000, categoryId: 'other'),
  // Mai nelle statistiche:
  tx(TransactionType.expense, 99900, categoryId: 'groceries', status: TransactionStatus.pending),
  tx(TransactionType.income, 10000, categoryId: 'salary', status: TransactionStatus.pending),
  tx(TransactionType.transfer, 50000),
  tx(TransactionType.adjustment, -20000),
  tx(TransactionType.adjustment, 100000),
  // Fuori dal periodo:
  tx(TransactionType.expense, 70000, categoryId: 'groceries', date: LocalDate(2026, 9, 30)),
  tx(TransactionType.income, 70000, categoryId: 'salary', date: LocalDate(2026, 11, 1)),
];

void main() {
  test('countsInStatistics: solo spese ed entrate confermate', () {
    expect(countsInStatistics(tx(TransactionType.expense, 1, categoryId: 'c')), isTrue);
    expect(countsInStatistics(tx(TransactionType.income, 1, categoryId: 'c')), isTrue);
    expect(countsInStatistics(tx(TransactionType.transfer, 1)), isFalse);
    expect(countsInStatistics(tx(TransactionType.adjustment, -1)), isFalse);
    expect(
      countsInStatistics(tx(TransactionType.expense, 1, categoryId: 'c', status: TransactionStatus.pending)),
      isFalse,
    );
  });

  group('summarize', () {
    test('esclude trasferimenti, rettifiche, pending e movimenti fuori periodo', () {
      final summary = summarize(transactions, october);
      expect(summary, const PeriodSummary(incomeCents: 200000, expenseCents: 45000));
      expect(summary.balanceCents, 155000);
      expect(summary.spentRatio, closeTo(0.225, 1e-9));
    });

    test('periodo vuoto', () {
      final summary = summarize(const [], october);
      expect(summary.balanceCents, 0);
      expect(summary.spentRatio, isNull);
    });
  });

  group('breakdownByCategory', () {
    test('spese per categoria, dalla più grande', () {
      expect(breakdownByCategory(transactions, october, CategoryKind.expense), const [
        BreakdownItem(id: 'groceries', totalCents: 30000, share: 30000 / 45000),
        BreakdownItem(id: 'restaurants', totalCents: 10000, share: 10000 / 45000),
        BreakdownItem(id: 'other', totalCents: 5000, share: 5000 / 45000),
      ]);
    });

    test('entrate per categoria', () {
      expect(breakdownByCategory(transactions, october, CategoryKind.income), const [
        BreakdownItem(id: 'salary', totalCents: 200000, share: 1),
      ]);
    });
  });

  group('breakdownByLabel', () {
    test('un movimento con più label conta in ciascuna; senza label → id null', () {
      // home: 300 + 100, holiday: 100, senza label: 50 → somma 550
      expect(breakdownByLabel(transactions, october, CategoryKind.expense), const [
        BreakdownItem(id: 'home', totalCents: 40000, share: 40000 / 55000),
        BreakdownItem(id: 'holiday', totalCents: 10000, share: 10000 / 55000),
        BreakdownItem(id: null, totalCents: 5000, share: 5000 / 55000),
      ]);
    });

    test('le quote sommano a 1', () {
      final items = breakdownByLabel(transactions, october, CategoryKind.expense);
      expect(items.fold<double>(0, (sum, item) => sum + item.share), closeTo(1, 1e-9));
    });

    test('una label ripetuta nello stesso movimento conta una volta', () {
      final items = breakdownByLabel(
        [
          tx(TransactionType.expense, 1000, categoryId: 'c', labelIds: ['home', 'home']),
        ],
        october,
        CategoryKind.expense,
      );
      expect(items, const [BreakdownItem(id: 'home', totalCents: 1000, share: 1)]);
    });
  });
}
