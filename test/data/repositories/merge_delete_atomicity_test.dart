import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spese_entrate/core/dates.dart';
import 'package:spese_entrate/core/ids.dart';
import 'package:spese_entrate/data/db/app_database.dart';
import 'package:spese_entrate/data/repositories/drift_category_repository.dart';
import 'package:spese_entrate/data/repositories/drift_label_repository.dart';
import 'package:spese_entrate/data/repositories/drift_transaction_repository.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/label.dart';
import 'package:spese_entrate/domain/models/transaction.dart';
import 'package:spese_entrate/domain/repositories/label_repository.dart';

const _tables = ['transactions', 'recurrence_rules', 'categories', 'labels', 'transaction_labels', 'outbox'];

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late DriftCategoryRepository categories;
  late DriftLabelRepository labels;
  late DriftTransactionRepository transactions;
  late String fromCategory;
  late String intoCategory;
  late String walletId;
  const home = Label(id: 'home', name: 'casa', color: 0);
  const house = Label(id: 'house', name: 'abitazione', color: 0);

  /// Fotografia completa delle tabelle toccate dalle unioni, outbox compreso.
  Future<Map<String, List<Map<String, Object?>>>> snapshot() async => {
    for (final table in _tables)
      table: [for (final row in await db.customSelect('SELECT * FROM $table ORDER BY rowid').get()) row.data],
  };

  /// Errore simulato: SQLite interrompe la scrittura che fa scattare il trigger.
  Future<void> failOn(String trigger) => db.customStatement(
    'CREATE TRIGGER errore_simulato $trigger BEGIN SELECT RAISE(ABORT, \'errore simulato\'); END;',
  );

  Transaction expense(String category, {List<String> labelIds = const []}) => Transaction(
    id: newId(),
    type: TransactionType.expense,
    amountCents: 100,
    date: LocalDate(2026, 10, 1),
    walletId: walletId,
    categoryId: category,
    labelIds: labelIds,
  );

  Future<void> insertRule({required String categoryId, required List<String> labelIds}) => db
      .into(db.recurrenceRules)
      .insert(
        RecurrenceRulesCompanion.insert(
          id: newId(),
          createdAt: 0,
          updatedAt: 0,
          deviceId: 'd',
          name: 'Regola',
          type: TransactionType.expense,
          amountCents: 100,
          currency: 'EUR',
          walletId: walletId,
          categoryId: Value(categoryId),
          labelIds: labelIds,
          frequency: RecurrenceFrequency.monthly,
          startDate: LocalDate(2026, 1, 1),
          mode: RecurrenceMode.auto,
        ),
      );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory(), now: () => DateTime.utc(2026, 10, 3, 8));
    categories = DriftCategoryRepository(db);
    labels = DriftLabelRepository(db);
    transactions = DriftTransactionRepository(db);
    final all = await categories.watchAll().first;
    fromCategory = all[0].id;
    intoCategory = all[1].id;
    walletId = (await db.select(db.wallets).get()).first.id;
    await labels.save(home);
    await labels.save(house);
    // Due movimenti e una ricorrenza sulla categoria e sulla label d'origine.
    await transactions.save(expense(fromCategory, labelIds: ['home']));
    await transactions.save(expense(fromCategory, labelIds: ['home', 'house']));
    await insertRule(categoryId: fromCategory, labelIds: ['home']);
  });
  tearDown(() => db.close());

  group('unione di categorie: tutto o niente', () {
    final failures = {
      'sul primo movimento': 'BEFORE UPDATE OF category_id ON transactions',
      'sulla ricorrenza (a metà)': 'BEFORE UPDATE OF category_id ON recurrence_rules',
      'sull\'outbox': "BEFORE INSERT ON outbox WHEN NEW.entity = 'recurrence_rules'",
      'sulla cancellazione dell\'origine (ultimo passo)':
          'BEFORE UPDATE OF deleted_at ON categories WHEN NEW.deleted_at IS NOT NULL',
    };

    for (final MapEntry(key: where, value: trigger) in failures.entries) {
      test('errore $where: nessuna modifica resta, outbox compreso', () async {
        final before = await snapshot();
        await failOn(trigger);
        await expectLater(
          categories.merge(fromId: fromCategory, intoId: intoCategory),
          throwsA(isA<SqliteException>()),
        );
        expect(await snapshot(), before);
      });
    }

    test('senza errori: movimenti, ricorrenza, origine cancellata e outbox', () async {
      final outboxBefore = (await db.select(db.outbox).get()).length;
      await categories.merge(fromId: fromCategory, intoId: intoCategory);

      expect((await transactions.getAll()).map((t) => t.categoryId).toSet(), {intoCategory});
      expect((await db.select(db.recurrenceRules).getSingle()).categoryId, intoCategory);
      final origin = await (db.select(db.categories)..where((c) => c.id.equals(fromCategory))).getSingle();
      expect(origin.deletedAt, isNotNull);
      final outbox = (await db.select(db.outbox).get()).skip(outboxBefore).toList();
      expect(outbox.map((o) => (o.entity, o.op)), [
        ('transactions', OutboxOp.upsert),
        ('transactions', OutboxOp.upsert),
        ('recurrence_rules', OutboxOp.upsert),
        ('categories', OutboxOp.delete),
      ]);
    });

    test('verso una categoria già cancellata non si unisce', () async {
      await categories.merge(fromId: fromCategory, intoId: intoCategory);
      final third = (await categories.watchAll().first)[2].id;
      await expectLater(categories.merge(fromId: third, intoId: fromCategory), throwsStateError);
    });
  });

  group('unione di label: tutto o niente', () {
    final failures = {
      'sul nuovo collegamento': 'BEFORE INSERT ON transaction_labels',
      'sulla ricorrenza': 'BEFORE UPDATE OF label_ids ON recurrence_rules',
      'sulla cancellazione della label d\'origine':
          'BEFORE UPDATE OF deleted_at ON labels WHEN NEW.deleted_at IS NOT NULL',
    };

    for (final MapEntry(key: where, value: trigger) in failures.entries) {
      test('errore $where: nessuna modifica resta, outbox compreso', () async {
        final before = await snapshot();
        await failOn(trigger);
        await expectLater(labels.merge(fromId: 'home', intoId: 'house'), throwsA(isA<SqliteException>()));
        expect(await snapshot(), before);
      });
    }

    test('verso o da una label eliminata non si unisce', () async {
      await labels.delete('house');
      await expectLater(labels.merge(fromId: 'home', intoId: 'house'), throwsA(isA<DeletedLabelException>()));
      await expectLater(labels.merge(fromId: 'house', intoId: 'home'), throwsA(isA<DeletedLabelException>()));
    });
  });

  group('eliminazione di una label', () {
    test('lapide e outbox: la label e i suoi collegamenti restano come cancellati', () async {
      final outboxBefore = (await db.select(db.outbox).get()).length;
      await labels.delete('home');

      final row = await (db.select(db.labels)..where((l) => l.id.equals('home'))).getSingle();
      expect(row.deletedAt, isNotNull, reason: 'non si cancella fisicamente: serve alla sincronizzazione');
      final links = await (db.select(db.transactionLabels)..where((l) => l.labelId.equals('home'))).get();
      expect(links, hasLength(2));
      expect(links.every((l) => l.deletedAt != null), isTrue);

      final outbox = (await db.select(db.outbox).get()).skip(outboxBefore).toList();
      expect(outbox.map((o) => (o.entity, o.op)), [
        ('transaction_labels', OutboxOp.delete),
        ('transaction_labels', OutboxOp.delete),
        ('labels', OutboxOp.delete),
      ]);
      expect(outbox.last.entityId, 'home');
      expect((await transactions.getAll()).expand((t) => t.labelIds), ['house']);
    });

    test('se fallisce, la label e i collegamenti restano attivi', () async {
      final before = await snapshot();
      await failOn('BEFORE UPDATE OF deleted_at ON labels WHEN NEW.deleted_at IS NOT NULL');
      await expectLater(labels.delete('home'), throwsA(isA<SqliteException>()));
      expect(await snapshot(), before);
    });

    test('non ricompare: salvarla di nuovo con lo stesso ID è rifiutato', () async {
      await labels.delete('home');
      await expectLater(labels.save(home), throwsA(isA<DeletedLabelException>()));
      expect((await labels.watchAll().first).map((l) => l.id), ['house']);
    });

    test('non ricompare: un movimento salvato dopo l\'eliminazione non la ricollega', () async {
      final tx = (await transactions.getAll()).firstWhere((t) => t.labelIds.length == 2);
      await labels.delete('home');
      // Es. la schermata di modifica era aperta prima dell'eliminazione.
      await transactions.save(tx.copyWith(note: 'modificato'));
      expect((await transactions.getById(tx.id))!.labelIds, ['house']);
      final links = await (db.select(db.transactionLabels)..where((l) => l.labelId.equals('home'))).get();
      expect(links.every((l) => l.deletedAt != null), isTrue);
    });

    test('lo stesso nome si può riusare: nasce una label nuova, la vecchia resta eliminata', () async {
      await labels.delete('home');
      await labels.save(const Label(id: 'home-2', name: 'casa', color: 0));
      expect((await labels.watchAll().first).map((l) => l.id), unorderedEquals(['house', 'home-2']));
      final old = await (db.select(db.labels)..where((l) => l.id.equals('home'))).getSingle();
      expect(old.deletedAt, isNotNull);
    });
  });
}
