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
import 'package:spese_entrate/core/widgets/app_switch.dart';
import 'package:spese_entrate/data/db/app_database.dart';
import 'package:spese_entrate/data/db/database_provider.dart';
import 'package:spese_entrate/data/repositories/repository_providers.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/recurrence_rule.dart';
import 'package:spese_entrate/domain/models/transaction.dart';
import 'package:spese_entrate/domain/services/recurrence.dart';
import 'package:spese_entrate/features/recurring/application/recurring_providers.dart';
import 'package:spese_entrate/features/transactions/presentation/quick_add_screen.dart';

LocalDate d(int y, int m, int day) => LocalDate(y, m, day);

void main() {
  setUpAll(() => initializeDateFormatting('it_IT'));
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late ProviderContainer container;
  late String walletId;
  late String houseId;

  /// Oggi è sabato 3 ottobre 2026. Con [seed]:
  /// - "Bolletta luce": ogni 2 mesi dal 5 agosto, da confermare (pending il 5 ottobre);
  /// - "Spotify": ogni mese dal 7 gennaio, automatica (confermate fino a settembre).
  Future<void> pumpAt(WidgetTester tester, String location, {bool seed = true}) async {
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
      walletId = (await db.select(db.wallets).get()).firstWhere((w) => w.name == 'Conto corrente').id;
      houseId = (await db.select(db.categories).get()).firstWhere((c) => c.name == 'Casa').id;
      if (!seed) return;
      final repository = container.read(recurrenceRepositoryProvider);
      RecurrenceRule rule(
        String id,
        String name,
        int cents,
        LocalDate start,
        RecurrenceMode mode, {
        int interval = 1,
      }) => anchorRuleAt(
        RecurrenceRule(
          id: id,
          name: name,
          type: TransactionType.expense,
          amountCents: cents,
          walletId: walletId,
          categoryId: houseId,
          frequency: RecurrenceFrequency.monthly,
          interval: interval,
          startDate: start,
          mode: mode,
        ),
        start,
      );
      await repository.save(rule('luce', 'Bolletta luce', 6400, d(2026, 8, 5), RecurrenceMode.confirm, interval: 2));
      await repository.save(rule('spotify', 'Spotify', 1099, d(2026, 1, 7), RecurrenceMode.auto));
      await container.read(recurrenceGeneratorProvider).run();
      // La bolletta di agosto è già stata confermata.
      final transactions = container.read(transactionRepositoryProvider);
      final august = (await transactions.getById(occurrenceId('luce', d(2026, 8, 5))))!;
      await transactions.save(august.copyWith(status: TransactionStatus.confirmed));
    });

    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const App()));
    await tester.pumpAndSettle();
    if (location != AppRoutes.transactions) {
      container.read(appRouterProvider).push(location);
      await tester.pumpAndSettle();
    }
  }

  /// Fa scattare i timer con cui Drift chiude gli stream delle schermate lasciate.
  Future<void> finish(WidgetTester tester) => tester.pump(const Duration(milliseconds: 10));

  Future<T> db<T>(WidgetTester tester, Future<T> Function() action) async => (await tester.runAsync(action)) as T;

  /// Le scritture fanno più passi sul database: si lascia lavorare l'I/O finché [done] è vero.
  Future<void> waitFor(WidgetTester tester, Future<bool> Function() done) async {
    for (var i = 0; i < 100 && !(await db(tester, done)); i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  // Letture dirette, da usare dentro waitFor; fuori si passano a db().
  Future<Transaction?> readTx(String id) => container.read(transactionRepositoryProvider).getById(id);
  Future<List<RecurrenceRule>> readRules() => container.read(recurrenceRepositoryProvider).watchAll().first;

  Future<Transaction?> byId(WidgetTester tester, String id) => db(tester, () => readTx(id));
  Future<List<RecurrenceRule>> rules(WidgetTester tester) => db(tester, readRules);

  final octoberBill = occurrenceId('luce', d(2026, 10, 5));

  /// Tocca [finder] dopo averlo portato in vista (i pannelli lunghi scorrono).
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pump();
  }

  group('In arrivo e Conferma', () {
    testWidgets('la home mostra il pending; Conferma apre il form compilato e lo conferma', (tester) async {
      await pumpAt(tester, AppRoutes.transactions);
      expect(find.text('IN ARRIVO · PROSSIMI 7 GIORNI'), findsOneWidget);
      expect(find.text('Bolletta luce'), findsOneWidget);
      expect(find.text('lun 5 ott · − € 64,00'), findsOneWidget);
      expect(find.text('Spotify'), findsNothing, reason: 'le automatiche non sono da confermare');

      await tester.tap(find.text('Conferma'));
      await tester.pumpAndSettle();
      expect(find.byType(ConfirmTransactionScreen), findsOneWidget);
      expect(find.text('64,00'), findsOneWidget, reason: 'importo proposto dalla regola');
      expect(find.bySemanticsLabel(RegExp('si ripete')), findsOneWidget);

      for (final digit in ['7', '1', '2', '0']) {
        await tester.tap(find.descendant(of: find.byType(ConfirmTransactionScreen), matching: find.text(digit)));
        await tester.pump();
      }
      expect(find.text('71,20'), findsOneWidget, reason: 'il primo tasto sostituisce la proposta');
      await tester.tap(find.text('Conferma spesa'));
      await waitFor(tester, () async => (await readTx(octoberBill))!.isConfirmed);

      final confirmed = (await byId(tester, octoberBill))!;
      expect(confirmed.amountCents, 7120);
      expect(confirmed.date, d(2026, 10, 5), reason: 'resta la data dell\'occorrenza');
      expect(find.text('Spesa di € 71,20 confermata'), findsOneWidget);
      expect(find.text('IN ARRIVO · PROSSIMI 7 GIORNI'), findsNothing);
      await finish(tester);
    });

    testWidgets('automatica futura: visibile in "In arrivo" senza Conferma, in nessun percorso', (tester) async {
      await pumpAt(tester, AppRoutes.transactions);
      // Spotify del 7 ottobre creata in anticipo (es. "Modifica solo questa"): pending.
      final spotify = occurrenceId('spotify', d(2026, 10, 7));
      await tester.runAsync(
        () => container.read(recurrenceRepositoryProvider).occurrenceTransaction('spotify', d(2026, 10, 7)),
      );
      await waitFor(tester, () async => (await readTx(spotify)) != null);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pumpAndSettle();

      expect(find.text('Spotify'), findsOneWidget);
      expect(find.text('Automatica · 7 ott'), findsOneWidget);
      expect(find.text('Conferma'), findsOneWidget, reason: 'solo quello della bolletta, che è da confermare');

      // Neanche aprendo direttamente la rotta di conferma.
      container.read(appRouterProvider).push(AppRoutes.confirm(spotify));
      await tester.pumpAndSettle();
      expect(find.byType(ConfirmTransactionScreen), findsOneWidget);
      expect(find.text('Conferma spesa'), findsNothing);
      expect(find.textContaining('verrà registrato da solo il mercoledì 7 ottobre 2026'), findsOneWidget);
      container.read(appRouterProvider).pop();
      await tester.pumpAndSettle();

      // Né dal dettaglio della ricorrenza.
      container.read(appRouterProvider).push(AppRoutes.recurrence('spotify'));
      await tester.pumpAndSettle();
      expect(find.text('Mercoledì 7 ottobre 2026'), findsOneWidget);
      expect(find.text('Verrà registrata automaticamente'), findsWidgets);
      expect(find.text('Conferma'), findsNothing);

      expect((await byId(tester, spotify))!.status, TransactionStatus.pending);
      await finish(tester);
    });

    testWidgets('"Tutti" apre i movimenti ricorrenti', (tester) async {
      await pumpAt(tester, AppRoutes.transactions);
      await tester.tap(find.text('Tutti'));
      await tester.pumpAndSettle();
      expect(find.text('Movimenti ricorrenti'), findsOneWidget);
      await finish(tester);
    });
  });

  group('Movimenti ricorrenti', () {
    testWidgets('totali effettivi di ottobre e media mensile prevista', (tester) async {
      await pumpAt(tester, AppRoutes.recurring);
      expect(find.text('Uscite fisse a ottobre'), findsOneWidget);
      // Ottobre: luce (5) + Spotify (7). Media: luce ogni 2 mesi vale la metà.
      expect(find.text('€ 74,99'), findsOneWidget);
      expect(find.text('Media mensile prevista € 42,99'), findsOneWidget);
      expect(find.textContaining('Media mensile prevista € 0,00'), findsNothing, reason: 'nessuna entrata non mensile');

      expect(find.text('ATTIVE'), findsOneWidget);
      expect(find.text('Ogni 2 mesi, il 5 · Casa · Conto corrente'), findsOneWidget);
      expect(find.text('Da confermare'), findsOneWidget);
      expect(find.text('Automatico'), findsOneWidget);
      expect(find.text('Prossima: 5 ott'), findsOneWidget);
      expect(find.text('Prossima: 7 ott'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('senza ricorrenze: messaggio e "+ Nuova ricorrenza" apre Ripeti con Ogni mese', (tester) async {
      await pumpAt(tester, AppRoutes.recurring, seed: false);
      expect(find.text('Nessun movimento ricorrente.'), findsOneWidget);
      await tester.tap(find.text('+ Nuova ricorrenza'));
      await tester.pumpAndSettle();
      expect(find.text('Data e ripetizione'), findsOneWidget);
      final monthly = tester.widget<Semantics>(
        find.ancestor(of: find.text('Ogni mese'), matching: find.byType(Semantics)).first,
      );
      expect(monthly.properties.selected ?? true, isTrue);
      expect(find.textContaining('Prossimo: 3 nov'), findsOneWidget);
      await finish(tester);
    });
  });

  group('Dettaglio ricorrenza', () {
    testWidgets('prossime occorrenze, salto e pausa', (tester) async {
      await pumpAt(tester, AppRoutes.recurrence('luce'));
      expect(find.text('Bolletta luce'), findsOneWidget);
      expect(find.text('Lunedì 5 ottobre 2026'), findsOneWidget);
      expect(find.text('Da confermare'), findsWidgets);
      expect(find.text('Sabato 5 dicembre 2026'), findsOneWidget);
      expect(find.text('Conferma'), findsOneWidget);

      await tester.tap(find.byTooltip('Opzioni per Sabato 5 dicembre 2026'));
      await tester.pumpAndSettle();
      expect(find.text('Occorrenza del 5 dic'), findsOneWidget);
      await tester.tap(find.text('Salta solo questa'));
      await waitFor(
        tester,
        () async => (await container.read(recurrenceRepositoryProvider).watchExceptions().first).isNotEmpty,
      );
      expect(find.text('Saltata'), findsOneWidget);

      await tester.tap(find.byType(AppSwitch));
      await waitFor(tester, () async => (await readRules()).firstWhere((r) => r.id == 'luce').isPaused);
      expect(find.text('In pausa'), findsWidgets);
      expect(find.text('Conferma'), findsNothing, reason: 'in pausa non si conferma');
      await finish(tester);
    });

    testWidgets('un\'occorrenza eliminata dal form di modifica appare come "Eliminata", senza azioni', (tester) async {
      await pumpAt(tester, AppRoutes.recurrence('luce'));
      await tester.runAsync(() => container.read(transactionRepositoryProvider).delete(octoberBill));
      await waitFor(tester, () async => (await readTx(octoberBill)) == null);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pumpAndSettle();
      expect(find.text('Lunedì 5 ottobre 2026'), findsOneWidget);
      expect(find.text('Eliminata'), findsOneWidget);
      expect(find.byTooltip('Opzioni per Lunedì 5 ottobre 2026'), findsNothing);
      expect(find.text('Conferma'), findsNothing);
      await finish(tester);
    });

    testWidgets('elimina: chiede conferma, lo storico resta', (tester) async {
      await pumpAt(tester, AppRoutes.recurrence('spotify'));
      await tester.scrollUntilVisible(find.text('Elimina ricorrenza'), 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Elimina ricorrenza'));
      await tester.pumpAndSettle();
      expect(find.text('Eliminare la ricorrenza?'), findsOneWidget);
      await tester.tap(find.text('Elimina'));
      await waitFor(tester, () async => (await readRules()).length == 1);
      expect(find.text('Ricorrenza «Spotify» eliminata'), findsOneWidget);
      final history = await db(tester, () => container.read(transactionRepositoryProvider).getAll());
      expect(history.where((t) => t.recurrenceId == 'spotify'), hasLength(9));
      await finish(tester);
    });

    testWidgets('modifica questa e le successive da un\'occorrenza futura', (tester) async {
      await pumpAt(tester, AppRoutes.recurrence('luce'));
      await tester.tap(find.byTooltip('Opzioni per Sabato 5 dicembre 2026'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Modifica questa e le successive'));
      await tester.pumpAndSettle();
      expect(find.text('Modifica movimento'), findsOneWidget);
      expect(find.text('Le modifiche varranno anche per le occorrenze successive'), findsOneWidget);

      expect(find.text('NOME DELLA RICORRENZA'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, '64,00'), '70,00');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salva modifiche'));
      await waitFor(tester, () async => (await readRules()).length == 3);

      final all = await rules(tester);
      final next = all.firstWhere((r) => r.id != 'luce' && r.id != 'spotify');
      expect(next.amountCents, 7000);
      expect(next.startDate, d(2026, 12, 5));
      expect(all.firstWhere((r) => r.id == 'luce').endDate, d(2026, 12, 4));
      expect(find.text('Modifiche salvate anche per le successive'), findsOneWidget);
      await finish(tester);
    });
  });

  group('Modifica movimento ricorrente', () {
    testWidgets('banner e scelta della portata: solo questo', (tester) async {
      await pumpAt(tester, AppRoutes.transaction(octoberBill));
      expect(find.text('Bolletta luce'), findsOneWidget);
      expect(find.text('Si ripete · Ogni 2 mesi, il 5 · da confermare'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '71,20');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salva modifiche'));
      await tester.pumpAndSettle();
      expect(find.text('Movimento ricorrente'), findsOneWidget);
      await tester.tap(find.text('Solo questo'));
      await waitFor(tester, () async => (await readTx(octoberBill))!.amountCents == 7120);

      expect((await rules(tester)), hasLength(2), reason: 'la regola non si divide');
      expect((await rules(tester)).firstWhere((r) => r.id == 'luce').amountCents, 6400);
      await finish(tester);
    });

    testWidgets('chiudere la scelta della portata non salva', (tester) async {
      await pumpAt(tester, AppRoutes.transaction(octoberBill));
      await tester.enterText(find.byType(TextField).first, '71,20');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salva modifiche'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(195, 60)); // sul velo, fuori dal pannello
      await tester.pumpAndSettle();
      expect(find.text('Modifica movimento'), findsOneWidget);
      expect((await byId(tester, octoberBill))!.amountCents, 6400);
      await finish(tester);
    });
  });

  group('Ripeti in Inserimento rapido', () {
    testWidgets('ogni mese da una data passata: chiede degli arretrati, "solo da oggi" li salta', (tester) async {
      await pumpAt(tester, AppRoutes.add('expense'), seed: false);
      for (final digit in ['3', '9', '0', '0']) {
        await tester.tap(find.descendant(of: find.byType(QuickAddScreen), matching: find.text(digit)));
        await tester.pump();
      }
      await tester.tap(find.text('Casa'));
      await tester.tap(find.bySemanticsLabel(RegExp('^Data del movimento: ')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Mese precedente'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Mese precedente'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('3 agosto 2026'));
      await tester.pump();
      await tapVisible(tester, find.text('Ogni mese'));
      expect(find.textContaining('Prossimo: 3 set · verrà registrato automaticamente'), findsOneWidget);
      await tapVisible(tester, find.text('Conferma'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp('si ripete')), findsOneWidget);

      await tester.tap(find.text('Salva spesa'));
      await tester.pumpAndSettle();
      expect(find.text('Occorrenze passate'), findsOneWidget);
      expect(find.text('Registra anche quella passata'), findsOneWidget);
      expect(find.text('il 3 set'), findsOneWidget);
      await tester.tap(find.text('Solo da oggi in poi'));
      await waitFor(tester, () async => (await readRules()).isNotEmpty);

      final rule = (await rules(tester)).single;
      expect(rule.name, isEmpty, reason: 'senza nota la regola non ha un nome: il titolo è la categoria');
      expect(rule.byMonthDay, 3);
      final created = (await db(
        tester,
        () => container.read(transactionRepositoryProvider).getAll(),
      )).map((t) => t.date).toList();
      // 3 agosto (questo movimento) e 3 ottobre (oggi, automatico); il 3 settembre è saltato.
      expect(created, [d(2026, 10, 3), d(2026, 8, 3)]);
      await finish(tester);
    });

    testWidgets('Personalizza: ogni 2 mesi per 6 volte', (tester) async {
      await pumpAt(tester, AppRoutes.add('expense'), seed: false);
      await tester.tap(find.bySemanticsLabel(RegExp('^Data del movimento: ')));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Personalizza…'));
      await tester.pumpAndSettle();
      expect(find.text('Ripetizione personalizzata'), findsOneWidget);
      await tester.tap(find.byTooltip('Intervallo più lungo'));
      await tester.pump();
      expect(find.text('Ogni 2 mesi'), findsOneWidget);
      await tapVisible(tester, find.text('Dopo'));
      for (var i = 0; i < 6; i++) {
        await tapVisible(tester, find.byTooltip('Una volta in meno'));
      }
      expect(find.text('6 volte'), findsOneWidget);
      await tapVisible(tester, find.text('Applica'));
      await tester.pumpAndSettle();
      expect(find.text('Ogni 2 mesi · 6 volte'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('con la nota "Netflix": la ricorrenza si chiama "Netflix" in elenco', (tester) async {
      await pumpAt(tester, AppRoutes.add('expense'), seed: false);
      for (final digit in ['1', '2', '9', '9']) {
        await tester.tap(find.descendant(of: find.byType(QuickAddScreen), matching: find.text(digit)));
        await tester.pump();
      }
      await tester.tap(find.text('Abbonamenti'));
      await tester.enterText(find.widgetWithText(TextField, 'Nota (facoltativa)'), 'Netflix');
      await tester.tap(find.bySemanticsLabel(RegExp('^Data del movimento: ')));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Ogni mese'));
      await tapVisible(tester, find.text('Conferma'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salva spesa'));
      await waitFor(tester, () async => (await readRules()).isNotEmpty);
      expect((await rules(tester)).single.name, 'Netflix');

      container.read(appRouterProvider).go(AppRoutes.recurring);
      await tester.pumpAndSettle();
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('Ogni mese, il 3 · Abbonamenti · Conto corrente'), findsOneWidget);
      expect(find.text('Prossima: 3 nov'), findsOneWidget);
      await finish(tester);
    });
  });

  group('Nome alla creazione', () {
    testWidgets('il nome scelto in "Data e ripetizione" vince sulla nota', (tester) async {
      await pumpAt(tester, AppRoutes.add('expense'), seed: false);
      for (final digit in ['1', '2', '9', '9']) {
        await tester.tap(find.descendant(of: find.byType(QuickAddScreen), matching: find.text(digit)));
        await tester.pump();
      }
      await tester.tap(find.text('Abbonamenti'));
      await tester.enterText(find.widgetWithText(TextField, 'Nota (facoltativa)'), 'Netflix');
      await tester.tap(find.bySemanticsLabel(RegExp('^Data del movimento: ')));
      await tester.pumpAndSettle();
      expect(find.text('NOME DELLA RICORRENZA'), findsNothing, reason: 'solo con una ripetizione');
      await tapVisible(tester, find.text('Ogni mese'));
      final name = find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField));
      expect(tester.widget<TextField>(name).decoration!.hintText, 'Netflix', reason: 'segnaposto: la nota');
      await tester.enterText(name, 'Streaming');
      await tapVisible(tester, find.text('Conferma'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salva spesa'));
      await waitFor(tester, () async => (await readRules()).isNotEmpty);
      expect((await rules(tester)).single.name, 'Streaming');
      await finish(tester);
    });
  });

  group('Modifica regola', () {
    testWidgets('la matita apre "questa e le successive" sulla prossima occorrenza, con il nome', (tester) async {
      await pumpAt(tester, AppRoutes.recurrence('spotify'));
      expect(find.text('Spotify'), findsOneWidget);

      await tester.tap(find.byTooltip('Modifica regola'));
      await tester.pumpAndSettle();
      expect(find.text('Modifica movimento'), findsOneWidget);
      expect(find.text('Le modifiche varranno anche per le occorrenze successive'), findsOneWidget);
      final name = find.widgetWithText(TextField, 'Spotify');
      expect(tester.widget<TextField>(name).decoration!.hintText, 'Casa', reason: 'senza nota: la categoria');

      await tester.enterText(name, 'Musica');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salva modifiche'));
      await waitFor(tester, () async => (await readRules()).any((r) => r.name == 'Musica'));

      final all = await rules(tester);
      final next = all.firstWhere((r) => r.name == 'Musica');
      expect(next.startDate, d(2026, 10, 7), reason: 'dalla prossima occorrenza');
      expect(all.firstWhere((r) => r.id == 'spotify').endDate, d(2026, 10, 6));
      await finish(tester);
    });

    testWidgets('nome svuotato: la nuova regola usa il titolo calcolato', (tester) async {
      await pumpAt(tester, AppRoutes.recurrence('spotify'));
      await tester.tap(find.byTooltip('Modifica regola'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Spotify'), '');
      final note = find.widgetWithText(TextField, 'Nota (facoltativa)');
      await tester.scrollUntilVisible(note, 200, scrollable: find.byType(Scrollable).first);
      await tester.enterText(note, 'Spotify Family');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salva modifiche'));
      await waitFor(tester, () async => (await readRules()).length == 3);

      final next = (await rules(tester)).firstWhere((r) => r.id != 'spotify' && r.id != 'luce');
      expect(next.name, isEmpty);
      container.read(appRouterProvider).go(AppRoutes.recurring);
      await tester.pumpAndSettle();
      expect(find.text('Spotify Family'), findsOneWidget, reason: 'senza nome: la nota');
      await finish(tester);
    });
  });
}
