import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:spese_entrate/core/dates.dart';
import 'package:spese_entrate/features/transactions/application/transaction_list_providers.dart';
import 'package:spese_entrate/features/transactions/presentation/period_labels.dart';

void main() {
  setUpAll(() => initializeDateFormatting('it_IT'));
  final today = LocalDate(2026, 10, 3); // sabato

  group('changePeriodType', () {
    final october = Period.containing(PeriodType.month, today);

    test('se il periodo contiene oggi riparte da oggi', () {
      expect(changePeriodType(october, PeriodType.day, today: today, weekStart: 1).start, today);
      expect(
        changePeriodType(october, PeriodType.week, today: today, weekStart: 1).range,
        DateRange(LocalDate(2026, 9, 28), LocalDate(2026, 10, 4)),
      );
    });

    test('altrimenti dal primo giorno del periodo', () {
      final august = Period.containing(PeriodType.month, LocalDate(2026, 8, 20));
      expect(changePeriodType(august, PeriodType.day, today: today, weekStart: 1).start, LocalDate(2026, 8, 1));
    });

    test('Periodo mantiene le date attuali', () {
      final custom = changePeriodType(october, PeriodType.custom, today: today, weekStart: 1);
      expect((custom.type, custom.range), (PeriodType.custom, october.range));
    });
  });

  group('titoli', () {
    test('periodTitle', () {
      expect(periodTitle(Period.containing(PeriodType.day, today), today), 'Sabato 3 ottobre');
      expect(periodTitle(Period.containing(PeriodType.week, today), today), '28 set – 4 ott 2026');
      expect(periodTitle(Period.containing(PeriodType.month, today), today), 'Ottobre 2026');
      expect(periodTitle(Period.containing(PeriodType.year, today), today), '2026');
      expect(periodTitle(Period.custom(LocalDate(2026, 8, 1), today), today), '1 ago – 3 ott 2026');
      expect(
        periodTitle(Period.custom(LocalDate(2025, 12, 20), LocalDate(2026, 1, 5)), today),
        '20 dic 2025 – 5 gen 2026',
      );
    });

    test('dayTitle', () {
      expect(dayTitle(today, today), 'Oggi · sab 3 ottobre');
      expect(dayTitle(LocalDate(2026, 10, 2), today), 'Ieri · ven 2 ottobre');
      expect(dayTitle(LocalDate(2026, 10, 1), today), 'Gio 1 ottobre');
      expect(dayTitle(LocalDate(2025, 10, 1), today), 'Mer 1 ottobre 2025');
    });
  });
}
