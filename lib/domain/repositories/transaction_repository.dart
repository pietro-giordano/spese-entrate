import '../../core/dates.dart';
import '../models/transaction.dart';

abstract interface class TransactionRepository {
  /// Tutti i movimenti non cancellati, dal più recente. Serve ai saldi.
  Stream<List<Transaction>> watchAll();

  /// Movimenti non cancellati con data in [range], dal più recente.
  Stream<List<Transaction>> watchInRange(DateRange range);

  Future<Transaction?> getById(String id);

  /// Crea o aggiorna per ID, comprese le label del movimento.
  Future<void> save(Transaction transaction);

  /// Cancellazione logica. Label e allegati restano, per poter annullare.
  Future<void> delete(String id);
}
