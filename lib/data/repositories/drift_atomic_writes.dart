import '../../domain/repositories/atomic_writes.dart';
import '../db/app_database.dart';

/// Transazione SQLite. Drift instrada nella transazione tutte le query fatte sullo stesso
/// database dentro [run]; le transazioni dei repository diventano savepoint annidati.
class DriftAtomicWrites implements AtomicWrites {
  DriftAtomicWrites(this._db);

  final AppDatabase _db;

  @override
  Future<T> run<T>(Future<T> Function() action) => _db.transaction(action);
}
