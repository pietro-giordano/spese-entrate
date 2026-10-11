import 'package:freezed_annotation/freezed_annotation.dart';

part 'import_record.freezed.dart';

/// Un import da CSV nello storico: file, conteggi e, se annullato, quando.
@freezed
abstract class ImportRecord with _$ImportRecord {
  const factory ImportRecord({
    required String id,
    required String fileName,

    /// Righe di dati lette dal file (valide e con errori).
    required int rowCount,
    required int insertedCount,
    required int updatedCount,
    required DateTime createdAt,
    DateTime? undoneAt,
  }) = _ImportRecord;

  const ImportRecord._();

  /// Righe saltate perché avevano errori.
  int get skippedCount => rowCount - insertedCount - updatedCount;

  bool get isUndone => undoneAt != null;
}
