import 'package:intl/intl.dart';

/// Segno meno tipografico (U+2212), più leggibile del trattino negli importi.
const minusSign = '−';

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
