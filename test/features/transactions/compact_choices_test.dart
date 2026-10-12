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
import 'package:spese_entrate/core/widgets/app_chip.dart';
import 'package:spese_entrate/data/db/app_database.dart';
import 'package:spese_entrate/data/db/database_provider.dart';
import 'package:spese_entrate/data/repositories/repository_providers.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/label.dart';
import 'package:spese_entrate/domain/models/transaction.dart';

/// Vista ridotta di categorie e label in Inserimento rapido e Modifica movimento.
void main() {
  setUpAll(() => initializeDateFormatting('it_IT'));
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late ProviderContainer container;
  late String saluteTxId;
  final today = LocalDate(2026, 10, 10);

  /// Categorie di spesa in sort_order: Spesa alimentare, Casa, Trasporti, Ristoranti, Svago,
  /// Salute, Abbonamenti, Altro. Negli ultimi 90 giorni: Altro ×3, Abbonamenti ×2 (inserite a mano);
  /// Svago ×5 ma importate e Salute ×4 di 100 giorni fa (non contano). Sette label, #l7 usata due volte.
  Future<void> pump(WidgetTester tester) async {
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
    await tester.runAsync(() async {
      final walletId = (await db.select(db.wallets).get()).first.id;
      // Solo quelle di spesa: "Altro" esiste anche tra le entrate.
      final categories = {
        for (final c in await db.select(db.categories).get())
          if (c.kind == CategoryKind.expense) c.name: c.id,
      };
      final labels = container.read(labelRepositoryProvider);
      for (var i = 1; i <= 7; i++) {
        await labels.save(Label(id: 'l$i', name: 'l$i', color: 0));
      }
      final transactions = container.read(transactionRepositoryProvider);
      Future<String> add(
        String category, {
        int daysAgo = 1,
        String? importBatchId,
        List<String> labelIds = const [],
      }) async {
        final id = newId();
        await transactions.save(
          Transaction(
            id: id,
            type: TransactionType.expense,
            amountCents: 100,
            date: today.addDays(-daysAgo),
            walletId: walletId,
            categoryId: categories[category],
            importBatchId: importBatchId,
            labelIds: labelIds,
          ),
        );
        return id;
      }

      for (var i = 0; i < 3; i++) {
        await add('Altro', labelIds: i < 2 ? const ['l7'] : const []);
      }
      for (var i = 0; i < 2; i++) {
        await add('Abbonamenti');
      }
      await db
          .into(db.imports)
          .insert(
            ImportsCompanion.insert(
              id: 'imp',
              createdAt: 1,
              updatedAt: 1,
              deviceId: 'd',
              fileName: 'x.csv',
              rowCount: 5,
              insertedCount: 5,
              updatedCount: 0,
            ),
          );
      for (var i = 0; i < 5; i++) {
        await add('Svago', importBatchId: 'imp');
      }
      for (var i = 0; i < 4; i++) {
        saluteTxId = await add('Salute', daysAgo: 100);
      }
    });
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const App()));
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester, String location) async {
    container.read(appRouterProvider).push(location);
    await tester.pumpAndSettle();
  }

  /// Testi dei chip delle categorie, nell'ordine in cui compaiono (prima della prima label).
  List<String> categoryChips(WidgetTester tester) =>
      [for (final chip in tester.widgetList<AppChip>(find.byType(AppChip))) chip.label]
          .takeWhile((label) => !label.startsWith('#'))
          .toList();

  List<String> labelChips(WidgetTester tester) => [
    for (final chip in tester.widgetList<AppChip>(find.byType(AppChip)))
      if (chip.label.startsWith('#')) chip.label,
  ];

  const sortOrder = ['Spesa alimentare', 'Casa', 'Trasporti', 'Ristoranti', 'Svago', 'Salute', 'Abbonamenti', 'Altro'];

  testWidgets('vista ridotta per utilizzi recenti; "Tutte (N)" espande in sort_order, "Meno" richiude', (tester) async {
    await pump(tester);
    await open(tester, AppRoutes.add('expense'));

    // 6 categorie: prima le usate (Altro 3, Abbonamenti 2), poi sort_order. Importate e vecchie no.
    expect(categoryChips(tester), [
      'Altro',
      'Abbonamenti',
      'Spesa alimentare',
      'Casa',
      'Trasporti',
      'Ristoranti',
      'Tutte (2)',
    ]);
    expect(find.bySemanticsLabel('Mostra tutte le categorie'), findsOneWidget);
    // 5 label: #l7 (usata) in testa, poi le altre.
    expect(labelChips(tester), ['#l7', '#l1', '#l2', '#l3', '#l4']);
    expect(find.bySemanticsLabel('Mostra tutte le label'), findsOneWidget);

    // Toccare un chip non sposta nulla.
    await tester.tap(find.text('Trasporti'));
    await tester.pump();
    expect(categoryChips(tester).first, 'Altro');
    expect(categoryChips(tester)[4], 'Trasporti');

    // Espansa: tutte in sort_order (il primo "Tutte" è delle categorie, il secondo delle label).
    await tester.tap(find.text('Tutte (2)').first);
    await tester.pump();
    expect(categoryChips(tester), [...sortOrder, 'Meno']);
    expect(find.bySemanticsLabel('Mostra meno categorie'), findsOneWidget);

    // Scelta una nascosta, richiudendo resta visibile, in testa.
    await tester.tap(find.text('Salute'));
    await tester.pump();
    await tester.tap(find.text('Meno'));
    await tester.pump();
    expect(categoryChips(tester), [
      'Salute',
      'Altro',
      'Abbonamenti',
      'Spesa alimentare',
      'Casa',
      'Trasporti',
      'Tutte (2)',
    ]);

    // Le label si espandono a parte.
    await tester.tap(find.text('Tutte (2)').last);
    await tester.pump();
    expect(labelChips(tester), ['#l1', '#l2', '#l3', '#l4', '#l5', '#l6', '#l7']);
  });

  testWidgets('lo stato espanso si azzera a ogni apertura', (tester) async {
    await pump(tester);
    await open(tester, AppRoutes.add('expense'));
    await tester.tap(find.text('Tutte (2)').first);
    await tester.pump();
    expect(find.text('Meno'), findsOneWidget);

    await tester.tap(find.byTooltip('Chiudi'));
    await tester.pumpAndSettle();
    await open(tester, AppRoutes.add('expense'));
    expect(find.text('Meno'), findsNothing);
    expect(find.text('Tutte (2)'), findsNWidgets(2));
  });

  testWidgets('Modifica movimento: la categoria del movimento è già in testa', (tester) async {
    await pump(tester);
    await open(tester, AppRoutes.transaction(saluteTxId));
    expect(categoryChips(tester).first, 'Salute', reason: 'usata solo 100 giorni fa, ma è quella del movimento');
    expect(categoryChips(tester), hasLength(7), reason: '6 categorie più "Tutte (2)"');
  });
}
