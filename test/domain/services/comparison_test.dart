import 'package:flutter_test/flutter_test.dart';
import 'package:spese_entrate/core/dates.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/transaction.dart';
import 'package:spese_entrate/domain/services/comparison.dart';

var _seq = 0;

Transaction tx(
  TransactionType type,
  int cents,
  LocalDate date, {
  TransactionStatus status = TransactionStatus.confirmed,
}) => Transaction(
  id: 't${_seq++}',
  type: type,
  status: status,
  amountCents: cents,
  date: date,
  walletId: 'cc',
  toWalletId: type == TransactionType.transfer ? 'cash' : null,
  categoryId: type == TransactionType.expense || type == TransactionType.income ? 'c' : null,
);

void main() {
  final today = LocalDate(2026, 10, 3);
  final october = Period.containing(PeriodType.month, today).range;

  group('presetPeriods', () {
    test('ultimi 3 mesi, mese vs anno precedente, anno vs anno', () {
      expect(presetPeriods(ComparePreset.lastThreeMonths, today).map((p) => p.start), [
        LocalDate(2026, 10, 1),
        LocalDate(2026, 9, 1),
        LocalDate(2026, 8, 1),
      ]);
      expect(presetPeriods(ComparePreset.monthVsLastYear, today).map((p) => p.range), [
        october,
        DateRange(LocalDate(2025, 10, 1), LocalDate(2025, 10, 31)),
      ]);
      expect(presetPeriods(ComparePreset.yearVsYear, today).map((p) => p.start.year), [2026, 2025]);
      expect(presetPeriods(ComparePreset.custom, today), isEmpty);
    });
  });

  group('metricValue', () {
    test('trasferimenti, rettifiche e pending non contano mai', () {
      for (final metric in CompareMetric.values) {
        expect(metricValue(tx(TransactionType.transfer, 500, today), metric), 0);
        expect(metricValue(tx(TransactionType.adjustment, 500, today), metric), 0);
        expect(metricValue(tx(TransactionType.expense, 500, today, status: TransactionStatus.pending), metric), 0);
      }
    });

    test('spese positive, saldo con segno', () {
      final expense = tx(TransactionType.expense, 500, today);
      final income = tx(TransactionType.income, 800, today);
      expect((metricValue(expense, CompareMetric.expense), metricValue(income, CompareMetric.expense)), (500, 0));
      expect((metricValue(expense, CompareMetric.income), metricValue(income, CompareMetric.income)), (0, 800));
      expect((metricValue(expense, CompareMetric.balance), metricValue(income, CompareMetric.balance)), (-500, 800));
    });
  });

  group('cumulativeByDay', () {
    test('un valore per giorno, sommato fino a quel giorno', () {
      final series = cumulativeByDay(
        [
          tx(TransactionType.expense, 1000, LocalDate(2026, 10, 1)),
          tx(TransactionType.expense, 500, LocalDate(2026, 10, 3)),
          tx(TransactionType.expense, 200, LocalDate(2026, 10, 3)),
          tx(TransactionType.transfer, 99900, LocalDate(2026, 10, 2)),
          tx(TransactionType.expense, 7000, LocalDate(2026, 9, 30)),
        ],
        october,
        CompareMetric.expense,
      );

      expect(series, hasLength(31));
      expect(series.take(4), [1000, 1000, 1700, 1700]);
      expect(series.last, 1700);
    });

    test('il saldo cumulato può scendere sotto zero', () {
      final series = cumulativeByDay(
        [
          tx(TransactionType.expense, 1000, LocalDate(2026, 10, 1)),
          tx(TransactionType.income, 3000, LocalDate(2026, 10, 2)),
        ],
        october,
        CompareMetric.balance,
      );
      expect(series.take(3), [-1000, 2000, 2000]);
    });
  });

  group('percentChange', () {
    test('variazione rispetto al riferimento', () {
      expect(percentChange(1458, 1703), closeTo(-0.1439, 0.0001));
      expect(percentChange(1100, 1000), closeTo(0.1, 1e-9));
      expect(percentChange(500, 0), isNull, reason: 'riferimento zero');
    });

    test('con riferimento negativo il segno resta leggibile', () {
      // Saldo da −100 a +100: miglioramento del 200%.
      expect(percentChange(100, -100), closeTo(2, 1e-9));
    });
  });

  test('metricTotal conta solo il periodo', () {
    expect(
      metricTotal(
        [
          tx(TransactionType.income, 1000, LocalDate(2026, 10, 1)),
          tx(TransactionType.income, 1000, LocalDate(2026, 11, 1)),
        ],
        october,
        CompareMetric.income,
      ),
      1000,
    );
  });
}
