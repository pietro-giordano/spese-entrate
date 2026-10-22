import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:spese_entrate/app.dart';
import 'package:spese_entrate/core/clock.dart';
import 'package:spese_entrate/core/dates.dart';
import 'package:spese_entrate/core/router/app_router.dart';
import 'package:spese_entrate/core/router/app_routes.dart';
import 'package:spese_entrate/data/db/app_database.dart';
import 'package:spese_entrate/data/db/database_provider.dart';
import 'package:spese_entrate/data/repositories/repository_providers.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/transaction.dart';
import 'package:spese_entrate/features/wallets/application/balance_visibility.dart';
import 'package:spese_entrate/features/wallets/presentation/wallet_detail_screen.dart';

/// Regressione: il selettore del portafoglio di spese ed entrate mostrava il saldo iniziale
/// (leggeva con `ref.read` un provider autoDispose che nessuno osservava, quindi vuoto) e ignorava
/// trasferimenti, rettifiche e spese. Ora legge la stessa fonte di Portafogli e del dettaglio.
void main() {
  setUpAll(() => initializeDateFormatting('it_IT'));
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late ProviderContainer container;
  late String checkingId;
  late String cashId;
  final today = LocalDate(2026, 10, 22);

  Transaction transfer(String id, int cents, {String? from, String? to}) => Transaction(
    id: id,
    type: TransactionType.transfer,
    amountCents: cents,
    date: today,
    walletId: from ?? checkingId,
    toWalletId: to ?? cashId,
  );

  /// Conto corrente con € 1.000 iniziali, Contanti con 0. Due trasferimenti Conto → Contanti
  /// (200 + 50), un terzo eliminato (999), una rettifica di +30 sui Contanti, una spesa di 10 dal Conto.
  /// Saldi: Conto 740, Contanti 280; patrimonio 1.020 (i trasferimenti non lo cambiano).
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory(), now: () => DateTime.utc(2026, 10, 22, 8));
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 22, 9)),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    await tester.runAsync(() async {
      final wallets = container.read(walletRepositoryProvider);
      final all = await wallets.watchAll().first;
      final checking = all.firstWhere((w) => w.type == WalletType.checking);
      checkingId = checking.id;
      cashId = all.firstWhere((w) => w.type == WalletType.cash).id;
      await wallets.save(checking.copyWith(initialBalanceCents: 100000));
      final category = (await db.select(db.categories).get()).firstWhere((c) => c.name == 'Spesa alimentare').id;
      final transactions = container.read(transactionRepositoryProvider);
      await transactions.save(transfer('t1', 20000));
      await transactions.save(transfer('t2', 5000));
      await transactions.save(transfer('deleted', 99900));
      await transactions.delete('deleted');
      await transactions.save(
        Transaction(id: 'adj', type: TransactionType.adjustment, amountCents: 3000, date: today, walletId: cashId),
      );
      await transactions.save(
        Transaction(
          id: 'exp',
          type: TransactionType.expense,
          amountCents: 1000,
          date: today,
          walletId: checkingId,
          categoryId: category,
        ),
      );
    });
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const App()));
    await tester.pumpAndSettle();
  }

  Future<void> go(WidgetTester tester, String location) async {
    container.read(appRouterProvider).go(location);
    await tester.pumpAndSettle();
  }

  /// Apre Inserimento rapido (spesa) e il selettore del portafoglio.
  Future<void> openPicker(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel(RegExp('^Portafoglio: ')));
    await tester.pumpAndSettle();
    expect(find.text('Paga da'), findsOneWidget);
  }

  Future<void> closePicker(WidgetTester tester) async {
    await tester.tapAt(const Offset(195, 60)); // sul velo, fuori dal pannello
    await tester.pumpAndSettle();
  }

  Finder inPicker(String text) => find.descendant(of: find.byType(BottomSheet), matching: find.text(text));

  Future<void> write(WidgetTester tester, Future<void> Function() action) async {
    await tester.runAsync(action);
    await tester.pumpAndSettle();
  }

  testWidgets('selettore, Portafogli e dettaglio mostrano gli stessi saldi, trasferimenti compresi', (tester) async {
    await pump(tester);

    await go(tester, AppRoutes.wallets);
    // Patrimonio, totale e legenda di Liquidità (entrambi i portafogli sono liquidità).
    expect(find.text('€ 1.020,00'), findsNWidgets(3), reason: 'i trasferimenti non cambiano il patrimonio');
    expect(find.text('€ 740,00'), findsWidgets);
    expect(find.text('€ 280,00'), findsWidgets);

    await go(tester, AppRoutes.wallet(cashId));
    expect(find.descendant(of: find.byType(WalletDetailScreen), matching: find.text('€ 280,00')), findsOneWidget);

    await go(tester, AppRoutes.transactions);
    container.read(appRouterProvider).push(AppRoutes.add('expense'));
    await tester.pumpAndSettle();
    await openPicker(tester);
    expect(inPicker('€ 740,00'), findsOneWidget, reason: 'Conto: 1.000 − 200 − 50 − 10');
    expect(inPicker('€ 280,00'), findsOneWidget, reason: 'Contanti: 200 + 50 + 30');
    expect(inPicker('€ 1.000,00'), findsNothing, reason: 'non il saldo iniziale');
    expect(inPicker('€ 0,00'), findsNothing);
  });

  testWidgets('il selettore si aggiorna dopo trasferimenti modificati, eliminati, annullati e nuovi', (tester) async {
    await pump(tester);
    container.read(appRouterProvider).push(AppRoutes.add('expense'));
    await tester.pumpAndSettle();
    final transactions = container.read(transactionRepositoryProvider);

    // Modificato mentre il selettore è aperto: 200 → 300.
    await openPicker(tester);
    await write(tester, () => transactions.save(transfer('t1', 30000)));
    expect(inPicker('€ 640,00'), findsOneWidget);
    expect(inPicker('€ 380,00'), findsOneWidget);
    await closePicker(tester);

    // Eliminato, poi annullato ("Annulla" = restore), senza riaprire la schermata.
    await write(tester, () => transactions.delete('t2'));
    await openPicker(tester);
    expect(inPicker('€ 690,00'), findsOneWidget);
    expect(inPicker('€ 330,00'), findsOneWidget);
    await write(tester, () => transactions.restore('t2'));
    expect(inPicker('€ 640,00'), findsOneWidget);
    expect(inPicker('€ 380,00'), findsOneWidget);

    // Nuovo trasferimento al contrario, Contanti → Conto: 80.
    await write(tester, () => transactions.save(transfer('t3', 8000, from: cashId, to: checkingId)));
    expect(inPicker('€ 720,00'), findsOneWidget);
    expect(inPicker('€ 300,00'), findsOneWidget);
    await closePicker(tester);

    // Patrimonio sempre 1.020: nessun trasferimento lo ha cambiato.
    await go(tester, AppRoutes.wallets);
    expect(find.text('€ 1.020,00'), findsNWidgets(3));
  });

  testWidgets('saldi nascosti: anche il selettore mostra il valore mascherato', (tester) async {
    await pump(tester);
    await tester.runAsync(() => container.read(balancesHiddenProvider.notifier).toggle());
    container.read(appRouterProvider).push(AppRoutes.add('expense'));
    await tester.pumpAndSettle();
    await openPicker(tester);
    expect(inPicker('€ ••••'), findsNWidgets(2));
    expect(find.bySemanticsLabel(RegExp('Saldo nascosto')), findsWidgets);
    await closePicker(tester);
  });
}
