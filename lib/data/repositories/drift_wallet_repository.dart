import 'package:drift/drift.dart';

import '../../domain/models/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../db/app_database.dart';
import 'mappers.dart';

class DriftWalletRepository implements WalletRepository {
  DriftWalletRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Wallet>> watchAll() {
    final query = _db.select(_db.wallets)
      ..whereNotDeleted()
      ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]);
    return query.watch().map((rows) => rows.map(walletFromRow).toList());
  }

  @override
  Future<Wallet?> getById(String id) async {
    final query = _db.select(_db.wallets)
      ..whereNotDeleted()
      ..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : walletFromRow(row);
  }

  @override
  Future<void> save(Wallet wallet) => _db.upsertSynced(_db.wallets, wallet.id, walletToCompanion(wallet));

  @override
  Future<void> delete(String id) => _db.softDelete(_db.wallets, id);
}
