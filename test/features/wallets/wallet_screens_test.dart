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
import 'package:spese_entrate/domain/models/local_preferences.dart';
import 'package:spese_entrate/features/settings/application/settings_providers.dart';
import 'package:spese_entrate/features/wallets/application/balance_visibility.dart';
import 'package:spese_entrate/features/wallets/presentation/wallet_detail_screen.dart';
import 'package:spese_entrate/features/wallets/presentation/wallet_form_screen.dart';
import 'package:spese_entrate/features/wallets/presentation/widgets/balance_chart.dart';

void main() {
  setUpAll(() => initializeDateFormatting('it_IT'));
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late ProviderContainer container;
  late Wallet etf;

  /// Ora del telefono: i test del ritorno in primo piano la spostano in avanti.
  late DateTime now;

  /// Conto corrente con € 1.000,00, Contanti, e un ETF fermo al 31 agosto (da aggiornare).
  Future<void> pumpWallets(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = AppDatabase(NativeDatabase.memory(), now: () => DateTime.utc(2026, 10, 3, 8));
    now = DateTime(2026, 10, 3, 9);
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db), clockProvider.overrideWithValue(() => now)],
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
    // scrollUntilVisible si ferma appena il pulsante esiste: va portato fuori da sotto la barra in basso.
    await tester.ensureVisible(find.text('Archivia portafoglio'));
    await tester.pumpAndSettle();
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

  group('saldi nascosti', () {
    /// Il testo compare almeno una volta in modo visibile (un BalanceText nascosto lo tiene
    /// invisibile solo per occupare lo spazio).
    bool shown(WidgetTester tester, String text) => find.text(text).evaluate().any((element) {
      final hiders = find.ancestor(of: find.byElementPredicate((e) => e == element), matching: find.byType(Visibility));
      return tester.widgetList<Visibility>(hiders).every((v) => v.visible);
    });

    testWidgets('l\'occhio nasconde patrimonio, gruppi e saldi in tutta l\'app, non gli importi dei movimenti', (
      tester,
    ) async {
      await pumpWallets(tester);
      await tester.runAsync(() async {
        final checking = (await container.read(walletRepositoryProvider).watchAll().first).firstWhere(
          (w) => w.type == WalletType.checking,
        );
        await container
            .read(transactionRepositoryProvider)
            .save(
              Transaction(
                id: newId(),
                type: TransactionType.expense,
                amountCents: 6420,
                date: LocalDate(2026, 10, 3),
                walletId: checking.id,
                categoryId: (await container.read(categoryRepositoryProvider).watchAll().first).first.id,
              ),
            );
      });
      await tester.pumpAndSettle();
      expect(shown(tester, '€ 13.415,80'), isTrue, reason: '1.000 − 64,20 + 12.480');

      await tester.tap(find.byTooltip('Nascondi saldi'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Mostra saldi'), findsOneWidget);
      expect(shown(tester, '€ 13.415,80'), isFalse);
      expect(shown(tester, '€ 935,80'), isFalse, reason: 'saldo del conto e totale Liquidità');
      expect(shown(tester, '€ 12.480,00'), isFalse);
      expect(find.text('€ ••••'), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Saldo nascosto')), findsWidgets);
      // Stessa larghezza: il segnaposto occupa lo spazio dell'importo vero.
      expect(
        tester.getSize(find.ancestor(of: find.text('€ 13.415,80'), matching: find.byType(Stack)).first).width,
        tester.getSize(find.text('€ 13.415,80')).width,
      );

      // Movimenti: il saldo della card è nascosto, gli importi dei movimenti no.
      container.read(appRouterProvider).go(AppRoutes.transactions);
      await tester.pumpAndSettle();
      expect(find.text('€ ••••'), findsOneWidget);
      expect(shown(tester, '− € 64,20'), isTrue, reason: 'il movimento nella lista');

      // Inserimento rapido, trasferimento: la scheda Da/A non mostra i saldi.
      container.read(appRouterProvider).push(AppRoutes.add('transfer'));
      await tester.pumpAndSettle();
      expect(find.text('Disponibile € ••••'), findsOneWidget);
      expect(find.text('Saldo € ••••'), findsOneWidget);
      // Pannello di scelta del portafoglio.
      await tester.tap(find.bySemanticsLabel(RegExp('^Da: ')));
      await tester.pumpAndSettle();
      expect(find.text('€ ••••'), findsNWidgets(3));
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      container.read(appRouterProvider).pop();
      await tester.pumpAndSettle();

      // Dettaglio portafoglio, poi di nuovo visibili.
      container.read(appRouterProvider).go(AppRoutes.wallet(etf.id));
      await tester.pumpAndSettle();
      expect(shown(tester, '€ 12.480,00'), isFalse);
      expect(find.text('€ ••••'), findsOneWidget);
      container.read(appRouterProvider).go(AppRoutes.wallets);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Mostra saldi'));
      await tester.pumpAndSettle();
      expect(shown(tester, '€ 13.415,80'), isTrue);
      expect(find.text('€ ••••'), findsNothing);
    });

    Future<void> hideBalances(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Nascondi saldi'));
      await tester.pumpAndSettle();
    }

    testWidgets('dettaglio: senza grafico dell\'andamento, con un messaggio', (tester) async {
      await pumpWallets(tester);
      await tester.tap(find.text('ETF'));
      await tester.pumpAndSettle();
      expect(find.byType(BalanceChart), findsOneWidget);

      container.read(appRouterProvider).go(AppRoutes.wallets);
      await tester.pumpAndSettle();
      await hideBalances(tester);
      await tester.tap(find.text('ETF'));
      await tester.pumpAndSettle();
      expect(find.byType(BalanceChart), findsNothing);
      expect(find.text('Andamento del saldo · ultimi 6 mesi'), findsNothing);
      expect(inDetail(find.text('Mostra i saldi per visualizzare l\'andamento')), findsOneWidget);
    });

    testWidgets('Aggiorna saldo: niente valori derivati dal saldo registrato, solo rettifica', (tester) async {
      await pumpWallets(tester);
      await hideBalances(tester);
      await tester.tap(find.text('ETF'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aggiorna saldo'));
      await tester.pumpAndSettle();

      final sheet = find.byType(BottomSheet);
      Finder inSheet(Finder finder) => find.descendant(of: sheet, matching: finder);
      final field = inSheet(find.byType(TextField));
      expect(tester.widget<TextField>(field).controller!.text, isEmpty, reason: 'il campo parte vuoto');
      expect(inSheet(find.text('Saldo registrato: € •••• · oggi')), findsOneWidget);
      expect(inSheet(find.text('€ ••••')), findsOneWidget, reason: 'differenza nascosta');
      expect(inSheet(find.text('€ 0,00')), findsNothing);

      // Stesso saldo: nessun "il saldo coincide", che direbbe il saldo.
      await tester.enterText(field, '12.480,00');
      await tester.pump();
      expect(find.textContaining('Il saldo coincide'), findsNothing);
      expect(inSheet(find.text('€ 0,00')), findsNothing);

      // Saldo diverso: né la differenza né il suo segno.
      await tester.enterText(field, '12.792,40');
      await tester.pump();
      expect(find.text('+ € 312,40'), findsNothing);
      expect(inSheet(find.text('€ ••••')), findsOneWidget);

      // "Entrata o spesa" non si può scegliere: la categoria direbbe il segno.
      expect(find.text('Mostra i saldi per usarla: serve conoscere la differenza.'), findsOneWidget);
      await tester.tap(find.text('Registra come entrata o spesa'));
      await tester.pump();
      expect(find.text('Categoria dell\'entrata'), findsNothing);
      expect(find.text('Categoria della spesa'), findsNothing);

      await tester.tap(find.text('Salva aggiornamento'));
      await waitFor(tester, () => gone(find.text('Salva aggiornamento')));
      final adjustment = (await stored(tester)).single;
      expect((adjustment.type, adjustment.amountCents), (TransactionType.adjustment, 31240));
      // Gli importi dei movimenti restano visibili.
      expect(inDetail(find.textContaining('312,40')), findsWidgets);
      expect(find.text('€ 12.792,40'), findsWidgets, reason: 'occupa lo spazio, nascosto');
    });

    testWidgets('sempre nascosti: di nuovo nascosti dopo almeno 1 minuto effettivo in background', (tester) async {
      await pumpWallets(tester);
      await tester.runAsync(() => container.read(balancesHiddenProvider.notifier).setMode(BalancesOnOpen.hidden));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Mostra saldi'), findsOneWidget, reason: 'la modalità ha effetto subito');
      expect(container.read(localPreferencesProvider).value?.biometricLock ?? false, isFalse);

      await tester.tap(find.byTooltip('Mostra saldi'));
      await tester.pumpAndSettle();
      expect(shown(tester, '€ 13.480,00'), isTrue);

      Future<void> away(List<AppLifecycleState> out, Duration time, List<AppLifecycleState> back) async {
        for (final state in out) {
          tester.binding.handleAppLifecycleStateChanged(state);
        }
        now = now.add(time);
        for (final state in back) {
          tester.binding.handleAppLifecycleStateChanged(state);
        }
        await tester.pumpAndSettle();
      }

      const out = [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused];
      const back = [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed];

      // Solo inactive (selettore delle app, centro di controllo): non è background.
      await away([AppLifecycleState.inactive], const Duration(minutes: 5), [AppLifecycleState.resumed]);
      expect(shown(tester, '€ 13.480,00'), isTrue);

      await away(out, const Duration(seconds: 59), back);
      expect(shown(tester, '€ 13.480,00'), isTrue, reason: 'meno di un minuto');

      await away(out, const Duration(minutes: 1), back);
      expect(shown(tester, '€ 13.480,00'), isFalse);
      expect(find.byTooltip('Mostra saldi'), findsOneWidget);
    });
  });
}
