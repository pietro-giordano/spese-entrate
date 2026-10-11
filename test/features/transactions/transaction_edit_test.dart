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
import 'package:spese_entrate/data/db/app_database.dart';
import 'package:spese_entrate/data/db/database_provider.dart';
import 'package:spese_entrate/data/files/attachment_picker.dart';
import 'package:spese_entrate/data/files/attachment_storage.dart';
import 'package:spese_entrate/data/repositories/repository_providers.dart';
import 'package:spese_entrate/domain/models/attachment.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/transaction.dart';
import 'package:spese_entrate/features/transactions/application/transaction_form_controller.dart';
import 'package:spese_entrate/features/transactions/presentation/transaction_detail_screen.dart';

class FakeAttachmentPicker extends AttachmentPicker {
  @override
  Future<PickedAttachment?> pickFile() async =>
      PickedAttachment(name: 'nuovo.pdf', mimeType: 'application/pdf', openRead: () => Stream.value(utf8.encode('x')));
}

void main() {
  setUpAll(() => initializeDateFormatting('it_IT'));
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late ProviderContainer container;
  late AppDatabase db;
  late Directory documents;
  late Transaction groceries;
  late Attachment receipt;

  /// DB in memoria con una spesa "Esselunga" del 1° ottobre e un allegato.
  Future<void> setUpData() async {
    db = AppDatabase(NativeDatabase.memory(), now: () => DateTime.utc(2026, 10, 3, 8));
    documents = await Directory.systemTemp.createTemp('spese_entrate_docs_');
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 3, 9)),
        attachmentPickerProvider.overrideWithValue(FakeAttachmentPicker()),
        attachmentStorageProvider.overrideWithValue(AttachmentStorage(documentsDirectory: () async => documents)),
      ],
    );
    final wallets = await container.read(walletRepositoryProvider).watchAll().first;
    final categories = await container.read(categoryRepositoryProvider).watchAll().first;
    groceries = Transaction(
      id: newId(),
      type: TransactionType.expense,
      amountCents: 6420,
      date: LocalDate(2026, 10, 1),
      walletId: wallets.first.id,
      categoryId: categories.firstWhere((c) => c.name == 'Spesa alimentare').id,
      note: 'Esselunga',
    );
    receipt = Attachment(
      id: newId(),
      transactionId: groceries.id,
      localPath: 'attachments/${groceries.id}/scontrino.jpg',
      mimeType: 'image/jpeg',
      sizeBytes: 3,
      sha256: 'x',
    );
    await container.read(transactionRepositoryProvider).save(groceries, attachments: [receipt]);
  }

  Future<void> tearDownData() async {
    container.dispose();
    await db.close();
    await documents.delete(recursive: true);
  }

  group('TransactionFormController in modifica', () {
    setUp(setUpData);
    tearDown(tearDownData);

    TransactionFormSeed seed() => TransactionFormSeed.edit(groceries, [receipt]);
    TransactionFormController controller() => container.read(transactionFormControllerProvider(seed()).notifier);

    setUp(() => container.listen(transactionFormControllerProvider(seed()), (_, _) {}));

    test('parte dai valori del movimento, senza modifiche', () {
      final state = container.read(transactionFormControllerProvider(seed()));
      expect((state.amountCents, state.note, state.date), (6420, 'Esselunga', LocalDate(2026, 10, 1)));
      expect(state.expenseWalletId, groceries.walletId);
      expect(state.savedAttachments, [receipt]);
      expect(controller().isDirty, isFalse);
    });

    test('isDirty segue le modifiche e torna false se si ripristina il valore', () {
      controller().setAmount(7000);
      expect(controller().isDirty, isTrue);
      controller().setAmount(6420);
      expect(controller().isDirty, isFalse);

      controller().setNote('Esselunga  ');
      expect(controller().isDirty, isFalse, reason: 'gli spazi ai lati non contano');

      controller().toggleLabel('home');
      expect(controller().isDirty, isTrue);
      controller().toggleLabel('home');
      expect(controller().isDirty, isFalse);

      controller().removeSavedAttachment(receipt);
      expect(controller().isDirty, isTrue);
    });

    test('il salvataggio mantiene ID, stato e ricorrenza e rimuove gli allegati tolti', () async {
      controller()
        ..setAmount(7000)
        ..removeSavedAttachment(receipt);
      final saved = await controller().save(walletId: groceries.walletId);

      final repo = container.read(transactionRepositoryProvider);
      expect(saved!.id, groceries.id);
      expect(await repo.getById(groceries.id), groceries.copyWith(amountCents: 7000));
      expect(await repo.getAttachments(groceries.id), isEmpty);
      expect((await repo.watchAll().first), hasLength(1));
    });
  });

  group('Modifica movimento', () {
    Future<void> pumpEdit(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.runAsync(setUpData);
      addTearDown(() => tester.runAsync(tearDownData));

      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const App()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Esselunga'));
      await tester.pumpAndSettle();
      expect(find.byType(TransactionDetailScreen), findsOneWidget);
    }

    Future<List<Transaction>> stored(WidgetTester tester) async =>
        (await tester.runAsync(() => container.read(transactionRepositoryProvider).watchAll().first))!;

    /// La sezione Allegati è in fondo alla lista: va portata a schermo prima di guardarla.
    Future<void> scrollToAttachments(WidgetTester tester) async {
      // Anche i campi di testo contengono uno Scrollable: si sceglie quello della lista.
      final list = find.descendant(of: find.byType(TransactionDetailScreen), matching: find.byType(ListView));
      await tester.scrollUntilVisible(
        find.textContaining('Creato il'),
        200,
        scrollable: find.descendant(of: list, matching: find.byType(Scrollable)).first,
      );
      await tester.pumpAndSettle();
    }

    FilledButton saveButton(WidgetTester tester) =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Salva modifiche'));

    testWidgets('mostra i dati e salva solo dopo una modifica', (tester) async {
      await pumpEdit(tester);

      expect(find.text('Modifica movimento'), findsOneWidget);
      expect(find.text('64,20'), findsOneWidget);
      expect(find.text('Giovedì 1 ottobre 2026'), findsOneWidget);
      await scrollToAttachments(tester);
      expect(find.text('1 di 5'), findsOneWidget);
      expect(find.textContaining('Creato il 3 ott 2026'), findsOneWidget);
      expect(saveButton(tester).onPressed, isNull, reason: 'nessuna modifica');

      await tester.enterText(find.widgetWithText(TextField, 'Esselunga'), 'Esselunga Via Roma');
      await tester.pump();
      expect(saveButton(tester).onPressed, isNotNull);

      await tester.tap(find.text('Salva modifiche'));
      await tester.pumpAndSettle();
      expect(find.byType(TransactionDetailScreen), findsNothing);
      expect(find.text('Modifiche salvate'), findsOneWidget);
      expect(find.text('Esselunga Via Roma'), findsOneWidget);
    });

    testWidgets('importo non valido: errore al salvataggio', (tester) async {
      await pumpEdit(tester);
      await tester.enterText(find.widgetWithText(TextField, '64,20'), '12,345');
      await tester.pump();
      await tester.tap(find.text('Salva modifiche'));
      await tester.pumpAndSettle();
      expect(find.text('Inserisci un importo valido'), findsOneWidget);
      expect((await stored(tester)).single.amountCents, 6420);
    });

    testWidgets('Duplica crea una copia di oggi con nuovo ID e senza allegati', (tester) async {
      await pumpEdit(tester);
      await tester.tap(find.byTooltip('Duplica movimento'));
      await tester.pumpAndSettle();

      expect(find.text('Movimento duplicato'), findsOneWidget);
      expect(find.byType(TransactionDetailScreen), findsOneWidget);
      await scrollToAttachments(tester);
      expect(find.text('0 di 5'), findsOneWidget);

      final all = await stored(tester);
      expect(all, hasLength(2));
      final copy = all.firstWhere((t) => t.id != groceries.id);
      expect(copy.date, LocalDate(2026, 10, 3));
      expect(copy.copyWith(id: groceries.id, date: groceries.date), groceries);
      final copyAttachments = await tester.runAsync(
        () => container.read(transactionRepositoryProvider).getAttachments(copy.id),
      );
      expect(copyAttachments, isEmpty);
    });

    testWidgets('Duplica è disattivato con modifiche non salvate', (tester) async {
      await pumpEdit(tester);
      await tester.enterText(find.widgetWithText(TextField, 'Esselunga'), 'Altro');
      await tester.pump();
      expect(find.byTooltip('Salva le modifiche prima di duplicare'), findsOneWidget);
    });

    testWidgets('Elimina chiede conferma, cancella e Annulla ripristina', (tester) async {
      await pumpEdit(tester);

      await tester.tap(find.byTooltip('Elimina movimento'));
      await tester.pumpAndSettle();
      expect(find.text('Eliminare questo movimento?'), findsOneWidget);
      expect(find.textContaining('Esselunga · − € 64,20.'), findsOneWidget);

      // Annulla nel dialog: non succede nulla.
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Annulla')));
      await tester.pumpAndSettle();
      expect(find.byType(TransactionDetailScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Elimina movimento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elimina'));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionDetailScreen), findsNothing);
      expect(find.text('Movimento eliminato'), findsOneWidget);
      expect(find.text('Esselunga'), findsNothing);
      expect(await stored(tester), isEmpty);

      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();
      expect(find.text('Esselunga'), findsOneWidget);
      expect((await stored(tester)).single.id, groceries.id);
    });

    testWidgets('allegati: rimozione e aggiunta', (tester) async {
      await pumpEdit(tester);
      await scrollToAttachments(tester);

      await tester.tap(find.bySemanticsLabel('Rimuovi scontrino.jpg'));
      await tester.pump();
      expect(find.text('0 di 5'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Aggiungi allegato'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scegli un file (PDF, immagine)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fatto'));
      await tester.pumpAndSettle();
      expect(find.text('1 di 5'), findsOneWidget);
      expect(find.bySemanticsLabel('Rimuovi nuovo.pdf'), findsOneWidget);

      await tester.tap(find.text('Salva modifiche'));
      for (var i = 0; i < 50 && find.byType(TransactionDetailScreen).evaluate().isNotEmpty; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      final attachments = (await tester.runAsync(
        () => container.read(transactionRepositoryProvider).getAttachments(groceries.id),
      ))!;
      expect(attachments.map((a) => a.mimeType), ['application/pdf']);
      expect(attachments.single.id, isNot(receipt.id));
    });
  });
}
