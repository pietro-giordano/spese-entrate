/// Formato CSV dei movimenti, condiviso da export e import: stesse intestazioni e stessi nomi
/// dei tipi, così un file esportato si può sempre reimportare.
library;

import '../models/enums.dart';

/// Intestazioni delle colonne, in quest'ordine (esatte: l'import le richiede identiche).
const csvHeaders = [
  'data',
  'tipo',
  'importo',
  'valuta',
  'portafoglio',
  'portafoglio_destinazione',
  'categoria',
  'label',
  'nota',
  'id',
];

/// Separatore delle label nella colonna `label`.
const csvLabelSeparator = '|';

/// Nome del tipo nel CSV.
String csvTypeLabel(TransactionType type) => switch (type) {
  TransactionType.expense => 'spesa',
  TransactionType.income => 'entrata',
  TransactionType.transfer => 'trasferimento',
  TransactionType.adjustment => 'rettifica',
};

/// Tipo da un nome del CSV, senza distinzione tra maiuscole e minuscole; null se sconosciuto.
TransactionType? csvTypeFromLabel(String label) {
  final normalized = label.trim().toLowerCase();
  for (final type in TransactionType.values) {
    if (csvTypeLabel(type) == normalized) return type;
  }
  return null;
}
