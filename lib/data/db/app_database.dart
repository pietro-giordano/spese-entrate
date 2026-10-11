import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../core/dates.dart';
import '../../core/ids.dart';
import '../../domain/models/enums.dart';
import 'app_database.steps.dart';
import 'converters.dart';
import 'seed.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Wallets,
    Categories,
    Labels,
    Transactions,
    TransactionLabels,
    Attachments,
    RecurrenceRules,
    RecurrenceExceptions,
    Imports,
    Settings,
    AppMeta,
    Outbox,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// [executor] è il motore SQLite (file sul dispositivo, oppure in memoria nei test).
  /// [now] permette ai test di fissare l'orologio.
  AppDatabase(super.executor, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  /// Database dell'app nel file `spese_entrate.sqlite` della cartella documenti.
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'spese_entrate'));

  final DateTime Function() _now;

  /// Istante attuale in millisecondi UTC, il formato di tutti i timestamp.
  int nowMs() => _now().toUtc().millisecondsSinceEpoch;

  /// Data di calendario di oggi sul dispositivo.
  LocalDate today() => LocalDate.fromDateTime(_now());

  /// Versione dello schema. Va incrementata a ogni modifica delle tabelle,
  /// insieme a una migrazione (vedi [migration]).
  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) => m.createAll(),
      // Un passo per ogni versione. Per aggiungerne uno: modifica le tabelle, incrementa
      // schemaVersion, lancia `dart run drift_dev make-migrations` (rigenera app_database.steps.dart
      // e i test in test/drift/) e aggiungi qui il nuovo `fromXToY`.
      onUpgrade: stepByStep(
        from1To2: (m, schema) async {
          await m.addColumn(schema.wallets, schema.wallets.lastBalanceVerifiedDate);
        },
        // v3: import da file. Una tabella nuova e una colonna (con indice) sui movimenti:
        // i dati esistenti restano, import_batch_id parte vuoto.
        from2To3: (m, schema) async {
          await m.createTable(schema.imports);
          await m.addColumn(schema.transactions, schema.transactions.importBatchId);
          await m.createIndex(schema.transactionsImportBatchId);
        },
      ),
      beforeOpen: (details) async {
        final deviceId = await _ensureDeviceId();
        if (details.wasCreated) {
          await seedInitialData(this, deviceId: deviceId);
        }
      },
    );
  }

  /// Legge il device_id da app_meta, generandolo la prima volta.
  Future<String> _ensureDeviceId() async {
    final existing = await (select(appMeta)..where((t) => t.key.equals(AppMetaKeys.deviceId))).getSingleOrNull();
    if (existing != null) return existing.value;

    final deviceId = newId(nowMs: nowMs());
    await into(appMeta).insert(AppMetaCompanion.insert(key: AppMetaKeys.deviceId, value: deviceId));
    return deviceId;
  }

  String? _deviceId;

  /// ID di questo dispositivo, da scrivere in `device_id` di ogni record.
  Future<String> deviceId() async {
    return _deviceId ??= (await (select(appMeta)..where((t) => t.key.equals(AppMetaKeys.deviceId))).getSingle()).value;
  }

  /// Aggiunge una riga alla coda di sincronizzazione.
  /// Va chiamata nella stessa transazione della scrittura che la riguarda.
  Future<void> enqueueChange(String entity, String entityId, OutboxOp op, int changedAt) {
    return into(outbox)
        .insert(OutboxCompanion.insert(entity: entity, entityId: entityId, op: op, changedAt: changedAt));
  }

  /// Crea o aggiorna il record [id] di una tabella sincronizzabile.
  ///
  /// [values] è un Companion con i soli campi propri della tabella. Qui si impostano
  /// `updated_at` e `device_id`, si conserva `created_at` (o lo si imposta alla creazione)
  /// e si azzera `deleted_at`: salvare un record cancellato lo ripristina.
  /// Accoda un `upsert` nell'outbox. Tutto in una transazione.
  Future<void> upsertSynced<T extends Table, D>(TableInfo<T, D> table, String id, Insertable<D> values) {
    _requireSyncTable(table);
    return transaction(() async {
      final now = nowMs();
      final columns = {
        ...values.toColumns(false),
        'id': Variable<String>(id),
        'updated_at': Variable<int>(now),
        'device_id': Variable<String>(await deviceId()),
        'deleted_at': const Variable<int>(null),
      };
      final updated = await (update(
        table,
      )..where((t) => (t as SyncColumns).id.equals(id))).write(RawValuesInsertable<D>(columns));
      if (updated == 0) {
        await into(table).insert(RawValuesInsertable<D>({...columns, 'created_at': Variable<int>(now)}));
      }
      await enqueueChange(table.actualTableName, id, OutboxOp.upsert, now);
    });
  }

  /// Cancellazione logica: imposta `deleted_at`, `updated_at` e `device_id` e accoda un `delete`
  /// nell'outbox, tutto in una transazione. Restituisce false se il record non esiste o era già cancellato.
  Future<bool> softDelete<T extends Table, D>(TableInfo<T, D> table, String id) {
    _requireSyncTable(table);
    return transaction(() async {
      final now = nowMs();
      final query = update(table)
        ..where((t) {
          final columns = t as SyncColumns;
          return columns.id.equals(id) & columns.deletedAt.isNull();
        });
      final changed = await query.write(
        RawValuesInsertable<D>({
          'deleted_at': Variable<int>(now),
          'updated_at': Variable<int>(now),
          'device_id': Variable<String>(await deviceId()),
        }),
      );
      if (changed == 0) return false;
      await enqueueChange(table.actualTableName, id, OutboxOp.delete, now);
      return true;
    });
  }

  /// Annulla una cancellazione logica: azzera `deleted_at`, imposta `updated_at` e `device_id`
  /// e accoda un `upsert` nell'outbox. Restituisce false se il record non era cancellato.
  Future<bool> restoreSynced<T extends Table, D>(TableInfo<T, D> table, String id) {
    _requireSyncTable(table);
    return transaction(() async {
      final now = nowMs();
      final query = update(table)
        ..where((t) {
          final columns = t as SyncColumns;
          return columns.id.equals(id) & columns.deletedAt.isNotNull();
        });
      final changed = await query.write(
        RawValuesInsertable<D>({
          'deleted_at': const Variable<int>(null),
          'updated_at': Variable<int>(now),
          'device_id': Variable<String>(await deviceId()),
        }),
      );
      if (changed == 0) return false;
      await enqueueChange(table.actualTableName, id, OutboxOp.upsert, now);
      return true;
    });
  }

  void _requireSyncTable(TableInfo<Table, dynamic> table) {
    if (table is! SyncColumns) {
      throw ArgumentError('${table.actualTableName} non è una tabella sincronizzabile');
    }
  }
}

/// Chiavi della tabella `settings`.
abstract final class SettingKeys {
  static const defaultExpenseWalletId = 'default_expense_wallet_id';
  static const defaultIncomeWalletId = 'default_income_wallet_id';
  static const weekStart = 'week_start';
  static const defaultPeriod = 'default_period';
  static const currency = 'currency';
}

/// Chiavi di `app_meta`.
abstract final class AppMetaKeys {
  static const deviceId = 'device_id';
  static const themeMode = 'theme_mode';
  static const biometricLock = 'biometric_lock';
  static const profileName = 'profile_name';
  static const profileEmail = 'profile_email';
}

/// Filtro per le query "normali": esclude i record cancellati logicamente.
///
/// Uso: `(db.select(db.wallets)..whereNotDeleted()).get()`.
extension NotDeletedFilter<T extends HasResultSet, D> on SimpleSelectStatement<T, D> {
  void whereNotDeleted() => where((t) => (t as SyncColumns).deletedAt.isNull());
}
