import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/clock.dart';
import '../../../core/ids.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/label.dart';

part 'category_label_actions.g.dart';

/// Operazioni della gestione di categorie e label.
class CategoryLabelActions {
  CategoryLabelActions(this._ref);

  final Ref _ref;

  /// Nuova categoria in fondo all'elenco del suo tipo.
  Future<Category> createCategory({required String name, required int color, required CategoryKind kind}) async {
    final repository = _ref.read(categoryRepositoryProvider);
    final existing = (await repository.watchAll().first).where((c) => c.kind == kind);
    final category = Category(
      id: newId(),
      name: name.trim(),
      kind: kind,
      color: color,
      sortOrder: existing.fold(-1, (max, c) => c.sortOrder > max ? c.sortOrder : max) + 1,
    );
    await repository.save(category);
    return category;
  }

  Future<void> updateCategory(Category category) =>
      _ref.read(categoryRepositoryProvider).save(category.copyWith(name: category.name.trim()));

  /// Archiviata: non compare più nelle scelte, ma i movimenti che la usano restano.
  Future<void> archiveCategory(Category category) =>
      _ref.read(categoryRepositoryProvider).save(category.copyWith(archivedAt: _ref.read(clockProvider)().toUtc()));

  Future<void> restoreCategory(Category category) =>
      _ref.read(categoryRepositoryProvider).save(category.copyWith(archivedAt: null));

  /// Nuovo ordine delle categorie di un tipo (quello dell'inserimento rapido).
  Future<void> reorderCategories(List<Category> ordered) =>
      _ref.read(categoryRepositoryProvider).reorder([for (final c in ordered) c.id]);

  Future<void> mergeCategory(Category from, Category into) =>
      _ref.read(categoryRepositoryProvider).merge(fromId: from.id, intoId: into.id);

  /// Lancia DuplicateLabelNameException se il nome è già usato.
  Future<Label> createLabel({required String name, required int color}) async {
    final label = Label(id: newId(), name: name.trim(), color: color);
    await _ref.read(labelRepositoryProvider).save(label);
    return label;
  }

  Future<void> updateLabel(Label label) => _ref.read(labelRepositoryProvider).save(label);

  Future<void> deleteLabel(Label label) => _ref.read(labelRepositoryProvider).delete(label.id);

  Future<void> mergeLabel(Label from, Label into) =>
      _ref.read(labelRepositoryProvider).merge(fromId: from.id, intoId: into.id);
}

@Riverpod(keepAlive: true)
CategoryLabelActions categoryLabelActions(Ref ref) => CategoryLabelActions(ref);
