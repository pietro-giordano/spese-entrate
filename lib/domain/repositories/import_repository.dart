import '../models/import_record.dart';
import '../models/transaction.dart';
import '../services/import_operations.dart';

/// Import da CSV: esecuzione, storico e annullamento.
abstract interface class ImportRepository {
  /// Storico degli import, dal più recente.
  Stream<List<ImportRecord>> watchAll();

  /// Id dei movimenti attivi e di quelli cancellati (servono al piano: aggiornare o rifiutare).
  Future<({Set<String> active, Set<String> deleted})> transactionIds();

  /// Movimenti attivi con questi id (quelli che l'import aggiornerà).
  Future<Map<String, Transaction>> transactionsByIds(Set<String> ids);

  /// Scrive [operations] in un'unica transazione: o tutto o niente. I movimenti si salvano a
  /// blocchi di [chunkSize]; dopo ogni blocco [onProgress] riceve quanti sono fatti sul totale.
  /// Restituisce il record dell'import nello storico.
  Future<ImportRecord> execute({
    required String id,
    required String fileName,
    required int rowCount,
    required ImportOperations operations,
    void Function(int done, int total)? onProgress,
    int chunkSize = 250,
  });

  /// Annulla l'import [id]: cancella logicamente i movimenti che ha creato e segna `undone_at`.
  /// I movimenti che ha solo aggiornato restano come sono. Restituisce quanti ne ha cancellati.
  Future<int> undo(String id);
}
