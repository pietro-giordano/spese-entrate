import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spese_entrate/core/dates.dart';
import 'package:spese_entrate/core/ids.dart';
import 'package:spese_entrate/data/db/app_database.dart';
import 'package:spese_entrate/data/db/seed.dart';
import 'package:spese_entrate/domain/models/enums.dart';

/// Orologio fisso: 10 ottobre 2026, 08:00 UTC.
final fixedNow = DateTime.utc(2026, 10, 10, 8);

AppDatabase memoryDb() => AppDatabase(NativeDatabase.memory(), now: () => fixedNow);

Matcher throwsConstraint(String kind) =>
    throwsA(predicate((e) => e.toString().contains('$kind constraint failed'), '$kind constraint failed'));

TransactionsCompanion tx({
  TransactionType type = TransactionType.expense,
  int amountCents = 1000,
  String? categoryId = 'category',
  String? toWalletId,
  String? recurrenceId,
  LocalDate? occurrenceDate,
}) {
  return TransactionsCompanion.insert(
    id: newId(),
    createdAt: 0,
    updatedAt: 0,
    deviceId: 'device',
    type: type,
    amountCents: amountCents,
    currency: 'EUR',
    date: LocalDate(2026, 10, 10),
    walletId: 'wallet',
    categoryId: Value(categoryId),
    toWalletId: Value(toWalletId),
    recurrenceId: Value(recurrenceId),
    occurrenceDate: Value(occurrenceDate),
  );
}

