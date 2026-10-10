import '../../core/dates.dart';
import '../models/attachment.dart';
import '../models/transaction.dart';

abstract interface class TransactionRepository {
  /// Tutti i movimenti non cancellati, dal più recente. Serve ai saldi.
  Stream<List<Transaction>> watchAll();

  /// Movimenti non cancellati con data in [range], dal più recente.
  Stream<List<Transaction>> watchInRange(DateRange range);

  Future<Transaction?> getById(String id);

  /// Crea o aggiorna per ID, comprese le label del movimento.
  /// [attachments] sono allegati da aggiungere (i file sono già nella cartella dell'app):
  /// vengono scritti nella stessa transazione del movimento.
  Future<void> save(Transaction transaction, {List<Attachment> attachments = const []});

  /// Allegati non cancellati del movimento, dal primo aggiunto.
  Future<List<Attachment>> getAttachments(String transactionId);

  /// Cancellazione logica. Label e allegati restano, per poter annullare.
  Future<void> delete(String id);
}
