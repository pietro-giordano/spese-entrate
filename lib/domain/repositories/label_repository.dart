import '../models/label.dart';

/// Esiste già una label non cancellata con lo stesso nome.
class DuplicateLabelNameException implements Exception {
  const DuplicateLabelNameException(this.name);

  final String name;

  @override
  String toString() => 'Esiste già una label "$name"';
}

abstract interface class LabelRepository {
  /// Label non cancellate, in ordine alfabetico.
  Stream<List<Label>> watchAll();

  /// Crea o aggiorna per ID. Lancia [DuplicateLabelNameException] se un'altra label
  /// non cancellata ha lo stesso nome (senza distinguere maiuscole e spazi ai lati).
  Future<void> save(Label label);

  /// Cancellazione logica.
  Future<void> delete(String id);
}
