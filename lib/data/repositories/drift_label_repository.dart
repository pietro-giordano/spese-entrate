import 'package:drift/drift.dart';

import '../../domain/models/label.dart';
import '../../domain/repositories/label_repository.dart';
import '../db/app_database.dart';
import 'mappers.dart';

class DriftLabelRepository implements LabelRepository {
  DriftLabelRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Label>> watchAll() {
    final query = _db.select(_db.labels)
      ..whereNotDeleted()
      ..orderBy([(t) => OrderingTerm(expression: t.name.collate(Collate.noCase))]);
    return query.watch().map((rows) => rows.map(labelFromRow).toList());
  }

  @override
  Future<void> save(Label label) {
    final name = label.name.trim();
    return _db.transaction(() async {
      // Confronto in Dart: lower() di SQLite non gestisce le lettere accentate.
      final others =
          await (_db.select(_db.labels)
                ..whereNotDeleted()
                ..where((t) => t.id.equals(label.id).not()))
              .get();
      if (others.any((other) => other.name.trim().toLowerCase() == name.toLowerCase())) {
        throw DuplicateLabelNameException(name);
      }
      await _db.upsertSynced(_db.labels, label.id, labelToCompanion(label.copyWith(name: name)));
    });
  }

  @override
  Future<void> delete(String id) => _db.softDelete(_db.labels, id);
}
