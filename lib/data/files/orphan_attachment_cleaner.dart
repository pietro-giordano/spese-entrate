import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/clock.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../repositories/repository_providers.dart';
import 'attachment_storage.dart';

part 'orphan_attachment_cleaner.g.dart';

/// Pulizia dei file orfani: file nella cartella degli allegati senza **nessun** record in
/// `attachments`, nemmeno cancellato logicamente (es. app chiusa a metà di un salvataggio).
///
/// Non si attiva da sola: per ora l'app non la chiama mai. I file di allegati cancellati
/// logicamente non sono orfani e restano, perché servono all'annullamento e alla futura
/// sincronizzazione. [minAge] protegge i file appena copiati da un salvataggio in corso
/// (la copia avviene prima della scrittura nel database).
class OrphanAttachmentCleaner {
  OrphanAttachmentCleaner({required this.storage, required this.transactions, required this.now});

  final AttachmentStorage storage;
  final TransactionRepository transactions;
  final DateTime Function() now;

  static const defaultMinAge = Duration(days: 1);

  /// Percorsi relativi dei file orfani più vecchi di [minAge].
  Future<List<String>> findOrphans({Duration minAge = defaultMinAge}) async {
    final onRecord = await transactions.attachmentPathsOnRecord();
    final threshold = now().subtract(minAge);
    return [
      for (final file in await storage.listFiles())
        if (!onRecord.contains(file.localPath) && file.modified.isBefore(threshold)) file.localPath,
    ];
  }

  /// Elimina i file orfani più vecchi di [minAge] e restituisce quelli eliminati.
  Future<List<String>> deleteOrphans({Duration minAge = defaultMinAge}) async {
    final orphans = await findOrphans(minAge: minAge);
    await storage.deletePaths(orphans);
    return orphans;
  }
}

@Riverpod(keepAlive: true)
OrphanAttachmentCleaner orphanAttachmentCleaner(Ref ref) => OrphanAttachmentCleaner(
  storage: ref.watch(attachmentStorageProvider),
  transactions: ref.watch(transactionRepositoryProvider),
  now: ref.watch(clockProvider),
);
