import 'package:drift/drift.dart';

import '../../domain/models/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../db/app_database.dart';
import 'mappers.dart';

class DriftCategoryRepository implements CategoryRepository {
  DriftCategoryRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Category>> watchAll() {
    final query = _db.select(_db.categories)
      ..whereNotDeleted()
      ..orderBy([(t) => OrderingTerm(expression: t.kind), (t) => OrderingTerm(expression: t.sortOrder)]);
    return query.watch().map((rows) => rows.map(categoryFromRow).toList());
  }

  @override
  Future<void> save(Category category) {
    return _db.transaction(() async {
      // Confronto in Dart: lower() di SQLite non gestisce le lettere accentate.
      final name = category.name.trim().toLowerCase();
      final sameKind =
          await (_db.select(_db.categories)
                ..whereNotDeleted()
                ..where((t) => t.kind.equalsValue(category.kind) & t.id.equals(category.id).not()))
              .get();
      if (sameKind.any((other) => other.name.trim().toLowerCase() == name)) {
        throw DuplicateCategoryNameException(category.name.trim(), category.kind);
      }
      await _db.upsertSynced(_db.categories, category.id, categoryToCompanion(category));
    });
  }

  @override
  Future<void> delete(String id) => _db.softDelete(_db.categories, id);

  @override
  Future<void> reorder(List<String> orderedIds) {
    return _db.transaction(() async {
      final rows = {for (final row in await (_db.select(_db.categories)..whereNotDeleted()).get()) row.id: row};
      for (final (index, id) in orderedIds.indexed) {
        // Si scrive (e si accoda nell'outbox) solo ciò che cambia davvero.
        if (rows[id] != null && rows[id]!.sortOrder != index) {
          await _db.upsertSynced(_db.categories, id, CategoriesCompanion(sortOrder: Value(index)));
        }
      }
    });
  }

  @override
  Future<void> merge({required String fromId, required String intoId}) {
    if (fromId == intoId) throw ArgumentError('Una categoria non si unisce a se stessa');
    return _db.transaction(() async {
      for (final id in [fromId, intoId]) {
        final row = await (_db.select(_db.categories)..where((t) => t.id.equals(id))).getSingleOrNull();
        if (row == null || row.deletedAt != null) throw StateError('La categoria $id non esiste o è stata cancellata');
      }
      final transactions =
          await (_db.select(_db.transactions)
                ..whereNotDeleted()
                ..where((t) => t.categoryId.equals(fromId)))
              .get();
      for (final tx in transactions) {
        await _db.upsertSynced(_db.transactions, tx.id, TransactionsCompanion(categoryId: Value(intoId)));
      }
      final rules =
          await (_db.select(_db.recurrenceRules)
                ..whereNotDeleted()
                ..where((t) => t.categoryId.equals(fromId)))
              .get();
      for (final rule in rules) {
        await _db.upsertSynced(_db.recurrenceRules, rule.id, RecurrenceRulesCompanion(categoryId: Value(intoId)));
      }
      await _db.softDelete(_db.categories, fromId);
    });
  }
}
