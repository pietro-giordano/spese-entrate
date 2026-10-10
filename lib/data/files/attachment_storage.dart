import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/ids.dart';
import '../../domain/models/attachment.dart';
import 'attachment_picker.dart';

part 'attachment_storage.g.dart';

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
  }

  /// File sul disco di un allegato salvato.
  Future<File> fileFor(Attachment attachment) => _absolute(attachment.localPath);

  /// Elimina i file (usato per annullare un salvataggio fallito). Ignora quelli già assenti.
  Future<void> delete(Iterable<Attachment> attachments) async {
    for (final attachment in attachments) {
      final file = await fileFor(attachment);
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
