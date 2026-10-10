import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spese_entrate/core/clock.dart';
import 'package:spese_entrate/core/dates.dart';
import 'package:spese_entrate/core/ids.dart';
import 'package:spese_entrate/data/db/app_database.dart';
import 'package:spese_entrate/data/db/database_provider.dart';
import 'package:spese_entrate/data/repositories/repository_providers.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/recurrence_rule.dart';
import 'package:spese_entrate/domain/models/transaction.dart';
import 'package:spese_entrate/domain/services/recurrence.dart';
import 'package:spese_entrate/features/recurring/application/recurring_providers.dart';
import 'package:spese_entrate/features/transactions/application/transaction_form_controller.dart';

LocalDate d(int y, int m, int day) => LocalDate(y, m, day);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late ProviderContainer container;
  late String walletId;
  late String categoryId;
  var now = DateTime(2026, 10, 10, 9);

  setUp(() async {
    now = DateTime(2026, 10, 10, 9);
    db = AppDatabase(NativeDatabase.memory(), now: () => now);
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db), clockProvider.overrideWithValue(() => now)],
    );
    walletId = (await db.select(db.wallets).get()).first.id;
    categoryId = (await db.select(db.categories).get()).first.id;
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
  });

  /// Form tenuto in vita da un ascoltatore (si auto-elimina).
  TransactionFormController form(TransactionFormSeed seed) {
    final provider = transactionFormControllerProvider(seed);
    container.listen(provider, (_, _) {});
    return container.read(provider.notifier);
  }

  TransactionFormState stateOf(TransactionFormSeed seed) => container.read(transactionFormControllerProvider(seed));

  Future<List<Transaction>> all() => container.read(transactionRepositoryProvider).getAll();

  group('Ripeti in Inserimento rapido', () {
    const seed = TransactionFormSeed.create(TransactionType.expense);

    void fill(TransactionFormController f, {required LocalDate date, RepeatSettings? repeat}) {
      f
        ..pressKey('6')
        ..pressKey('4')
        ..pressKey('00')
        ..selectCategory(categoryId)
        ..setNote('Bolletta luce')
        ..setDate(date)
        ..setRepeat(repeat);
    }

    test('crea la regola e il movimento come prima occorrenza, nella stessa transazione', () async {
      final f = form(seed);
      fill(
        f,
        date: d(2026, 10, 5),
        repeat: const RepeatSettings(frequency: RecurrenceFrequency.monthly),
      );
      final saved = await f.save(walletId: walletId);

      final rule = (await container.read(recurrenceRepositoryProvider).watchAll().first).single;
      expect(rule.name, 'Bolletta luce');
      expect(rule.amountCents, 6400);
      expect(rule.byMonthDay, 5);
      expect(rule.startDate, d(2026, 10, 5));
      expect(saved!.recurrenceId, rule.id);
      expect(saved.occurrenceDate, d(2026, 10, 5));
      expect((await all()).single.id, saved.id, reason: 'la prossima è a novembre');
    });

    test('regola nel passato: gli arretrati si conoscono prima e si registrano solo se accettati', () async {
      final f = form(seed);
      fill(
        f,
        date: d(2026, 7, 5),
        repeat: const RepeatSettings(frequency: RecurrenceFrequency.monthly),
      );
      expect(stateOf(seed).backlogDates(d(2026, 10, 10)), [d(2026, 8, 5), d(2026, 9, 5), d(2026, 10, 5)]);

      // Rifiutati: restano come date saltate, il generatore non le crea mai.
      await f.save(walletId: walletId, skippedBacklog: stateOf(seed).backlogDates(d(2026, 10, 10)));
      await container.read(recurrenceGeneratorProvider).run();
      expect((await all()).map((t) => t.date), [d(2026, 7, 5)]);
    });

    test('arretrati accettati: generati con la data originale di ciascuna occorrenza', () async {
      final f = form(seed);
      fill(
        f,
        date: d(2026, 8, 5),
        repeat: const RepeatSettings(frequency: RecurrenceFrequency.monthly),
      );
      await f.save(walletId: walletId);
      expect((await all()).map((t) => t.date), [d(2026, 10, 5), d(2026, 9, 5), d(2026, 8, 5)]);
      expect((await all()).every((t) => t.isConfirmed), isTrue);
    });

    test('se il movimento non si salva, non resta nemmeno la regola', () async {
      await db.customStatement(
        'CREATE TRIGGER errore_simulato BEFORE INSERT ON transactions '
        "BEGIN SELECT RAISE(ABORT, 'errore simulato'); END;",
      );
      final f = form(seed);
      fill(
        f,
        date: d(2026, 10, 5),
        repeat: const RepeatSettings(frequency: RecurrenceFrequency.monthly),
      );
      await expectLater(f.save(walletId: walletId), throwsA(isA<SqliteException>()));
      expect(await db.select(db.recurrenceRules).get(), isEmpty);
      expect((await db.select(db.outbox).get()).where((o) => o.entity == 'recurrence_rules'), isEmpty);
    });
  });

  group('Conferma da "In arrivo"', () {
    test('il primo tasto sostituisce l\'importo proposto; il salvataggio conferma', () async {
      final repository = container.read(recurrenceRepositoryProvider);
      await repository.save(
        anchorRuleAt(
          ruleFor(walletId, categoryId, start: d(2026, 10, 12), mode: RecurrenceMode.confirm),
          d(2026, 10, 12),
        ),
      );
      await container.read(recurrenceGeneratorProvider).run();
      container.listen(upcomingTransactionsProvider, (_, _) {});
      final pending = (await container.read(upcomingTransactionsProvider.future)).single;

      final seed = TransactionFormSeed.confirm(pending);
      final f = form(seed);
      expect(stateOf(seed).amountCents, 6400);
      f
        ..pressKey('7')
        ..pressKey('1')
        ..pressKey('2')
        ..pressKey('0');
      expect(stateOf(seed).amountCents, 7120);
      final saved = await f.save(walletId: pending.walletId);
      expect(saved!.status, TransactionStatus.confirmed);
      expect(saved.id, pending.id);
      expect((await container.read(transactionRepositoryProvider).getById(pending.id))!.isConfirmed, isTrue);
    });
  });

  group('Modifica "questa e le successive"', () {
    test('divide la regola, sposta la data e non tocca i successivi già confermati', () async {
      final repository = container.read(recurrenceRepositoryProvider);
      await repository.save(
        anchorRuleAt(ruleFor(walletId, categoryId, start: d(2026, 9, 5), mode: RecurrenceMode.confirm), d(2026, 9, 5)),
      );
      await repository.generate(today: d(2026, 10, 1)); // 5 set e 5 ott pending
      final transactions = container.read(transactionRepositoryProvider);
      final october = (await transactions.getById(occurrenceId('luce', d(2026, 10, 5))))!;
      await transactions.save(october.copyWith(status: TransactionStatus.confirmed));
      final september = (await transactions.getById(occurrenceId('luce', d(2026, 9, 5))))!;

      final seed = TransactionFormSeed.edit(september, const []);
      final f = form(seed)
        ..setAmount(7000)
        ..setDate(d(2026, 9, 8));
      final saved = await f.save(walletId: walletId, scope: EditScope.following);

      final rules = await repository.watchAll().first;
      final old = rules.firstWhere((r) => r.id == 'luce');
      final next = rules.firstWhere((r) => r.id != 'luce');
      expect(old.endDate, d(2026, 9, 4));
      expect(next.startDate, d(2026, 9, 8));
      expect(next.amountCents, 7000);
      expect(saved!.recurrenceId, next.id);
      expect(saved.occurrenceDate, d(2026, 9, 8));
      expect(saved.id, september.id, reason: 'stesso movimento, aggiornato per ID');

      final octoberAfter = (await transactions.getById(october.id))!;
      expect(octoberAfter, october.copyWith(status: TransactionStatus.confirmed));
      await repository.generate(today: d(2026, 11, 5));
      final ofNext = (await all()).where((t) => t.recurrenceId == next.id).map((t) => t.date).toList()..sort();
      expect(ofNext, [d(2026, 9, 8), d(2026, 11, 8)], reason: 'l\'8 ottobre corrisponde al 5 ottobre già confermato');
    });

    test('data prima dell\'occorrenza precedente: errore e nessuna modifica', () async {
      final repository = container.read(recurrenceRepositoryProvider);
      await repository.save(anchorRuleAt(ruleFor(walletId, categoryId, start: d(2026, 8, 5)), d(2026, 8, 5)));
      await repository.generate(today: d(2026, 10, 1));
      final september = (await container
          .read(transactionRepositoryProvider)
          .getById(occurrenceId('luce', d(2026, 9, 5))))!;
      final f = form(TransactionFormSeed.edit(september, const []))..setDate(d(2026, 8, 1));
      await expectLater(f.save(walletId: walletId, scope: EditScope.following), throwsA(isA<SplitDateException>()));
      expect(await repository.watchAll().first, hasLength(1));
      expect((await container.read(transactionRepositoryProvider).getById(september.id))!.date, d(2026, 9, 5));
    });
  });
}

/// Regola mensile "luce" da € 64,00 (da passare ad `anchorRuleAt`).
RecurrenceRule ruleFor(
  String walletId,
  String categoryId, {
  required LocalDate start,
  RecurrenceMode mode = RecurrenceMode.auto,
}) => RecurrenceRule(
  id: 'luce',
  name: 'Bolletta luce',
  type: TransactionType.expense,
  amountCents: 6400,
  walletId: walletId,
  categoryId: categoryId,
  frequency: RecurrenceFrequency.monthly,
  startDate: start,
  mode: mode,
);
