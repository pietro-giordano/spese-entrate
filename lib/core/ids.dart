/// Generazione degli ID dei record.
///
/// - [newId]: UUID v7 casuale e ordinato nel tempo, per ogni nuovo record.
/// - [occurrenceId]: UUID v5 deterministico per le occorrenze delle ricorrenze,
///   così generarle due volte (o su due dispositivi) produce lo stesso ID.
/// - [importedRowId]: UUID v5 deterministico per le righe CSV senza id, così reimportare
///   lo stesso file non crea duplicati.
library;

import 'package:uuid/data.dart';
import 'package:uuid/rng.dart';
import 'package:uuid/uuid.dart';

import 'dates.dart';

/// Namespace UUID dell'app per le occorrenze delle ricorrenze.
///
/// NON va mai cambiato: cambierebbe tutti gli ID delle occorrenze già create
/// e il generatore creerebbe dei duplicati.
const recurrenceNamespace = 'ff555432-14b1-4533-8bc4-1ca0e9307887';

/// Namespace UUID dell'app per le righe importate da CSV senza id.
///
/// NON va mai cambiato: reimportare un file già importato creerebbe dei duplicati.
const importNamespace = '6b0f3c2e-8d1a-4f57-9c4e-2a7d5b1e9f30';

/// Generatore con numeri casuali crittografici (Random.secure).
const _uuid = Uuid(goptions: GlobalOptions(CryptoRNG()));

/// Nuovo ID UUID v7: i primi 48 bit sono il timestamp in millisecondi,
/// il resto è casuale. Gli ID creati dopo si ordinano dopo (tra millisecondi diversi).
///
/// [nowMs] (millisecondi UTC) serve solo ai test.
String newId({int? nowMs}) => _uuid.v7(config: nowMs == null ? null : V7Options(nowMs, null));

/// ID deterministico dell'occorrenza [occurrenceDate] della ricorrenza [recurrenceId].
///
/// Nome UUID v5: `"<recurrence_id>|<YYYY-MM-DD>"` nel namespace [recurrenceNamespace].
String occurrenceId(String recurrenceId, LocalDate occurrenceDate) {
  return _uuid.v5(recurrenceNamespace, '$recurrenceId|$occurrenceDate');
}

/// ID deterministico di una riga CSV senza id: UUID v5 di [normalizedRow] (la riga con i campi
/// normalizzati) e del suo numero d'ordine [repeat] tra le righe identiche del file (0, 1, …),
/// nel namespace [importNamespace].
String importedRowId(String normalizedRow, int repeat) => _uuid.v5(importNamespace, '$normalizedRow#$repeat');

/// True se [value] è un UUID scritto in forma canonica (8-4-4-4-12 cifre esadecimali).
bool isUuid(String value) => _uuidPattern.hasMatch(value);

final _uuidPattern = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
