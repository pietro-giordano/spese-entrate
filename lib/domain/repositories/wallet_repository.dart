import '../models/wallet.dart';

abstract interface class WalletRepository {
  /// Portafogli non cancellati (anche archiviati), ordinati per `sortOrder`.
  Stream<List<Wallet>> watchAll();

  Future<Wallet?> getById(String id);

  /// Crea o aggiorna per ID. Un record cancellato con lo stesso ID viene ripristinato.
  Future<void> save(Wallet wallet);

  /// Cancellazione logica.
  Future<void> delete(String id);
}
