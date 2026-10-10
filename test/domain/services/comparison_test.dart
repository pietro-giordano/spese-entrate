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

  group('cumulativeByDay ai confini', () {
    List<int> run(DateRange range, List<Transaction> list) => cumulativeByDay(list, range, CompareMetric.expense);
    DateRange month(int year, int m) => Period.containing(PeriodType.month, LocalDate(year, m, 1)).range;

    test('un elemento per giorno: mesi da 28, 29, 30 e 31 giorni, anni da 365 e 366', () {
      expect(run(month(2026, 2), const []), hasLength(28));
      expect(run(month(2024, 2), const []), hasLength(29));
      expect(run(month(2026, 4), const []), hasLength(30));
      expect(run(month(2026, 1), const []), hasLength(31));
      expect(run(Period.containing(PeriodType.year, LocalDate(2025, 1, 1)).range, const []), hasLength(365));
      expect(run(Period.containing(PeriodType.year, LocalDate(2024, 1, 1)).range, const []), hasLength(366));
    });

    test('nei giorni senza movimenti il cumulato resta uguale', () {
      final series = run(month(2026, 4), [
        tx(TransactionType.expense, 1000, LocalDate(2026, 4, 3)),
        tx(TransactionType.expense, 500, LocalDate(2026, 4, 20)),
      ]);
      expect(series.sublist(0, 2), [0, 0]);
      expect(series.sublist(2, 19).toSet(), {1000}, reason: 'dal 3 al 19 aprile');
      expect(series.sublist(19).toSet(), {1500}, reason: 'dal 20 al 30 aprile');
    });

    test('primo e ultimo giorno contano; il giorno prima e quello dopo no', () {
      final series = run(month(2026, 2), [
        tx(TransactionType.expense, 7, LocalDate(2026, 1, 31)),
        tx(TransactionType.expense, 100, LocalDate(2026, 2, 1)),
        tx(TransactionType.expense, 200, LocalDate(2026, 2, 28)),
        tx(TransactionType.expense, 9, LocalDate(2026, 3, 1)),
      ]);
      expect(series.first, 100);
      expect(series[26], 100, reason: '27 febbraio');
      expect(series.last, 300);
    });

    test('29 febbraio nell\'anno bisestile', () {
      final series = run(month(2024, 2), [tx(TransactionType.expense, 50, LocalDate(2024, 2, 29))]);
      expect(series[27], 0, reason: '28 febbraio');
      expect(series.last, 50);
      final year = run(Period.containing(PeriodType.year, LocalDate(2024, 1, 1)).range, [
        tx(TransactionType.expense, 50, LocalDate(2024, 2, 29)),
        tx(TransactionType.expense, 25, LocalDate(2024, 12, 31)),
      ]);
      expect(year[58], 0, reason: '28 febbraio (indice 58)');
      expect(year[59], 50, reason: '29 febbraio (indice 59)');
      expect(year[364], 50, reason: '30 dicembre');
      expect(year.last, 75);
    });

    test('periodo a cavallo di anno e dei cambi d\'ora legale', () {
      final newYear = run(DateRange(LocalDate(2025, 12, 30), LocalDate(2026, 1, 2)), [
        tx(TransactionType.expense, 10, LocalDate(2025, 12, 31)),
        tx(TransactionType.expense, 20, LocalDate(2026, 1, 1)),
      ]);
      expect(newYear, [0, 10, 30, 30]);

      // In Italia l'ora cambia il 29 marzo e il 25 ottobre 2026: gli indici non devono slittare.
      final march = run(month(2026, 3), [tx(TransactionType.expense, 5, LocalDate(2026, 3, 30))]);
      expect((march[28], march[29]), (0, 5));
      final october = run(month(2026, 10), [tx(TransactionType.expense, 5, LocalDate(2026, 10, 26))]);
      expect((october[24], october[25]), (0, 5));
    });
  });

  group('comparisonCaveats', () {
    Period month(int year, int m) => Period.containing(PeriodType.month, LocalDate(year, m, 1));

    test('durate diverse e periodo in corso', () {
      final caveats = comparisonCaveats([month(2026, 10), month(2026, 9), month(2026, 8)], today);
      expect(caveats.differentLengths, isTrue, reason: '31, 30, 31 giorni');
      expect(caveats.inProgress, [month(2026, 10)]);
      expect(caveats.any, isTrue);
    });

    test('stessa durata e periodi conclusi: nessun avviso', () {
      final caveats = comparisonCaveats([month(2026, 8), month(2025, 8)], today);
      expect(caveats.differentLengths, isFalse);
      expect(caveats.inProgress, isEmpty);
      expect(caveats.any, isFalse);
    });

    test('un periodo nel futuro non è concluso; l\'ultimo giorno di ieri sì', () {
      expect(comparisonCaveats([month(2026, 11)], today).inProgress, hasLength(1));
      final endedYesterday = Period.custom(LocalDate(2026, 9, 3), LocalDate(2026, 10, 2));
      expect(comparisonCaveats([endedYesterday], today).inProgress, isEmpty);
    });

    test('anni bisestili: 366 e 365 giorni sono durate diverse', () {
      final years = [
        Period.containing(PeriodType.year, LocalDate(2024, 1, 1)),
        Period.containing(PeriodType.year, LocalDate(2023, 1, 1)),
      ];
      expect(comparisonCaveats(years, today).differentLengths, isTrue);
    });
  });
}
