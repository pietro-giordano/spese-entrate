import 'package:drift/drift.dart';

import '../../domain/models/import_record.dart';
import '../../domain/models/transaction.dart';
import '../../domain/repositories/import_repository.dart';
import '../../domain/services/import_operations.dart';
import '../db/app_database.dart';
import 'drift_transaction_repository.dart';
import 'mappers.dart';

class DriftImportRepository implements ImportRepository {
  DriftImportRepository(this._db) : _transactions = DriftTransactionRepository(_db);

  final AppDatabase _db;

  /// I movimenti passano dal repository dei movimenti: label, outbox e regole come sempre.
  final DriftTransactionRepository _transactions;

  @override
  Stream<List<ImportRecord>> watchAll() {
    final query = _db.select(_db.imports)
      ..whereNotDeleted()
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt), (t) => OrderingTerm.desc(t.id)]);
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  @override
  Future<({Set<String> active, Set<String> deleted})> transactionIds() async {
    final query = _db.selectOnly(_db.transactions)..addColumns([_db.transactions.id, _db.transactions.deletedAt]);
    final active = <String>{}, deleted = <String>{};
    for (final row in await query.get()) {
      final id = row.read(_db.transactions.id)!;
      (row.read(_db.transactions.deletedAt) == null ? active : deleted).add(id);
    }
    return (active: active, deleted: deleted);
  }

  @override
  Future<Map<String, Transaction>> transactionsByIds(Set<String> ids) async {
    if (ids.isEmpty) return const {};
    return {
      for (final tx in await _transactions.getAll())
        if (ids.contains(tx.id)) tx.id: tx,
    };
  }

  @override
  Future<ImportRecord> execute({
    required String id,
    required String fileName,
    required int rowCount,
    required ImportOperations operations,
    void Function(int done, int total)? onProgress,
    int chunkSize = 250,
  }) {
    return _db.transaction(() async {
      await _db.upsertSynced(
        _db.imports,
        id,
        ImportsCompanion(
          fileName: Value(fileName),
          rowCount: Value(rowCount),
          insertedCount: Value(operations.inserts.length),
          updatedCount: Value(operations.updates.length),
        ),
      );
      for (final wallet in operations.newWallets) {
        await _db.upsertSynced(_db.wallets, wallet.id, walletToCompanion(wallet));
      }
      for (final category in operations.newCategories) {
        await _db.upsertSynced(_db.categories, category.id, categoryToCompanion(category));
      }
      for (final label in operations.newLabels) {
        await _db.upsertSynced(_db.labels, label.id, labelToCompanion(label));
      }

      final all = [...operations.inserts, ...operations.updates];
      onProgress?.call(0, all.length);
      for (var start = 0; start < all.length; start += chunkSize) {
        final end = start + chunkSize < all.length ? start + chunkSize : all.length;
        for (final tx in all.sublist(start, end)) {
          await _transactions.save(tx);
        }
        onProgress?.call(end, all.length);
        // Lascia respirare l'interfaccia tra un blocco e l'altro (la barra di avanzamento si aggiorna).
        await Future<void>.delayed(Duration.zero);
      }
      return _fromRow(await (_db.select(_db.imports)..where((t) => t.id.equals(id))).getSingle());
    });
  }

  @override
  Future<int> undo(String id) {
    return _db.transaction(() async {
      final record =
          await (_db.select(_db.imports)
                ..whereNotDeleted()
                ..where((t) => t.id.equals(id)))
              .getSingleOrNull();
      if (record == null || record.undoneAt != null) return 0;
      final created =
          await (_db.select(_db.transactions)
                ..whereNotDeleted()
                ..where((t) => t.importBatchId.equals(id)))
              .get();
      for (final row in created) {
        await _db.softDelete(_db.transactions, row.id);
      }
      await _db.upsertSynced(_db.imports, id, ImportsCompanion(undoneAt: Value(_db.nowMs())));
      return created.length;
    });
  }

  ImportRecord _fromRow(ImportRow row) => ImportRecord(
    id: row.id,
    fileName: row.fileName,
    rowCount: row.rowCount,
    insertedCount: row.insertedCount,
    updatedCount: row.updatedCount,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
    undoneAt: row.undoneAt == null ? null : DateTime.fromMillisecondsSinceEpoch(row.undoneAt!, isUtc: true),
  );
}
