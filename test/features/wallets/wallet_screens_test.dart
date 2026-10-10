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
import 'package:spese_entrate/core/router/app_router.dart';
import 'package:spese_entrate/core/router/app_routes.dart';
import 'package:spese_entrate/data/db/app_database.dart';
import 'package:spese_entrate/data/db/database_provider.dart';
import 'package:spese_entrate/data/repositories/repository_providers.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/transaction.dart';
import 'package:spese_entrate/domain/models/wallet.dart';
import 'package:spese_entrate/features/wallets/presentation/wallet_detail_screen.dart';
import 'package:spese_entrate/features/wallets/presentation/wallet_form_screen.dart';

void main() {
  setUpAll(() => initializeDateFormatting('it_IT'));
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late ProviderContainer container;
  late Wallet etf;

  /// Conto corrente con € 1.000,00, Contanti, e un ETF fermo al 31 agosto (da aggiornare).
  Future<void> pumpWallets(WidgetTester tester) async {
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
      final wallets = container.read(walletRepositoryProvider);
      final checking = (await wallets.watchAll().first).firstWhere((w) => w.type == WalletType.checking);
      await wallets.save(checking.copyWith(initialBalanceCents: 100000));
      etf = Wallet(
        id: newId(),
        name: 'ETF',
        type: WalletType.investment,
        initialBalanceCents: 1248000,
        initialBalanceDate: LocalDate(2026, 8, 31),
        sortOrder: 2,
      );
      await wallets.save(etf);
    });

    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const App()));
    await tester.pumpAndSettle();
    container.read(appRouterProvider).go(AppRoutes.wallets);
    await tester.pumpAndSettle();
  }

  Future<List<Transaction>> stored(WidgetTester tester) async =>
      (await tester.runAsync(() => container.read(transactionRepositoryProvider).watchAll().first))!;

  /// Le azioni che salvano fanno più scritture in fila: pumpAndSettle si ferma quando non ci sono
  /// più animazioni, non quando il database ha finito. Qui si lascia lavorare finché [done] è vero.
  Future<void> waitFor(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 100 && !done(); i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(done(), isTrue, reason: 'operazione non completata');
  }

  bool gone(Finder finder) => finder.evaluate().isEmpty;

  Finder inDetail(Finder finder) => find.descendant(of: find.byType(WalletDetailScreen), matching: finder);

  testWidgets('tab: patrimonio per gruppi, badge e saldi', (tester) async {
    await pumpWallets(tester);

    expect(find.text('Patrimonio totale'), findsOneWidget);
    expect(find.text('€ 13.480,00'), findsOneWidget, reason: '1.000 + 0 + 12.480');
    expect(find.text('LIQUIDITÀ'), findsOneWidget);
    expect(find.text('INVESTIMENTI'), findsOneWidget);
    expect(find.text('Predefinito spese ed entrate'), findsOneWidget);
    expect(find.text('Da aggiornare'), findsOneWidget);
    expect(find.text('Aggiornato il 31 ago'), findsOneWidget);
    expect(find.text('Aggiornato oggi'), findsNWidgets(2));
  });

  testWidgets('nuovo portafoglio: nome obbligatorio, tipo, predefinito per le spese', (tester) async {
    await pumpWallets(tester);
    await tester.tap(find.byTooltip('Nuovo portafoglio'));
    await tester.pumpAndSettle();
    expect(find.byType(WalletFormScreen), findsOneWidget);

    await tester.tap(find.text('Crea portafoglio'));
    await tester.pumpAndSettle();
    expect(find.text('Inserisci un nome'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Es. Conto Banca, Portafoglio, Broker'), 'Conto deposito');
    await tester.tap(find.text('Risparmio'));
    await tester.enterText(find.widgetWithText(TextField, '0,00'), '5.000');
    await tester.tap(find.text('Predefinito per le spese'));
    await tester.pump();
    expect(find.text('Le nuove spese partiranno da qui'), findsOneWidget);

    await tester.tap(find.text('Crea portafoglio'));
    await waitFor(tester, () => gone(find.byType(WalletFormScreen)));

    expect(find.text('Portafoglio creato'), findsOneWidget);
    expect(find.text('RISPARMI'), findsOneWidget);
    expect(find.text('Conto deposito'), findsOneWidget);
    expect(find.text('Predefinito spese'), findsOneWidget);
    expect(find.text('Predefinito entrate'), findsOneWidget, reason: 'il conto corrente resta solo per le entrate');
    expect(find.text('€ 18.480,00'), findsOneWidget);
  });

  testWidgets('investimento: avviso nel form', (tester) async {
    await pumpWallets(tester);
    await tester.tap(find.byTooltip('Nuovo portafoglio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Investimenti'));
    await tester.pump();
    expect(find.textContaining('Il valore di un investimento cambia anche senza movimenti'), findsOneWidget);
  });

  testWidgets('dettaglio: Aggiorna saldo come rettifica', (tester) async {
    await pumpWallets(tester);
    await tester.tap(find.text('ETF'));
    await tester.pumpAndSettle();

    expect(inDetail(find.text('€ 12.480,00')), findsOneWidget);
    expect(inDetail(find.text('Da aggiornare')), findsOneWidget);
    expect(find.text('Andamento del saldo · ultimi 6 mesi'), findsOneWidget);

    await tester.tap(find.text('Aggiorna saldo'));
    await tester.pumpAndSettle();
    expect(find.text('Saldo registrato: € 12.480,00 · oggi'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, '12.480,00'), '12.792,40');
    await tester.pump();
    expect(find.text('+ € 312,40'), findsOneWidget);

    await tester.tap(find.text('Salva aggiornamento'));
    await waitFor(tester, () => gone(find.text('Salva aggiornamento')));

    expect(find.text('Saldo aggiornato'), findsOneWidget);
    expect(inDetail(find.text('€ 12.792,40')), findsOneWidget);
    expect(inDetail(find.text('Aggiornato oggi')), findsOneWidget);
    expect(inDetail(find.text('Da aggiornare')), findsNothing);
    expect(find.text('Rettifica di valore'), findsOneWidget);
    expect(find.text('3 ott · aggiornamento saldo'), findsOneWidget);

    final adjustment = (await stored(tester)).single;
    expect((adjustment.type, adjustment.amountCents), (TransactionType.adjustment, 31240));
  });

  testWidgets('dettaglio: saldo confermato senza differenze toglie il badge senza creare movimenti', (tester) async {
    await pumpWallets(tester);
    await tester.tap(find.text('ETF'));
    await tester.pumpAndSettle();
    expect(inDetail(find.text('Da aggiornare')), findsOneWidget);

    await tester.tap(find.text('Aggiorna saldo'));
    await tester.pumpAndSettle();
    expect(find.text('€ 0,00'), findsOneWidget, reason: 'differenza');
    expect(find.textContaining('Il saldo coincide'), findsOneWidget);

    await tester.tap(find.text('Salva aggiornamento'));
    await waitFor(tester, () => gone(find.text('Salva aggiornamento')));

    expect(find.text('Saldo aggiornato'), findsOneWidget);
    expect(inDetail(find.text('Da aggiornare')), findsNothing);
    expect(inDetail(find.text('Aggiornato oggi')), findsOneWidget);
    expect(inDetail(find.text('€ 12.480,00')), findsOneWidget);
    expect(await stored(tester), isEmpty);
    expect(find.text('Ancora nessun movimento.'), findsOneWidget);
  });

  testWidgets('dettaglio: Aggiorna saldo come movimento chiede la categoria', (tester) async {
    await pumpWallets(tester);
    await tester.tap(find.text('Contanti'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aggiorna saldo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '0,00'), '20');
    await tester.tap(find.text('Registra come entrata o spesa'));
    await tester.pump();
    expect(find.text('CATEGORIA DELL\'ENTRATA'), findsOneWidget);

    await tester.tap(find.text('Salva aggiornamento'));
    await tester.pump();
    expect(find.text('Scegli una categoria'), findsOneWidget);

    await tester.tap(find.text('Regali'));
    await tester.tap(find.text('Salva aggiornamento'));
    await waitFor(tester, () => gone(find.text('Salva aggiornamento')));

    final income = (await stored(tester)).single;
    expect((income.type, income.amountCents, income.note), (TransactionType.income, 2000, 'Aggiornamento saldo'));
    expect(inDetail(find.text(formatCents(2000))), findsOneWidget);
  });

  testWidgets('modifica: archivia e annulla', (tester) async {
    await pumpWallets(tester);
    await tester.tap(find.text('ETF'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Modifica portafoglio'));
    await tester.pumpAndSettle();
    expect(find.text('Modifica portafoglio'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Archivia portafoglio'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Archivia portafoglio'));
    await waitFor(tester, () => gone(find.byType(WalletFormScreen)));

    expect(find.text('"ETF" archiviato'), findsOneWidget);
    expect(find.text('INVESTIMENTI'), findsNothing);
    expect(find.text('€ 1.000,00'), findsWidgets);
    await tester.scrollUntilVisible(find.text('ARCHIVIATI'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Archiviato'), findsOneWidget);

    await tester.tap(find.text('Annulla'));
    await waitFor(tester, () => gone(find.text('ARCHIVIATI')));
  });
}
