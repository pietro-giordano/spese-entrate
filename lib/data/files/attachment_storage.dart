import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/ids.dart';
import '../../domain/models/attachment.dart';
import 'attachment_picker.dart';

part 'attachment_storage.g.dart';

/// Stato del file di un allegato salvato.
enum AttachmentFileStatus {
  ok,

  /// Il file non c'è più (es. cancellato dal sistema o ripristino senza file).
  missing,

  /// Il file c'è ma dimensione o SHA-256 non corrispondono a quelli salvati.
  corrupted,
}

/// Un file nella cartella degli allegati, con percorso relativo e ultima modifica.
typedef StoredAttachmentFile = ({String localPath, DateTime modified});

/// Copia gli allegati in `<documenti app>/attachments/<transaction_id>/<uuid>.<ext>`.
///
/// Il percorso salvato nel database è relativo alla cartella documenti e usa sempre `/`,
/// così resta valido se cambia la cartella (es. ripristino su un altro dispositivo).
class AttachmentStorage {
  /// Il parametro si chiama `documentsDirectory`: Dart toglie il `_` dal nome pubblico.
  AttachmentStorage({required this._documentsDirectory});

  static const folder = 'attachments';

  final Future<Directory> Function() _documentsDirectory;

  /// Copia [file] tra gli allegati di [transactionId] e ne calcola dimensione e SHA-256.
  Future<Attachment> store(String transactionId, PickedAttachment file) async {
    final id = newId();
    final relativePath = p.posix.join(folder, transactionId, '$id${p.extension(file.name).toLowerCase()}');
    final target = await _absolute(relativePath);
    await target.parent.create(recursive: true);

    try {
      final sink = target.openWrite();
      try {
        await sink.addStream(file.openRead());
      } finally {
        await sink.close();
      }
      return Attachment(
        id: id,
        transactionId: transactionId,
        localPath: relativePath,
        mimeType: file.mimeType,
        sizeBytes: await target.length(),
        sha256: (await sha256.bind(target.openRead()).first).toString(),
      );
    } catch (_) {
      // Copia a metà (es. lettura interrotta): non deve restare un file orfano.
      if (await target.exists()) await target.delete();
      rethrow;
    }
  }

  /// Controlla che il file dell'allegato esista e sia quello salvato (dimensione e SHA-256).
  Future<AttachmentFileStatus> check(Attachment attachment) async {
    final file = await fileFor(attachment);
    if (!await file.exists()) return AttachmentFileStatus.missing;
    try {
      if (await file.length() != attachment.sizeBytes) return AttachmentFileStatus.corrupted;
      final digest = await sha256.bind(file.openRead()).first;
      return digest.toString() == attachment.sha256 ? AttachmentFileStatus.ok : AttachmentFileStatus.corrupted;
    } on FileSystemException {
      return AttachmentFileStatus.corrupted;
    }
  }

  /// Tutti i file presenti nella cartella degli allegati (per la pulizia degli orfani).
  Future<List<StoredAttachmentFile>> listFiles() async {
    final documents = await _documentsDirectory();
    final root = Directory(p.join(documents.path, folder));
    if (!await root.exists()) return const [];
    return [
      await for (final entity in root.list(recursive: true))
        if (entity is File)
          (
            localPath: p.posix.joinAll(p.split(p.relative(entity.path, from: documents.path))),
            modified: await entity.lastModified(),
          ),
    ];
  }

  /// File sul disco di un allegato salvato.
  Future<File> fileFor(Attachment attachment) => _absolute(attachment.localPath);

  /// Elimina i file. Si usa solo per file mai referenziati da un record salvato (salvataggio
  /// fallito) o per gli orfani: i file di allegati cancellati logicamente restano.
  /// Ignora quelli già assenti.
  Future<void> delete(Iterable<Attachment> attachments) =>
      deletePaths([for (final attachment in attachments) attachment.localPath]);

  /// Come [delete], con i percorsi relativi.
  Future<void> deletePaths(Iterable<String> localPaths) async {
    for (final localPath in localPaths) {
      final file = await _absolute(localPath);
      if (await file.exists()) await file.delete();
    }
  }

  Future<File> _absolute(String relativePath) async {
    final documents = await _documentsDirectory();
    return File(p.joinAll([documents.path, ...p.posix.split(relativePath)]));
  }
}

@Riverpod(keepAlive: true)
AttachmentStorage attachmentStorage(Ref ref) => AttachmentStorage(documentsDirectory: getApplicationDocumentsDirectory);
