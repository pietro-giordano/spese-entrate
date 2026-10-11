import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spese_entrate/core/dates.dart';
import 'package:spese_entrate/core/ids.dart';
import 'package:spese_entrate/data/db/app_database.dart';
import 'package:spese_entrate/data/repositories/drift_category_repository.dart';
import 'package:spese_entrate/data/repositories/drift_import_repository.dart';
import 'package:spese_entrate/data/repositories/drift_label_repository.dart';
import 'package:spese_entrate/data/repositories/drift_transaction_repository.dart';
import 'package:spese_entrate/data/repositories/drift_wallet_repository.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/transaction.dart';
import 'package:spese_entrate/domain/services/csv_import.dart';
import 'package:spese_entrate/domain/services/import_operations.dart';

const header = 'data;tipo;importo;valuta;portafoglio;portafoglio_destinazione;categoria;label;nota;id';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late DriftImportRepository imports;
  late DriftTransactionRepository transactions;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory(), now: () => DateTime.utc(2026, 10, 3, 8));
    imports = DriftImportRepository(db);
    transactions = DriftTransactionRepository(db);
  });
  tearDown(() => db.close());

  /// Piano + operazioni + esecuzione, come farà il flusso dell'app.
  Future<({ImportPlan plan, ImportOperations ops, String id})> runImport(
    List<String> lines, {
    ImportChoices choices = const ImportChoices(),
    String fileName = 'banca.csv',
    void Function(int, int)? onProgress,
    int chunkSize = 250,
  }) async {
    final wallets = await DriftWalletRepository(db).watchAll().first;
    final categories = await DriftCategoryRepository(db).watchAll().first;
    final labels = await DriftLabelRepository(db).watchAll().first;
    final ids = await imports.transactionIds();
    final plan = planCsvImport(
      [header, ...lines].join('\n'),
      wallets: wallets,
      categories: categories,
      labels: labels,
      activeIds: ids.active,
      deletedIds: ids.deleted,
    );
    final id = newId();
    final ops = buildImportOperations(
      plan: plan,
      choices: choices,
      batchId: id,
      wallets: wallets,
      categories: categories,
      labels: labels,
      existing: await imports.transactionsByIds({for (final r in plan.updates) r.id}),
      today: LocalDate(2026, 10, 3),
      newId: newId,
    );
    await imports.execute(
      id: id,
      fileName: fileName,
      rowCount: plan.rows.length + plan.errors.where((e) => e.line > 1).map((e) => e.line).toSet().length,
      operations: ops,
      onProgress: onProgress,
      chunkSize: chunkSize,
    );
    return (plan: plan, ops: ops, id: id);
  }

  Future<List<Transaction>> active() => transactions.getAll();

  test('crea portafogli, categorie e label sconosciuti; i movimenti nuovi hanno l\'import', () async {
    final result = await runImport([
      '03/10/2026;spesa;64,20;;Carta Visa;;Palestra;sport|casa;Abbonamento;',
      '02/10/2026;entrata;2.400,00;;Conto corrente;;Stipendio;;;',
      'data sbagliata;spesa;1;;Contanti;;Casa;;;',
    ]);
    expect(result.ops.newWallets.single.name, 'Carta Visa');
    expect(result.ops.newWallets.single.type, WalletType.other);
    expect(result.ops.newCategories.single.name, 'Palestra');
    expect(result.ops.newLabels.map((l) => l.name), ['sport', 'casa']);

    final txs = await active();
    expect(txs, hasLength(2), reason: 'la riga con errori è saltata');
    expect(txs.every((t) => t.importBatchId == result.id), isTrue);
    final gym = txs.firstWhere((t) => t.note == 'Abbonamento');
    expect(gym.walletId, result.ops.newWallets.single.id);
    expect(gym.labelIds, hasLength(2));

    final record = (await imports.watchAll().first).single;
    expect(
      (record.fileName, record.rowCount, record.insertedCount, record.updatedCount, record.skippedCount),
      ('banca.csv', 3, 2, 0, 1),
    );
  });

  test('abbinamenti: portafoglio e categoria sconosciuti finiscono su quelli esistenti', () async {
    final cash = (await DriftWalletRepository(db).watchAll().first).firstWhere((w) => w.name == 'Contanti');
    final home = (await DriftCategoryRepository(db).watchAll().first).firstWhere((c) => c.name == 'Casa');
    final result = await runImport(
      ['03/10/2026;spesa;10;;Borsellino;;Affitto;;;'],
      choices: ImportChoices(
        walletMatches: {'Borsellino': cash.id},
        categoryMatches: {(name: 'Affitto', kind: CategoryKind.expense): home.id},
      ),
    );
    expect(result.ops.newWallets, isEmpty);
    expect(result.ops.newCategories, isEmpty);
    final tx = (await active()).single;
    expect((tx.walletId, tx.categoryId), (cash.id, home.id));
  });

  test('label aggiuntiva su spese ed entrate (non sui trasferimenti), creata se non esiste', () async {
    final result = await runImport([
      '03/10/2026;spesa;10;;Contanti;;Casa;;;',
      '03/10/2026;trasferimento;20;;Conto corrente;Contanti;;;;',
    ], choices: const ImportChoices(extraLabel: ' Importato '));
    final label = result.ops.newLabels.single;
    expect(label.name, 'Importato');
    final txs = await active();
    expect(txs.firstWhere((t) => t.type == TransactionType.expense).labelIds, [label.id]);
    expect(txs.firstWhere((t) => t.type == TransactionType.transfer).labelIds, isEmpty);
  });

  test('una riga con id esistente aggiorna il movimento, senza cambiarne stato, ricorrenza e import', () async {
    final walletId = (await db.select(db.wallets).get()).first.id;
    final categoryId = (await db.select(db.categories).get()).first.id;
    const id = '01928f0e-1111-7aaa-8bbb-000000000001';
    await transactions.save(
      Transaction(
        id: id,
        type: TransactionType.expense,
        status: TransactionStatus.pending,
        amountCents: 100,
        date: LocalDate(2026, 9, 1),
        walletId: walletId,
        categoryId: categoryId,
        recurrenceId: 'r1',
        occurrenceDate: LocalDate(2026, 9, 1),
      ),
    );
    final result = await runImport(['03/10/2026;spesa;99,00;;Conto corrente;;Casa;;nuova nota;$id']);
    expect(result.ops.updates, hasLength(1));
    final updated = (await transactions.getById(id))!;
    expect(updated.amountCents, 9900);
    expect(updated.note, 'nuova nota');
    expect(updated.status, TransactionStatus.pending);
    expect(updated.recurrenceId, 'r1');
    expect(updated.importBatchId, isNull, reason: 'annullare l\'import non deve cancellarlo');
    expect((await imports.watchAll().first).single.updatedCount, 1);
  });

  test('avanzamento a blocchi', () async {
    final progress = <(int, int)>[];
    await runImport(
      [for (var i = 0; i < 7; i++) '0${i + 1}/10/2026;spesa;${i + 1};;Contanti;;Casa;;;'],
      chunkSize: 3,
      onProgress: (done, total) => progress.add((done, total)),
    );
    expect(progress, [(0, 7), (3, 7), (6, 7), (7, 7)]);
  });

  test('errore a metà: rollback completo, nessun movimento, nessuna creazione, niente storico', () async {
    Future<Map<String, int>> counts() async => {
      for (final t in ['transactions', 'wallets', 'categories', 'labels', 'imports', 'outbox', 'transaction_labels'])
        t: (await db.customSelect('SELECT COUNT(*) AS c FROM $t').getSingle()).read<int>('c'),
    };
    final before = await counts();
    await db.customStatement(
      "CREATE TRIGGER errore_simulato BEFORE INSERT ON transactions WHEN NEW.note = 'boom' "
      "BEGIN SELECT RAISE(ABORT, 'errore simulato'); END;",
    );
    await expectLater(
      runImport([
        '01/10/2026;spesa;1;;Nuovo conto;;Nuova categoria;nuova;;',
        '02/10/2026;spesa;2;;Contanti;;Casa;;boom;',
      ], chunkSize: 1),
      throwsA(isA<SqliteException>()),
    );
    expect(await counts(), before);
  });

  group('annulla importazione', () {
    test('cancella logicamente solo i movimenti creati, non quelli aggiornati', () async {
      final walletId = (await db.select(db.wallets).get()).first.id;
      final categoryId = (await db.select(db.categories).get()).first.id;
      const existingId = '01928f0e-2222-7aaa-8bbb-000000000002';
      await transactions.save(
        Transaction(
          id: existingId,
          type: TransactionType.expense,
          amountCents: 100,
          date: LocalDate(2026, 9, 1),
          walletId: walletId,
          categoryId: categoryId,
        ),
      );
      final result = await runImport([
        '03/10/2026;spesa;5;;Contanti;;Casa;;;',
        '04/10/2026;spesa;6;;Contanti;;Casa;;;',
        '05/10/2026;spesa;7;;Contanti;;Casa;;;$existingId',
      ]);

      expect(await imports.undo(result.id), 2);
      final remaining = await active();
      expect(remaining.single.id, existingId);
      expect(remaining.single.amountCents, 700, reason: 'l\'aggiornamento resta');
      final record = (await imports.watchAll().first).single;
      expect(record.isUndone, isTrue);
      expect(await imports.undo(result.id), 0, reason: 'una seconda volta non fa nulla');

      final outbox = await (db.select(db.outbox)..where((o) => o.entity.equals('transactions'))).get();
      expect(outbox.where((o) => o.op == OutboxOp.delete), hasLength(2));
    });

    test('dopo l\'annullamento si può reimportare: righe nuove, le cancellate restano cancellate', () async {
      final lines = ['03/10/2026;spesa;5;;Contanti;;Casa;;;'];
      final first = await runImport(lines);
      final firstId = (await active()).single.id;
      await imports.undo(first.id);

      final second = await runImport(lines);
      expect(second.ops.inserts, hasLength(1));
      final again = (await active()).single;
      expect(again.id, isNot(firstId), reason: 'la lapide non torna in vita');
      final tombstone = await (db.select(db.transactions)..where((t) => t.id.equals(firstId))).getSingle();
      expect(tombstone.deletedAt, isNotNull);

      // Un terzo import dello stesso file aggiorna quella riga: nessun duplicato.
      final third = await runImport(lines);
      expect(third.ops.inserts, isEmpty);
      expect(third.ops.updates.single.id, again.id);
      expect(await active(), hasLength(1));
    });
  });

  test('reimportare lo stesso file aggiorna invece di duplicare', () async {
    final lines = ['03/10/2026;spesa;5;;Contanti;;Casa;;;', '03/10/2026;spesa;5;;Contanti;;Casa;;;'];
    await runImport(lines);
    final second = await runImport(lines);
    expect(second.ops.inserts, isEmpty);
    expect(second.ops.updates, hasLength(2));
    expect(await active(), hasLength(2));
  });

  test('un trasferimento che con gli abbinamenti avrebbe stesso portafoglio è scartato', () async {
    final cash = (await DriftWalletRepository(db).watchAll().first).firstWhere((w) => w.name == 'Contanti');
    final result = await runImport([
      '03/10/2026;trasferimento;5;;Borsellino;Contanti;;;;',
      '03/10/2026;spesa;5;;Contanti;;Casa;;;',
    ], choices: ImportChoices(walletMatches: {'Borsellino': cash.id}));
    expect(result.ops.skipped.single.line, 2);
    expect(await active(), hasLength(1));
  });
}