void main() {
  // Ogni test apre il suo database: Drift altrimenti avvisa delle istanze multiple.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  group('schema', () {
    test('ha tutte le tabelle e gli indici', () async {
      final rows = await db.customSelect("SELECT type, name FROM sqlite_master WHERE name NOT LIKE 'sqlite_%'").get();
      final names = rows.map((r) => r.read<String>('name')).toSet();

      expect(
        names,
        containsAll([
          'wallets',
          'categories',
          'labels',
          'transactions',
          'transaction_labels',
          'attachments',
          'recurrence_rules',
          'recurrence_exceptions',
          'imports',
          'settings',
          'app_meta',
          'outbox',
          'transactions_date',
          'transactions_wallet_id',
          'transactions_category_id',
          'transactions_import_batch_id',
        ]),
      );
      expect(db.schemaVersion, 3);
    });
  });

  group('dati iniziali', () {
    test('crea device_id, portafogli, categorie e impostazioni', () async {
      final deviceId = await db.deviceId();
      expect(deviceId, isNotEmpty);

      final wallets = await (db.select(db.wallets)..orderBy([(t) => OrderingTerm(expression: t.sortOrder)])).get();
      expect(wallets.map((w) => (w.name, w.type)), [
        ('Conto corrente', WalletType.checking),
        ('Contanti', WalletType.cash),
      ]);
      for (final wallet in wallets) {
        expect(wallet.initialBalanceCents, 0);
        expect(wallet.initialBalanceDate, LocalDate(2026, 10, 10));
        expect(wallet.includeInTotal, isTrue);
        expect(wallet.currency, 'EUR');
        expect(wallet.deviceId, deviceId);
        expect(wallet.createdAt, fixedNow.millisecondsSinceEpoch);
      }

      final categories = await db.select(db.categories).get();
      final expense = categories.where((c) => c.kind == CategoryKind.expense).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      final income = categories.where((c) => c.kind == CategoryKind.income).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      expect(expense.map((c) => c.name), initialExpenseCategories.keys);
      expect(income.map((c) => c.name), initialIncomeCategories.keys);

      expect(await db.select(db.labels).get(), isEmpty);

      final settings = {for (final s in await db.select(db.settings).get()) s.key: s.value};
      final checkingId = wallets.first.id;
      expect(settings, {
        SettingKeys.defaultExpenseWalletId: checkingId,
        SettingKeys.defaultIncomeWalletId: checkingId,
        SettingKeys.weekStart: '1',
        SettingKeys.defaultPeriod: 'month',
        SettingKeys.currency: 'EUR',
      });
    });

    test('ogni riga creata ha la sua voce upsert nell\'outbox', () async {
      final outbox = await db.select(db.outbox).get();
      expect(outbox, hasLength(2 + 13 + 5));
      expect(outbox.every((o) => o.op == OutboxOp.upsert), isTrue);

      final walletIds = (await db.select(db.wallets).get()).map((w) => w.id);
      expect(outbox.where((o) => o.entity == 'wallets').map((o) => o.entityId), unorderedEquals(walletIds));
    });

    test('non viene ripetuto alla riapertura del database', () async {
      final dir = await Directory.systemTemp.createTemp('spese_entrate_db_');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/test.sqlite');

      final first = AppDatabase(NativeDatabase(file), now: () => fixedNow);
      final deviceId = await first.deviceId();
      await first.close();

      final second = AppDatabase(NativeDatabase(file), now: () => fixedNow);
      addTearDown(second.close);
      expect(await second.deviceId(), deviceId);
      expect(await second.select(second.wallets).get(), hasLength(2));
      expect(await second.select(second.categories).get(), hasLength(13));
    });
  });

  group('vincoli unici', () {
    test('(recurrence_id, occurrence_date) dei movimenti', () async {
      final date = LocalDate(2026, 10, 1);
      await db.into(db.transactions).insert(tx(recurrenceId: 'rule', occurrenceDate: date));

      await expectLater(
        () => db.into(db.transactions).insert(tx(recurrenceId: 'rule', occurrenceDate: date)),
        throwsConstraint('UNIQUE'),
      );

      // Come farà il generatore delle ricorrenze: insert che ignora i conflitti.
      await db
          .into(db.transactions)
          .insert(
            tx(recurrenceId: 'rule', occurrenceDate: date),
            mode: InsertMode.insertOrIgnore,
          );
      await db.into(db.transactions).insert(tx(recurrenceId: 'rule', occurrenceDate: date.addDays(1)));
      expect(await db.select(db.transactions).get(), hasLength(2));
    });

    test('i movimenti non ricorrenti (NULL) non entrano in conflitto', () async {
      await db.into(db.transactions).insert(tx());
      await db.into(db.transactions).insert(tx());
      expect(await db.select(db.transactions).get(), hasLength(2));
    });

    test('(transaction_id, label_id)', () async {
      TransactionLabelsCompanion link() => TransactionLabelsCompanion.insert(
        id: newId(),
        createdAt: 0,
        updatedAt: 0,
        deviceId: 'device',
        transactionId: 'tx',
        labelId: 'label',
      );
      await db.into(db.transactionLabels).insert(link());
      await expectLater(() => db.into(db.transactionLabels).insert(link()), throwsConstraint('UNIQUE'));
    });

    test('(rule_id, occurrence_date) delle eccezioni', () async {
      RecurrenceExceptionsCompanion skip() => RecurrenceExceptionsCompanion.insert(
        id: newId(),
        createdAt: 0,
        updatedAt: 0,
        deviceId: 'device',
        ruleId: 'rule',
        occurrenceDate: LocalDate(2026, 11, 1),
        kind: RecurrenceExceptionKind.skip,
      );
      await db.into(db.recurrenceExceptions).insert(skip());
      await expectLater(() => db.into(db.recurrenceExceptions).insert(skip()), throwsConstraint('UNIQUE'));
    });

    test('key delle impostazioni', () async {
      await expectLater(
        () => db
            .into(db.settings)
            .insert(
              SettingsCompanion.insert(
                id: newId(),
                createdAt: 0,
                updatedAt: 0,
                deviceId: 'device',
                key: SettingKeys.weekStart,
                value: '7',
              ),
            ),
        throwsConstraint('UNIQUE'),
      );
    });

    test('id come chiave primaria', () async {
      final row = tx();
      await db.into(db.transactions).insert(row);
      await expectLater(() => db.into(db.transactions).insert(row), throwsConstraint('UNIQUE'));
    });
  });

  group('vincoli sui movimenti', () {
    test('importo > 0, tranne le rettifiche', () async {
      await expectLater(() => db.into(db.transactions).insert(tx(amountCents: 0)), throwsConstraint('CHECK'));
      await expectLater(() => db.into(db.transactions).insert(tx(amountCents: -500)), throwsConstraint('CHECK'));
      await db.into(db.transactions).insert(tx(type: TransactionType.adjustment, amountCents: -500, categoryId: null));
    });

    test('categoria obbligatoria per spese ed entrate', () async {
      await expectLater(() => db.into(db.transactions).insert(tx(categoryId: null)), throwsConstraint('CHECK'));
      await expectLater(
        () => db.into(db.transactions).insert(tx(type: TransactionType.income, categoryId: null)),
        throwsConstraint('CHECK'),
      );
    });

    test('portafoglio di destinazione solo e sempre per i trasferimenti', () async {
      await expectLater(
        () => db.into(db.transactions).insert(tx(type: TransactionType.transfer, categoryId: null)),
        throwsConstraint('CHECK'),
      );
      await expectLater(() => db.into(db.transactions).insert(tx(toWalletId: 'other')), throwsConstraint('CHECK'));
      await db.into(db.transactions).insert(tx(type: TransactionType.transfer, categoryId: null, toWalletId: 'other'));
    });
  });

  group('cancellazione logica', () {
    test('imposta deleted_at, tiene la riga e accoda un delete nell\'outbox', () async {
      final wallet = (await db.select(db.wallets).get()).first;
      final outboxBefore = (await db.select(db.outbox).get()).length;

      expect(await db.softDelete(db.wallets, wallet.id), isTrue);

      final stored = await (db.select(db.wallets)..where((t) => t.id.equals(wallet.id))).getSingle();
      expect(stored.deletedAt, fixedNow.millisecondsSinceEpoch);
      expect(stored.updatedAt, fixedNow.millisecondsSinceEpoch);

      final outbox = await db.select(db.outbox).get();
      expect(outbox, hasLength(outboxBefore + 1));
      expect((outbox.last.entity, outbox.last.entityId, outbox.last.op), ('wallets', wallet.id, OutboxOp.delete));
    });

    test('whereNotDeleted esclude i cancellati', () async {
      final wallets = await db.select(db.wallets).get();
      await db.softDelete(db.wallets, wallets.first.id);

      final active = await (db.select(db.wallets)..whereNotDeleted()).get();
      expect(active.map((w) => w.id), [wallets.last.id]);
      expect(await db.select(db.wallets).get(), hasLength(2));
    });

    test('non fa nulla su record inesistenti o già cancellati', () async {
      final wallet = (await db.select(db.wallets).get()).first;
      await db.softDelete(db.wallets, wallet.id);
      final outboxCount = (await db.select(db.outbox).get()).length;

      expect(await db.softDelete(db.wallets, wallet.id), isFalse);
      expect(await db.softDelete(db.wallets, 'inesistente'), isFalse);
      expect(await db.select(db.outbox).get(), hasLength(outboxCount));
    });

    test('rifiuta le tabelle non sincronizzabili', () {
      expect(() => db.softDelete(db.appMeta, 'device_id'), throwsArgumentError);
    });
  });
}
