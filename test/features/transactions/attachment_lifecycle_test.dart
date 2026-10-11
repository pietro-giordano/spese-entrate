import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spese_entrate/core/clock.dart';
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
import 'package:spese_entrate/features/transactions/application/attachment_actions.dart';
import 'package:spese_entrate/features/transactions/application/transaction_form_controller.dart';

PickedAttachment picked(String name, [String? content]) => PickedAttachment(
  name: name,
  mimeType: mimeTypeForName(name),
  openRead: () => Stream.value(utf8.encode(content ?? name)),
);

/// Apre i file "per finta" e ricorda cosa ha aperto.
class FakeOpener extends ExternalFileOpener {
  ExternalOpenResult result = ExternalOpenResult.opened;
  final opened = <(String, String)>[];

  @override
  Future<ExternalOpenResult> open(String path, {required String mimeType}) async {
    opened.add((path, mimeType));
    return result;
  }
}

class FakeSharer extends FileSharer {
  final shared = <String>[];

  @override
  Future<void> shareFile(String path, {required String mimeType, String? subject}) async => shared.add(path);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late Directory documents;
  late AttachmentStorage storage;
  late ProviderContainer container;
  late String walletId;
  late String categoryId;
  late FakeOpener opener;
  late FakeSharer sharer;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory(), now: () => DateTime.utc(2026, 10, 3, 8));
    documents = await Directory.systemTemp.createTemp('spese_entrate_docs_');
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
    walletId = (await db.select(db.wallets).get()).first.id;
    categoryId = (await db.select(db.categories).get()).first.id;
    addTearDown(() async {
      container.dispose();
      await db.close();
      await documents.delete(recursive: true);
    });
  });

  /// Spesa nuova con [files] allegati, salvata dal form come in Inserimento rapido.
  Future<Transaction?> saveNew(List<PickedAttachment> files) async {
    const seed = TransactionFormSeed.create(TransactionType.expense);
    final provider = transactionFormControllerProvider(seed);
    container.listen(provider, (_, _) {});
    final form = container.read(provider.notifier)
      ..pressKey('5')
      ..selectCategory(categoryId);
    for (final file in files) {
      form.addAttachment(file);
    }
    return form.save(walletId: walletId);
  }

  Future<List<AttachmentRow>> attachmentRows() => db.select(db.attachments).get();

  group('rimozione e ripristino', () {
    test('rimuovere un allegato: cancellazione logica con outbox, il file resta su disco', () async {
      final tx = (await saveNew([picked('a.jpg'), picked('b.pdf')]))!;
      final repository = container.read(transactionRepositoryProvider);
      final attachments = await repository.getAttachments(tx.id);
      final removed = attachments.firstWhere((a) => a.mimeType == 'image/jpeg');

      final seed = TransactionFormSeed.edit(tx, attachments);
      container.listen(transactionFormControllerProvider(seed), (_, _) {});
      final form = container.read(transactionFormControllerProvider(seed).notifier)..removeSavedAttachment(removed);
      expect(container.read(transactionFormControllerProvider(seed)).savedAttachments, hasLength(1));
      final outboxBefore = (await db.select(db.outbox).get()).length;
      await form.save(walletId: walletId);

      expect((await repository.getAttachments(tx.id)).map((a) => a.id), [
        attachments.firstWhere((a) => a.id != removed.id).id,
      ]);
      final row = (await attachmentRows()).firstWhere((r) => r.id == removed.id);
      expect(row.deletedAt, isNotNull);
      final outbox = (await db.select(db.outbox).get()).skip(outboxBefore);
      expect(outbox.where((o) => o.entity == 'attachments').map((o) => (o.entityId, o.op)), [
        (removed.id, OutboxOp.delete),
      ]);
      expect(await (await storage.fileFor(removed)).exists(), isTrue, reason: 'il file non si cancella subito');
    });

    test('eliminare il movimento preserva gli allegati; "Annulla" li rende di nuovo disponibili', () async {
      final tx = (await saveNew([picked('a.jpg'), picked('b.pdf')]))!;
      final repository = container.read(transactionRepositoryProvider);
      final before = await repository.getAttachments(tx.id);

      await repository.delete(tx.id);
      expect(await repository.getById(tx.id), isNull);
      expect((await attachmentRows()).every((r) => r.deletedAt == null), isTrue);
      for (final attachment in before) {
        expect(await storage.check(attachment), AttachmentFileStatus.ok);
      }

      await repository.restore(tx.id);
      expect(await repository.getById(tx.id), isNotNull);
      expect(await repository.getAttachments(tx.id), before);
      final actions = container.read(attachmentActionsProvider);
      expect(await actions.openExternally(before.firstWhere((a) => a.mimeType == 'application/pdf')), isNull);
    });
  });

  group('nessun file orfano se il salvataggio fallisce', () {
    test('errore nel database: le copie vengono eliminate e non resta nessun record', () async {
      await db.customStatement(
        "CREATE TRIGGER errore_simulato BEFORE INSERT ON attachments BEGIN SELECT RAISE(ABORT, 'errore'); END;",
      );
      await expectLater(saveNew([picked('a.jpg'), picked('b.pdf')]), throwsA(isA<SqliteException>()));
      expect(await storage.listFiles(), isEmpty);
      expect(await db.select(db.transactions).get(), isEmpty);
      expect(await attachmentRows(), isEmpty);
    });

    test('copia interrotta al secondo file: anche il primo viene eliminato', () async {
      final broken = PickedAttachment(
        name: 'rotto.jpg',
        mimeType: 'image/jpeg',
        openRead: () async* {
          yield utf8.encode('metà');
          throw const FileSystemException('lettura interrotta');
        },
      );
      await expectLater(saveNew([picked('a.jpg'), broken]), throwsA(isA<FileSystemException>()));
      expect(await storage.listFiles(), isEmpty);
      expect(await db.select(db.transactions).get(), isEmpty);
    });
  });

  group('apertura e condivisione', () {
    late Attachment pdf;

    setUp(() async {
      final tx = (await saveNew([picked('fattura.pdf', '%PDF-1.4')]))!;
      pdf = (await container.read(transactionRepositoryProvider).getAttachments(tx.id)).single;
    });

    test('un PDF integro si apre con un\'altra app, con il suo tipo', () async {
      final actions = container.read(attachmentActionsProvider);
      expect(await actions.openExternally(pdf), isNull);
      expect(opener.opened.single, ((await storage.fileFor(pdf)).path, 'application/pdf'));
    });

    test('nessuna app o errore del sistema: messaggio, niente eccezioni', () async {
      final actions = container.read(attachmentActionsProvider);
      opener.result = ExternalOpenResult.noApp;
      expect(await actions.openExternally(pdf), AttachmentProblem.noApp);
      opener.result = ExternalOpenResult.failed;
      expect(await actions.openExternally(pdf), AttachmentProblem.failed);
    });

    test('file mancante o danneggiato: non si apre né si condivide', () async {
      final actions = container.read(attachmentActionsProvider);
      final file = await storage.fileFor(pdf);
      await file.writeAsString('%PDF-9.9');
      expect(await actions.openExternally(pdf), AttachmentProblem.corrupted);
      await file.delete();
      expect(await actions.openExternally(pdf), AttachmentProblem.missing);
      expect(await actions.share(pdf), AttachmentProblem.missing);
      expect(opener.opened, isEmpty);
      expect(sharer.shared, isEmpty);
    });

    test('condividi passa il file privato al menu del telefono', () async {
      expect(await container.read(attachmentActionsProvider).share(pdf), isNull);
      expect(sharer.shared, [(await storage.fileFor(pdf)).path]);
    });
  });

  test('restano al massimo 5 allegati per movimento', () async {
    const seed = TransactionFormSeed.create(TransactionType.expense);
    container.listen(transactionFormControllerProvider(seed), (_, _) {});
    final form = container.read(transactionFormControllerProvider(seed).notifier);
    for (var i = 0; i < 5; i++) {
      expect(form.addAttachment(picked('f$i.jpg')), isTrue);
    }
    expect(form.addAttachment(picked('troppi.jpg')), isFalse);
  });
}
