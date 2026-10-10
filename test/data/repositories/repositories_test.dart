import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spese_entrate/core/dates.dart';
import 'package:spese_entrate/core/ids.dart';
import 'package:spese_entrate/data/db/app_database.dart';
import 'package:spese_entrate/data/repositories/drift_label_repository.dart';
import 'package:spese_entrate/data/repositories/drift_settings_repository.dart';
import 'package:spese_entrate/data/repositories/drift_transaction_repository.dart';
import 'package:spese_entrate/data/repositories/drift_wallet_repository.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/label.dart';
import 'package:spese_entrate/domain/models/transaction.dart';
import 'package:spese_entrate/domain/models/wallet.dart';
import 'package:spese_entrate/domain/repositories/label_repository.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  // Orologio modificabile dai test.
  var now = DateTime.utc(2026, 10, 10, 8);
  int ms(DateTime t) => t.millisecondsSinceEpoch;

  late AppDatabase db;
  late int seededOutbox;

  setUp(() async {
    now = DateTime.utc(2026, 10, 10, 8);
    db = AppDatabase(NativeDatabase.memory(), now: () => now);
    seededOutbox = (await db.select(db.outbox).get()).length;
  });
  tearDown(() => db.close());

  Future<List<OutboxRow>> newOutbox() async => (await db.select(db.outbox).get()).skip(seededOutbox).toList();

  Transaction expense({String? id, List<String> labelIds = const [], LocalDate? date, String? categoryId = 'cat'}) =>
      Transaction(
        id: id ?? newId(),
        type: TransactionType.expense,
        amountCents: 1000,
        date: date ?? LocalDate(2026, 10, 10),
        walletId: 'cc',
        categoryId: categoryId,
        labelIds: labelIds,
      );

  group('scritture sincronizzate', () {
    test('la creazione imposta i campi comuni e accoda un upsert', () async {
      final repo = DriftWalletRepository(db);
      final wallet = Wallet(
        id: newId(),
        name: 'Carta',
        type: WalletType.card,
        initialBalanceDate: LocalDate(2026, 10, 1),
      );
      await repo.save(wallet);

      final row = await (db.select(db.wallets)..where((t) => t.id.equals(wallet.id))).getSingle();
      expect(row.createdAt, ms(now));
      expect(row.updatedAt, ms(now));
      expect(row.deviceId, await db.deviceId());
      expect(row.deletedAt, isNull);

      final outbox = await newOutbox();
      expect(outbox.map((o) => (o.entity, o.entityId, o.op, o.changedAt)), [
        ('wallets', wallet.id, OutboxOp.upsert, ms(now)),
      ]);
      expect(await repo.getById(wallet.id), wallet);
    });

    test('la modifica aggiorna updated_at e conserva created_at', () async {
      final repo = DriftWalletRepository(db);
      final wallet = Wallet(
        id: newId(),
        name: 'Carta',
        type: WalletType.card,
        initialBalanceDate: LocalDate(2026, 10, 1),
      );
      await repo.save(wallet);
      final created = now;

      now = now.add(const Duration(hours: 1));
      await repo.save(wallet.copyWith(name: 'Carta prepagata'));

      final row = await (db.select(db.wallets)..where((t) => t.id.equals(wallet.id))).getSingle();
      expect(row.name, 'Carta prepagata');
      expect(row.createdAt, ms(created));
      expect(row.updatedAt, ms(now));
      expect(await newOutbox(), hasLength(2));
    });

    test('se la scrittura fallisce non resta nulla, neanche nell\'outbox', () async {
      final repo = DriftTransactionRepository(db);
      // Spesa senza categoria: viola un CHECK del database.
      await expectLater(repo.save(expense(categoryId: null, labelIds: ['home'])), throwsA(anything));

      expect(await db.select(db.transactions).get(), isEmpty);
      expect(await db.select(db.transactionLabels).get(), isEmpty);
      expect(await newOutbox(), isEmpty);
    });

    test('cancellare e risalvare con lo stesso ID ripristina il record', () async {
      final repo = DriftWalletRepository(db);
      final wallet = (await repo.watchAll().first).first;

      await repo.delete(wallet.id);
      expect(await repo.getById(wallet.id), isNull);
      expect((await repo.watchAll().first).map((w) => w.id), isNot(contains(wallet.id)));

      await repo.save(wallet);
      expect(await repo.getById(wallet.id), wallet);
      expect((await newOutbox()).map((o) => o.op), [OutboxOp.delete, OutboxOp.upsert]);
    });
  });

  group('movimenti', () {
    test('salva e rilegge le label', () async {
      final repo = DriftTransactionRepository(db);
      final tx = expense(labelIds: ['home', 'holiday']);
      await repo.save(tx);

      final stored = await repo.getById(tx.id);
      expect(stored!.labelIds, unorderedEquals(['home', 'holiday']));
      expect((await newOutbox()).map((o) => o.entity), ['transactions', 'transaction_labels', 'transaction_labels']);
    });

    test('togliere e rimettere una label riusa il collegamento esistente', () async {
      final repo = DriftTransactionRepository(db);
      final tx = expense(labelIds: ['home', 'holiday']);
      await repo.save(tx);
      Future<List<TransactionLabelRow>> links() =>
          (db.select(db.transactionLabels)..where((l) => l.transactionId.equals(tx.id))).get();
      final homeLinkId = (await links()).firstWhere((l) => l.labelId == 'home').id;

      await repo.save(tx.copyWith(labelIds: ['holiday', 'work']));
      expect((await repo.getById(tx.id))!.labelIds, unorderedEquals(['holiday', 'work']));
      final home = (await links()).firstWhere((l) => l.labelId == 'home');
      expect(home.deletedAt, isNotNull);

      await repo.save(tx.copyWith(labelIds: ['home', 'holiday', 'work']));
      expect((await repo.getById(tx.id))!.labelIds, unorderedEquals(['home', 'holiday', 'work']));
      final restored = (await links()).where((l) => l.labelId == 'home').toList();
      expect(restored.single.id, homeLinkId);
      expect(restored.single.deletedAt, isNull);
    });

    test('watchInRange filtra per data, esclude i cancellati e ordina dal più recente', () async {
      final repo = DriftTransactionRepository(db);
      final early = expense(date: LocalDate(2026, 10, 1));
      final late = expense(date: LocalDate(2026, 10, 20));
      final deleted = expense(date: LocalDate(2026, 10, 5));
      final outside = expense(date: LocalDate(2026, 11, 1));
      for (final tx in [early, late, deleted, outside]) {
        await repo.save(tx);
      }
      await repo.delete(deleted.id);

      final october = Period.containing(PeriodType.month, LocalDate(2026, 10, 1)).range;
      final found = await repo.watchInRange(october).first;
      expect(found.map((t) => t.id), [late.id, early.id]);
      expect(await repo.getById(deleted.id), isNull);
    });

    test('watch emette di nuovo quando cambiano solo le label', () async {
      final repo = DriftTransactionRepository(db);
      final tx = expense();
      await repo.save(tx);

      final emitted = repo.watchAll().map((list) => list.single.labelIds).take(2).toList();
      await Future<void>.delayed(Duration.zero);
      await repo.save(tx.copyWith(labelIds: ['home']));
      expect(await emitted, [
        <String>[],
        ['home'],
      ]);
    });
  });

  group('label', () {
    test('nome unico tra le label non cancellate, senza distinguere maiuscole e spazi', () async {
      final repo = DriftLabelRepository(db);
      final home = Label(id: newId(), name: 'Casa', color: 0xFF000000);
      await repo.save(home);

      await expectLater(
        repo.save(Label(id: newId(), name: '  casa ', color: 0xFF000000)),
        throwsA(isA<DuplicateLabelNameException>()),
      );
      // Rinominare la stessa label va bene.
      await repo.save(home.copyWith(name: 'CASA'));

      // Dopo la cancellazione il nome torna libero.
      await repo.delete(home.id);
      await repo.save(Label(id: newId(), name: 'Casa', color: 0xFF000000));
      expect((await repo.watchAll().first).map((l) => l.name), ['Casa']);
    });

    test('salva il nome senza spazi ai lati', () async {
      final repo = DriftLabelRepository(db);
      await repo.save(Label(id: newId(), name: '  vacanze  ', color: 0));
      expect((await repo.watchAll().first).single.name, 'vacanze');
    });
  });

  group('impostazioni', () {
    test('legge i valori iniziali e salva solo le chiavi cambiate', () async {
      final repo = DriftSettingsRepository(db);
      final settings = await repo.watch().first;
      final checkingId = (await DriftWalletRepository(db).watchAll().first).first.id;
      expect(settings.defaultExpenseWalletId, checkingId);
      expect(settings.weekStart, 1);
      expect(settings.defaultPeriod, PeriodType.month);

      await repo.save(settings.copyWith(weekStart: 7));
      expect((await repo.watch().first).weekStart, 7);
      expect((await newOutbox()).map((o) => (o.entity, o.op)), [('settings', OutboxOp.upsert)]);
    });

    test('togliere un portafoglio predefinito cancella la chiave', () async {
      final repo = DriftSettingsRepository(db);
      final settings = await repo.watch().first;

      await repo.save(settings.copyWith(defaultIncomeWalletId: null));
      expect((await repo.watch().first).defaultIncomeWalletId, isNull);
      expect((await newOutbox()).single.op, OutboxOp.delete);

      await repo.save(settings);
      expect((await repo.watch().first).defaultIncomeWalletId, settings.defaultIncomeWalletId);
    });
  });
}
