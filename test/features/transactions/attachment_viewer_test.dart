import 'dart:convert';
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
import 'package:spese_entrate/core/ids.dart';
import 'package:spese_entrate/core/router/app_router.dart';
import 'package:spese_entrate/core/router/app_routes.dart';
import 'package:spese_entrate/data/db/app_database.dart';
import 'package:spese_entrate/data/db/database_provider.dart';
import 'package:spese_entrate/data/files/attachment_picker.dart';
import 'package:spese_entrate/data/files/attachment_storage.dart';
import 'package:spese_entrate/data/files/external_file_opener.dart';
import 'package:spese_entrate/data/files/file_sharer.dart';
import 'package:spese_entrate/data/repositories/repository_providers.dart';
import 'package:spese_entrate/domain/models/attachment.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/transaction.dart';
import 'package:spese_entrate/features/transactions/presentation/attachment_viewer_screen.dart';
import 'package:spese_entrate/features/transactions/presentation/transaction_detail_screen.dart';

import 'attachment_lifecycle_test.dart' show FakeOpener, FakeSharer;

/// PNG 1×1 valido.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

void main() {
  setUpAll(() => initializeDateFormatting('it_IT'));
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late ProviderContainer container;
  late AttachmentStorage storage;
  late FakeOpener opener;
  late FakeSharer sharer;
  late List<Attachment> attachments;
  late String txId;

  /// Modifica movimento di una spesa con due foto e un PDF.
  Future<void> pumpEdit(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = AppDatabase(NativeDatabase.memory(), now: () => DateTime.utc(2026, 10, 3, 8));
    final documents = (await tester.runAsync(() => Directory.systemTemp.createTemp('spese_entrate_docs_')))!;
    storage = AttachmentStorage(documentsDirectory: () async => documents);
    opener = FakeOpener();
    sharer = FakeSharer();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 3, 9)),
        attachmentStorageProvider.overrideWithValue(storage),
        externalFileOpenerProvider.overrideWithValue(opener),
        fileSharerProvider.overrideWithValue(sharer),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
      await tester.runAsync(() => documents.delete(recursive: true));
    });

    await tester.runAsync(() async {
      txId = newId();
      PickedAttachment file(String name, List<int> bytes) =>
          PickedAttachment(name: name, mimeType: mimeTypeForName(name), openRead: () => Stream.value(bytes));
      attachments = [
        await storage.store(txId, file('uno.png', _png)),
        await storage.store(txId, file('fattura.pdf', utf8.encode('%PDF-1.4'))),
        await storage.store(txId, file('due.png', _png)),
      ];
      await container
          .read(transactionRepositoryProvider)
          .save(
            Transaction(
              id: txId,
              type: TransactionType.expense,
              amountCents: 6420,
              date: LocalDate(2026, 10, 1),
              walletId: (await db.select(db.wallets).get()).first.id,
              categoryId: (await db.select(db.categories).get()).first.id,
              note: 'Esselunga',
            ),
            attachments: attachments,
          );
    });

    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const App()));
    await tester.pumpAndSettle();
    container.read(appRouterProvider).push(AppRoutes.transaction(txId));
    await tester.pumpAndSettle();
    final list = find.descendant(of: find.byType(TransactionDetailScreen), matching: find.byType(ListView));
    await tester.scrollUntilVisible(
      find.textContaining('Creato il'),
      200,
      scrollable: find.descendant(of: list, matching: find.byType(Scrollable)).first,
    );
    await tester.pumpAndSettle();
  }

  String nameOf(Attachment attachment) => attachment.localPath.split('/').last;

  /// Lascia completare l'I/O reale (controllo del file) finché [done] è vero, poi ridisegna.
  Future<void> settleIo(WidgetTester tester, [bool Function()? done]) async {
    for (var i = 0; i < 100 && !(done?.call() ?? false); i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
  }

  testWidgets('foto: visualizzatore a schermo intero, scorre tra le immagini e condivide', (tester) async {
    await pumpEdit(tester);
    await tester.tap(find.bySemanticsLabel('Apri ${nameOf(attachments[2])}'));
    await tester.pumpAndSettle();
    await settleIo(tester, () => find.byType(InteractiveViewer).evaluate().isNotEmpty);

    expect(find.byType(AttachmentViewerScreen), findsOneWidget);
    expect(find.text('2 di 2'), findsOneWidget, reason: 'solo le immagini, aperta sulla seconda');
    expect(find.byType(InteractiveViewer), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('1 di 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Condividi'));
    await settleIo(tester, () => sharer.shared.isNotEmpty);
    expect(sharer.shared, [(await tester.runAsync(() => storage.fileFor(attachments[0])))!.path]);

    await tester.tap(find.byTooltip('Chiudi'));
    await tester.pumpAndSettle();
    expect(find.byType(TransactionDetailScreen), findsOneWidget);
  });

  testWidgets('pinch-to-zoom: ingrandita non cambia pagina; doppio tocco torna normale', (tester) async {
    await pumpEdit(tester);
    await tester.tap(find.bySemanticsLabel('Apri ${nameOf(attachments[0])}'));
    await tester.pumpAndSettle();
    await settleIo(tester, () => find.byType(InteractiveViewer).evaluate().isNotEmpty);
    expect(find.text('1 di 2'), findsOneWidget);

    // Due dita che si allontanano.
    final center = tester.getCenter(find.byType(InteractiveViewer));
    final first = await tester.startGesture(center - const Offset(20, 0));
    final second = await tester.startGesture(center + const Offset(20, 0), pointer: 7);
    for (var i = 0; i < 10; i++) {
      await first.moveBy(const Offset(-10, 0));
      await second.moveBy(const Offset(10, 0));
      await tester.pump();
    }
    await first.up();
    await second.up();
    await tester.pumpAndSettle();
    PageView pageView() => tester.widget<PageView>(find.byType(PageView));
    expect(pageView().physics, isA<NeverScrollableScrollPhysics>());

    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('1 di 2'), findsOneWidget, reason: 'ingrandita, il trascinamento sposta l\'immagine');

    await tester.tap(find.byType(InteractiveViewer));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byType(InteractiveViewer));
    await tester.pumpAndSettle();
    expect(pageView().physics, isNull);
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('2 di 2'), findsOneWidget);
  });

  testWidgets('foto mancante: messaggio chiaro al posto dell\'immagine, nessun crash', (tester) async {
    await pumpEdit(tester);
    await tester.runAsync(() async => (await storage.fileFor(attachments[0])).delete());
    await tester.tap(find.bySemanticsLabel('Apri ${nameOf(attachments[0])}'));
    await tester.pumpAndSettle();
    final missing = find.text('Il file di questo allegato non si trova più sul telefono.');
    await settleIo(tester, () => missing.evaluate().isNotEmpty);
    expect(missing, findsOneWidget);

    await tester.tap(find.byTooltip('Condividi'));
    await settleIo(tester, () => missing.evaluate().length > 1);
    expect(sharer.shared, isEmpty);
    expect(find.text('Il file di questo allegato non si trova più sul telefono.'), findsWidgets);
  });

  testWidgets('PDF: Apri con un\'app esterna; senza app adatta un messaggio', (tester) async {
    await pumpEdit(tester);
    await tester.tap(find.bySemanticsLabel('Apri ${nameOf(attachments[1])}'));
    await tester.pumpAndSettle();
    expect(find.text('Documento PDF'), findsOneWidget);
    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();
    await settleIo(tester, () => opener.opened.isNotEmpty);
    expect(opener.opened.single.$2, 'application/pdf');

    opener.result = ExternalOpenResult.noApp;
    await tester.tap(find.bySemanticsLabel('Apri ${nameOf(attachments[1])}'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();
    await settleIo(tester, () => opener.opened.length > 1);
    await tester.pump();
    expect(find.text('Nessuna app installata può aprire questo file. Prova con "Condividi".'), findsOneWidget);
  });

  testWidgets('PDF danneggiato: Condividi non parte e spiega il motivo', (tester) async {
    await pumpEdit(tester);
    await tester.runAsync(() async => (await storage.fileFor(attachments[1])).writeAsString('rovinato'));
    await tester.tap(find.bySemanticsLabel('Apri ${nameOf(attachments[1])}'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Condividi'));
    await tester.pumpAndSettle();
    final damaged = find.text('Il file di questo allegato è danneggiato e non si può aprire.');
    await settleIo(tester, () => damaged.evaluate().isNotEmpty);
    expect(sharer.shared, isEmpty);
    expect(find.text('Il file di questo allegato è danneggiato e non si può aprire.'), findsOneWidget);
  });
}
