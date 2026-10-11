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
import 'package:spese_entrate/core/widgets/app_segmented.dart';
import 'package:spese_entrate/data/db/app_database.dart';
import 'package:spese_entrate/data/db/database_provider.dart';
import 'package:spese_entrate/data/repositories/repository_providers.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/label.dart';
import 'package:spese_entrate/domain/models/transaction.dart';
import 'package:spese_entrate/domain/models/transaction_filters.dart';
import 'package:spese_entrate/features/analytics/application/compare_providers.dart';
import 'package:spese_entrate/features/analytics/presentation/compare_screen.dart';
import 'package:spese_entrate/features/analytics/presentation/widgets/compare_charts.dart';
import 'package:spese_entrate/features/transactions/application/transaction_list_providers.dart';
import 'package:spese_entrate/features/transactions/presentation/filters_screen.dart';
import 'package:spese_entrate/features/transactions/presentation/transactions_screen.dart';

void main() {
  setUpAll(() => initializeDateFormatting('it_IT'));
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late ProviderContainer container;

  /// Oggi è il 3 ottobre 2026. Ottobre: spese 64,20 (#casa) + 4,50, stipendio 2.400,
  /// più trasferimento, rettifica e pending che non devono contare. Settembre: 50 + 750. Agosto: 40.
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
      final wallets = await container.read(walletRepositoryProvider).watchAll().first;
      final categories = await container.read(categoryRepositoryProvider).watchAll().first;
      final home = Label(id: newId(), name: 'casa', color: 0xFF1D4ED8);
      await container.read(labelRepositoryProvider).save(home);
      String category(String name) => categories.firstWhere((c) => c.name == name).id;
      final cc = wallets.first.id;
      final cash = wallets.last.id;
      Transaction t(
        TransactionType type,
        int cents,
        LocalDate date, {
        String? cat,
        List<String> labels = const [],
        TransactionStatus status = TransactionStatus.confirmed,
      }) => Transaction(
        id: newId(),
        type: type,
        status: status,
        amountCents: cents,
        date: date,
        walletId: cc,
        toWalletId: type == TransactionType.transfer ? cash : null,
        categoryId: cat == null ? null : category(cat),
        labelIds: labels,
      );
      final repo = container.read(transactionRepositoryProvider);
      for (final tx in [
        t(TransactionType.expense, 6420, LocalDate(2026, 10, 3), cat: 'Spesa alimentare', labels: [home.id]),
        t(TransactionType.expense, 450, LocalDate(2026, 10, 2), cat: 'Ristoranti'),
        t(TransactionType.income, 240000, LocalDate(2026, 10, 1), cat: 'Stipendio'),
        t(TransactionType.transfer, 50000, LocalDate(2026, 10, 1)),
        t(TransactionType.adjustment, -9000, LocalDate(2026, 10, 1)),
        t(TransactionType.expense, 99900, LocalDate(2026, 10, 2), cat: 'Casa', status: TransactionStatus.pending),
        t(TransactionType.expense, 5000, LocalDate(2026, 9, 10), cat: 'Spesa alimentare'),
        t(TransactionType.expense, 75000, LocalDate(2026, 9, 1), cat: 'Casa'),
        t(TransactionType.expense, 4000, LocalDate(2026, 8, 20), cat: 'Spesa alimentare'),
      ]) {
        await repo.save(tx);
      }
    });

    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const App()));
    await tester.pumpAndSettle();
    container.read(appRouterProvider).go(location);
    await tester.pumpAndSettle();
  }

  group('Grafici', () {
    testWidgets('spese del mese per categoria, senza trasferimenti, rettifiche e pending', (tester) async {
      await pumpTab(tester, AppRoutes.charts);

      expect(find.text('Ottobre 2026'), findsOneWidget);
      expect(find.text('Totale spese'), findsOneWidget);
      expect(find.text('€ 68,70'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Spesa alimentare, 93,4%, € 64,20')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Ristoranti, 6,6%, € 4,50')), findsOneWidget);
      expect(find.text('Casa'), findsNothing, reason: 'la spesa pending non conta');
    });

    testWidgets('entrate e mese precedente', (tester) async {
      await pumpTab(tester, AppRoutes.charts);
      await tester.tap(find.descendant(of: find.byType(AppSegmented<CategoryKind>), matching: find.text('Entrate')));
      await tester.pumpAndSettle();
      expect(find.text('Totale entrate'), findsOneWidget);
      expect(find.text('Stipendio'), findsOneWidget);

      await tester.tap(find.descendant(of: find.byType(AppSegmented<CategoryKind>), matching: find.text('Spese')));
      await tester.tap(find.byTooltip('Periodo precedente'));
      await tester.pumpAndSettle();
      expect(find.text('Settembre 2026'), findsOneWidget);
      expect(find.text('€ 800,00'), findsOneWidget);
    });

    testWidgets('per label: nota sulle percentuali e voce "Senza label"', (tester) async {
      await pumpTab(tester, AppRoutes.charts);
      await tester.tap(find.text('Label'));
      await tester.pumpAndSettle();

      expect(find.textContaining('le percentuali sono calcolate sulla somma delle label'), findsOneWidget);
      expect(find.text('#casa'), findsOneWidget);
      expect(find.text('Senza label'), findsOneWidget);
    });

    testWidgets('toccando una categoria si apre la lista filtrata', (tester) async {
      await pumpTab(tester, AppRoutes.charts);
      await tester.tap(find.text('Ristoranti'));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionsScreen), findsOneWidget);
      expect(container.read(activeFiltersProvider).type, TypeFilter.expense);
      expect(container.read(activeFiltersProvider).categoryIds, hasLength(1));
      expect(find.byTooltip('Filtri, 2 attivi'), findsOneWidget);
      expect(find.text('Ottobre 2026'), findsOneWidget);
      expect(find.text('Spesa alimentare'), findsNothing);
      expect(find.text('Ristoranti'), findsOneWidget);
    });
  });

  group('Senza label', () {
    testWidgets('dalla legenda dei Grafici: lista dei soli movimenti senza label', (tester) async {
      await pumpTab(tester, AppRoutes.charts);
      await tester.tap(find.text('Label'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Senza label'));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionsScreen), findsOneWidget);
      expect(container.read(activeFiltersProvider).withoutLabels, isTrue);
      expect(container.read(activeFiltersProvider).labelIds, isEmpty);
      expect(find.text('Ristoranti'), findsOneWidget);
      expect(find.text('Spesa alimentare'), findsNothing, reason: 'ha la label #casa');
      expect(find.text('Stipendio'), findsNothing, reason: 'il grafico era sulle spese');
    });

    testWidgets('nei Filtri: «Senza label» a tre stati, separato da «Almeno una/Tutte»', (tester) async {
      // Come nell'app: i Filtri si aprono sopra la lista (push), così "Applica" può tornare indietro.
      await pumpTab(tester, AppRoutes.transactions);
      container.read(appRouterProvider).push(AppRoutes.filters);
      await tester.pumpAndSettle();
      expect(find.byType(FiltersScreen), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Senza label'), 200, scrollable: find.byType(Scrollable).first);

      // Si possono includere entrambe, anche con «Tutte»: nessuna scelta toglie l'altra.
      await tester.tap(find.text('#casa'));
      await tester.tap(find.text('Senza label'));
      await tester.pump();
      expect(find.text('2 incluse'), findsOneWidget);
      await tester.tap(find.text('Tutte'));
      await tester.pump();
      expect(find.text('2 incluse'), findsOneWidget);
      expect(find.textContaining('valgono per le label incluse'), findsOneWidget);

      // Secondo tocco: «Senza label» escluso.
      await tester.tap(find.text('Senza label'));
      await tester.pump();
      expect(find.text('1 inclusa · 1 esclusa'), findsOneWidget);
      expect(tester.getSemantics(find.bySemanticsLabel('Senza label')).value, 'escluso');
      await tester.tap(find.text('Applica filtri'));
      await tester.pumpAndSettle();
      final filters = container.read(activeFiltersProvider);
      expect(filters.withoutLabels, isFalse);
      expect(filters.excludeWithoutLabels, isTrue);
      expect(filters.labelIds, hasLength(1));
      expect(filters.labelMatch, LabelMatch.all);
      expect(filters.activeCount, 1, reason: 'una sola dimensione: le label');
    });
  });

  group('Confronta', () {
    testWidgets('ultimi 3 mesi: periodi, barre e tabella delle variazioni', (tester) async {
      await pumpTab(tester, AppRoutes.compare);

      expect(find.text('Ottobre 2026'), findsOneWidget);
      expect(find.text('Settembre 2026'), findsOneWidget);
      expect(find.text('Agosto 2026'), findsOneWidget);
      expect(find.byType(CompareBarChart), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Totale'), 200, scrollable: find.byType(Scrollable).first);
      // Totale spese: 69 € (68,70) a ottobre contro 800 € a settembre → −91,4%.
      expect(find.text('69'), findsOneWidget);
      expect(find.text('800'), findsOneWidget);
      expect(find.text('−91,4%'), findsOneWidget);
      expect(find.text('Casa'), findsWidgets, reason: 'categoria presente solo a settembre (tabella e barre)');
      expect(find.text('—'), findsWidgets, reason: 'Ristoranti: nessun riferimento a settembre');
    });

    testWidgets('avviso: periodo non concluso e durate diverse, importi assoluti', (tester) async {
      await pumpTab(tester, AppRoutes.compare);
      expect(
        find.text(
          'Ottobre 2026 non è ancora concluso. I periodi hanno durate diverse. '
          'Il confronto usa importi assoluti, senza normalizzare per giorno.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('nessun avviso con periodi conclusi della stessa durata', (tester) async {
      await pumpTab(tester, AppRoutes.compare);
      final controller = container.read(compareControllerProvider.notifier);
      for (final period in [...container.read(compareControllerProvider).periods]) {
        controller.removePeriod(period);
      }
      // Resta un solo periodo (ottobre, in corso): lo si sostituisce con agosto e agosto 2025.
      controller
        ..addPeriod(Period.containing(PeriodType.month, LocalDate(2026, 8, 1)))
        ..addPeriod(Period.containing(PeriodType.month, LocalDate(2025, 8, 1)))
        ..removePeriod(container.read(compareControllerProvider).periods.first);
      await tester.pumpAndSettle();
      expect(find.textContaining('importi assoluti'), findsNothing);
    });

    testWidgets('saldo e linee cumulate', (tester) async {
      await pumpTab(tester, AppRoutes.compare);
      await tester.tap(find.text('Saldo'));
      await tester.pumpAndSettle();
      expect(find.text('Entrate, uscite e saldo (€)'), findsOneWidget);

      await tester.tap(find.text('Linee'));
      await tester.pumpAndSettle();
      expect(find.byType(CompareLineChart), findsOneWidget);
      expect(find.text('Saldo cumulato, giorno per giorno (€)'), findsOneWidget);
    });

    testWidgets('preset, rimozione e aggiunta di un periodo', (tester) async {
      await pumpTab(tester, AppRoutes.compare);

      // I preset sono in una fila che scorre in orizzontale: "Anno vs anno" va portato a schermo.
      await tester.ensureVisible(find.text('Anno vs anno'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anno vs anno'));
      await tester.pumpAndSettle();
      expect(find.text('2026'), findsWidgets);
      expect(find.text('2025'), findsWidgets);

      await tester.tap(find.byTooltip('Rimuovi 2025'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Rimuovi 2026'), findsNothing, reason: 'l\'unico periodo non si può togliere');

      await tester.tap(find.text('+ Periodo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aggiungi'));
      await tester.pumpAndSettle();
      expect(find.text('Ottobre 2026'), findsOneWidget);
      expect(find.byType(CompareScreen), findsOneWidget);
    });
  });
}
