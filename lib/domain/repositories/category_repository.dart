import '../models/category.dart';
import '../models/enums.dart';

/// Esiste già una categoria (non cancellata, anche archiviata) dello stesso tipo con questo nome.
/// Lo stesso nome è ammesso se il tipo è diverso (es. "Regali" di spesa e "Regali" di entrata).
class DuplicateCategoryNameException implements Exception {
  const DuplicateCategoryNameException(this.name, this.kind);

  final String name;
  final CategoryKind kind;

  @override
  String toString() => 'Esiste già una categoria ${kind == CategoryKind.expense ? 'di spesa' : 'di entrata'} «$name»';
}

abstract interface class CategoryRepository {
  /// Categorie non cancellate (anche archiviate), ordinate per tipo e `sortOrder`.
  Stream<List<Category>> watchAll();

  /// Crea o aggiorna per ID. Lancia [DuplicateCategoryNameException] se un'altra categoria dello
  /// stesso tipo ha già questo nome (senza distinzione di maiuscole e spazi ai lati).
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
