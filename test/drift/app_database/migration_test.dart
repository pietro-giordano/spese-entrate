// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
// Generato da `dart run drift_dev make-migrations`, poi completato a mano il test dei dati.
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:spese_entrate/data/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

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
}
