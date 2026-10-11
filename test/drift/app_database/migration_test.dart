// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
// Generato da `dart run drift_dev make-migrations`, poi completato a mano il test dei dati.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:spese_entrate/data/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  // Con la v2 si aggiunge solo una colonna: i dati esistenti devono restare identici
  // e la nuova data di verifica parte vuota.
  test(
    'da v1 a v2: i portafogli restano e last_balance_verified_date è null',
    () async {
      const oldWallet = v1.WalletsData(
        id: 'w1',
        createdAt: 1,
        updatedAt: 2,
        deviceId: 'device',
        name: 'Conto corrente',
        type: 'checking',
        currency: 'EUR',
        initialBalanceCents: 12345,
        initialBalanceDate: '2026-01-01',
        includeInTotal:
            1, // negli schemi generati i booleani sono interi, come in SQLite
        sortOrder: 0,
      );
      const expectedWallet = v2.WalletsData(
        id: 'w1',
        createdAt: 1,
        updatedAt: 2,
        deviceId: 'device',
        name: 'Conto corrente',
        type: 'checking',
        currency: 'EUR',
        initialBalanceCents: 12345,
        initialBalanceDate: '2026-01-01',
        includeInTotal:
            1, // negli schemi generati i booleani sono interi, come in SQLite
        sortOrder: 0,
        lastBalanceVerifiedDate: null,
      );

      await verifier.testWithDataIntegrity(
        oldVersion: 1,
        newVersion: 2,
        createOld: v1.DatabaseAtV1.new,
        createNew: v2.DatabaseAtV2.new,
        openTestedDatabase: AppDatabase.new,
        createItems: (batch, oldDb) => batch.insert(oldDb.wallets, oldWallet),
        validateItems: (newDb) async {
          expect(await newDb.select(newDb.wallets).get(), [expectedWallet]);
          // All'apertura l'app crea il device_id, ma non ripete i dati iniziali su un DB esistente.
          expect(await newDb.select(newDb.categories).get(), isEmpty);
        },
      );
    },
  );

  // v3: tabella imports e transactions.import_batch_id. Ogni riga esistente deve arrivare
  // identica (confronto per mappe JSON tra le classi generate di v2 e v3), con la nuova
  // colonna vuota; la nuova tabella è vuota e utilizzabile.
  group('da v2 a v3 (import)', () {
    const wallet = v2.WalletsData(
      id: 'w1',
      createdAt: 1,
      updatedAt: 2,
      deviceId: 'device',
      name: 'Conto corrente',
      type: 'checking',
      currency: 'EUR',
      initialBalanceCents: 12345,
      initialBalanceDate: '2026-01-01',
      includeInTotal: 1,
      sortOrder: 0,
      lastBalanceVerifiedDate: '2026-09-30',
    );
    const category = v2.CategoriesData(
      id: 'c1',
      createdAt: 1,
      updatedAt: 1,
      deviceId: 'device',
      name: 'Casa',
      kind: 'expense',
      color: 0xFFC2410C,
      sortOrder: 0,
    );
    const label = v2.LabelsData(
      id: 'l1',
      createdAt: 1,
      updatedAt: 1,
      deviceId: 'device',
      name: 'casa',
      color: 0,
    );
    const rent = v2.TransactionsData(
      id: 't1',
      createdAt: 3,
      updatedAt: 4,
      deviceId: 'device',
      type: 'expense',
      status: 'confirmed',
      amountCents: 75000,
      currency: 'EUR',
      date: '2026-10-01',
      walletId: 'w1',
      categoryId: 'c1',
      note: 'Affitto',
      recurrenceId: 'r1',
      occurrenceDate: '2026-10-01',
    );
    const deleted = v2.TransactionsData(
      id: 't2',
      createdAt: 5,
      updatedAt: 6,
      deletedAt: 6,
      deviceId: 'device',
      type: 'adjustment',
      status: 'confirmed',
      amountCents: -500,
      currency: 'EUR',
      date: '2026-10-02',
      walletId: 'w1',
    );
    const link = v2.TransactionLabelsData(
      id: 'tl1',
      createdAt: 3,
      updatedAt: 3,
      deviceId: 'device',
      transactionId: 't1',
      labelId: 'l1',
    );
    const outbox = v2.OutboxData(
      id: 1,
      entity: 'transactions',
      entityId: 't1',
      op: 'upsert',
      changedAt: 4,
    );

    test('nessun dato perso, import_batch_id vuoto, tabella imports vuota con indice', () async {
      await verifier.testWithDataIntegrity(
        oldVersion: 2,
        newVersion: 3,
        createOld: v2.DatabaseAtV2.new,
        createNew: v3.DatabaseAtV3.new,
        openTestedDatabase: AppDatabase.new,
        createItems: (batch, oldDb) {
          batch
            ..insert(oldDb.wallets, wallet)
            ..insert(oldDb.categories, category)
            ..insert(oldDb.labels, label)
            ..insertAll(oldDb.transactions, [rent, deleted])
            ..insert(oldDb.transactionLabels, link)
            ..insert(oldDb.outbox, outbox);
        },
        validateItems: (newDb) async {
          Future<List<Map<String, dynamic>>> json<
            T extends Table,
            D extends DataClass
          >(TableInfo<T, D> table) async => [
            for (final row in await newDb.select(table).get()) row.toJson(),
          ];

          expect(await json(newDb.wallets), [wallet.toJson()]);
          expect(await json(newDb.categories), [category.toJson()]);
          expect(await json(newDb.labels), [label.toJson()]);
          expect(await json(newDb.transactionLabels), [link.toJson()]);
          expect(await json(newDb.outbox), [outbox.toJson()]);
          expect(await json(newDb.transactions), [
            {...rent.toJson(), 'importBatchId': null},
            {...deleted.toJson(), 'importBatchId': null},
          ], reason: 'anche i movimenti cancellati logicamente restano');
          expect(await newDb.select(newDb.imports).get(), isEmpty);

          final indexes = await newDb
              .customSelect(
                "SELECT name FROM sqlite_master WHERE type = 'index' AND tbl_name = 'transactions'",
              )
              .map((row) => row.read<String>('name'))
              .get();
          expect(indexes, contains('transactions_import_batch_id'));
        },
      );
    });

    test('dopo la migrazione un import e i suoi movimenti si scrivono e si leggono', () async {
      final schema = await verifier.schemaAt(2);
      final oldDb = v2.DatabaseAtV2(schema.newConnection());
      await oldDb.into(oldDb.wallets).insert(wallet);
      await oldDb.into(oldDb.categories).insert(category);
      await oldDb.into(oldDb.transactions).insert(rent);
      await oldDb.close();

      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 3);
      await db
          .into(db.imports)
          .insert(
            ImportsCompanion.insert(
              id: 'i1',
              createdAt: 10,
              updatedAt: 10,
              deviceId: 'device',
              fileName: 'estratto-conto.csv',
              rowCount: 12,
              insertedCount: 10,
              updatedCount: 1,
            ),
          );
      await (db.update(db.transactions)..where((t) => t.id.equals('t1'))).write(
        const TransactionsCompanion(importBatchId: Value('i1')),
      );
      final imported = await (db.select(
        db.transactions,
      )..where((t) => t.importBatchId.equals('i1'))).get();
      expect(imported.single.note, 'Affitto');
      expect((await db.select(db.imports).getSingle()).undoneAt, isNull);
      await expectLater(
        db.customStatement(
          'INSERT INTO imports (id, created_at, updated_at, device_id, file_name, row_count, inserted_count, updated_count) '
          "VALUES ('i2', 1, 1, 'd', 'x.csv', -1, 0, 0)",
        ),
        throwsA(anything),
        reason: 'i conteggi non possono essere negativi',
      );
      await db.close();
    });
  });

  test(
    'da v1 a v3 in un colpo: si applicano tutti i passi, nell\'ordine',
    () async {
      const oldWallet = v1.WalletsData(
        id: 'w1',
        createdAt: 1,
        updatedAt: 2,
        deviceId: 'device',
        name: 'Contanti',
        type: 'cash',
        currency: 'EUR',
        initialBalanceCents: 0,
        initialBalanceDate: '2026-01-01',
        includeInTotal: 1,
        sortOrder: 1,
      );
      await verifier.testWithDataIntegrity(
        oldVersion: 1,
        newVersion: 3,
        createOld: v1.DatabaseAtV1.new,
        createNew: v3.DatabaseAtV3.new,
        openTestedDatabase: AppDatabase.new,
        createItems: (batch, oldDb) => batch.insert(oldDb.wallets, oldWallet),
        validateItems: (newDb) async {
          final wallets = await newDb.select(newDb.wallets).get();
          expect(wallets.single.toJson(), {
            ...oldWallet.toJson(),
            'lastBalanceVerifiedDate': null,
          });
          expect(await newDb.select(newDb.imports).get(), isEmpty);
        },
      );
    },
  );
}
