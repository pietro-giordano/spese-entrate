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
import 'package:spese_entrate/domain/models/label.dart';
import 'package:spese_entrate/domain/models/recurrence_rule.dart';
import 'package:spese_entrate/domain/models/transaction.dart';
import 'package:spese_entrate/domain/services/recurrence.dart';
import 'package:spese_entrate/features/recurring/application/recurring_providers.dart';

/// Ogni schermata, in tema chiaro e scuro, con il testo normale e ingrandito al 130%:
/// nessun overflow, controlli toccabili con un'etichetta per lo screen reader, target
/// tattili di almeno 44×44 (CLAUDE.md, come la linea guida iOS).
void main() {
  setUpAll(() => initializeDateFormatting('it_IT'));
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late ProviderContainer container;
  late String walletId;
  late String txId;

  Future<void> pumpAt(
    WidgetTester tester,
    String Function() location, {
    required Brightness brightness,
    required double textScale,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);

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
      final wallets = await db.select(db.wallets).get();
      walletId = wallets.first.id;
      final categories = await db.select(db.categories).get();
      String category(String name) => categories.firstWhere((c) => c.name == name).id;
      await container.read(labelRepositoryProvider).save(const Label(id: 'casa', name: 'casa', color: 0xFF1D4ED8));
      final transactions = container.read(transactionRepositoryProvider);
      txId = newId();
      for (final tx in [
        Transaction(
          id: txId,
          type: TransactionType.expense,
          amountCents: 6420,
          date: LocalDate(2026, 10, 3),
          walletId: walletId,
          categoryId: category('Spesa alimentare'),
          note: 'Esselunga di via Roma con un nome lungo',
          labelIds: const ['casa'],
        ),
        Transaction(
          id: newId(),
          type: TransactionType.income,
          amountCents: 240000,
          date: LocalDate(2026, 10, 2),
          walletId: walletId,
          categoryId: category('Stipendio'),
        ),
        Transaction(
          id: newId(),
          type: TransactionType.transfer,
          amountCents: 50000,
          date: LocalDate(2026, 10, 1),
          walletId: walletId,
          toWalletId: wallets[1].id,
        ),
        Transaction(
          id: newId(),
          type: TransactionType.expense,
          amountCents: 75000,
          date: LocalDate(2026, 9, 1),
          walletId: walletId,
          categoryId: category('Casa'),
          note: 'Affitto',
        ),
      ]) {
        await transactions.save(tx);
      }
      await container
          .read(recurrenceRepositoryProvider)
          .save(
            anchorRuleAt(
              RecurrenceRule(
                id: 'luce',
                name: 'Bolletta della luce e del gas',
                type: TransactionType.expense,
                amountCents: 6400,
                walletId: walletId,
                categoryId: category('Casa'),
                frequency: RecurrenceFrequency.monthly,
                interval: 2,
                startDate: LocalDate(2026, 8, 5),
                mode: RecurrenceMode.confirm,
              ),
              LocalDate(2026, 8, 5),
            ),
          );
      await container.read(recurrenceGeneratorProvider).run();
    });

    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const App()));
    await tester.pumpAndSettle();
    final path = location();
    if (path != AppRoutes.transactions) {
      container.read(appRouterProvider).go(path);
      await tester.pumpAndSettle();
    }
  }

  final screens = <String, String Function()>{
    'Movimenti': () => AppRoutes.transactions,
    'Inserimento rapido': () => AppRoutes.add('expense'),
    'Trasferimento': () => AppRoutes.add('transfer'),
    'Modifica movimento': () => AppRoutes.transaction(txId),
    'Filtri': () => AppRoutes.filters,
    'Filtri di Grafici': () => AppRoutes.filtersOf('charts'),
    'Portafogli': () => AppRoutes.wallets,
    'Dettaglio portafoglio': () => AppRoutes.wallet(walletId),
    'Nuovo portafoglio': () => AppRoutes.newWallet,
    'Grafici': () => AppRoutes.charts,
    'Confronta': () => AppRoutes.compare,
    'Impostazioni': () => AppRoutes.settings,
    'Categorie e label': () => AppRoutes.categories,
    'Movimenti ricorrenti': () => AppRoutes.recurring,
    'Dettaglio ricorrenza': () => AppRoutes.recurrence('luce'),
    'Backup': () => AppRoutes.backup,
    'Importa da CSV': () => AppRoutes.import,
    'Storico importazioni': () => AppRoutes.imports,
  };

  // Pannelli che si aprono sopra le schermate: si controllano con il testo al 130%.
  final sheets = <String, (String Function(), Finder Function())>{
    'Data e ripetizione': (() => AppRoutes.add('expense'), () => find.bySemanticsLabel(RegExp('^Data del movimento'))),
    'Aggiorna saldo': (() => AppRoutes.wallet(walletId), () => find.text('Aggiorna saldo')),
    'Modifica categoria': (() => AppRoutes.categories, () => find.byTooltip('Modifica Casa')),
  };
  for (final brightness in Brightness.values) {
    final variant = '${brightness == Brightness.dark ? 'scuro' : 'chiaro'}, testo 130%';
    for (final MapEntry(key: name, value: (location, opener)) in sheets.entries) {
      testWidgets('pannello $name ($variant)', (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpAt(tester, location, brightness: brightness, textScale: 1.3);
        await tester.ensureVisible(opener().first);
        await tester.pumpAndSettle();
        await tester.tap(opener().first);
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsOneWidget);
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        semantics.dispose();
        await tester.pump(const Duration(milliseconds: 10));
      });
    }
  }

  for (final brightness in Brightness.values) {
    for (final textScale in [1.0, 1.3]) {
      final variant = '${brightness == Brightness.dark ? 'scuro' : 'chiaro'}, testo ${(textScale * 100).round()}%';
      for (final MapEntry(key: name, value: location) in screens.entries) {
        testWidgets('$name ($variant)', (tester) async {
          final semantics = tester.ensureSemantics();
          await pumpAt(tester, location, brightness: brightness, textScale: textScale);
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
          semantics.dispose();
          await tester.pump(const Duration(milliseconds: 10));
        });
      }
    }
  }
}
