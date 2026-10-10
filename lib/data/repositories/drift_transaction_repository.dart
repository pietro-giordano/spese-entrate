import 'package:drift/drift.dart';

import '../../core/dates.dart';
import '../../core/ids.dart';
import '../../domain/models/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../db/app_database.dart';
import 'mappers.dart';

class DriftTransactionRepository implements TransactionRepository {
  DriftTransactionRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Transaction>> watchAll() => _query().watch().map(_toTransactions);

  @override
  Stream<List<Transaction>> watchInRange(DateRange range) {
    // Le date 'YYYY-MM-DD' si ordinano correttamente anche come testo.
    return _query((t) => t.date.isBetweenValues(range.start.toString(), range.end.toString()))
        .watch()
        .map(_toTransactions);
  }

  @override
  Future<Transaction?> getById(String id) async {
    final rows = await _query((t) => t.id.equals(id)).get();
    final transactions = _toTransactions(rows);
    return transactions.isEmpty ? null : transactions.first;
  }

  @override
  Future<void> save(Transaction transaction) {
    return _db.transaction(() async {
      await _db.upsertSynced(_db.transactions, transaction.id, transactionToCompanion(transaction));
      await _syncLabels(transaction.id, transaction.labelIds.toSet());
    });
  }

  @override
  Future<void> delete(String id) => _db.softDelete(_db.transactions, id);

  /// Movimenti non cancellati con le loro label attive, dal più recente.
  /// Il join fa sì che `watch()` emetta anche quando cambiano solo le label.
  JoinedSelectStatement<HasResultSet, dynamic> _query([Expression<bool> Function($TransactionsTable t)? filter]) {
    final t = _db.transactions;
    final links = _db.transactionLabels;
    return _db.select(t).join([leftOuterJoin(links, links.transactionId.equalsExp(t.id) & links.deletedAt.isNull())])
      ..where(t.deletedAt.isNull() & (filter?.call(t) ?? const Constant(true)))
      ..orderBy([OrderingTerm.desc(t.date), OrderingTerm.desc(t.createdAt), OrderingTerm.asc(t.id)]);
  }

  /// Il join produce una riga per ogni label: le raggruppa per movimento, mantenendo l'ordine.
  List<Transaction> _toTransactions(List<TypedResult> rows) {
    final grouped = <String, (TransactionRow, List<String>)>{};
    for (final row in rows) {
      final tx = row.readTable(_db.transactions);
      final link = row.readTableOrNull(_db.transactionLabels);
      final entry = grouped.putIfAbsent(tx.id, () => (tx, <String>[]));
      if (link != null) entry.$2.add(link.labelId);
    }
    return [for (final (row, labelIds) in grouped.values) transactionFromRow(row, labelIds: labelIds)];
  }

  /// Allinea `transaction_labels` alle label volute: crea i collegamenti nuovi,
  /// ripristina quelli cancellati (il vincolo unico vieta di ricrearli) e cancella quelli tolti.
  Future<void> _syncLabels(String transactionId, Set<String> labelIds) async {
    final existing = await (_db.select(
      _db.transactionLabels,
    )..where((l) => l.transactionId.equals(transactionId))).get();
    final byLabel = {for (final link in existing) link.labelId: link};

    for (final labelId in labelIds) {
      final link = byLabel[labelId];
      if (link != null && link.deletedAt == null) continue;
      await _db.upsertSynced(
        _db.transactionLabels,
        link?.id ?? newId(nowMs: _db.nowMs()),
        TransactionLabelsCompanion(transactionId: Value(transactionId), labelId: Value(labelId)),
      );
    }

    for (final link in existing) {
      if (link.deletedAt == null && !labelIds.contains(link.labelId)) {
        await _db.softDelete(_db.transactionLabels, link.id);
      }
    }
  }
}
