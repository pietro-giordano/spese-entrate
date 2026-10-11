import 'package:flutter_test/flutter_test.dart';
import 'package:spese_entrate/core/dates.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/transaction.dart';
import 'package:spese_entrate/domain/models/transaction_filters.dart';
import 'package:spese_entrate/domain/services/transaction_list.dart';

var _seq = 0;

Transaction tx(
  TransactionType type, {
  int cents = 1000,
  String walletId = 'cc',
  String? toWalletId,
  String? categoryId,
  List<String> labelIds = const [],
  LocalDate? date,
  TransactionStatus status = TransactionStatus.confirmed,
}) => Transaction(
  id: 't${_seq++}',
  type: type,
  status: status,
  amountCents: cents,
  date: date ?? LocalDate(2026, 10, 3),
  walletId: walletId,
  toWalletId: toWalletId,
  categoryId: categoryId ?? (type == TransactionType.expense || type == TransactionType.income ? 'cat' : null),
  labelIds: labelIds,
);

void main() {
  group('matchesFilters', () {
    final expense = tx(TransactionType.expense, categoryId: 'food', labelIds: ['home', 'work']);
    final income = tx(TransactionType.income, categoryId: 'salary');
    final transfer = tx(TransactionType.transfer, toWalletId: 'cash');
    final adjustment = tx(TransactionType.adjustment, cents: -500);
    final all = [expense, income, transfer, adjustment];

    List<Transaction> filter(TransactionFilters filters) => all.where((t) => matchesFilters(t, filters)).toList();

    test('senza filtri passa tutto', () {
      expect(filter(const TransactionFilters()), all);
    });

    test('tipo Spese: niente entrate né rettifiche, trasferimenti secondo l\'interruttore', () {
      expect(filter(const TransactionFilters(type: TypeFilter.expense)), [expense, transfer]);
      expect(filter(const TransactionFilters(type: TypeFilter.expense, showTransfers: false)), [expense]);
    });

    test('portafogli: conta anche la destinazione dei trasferimenti', () {
      expect(filter(const TransactionFilters(walletIds: {'cash'})), [transfer]);
    });

    test('categorie: escludono trasferimenti e rettifiche', () {
      expect(filter(const TransactionFilters(categoryIds: {'food'})), [expense]);
    });

    test('label: almeno una oppure tutte', () {
      expect(filter(const TransactionFilters(labelIds: {'home', 'travel'})), [expense]);
      expect(filter(const TransactionFilters(labelIds: {'home', 'travel'}, labelMatch: LabelMatch.all)), isEmpty);
      expect(filter(const TransactionFilters(labelIds: {'home', 'work'}, labelMatch: LabelMatch.all)), [expense]);
    });

    group('Senza label', () {
      final home = tx(TransactionType.expense, categoryId: 'food', labelIds: ['home']);
      final both = tx(TransactionType.expense, categoryId: 'food', labelIds: ['home', 'work']);
      final none = tx(TransactionType.expense, categoryId: 'food');
      final list = [home, both, none, transfer, adjustment];
      List<Transaction> pick(TransactionFilters f) => list.where((t) => matchesFilters(t, f)).toList();

      test('da solo: i movimenti senza label, in entrambe le modalità', () {
        expect(pick(const TransactionFilters(withoutLabels: true)), [none]);
        expect(pick(const TransactionFilters(withoutLabels: true, labelMatch: LabelMatch.all)), [none]);
      });

      test('«Almeno una»: label scelte oppure nessuna label', () {
        expect(pick(const TransactionFilters(withoutLabels: true, labelIds: {'work'})), [both, none]);
      });

      test('«Tutte» vale solo per le label incluse; «Senza label» si aggiunge', () {
        expect(
          pick(const TransactionFilters(withoutLabels: true, labelIds: {'home', 'work'}, labelMatch: LabelMatch.all)),
          [both, none],
        );
      });

      test('trasferimenti e rettifiche restano esclusi: le label non si applicano', () {
        expect(pick(const TransactionFilters(withoutLabels: true)), isNot(contains(transfer)));
        expect(pick(const TransactionFilters(withoutLabels: true)), isNot(contains(adjustment)));
      });

      test('conta come un solo filtro, anche insieme ad altre label', () {
        expect(const TransactionFilters(withoutLabels: true).activeCount, 1);
        expect(const TransactionFilters(withoutLabels: true, labelIds: {'home'}).activeCount, 1);
      });
    });

    test('activeCount conta i filtri diversi dal predefinito', () {
      expect(const TransactionFilters().activeCount, 0);
      expect(const TransactionFilters(type: TypeFilter.income, walletIds: {'cc'}, showTransfers: false).activeCount, 3);
      // La modalità delle label da sola non è un filtro.
      expect(const TransactionFilters(labelMatch: LabelMatch.all).activeCount, 0);
    });
  });

  group('groupByDay', () {
    test('giorni dal più recente con totale entrate − spese, senza trasferimenti e rettifiche', () {
      final groups = groupByDay([
        tx(TransactionType.expense, cents: 6420, date: LocalDate(2026, 10, 3)),
        tx(TransactionType.expense, cents: 450, date: LocalDate(2026, 10, 3)),
        tx(TransactionType.income, cents: 240000, date: LocalDate(2026, 10, 2)),
        tx(TransactionType.expense, cents: 75000, date: LocalDate(2026, 10, 1)),
        tx(TransactionType.transfer, cents: 50000, toWalletId: 'etf', date: LocalDate(2026, 10, 1)),
        tx(TransactionType.adjustment, cents: 999, date: LocalDate(2026, 10, 1)),
      ]);

      expect(groups.map((g) => g.date), [LocalDate(2026, 10, 3), LocalDate(2026, 10, 2), LocalDate(2026, 10, 1)]);
      expect(groups.map((g) => g.totalCents), [-6870, 240000, -75000]);
      expect(groups.last.transactions, hasLength(3));
    });
  });
}
