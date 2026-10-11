import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'attachment_picker.g.dart';

/// Massimo di allegati per movimento.
const maxAttachments = 5;

/// Un file scelto dall'utente e non ancora salvato nella cartella dell'app.
class PickedAttachment {
  const PickedAttachment({required this.name, required this.mimeType, required this.openRead, this.previewPath});

  /// Nome originale, estensione compresa (serve a ricavare l'estensione del file salvato).
  final String name;
  final String mimeType;

  /// Legge il contenuto. Un flusso di byte funziona anche quando il file non ha un percorso
  /// (su Android file_picker può restituire un indirizzo `content://`).
  final Stream<List<int>> Function() openRead;

  /// Percorso locale per l'anteprima, se disponibile.
  final String? previewPath;

  bool get isImage => mimeType.startsWith('image/');
}

/// Tipo MIME ricavato dall'estensione del nome.
String mimeTypeForName(String name) {
  return switch (p.extension(name).toLowerCase()) {
    '.jpg' || '.jpeg' => 'image/jpeg',
    '.png' => 'image/png',
    '.heic' => 'image/heic',
    '.pdf' => 'application/pdf',
    _ => 'application/octet-stream',
  };
}

/// Scelta di foto e file tramite i plugin di sistema. Nei test si sostituisce con un finto.
class AttachmentPicker {
  const AttachmentPicker();

  static const _imageQuality = 75;
  static const _maxSide = 2048.0;

  /// Scatta una foto. Null se l'utente annulla.
  Future<PickedAttachment?> takePhoto() => _pickImage(ImageSource.camera);

  /// Sceglie una foto dalla galleria. Null se l'utente annulla.
  Future<PickedAttachment?> pickFromGallery() => _pickImage(ImageSource.gallery);

  /// Sceglie un PDF o un'immagine dai file. Null se l'utente annulla.
  Future<PickedAttachment?> pickFile() async {
    final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png']);
    if (file == null) return null;
    return PickedAttachment(
      name: file.name,
      mimeType: mimeTypeForName(file.name),
      openRead: file.readAsByteStream,
      previewPath: file.path,
    );
  }

  Future<PickedAttachment?> _pickImage(ImageSource source) async {
    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: _imageQuality,
      maxWidth: _maxSide,
      maxHeight: _maxSide,
    );
    if (image == null) return null;
    return PickedAttachment(
      name: image.name,
      mimeType: image.mimeType ?? mimeTypeForName(image.name),
      openRead: image.openRead,
      previewPath: image.path,
    );
  }
}

@Riverpod(keepAlive: true)
AttachmentPicker attachmentPicker(Ref ref) => const AttachmentPicker();
