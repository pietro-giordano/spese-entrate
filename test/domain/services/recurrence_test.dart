import 'package:flutter_test/flutter_test.dart';
import 'package:spese_entrate/core/dates.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/recurrence_exception.dart';
import 'package:spese_entrate/domain/models/recurrence_rule.dart';
import 'package:spese_entrate/domain/models/transaction.dart';
import 'package:spese_entrate/domain/services/recurrence.dart';

LocalDate d(int y, int m, int day) => LocalDate(y, m, day);

RecurrenceRule rule(
  RecurrenceFrequency frequency,
  LocalDate start, {
  int interval = 1,
  LocalDate? end,
  int? maxCount,
  int amount = 1000,
  TransactionType type = TransactionType.expense,
  String id = 'r',
  DateTime? pausedAt,
}) => anchorRuleAt(
  RecurrenceRule(
    id: id,
    name: 'Regola',
    type: type,
    amountCents: amount,
    walletId: 'w',
    frequency: frequency,
    interval: interval,
    startDate: start,
    endDate: end,
    maxCount: maxCount,
    mode: RecurrenceMode.auto,
    pausedAt: pausedAt,
  ),
  start,
);

List<LocalDate> first(RecurrenceRule r, int n) => occurrenceDates(r).take(n).toList();

void main() {
  group('occorrenze', () {
    test('giornaliera con intervallo', () {
      expect(first(rule(RecurrenceFrequency.daily, d(2026, 2, 27), interval: 2), 3), [
        d(2026, 2, 27),
        d(2026, 3, 1),
        d(2026, 3, 3),
      ]);
    });

    test('settimanale: stesso giorno della settimana, ogni 2 settimane', () {
      final r = rule(RecurrenceFrequency.weekly, d(2026, 10, 5), interval: 2); // lunedì
      expect(r.byWeekday, DateTime.monday);
      expect(first(r, 3), [d(2026, 10, 5), d(2026, 10, 19), d(2026, 11, 2)]);
    });

    test('mensile il 31: ultimo giorno nei mesi corti, poi di nuovo il 31', () {
      expect(first(rule(RecurrenceFrequency.monthly, d(2026, 1, 31)), 4), [
        d(2026, 1, 31),
        d(2026, 2, 28),
        d(2026, 3, 31),
        d(2026, 4, 30),
      ]);
    });

    test('mensile il 30 in un anno bisestile e cambio d\'anno', () {
      expect(first(rule(RecurrenceFrequency.monthly, d(2027, 12, 30), interval: 2), 3), [
        d(2027, 12, 30),
        d(2028, 2, 29),
        d(2028, 4, 30),
      ]);
    });

    test('annuale il 29 febbraio: 28 negli anni non bisestili, 29 nei bisestili', () {
      expect(first(rule(RecurrenceFrequency.yearly, d(2028, 2, 29)), 5), [
        d(2028, 2, 29),
        d(2029, 2, 28),
        d(2030, 2, 28),
        d(2031, 2, 28),
        d(2032, 2, 29),
      ]);
    });

    test('mensile con giorno fisso prima dell\'inizio: la prima cade il mese dopo', () {
      final r = rule(RecurrenceFrequency.monthly, d(2026, 10, 10)).copyWith(byMonthDay: 5);
      expect(first(r, 2), [d(2026, 11, 5), d(2026, 12, 5)]);
    });

    test('rispetta end_date (compresa) e max_count', () {
      expect(occurrenceDates(rule(RecurrenceFrequency.monthly, d(2026, 1, 15), end: d(2026, 4, 15))).toList(), [
        d(2026, 1, 15),
        d(2026, 2, 15),
        d(2026, 3, 15),
        d(2026, 4, 15),
      ]);
      expect(occurrenceDates(rule(RecurrenceFrequency.weekly, d(2026, 1, 1), maxCount: 3)).length, 3);
      expect(occurrenceDates(rule(RecurrenceFrequency.daily, d(2026, 1, 1), maxCount: 0)), isEmpty);
    });

    test('intervalli, prossima, precedente, posizione, fine', () {
      final r = rule(RecurrenceFrequency.monthly, d(2026, 1, 5), maxCount: 4);
      expect(occurrencesBetween(r, d(2026, 2, 1), d(2026, 3, 31)), [d(2026, 2, 5), d(2026, 3, 5)]);
      expect(nextOccurrence(r, d(2026, 2, 6)), d(2026, 3, 5));
      expect(nextOccurrence(r, d(2026, 4, 6)), isNull);
      expect(previousOccurrence(r, d(2026, 3, 5)), d(2026, 2, 5));
      expect(previousOccurrence(r, d(2026, 1, 5)), isNull);
      expect(occurrenceIndex(r, d(2026, 3, 5)), 2);
      expect(occurrenceIndex(r, d(2026, 3, 6)), isNull);
      expect(isRuleFinished(r, d(2026, 4, 5)), isFalse);
      expect(isRuleFinished(r, d(2026, 4, 6)), isTrue);
    });
  });

  group('importo medio mensile', () {
    test('mensile = importo, altre frequenze = media', () {
      expect(monthlyEquivalentCents(rule(RecurrenceFrequency.monthly, d(2026, 1, 1), amount: 1099)), 1099);
      expect(monthlyEquivalentCents(rule(RecurrenceFrequency.monthly, d(2026, 1, 1), amount: 6400, interval: 2)), 3200);
      expect(monthlyEquivalentCents(rule(RecurrenceFrequency.yearly, d(2026, 1, 1), amount: 48000)), 4000);
      expect(monthlyEquivalentCents(rule(RecurrenceFrequency.weekly, d(2026, 1, 1), amount: 1200)), 5200);
      expect(monthlyEquivalentCents(rule(RecurrenceFrequency.daily, d(2026, 1, 1), amount: 100)), 3042);
    });
  });

  group('totali delle ricorrenze', () {
    final october = DateRange(d(2026, 10, 1), d(2026, 10, 31));

    test('effettivi del mese e media prevista sono distinti', () {
      final rules = [
        rule(RecurrenceFrequency.monthly, d(2026, 1, 7), amount: 1099, id: 'spotify'),
        // Ogni 2 mesi dal 5 agosto: cade in ottobre per intero, la media è la metà.
        rule(RecurrenceFrequency.monthly, d(2026, 8, 5), amount: 6400, interval: 2, id: 'luce'),
        // Annuale a marzo: non cade in ottobre, ma pesa 1/12 nella media.
        rule(RecurrenceFrequency.yearly, d(2026, 3, 15), amount: 48000, id: 'assicurazione'),
        rule(RecurrenceFrequency.monthly, d(2026, 1, 2), amount: 240000, type: TransactionType.income, id: 'stip'),
        rule(RecurrenceFrequency.monthly, d(2026, 1, 1), amount: 50000, type: TransactionType.transfer, id: 'pac'),
      ];
      final totals = recurringTotals(
        rules: rules,
        exceptions: const [],
        transactions: const [],
        month: october,
        today: d(2026, 10, 3),
      );
      expect(totals.expenseInMonth, 1099 + 6400);
      expect(totals.expenseMonthlyAverage, 1099 + 3200 + 4000);
      expect(totals.incomeInMonth, 240000);
      expect(totals.incomeMonthlyAverage, 240000);
      expect(totals.expenseHasNonMonthly, isTrue);
      expect(totals.incomeHasNonMonthly, isFalse, reason: 'lo stipendio è mensile: nessuna media da mostrare');
    });

    test('nel mese contano gli importi registrati, le saltate e le pause no', () {
      final rules = [
        rule(RecurrenceFrequency.monthly, d(2026, 1, 5), amount: 6400, id: 'luce'),
        rule(
          RecurrenceFrequency.monthly,
          d(2026, 1, 10),
          amount: 3900,
          id: 'palestra',
          pausedAt: DateTime.utc(2026, 9),
        ),
        rule(RecurrenceFrequency.monthly, d(2026, 1, 20), amount: 1000, id: 'saltata'),
      ];
      final totals = recurringTotals(
        rules: rules,
        exceptions: [RecurrenceException(id: 'e', ruleId: 'saltata', occurrenceDate: d(2026, 10, 20))],
        transactions: [
          Transaction(
            id: 't',
            type: TransactionType.expense,
            amountCents: 7120,
            date: d(2026, 10, 6),
            walletId: 'w',
            recurrenceId: 'luce',
            occurrenceDate: d(2026, 10, 5),
          ),
        ],
        month: october,
        today: d(2026, 10, 3),
      );
      expect(totals.expenseInMonth, 7120);
      expect(totals.expenseMonthlyAverage, 6400 + 1000, reason: 'la regola in pausa non conta nella media');
      expect(totals.expenseHasNonMonthly, isFalse);
    });
  });

  group('divisione "questa e le successive"', () {
    final old = rule(RecurrenceFrequency.monthly, d(2026, 1, 5), maxCount: 12);

    RecurrenceRule next(LocalDate start, {int amount = 7000}) =>
        anchorRuleAt(old.copyWith(id: 'nuova', amountCents: amount, maxCount: null), start);

    test('stessa data: la vecchia finisce il giorno prima, la nuova eredita le occorrenze rimaste', () {
      final split = splitRule(old, boundary: d(2026, 10, 5), next: next(d(2026, 10, 5)));
      expect(split.ended.endDate, d(2026, 10, 4));
      expect(occurrenceDates(split.ended).last, d(2026, 9, 5));
      expect(split.next.maxCount, 3, reason: '12 in tutto, 9 già nella vecchia');
      expect(occurrenceDates(split.next).toList(), [d(2026, 10, 5), d(2026, 11, 5), d(2026, 12, 5)]);
      expect(split.nextSkips, isEmpty);
    });

    test('data spostata avanti: nuovo giorno del mese, nessuna sovrapposizione', () {
      final split = splitRule(old, boundary: d(2026, 10, 5), next: next(d(2026, 10, 12)));
      expect(split.ended.endDate, d(2026, 10, 4));
      expect(split.next.byMonthDay, 12);
      expect(first(split.next, 2), [d(2026, 10, 12), d(2026, 11, 12)]);
    });

    test('data spostata indietro: la vecchia finisce prima della nuova data', () {
      final split = splitRule(old, boundary: d(2026, 10, 5), next: next(d(2026, 9, 28)));
      expect(split.ended.endDate, d(2026, 9, 27));
      expect(occurrenceDates(split.ended).last, d(2026, 9, 5));
      expect(first(split.next, 2), [d(2026, 9, 28), d(2026, 10, 28)]);
    });

    test('data prima o uguale all\'occorrenza precedente: rifiutata', () {
      expect(
        () => splitRule(old, boundary: d(2026, 10, 5), next: next(d(2026, 9, 5))),
        throwsA(isA<SplitDateException>().having((e) => e.previousOccurrence, 'precedente', d(2026, 9, 5))),
      );
    });

    test('le occorrenze successive già risolte saltano la loro controparte nella nuova regola', () {
      // Novembre confermato in anticipo e gennaio eliminato nella vecchia regola:
      // la nuova (dal 12) salta il 12 novembre e il 12 gennaio, dicembre resta.
      final split = splitRule(
        old,
        boundary: d(2026, 10, 5),
        next: next(d(2026, 10, 12)).copyWith(maxCount: null),
        resolvedOldDates: {d(2026, 11, 5), d(2027, 1, 5), d(2026, 9, 5)},
      );
      expect(split.nextSkips, [d(2026, 11, 12)]);
      // La vecchia ha max 12: gennaio 2027 sarebbe la tredicesima, quindi non esiste.
      final unlimited = splitRule(
        old.copyWith(maxCount: null),
        boundary: d(2026, 10, 5),
        next: next(d(2026, 10, 12)),
        resolvedOldDates: {d(2026, 11, 5), d(2027, 1, 5)},
      );
      expect(unlimited.nextSkips, [d(2026, 11, 12), d(2027, 1, 12)]);
    });

    test('il confine deve essere un\'occorrenza', () {
      expect(() => splitRule(old, boundary: d(2026, 10, 6), next: next(d(2026, 10, 6))), throwsArgumentError);
    });
  });
}
