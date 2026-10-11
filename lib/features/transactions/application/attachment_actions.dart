import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/files/attachment_storage.dart';
import '../../../data/files/external_file_opener.dart';
import '../../../data/files/file_sharer.dart';
import '../../../domain/models/attachment.dart';

part 'attachment_actions.g.dart';

/// Perché un allegato non si può aprire o condividere.
enum AttachmentProblem {
  missing('Il file di questo allegato non si trova più sul telefono.'),
  corrupted('Il file di questo allegato è danneggiato e non si può aprire.'),
  noApp('Nessuna app installata può aprire questo file. Prova con "Condividi".'),
  failed('Non è stato possibile aprire il file. Riprova.');

  const AttachmentProblem(this.message);

  /// Messaggio per l'utente.
  final String message;
}

/// Apertura e condivisione degli allegati salvati. Prima di tutto si controlla il file:
/// un file mancante o danneggiato dà un messaggio, mai un crash.
class AttachmentActions {
  AttachmentActions({required this.storage, required this.opener, required this.sharer});

  final AttachmentStorage storage;
  final ExternalFileOpener opener;
  final FileSharer sharer;

  /// Il file pronto da mostrare, oppure il problema che lo impedisce.
  Future<(File?, AttachmentProblem?)> resolve(Attachment attachment) async {
    return switch (await storage.check(attachment)) {
      AttachmentFileStatus.ok => (await storage.fileFor(attachment), null),
      AttachmentFileStatus.missing => (null, AttachmentProblem.missing),
      AttachmentFileStatus.corrupted => (null, AttachmentProblem.corrupted),
    };
  }

  /// Apre l'allegato con un'app esterna (i PDF). Null se è andata bene.
  Future<AttachmentProblem?> openExternally(Attachment attachment) async {
    final (file, problem) = await resolve(attachment);
    if (file == null) return problem;
    return switch (await opener.open(file.path, mimeType: attachment.mimeType)) {
      ExternalOpenResult.opened => null,
      ExternalOpenResult.noApp => AttachmentProblem.noApp,
      ExternalOpenResult.failed => AttachmentProblem.failed,
    };
  }

  /// Menu di condivisione del telefono per l'allegato. Null se è andata bene.
  Future<AttachmentProblem?> share(Attachment attachment) async {
    final (file, problem) = await resolve(attachment);
    if (file == null) return problem;
    try {
      await sharer.shareFile(file.path, mimeType: attachment.mimeType);
      return null;
    } on Exception {
      return AttachmentProblem.failed;
    }
  }
}

@riverpod
AttachmentActions attachmentActions(Ref ref) => AttachmentActions(
  storage: ref.watch(attachmentStorageProvider),
  opener: ref.watch(externalFileOpenerProvider),
  sharer: ref.watch(fileSharerProvider),
);
