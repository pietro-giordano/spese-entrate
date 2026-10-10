import 'dart:convert';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spese_entrate/core/clock.dart';
import 'package:spese_entrate/core/dates.dart';
import 'package:spese_entrate/core/ids.dart';
import 'package:spese_entrate/core/money.dart';
import 'package:spese_entrate/data/db/app_database.dart';
import 'package:spese_entrate/data/db/database_provider.dart';
import 'package:spese_entrate/data/device/biometric_auth.dart';
import 'package:spese_entrate/data/repositories/repository_providers.dart';
import 'package:spese_entrate/domain/models/category.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/label.dart';
import 'package:spese_entrate/domain/models/local_preferences.dart';
import 'package:spese_entrate/domain/models/transaction.dart';
import 'package:spese_entrate/domain/services/csv_export.dart';
import 'package:spese_entrate/features/settings/application/app_lock.dart';
import 'package:spese_entrate/features/settings/application/settings_providers.dart';

/// Biometria finta: [available] e [succeeds] decidono le risposte.
class FakeBiometricAuth extends BiometricAuth {
  FakeBiometricAuth({this.available = true, this.succeeds = true});

  bool available;
  bool succeeds;
  var calls = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async {
    calls++;
    return succeeds;
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late ProviderContainer container;
  var now = DateTime.utc(2026, 10, 3, 8);
  late FakeBiometricAuth biometric;

  setUp(() {
    now = DateTime.utc(2026, 10, 3, 8);
    biometric = FakeBiometricAuth();
    db = AppDatabase(NativeDatabase.memory(), now: () => now);
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => now),
        biometricAuthProvider.overrideWithValue(biometric),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
  });

  Future<int> outboxCount() async => (await db.select(db.outbox).get()).length;

  group('preferenze locali (app_meta)', () {
    test('salva e rilegge, senza scrivere nell\'outbox', () async {
      final repository = container.read(localPreferencesRepositoryProvider);
      expect(await repository.get(), const LocalPreferences());
      final before = await outboxCount();

      await repository.save(
        const LocalPreferences(
          themeMode: AppThemeMode.dark,
          biometricLock: true,
          profileName: ' Pietro ',
          profileEmail: 'p@example.com',
        ),
      );
      expect(
        await repository.get(),
        const LocalPreferences(
          themeMode: AppThemeMode.dark,
          biometricLock: true,
          profileName: 'Pietro',
          profileEmail: 'p@example.com',
        ),
      );
      expect(await outboxCount(), before, reason: 'app_meta è solo locale');
    });

    test('un campo svuotato viene tolto; il device_id resta', () async {
      final repository = container.read(localPreferencesRepositoryProvider);
      await repository.save(const LocalPreferences(profileName: 'Pietro'));
      await repository.save(const LocalPreferences(profileName: '   '));
      expect((await repository.get()).profileName, isNull);
      expect(await db.deviceId(), isNotEmpty);
    });
  });

  group('categorie', () {
    Future<List<Category>> expenses() async => (await container.read(categoryRepositoryProvider).watchAll().first)
        .where((c) => c.kind == CategoryKind.expense)
        .toList();

    test('riordino: scrive solo le categorie che cambiano posizione', () async {
      final list = await expenses();
      final before = await outboxCount();
      final reordered = [list[2], list[0], list[1], ...list.skip(3)];
      await container.read(categoryRepositoryProvider).reorder([for (final c in reordered) c.id]);

      expect((await expenses()).map((c) => c.id), [for (final c in reordered) c.id]);
      expect(await outboxCount(), before + 3, reason: 'solo le prime tre cambiano');
    });

    test('unione: movimenti e ricorrenze passano alla destinazione, la sorgente sparisce', () async {
      final list = await expenses();
      final [from, into, ...] = list;
      final wallet = (await container.read(walletRepositoryProvider).watchAll().first).first;
      final tx = Transaction(
        id: newId(),
        type: TransactionType.expense,
        amountCents: 100,
        date: LocalDate(2026, 10, 1),
        walletId: wallet.id,
        categoryId: from.id,
      );
      await container.read(transactionRepositoryProvider).save(tx);
      await db
          .into(db.recurrenceRules)
          .insert(
            RecurrenceRulesCompanion.insert(
              id: 'rule',
              createdAt: 0,
              updatedAt: 0,
              deviceId: 'd',
              name: 'Spesa',
              type: TransactionType.expense,
              amountCents: 100,
              currency: 'EUR',
              walletId: wallet.id,
              categoryId: Value(from.id),
              labelIds: const [],
              frequency: RecurrenceFrequency.monthly,
              startDate: LocalDate(2026, 1, 1),
              mode: RecurrenceMode.auto,
            ),
          );

      await container.read(categoryRepositoryProvider).merge(fromId: from.id, intoId: into.id);

      expect((await container.read(transactionRepositoryProvider).getById(tx.id))!.categoryId, into.id);
      final rule = await (db.select(db.recurrenceRules)..where((r) => r.id.equals('rule'))).getSingle();
      expect(rule.categoryId, into.id);
      expect((await expenses()).map((c) => c.id), isNot(contains(from.id)));
    });
  });

