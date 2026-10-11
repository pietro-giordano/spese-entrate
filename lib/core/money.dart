/// Importi in centesimi interi (mai `double`) con formato italiano: `€ 1.234,56`.
library;

import 'package:intl/intl.dart';

/// Segno meno tipografico (U+2212), più leggibile del trattino negli importi.
const minusSign = '−';

/// Valuta predefinita (codice ISO 4217). Per ora l'app è solo in euro.
const defaultCurrency = 'EUR';

/// Massimo assoluto accettato da [parseCents]: 999.999.999.999,99.
/// Tiene lontani gli overflow quando si sommano molti importi.
const maxAbsCents = 99999999999999;

final _thousands = NumberFormat('#,##0', 'it_IT');

/// Formatta centesimi come `€ 1.234,56`, senza passare da `double`.
///
/// I negativi diventano `− € 1.234,56`. Con [withSymbol] a false: `1.234,56`.
String formatCents(int cents, {bool withSymbol = true}) {
  final abs = cents.abs();
  final units = _thousands.format(abs ~/ 100);
  final decimals = (abs % 100).toString().padLeft(2, '0');
  final number = '$units,$decimals';
  final body = withSymbol ? '€ $number' : number;
  return cents < 0 ? '$minusSign $body' : body;
}

final _digits = RegExp(r'^\d*$');
final _groupedThousands = RegExp(r'^\d{1,3}(\.\d{3})+$');
final _dotDecimal = RegExp(r'^(\d+)\.(\d{1,2})$');

/// Converte un importo scritto in italiano in centesimi. Restituisce null se non è valido.
///
/// Accetta: `1234`, `1234,5`, `1.234,56`, `,50`, `€ 12,00`, `-3,00`, `− 3`.
/// Senza virgola, un punto seguito da 1–2 cifre è il separatore decimale (`12.5` = 12,50 €),
/// seguito da gruppi di 3 cifre è il separatore delle migliaia (`1.234` = 1.234,00 €).
/// Rifiuta più di 2 decimali, migliaia raggruppate male e importi oltre [maxAbsCents].
int? parseCents(String input) {
  var text = input.replaceAll(RegExp(r'[\s €]'), '');

  var negative = false;
  if (text.startsWith('-') || text.startsWith(minusSign)) {
    negative = true;
    text = text.substring(1);
  } else if (text.startsWith('+')) {
    text = text.substring(1);
  }

  String units;
  String decimals;
  final commaParts = text.split(',');
  if (commaParts.length > 2) return null;

  if (commaParts.length == 2) {
    units = commaParts[0];
    decimals = commaParts[1];
    if (units.contains('.')) {
      if (!_groupedThousands.hasMatch(units)) return null;
      units = units.replaceAll('.', '');
    }
  } else if (_dotDecimal.firstMatch(text) case final match?) {
    units = match[1]!;
    decimals = match[2]!;
  } else if (text.contains('.')) {
    if (!_groupedThousands.hasMatch(text)) return null;
    units = text.replaceAll('.', '');
    decimals = '';
  } else {
    units = text;
    decimals = '';
  }

  if (units.isEmpty && decimals.isEmpty) return null;
  if (!_digits.hasMatch(units) || !_digits.hasMatch(decimals) || decimals.length > 2) return null;
  // 13 cifre intere bastano per maxAbsCents e restano lontane dal limite degli int.
  if (units.length > 13) return null;

  final cents = int.parse(units.isEmpty ? '0' : units) * 100 + int.parse(decimals.padRight(2, '0'));
  if (cents > maxAbsCents) return null;
  return negative ? -cents : cents;
}

/// Formato per i fogli di calcolo: virgola decimale, niente simbolo né separatore delle migliaia,
/// trattino come segno meno (es. `1234,56`, `-15,50`). Excel in italiano lo legge come numero.
String formatCentsForSpreadsheet(int cents) {
  final abs = cents.abs();
  final text = '${abs ~/ 100},${(abs % 100).toString().padLeft(2, '0')}';
  return cents < 0 ? '-$text' : text;
}
