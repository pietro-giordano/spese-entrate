import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:spese_entrate/core/clock.dart';
import 'package:spese_entrate/core/dates.dart';
import 'package:spese_entrate/data/db/app_database.dart';
import 'package:spese_entrate/data/db/database_provider.dart';
import 'package:spese_entrate/domain/models/statistics.dart';
import 'package:spese_entrate/domain/services/comparison.dart';
import 'package:spese_entrate/features/analytics/application/compare_providers.dart';
import 'package:spese_entrate/features/analytics/presentation/compare_screen.dart';
import 'package:spese_entrate/features/analytics/presentation/widgets/compare_charts.dart';

ComparedPeriod period(
  int month, {
  required int income,
  required int expense,
  Map<String?, int> byCategory = const {},
}) => ComparedPeriod(
  period: Period.containing(PeriodType.month, LocalDate(2026, month, 1)),
  summary: PeriodSummary(incomeCents: income, expenseCents: expense),
  byCategory: byCategory,
  cumulative: const [],
);

void main() {
  setUpAll(() => initializeDateFormatting('it_IT'));

  group('buildCompareRows', () {
    final data = [
      period(9, income: 0, expense: 145800, byCategory: {'home': 75000, 'food': 34200, 'fun': 6400}),
      period(8, income: 0, expense: 170300, byCategory: {'home': 75000, 'food': 29800, 'travel': 21500}),
    ];
    final names = {'home': 'Casa', 'food': 'Spesa alimentare', 'fun': 'Svago', 'travel': 'Trasporti'};

    test('una riga per categoria (dalla più grande) più il totale', () {
      final rows = buildCompareRows(data, CompareMetric.expense, names);
      // Ordine sul primo periodo: Svago (64 €) prima di Trasporti (0 €, presente solo ad agosto).
      expect(rows.map((r) => r.name), ['Casa', 'Spesa alimentare', 'Svago', 'Trasporti', 'Totale']);
      expect(rows.firstWhere((r) => r.name == 'Trasporti').values, [0, 21500], reason: 'zero dove manca');
      expect(rows.last.values, [145800, 170300]);
      expect(rows.last.isTotal, isTrue);
      expect(rows.every((r) => !r.higherIsBetter), isTrue, reason: 'per le spese aumentare è negativo');
    });

    test('saldo: entrate, uscite e saldo', () {
      final rows = buildCompareRows(
        [period(9, income: 240000, expense: 145800), period(8, income: 240000, expense: 170300)],
        CompareMetric.balance,
        names,
      );
      // Le liste si confrontano per contenuto solo campo per campo (in un record varrebbe l'identità).
      expect(rows.map((r) => r.name), ['Entrate', 'Uscite', 'Saldo']);
      expect(rows.map((r) => r.values), [
        [240000, 240000],
        [145800, 170300],
        [94200, 69700],
      ]);
      expect(rows.map((r) => r.higherIsBetter), [true, false, true]);
    });
  });

  test('nomi brevi per le etichette', () {
    expect(shortCategoryName('Spesa alimentare'), 'Spesa');
    expect(shortCategoryName('Trasporti'), 'Trasp.');
    expect(shortCategoryName('Casa'), 'Casa');
    expect(shortPeriodLabel(Period.containing(PeriodType.month, LocalDate(2026, 9, 1)), 0), 'Set 26');
    expect(shortPeriodLabel(Period.containing(PeriodType.year, LocalDate(2025, 1, 1)), 1), '2025');
    expect(shortPeriodLabel(Period.containing(PeriodType.week, LocalDate(2026, 9, 1)), 2), 'P3');
  });

  test('niceStep: passi tondi per l\'asse', () {
    expect(niceStep(1040), 500, reason: '0, 500, 1k, 1,5k');
    expect(niceStep(90), 50);
    expect(niceStep(2400), 1000);
    expect(niceStep(0), 1);
  });

  group('CompareController', () {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    late ProviderContainer container;
    setUp(() {
      final db = AppDatabase(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => DateTime(2026, 10, 3, 9)),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
    });

    CompareController controller() => container.read(compareControllerProvider.notifier);
    CompareState state() => container.read(compareControllerProvider);

    test('parte dagli ultimi 3 mesi e non supera 3 periodi', () {
      expect(state().preset, ComparePreset.lastThreeMonths);
      expect(state().periods, hasLength(3));
      expect(controller().addPeriod(Period.containing(PeriodType.year, LocalDate(2026, 1, 1))), isFalse);
    });

    test('togliere o aggiungere passa a Personalizzato; niente doppioni; mai sotto 1', () {
      final [first, second, third] = state().periods;
      controller().removePeriod(third);
      expect(state().preset, ComparePreset.custom);
      expect(controller().addPeriod(second), isFalse, reason: 'già presente');
      expect(controller().addPeriod(third), isTrue);

      controller()
        ..removePeriod(first)
        ..removePeriod(second)
        ..removePeriod(third);
      expect(state().periods, hasLength(1));
    });

    test('un preset sostituisce i periodi', () {
      controller().applyPreset(ComparePreset.yearVsYear);
      expect(state().periods.map((p) => (p.type, p.start.year)), [(PeriodType.year, 2026), (PeriodType.year, 2025)]);
      controller().applyPreset(ComparePreset.custom);
      expect(state().periods, hasLength(2), reason: 'Personalizzato tiene i periodi attuali');
    });
  });
}
