import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spese_entrate/core/dates.dart';
import 'package:spese_entrate/core/ids.dart';
import 'package:spese_entrate/data/db/app_database.dart';
import 'package:spese_entrate/data/files/attachment_picker.dart';
import 'package:spese_entrate/data/files/attachment_storage.dart';
import 'package:spese_entrate/data/files/orphan_attachment_cleaner.dart';
import 'package:spese_entrate/data/repositories/drift_transaction_repository.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/transaction.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late Directory documents;
  late AttachmentStorage storage;
  late DriftTransactionRepository transactions;
  late OrphanAttachmentCleaner cleaner;
  late Transaction tx;
  var now = DateTime(2026, 10, 3, 9);

  PickedAttachment file(String name) =>
      PickedAttachment(name: name, mimeType: mimeTypeForName(name), openRead: () => Stream.value(utf8.encode(name)));

  setUp(() async {
    now = DateTime(2026, 10, 3, 9);
    db = AppDatabase(NativeDatabase.memory());
    documents = await Directory.systemTemp.createTemp('spese_entrate_docs_');
    storage = AttachmentStorage(documentsDirectory: () async => documents);
    transactions = DriftTransactionRepository(db);
    cleaner = OrphanAttachmentCleaner(storage: storage, transactions: transactions, now: () => now);
    final wallets = await db.select(db.wallets).get();
    tx = Transaction(
      id: newId(),
      type: TransactionType.transfer,
      amountCents: 100,
      date: LocalDate(2026, 10, 1),
      walletId: wallets[0].id,
      toWalletId: wallets[1].id,
    );
  });
  tearDown(() async {
    await db.close();
    await documents.delete(recursive: true);
  });

  test('orfano = file senza alcun record; i file di allegati cancellati o di movimenti eliminati restano', () async {
    final kept = await storage.store(tx.id, file('attivo.jpg'));
    final removed = await storage.store(tx.id, file('tolto.jpg'));
    await transactions.save(tx, attachments: [kept, removed]);
    await transactions.save(tx, removedAttachmentIds: [removed.id]); // cancellato logicamente
    final other = tx.copyWith(id: newId());
    final ofDeleted = await storage.store(other.id, file('eliminato.pdf'));
    await transactions.save(other, attachments: [ofDeleted]);
    await transactions.delete(other.id); // movimento eliminato: si può ancora annullare
    final orphan = await storage.store('mai-salvato', file('orfano.jpg'));

    // L'età si misura dall'ora di modifica reale del file.
    now = DateTime.now().add(const Duration(days: 2));
    expect(await cleaner.findOrphans(), [orphan.localPath]);
    expect(await cleaner.deleteOrphans(), [orphan.localPath]);

    expect(
      (await storage.listFiles()).map((f) => f.localPath),
      unorderedEquals([kept.localPath, removed.localPath, ofDeleted.localPath]),
    );
  });

  test('un file appena copiato (salvataggio in corso) non è mai considerato orfano', () async {
    await storage.store('in-corso', file('nuovo.jpg'));
    now = DateTime.now();
    expect(await cleaner.findOrphans(), isEmpty);
    expect(await cleaner.deleteOrphans(), isEmpty);
    expect(await storage.listFiles(), hasLength(1));
    expect(await cleaner.findOrphans(minAge: Duration.zero), hasLength(1));
  });
}
