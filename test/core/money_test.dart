import 'package:flutter_test/flutter_test.dart';
import 'package:spese_entrate/core/money.dart';

void main() {
  group('formatCents', () {
    test('formatta con separatore delle migliaia e virgola decimale', () {
      expect(formatCents(123456), '€ 1.234,56');
      expect(formatCents(100000000), '€ 1.000.000,00');
    });

    test('gestisce zero e pochi centesimi', () {
      expect(formatCents(0), '€ 0,00');
      expect(formatCents(5), '€ 0,05');
      expect(formatCents(90), '€ 0,90');
    });

    test('i negativi usano il segno meno tipografico', () {
      expect(formatCents(-1500), '$minusSign € 15,00');
    });

    test('senza simbolo', () {
      expect(formatCents(8990, withSymbol: false), '89,90');
    });
  });
}
