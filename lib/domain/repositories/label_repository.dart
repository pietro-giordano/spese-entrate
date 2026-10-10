import '../models/label.dart';

/// Esiste già una label non cancellata con lo stesso nome.
class DuplicateLabelNameException implements Exception {
  const DuplicateLabelNameException(this.name);

  final String name;

  @override
  String toString() => 'Esiste già una label "$name"';
}

/// La label è stata eliminata: non si può più salvare né usare come destinazione.
/// Un'eliminazione è definitiva (resta come `deleted_at`, la "lapide" per la sincronizzazione).
class DeletedLabelException implements Exception {
  const DeletedLabelException(this.id);

  final String id;

  @override
  String toString() => 'La label $id è stata eliminata';
}

abstract interface class LabelRepository {
  /// Label non cancellate, in ordine alfabetico.
  Stream<List<Label>> watchAll();

  /// Crea o aggiorna per ID. Lancia [DuplicateLabelNameException] se un'altra label
  /// non cancellata ha lo stesso nome (senza distinguere maiuscole e spazi ai lati),
  /// e [DeletedLabelException] se la label con quell'ID è stata eliminata (non si resuscita).
  Future<void> save(Label label);

  /// Cancellazione logica della label e dei suoi collegamenti ai movimenti.
  Future<void> delete(String id);

  /// Unisce [fromId] in [intoId]: i movimenti con [fromId] ottengono [intoId] (senza doppioni),
  /// le ricorrenze pure, poi [fromId] viene cancellata. Tutto in una transazione:
  /// se un passo fallisce non cambia nulla, outbox compreso.
  /// Lancia [DeletedLabelException] se una delle due label non esiste o è eliminata.
  Future<void> merge({required String fromId, required String intoId});
}
