import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spese_entrate/core/dates.dart';
import 'package:spese_entrate/core/ids.dart';
import 'package:spese_entrate/data/db/app_database.dart';
import 'package:spese_entrate/data/repositories/drift_label_repository.dart';
import 'package:spese_entrate/data/repositories/drift_recurrence_repository.dart';
import 'package:spese_entrate/data/repositories/drift_transaction_repository.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/label.dart';
import 'package:spese_entrate/domain/models/recurrence_rule.dart';
import 'package:spese_entrate/domain/models/transaction.dart';
import 'package:spese_entrate/domain/services/recurrence.dart';

LocalDate d(int y, int m, int day) => LocalDate(y, m, day);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late DriftRecurrenceRepository recurrences;
  late DriftTransactionRepository transactions;
  late String walletId;
  late String categoryId;
  var now = DateTime(2026, 10, 3, 9);

  RecurrenceRule monthly({
    String id = 'luce',
    required LocalDate start,
    RecurrenceMode mode = RecurrenceMode.auto,
    int amount = 6400,
    int? maxCount,
  }) => anchorRuleAt(
    RecurrenceRule(
      id: id,
      name: 'Bolletta luce',
      type: TransactionType.expense,
      amountCents: amount,
      walletId: walletId,
      categoryId: categoryId,
      labelIds: const ['casa'],
      frequency: RecurrenceFrequency.monthly,
      startDate: start,
      maxCount: maxCount,
      mode: mode,
    ),
    start,
  );

  Future<List<Transaction>> ofRule(String ruleId) async =>
      (await transactions.getAll()).where((t) => t.recurrenceId == ruleId).toList()
        ..sort((a, b) => a.occurrenceDate!.compareTo(b.occurrenceDate!));

  Future<List<TransactionRow>> rowsOfRule(String ruleId) =>
      (db.select(db.transactions)..where((t) => t.recurrenceId.equals(ruleId))).get();

  Future<int> outboxCount() async => (await db.select(db.outbox).get()).length;

  Future<Set<LocalDate>> skipsOf(String ruleId) async => {
    for (final e in await (db.select(db.recurrenceExceptions)..where((e) => e.ruleId.equals(ruleId))).get())
      e.occurrenceDate,
  };

  /// Fotografia di tutte le tabelle toccate, per verificare i rollback.
  Future<List<List<Map<String, Object?>>>> snapshot() async => [
    for (final table in ['transactions', 'transaction_labels', 'recurrence_rules', 'recurrence_exceptions', 'outbox'])
      [for (final row in await db.customSelect('SELECT * FROM $table ORDER BY rowid').get()) row.data],
  ];

  setUp(() async {
    now = DateTime(2026, 10, 3, 9);
    db = AppDatabase(NativeDatabase.memory(), now: () => now);
    recurrences = DriftRecurrenceRepository(db);
    transactions = DriftTransactionRepository(db);
    walletId = (await db.select(db.wallets).get()).first.id;
    categoryId = (await db.select(db.categories).get()).first.id;
    await DriftLabelRepository(db).save(const Label(id: 'casa', name: 'casa', color: 0));
  });
  tearDown(() => db.close());

  group('generatore', () {
    test('auto: recupera le occorrenze mancate fino a oggi, confermate e con la data originale', () async {
      await recurrences.save(monthly(start: d(2026, 7, 5)));
      expect(await recurrences.generate(today: d(2026, 10, 3)), 3);

      final created = await ofRule('luce');
      expect(created.map((t) => t.date), [d(2026, 7, 5), d(2026, 8, 5), d(2026, 9, 5)]);
      expect(created.every((t) => t.isConfirmed && t.date == t.occurrenceDate), isTrue);
      expect(created.first.id, occurrenceId('luce', d(2026, 7, 5)));
      expect(created.first.labelIds, ['casa']);
      expect(created.first.categoryId, categoryId);
    });

    test('confirm: pending fino a oggi + 7', () async {
      await recurrences.save(monthly(start: d(2026, 9, 5), mode: RecurrenceMode.confirm));
      await recurrences.generate(today: d(2026, 9, 28));
      final created = await ofRule('luce');
      expect(created.map((t) => t.date), [d(2026, 9, 5), d(2026, 10, 5)]);
      expect(created.every((t) => t.status == TransactionStatus.pending), isTrue);
    });

    test('idempotente: una seconda esecuzione non crea nulla e non scrive nell\'outbox', () async {
      await recurrences.save(monthly(start: d(2026, 1, 5)));
      expect(await recurrences.generate(today: d(2026, 10, 3)), 9);
      final outbox = await outboxCount();
      expect(await recurrences.generate(today: d(2026, 10, 3)), 0);
      expect(await outboxCount(), outbox);
      expect(await ofRule('luce'), hasLength(9));
    });

    test('esecuzioni in parallelo non duplicano', () async {
      await recurrences.save(monthly(start: d(2026, 1, 5)));
      await Future.wait([recurrences.generate(today: d(2026, 10, 3)), recurrences.generate(today: d(2026, 10, 3))]);
      expect(await rowsOfRule('luce'), hasLength(9));
    });

    test('un\'occorrenza eliminata o saltata non viene ricreata', () async {
      await recurrences.save(monthly(start: d(2026, 8, 5)));
      await recurrences.generate(today: d(2026, 10, 3));
      await transactions.delete(occurrenceId('luce', d(2026, 8, 5)));
      await recurrences.skip('luce', d(2026, 10, 5));
      await recurrences.generate(today: d(2026, 11, 10));
      expect((await ofRule('luce')).map((t) => t.date), [d(2026, 9, 5), d(2026, 11, 5)]);
    });

    test('le regole in pausa o cancellate non generano', () async {
      await recurrences.save(monthly(start: d(2026, 8, 5)));
      await recurrences.save(monthly(id: 'gas', start: d(2026, 8, 5)));
      await recurrences.pause('luce');
      await recurrences.delete('gas');
      expect(await recurrences.generate(today: d(2026, 10, 3)), 0);
    });

    test('auto: un pending creato in anticipo diventa confermato quando arriva la data', () async {
      await recurrences.save(monthly(start: d(2026, 9, 5)));
      await recurrences.generate(today: d(2026, 10, 3));
      final future = await recurrences.occurrenceTransaction('luce', d(2026, 10, 5));
      expect(future!.status, TransactionStatus.pending);
      await transactions.save(future.copyWith(amountCents: 7120, date: d(2026, 10, 6)));

      await recurrences.generate(today: d(2026, 10, 5));
      expect((await transactions.getById(future.id))!.status, TransactionStatus.pending, reason: 'la data è il 6');
      await recurrences.generate(today: d(2026, 10, 6));
      final confirmed = (await transactions.getById(future.id))!;
      expect(confirmed.status, TransactionStatus.confirmed);
      expect(confirmed.amountCents, 7120, reason: 'la modifica "solo questa" resta');
    });

    test('rispetta max_count e gli arretrati rifiutati alla creazione', () async {
      await recurrences.save(monthly(start: d(2026, 5, 5), maxCount: 4), skippedDates: [d(2026, 6, 5), d(2026, 7, 5)]);
      await recurrences.generate(today: d(2026, 12, 1));
      expect((await ofRule('luce')).map((t) => t.date), [d(2026, 5, 5), d(2026, 8, 5)]);
    });
  });

  group('pausa e ripresa', () {
    test('le occorrenze cadute durante la pausa non si recuperano, anche dopo un riavvio', () async {
      await recurrences.save(monthly(start: d(2026, 8, 5)));
      await recurrences.generate(today: d(2026, 9, 1));
      now = DateTime(2026, 9, 1, 9);
      await recurrences.pause('luce');
      await recurrences.generate(today: d(2026, 10, 20)); // in pausa: niente
      expect((await ofRule('luce')).map((t) => t.date), [d(2026, 8, 5)]);

      await recurrences.resume('luce', today: d(2026, 11, 5));
      expect(await skipsOf('luce'), {d(2026, 9, 5), d(2026, 10, 5)});

      // "Riavvio": un repository nuovo sullo stesso database.
      final afterRestart = DriftRecurrenceRepository(db);
      await afterRestart.generate(today: d(2026, 11, 5));
      await afterRestart.generate(today: d(2026, 11, 5));
      expect((await ofRule('luce')).map((t) => t.date), [d(2026, 8, 5), d(2026, 11, 5)]);
    });

    test('alla ripresa i pending delle date in pausa spariscono, i confermati restano', () async {
      await recurrences.save(monthly(start: d(2026, 9, 5), mode: RecurrenceMode.confirm));
      await recurrences.generate(today: d(2026, 9, 30)); // 5 set e 5 ott, pending
      final september = occurrenceId('luce', d(2026, 9, 5));
      await transactions.save((await transactions.getById(september))!.copyWith(status: TransactionStatus.confirmed));
      now = DateTime(2026, 9, 30, 9);
      await recurrences.pause('luce');

      await recurrences.resume('luce', today: d(2026, 11, 1));
      final rows = {for (final r in await rowsOfRule('luce')) r.occurrenceDate: r};
      expect(rows[d(2026, 9, 5)]!.deletedAt, isNull);
      expect(rows[d(2026, 10, 5)]!.deletedAt, isNotNull);
      expect(await skipsOf('luce'), {d(2026, 10, 5)});

      // Le occorrenze da oggi in poi tornano normalmente.
      await recurrences.generate(today: d(2026, 11, 1));
      expect((await ofRule('luce')).map((t) => t.date), [d(2026, 9, 5), d(2026, 11, 5)]);
    });

    test('tutto l\'intervallo di pausa risulta saltato, anche i pending generati prima; dopo la ripresa no', () async {
      // Ogni giorno, da confermare: il 1° ottobre il generatore propone fino all'8.
      final daily = anchorRuleAt(
        monthly(start: d(2026, 10, 1), mode: RecurrenceMode.confirm).copyWith(frequency: RecurrenceFrequency.daily),
        d(2026, 10, 1),
      );
      await recurrences.save(daily);
      await recurrences.generate(today: d(2026, 10, 1));
      // L'1 ottobre viene confermato prima della pausa.
      final first = (await transactions.getById(occurrenceId('luce', d(2026, 10, 1))))!;
      await transactions.save(first.copyWith(status: TransactionStatus.confirmed));

      now = DateTime(2026, 10, 2, 9); // pausa il 2
      await recurrences.pause('luce');
      await recurrences.generate(today: d(2026, 10, 4)); // in pausa: nulla di nuovo
      await recurrences.resume('luce', today: d(2026, 10, 5)); // ripresa il 5

      final pauseRange = [d(2026, 10, 2), d(2026, 10, 3), d(2026, 10, 4)];
      expect(await skipsOf('luce'), pauseRange.toSet());
      final rows = {for (final r in await rowsOfRule('luce')) r.occurrenceDate: r};
      for (final date in pauseRange) {
        expect(rows[date]!.deletedAt, isNotNull, reason: 'pending del $date generato prima della pausa');
      }
      expect(rows[d(2026, 10, 1)]!.deletedAt, isNull, reason: 'confermato prima della pausa');
      for (final date in [d(2026, 10, 5), d(2026, 10, 6), d(2026, 10, 7), d(2026, 10, 8)]) {
        expect(rows[date]!.deletedAt, isNull, reason: 'il $date è dopo la ripresa');
        expect(rows[date]!.status, TransactionStatus.pending);
      }

      await recurrences.generate(today: d(2026, 10, 5));
      final active = (await ofRule('luce')).map((t) => t.date).toList();
      expect(active, [for (var day = 5; day <= 12; day++) d(2026, 10, day)]..insert(0, d(2026, 10, 1)));
    });

    test('pausa e ripresa nello stesso giorno non saltano nulla', () async {
      await recurrences.save(monthly(start: d(2026, 9, 5)));
      await recurrences.pause('luce');
      await recurrences.resume('luce', today: d(2026, 10, 3));
      expect(await skipsOf('luce'), isEmpty);
      expect((await recurrences.getById('luce'))!.isPaused, isFalse);
    });
  });

  group('salta, elimina, occorrenza', () {
    test('le occorrenze eliminate si vedono come tali e non si rigenerano', () async {
      await recurrences.save(monthly(start: d(2026, 9, 5), mode: RecurrenceMode.confirm));
      await recurrences.generate(today: d(2026, 9, 30));
      expect(await recurrences.watchDeletedOccurrences('luce').first, isEmpty);
      await transactions.delete(occurrenceId('luce', d(2026, 10, 5)));
      expect(await recurrences.watchDeletedOccurrences('luce').first, {d(2026, 10, 5)});
      await recurrences.generate(today: d(2026, 10, 1));
      expect((await ofRule('luce')).map((t) => t.date), [d(2026, 9, 5)]);
    });

    test('salta: eccezione e pending cancellato; un confermato resta', () async {
      await recurrences.save(monthly(start: d(2026, 9, 5), mode: RecurrenceMode.confirm));
      await recurrences.generate(today: d(2026, 9, 30));
      await recurrences.skip('luce', d(2026, 10, 5));
      expect((await ofRule('luce')).map((t) => t.date), [d(2026, 9, 5)]);
      expect(await skipsOf('luce'), {d(2026, 10, 5)});

      await transactions.save((await ofRule('luce')).single.copyWith(status: TransactionStatus.confirmed));
      await recurrences.skip('luce', d(2026, 9, 5));
      expect((await ofRule('luce')).single.isConfirmed, isTrue);
    });

    test('elimina: la regola e i pending spariscono, lo storico confermato resta', () async {
      await recurrences.save(monthly(start: d(2026, 8, 5), mode: RecurrenceMode.confirm));
      await recurrences.generate(today: d(2026, 9, 30));
      final august = (await ofRule('luce')).first;
      await transactions.save(august.copyWith(status: TransactionStatus.confirmed));

      await recurrences.delete('luce');
      expect(await recurrences.getById('luce'), isNull);
      expect((await ofRule('luce')).map((t) => t.date), [d(2026, 8, 5)]);
      expect(await recurrences.generate(today: d(2026, 12, 1)), 0);
      await expectLater(recurrences.save(monthly(start: d(2026, 8, 5))), throwsStateError);
    });

    test('occorrenza futura: creata una volta sola come pending con ID deterministico', () async {
      await recurrences.save(monthly(start: d(2026, 9, 5)));
      final first = await recurrences.occurrenceTransaction('luce', d(2026, 12, 5));
      final again = await recurrences.occurrenceTransaction('luce', d(2026, 12, 5));
      expect(first!.id, occurrenceId('luce', d(2026, 12, 5)));
      expect(first.status, TransactionStatus.pending);
      expect(again!.id, first.id);
      expect(await rowsOfRule('luce'), hasLength(1));

      await recurrences.skip('luce', d(2027, 1, 5));
      expect(await recurrences.occurrenceTransaction('luce', d(2027, 1, 5)), isNull);
    });
  });

  group('divisione "questa e le successive"', () {
    /// Simula il form: l'occorrenza [boundary] modificata e spostata a [newDate], con [amount].
    Future<RecurrenceRule> splitAt(LocalDate boundary, LocalDate newDate, {int amount = 7000}) async {
      final old = (await recurrences.getById('luce'))!;
      final next = anchorRuleAt(old.copyWith(id: 'luce-2', amountCents: amount, pausedAt: null), newDate);
      final saved = await recurrences.split('luce', boundary: boundary, next: next);
      final edited = (await transactions.getById(occurrenceId('luce', boundary)))!;
      await transactions.save(
        edited.copyWith(amountCents: amount, date: newDate, recurrenceId: saved.id, occurrenceDate: saved.startDate),
      );
      return saved;
    }

    test('con cambio data: niente sovrapposizioni né duplicati, i pending si rigenerano', () async {
      await recurrences.save(monthly(start: d(2026, 8, 5), mode: RecurrenceMode.confirm));
      await recurrences.generate(today: d(2026, 9, 30)); // 5 ago, 5 set, 5 ott pending
      await splitAt(d(2026, 9, 5), d(2026, 9, 12));
      // Orizzonte fino al 12 ottobre; due volte per verificare che non si duplica.
      await recurrences.generate(today: d(2026, 10, 5));
      await recurrences.generate(today: d(2026, 10, 5));

      expect((await recurrences.getById('luce'))!.endDate, d(2026, 9, 4));
      expect((await ofRule('luce')).map((t) => t.date), [d(2026, 8, 5)]);
      final newOnes = await ofRule('luce-2');
      expect(newOnes.map((t) => t.date), [d(2026, 9, 12), d(2026, 10, 12)]);
      expect(newOnes.map((t) => t.amountCents).toSet(), {7000});
      // Il 5 ottobre della vecchia regola, ancora da confermare, non esiste più.
      final oldOctober = (await rowsOfRule('luce')).firstWhere((r) => r.occurrenceDate == d(2026, 10, 5));
      expect(oldOctober.deletedAt, isNotNull);
    });

    test('i movimenti successivi già confermati restano identici e non si duplicano', () async {
      await recurrences.save(monthly(start: d(2026, 8, 5), mode: RecurrenceMode.confirm));
      await recurrences.generate(today: d(2026, 9, 30));
      // Ottobre confermato in anticipo, con importo reale.
      final october = (await transactions.getById(occurrenceId('luce', d(2026, 10, 5))))!;
      await transactions.save(october.copyWith(status: TransactionStatus.confirmed, amountCents: 6650));
      final octoberBefore = await (db.select(db.transactions)..where((t) => t.id.equals(october.id))).getSingle();

      await splitAt(d(2026, 9, 5), d(2026, 9, 12));
      await recurrences.generate(today: d(2026, 11, 5));

      final octoberAfter = await (db.select(db.transactions)..where((t) => t.id.equals(october.id))).getSingle();
      expect(octoberAfter, octoberBefore, reason: 'nessun campo cambiato, nemmeno updated_at');
      // La nuova regola salta il 12 ottobre (corrisponde al 5 ottobre già confermato).
      expect(await skipsOf('luce-2'), {d(2026, 10, 12)});
      expect((await ofRule('luce-2')).map((t) => t.date), [d(2026, 9, 12), d(2026, 11, 12)]);
    });

    test('auto: lo storico confermato della vecchia regola non cambia', () async {
      await recurrences.save(monthly(start: d(2026, 1, 5), maxCount: 12));
      await recurrences.generate(today: d(2026, 10, 3)); // gen–set confermati
      final historyBefore = await rowsOfRule('luce');
      final next = anchorRuleAt(
        (await recurrences.getById('luce'))!.copyWith(id: 'luce-2', amountCents: 7000),
        d(2026, 10, 5),
      );
      final saved = await recurrences.split('luce', boundary: d(2026, 10, 5), next: next);
      expect(saved.maxCount, 3);
      expect(await rowsOfRule('luce'), historyBefore);
      await recurrences.generate(today: d(2027, 6, 1));
      expect((await ofRule('luce-2')).map((t) => t.date), [d(2026, 10, 5), d(2026, 11, 5), d(2026, 12, 5)]);
    });

    test('data sovrapposta all\'occorrenza precedente: rifiutata senza modifiche', () async {
      await recurrences.save(monthly(start: d(2026, 8, 5), mode: RecurrenceMode.confirm));
      await recurrences.generate(today: d(2026, 9, 30));
      final before = await snapshot();
      final next = anchorRuleAt((await recurrences.getById('luce'))!.copyWith(id: 'luce-2'), d(2026, 8, 5));
      await expectLater(
        recurrences.split('luce', boundary: d(2026, 9, 5), next: next),
        throwsA(isA<SplitDateException>()),
      );
      expect(await snapshot(), before);
    });

    test('errore a metà (salvataggio della nuova regola): rollback completo', () async {
      await recurrences.save(monthly(start: d(2026, 8, 5), mode: RecurrenceMode.confirm));
      await recurrences.generate(today: d(2026, 9, 30));
      final before = await snapshot();
      await db.customStatement(
        "CREATE TRIGGER errore_simulato BEFORE INSERT ON recurrence_rules WHEN NEW.id = 'luce-2' "
        "BEGIN SELECT RAISE(ABORT, 'errore simulato'); END;",
      );
      final next = anchorRuleAt((await recurrences.getById('luce'))!.copyWith(id: 'luce-2'), d(2026, 9, 12));
      await expectLater(
        recurrences.split('luce', boundary: d(2026, 9, 5), next: next),
        throwsA(isA<SqliteException>()),
      );
      expect(await snapshot(), before);
    });
  });

  test('ripresa con errore a metà: resta in pausa e senza eccezioni', () async {
    await recurrences.save(monthly(start: d(2026, 8, 5)));
    now = DateTime(2026, 8, 10, 9);
    await recurrences.pause('luce');
    final before = await snapshot();
    await db.customStatement(
      'CREATE TRIGGER errore_simulato BEFORE UPDATE OF paused_at ON recurrence_rules '
      "BEGIN SELECT RAISE(ABORT, 'errore simulato'); END;",
    );
    await expectLater(recurrences.resume('luce', today: d(2026, 11, 1)), throwsA(isA<SqliteException>()));
    expect(await snapshot(), before);
  });
}
