import 'package:flutter_test/flutter_test.dart';
import 'package:spese_entrate/core/dates.dart';
import 'package:spese_entrate/core/ids.dart';

final _v7Pattern = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
final _v5Pattern = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

void main() {
  group('newId', () {
    test('è un UUID v7 valido', () {
      expect(newId(), matches(_v7Pattern));
    });

    test('i primi 48 bit sono il timestamp in millisecondi', () {
      // 1760000000000 ms = 0x0199c82cc000
      expect(newId(nowMs: 1760000000000), startsWith('0199c82c-c000-7'));
    });

    test('gli ID di millisecondi successivi si ordinano dopo', () {
      final earlier = newId(nowMs: 1760000000000);
      final later = newId(nowMs: 1760000000001);
      expect(earlier.compareTo(later), lessThan(0));
    });

    test('non si ripete su molte generazioni nello stesso millisecondo', () {
      final ids = {for (var i = 0; i < 10000; i++) newId(nowMs: 1760000000000)};
      expect(ids, hasLength(10000));
    });
  });

  group('occurrenceId', () {
    const recurrenceId = '0192f0c1-7b2a-7cde-8f00-112233445566';
    final date = LocalDate(2026, 10, 31);

    test('è un UUID v5 con il valore atteso', () {
      // Valore calcolato in modo indipendente con Python:
      // uuid.uuid5(UUID(recurrenceNamespace), '<recurrenceId>|2026-10-31')
      final id = occurrenceId(recurrenceId, date);
      expect(id, matches(_v5Pattern));
      expect(id, '74355bf5-2508-52f0-989b-77ebf979cf74');
    });

    test('è deterministico', () {
      expect(occurrenceId(recurrenceId, date), occurrenceId(recurrenceId, LocalDate.parse('2026-10-31')));
    });

    test('cambia con la data o con la ricorrenza', () {
      final base = occurrenceId(recurrenceId, date);
      expect(occurrenceId(recurrenceId, date.addDays(1)), isNot(base));
      expect(occurrenceId('altra-ricorrenza', date), isNot(base));
    });
  });
}
