import '../models/category.dart';

abstract interface class CategoryRepository {
  /// Categorie non cancellate (anche archiviate), ordinate per tipo e `sortOrder`.
  Stream<List<Category>> watchAll();

  /// Crea o aggiorna per ID.
  Future<void> save(Category category);

  /// Cancellazione logica.
  Future<void> delete(String id);

  /// Nuovo ordine (quello dell'inserimento rapido): [orderedIds] dal primo all'ultimo.
  Future<void> reorder(List<String> orderedIds);

  /// Unisce [fromId] in [intoId]: movimenti e ricorrenze passano a [intoId],
  /// poi [fromId] viene cancellata (logicamente). Tutto in una transazione: se un passo fallisce
  /// non cambia nulla, outbox compreso. Lancia [StateError] se una delle due categorie non esiste
  /// o è cancellata.
  Future<void> merge({required String fromId, required String intoId});
}
