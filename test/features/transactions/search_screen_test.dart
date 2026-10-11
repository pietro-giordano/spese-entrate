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
import 'package:spese_entrate/data/db/app_database.dart';
import 'package:spese_entrate/data/db/database_provider.dart';
import 'package:spese_entrate/data/repositories/repository_providers.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/transaction.dart';
import 'package:spese_entrate/domain/models/transaction_filters.dart';
import 'package:spese_entrate/features/transactions/application/search_providers.dart';
import 'package:spese_entrate/features/transactions/application/transaction_list_providers.dart';

void main() {
  setUpAll(() => initializeDateFormatting('it_IT'));
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late ProviderContainer container;

  /// Oggi è il 3 ottobre 2026. Esselunga di oggi (64,20), Caffè di agosto 2025 (1,50, contanti),
  /// stipendio di ottobre.
  Future<void> pumpHome(WidgetTester tester) async {
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
      final wallets = {for (final w in await db.select(db.wallets).get()) w.name: w.id};
      final categories = {for (final c in await db.select(db.categories).get()) '${c.kind.name}:${c.name}': c.id};
      final repo = container.read(transactionRepositoryProvider);
      for (final tx in [
        Transaction(
          id: newId(),
          type: TransactionType.expense,
          amountCents: 6420,
          date: LocalDate(2026, 10, 3),
          walletId: wallets['Conto corrente']!,
          categoryId: categories['expense:Spesa alimentare'],
          note: 'Esselunga',
        ),
        Transaction(
          id: newId(),
          type: TransactionType.expense,
          amountCents: 150,
          date: LocalDate(2025, 8, 20),
          walletId: wallets['Contanti']!,
          categoryId: categories['expense:Ristoranti'],
          note: 'Caffè al bar',
        ),
        Transaction(
          id: newId(),
          type: TransactionType.income,
          amountCents: 240000,
          date: LocalDate(2026, 10, 1),
          walletId: wallets['Conto corrente']!,
          categoryId: categories['income:Stipendio'],
        ),
      ]) {
        await repo.save(tx);
      }
    });
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const App()));
    await tester.pumpAndSettle();
  }

  Future<void> finish(WidgetTester tester) => tester.pump(const Duration(milliseconds: 10));

  /// Scrive [text], aspetta il debounce e lascia lavorare il database.
  Future<void> typeQuery(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump(const Duration(milliseconds: 310));
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  testWidgets('cerca apre il campo; suggerimento iniziale; periodo e riepilogo nascosti', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.byTooltip('Cerca'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Cerca in tutto lo storico'), findsOneWidget);
    expect(find.text('Ottobre 2026'), findsNothing);
    expect(find.text('Saldo del periodo'), findsNothing);
    await finish(tester);
  });

  testWidgets('debounce di 300 ms, poi risultati su tutto lo storico senza accenti', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.byTooltip('Cerca'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'caffe');
    await tester.pump(const Duration(milliseconds: 250));
    expect(container.read(transactionSearchProvider).query, '', reason: 'prima dei 300 ms non si cerca');
    await typeQuery(tester, 'caffe');
    expect(container.read(transactionSearchProvider).query, 'caffe');

    expect(find.text('1 risultato · − € 1,50'), findsOneWidget);
    expect(find.textContaining('AGOSTO 2025'), findsOneWidget, reason: 'fuori dal mese selezionato');
    expect(find.text('Caffè al bar'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('per importo e per portafoglio, con totale dei risultati', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.byTooltip('Cerca'));
    await tester.pumpAndSettle();
    await typeQuery(tester, '64,20');
    expect(find.text('Esselunga'), findsOneWidget);
    expect(find.text('1 risultato · − € 64,20'), findsOneWidget);

    await typeQuery(tester, 'conto corrente');
    expect(find.text('2 risultati · + € 2.335,80'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('i filtri attivi valgono anche nella ricerca; nessun risultato con "Azzera filtri"', (tester) async {
    await pumpHome(tester);
    container.read(activeFiltersProvider.notifier).apply(const TransactionFilters(type: TypeFilter.income));
    await tester.tap(find.byTooltip(RegExp('^Cerca')));
    await tester.pumpAndSettle();
    await typeQuery(tester, 'esselunga');
    expect(find.text('Nessun risultato per «esselunga»'), findsOneWidget);
    expect(find.text('Prova con un\'altra parola o togli i filtri attivi.'), findsOneWidget);

    await tester.tap(find.text('Azzera filtri'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    expect(find.text('Esselunga'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('chiudere (pulsante o indietro) torna alla lista del periodo e dimentica il testo', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.byTooltip('Cerca'));
    await tester.pumpAndSettle();
    await typeQuery(tester, 'caffe');
    await tester.tap(find.byTooltip('Chiudi ricerca'));
    await tester.pumpAndSettle();
    expect(find.text('Ottobre 2026'), findsOneWidget);
    expect(find.text('Caffè al bar'), findsNothing, reason: 'agosto 2025 non è nel mese');
    expect(container.read(transactionSearchProvider).query, '');

    await tester.tap(find.byTooltip('Cerca'));
    await tester.pumpAndSettle();
    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(handled, isTrue);
    expect(container.read(transactionSearchProvider).open, isFalse);
    expect(find.text('Ottobre 2026'), findsOneWidget);
    await finish(tester);
  });
}
