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
import 'package:spese_entrate/core/widgets/fading_scroll_view.dart';
import 'package:spese_entrate/data/db/app_database.dart';
import 'package:spese_entrate/data/db/database_provider.dart';
import 'package:spese_entrate/data/repositories/repository_providers.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/label.dart';
import 'package:spese_entrate/domain/models/transaction.dart';
import 'package:spese_entrate/features/transactions/presentation/quick_add_screen.dart';
import 'package:spese_entrate/features/transactions/presentation/transactions_screen.dart';

void main() {
  setUpAll(() => initializeDateFormatting('it_IT'));

  late ProviderContainer container;

  Future<void> pumpHome(WidgetTester tester) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = AppDatabase(NativeDatabase.memory(), now: () => DateTime.utc(2026, 10, 10, 8));
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 10, 9)),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    await tester.runAsync(
      () => container.read(labelRepositoryProvider).save(Label(id: newId(), name: 'casa', color: 0xFF000000)),
    );
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const App()));
    await tester.pumpAndSettle();
  }

  Future<List<Transaction>> storedTransactions(WidgetTester tester) async =>
      (await tester.runAsync(() => container.read(transactionRepositoryProvider).watchAll().first))!;

  Future<void> typeAmount(WidgetTester tester, String digits) async {
    for (final digit in digits.split('')) {
      await tester.tap(find.descendant(of: find.byType(QuickAddScreen), matching: find.text(digit)));
      await tester.pump();
    }
  }

  testWidgets('spesa completa: importo, categoria, label, portafoglio, data e nota', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.text('Spesa'));
    await tester.pumpAndSettle();

    expect(find.byType(QuickAddScreen), findsOneWidget);
    expect(find.text('Conto corrente'), findsOneWidget, reason: 'portafoglio predefinito per le spese');
    expect(find.text('Oggi'), findsOneWidget);

    await typeAmount(tester, '6420');
    expect(find.text('64,20'), findsOneWidget);

    // Senza categoria non salva.
    await tester.tap(find.text('Salva spesa'));
    await tester.pumpAndSettle();
    expect(find.text('Scegli una categoria'), findsOneWidget);
    expect(await storedTransactions(tester), isEmpty);

    await tester.tap(find.text('Spesa alimentare'));
    await tester.tap(find.text('#casa'));
    await tester.pump();

    await tester.tap(find.bySemanticsLabel(RegExp('^Portafoglio: ')));
    await tester.pumpAndSettle();
    expect(find.text('Paga da'), findsOneWidget);
    await tester.tap(find.text('Contanti'));
    await tester.pumpAndSettle();
    expect(find.text('Contanti'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(RegExp('^Data del movimento: ')));
    await tester.pumpAndSettle();
    expect(find.text('Ottobre 2026'), findsOneWidget);
    await tester.tap(find.text('Ieri'));
    await tester.tap(find.text('Conferma'));
    await tester.pumpAndSettle();
    expect(find.text('Ieri'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Esselunga');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salva spesa'));
    await tester.pumpAndSettle();

    expect(find.byType(QuickAddScreen), findsNothing);
    expect(find.byType(TransactionsScreen), findsOneWidget);
    expect(find.text('Spesa di € 64,20 salvata'), findsOneWidget);

    final saved = (await storedTransactions(tester)).single;
    final cash = (await tester.runAsync(() => container.read(walletRepositoryProvider).watchAll().first))!
        .firstWhere((w) => w.name == 'Contanti');
    expect(saved.type, TransactionType.expense);
    expect(saved.amountCents, 6420);
    expect(saved.walletId, cash.id);
    expect(saved.date, LocalDate(2026, 10, 9));
    expect(saved.labelIds, hasLength(1));
    expect(saved.note, 'Esselunga');
  });

  testWidgets('+ Entrata apre il tipo entrata con le sue categorie', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.text('Entrata'));
    await tester.pumpAndSettle();

    expect(find.text('Salva entrata'), findsOneWidget);
    expect(find.text('Stipendio'), findsOneWidget);
    expect(find.text('Spesa alimentare'), findsNothing);

    // Senza importo non salva.
    await tester.tap(find.text('Stipendio'));
    await tester.tap(find.text('Salva entrata'));
    await tester.pumpAndSettle();
    expect(find.text('Inserisci un importo'), findsOneWidget);

    await typeAmount(tester, '185000');
    await tester.tap(find.text('Salva entrata'));
    await tester.pumpAndSettle();

    expect(find.text('Entrata di € 1.850,00 salvata'), findsOneWidget);
    expect((await storedTransactions(tester)).single.type, TransactionType.income);
  });

  testWidgets('cambiando in Entrata compaiono le categorie di entrata', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.text('Spesa'));
    await tester.pumpAndSettle();

    await tester.tap(find.descendant(of: find.byType(QuickAddScreen), matching: find.text('Entrata')));
    await tester.pumpAndSettle();
    expect(find.text('Freelance'), findsOneWidget);
    expect(find.text('Trasporti'), findsNothing);
    expect(find.text('Salva entrata'), findsOneWidget);
  });

  testWidgets('chiudere senza salvare non crea nulla', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.text('Spesa'));
    await tester.pumpAndSettle();
    await typeAmount(tester, '100');

    await tester.tap(find.byTooltip('Chiudi'));
    await tester.pumpAndSettle();
    expect(find.byType(QuickAddScreen), findsNothing);
    expect(await storedTransactions(tester), isEmpty);
  });

  testWidgets('dissolvenza: niente con le liste compatte, in basso con "Tutte", in alto in fondo', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.text('Spesa'));
    await tester.pumpAndSettle();
    FadingScrollViewState fade() => tester.state(find.byType(FadingScrollView));
    expect((fade().fadeTop, fade().fadeBottom), (false, false), reason: 'tutto sta nell\'area');

    await tester.tap(find.text('Tutte (2)'));
    await tester.pumpAndSettle();
    expect((fade().fadeTop, fade().fadeBottom), (false, true), reason: 'la lista espansa esce dall\'area');

    await tester.drag(find.byType(FadingScrollView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect((fade().fadeTop, fade().fadeBottom), (true, false), reason: 'in fondo: solo in alto');

    // Cambio Spesa/Entrata: le categorie di entrata sono 5, tutto torna nell'area.
    await tester.drag(find.byType(FadingScrollView), const Offset(0, 1000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrata'));
    await tester.pumpAndSettle();
    expect((fade().fadeTop, fade().fadeBottom), (false, false));
  });
}
