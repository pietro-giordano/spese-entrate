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
import 'package:spese_entrate/core/money.dart';
import 'package:spese_entrate/core/widgets/app_segmented.dart';
import 'package:spese_entrate/data/db/app_database.dart';
import 'package:spese_entrate/data/db/database_provider.dart';
import 'package:spese_entrate/data/repositories/repository_providers.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/transaction.dart';
import 'package:spese_entrate/domain/models/transaction_filters.dart';
import 'package:spese_entrate/features/transactions/application/transaction_list_providers.dart';
import 'package:spese_entrate/features/transactions/presentation/filters_screen.dart';

void main() {
  setUpAll(() => initializeDateFormatting('it_IT'));

  late ProviderContainer container;

  /// Avvia l'app il sabato 3 ottobre 2026; con [seed] inserisce movimenti simili al mockup.
  Future<void> pumpHome(WidgetTester tester, {bool seed = true}) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
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

    if (seed) {
      await tester.runAsync(() async {
        final wallets = await container.read(walletRepositoryProvider).watchAll().first;
        final categories = await container.read(categoryRepositoryProvider).watchAll().first;
        String wallet(String name) => wallets.firstWhere((w) => w.name == name).id;
        String category(String name, CategoryKind kind) =>
            categories.firstWhere((c) => c.name == name && c.kind == kind).id;
        Transaction t(
          TransactionType type,
          int cents,
          LocalDate date, {
          String walletName = 'Conto corrente',
          String? toWalletName,
          String? categoryName,
          String? note,
          TransactionStatus status = TransactionStatus.confirmed,
        }) => Transaction(
          id: newId(),
          type: type,
          status: status,
          amountCents: cents,
          date: date,
          walletId: wallet(walletName),
          toWalletId: toWalletName == null ? null : wallet(toWalletName),
          categoryId: categoryName == null
              ? null
              : category(categoryName, type == TransactionType.income ? CategoryKind.income : CategoryKind.expense),
          note: note,
        );

        final repo = container.read(transactionRepositoryProvider);
        for (final tx in [
          t(TransactionType.expense, 6420, LocalDate(2026, 10, 3), categoryName: 'Spesa alimentare', note: 'Esselunga'),
          t(TransactionType.expense, 450, LocalDate(2026, 10, 3), categoryName: 'Ristoranti', walletName: 'Contanti'),
          t(TransactionType.income, 240000, LocalDate(2026, 10, 2), categoryName: 'Stipendio'),
          t(TransactionType.expense, 75000, LocalDate(2026, 10, 1), categoryName: 'Casa', note: 'Affitto'),
          t(TransactionType.transfer, 50000, LocalDate(2026, 10, 1), toWalletName: 'Contanti'),
          t(
            TransactionType.expense,
            9999,
            LocalDate(2026, 10, 2),
            categoryName: 'Casa',
            status: TransactionStatus.pending,
          ),
          t(TransactionType.expense, 1000, LocalDate(2026, 9, 15), categoryName: 'Svago'),
        ]) {
          await repo.save(tx);
        }
      });
    }

    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const App()));
    await tester.pumpAndSettle();
  }

  Future<void> openFilters(WidgetTester tester) async {
    await tester.tap(find.byTooltip(RegExp('^Filtri')));
    await tester.pumpAndSettle();
    expect(find.byType(FiltersScreen), findsOneWidget);
  }

  Future<void> applyFilters(WidgetTester tester) async {
    await tester.tap(find.text('Applica filtri'));
    await tester.pumpAndSettle();
  }

  testWidgets('stato vuoto nel mese corrente', (tester) async {
    await pumpHome(tester, seed: false);

    expect(find.text('Ottobre 2026'), findsOneWidget);
    expect(find.text('Nessun movimento nel periodo'), findsOneWidget);
    expect(find.text('€ 0,00'), findsNWidgets(3));
  });

  testWidgets('riepilogo e lista per giorno del mese', (tester) async {
    await pumpHome(tester);

    // 2.400,00 − (64,20 + 4,50 + 750,00); il pending e il trasferimento non contano.
    expect(find.text('+ € 1.581,30'), findsOneWidget);
    expect(find.text('Hai speso il 34% delle entrate'), findsOneWidget);
    expect(find.text('Tutti i portafogli'), findsOneWidget);

    expect(find.text('OGGI · SAB 3 OTTOBRE'), findsOneWidget);
    expect(find.text('$minusSign € 68,70'), findsOneWidget);
    expect(find.text('IERI · VEN 2 OTTOBRE'), findsOneWidget);
    expect(find.text('+ € 2.400,00'), findsNWidgets(2), reason: 'totale del giorno e riga');

    await tester.scrollUntilVisible(find.text('Conto corrente → Contanti'), 200);
    expect(find.text('Trasferimento'), findsOneWidget);
    expect(find.text('€ 500,00'), findsOneWidget, reason: 'trasferimento senza segno');
    expect(find.text('Esselunga'), findsOneWidget);
    expect(find.text('Spesa alimentare · Conto corrente'), findsOneWidget);
    expect(find.text('$minusSign € 99,99'), findsNothing, reason: 'i pending non sono nella lista');
    expect(find.text('Svago'), findsNothing, reason: 'settembre è fuori periodo');
  });

  testWidgets('frecce e selettore cambiano il periodo', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.byTooltip('Periodo precedente'));
    await tester.pumpAndSettle();
    expect(find.text('Settembre 2026'), findsOneWidget);
    expect(find.text('Svago'), findsOneWidget);
    expect(find.text('Esselunga'), findsNothing);

    await tester.tap(find.byTooltip('Periodo successivo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Giorno'));
    await tester.pumpAndSettle();
    expect(find.text('Sabato 3 ottobre'), findsOneWidget);
    expect(find.text('Esselunga'), findsOneWidget);
    expect(find.text('Stipendio'), findsNothing);
  });

  testWidgets('filtro Spese: badge sull\'icona, entrate nascoste, Azzera', (tester) async {
    await pumpHome(tester);
    await openFilters(tester);

    await tester.tap(find.descendant(of: find.byType(AppSegmented<TypeFilter>), matching: find.text('Spese')));
    await tester.pump();
    await applyFilters(tester);

    expect(find.byTooltip('Filtri, 1 attivi'), findsOneWidget);
    expect(find.text('Stipendio'), findsNothing);
    expect(container.read(activeFiltersProvider).type, TypeFilter.expense);

    await openFilters(tester);
    await tester.tap(find.text('Azzera'));
    await tester.pump();
    await applyFilters(tester);
    expect(find.byTooltip('Filtri'), findsOneWidget);
    expect(find.text('Stipendio'), findsOneWidget);
  });

  testWidgets('chiudere i filtri senza applicare scarta le modifiche', (tester) async {
    await pumpHome(tester);
    await openFilters(tester);
    await tester.tap(find.descendant(of: find.byType(AppSegmented<TypeFilter>), matching: find.text('Entrate')));
    await tester.pump();
    await tester.tap(find.byTooltip('Chiudi'));
    await tester.pumpAndSettle();

    expect(container.read(activeFiltersProvider), const TransactionFilters());
    expect(find.text('Esselunga'), findsOneWidget);
  });

  testWidgets('filtro portafoglio dal chip del riepilogo', (tester) async {
    await pumpHome(tester);
    // Il chip è un pulsante a sé anche per lo screen reader (Semantics con container: true).
    await tester.tap(find.bySemanticsLabel('Tutti i portafogli, cambia filtro portafogli'));
    await tester.pumpAndSettle();

    await tester.tap(find.descendant(of: find.byType(FiltersScreen), matching: find.text('Contanti')));
    await tester.pump();
    expect(find.text('1 SELEZIONATO'), findsNothing, reason: 'il conteggio non è in maiuscolo');
    expect(find.text('1 selezionato'), findsOneWidget);
    await applyFilters(tester);

    expect(find.text('Contanti'), findsWidgets);
    expect(find.text('Ristoranti'), findsOneWidget);
    expect(find.text('Esselunga'), findsNothing);
    await tester.scrollUntilVisible(find.text('Conto corrente → Contanti'), 200);
    // Il 1° ottobre per Contanti c'è solo il trasferimento: nessun totale del giorno.
    expect(find.text('GIO 1 OTTOBRE'), findsOneWidget);
    expect(find.text('€ 0,00'), findsOneWidget, reason: 'solo le Entrate del riepilogo');
  });

  testWidgets('periodo personalizzato con scorciatoia', (tester) async {
    await pumpHome(tester);
    await openFilters(tester);

    await tester.tap(find.descendant(of: find.byType(FiltersScreen), matching: find.text('Periodo')));
    await tester.pumpAndSettle();
    expect(find.text('Dal'), findsOneWidget);
    await tester.tap(find.text('Ultimi 30 gg'));
    await tester.pump();
    expect(find.text('04/09/2026'), findsOneWidget);
    await applyFilters(tester);

    expect(find.text('4 set – 3 ott 2026'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Svago'), 200);
  });
}
