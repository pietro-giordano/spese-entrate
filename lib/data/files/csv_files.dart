import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'file_sharer.dart';

part 'csv_files.g.dart';

/// Un file CSV scelto dall'utente, già letto come testo.
typedef PickedCsv = ({String name, String content});

/// File dell'import CSV: scelta del file (solo `.csv`) e condivisione del modello.
/// Nei test si sostituisce con un finto.
class CsvFiles {
  CsvFiles({required this._sharer, required this._directory});

  final FileSharer _sharer;
  final Future<Directory> Function() _directory;

  /// Nome del modello condiviso.
  static const templateName = 'modello_import_movimenti.csv';

  /// Sceglie un `.csv` e lo legge come UTF-8 (caratteri non validi sostituiti, mai un crash).
  /// Null se l'utente annulla.
  Future<PickedCsv?> pickCsv() async {
    final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['csv']);
    if (file == null) return null;
    final bytes = <int>[];
    await for (final chunk in file.readAsByteStream()) {
      bytes.addAll(chunk);
    }
    return (name: file.name, content: utf8.decode(bytes, allowMalformed: true));
  }

  /// Scrive [csv] in una cartella temporanea e apre la condivisione del telefono.
  Future<void> shareTemplate(String csv) async {
    final file = File(p.join((await _directory()).path, templateName));
    await file.writeAsString(csv, flush: true);
    await _sharer.shareFile(file.path, mimeType: 'text/csv', subject: 'Modello per importare i movimenti');
  }
}

@Riverpod(keepAlive: true)
CsvFiles csvFiles(Ref ref) => CsvFiles(sharer: ref.watch(fileSharerProvider), directory: getTemporaryDirectory);
