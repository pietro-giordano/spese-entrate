import 'package:flutter_test/flutter_test.dart';
import 'package:spese_entrate/core/dates.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/transaction.dart';
import 'package:spese_entrate/domain/models/transaction_filters.dart';
import 'package:spese_entrate/domain/services/statistics.dart';
import 'package:spese_entrate/domain/services/transaction_list.dart';
import 'package:spese_entrate/domain/services/transaction_search.dart';

import 'transaction_list_test.dart' show tx;

/// Esclusioni nei filtri: vincono sempre, anche combinate con inclusioni e modalità delle label.
void main() {
  final groceries = tx(TransactionType.expense, walletId: 'cc', categoryId: 'food', labelIds: ['home']);
  final rent = tx(TransactionType.expense, walletId: 'cc', categoryId: 'house', labelIds: ['home', 'history']);
  final trip = tx(TransactionType.expense, walletId: 'card', categoryId: 'food', labelIds: ['home', 'holiday']);
  final cashLunch = tx(TransactionType.expense, walletId: 'cash', categoryId: 'food');
  final salary = tx(TransactionType.income, walletId: 'cc', categoryId: 'salary');
  final withdrawal = tx(TransactionType.transfer, walletId: 'cc', toWalletId: 'cash');
  final adjustment = tx(TransactionType.adjustment, walletId: 'card', cents: -500);
  final all = [groceries, rent, trip, cashLunch, salary, withdrawal, adjustment];

  List<Transaction> pick(TransactionFilters f) => all.where((t) => matchesFilters(t, f)).toList();

  group('l\'esclusione vince sempre sull\'inclusione', () {
    test('portafoglio incluso, categoria esclusa', () {
      final f = const TransactionFilters(walletIds: {'cc'}, excludedCategoryIds: {'house'});
      expect(pick(f), [groceries, salary, withdrawal]);
    });

    test('categoria inclusa, label esclusa', () {
      final f = const TransactionFilters(categoryIds: {'food'}, excludedLabelIds: {'holiday'});
      expect(pick(f), [groceries, cashLunch]);
    });

    test('label inclusa ed esclusa sullo stesso movimento: esce', () {
      final f = const TransactionFilters(labelIds: {'home'}, excludedLabelIds: {'history'});
      expect(pick(f), [groceries, trip]);
    });

    test('portafoglio escluso anche quando è la destinazione di un trasferimento', () {
      final f = const TransactionFilters(walletIds: {'cc'}, excludedWalletIds: {'cash'});
      expect(pick(f), [groceries, rent, salary], reason: 'il prelievo verso Contanti esce');
    });
  });

  group('portafoglio escluso: toglie ogni movimento che lo coinvolge', () {
    test('trasferimento: esce sia con l\'origine sia con la destinazione esclusa, anche se l\'altra è inclusa', () {
      expect(pick(const TransactionFilters(walletIds: {'cash'}, excludedWalletIds: {'cc'})), [cashLunch]);
      expect(
        pick(const TransactionFilters(walletIds: {'cc'}, excludedWalletIds: {'cash'})),
        isNot(contains(withdrawal)),
      );
    });

    test('rettifica: esce con il suo portafoglio escluso', () {
      expect(pick(const TransactionFilters(excludedWalletIds: {'card'})), isNot(contains(adjustment)));
      expect(pick(const TransactionFilters(excludedWalletIds: {'cc'})), contains(adjustment));
    });
  });

  group('«Senza label» a tre stati, separato dalle label effettive', () {
    test('neutro → incluso → escluso → neutro', () {
      var f = const TransactionFilters();
      expect(f.withoutLabelsState, FilterChipState.neutral);
      f = f.cycleWithoutLabels();
      expect((f.withoutLabelsState, f.withoutLabels, f.excludeWithoutLabels), (FilterChipState.included, true, false));
      f = f.cycleWithoutLabels();
      expect((f.withoutLabelsState, f.withoutLabels, f.excludeWithoutLabels), (FilterChipState.excluded, false, true));
      f = f.cycleWithoutLabels();
      expect(f, const TransactionFilters());
    });

    test('escluso da solo: toglie spese ed entrate senza label, non trasferimenti e rettifiche', () {
      expect(pick(const TransactionFilters(excludeWithoutLabels: true)), [
        groceries,
        rent,
        trip,
        withdrawal,
        adjustment,
      ]);
    });

    test('escluso con label incluse: restano i movimenti con le label incluse (almeno una / tutte)', () {
      const f = TransactionFilters(labelIds: {'home', 'holiday'}, excludeWithoutLabels: true);
      expect(pick(f), [groceries, rent, trip]);
      expect(pick(f.copyWith(labelMatch: LabelMatch.all)), [trip]);
    });

    test('escluso con label escluse: solo movimenti con label, nessuna delle escluse', () {
      expect(pick(const TransactionFilters(excludeWithoutLabels: true, excludedLabelIds: {'holiday'})), [
        groceries,
        rent,
        withdrawal,
        adjustment,
      ]);
    });

    test('incluso con label incluse: si aggiunge, in entrambe le modalità', () {
      const f = TransactionFilters(labelIds: {'home', 'history'}, withoutLabels: true);
      expect(pick(f), [groceries, rent, trip, cashLunch, salary], reason: 'almeno una label oppure nessuna');
      expect(pick(f.copyWith(labelMatch: LabelMatch.all)), [rent, cashLunch, salary], reason: 'tutte oppure nessuna');
    });

    test('incluso nasconde trasferimenti e rettifiche come ogni inclusione', () {
      expect(pick(const TransactionFilters(withoutLabels: true)), [cashLunch, salary]);
    });

    test('conta nella dimensione label, una sola volta', () {
      expect(const TransactionFilters(excludeWithoutLabels: true).activeCount, 1);
      expect(
        const TransactionFilters(labelIds: {'a'}, excludedLabelIds: {'b'}, excludeWithoutLabels: true).activeCount,
        1,
      );
    });
  });

  group('tutto escluso: risultato vuoto, ma con filtri attivi', () {
    test('tutte le categorie escluse', () {
      const f = TransactionFilters(excludedCategoryIds: {'food', 'house', 'salary'});
      expect(pick(f).where((t) => t.type == TransactionType.expense || t.type == TransactionType.income), isEmpty);
      expect(filterForAnalytics(all, f).where(countsInStatistics), isEmpty);
      expect(f.isActive, isTrue);
      expect(f.activeCount, 1);
      expect(f, isNot(const TransactionFilters()));
    });

    test('tutti i portafogli esclusi', () {
      const f = TransactionFilters(excludedWalletIds: {'cc', 'cash', 'card'});
      expect(pick(f), isEmpty);
      expect(filterForAnalytics(all, f), isEmpty);
      expect(f.isActive, isTrue);
      expect(f.activeCount, 1);
    });
  });

  group('label: «almeno una / tutte» solo per le incluse, una esclusa basta per escludere', () {
    test('almeno una', () {
      final f = const TransactionFilters(labelIds: {'home', 'holiday'}, excludedLabelIds: {'history'});
      expect(pick(f), [groceries, trip]);
    });

    test('tutte', () {
      final f = const TransactionFilters(labelIds: {'home'}, labelMatch: LabelMatch.all, excludedLabelIds: {'holiday'});
      expect(pick(f), [groceries, rent]);
      final both = const TransactionFilters(labelIds: {'home', 'history'}, labelMatch: LabelMatch.all);
      expect(pick(both), [rent]);
      expect(pick(both.copyWith(excludedLabelIds: {'history'})), isEmpty, reason: 'l\'esclusione vince');
    });

    test('«Senza label» con label escluse: i movimenti senza label restano', () {
      final f = const TransactionFilters(withoutLabels: true, excludedLabelIds: {'home'});
      expect(pick(f), [cashLunch, salary]);
    });
  });

  group('solo esclusioni', () {
    test('non nascondono trasferimenti e rettifiche (tolgono solo i movimenti coinvolti)', () {
      expect(pick(const TransactionFilters(excludedCategoryIds: {'food'})), [rent, salary, withdrawal, adjustment]);
      expect(pick(const TransactionFilters(excludedLabelIds: {'home'})), [cashLunch, salary, withdrawal, adjustment]);
    });

    test('un portafoglio escluso toglie anche trasferimenti e rettifiche che lo riguardano', () {
      expect(pick(const TransactionFilters(excludedWalletIds: {'card'})), [
        groceries,
        rent,
        cashLunch,
        salary,
        withdrawal,
      ]);
      expect(pick(const TransactionFilters(excludedWalletIds: {'cash'})), [groceries, rent, trip, salary, adjustment]);
    });

    test('le inclusioni continuano a nascondere trasferimenti e rettifiche', () {
      expect(pick(const TransactionFilters(categoryIds: {'salary'})), [salary]);
    });
  });

  group('stato dei chip e conteggio', () {
    test('neutro → incluso → escluso → neutro, per portafogli, categorie e label', () {
      var f = const TransactionFilters();
      expect(f.walletState('cc'), FilterChipState.neutral);
      f = f.cycleWallet('cc');
      expect(f.walletState('cc'), FilterChipState.included);
      expect(f.walletIds, {'cc'});
      expect(f.excludedWalletIds, isEmpty);
      f = f.cycleWallet('cc');
      expect(f.walletState('cc'), FilterChipState.excluded);
      expect(f.walletIds, isEmpty);
      expect(f.excludedWalletIds, {'cc'});
      f = f.cycleWallet('cc');
      expect(f, const TransactionFilters());

      expect(const TransactionFilters().cycleCategory('food').categoryState('food'), FilterChipState.included);
      expect(
        const TransactionFilters().cycleLabel('home').cycleLabel('home').labelState('home'),
        FilterChipState.excluded,
      );
    });

    test('inclusioni ed esclusioni della stessa sezione contano come un filtro', () {
      expect(const TransactionFilters(excludedLabelIds: {'x'}).activeCount, 1);
      expect(const TransactionFilters(labelIds: {'a'}, excludedLabelIds: {'x'}).activeCount, 1);
      expect(
        const TransactionFilters(
          excludedWalletIds: {'w'},
          excludedCategoryIds: {'c'},
          excludedLabelIds: {'l'},
        ).activeCount,
        3,
      );
      expect(const TransactionFilters(excludedCategoryIds: {'c'}).isActive, isTrue);
    });
  });

  group('valgono ovunque', () {
    final range = DateRange(LocalDate(2026, 10, 1), LocalDate(2026, 10, 31));

    test('Grafici e Confronta: i calcoli escludono i movimenti esclusi', () {
      final filtered = filterForAnalytics(all, const TransactionFilters(excludedLabelIds: {'history'}));
      expect(summarize(filtered, range).expenseCents, 3000, reason: 'spesa, viaggio e pranzo; non l\'affitto');
      final byLabel = breakdownByLabel(filtered, range, CategoryKind.expense);
      expect(byLabel.map((i) => i.id), isNot(contains('history')));
    });

    test('il tap su una fetta mantiene le esclusioni del grafico', () {
      final chart = const TransactionFilters(excludedLabelIds: {'history'}, excludedWalletIds: {'cash'});
      final slice = sliceFilters(chart, kind: CategoryKind.expense, byLabel: true, id: 'home');
      expect(slice.labelIds, {'home'});
      expect(slice.excludedLabelIds, {'history'});
      expect(slice.excludedWalletIds, {'cash'});
      expect(all.where((t) => matchesFilters(t, slice)), [groceries, trip]);
    });

    test('il tap su una fetta mantiene tutte le esclusioni, in ogni dimensione', () {
      const chart = TransactionFilters(
        walletIds: {'cc', 'card'},
        excludedWalletIds: {'cash'},
        excludedCategoryIds: {'house'},
        excludedLabelIds: {'holiday'},
        excludeWithoutLabels: true,
      );
      for (final slice in [
        sliceFilters(chart, kind: CategoryKind.expense, byLabel: false, id: 'food'),
        sliceFilters(chart, kind: CategoryKind.expense, byLabel: true, id: 'home'),
      ]) {
        expect(slice.excludedWalletIds, {'cash'});
        expect(slice.excludedCategoryIds, {'house'});
        expect(slice.excludedLabelIds, {'holiday'});
        expect(slice.excludeWithoutLabels, isTrue);
        expect(all.where((t) => matchesFilters(t, slice)), [groceries]);
      }
    });

    test('ricerca: le esclusioni dei filtri attivi si applicano', () {
      const names = SearchNames(categories: {'food': 'Spesa alimentare'});
      final results = searchTransactions(
        all,
        SearchQuery('alimentare'),
        names: names,
        filters: const TransactionFilters(excludedWalletIds: {'card'}),
      );
      expect(results, [groceries, cashLunch]);
    });
  });
}
