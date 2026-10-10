import '../../core/dates.dart';
import '../models/attachment.dart';
import '../models/transaction.dart';

abstract interface class TransactionRepository {
  /// Tutti i movimenti non cancellati, dal più recente. Serve ai saldi.
  Stream<List<Transaction>> watchAll();

  /// Come [watchAll], ma una lettura singola.
  Future<List<Transaction>> getAll();

  /// Movimenti non cancellati con data in [range], dal più recente.
  Stream<List<Transaction>> watchInRange(DateRange range);

  Future<Transaction?> getById(String id);

  /// Crea o aggiorna per ID, comprese le label del movimento, in un'unica transazione.
  /// [attachments] sono allegati da aggiungere (i file sono già nella cartella dell'app);
  /// [removedAttachmentIds] sono allegati da cancellare logicamente (i file restano).
  Future<void> save(
    Transaction transaction, {
    List<Attachment> attachments = const [],
    List<String> removedAttachmentIds = const [],
  });

  /// Allegati non cancellati del movimento, dal primo aggiunto.
  Future<List<Attachment>> getAttachments(String transactionId);

  /// Cancellazione logica. Label e allegati restano, per poter annullare.
  Future<void> delete(String id);

  /// Annulla una cancellazione logica (azzera `deleted_at`).
  Future<void> restore(String id);

  /// Quando il movimento è stato creato e modificato l'ultima volta; null se non esiste.
  Future<({DateTime createdAt, DateTime updatedAt})?> getTimestamps(String id);
}
