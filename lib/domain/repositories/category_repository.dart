import '../models/category.dart';

abstract interface class CategoryRepository {
  /// Categorie non cancellate (anche archiviate), ordinate per tipo e `sortOrder`.
  Stream<List<Category>> watchAll();

  /// Crea o aggiorna per ID.
  Future<void> save(Category category);

  /// Cancellazione logica.
  Future<void> delete(String id);
}
