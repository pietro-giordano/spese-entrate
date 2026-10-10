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

    test('formatta anche il massimo consentito', () {
      expect(formatCents(maxAbsCents), '€ 999.999.999.999,99');
    });
  });

  group('parseCents', () {
    test('interi e decimali con la virgola', () {
      expect(parseCents('1234'), 123400);
      expect(parseCents('1234,5'), 123450);
      expect(parseCents('1234,56'), 123456);
      expect(parseCents('0,05'), 5);
      expect(parseCents(',50'), 50);
      expect(parseCents('12,'), 1200);
    });

    test('separatore delle migliaia', () {
      expect(parseCents('1.234,56'), 123456);
      expect(parseCents('1.234.567'), 123456700);
      expect(parseCents('1.234'), 123400);
    });

    test('punto come decimale se seguito da 1–2 cifre', () {
      expect(parseCents('12.5'), 1250);
      expect(parseCents('12.50'), 1250);
    });

    test('simbolo, spazi e segni', () {
      expect(parseCents('€ 12,00'), 1200);
      expect(parseCents(' 1 234,56 '), 123456);
      expect(parseCents('-3,00'), -300);
      expect(parseCents('$minusSign € 3'), -300);
      expect(parseCents('+7'), 700);
    });

    test('rifiuta testi non validi', () {
      for (final input in ['', '€', ',', 'abc', '12,345', '1,2,3', '12.3.4', '1.23,45', '12,5a', '--3', '1e5']) {
        expect(parseCents(input), isNull, reason: input);
      }
    });

    test('rifiuta importi oltre il massimo', () {
      expect(parseCents('999.999.999.999,99'), maxAbsCents);
      expect(parseCents('1.000.000.000.000'), isNull);
      expect(parseCents('99999999999999999999'), isNull);
    });

    test('formato e lettura sono uno l\'inverso dell\'altro', () {
      for (final cents in [0, 1, 99, 100, 123456, -98765, 100000000]) {
        expect(parseCents(formatCents(cents)), cents, reason: '$cents');
      }
    });
  });
}
