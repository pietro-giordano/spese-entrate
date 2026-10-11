import 'package:drift/drift.dart';

import '../../core/ids.dart';
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
      // Salvare una label eliminata la farebbe ricomparire (upsertSynced azzera deleted_at).
      final existing = await (_db.select(_db.labels)..where((t) => t.id.equals(label.id))).getSingleOrNull();
      if (existing?.deletedAt != null) throw DeletedLabelException(label.id);
      await _db.upsertSynced(_db.labels, label.id, labelToCompanion(label.copyWith(name: name)));
    });
  }

  @override
  Future<void> delete(String id) {
    return _db.transaction(() async {
      for (final link in await _activeLinks(id)) {
        await _db.softDelete(_db.transactionLabels, link.id);
      }
      await _db.softDelete(_db.labels, id);
    });
  }

  @override
  Future<void> merge({required String fromId, required String intoId}) {
    if (fromId == intoId) throw ArgumentError('Una label non si unisce a se stessa');
    return _db.transaction(() async {
      for (final id in [fromId, intoId]) {
        final row = await (_db.select(_db.labels)..where((t) => t.id.equals(id))).getSingleOrNull();
        if (row == null || row.deletedAt != null) throw DeletedLabelException(id);
      }
      final intoLinks = {
        for (final link in await (_db.select(_db.transactionLabels)..where((l) => l.labelId.equals(intoId))).get())
          link.transactionId: link,
      };
      for (final link in await _activeLinks(fromId)) {
        await _db.softDelete(_db.transactionLabels, link.id);
        final existing = intoLinks[link.transactionId];
        if (existing != null && existing.deletedAt == null) continue; // aveva già la label di destinazione
        // Un collegamento cancellato si ripristina: il vincolo unico vieta di ricrearlo.
        await _db.upsertSynced(
          _db.transactionLabels,
          existing?.id ?? newId(nowMs: _db.nowMs()),
          TransactionLabelsCompanion(transactionId: Value(link.transactionId), labelId: Value(intoId)),
        );
      }

      for (final rule in await (_db.select(_db.recurrenceRules)..whereNotDeleted()).get()) {
        if (!rule.labelIds.contains(fromId)) continue;
        final labelIds = {for (final id in rule.labelIds) id == fromId ? intoId : id}.toList();
        await _db.upsertSynced(_db.recurrenceRules, rule.id, RecurrenceRulesCompanion(labelIds: Value(labelIds)));
      }

      await _db.softDelete(_db.labels, fromId);
    });
  }

  Future<List<TransactionLabelRow>> _activeLinks(String labelId) {
    return (_db.select(_db.transactionLabels)
          ..whereNotDeleted()
          ..where((l) => l.labelId.equals(labelId)))
        .get();
  }
}
