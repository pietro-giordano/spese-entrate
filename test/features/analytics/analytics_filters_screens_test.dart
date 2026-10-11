import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:spese_entrate/app.dart';
import 'package:spese_entrate/core/clock.dart';
import 'package:spese_entrate/core/dates.dart';
import 'package:spese_entrate/core/ids.dart';
import 'package:spese_entrate/core/router/app_router.dart';
import 'package:spese_entrate/core/router/app_routes.dart';
import 'package:spese_entrate/data/db/app_database.dart';
import 'package:spese_entrate/data/db/database_provider.dart';
import 'package:spese_entrate/data/repositories/repository_providers.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/transaction.dart';
import 'package:spese_entrate/domain/models/transaction_filters.dart';
import 'package:spese_entrate/domain/services/comparison.dart';
import 'package:spese_entrate/features/analytics/application/analytics_filters.dart';
import 'package:spese_entrate/features/analytics/application/charts_providers.dart';
import 'package:spese_entrate/features/analytics/application/compare_providers.dart';
import 'package:spese_entrate/features/transactions/application/transaction_list_providers.dart';
import 'package:spese_entrate/features/transactions/presentation/filters_screen.dart';
import 'package:spese_entrate/features/transactions/presentation/transactions_screen.dart';

void main() {
  setUpAll(() => initializeDateFormatting('it_IT'));
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late ProviderContainer container;
  late Map<String, String> walletIds;
  late Map<String, String> categoryIds;

  /// Oggi è il 3 ottobre 2026.
  /// Ottobre: Spesa alimentare 64,20 (conto), Ristoranti 4,50 (contanti), Stipendio 2.400 (conto).
  /// Settembre: Spesa alimentare 50 (contanti), Casa 750 (conto). Agosto: Spesa alimentare 40 (conto).
  Future<void> pumpTab(WidgetTester tester, String location) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory(), now: () => DateTime.utc(2026, 10, 3, 8));
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
    await tester.runAsync(() async {
      walletIds = {for (final w in await db.select(db.wallets).get()) w.name: w.id};
      categoryIds = {for (final c in await db.select(db.categories).get()) '${c.kind.name}:${c.name}': c.id};
      Transaction t(TransactionType type, int cents, LocalDate date, String wallet, String category) => Transaction(
        id: newId(),
        type: type,
        amountCents: cents,
        date: date,
        walletId: walletIds[wallet]!,
        categoryId: categoryIds['${type == TransactionType.income ? 'income' : 'expense'}:$category'],
      );
      final repo = container.read(transactionRepositoryProvider);
      for (final tx in [
        t(TransactionType.expense, 6420, LocalDate(2026, 10, 3), 'Conto corrente', 'Spesa alimentare'),
        t(TransactionType.expense, 450, LocalDate(2026, 10, 2), 'Contanti', 'Ristoranti'),
        t(TransactionType.income, 240000, LocalDate(2026, 10, 1), 'Conto corrente', 'Stipendio'),
        t(TransactionType.expense, 5000, LocalDate(2026, 9, 10), 'Contanti', 'Spesa alimentare'),
        t(TransactionType.expense, 75000, LocalDate(2026, 9, 1), 'Conto corrente', 'Casa'),
        t(TransactionType.expense, 4000, LocalDate(2026, 8, 20), 'Conto corrente', 'Spesa alimentare'),
      ]) {
        await repo.save(tx);
      }
    });
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const App()));
    await tester.pumpAndSettle();
    container.read(appRouterProvider).go(location);
    await tester.pumpAndSettle();
  }

  Future<void> finish(WidgetTester tester) => tester.pump(const Duration(milliseconds: 10));

  /// Apre i Filtri dalla tab, sceglie [chip] e applica.
  Future<void> filterBy(WidgetTester tester, String chip) async {
    await tester.tap(find.byTooltip('Filtri'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(FiltersScreen), matching: find.text(chip)).first);
    await tester.pump();
    await tester.tap(find.text('Applica filtri'));
    await tester.pumpAndSettle();
  }

  group('Grafici', () {
    testWidgets('i Filtri della tab mostrano solo portafogli, categorie e label', (tester) async {
      await pumpTab(tester, AppRoutes.charts);
      await tester.tap(find.byTooltip('Filtri'));
      await tester.pumpAndSettle();
      final filters = find.byType(FiltersScreen);
      expect(filters, findsOneWidget);
      expect(find.descendant(of: filters, matching: find.text('TIPO')), findsNothing);
      expect(find.descendant(of: filters, matching: find.text('PERIODO')), findsNothing);
      expect(find.text('Mostra anche i trasferimenti tra portafogli'), findsNothing);
      expect(find.descendant(of: filters, matching: find.text('PORTAFOGLI')), findsOneWidget);
      expect(find.descendant(of: filters, matching: find.text('CATEGORIE')), findsOneWidget);
      await finish(tester);
    });

    testWidgets('filtro per portafoglio: torta e totale filtrati, chip, badge; le altre tab non cambiano', (
      tester,
    ) async {
      await pumpTab(tester, AppRoutes.charts);
      expect(find.text('€ 68,70'), findsOneWidget, reason: 'spese di ottobre senza filtri');

      await filterBy(tester, 'Contanti');
      expect(container.read(analyticsFiltersProvider(AnalyticsTab.charts)).walletIds, {walletIds['Contanti']});
      expect(find.byTooltip('Filtri, 1 attivi'), findsOneWidget);
      expect(find.bySemanticsLabel('Rimuovi filtro Contanti'), findsOneWidget);
      expect(find.text('€ 68,70'), findsNothing);
      expect(find.text('Ristoranti'), findsOneWidget);
      expect(find.text('Spesa alimentare'), findsNothing);

      // Ogni tab ha i suoi filtri.
      expect(container.read(activeFiltersProvider), const TransactionFilters());
      expect(container.read(analyticsFiltersProvider(AnalyticsTab.compare)), const TransactionFilters());

      // Il chip toglie il filtro.
      await tester.tap(find.bySemanticsLabel('Rimuovi filtro Contanti'));
      await tester.pumpAndSettle();
      expect(container.read(analyticsFiltersProvider(AnalyticsTab.charts)).isActive, isFalse);
      expect(find.text('€ 68,70'), findsOneWidget);
      expect(find.text('Azzera'), findsNothing, reason: 'senza filtri la riga sparisce');
      await finish(tester);
    });

    testWidgets('"Azzera" toglie tutti i filtri della tab', (tester) async {
      await pumpTab(tester, AppRoutes.charts);
      container
          .read(analyticsFiltersProvider(AnalyticsTab.charts).notifier)
          .apply(
            TransactionFilters(walletIds: {walletIds['Contanti']!}, categoryIds: {categoryIds['expense:Ristoranti']!}),
          );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Filtri, 2 attivi'), findsOneWidget);
      expect(find.bySemanticsLabel('Rimuovi filtro Ristoranti'), findsOneWidget);
      await tester.tap(find.text('Azzera'));
      await tester.pumpAndSettle();
      expect(container.read(analyticsFiltersProvider(AnalyticsTab.charts)), const TransactionFilters());
      await finish(tester);
    });

    testWidgets('selettore Giorno/Sett./Mese/Anno/Periodo come in Movimenti', (tester) async {
      await pumpTab(tester, AppRoutes.charts);
      await tester.tap(find.text('Anno'));
      await tester.pumpAndSettle();
      expect(container.read(chartsPeriodProvider).type, PeriodType.year);
      expect(find.text('2026'), findsOneWidget);
      expect(find.text('€ 908,70'), findsOneWidget, reason: 'tutte le spese del 2026');

      await tester.tap(find.byTooltip('Periodo precedente'));
      await tester.pumpAndSettle();
      expect(container.read(chartsPeriodProvider).start, LocalDate(2025, 1, 1));

      await tester.tap(find.text('Periodo'));
      await tester.pumpAndSettle();
      expect(container.read(chartsPeriodProvider).type, PeriodType.custom);
      expect(find.text('Dal'), findsOneWidget);
      await tester.tap(find.text('Ultimi 30 gg'));
      await tester.pumpAndSettle();
      expect(container.read(chartsPeriodProvider).range, DateRange(LocalDate(2026, 9, 4), LocalDate(2026, 10, 3)));
      expect(container.read(selectedPeriodProvider).type, PeriodType.month, reason: 'Movimenti ha il suo periodo');
      await finish(tester);
    });

    testWidgets('tap su una fetta: Movimenti con periodo, tipo, voce toccata e filtri del grafico', (tester) async {
      await pumpTab(tester, AppRoutes.charts);
      await filterBy(tester, 'Contanti');

      await tester.tap(find.bySemanticsLabel(RegExp('^Ristoranti, .*mostra i movimenti')));
      await tester.pumpAndSettle();
      expect(find.byType(TransactionsScreen), findsOneWidget);
      final filters = container.read(activeFiltersProvider);
      expect(filters.type, TypeFilter.expense);
      expect(filters.categoryIds, {categoryIds['expense:Ristoranti']});
      expect(filters.walletIds, {walletIds['Contanti']});
      expect(container.read(selectedPeriodProvider), container.read(chartsPeriodProvider));
      expect(find.text('$_minus € 4,50'), findsWidgets);
      await finish(tester);
    });
  });

  group('Confronta', () {
    testWidgets('i filtri valgono per barre, linee, totali e tabella delle variazioni', (tester) async {
      await pumpTab(tester, AppRoutes.compare);
      List<int> totals() => [for (final p in container.read(comparisonProvider).value!) p.total(CompareMetric.expense)];
      expect(totals(), [6870, 80000, 4000]);

      await filterBy(tester, 'Contanti');
      expect(find.byTooltip('Filtri, 1 attivi'), findsOneWidget);
      expect(find.bySemanticsLabel('Rimuovi filtro Contanti'), findsOneWidget);
      expect(totals(), [450, 5000, 0]);
      final data = container.read(comparisonProvider).value!;
      expect(data.first.cumulative.last, 450, reason: 'linee cumulate filtrate');
      expect(data[1].byCategory, {categoryIds['expense:Spesa alimentare']: 5000}, reason: 'tabella per categoria');
      expect(container.read(analyticsFiltersProvider(AnalyticsTab.charts)).isActive, isFalse);
      await finish(tester);
    });
  });
}

const _minus = '−';
