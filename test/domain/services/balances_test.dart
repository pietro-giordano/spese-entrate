import 'package:flutter_test/flutter_test.dart';
import 'package:spese_entrate/core/dates.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/transaction.dart';
import 'package:spese_entrate/domain/models/wallet.dart';
import 'package:spese_entrate/domain/services/balances.dart';

final checking = Wallet(
  id: 'cc',
  name: 'Conto corrente',
  type: WalletType.checking,
  initialBalanceCents: 100000,
  initialBalanceDate: LocalDate(2026, 1, 1),
);
final cash = Wallet(
  id: 'cash',
  name: 'Contanti',
  type: WalletType.cash,
  initialBalanceCents: 5000,
  initialBalanceDate: LocalDate(2026, 1, 1),
);

var _seq = 0;

Transaction tx(
  TransactionType type,
  int amountCents, {
  String walletId = 'cc',
  String? toWalletId,
  TransactionStatus status = TransactionStatus.confirmed,
  LocalDate? date,
}) {
  return Transaction(
    id: 't${_seq++}',
    type: type,
    status: status,
    amountCents: amountCents,
    date: date ?? LocalDate(2026, 10, 1),
    walletId: walletId,
    toWalletId: toWalletId,
    categoryId: type == TransactionType.expense || type == TransactionType.income ? 'cat' : null,
  );
}