  group('label', () {
    late String txA;
    late String txB;
    late Label home;
    late Label house;

    setUp(() async {
      final wallet = (await container.read(walletRepositoryProvider).watchAll().first).first;
      final category = (await container.read(categoryRepositoryProvider).watchAll().first).first;
      home = Label(id: newId(), name: 'casa', color: 0);
      house = Label(id: newId(), name: 'abitazione', color: 0);
      await container.read(labelRepositoryProvider).save(home);
      await container.read(labelRepositoryProvider).save(house);
      Transaction t(List<String> labels) => Transaction(
        id: newId(),
        type: TransactionType.expense,
        amountCents: 100,
        date: LocalDate(2026, 10, 1),
        walletId: wallet.id,
        categoryId: category.id,
        labelIds: labels,
      );
      final a = t([home.id]);
      final b = t([home.id, house.id]);
      txA = a.id;
      txB = b.id;
      await container.read(transactionRepositoryProvider).save(a);
      await container.read(transactionRepositoryProvider).save(b);
    });

    Future<List<String>> labelsOf(String id) async =>
        (await container.read(transactionRepositoryProvider).getById(id))!.labelIds;

    test('unione senza doppioni: chi aveva già la destinazione la tiene una volta', () async {
      await container.read(labelRepositoryProvider).merge(fromId: home.id, intoId: house.id);
      expect(await labelsOf(txA), [house.id]);
      expect(await labelsOf(txB), [house.id]);
      expect((await container.read(labelRepositoryProvider).watchAll().first).map((l) => l.id), [house.id]);
    });

    test('unione: un collegamento cancellato in passato si ripristina invece di essere ricreato', () async {
      // txA aveva avuto "abitazione" e poi l'aveva persa.
      await container
          .read(transactionRepositoryProvider)
          .save(
            (await container.read(transactionRepositoryProvider).getById(txA))!.copyWith(labelIds: [home.id, house.id]),
          );
      await container
          .read(transactionRepositoryProvider)
          .save((await container.read(transactionRepositoryProvider).getById(txA))!.copyWith(labelIds: [home.id]));
      await container.read(labelRepositoryProvider).merge(fromId: home.id, intoId: house.id);
      expect(await labelsOf(txA), [house.id]);
    });

    test('eliminare una label la toglie anche dai movimenti', () async {
      await container.read(labelRepositoryProvider).delete(home.id);
      expect(await labelsOf(txA), isEmpty);
      expect(await labelsOf(txB), [house.id]);
    });
  });

  group('CSV', () {
    test('separatore ;, BOM, importi con la virgola, label con |, ordine cronologico', () {
      final csv = transactionsToCsv(
        [
          Transaction(
            id: 'b',
            type: TransactionType.transfer,
            amountCents: 50000,
            date: LocalDate(2026, 10, 2),
            walletId: 'cc',
            toWalletId: 'cash',
          ),
          Transaction(
            id: 'a',
            type: TransactionType.expense,
            amountCents: 123456,
            date: LocalDate(2026, 10, 1),
            walletId: 'cc',
            categoryId: 'food',
            labelIds: ['home', 'work'],
            note: 'Spesa; "grande"',
          ),
          Transaction(
            id: 'c',
            type: TransactionType.adjustment,
            amountCents: -1550,
            date: LocalDate(2026, 10, 3),
            walletId: 'cash',
          ),
        ],
        walletNames: {'cc': 'Conto corrente', 'cash': 'Contanti'},
        categoryNames: {'food': 'Spesa alimentare'},
        labelNames: {'home': 'casa', 'work': 'lavoro'},
      );

      expect(csv.startsWith('﻿'), isTrue, reason: 'BOM per Excel');
      final lines = csv.substring(1).split('\r\n');
      expect(lines[0], 'data;tipo;importo;valuta;portafoglio;portafoglio destinazione;categoria;label;nota;id');
      expect(
        lines[1],
        '01/10/2026;spesa;1234,56;EUR;Conto corrente;;Spesa alimentare;casa|lavoro;"Spesa; ""grande""";a',
      );
      expect(lines[2], '02/10/2026;trasferimento;500,00;EUR;Conto corrente;Contanti;;;;b');
      expect(lines[3], '03/10/2026;rettifica;-15,50;EUR;Contanti;;;;;c');
      expect(utf8.encode(csv).take(3), [0xEF, 0xBB, 0xBF]);
    });

    test('formatCentsForSpreadsheet', () {
      expect(formatCentsForSpreadsheet(123456), '1234,56');
      expect(formatCentsForSpreadsheet(5), '0,05');
      expect(formatCentsForSpreadsheet(-1550), '-15,50');
    });
  });

  group('blocco con biometria', () {
    Future<void> enableLock() async {
      await container.read(localPreferencesRepositoryProvider).save(const LocalPreferences(biometricLock: true));
      container.listen(localPreferencesProvider, (_, _) {});
      await container.read(localPreferencesProvider.future);
    }

    test('bloccata all\'apertura se attivo, libera se disattivo', () async {
      expect(container.read(appLockProvider), isFalse);
      container.invalidate(appLockProvider);
      await enableLock();
      expect(container.read(appLockProvider), isTrue);
    });

    test('si blocca solo dopo almeno 1 minuto in background', () async {
      await enableLock();
      final lock = container.read(appLockProvider.notifier);
      await lock.unlock();
      expect(container.read(appLockProvider), isFalse);

      lock.wentToBackground();
      now = now.add(const Duration(seconds: 59));
      lock.cameToForeground();
      expect(container.read(appLockProvider), isFalse);

      lock.wentToBackground();
      now = now.add(const Duration(seconds: 30));
      lock.wentToBackground(); // un secondo evento non sposta l'inizio
      now = now.add(const Duration(seconds: 30));
      lock.cameToForeground();
      expect(container.read(appLockProvider), isTrue);
    });

    test('se la biometria fallisce resta bloccata', () async {
      await enableLock();
      biometric.succeeds = false;
      expect(await container.read(appLockProvider.notifier).unlock(), isFalse);
      expect(container.read(appLockProvider), isTrue);
    });

    test('con il blocco disattivo non si blocca mai', () async {
      final lock = container.read(appLockProvider.notifier);
      lock.wentToBackground();
      now = now.add(const Duration(hours: 1));
      lock.cameToForeground();
      expect(container.read(appLockProvider), isFalse);
    });
  });
}
