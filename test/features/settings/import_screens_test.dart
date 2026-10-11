import 'dart:io';

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
import 'package:spese_entrate/data/files/csv_files.dart';
import 'package:spese_entrate/data/files/file_sharer.dart';
import 'package:spese_entrate/data/repositories/repository_providers.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/transaction.dart';
import 'package:spese_entrate/features/settings/presentation/import_history_screen.dart';
import 'package:spese_entrate/features/settings/presentation/import_screen.dart';

const header = 'data;tipo;importo;valuta;portafoglio;portafoglio_destinazione;categoria;label;nota;id';
const existingId = '01928f0e-1111-7aaa-8bbb-000000000001';

/// File scelto "per finta" e modello condiviso registrato.
class FakeCsvFiles extends CsvFiles {
  FakeCsvFiles() : super(sharer: const FileSharer(), directory: () async => Directory.systemTemp);

  PickedCsv? next;
  final sharedTemplates = <String>[];

  @override
  Future<PickedCsv?> pickCsv() async => next;

  @override
  Future<void> shareTemplate(String csv) async => sharedTemplates.add(csv);
}

void main() {
  setUpAll(() => initializeDateFormatting('it_IT'));
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late ProviderContainer container;
  late AppDatabase db;
  late FakeCsvFiles files;

  Future<void> pumpAt(WidgetTester tester, String location) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    db = AppDatabase(NativeDatabase.memory(), now: () => DateTime.utc(2026, 10, 3, 8));
    files = FakeCsvFiles();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 3, 9)),
        csvFilesProvider.overrideWithValue(files),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    await tester.runAsync(() async {
      final wallet = (await db.select(db.wallets).get()).firstWhere((w) => w.name == 'Conto corrente');
      final category = (await db.select(db.categories).get()).firstWhere((c) => c.name == 'Casa');
      await container
          .read(transactionRepositoryProvider)
          .save(
            Transaction(
              id: existingId,
              type: TransactionType.expense,
              amountCents: 100,
              date: LocalDate(2026, 9, 1),
              walletId: wallet.id,
              categoryId: category.id,
              note: 'prima',
            ),
          );
    });
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const App()));
    await tester.pumpAndSettle();
    container.read(appRouterProvider).go(AppRoutes.settings);
    await tester.pumpAndSettle();
    container.read(appRouterProvider).push(location);
    await tester.pumpAndSettle();
  }

  Future<void> finish(WidgetTester tester) => tester.pump(const Duration(milliseconds: 10));

  /// Lascia lavorare l'I/O del database finché [done] è vero.
  Future<void> waitFor(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 200 && !done(); i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  Future<List<TransactionRow>> rows(WidgetTester tester) async =>
      (await tester.runAsync(() => db.select(db.transactions).get()))!;

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Dalla schermata introduttiva sceglie un file con [lines].
  Future<void> pick(WidgetTester tester, List<String> lines, {String name = 'banca.csv'}) async {
    files.next = (name: name, content: [header, ...lines].join('\n'));
    await tester.tap(find.text('Scegli file'));
    await waitFor(
      tester,
      () => find.text('Continua').evaluate().isNotEmpty || find.text('Scegli un altro file').evaluate().isNotEmpty,
    );
  }

  testWidgets('Impostazioni › Dati ha "Importa da CSV" e "Storico importazioni"', (tester) async {
    await pumpAt(tester, AppRoutes.settings);
    await tester.scrollUntilVisible(find.text('Storico importazioni'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Importa da CSV'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('introduzione: colonne descritte e "Scarica modello"', (tester) async {
    await pumpAt(tester, AppRoutes.import);
    expect(find.byType(ImportScreen), findsOneWidget);
    expect(find.text('portafoglio_destinazione'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Scarica modello'), 300, scrollable: find.byType(Scrollable).first);
    await tapVisible(tester, find.text('Scarica modello'));
    await waitFor(tester, () => files.sharedTemplates.isNotEmpty);
    expect(files.sharedTemplates.single, contains(header));
    await finish(tester);
  });

  testWidgets('flusso completo: anteprima, abbinamenti, opzioni, importazione, storico e annullamento', (tester) async {
    await pumpAt(tester, AppRoutes.import);
    await pick(tester, [
      '01/10/2026;spesa;10,00;;Carta;;Palestra;;abbonamento;',
      '02/10/2026;spesa;20,00;;;;Casa;;senza portafoglio;',
      'ieri;spesa;1;;Contanti;;Casa;;;',
      '03/10/2026;spesa;99,00;;Conto corrente;;Casa;;dopo;$existingId',
    ]);

    // Anteprima
    expect(find.text('1 di 4'), findsOneWidget);
    expect(find.bySemanticsLabel('2 righe pronte'), findsOneWidget);
    expect(find.bySemanticsLabel('2 con errori (saltate)'), findsOneWidget);
    expect(find.text('1 movimento nuovo · 1 aggiorna un movimento esistente'), findsOneWidget);
    expect(find.textContaining('1 movimento esistente verrà aggiornato'), findsOneWidget);
    expect(find.text('Riga 4'), findsNothing, reason: 'errori chiusi di base');
    await tapVisible(tester, find.text('Errori (2)'));
    expect(find.text('Riga 4'), findsOneWidget);
    expect(find.textContaining('data non valida'), findsOneWidget);

    // Abbinamenti: "Carta" va su Contanti, "Palestra" resta da creare.
    await tapVisible(tester, find.text('Continua'));
    expect(find.text('2 di 4'), findsOneWidget);
    await tapVisible(tester, find.text('Carta'));
    await tapVisible(tester, find.text('Abbina a Contanti'));
    expect(find.text('Abbinato a Contanti'), findsOneWidget);
    expect(find.text('Verrà creata'), findsOneWidget);

    // Opzioni: portafoglio per la riga senza, label aggiuntiva.
    await tapVisible(tester, find.text('Continua'));
    expect(find.text('3 di 4'), findsOneWidget);
    expect(find.text('1 riga senza portafoglio'), findsOneWidget);
    await tapVisible(tester, find.text('Portafoglio se la colonna è vuota'));
    await tester.tap(find.text('Conto corrente').last);
    await waitFor(tester, () => find.text('Importa 3 movimenti').evaluate().isNotEmpty);
    await tester.enterText(find.byType(TextFormField), 'import-ottobre');
    await tester.pump();
    expect(find.textContaining('La label #import-ottobre verrà creata'), findsOneWidget);

    // Importazione e riepilogo
    await tapVisible(tester, find.text('Importa 3 movimenti'));
    await waitFor(tester, () => find.text('Importazione completata').evaluate().isNotEmpty);
    expect(find.text('Importazione completata'), findsOneWidget);
    final all = await rows(tester);
    expect(all.where((r) => r.deletedAt == null), hasLength(3));
    expect(all.firstWhere((r) => r.id == existingId).note, 'dopo');
    final imported = all.where((r) => r.importBatchId != null).toList();
    expect(imported, hasLength(2), reason: 'solo i movimenti nuovi hanno l\'import');

    // Storico e annullamento
    await tapVisible(tester, find.text('Storico importazioni'));
    expect(find.byType(ImportHistoryScreen), findsOneWidget);
    expect(find.text('banca.csv'), findsOneWidget);
    expect(find.textContaining('2 nuovi · 1 aggiornato · 1 saltato'), findsOneWidget);
    await tapVisible(tester, find.text('banca.csv'));
    expect(find.textContaining('restano come sono: non si possono ripristinare'), findsOneWidget);
    await tapVisible(tester, find.text('Annulla importazione'));
    expect(find.text('Annullare l\'importazione?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Annulla importazione'));
    await waitFor(tester, () => find.text('Annullata').evaluate().isNotEmpty);
    expect(find.text('Importazione annullata: 2 movimenti eliminati'), findsOneWidget);
    final after = await rows(tester);
    expect(after.where((r) => r.deletedAt == null).map((r) => r.id), [existingId]);
    await finish(tester);
  });

  testWidgets('senza abbinamenti da fare si passa dall\'anteprima alle opzioni', (tester) async {
    await pumpAt(tester, AppRoutes.import);
    await pick(tester, ['01/10/2026;spesa;10,00;;Contanti;;Casa;;;']);
    await tapVisible(tester, find.text('Continua'));
    expect(find.text('3 di 4'), findsOneWidget);
    await tapVisible(tester, find.byTooltip('Indietro'));
    expect(find.text('1 di 4'), findsOneWidget, reason: 'indietro torna all\'anteprima');
    await finish(tester);
  });

  testWidgets('file non .csv o con intestazioni sbagliate: messaggio, niente da importare', (tester) async {
    await pumpAt(tester, AppRoutes.import);
    files.next = (name: 'foto.jpg', content: 'x');
    await tester.tap(find.text('Scegli file'));
    await waitFor(tester, () => find.textContaining('non è un file .csv').evaluate().isNotEmpty);
    expect(find.text('«foto.jpg» non è un file .csv'), findsOneWidget);

    files.next = (name: 'vecchio.csv', content: 'data;importo\n01/10/2026;5');
    await tester.tap(find.text('Scegli file'));
    await waitFor(tester, () => find.text('Scegli un altro file').evaluate().isNotEmpty);
    expect(find.textContaining('Il file non si può importare. Intestazioni non riconosciute'), findsOneWidget);
    expect(find.text('Continua'), findsNothing);
    await finish(tester);
  });

  testWidgets('errore durante l\'importazione: non viene importato nulla e si resta alle opzioni', (tester) async {
    await pumpAt(tester, AppRoutes.import);
    await tester.runAsync(
      () => db.customStatement(
        "CREATE TRIGGER errore_simulato BEFORE INSERT ON transactions WHEN NEW.note = 'boom' "
        "BEGIN SELECT RAISE(ABORT, 'errore simulato'); END;",
      ),
    );
    await pick(tester, [
      '01/10/2026;spesa;10,00;;Contanti;;Casa;;ok;',
      '02/10/2026;spesa;20,00;;Contanti;;Casa;;boom;',
    ]);
    await tapVisible(tester, find.text('Continua'));
    await tapVisible(tester, find.text('Importa 2 movimenti'));
    await waitFor(tester, () => find.textContaining('Importazione non riuscita').evaluate().isNotEmpty);
    expect(find.text('3 di 4'), findsOneWidget);
    final all = await rows(tester);
    expect(all.map((r) => r.id), [existingId]);
    expect(await tester.runAsync(() => db.select(db.imports).get()), isEmpty);
    await finish(tester);
  });
}
