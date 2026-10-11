import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:spese_entrate/core/dates.dart';
import 'package:spese_entrate/domain/models/category.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/recurrence_rule.dart';
import 'package:spese_entrate/domain/models/statistics.dart';
import 'package:spese_entrate/domain/models/transaction.dart';
import 'package:spese_entrate/domain/models/transaction_filters.dart';
import 'package:spese_entrate/domain/models/wallet.dart';
import 'package:spese_entrate/domain/services/recurrence.dart';
import 'package:spese_entrate/features/recurring/presentation/recurrence_text.dart';

// Regole dei modelli di dominio che non passano dai servizi: getter, gruppi, uguaglianze,
// validazioni e testi derivati (descrizioni delle ricorrenze, messaggi delle eccezioni).
void main() {
  setUpAll(() => initializeDateFormatting('it_IT'));

  group('Wallet', () {
    test('gruppi della schermata Portafogli', () {
      expect(WalletType.values.map((t) => (t, t.group)), [
        (WalletType.cash, WalletGroup.liquidity),
        (WalletType.checking, WalletGroup.liquidity),
        (WalletType.card, WalletGroup.liquidity),
        (WalletType.savings, WalletGroup.savings),
        (WalletType.investment, WalletGroup.investments),
        (WalletType.other, WalletGroup.liquidity),
      ]);
    });

    test('archiviato se ha archived_at', () {
      final wallet = Wallet(
        id: 'w',
        name: 'Conto',
        type: WalletType.checking,
        initialBalanceDate: LocalDate(2026, 1, 1),
      );
      expect(wallet.isArchived, isFalse);
      expect(wallet.copyWith(archivedAt: DateTime.utc(2026)).isArchived, isTrue);
      expect(wallet.includeInTotal, isTrue, reason: 'di base conta nel patrimonio');
      expect(wallet.currency, 'EUR');
    });
  });

  test('Category: archiviata se ha archived_at', () {
    const category = Category(id: 'c', name: 'Casa', kind: CategoryKind.expense, color: 0);
    expect(category.isArchived, isFalse);
    expect(category.copyWith(archivedAt: DateTime.utc(2026)).isArchived, isTrue);
  });

  group('Transaction', () {
    final tx = Transaction(
      id: 't',
      type: TransactionType.expense,
      amountCents: 100,
      date: LocalDate(2026, 10, 1),
      walletId: 'w',
    );

    test('di base è confermato, in euro e senza ricorrenza', () {
      expect(tx.isConfirmed, isTrue);
      expect(tx.currency, 'EUR');
      expect(tx.recurrenceId, isNull);
      expect(tx.copyWith(status: TransactionStatus.pending).isConfirmed, isFalse);
    });

    test('uguaglianza per valore (serve a capire se il form è cambiato)', () {
      expect(tx.copyWith(labelIds: ['a']), tx.copyWith(labelIds: ['a']));
      expect(tx.copyWith(amountCents: 101), isNot(tx));
    });
  });

  group('PeriodSummary', () {
    test('saldo ed entrate spese', () {
      const summary = PeriodSummary(incomeCents: 200000, expenseCents: 62000);
      expect(summary.balanceCents, 138000);
      expect(summary.spentRatio, closeTo(0.31, 1e-9));
    });

    test('senza entrate la quota spesa non esiste (niente divisione per zero)', () {
      expect(const PeriodSummary(incomeCents: 0, expenseCents: 5000).spentRatio, isNull);
      expect(const PeriodSummary(incomeCents: 0, expenseCents: 5000).balanceCents, -5000);
    });

    test('spese oltre le entrate: quota sopra 1', () {
      expect(const PeriodSummary(incomeCents: 1000, expenseCents: 1500).spentRatio, 1.5);
    });
  });

  group('TransactionFilters', () {
    test('predefiniti: nessun filtro attivo', () {
      const filters = TransactionFilters();
      expect(filters.isActive, isFalse);
      expect(filters.hasLabelFilter, isFalse);
      expect(filters.labelMatch, LabelMatch.any);
      expect(filters.showTransfers, isTrue);
    });

    test('ogni gruppo di filtri conta una volta sola', () {
      final filters = const TransactionFilters().copyWith(
        type: TypeFilter.expense,
        walletIds: {'a', 'b'},
        categoryIds: {'c'},
        labelIds: {'l1', 'l2'},
        withoutLabels: true,
        showTransfers: false,
      );
      expect(filters.activeCount, 5);
      expect(filters.isActive, isTrue);
    });
  });

  test('RecurrenceRule: in pausa se ha paused_at; intervallo di base 1', () {
    final rule = RecurrenceRule(
      id: 'r',
      name: 'Affitto',
      type: TransactionType.expense,
      amountCents: 75000,
      walletId: 'w',
      frequency: RecurrenceFrequency.monthly,
      startDate: LocalDate(2026, 1, 1),
      mode: RecurrenceMode.auto,
    );
    expect(rule.isPaused, isFalse);
    expect(rule.interval, 1);
    expect(rule.labelIds, isEmpty);
    expect(rule.copyWith(pausedAt: DateTime.utc(2026)).isPaused, isTrue);
  });

  group('Period', () {
    test('uguaglianza e hash per tipo e intervallo', () {
      final a = Period.containing(PeriodType.month, LocalDate(2026, 10, 3));
      final b = Period.containing(PeriodType.month, LocalDate(2026, 10, 28));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect({a, b}, hasLength(1));
      expect(a, isNot(Period.custom(a.start, a.end)), reason: 'stesse date, tipo diverso');
      expect(a.toString(), 'Period(month, 2026-10-01…2026-10-31)');
    });

    test('inizio settimana non valido: errore chiaro', () {
      expect(() => Period.containing(PeriodType.week, LocalDate(2026, 10, 3), weekStart: 0), throwsArgumentError);
      expect(() => Period.containing(PeriodType.week, LocalDate(2026, 10, 3), weekStart: 8), throwsArgumentError);
    });
  });

  group('Descrizioni delle ricorrenze', () {
    RecurrenceRule ruleOf(RecurrenceFrequency frequency, LocalDate start, {int interval = 1}) => anchorRuleAt(
      RecurrenceRule(
        id: 'r',
        name: 'Regola',
        type: TransactionType.expense,
        amountCents: 100,
        walletId: 'w',
        frequency: frequency,
        interval: interval,
        startDate: start,
        mode: RecurrenceMode.auto,
      ),
      start,
    );

    test('frequenze, intervalli, articoli e il primo del mese', () {
      expect(describeSchedule(ruleOf(RecurrenceFrequency.daily, LocalDate(2026, 10, 1))), 'Ogni giorno');
      expect(describeSchedule(ruleOf(RecurrenceFrequency.daily, LocalDate(2026, 10, 1), interval: 3)), 'Ogni 3 giorni');
      expect(describeSchedule(ruleOf(RecurrenceFrequency.weekly, LocalDate(2026, 10, 5))), 'Ogni settimana, il lunedì');
      expect(
        describeSchedule(ruleOf(RecurrenceFrequency.weekly, LocalDate(2026, 10, 4), interval: 2)),
        'Ogni 2 settimane, la domenica',
      );
      expect(describeSchedule(ruleOf(RecurrenceFrequency.monthly, LocalDate(2026, 10, 1))), 'Ogni mese, il 1°');
      expect(
        describeSchedule(ruleOf(RecurrenceFrequency.monthly, LocalDate(2026, 10, 5), interval: 2)),
        'Ogni 2 mesi, il 5',
      );
      expect(describeSchedule(ruleOf(RecurrenceFrequency.yearly, LocalDate(2027, 3, 15))), 'Ogni anno, il 15 marzo');
      expect(
        describeSchedule(ruleOf(RecurrenceFrequency.yearly, LocalDate(2027, 3, 1), interval: 2)),
        'Ogni 2 anni, il 1° marzo',
      );
    });

    test('fine della regola', () {
      final rule = ruleOf(RecurrenceFrequency.monthly, LocalDate(2026, 10, 5));
      expect(describeEnd(rule), isNull);
      expect(describeEnd(rule.copyWith(maxCount: 1)), '1 volta');
      expect(describeEnd(rule.copyWith(maxCount: 12)), '12 volte');
      expect(describeEnd(rule.copyWith(endDate: LocalDate(2027, 3, 5))), 'fino al 5 mar 2027');
    });

    test('date brevi con l\'anno solo se diverso', () {
      final today = LocalDate(2026, 10, 3);
      expect(shortDate(LocalDate(2026, 10, 5), today), '5 ott');
      expect(shortDate(LocalDate(2027, 1, 5), today), '5 gen 2027');
      expect(weekdayDate(LocalDate(2026, 10, 5), today), 'lun 5 ott');
      expect(longDate(LocalDate(2026, 10, 5)), 'lunedì 5 ottobre 2026');
    });
  });

  test('messaggi delle eccezioni in italiano', () {
    expect(SplitDateException(LocalDate(2026, 9, 5)).toString(), 'La nuova data deve essere dopo il 2026-09-05');
    expect(
      const AutomaticOccurrenceException('t').toString(),
      'Il movimento t verrà confermato automaticamente alla sua data',
    );
  });
}