void main() {
  group('saldi', () {
    final transactions = [
      tx(TransactionType.income, 200000),
      tx(TransactionType.expense, 30000),
      // pending: non contano
      tx(TransactionType.expense, 99999, status: TransactionStatus.pending),
      tx(TransactionType.income, 50000, status: TransactionStatus.pending),
      // trasferimento confermato cc → cash e uno pending cash → cc
      tx(TransactionType.transfer, 20000, toWalletId: 'cash'),
      tx(TransactionType.transfer, 5000, walletId: 'cash', toWalletId: 'cc', status: TransactionStatus.pending),
      // rettifiche con segno
      tx(TransactionType.adjustment, -1550),
      tx(TransactionType.adjustment, 300, walletId: 'cash'),
      tx(TransactionType.expense, 2000, walletId: 'cash'),
    ];

    test('conto corrente: entrate − spese − trasferimenti in uscita + rettifiche', () {
      // 1000,00 + 2000,00 − 300,00 − 200,00 − 15,50
      expect(walletBalance(checking, transactions), 248450);
    });

    test('contanti: trasferimenti in entrata + rettifica positiva − spese', () {
      // 50,00 + 200,00 + 3,00 − 20,00
      expect(walletBalance(cash, transactions), 23300);
    });

    test('walletBalances calcola tutti i saldi in un passaggio', () {
      expect(walletBalances([checking, cash], transactions), {'cc': 248450, 'cash': 23300});
    });

    test('i movimenti pending non cambiano il saldo, confermati sì', () {
      final pending = tx(TransactionType.expense, 1000, status: TransactionStatus.pending);
      expect(walletBalance(checking, [pending]), 100000);
      expect(walletBalance(checking, [pending.copyWith(status: TransactionStatus.confirmed)]), 99000);
    });

    test('un trasferimento lascia invariato il totale dei due portafogli', () {
      final transfer = [tx(TransactionType.transfer, 12345, toWalletId: 'cash')];
      final balances = walletBalances([checking, cash], transfer);
      expect(balances['cc']! + balances['cash']!, checking.initialBalanceCents + cash.initialBalanceCents);
    });

    test('upTo esclude i movimenti successivi alla data', () {
      final list = [
        tx(TransactionType.income, 1000, date: LocalDate(2026, 9, 30)),
        tx(TransactionType.income, 5000, date: LocalDate(2026, 10, 2)),
      ];
      expect(walletBalance(checking, list, upTo: LocalDate(2026, 10, 1)), 101000);
    });

    test('ignora i movimenti di portafogli sconosciuti', () {
      expect(walletBalances([checking], [tx(TransactionType.income, 1000, walletId: 'altro')]), {'cc': 100000});
    });
  });

  group('patrimonio totale', () {
    test('somma solo i portafogli inclusi e non archiviati', () {
      final excluded = cash.copyWith(id: 'excluded', includeInTotal: false);
      final archived = cash.copyWith(id: 'archived', archivedAt: DateTime.utc(2026));
      final balances = {'cc': 1000, 'cash': 200, 'excluded': 50000, 'archived': 70000};
      expect(netWorth([checking, cash, excluded, archived], balances), 1200);
    });
  });

  group('ultimo aggiornamento', () {
    test('senza rettifiche è la data del saldo iniziale', () {
      expect(
        lastUpdate(checking, [tx(TransactionType.income, 100, date: LocalDate(2026, 5, 1))]),
        LocalDate(2026, 1, 1),
      );
    });

    test('è la data dell\'ultima rettifica confermata del portafoglio', () {
      final list = [
        tx(TransactionType.adjustment, 100, date: LocalDate(2026, 3, 1)),
        tx(TransactionType.adjustment, 100, date: LocalDate(2026, 6, 1)),
        tx(TransactionType.adjustment, 100, date: LocalDate(2026, 8, 1), status: TransactionStatus.pending),
        tx(TransactionType.adjustment, 100, date: LocalDate(2026, 9, 1), walletId: 'cash'),
      ];
      expect(lastUpdate(checking, list), LocalDate(2026, 6, 1));
    });

    test('"Da aggiornare" dopo più di 30 giorni', () {
      expect(needsUpdate(checking, const [], LocalDate(2026, 1, 31)), isFalse);
      expect(needsUpdate(checking, const [], LocalDate(2026, 2, 1)), isTrue);
    });
  });

  group('gruppi', () {
    test('contanti, conto, carta e altro sono liquidità', () {
      expect(WalletType.values.map((t) => t.group), [
        WalletGroup.liquidity,
        WalletGroup.liquidity,
        WalletGroup.liquidity,
        WalletGroup.savings,
        WalletGroup.investments,
        WalletGroup.liquidity,
      ]);
    });
  });

  group('monthlyBalances', () {
    test('saldo a fine mese degli ultimi 6 mesi, l\'ultimo a oggi', () {
      final points = monthlyBalances(checking, [
        tx(TransactionType.income, 10000, date: LocalDate(2026, 6, 15)),
        tx(TransactionType.adjustment, -500, date: LocalDate(2026, 9, 30)),
        tx(TransactionType.expense, 2000, date: LocalDate(2026, 10, 2)),
      ], LocalDate(2026, 10, 3));

      expect(points.map((p) => p.date), [
        LocalDate(2026, 5, 31),
        LocalDate(2026, 6, 30),
        LocalDate(2026, 7, 31),
        LocalDate(2026, 8, 31),
        LocalDate(2026, 9, 30),
        LocalDate(2026, 10, 3),
      ]);
      expect(points.map((p) => p.balanceCents), [100000, 110000, 110000, 110000, 109500, 107500]);
    });
  });

  group('balanceUpdateTransaction', () {
    final existing = [tx(TransactionType.income, 20000, date: LocalDate(2026, 9, 1))];
    // Saldo al 30 settembre: 1.000,00 + 200,00 = 1.200,00
    Transaction? update(int newBalance, BalanceUpdateMode mode, {String? categoryId, LocalDate? date}) =>
        balanceUpdateTransaction(
          id: 'u',
          wallet: checking,
          transactions: existing,
          newBalanceCents: newBalance,
          date: date ?? LocalDate(2026, 9, 30),
          mode: mode,
          categoryId: categoryId,
        );

    test('rettifica con la differenza e il suo segno', () {
      final up = update(131240, BalanceUpdateMode.adjustment)!;
      expect((up.type, up.amountCents, up.categoryId), (TransactionType.adjustment, 11240, null));
      expect(update(100000, BalanceUpdateMode.adjustment)!.amountCents, -20000);
    });

    test('la differenza si calcola sul saldo alla data scelta', () {
      // Al 31 agosto l'entrata del 1° settembre non c'è ancora: saldo 1.000,00.
      expect(update(131240, BalanceUpdateMode.adjustment, date: LocalDate(2026, 8, 31))!.amountCents, 31240);
    });

    test('come movimento: entrata o spesa con categoria e importo positivo', () {
      final gain = update(130000, BalanceUpdateMode.movement, categoryId: 'gifts')!;
      expect((gain.type, gain.amountCents, gain.categoryId), (TransactionType.income, 10000, 'gifts'));
      final loss = update(110000, BalanceUpdateMode.movement, categoryId: 'other')!;
      expect((loss.type, loss.amountCents), (TransactionType.expense, 10000));
      expect(() => update(110000, BalanceUpdateMode.movement), throwsArgumentError);
    });

    test('differenza zero: nessun movimento, in entrambe le modalità', () {
      expect(update(120000, BalanceUpdateMode.adjustment), isNull);
      expect(update(120000, BalanceUpdateMode.movement), isNull, reason: 'senza differenza non serve la categoria');
    });
  });

  group('verifica del saldo', () {
    test('lastUpdate usa la verifica anche senza rettifiche', () {
      final verified = checking.copyWith(lastBalanceVerifiedDate: LocalDate(2026, 9, 20));
      expect(
        lastUpdate(verified, [tx(TransactionType.income, 100, date: LocalDate(2026, 10, 1))]),
        LocalDate(2026, 9, 20),
      );
    });

    test('vince la data più recente tra verifica e rettifica', () {
      final verified = checking.copyWith(lastBalanceVerifiedDate: LocalDate(2026, 9, 20));
      final later = tx(TransactionType.adjustment, 100, date: LocalDate(2026, 9, 25));
      expect(lastUpdate(verified, [later]), LocalDate(2026, 9, 25));
      expect(
        lastUpdate(verified.copyWith(lastBalanceVerifiedDate: LocalDate(2026, 9, 30)), [later]),
        LocalDate(2026, 9, 30),
      );
    });

    test('markBalanceVerified non torna indietro nel tempo', () {
      final verified = markBalanceVerified(checking, LocalDate(2026, 9, 20));
      expect(verified.lastBalanceVerifiedDate, LocalDate(2026, 9, 20));
      expect(markBalanceVerified(verified, LocalDate(2026, 9, 1)), same(verified));
      expect(markBalanceVerified(verified, LocalDate(2026, 9, 20)), same(verified));
      expect(markBalanceVerified(verified, LocalDate(2026, 10, 1)).lastBalanceVerifiedDate, LocalDate(2026, 10, 1));
    });

    test('una verifica di oltre 30 giorni fa fa ricomparire il badge', () {
      final verified = checking.copyWith(lastBalanceVerifiedDate: LocalDate(2026, 8, 31));
      expect(needsUpdate(verified, const [], LocalDate(2026, 9, 30)), isFalse);
      expect(needsUpdate(verified, const [], LocalDate(2026, 10, 1)), isTrue);
    });
  });

  group('monthlyBalances, casi limite', () {
    final today = LocalDate(2026, 10, 3);
    List<int> series(Wallet wallet, List<Transaction> list) =>
        monthlyBalances(wallet, list, today).map((p) => p.balanceCents).toList();
    final base = [tx(TransactionType.income, 10000, date: LocalDate(2026, 6, 15))];

    test('una rettifica di oggi cambia solo l\'ultimo punto', () {
      final before = series(checking, base);
      final after = series(checking, [...base, tx(TransactionType.adjustment, 5000, date: today)]);
      expect(after.sublist(0, 5), before.sublist(0, 5));
      expect(after.last, before.last + 5000);
    });

    test('un movimento retrodatato sposta i saldi dal suo mese in poi', () {
      final before = series(checking, base);
      final after = series(checking, [...base, tx(TransactionType.expense, 3000, date: LocalDate(2026, 7, 10))]);
      // Punti: mag, giu, lug, ago, set, ott. Luglio e i successivi calano di 30,00.
      expect(after.sublist(0, 2), before.sublist(0, 2));
      expect(after.sublist(2), [for (final v in before.sublist(2)) v - 3000]);
    });

    test('un movimento dell\'ultimo giorno del mese conta in quel mese', () {
      final points = series(checking, [tx(TransactionType.income, 700, date: LocalDate(2026, 8, 31))]);
      expect(points[3], 100700, reason: 'agosto');
      expect(points[2], 100000, reason: 'luglio');
    });

    test('ignora pending e altri portafogli, conta i trasferimenti nei due versi', () {
      final points = series(checking, [
        tx(TransactionType.expense, 999, status: TransactionStatus.pending, date: LocalDate(2026, 9, 1)),
        tx(TransactionType.income, 999, walletId: 'cash', date: LocalDate(2026, 9, 1)),
        tx(TransactionType.transfer, 2000, toWalletId: 'cash', date: LocalDate(2026, 9, 5)),
        tx(TransactionType.transfer, 500, walletId: 'cash', toWalletId: 'cc', date: LocalDate(2026, 9, 6)),
      ]);
      expect(points.sublist(4), [98500, 98500]);
    });

    test('i mesi prima del saldo iniziale non ci sono', () {
      final recent = checking.copyWith(initialBalanceDate: LocalDate(2026, 8, 15));
      final points = monthlyBalances(recent, const [], today);
      expect(points.map((p) => p.date), [LocalDate(2026, 8, 31), LocalDate(2026, 9, 30), today]);
    });
  });
}
