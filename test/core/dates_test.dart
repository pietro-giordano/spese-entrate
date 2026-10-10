import 'package:flutter_test/flutter_test.dart';
import 'package:spese_entrate/core/dates.dart';

LocalDate d(String iso) => LocalDate.parse(iso);

void main() {
  group('LocalDate', () {
    test('rifiuta date inesistenti', () {
      expect(() => LocalDate(2026, 2, 29), throwsArgumentError);
      expect(() => LocalDate(2026, 13, 1), throwsArgumentError);
      expect(() => LocalDate(2026, 4, 31), throwsArgumentError);
      expect(LocalDate(2024, 2, 29).day, 29);
    });

    test('parse accetta solo YYYY-MM-DD valide', () {
      expect(d('2026-10-10'), LocalDate(2026, 10, 10));
      expect(() => d('2026-1-05'), throwsFormatException);
      expect(() => d('10/10/2026'), throwsFormatException);
      expect(() => d('2025-02-29'), throwsFormatException);
      expect(() => d('2026-10-10T12:00'), throwsFormatException);
    });

    test('toString è il formato del database', () {
      expect(LocalDate(2026, 3, 7).toString(), '2026-03-07');
      expect(d('2026-12-31').toString(), '2026-12-31');
    });

    test('today usa il giorno locale e ignora l\'ora', () {
      expect(LocalDate.today(now: DateTime(2026, 10, 10, 23, 59)), d('2026-10-10'));
      expect(LocalDate.today(now: DateTime(2026, 10, 11, 0, 0)), d('2026-10-11'));
    });

    test('weekday: 1 = lunedì, 7 = domenica', () {
      expect(d('2026-10-05').weekday, DateTime.monday);
      expect(d('2026-10-10').weekday, DateTime.saturday);
      expect(d('2026-10-11').weekday, DateTime.sunday);
    });

    test('addDays attraversa mesi, anni e cambio dell\'ora legale', () {
      expect(d('2026-10-31').addDays(1), d('2026-11-01'));
      expect(d('2026-12-31').addDays(1), d('2027-01-01'));
      expect(d('2026-03-01').addDays(-1), d('2026-02-28'));
      // Il 29 marzo 2026 in Italia l'ora passa da 2 a 3.
      expect(d('2026-03-28').addDays(2), d('2026-03-30'));
      expect(d('2026-10-24').addDays(2), d('2026-10-26'));
    });

    test('addMonths usa l\'ultimo giorno se quello di partenza non esiste', () {
      expect(d('2026-01-31').addMonths(1), d('2026-02-28'));
      expect(d('2024-01-31').addMonths(1), d('2024-02-29'));
      expect(d('2026-03-31').addMonths(-1), d('2026-02-28'));
      expect(d('2026-05-31').addMonths(1), d('2026-06-30'));
      expect(d('2026-12-15').addMonths(1), d('2027-01-15'));
      expect(d('2026-01-15').addMonths(-13), d('2024-12-15'));
    });

    test('addYears porta il 29 febbraio al 28 negli anni non bisestili', () {
      expect(d('2024-02-29').addYears(1), d('2025-02-28'));
      expect(d('2024-02-29').addYears(4), d('2028-02-29'));
    });

    test('daysInMonth', () {
      expect(LocalDate.daysInMonth(2026, 2), 28);
      expect(LocalDate.daysInMonth(2024, 2), 29);
      expect(LocalDate.daysInMonth(1900, 2), 28);
      expect(LocalDate.daysInMonth(2000, 2), 29);
      expect(LocalDate.daysInMonth(2026, 12), 31);
    });

    test('confronto, uguaglianza e daysUntil', () {
      expect(d('2026-10-10').isBefore(d('2026-10-11')), isTrue);
      expect(d('2026-10-10').isAfter(d('2025-12-31')), isTrue);
      expect({d('2026-10-10'), LocalDate(2026, 10, 10)}, hasLength(1));
      expect(d('2026-10-01').daysUntil(d('2026-10-31')), 30);
      expect(d('2026-03-31').daysUntil(d('2026-03-01')), -30);
      expect([d('2026-10-10'), d('2025-01-01'), d('2026-01-01')]..sort(), [
        d('2025-01-01'),
        d('2026-01-01'),
        d('2026-10-10'),
      ]);
    });
  });

  group('DateRange', () {
    test('estremi inclusi', () {
      final range = DateRange(d('2026-10-01'), d('2026-10-31'));
      expect(range.dayCount, 31);
      expect(range.contains(d('2026-10-01')), isTrue);
      expect(range.contains(d('2026-10-31')), isTrue);
      expect(range.contains(d('2026-11-01')), isFalse);
      expect(DateRange(d('2026-10-10'), d('2026-10-10')).dayCount, 1);
    });

    test('rifiuta una fine prima dell\'inizio', () {
      expect(() => DateRange(d('2026-10-10'), d('2026-10-09')), throwsArgumentError);
    });
  });

  group('Period.containing', () {
    final saturday = d('2026-10-10');

    test('giorno', () {
      final period = Period.containing(PeriodType.day, saturday);
      expect(period.range, DateRange(saturday, saturday));
    });

    test('settimana da lunedì (default)', () {
      final period = Period.containing(PeriodType.week, saturday);
      expect(period.range, DateRange(d('2026-10-05'), d('2026-10-11')));
    });

    test('settimana da domenica', () {
      final period = Period.containing(PeriodType.week, saturday, weekStart: DateTime.sunday);
      expect(period.range, DateRange(d('2026-10-04'), d('2026-10-10')));
    });

    test('settimana che inizia proprio nel giorno scelto', () {
      final period = Period.containing(PeriodType.week, saturday, weekStart: DateTime.saturday);
      expect(period.range, DateRange(d('2026-10-10'), d('2026-10-16')));
    });

    test('settimana a cavallo di due anni', () {
      final period = Period.containing(PeriodType.week, d('2027-01-01'));
      expect(period.range, DateRange(d('2026-12-28'), d('2027-01-03')));
    });

    test('mese, anche febbraio bisestile', () {
      expect(Period.containing(PeriodType.month, saturday).range, DateRange(d('2026-10-01'), d('2026-10-31')));
      expect(Period.containing(PeriodType.month, d('2024-02-10')).range, DateRange(d('2024-02-01'), d('2024-02-29')));
    });

    test('anno', () {
      expect(Period.containing(PeriodType.year, saturday).range, DateRange(d('2026-01-01'), d('2026-12-31')));
    });

    test('periodo personalizzato e weekStart non validi', () {
      expect(() => Period.containing(PeriodType.custom, saturday), throwsArgumentError);
      expect(() => Period.containing(PeriodType.week, saturday, weekStart: 0), throwsArgumentError);
      expect(() => Period.containing(PeriodType.week, saturday, weekStart: 8), throwsArgumentError);
    });
  });

  group('Period.shift', () {
    test('giorno e settimana si spostano di 1 e 7 giorni', () {
      final day = Period.containing(PeriodType.day, d('2026-10-31'));
      expect(day.next.range, DateRange(d('2026-11-01'), d('2026-11-01')));

      final week = Period.containing(PeriodType.week, d('2026-10-10'), weekStart: DateTime.sunday);
      expect(week.previous.range, DateRange(d('2026-09-27'), d('2026-10-03')));
      expect(week.next.next.range, DateRange(d('2026-10-18'), d('2026-10-24')));
    });

    test('mese segue la lunghezza di ogni mese', () {
      final january = Period.containing(PeriodType.month, d('2026-01-31'));
      expect(january.next.range, DateRange(d('2026-02-01'), d('2026-02-28')));
      expect(january.next.next.range, DateRange(d('2026-03-01'), d('2026-03-31')));
      expect(january.previous.range, DateRange(d('2025-12-01'), d('2025-12-31')));
      expect(january.shift(12).range, DateRange(d('2027-01-01'), d('2027-01-31')));
    });

    test('anno', () {
      final year = Period.containing(PeriodType.year, d('2024-02-29'));
      expect(year.next.range, DateRange(d('2025-01-01'), d('2025-12-31')));
    });

    test('periodo personalizzato si sposta della sua durata', () {
      final custom = Period.custom(d('2026-08-01'), d('2026-10-03')); // 64 giorni
      expect(custom.range.dayCount, 64);
      expect(custom.previous.range, DateRange(d('2026-05-29'), d('2026-07-31')));
      expect(custom.next.range, DateRange(d('2026-10-04'), d('2026-12-06')));
      expect(custom.next.type, PeriodType.custom);
    });

    test('shift(0) restituisce lo stesso periodo', () {
      final month = Period.containing(PeriodType.month, d('2026-10-10'));
      expect(month.shift(0), month);
    });
  });
}
