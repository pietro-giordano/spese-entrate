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
  Future<void> save(Category category) => _db.upsertSynced(_db.categories, category.id, categoryToCompanion(category));

  @override
  Future<void> delete(String id) => _db.softDelete(_db.categories, id);
}
