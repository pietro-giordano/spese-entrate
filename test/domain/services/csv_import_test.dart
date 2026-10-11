import 'package:flutter_test/flutter_test.dart';
import 'package:spese_entrate/core/dates.dart';
import 'package:spese_entrate/core/ids.dart';
import 'package:spese_entrate/domain/models/category.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/label.dart';
import 'package:spese_entrate/domain/models/transaction.dart';
import 'package:spese_entrate/domain/models/wallet.dart';
import 'package:spese_entrate/domain/services/csv_export.dart';
import 'package:spese_entrate/domain/services/csv_format.dart';
import 'package:spese_entrate/domain/services/csv_import.dart';

const header = 'data;tipo;importo;valuta;portafoglio;portafoglio_destinazione;categoria;label;nota;id';

final wallets = [
  Wallet(id: 'w-cc', name: 'Conto corrente', type: WalletType.checking, initialBalanceDate: LocalDate(2026, 1, 1)),
  Wallet(id: 'w-cash', name: 'Contanti', type: WalletType.cash, initialBalanceDate: LocalDate(2026, 1, 1)),
];
const categories = [
  Category(id: 'c-food', name: 'Spesa alimentare', kind: CategoryKind.expense, color: 0),
  Category(id: 'c-salary', name: 'Stipendio', kind: CategoryKind.income, color: 0),
  Category(id: 'c-other-exp', name: 'Altro', kind: CategoryKind.expense, color: 0),
  Category(id: 'c-other-inc', name: 'Altro', kind: CategoryKind.income, color: 0),
];
const labels = [Label(id: 'l-home', name: 'casa', color: 0)];

/// Piano di un file con le intestazioni e [lines] (separate da a capo).
ImportPlan plan(List<String> lines, {Set<String> activeIds = const {}, Set<String> deletedIds = const {}}) =>
    planCsvImport(
      [header, ...lines].join('\n'),
      wallets: wallets,
      categories: categories,
      labels: labels,
      activeIds: activeIds,
      deletedIds: deletedIds,
    );

/// Errori della riga 2 (la prima dopo le intestazioni).
List<String> errorsOf(ImportPlan p) => [for (final e in p.errors) e.message];

void main() {
  const groceries = '03/10/2026;spesa;64,20;EUR;Conto corrente;;Spesa alimentare;casa;Esselunga;';

  group('lettura del file', () {
    test('intestazioni esatte; separatore ;, BOM, a capo Windows e righe vuote', () {
      final p = planCsvImport(
        '﻿$header\r\n\r\n$groceries\r\n   \r\n',
        wallets: wallets,
        categories: categories,
        labels: labels,
      );
      expect(p.errors, isEmpty);
      expect(p.rows.single.line, 3, reason: 'le righe vuote contano nella numerazione');
    });

    test('separatore , riconosciuto dalle intestazioni (importi con il punto o tra virgolette)', () {
      final p = planCsvImport(
        '${header.replaceAll(';', ',')}\n2026-10-03,spesa,1234.56,,Contanti,,Spesa alimentare,,,\n'
        '2026-10-04,spesa,"1.234,56",,Contanti,,Spesa alimentare,,,',
        wallets: wallets,
        categories: categories,
        labels: labels,
      );
      expect(p.errors, isEmpty);
      expect(p.rows.map((r) => r.amountCents), [123456, 123456]);
    });

    test('intestazioni diverse o in altro ordine: tutto il file è rifiutato', () {
      final p = planCsvImport(
        'data;tipo;importo;valuta;portafoglio;portafoglio destinazione;categoria;label;nota;id\n$groceries',
        wallets: wallets,
        categories: categories,
        labels: labels,
      );
      expect(p.errors.single.line, 1);
      expect(p.rows, isEmpty);
      expect(
        planCsvImport('', wallets: wallets, categories: categories, labels: labels).errors.single.message,
        'Il file è vuoto',
      );
    });

    test('colonne in più vuote ignorate, colonne mancanti = errore', () {
      expect(plan(['$groceries;;']).errors, isEmpty);
      expect(errorsOf(plan(['03/10/2026;spesa;5,00'])), ['3 colonne invece di 10']);
    });
  });

  group('data', () {
    test('AAAA-MM-GG e GG/MM/AAAA (anche con una cifra)', () {
      final p = plan([
        '2026-10-03;spesa;1;;Contanti;;Spesa alimentare;;;',
        '3/9/2026;spesa;1;;Contanti;;Spesa alimentare;;;',
      ]);
      expect(p.rows.map((r) => r.date), [LocalDate(2026, 10, 3), LocalDate(2026, 9, 3)]);
    });

    test('date non valide o inesistenti', () {
      for (final bad in ['31/02/2026', '2026-13-01', '10-03-2026', 'ieri', '']) {
        final p = plan(['$bad;spesa;1;;Contanti;;Spesa alimentare;;;']);
        expect(p.rows, isEmpty, reason: bad);
        expect(errorsOf(p).single, startsWith('data non valida'), reason: bad);
      }
    });
  });

  group('tipo', () {
    test('quattro tipi senza distinzione tra maiuscole e minuscole', () {
      final p = plan([
        '03/10/2026;SPESA;1;;Contanti;;Spesa alimentare;;;',
        '03/10/2026;Entrata;1;;Contanti;;Stipendio;;;',
        '03/10/2026;Trasferimento;1;;Contanti;Conto corrente;;;;',
        '03/10/2026; rettifica ;-1;;Contanti;;;;;',
      ]);
      expect(p.errors, isEmpty);
      expect(p.rows.map((r) => r.type), TransactionType.values);
    });

    test('tipo sconosciuto', () {
      expect(errorsOf(plan(['03/10/2026;bonifico;1;;Contanti;;;;;'])).single, startsWith('tipo non valido'));
    });
  });

  group('importo', () {
    test('1.234,56 e 1234.56', () {
      final p = plan([
        '03/10/2026;spesa;1.234,56;;Contanti;;Spesa alimentare;;;',
        '03/10/2026;spesa;1234.56;;Contanti;;Spesa alimentare;;;',
        '03/10/2026;spesa;€ 12,5;;Contanti;;Spesa alimentare;;;',
      ]);
      expect(p.rows.map((r) => r.amountCents), [123456, 123456, 1250]);
    });

    test('negativo in spesa o entrata: diventa positivo con un avviso', () {
      final p = plan(['03/10/2026;spesa;-64,20;;Contanti;;Spesa alimentare;;;']);
      expect(p.rows.single.amountCents, 6420);
      expect(p.warnings.single, ImportIssue(2, 'importo negativo reso positivo: il tipo «spesa» dice già il segno'));
    });

    test('la rettifica mantiene il segno', () {
      final p = plan(['03/10/2026;rettifica;-150,00;;Contanti;;;;;', '03/10/2026;rettifica;80;;Contanti;;;;;']);
      expect(p.rows.map((r) => r.amountCents), [-15000, 8000]);
      expect(p.warnings, isEmpty);
    });

    test('zero, vuoto, testo o negativo in un trasferimento: errore', () {
      expect(errorsOf(plan(['03/10/2026;spesa;0,00;;Contanti;;Spesa alimentare;;;'])), ['importo zero']);
      expect(
        errorsOf(plan(['03/10/2026;spesa;;;Contanti;;Spesa alimentare;;;'])).single,
        startsWith('importo non valido'),
      );
      expect(
        errorsOf(plan(['03/10/2026;spesa;dieci;;Contanti;;Spesa alimentare;;;'])).single,
        startsWith('importo non valido'),
      );
      expect(
        errorsOf(plan(['03/10/2026;spesa;1,234;;Contanti;;Spesa alimentare;;;'])).single,
        startsWith('importo non valido'),
      );
      expect(
        errorsOf(plan(['03/10/2026;trasferimento;-5;;Contanti;Conto corrente;;;;'])).single,
        startsWith('importo negativo in un trasferimento'),
      );
    });
  });

  group('valuta', () {
    test('vuota o EUR (anche minuscolo) va bene, le altre no', () {
      expect(
        plan([
          '03/10/2026;spesa;1;;Contanti;;Spesa alimentare;;;',
          '03/10/2026;spesa;1;eur;Contanti;;Spesa alimentare;;;',
        ]).rows,
        hasLength(2),
      );
      expect(errorsOf(plan(['03/10/2026;spesa;1;USD;Contanti;;Spesa alimentare;;;'])), [
        'valuta «USD» non supportata: per ora solo EUR',
      ]);
    });
  });

  group('portafogli', () {
    test('abbinati per nome senza distinzione tra maiuscole, minuscole e spazi', () {
      final row = plan(['03/10/2026;spesa;1;;  conto CORRENTE ;;Spesa alimentare;;;']).rows.single;
      expect(row.wallet, const ImportRef('Conto corrente', 'w-cc'));
    });

    test('portafoglio mancante: errore; sconosciuto: da creare, elencato una volta', () {
      expect(errorsOf(plan(['03/10/2026;spesa;1;;;;Spesa alimentare;;;'])), [
        'portafoglio mancante: scrivilo nel file o scegli un portafoglio per le righe senza',
      ]);
      final p = plan([
        '03/10/2026;spesa;1;;Carta Visa;;Spesa alimentare;;;',
        '03/10/2026;spesa;2;;carta visa;;Spesa alimentare;;;',
      ]);
      expect(p.unknownWallets, ['Carta Visa']);
      expect(p.rows.map((r) => r.wallet), [const ImportRef('Carta Visa'), const ImportRef('Carta Visa')]);
    });

    test('colonna vuota: si usa il portafoglio scelto nelle opzioni', () {
      final p = planCsvImport(
        '$header\n03/10/2026;spesa;1;;;;Spesa alimentare;;;\n03/10/2026;trasferimento;1;;;Contanti;;;;\n'
        '03/10/2026;trasferimento;2;;;Conto corrente;;;;',
        wallets: wallets,
        categories: categories,
        labels: labels,
        fallbackWallet: wallets.first,
      );
      expect(p.rows.first.wallet, const ImportRef('Conto corrente', 'w-cc'));
      expect(p.rows[1].toWallet!.id, 'w-cash');
      expect(p.errors.single, const ImportIssue(4, 'portafoglio e portafoglio_destinazione devono essere diversi'));
    });

    test('trasferimento: destinazione obbligatoria e diversa', () {
      expect(
        errorsOf(plan(['03/10/2026;trasferimento;1;;Contanti;;;;;'])).single,
        startsWith('portafoglio_destinazione mancante'),
      );
      expect(errorsOf(plan(['03/10/2026;trasferimento;1;;Contanti;CONTANTI;;;;'])), [
        'portafoglio e portafoglio_destinazione devono essere diversi',
      ]);
      final row = plan(['03/10/2026;trasferimento;1;;Contanti;Conto corrente;;;;']).rows.single;
      expect(row.toWallet, const ImportRef('Conto corrente', 'w-cc'));
    });

    test('destinazione in una spesa: ignorata con un avviso', () {
      final p = plan(['03/10/2026;spesa;1;;Contanti;Conto corrente;Spesa alimentare;;;']);
      expect(p.rows.single.toWallet, isNull);
      expect(p.warnings.single.message, startsWith('portafoglio_destinazione ignorato'));
    });
  });

  group('categoria', () {
    test('obbligatoria per spesa ed entrata', () {
      expect(
        errorsOf(plan(['03/10/2026;spesa;1;;Contanti;;;;;'])).single,
        'categoria mancante: è obbligatoria per spesa',
      );
      expect(
        errorsOf(plan(['03/10/2026;entrata;1;;Contanti;;;;;'])).single,
        'categoria mancante: è obbligatoria per entrata',
      );
    });

    test('del tipo giusto: con lo stesso nome nei due tipi si sceglie quella giusta', () {
      final p = plan(['03/10/2026;spesa;1;;Contanti;;altro;;;', '03/10/2026;entrata;1;;Contanti;;ALTRO;;;']);
      expect(p.rows.map((r) => r.category!.id), ['c-other-exp', 'c-other-inc']);
    });

    test('esiste solo dell\'altro tipo: errore', () {
      expect(errorsOf(plan(['03/10/2026;spesa;1;;Contanti;;Stipendio;;;'])), [
        'la categoria «Stipendio» è di entrata: qui ne serve una di spesa',
      ]);
    });

    test('sconosciuta: da creare con il tipo della riga', () {
      final p = plan(['03/10/2026;spesa;1;;Contanti;;Palestra;;;', '03/10/2026;entrata;1;;Contanti;;Bonus;;;']);
      expect(p.unknownCategories, [
        (name: 'Palestra', kind: CategoryKind.expense),
        (name: 'Bonus', kind: CategoryKind.income),
      ]);
    });

    test('in un trasferimento o una rettifica: ignorata con un avviso', () {
      final p = plan(['03/10/2026;trasferimento;1;;Contanti;Conto corrente;Spesa alimentare;casa;;']);
      expect(p.rows.single.category, isNull);
      expect(p.rows.single.labels, isEmpty);
      expect(p.warnings.map((w) => w.message), [
        'categoria ignorata: vale solo per spese ed entrate',
        'label ignorate: valgono solo per spese ed entrate',
      ]);
    });
  });

  group('label', () {
    test('separate da |, senza doppioni; le sconosciute verranno create', () {
      final p = plan(['03/10/2026;spesa;1;;Contanti;;Spesa alimentare; Casa |vacanze|| CASA |Vacanze;;']);
      expect(p.rows.single.labels, [const ImportRef('casa', 'l-home'), const ImportRef('vacanze')]);
      expect(p.unknownLabels, ['vacanze']);
    });

    test('i nomi da creare vengono solo dalle righe valide', () {
      final p = plan(['03/10/2026;spesa;0;;Nuovo conto;;Nuova categoria;nuova;;']);
      expect(p.rows, isEmpty);
      expect(p.unknownWallets, isEmpty);
      expect(p.unknownCategories, isEmpty);
      expect(p.unknownLabels, isEmpty);
    });
  });

  group('id', () {
    const existing = '01928f0e-1111-7aaa-8bbb-000000000001';
    const brandNew = '01928f0e-2222-7aaa-8bbb-000000000002';
    const deleted = '01928f0e-3333-7aaa-8bbb-000000000003';

    test('UUID esistente: la riga aggiorna il movimento', () {
      final p = plan(['03/10/2026;spesa;1;;Contanti;;Spesa alimentare;;;$existing'], activeIds: {existing});
      expect(p.rows.single.id, existing);
      expect(p.updates, hasLength(1));
      expect(p.inserts, isEmpty);
    });

    test('UUID nuovo: si usa così com\'è (anche scritto in maiuscolo)', () {
      final p = plan(['03/10/2026;spesa;1;;Contanti;;Spesa alimentare;;;${brandNew.toUpperCase()}']);
      expect(p.rows.single.id, brandNew);
      expect(p.rows.single.updatesExisting, isFalse);
    });

    test('non UUID, ripetuto nel file o di un movimento eliminato: errore', () {
      expect(
        errorsOf(plan(['03/10/2026;spesa;1;;Contanti;;Spesa alimentare;;;123'])).single,
        startsWith('id non valido'),
      );
      expect(errorsOf(plan(['03/10/2026;spesa;1;;Contanti;;Spesa alimentare;;;$deleted'], deletedIds: {deleted})), [
        'l\'id è di un movimento eliminato: non si reimporta',
      ]);
      final p = plan([
        '03/10/2026;spesa;1;;Contanti;;Spesa alimentare;;;$brandNew',
        '04/10/2026;spesa;2;;Contanti;;Spesa alimentare;;;$brandNew',
      ]);
      expect(p.rows, hasLength(1));
      expect(p.errors.single, const ImportIssue(3, 'id ripetuto nel file'));
    });

    test('vuoto: UUID v5 della riga; righe identiche hanno id diversi grazie al contatore', () {
      final p = plan([
        groceries,
        groceries,
        '04/10/2026;spesa;64,20;EUR;Conto corrente;;Spesa alimentare;casa;Esselunga;',
      ]);
      final ids = p.rows.map((r) => r.id).toList();
      expect(ids.toSet(), hasLength(3));
      expect(ids.every(isUuid), isTrue);
      expect(ids[0][14], '5', reason: 'versione 5');
    });

    test('la normalizzazione ignora maiuscole, spazi, formato di data e importo', () {
      final a = plan([groceries]).rows.single.id;
      final b = plan(['2026-10-03; SPESA ;64.20;eur; conto corrente ;;spesa alimentare; CASA ; Esselunga ;'])
          .rows
          .single
          .id;
      expect(b, a);
    });

    test('id calcolato di un movimento eliminato: nuova generazione deterministica, non errore', () {
      final first = plan([groceries]).rows.single.id;
      final regenerated = plan([groceries], deletedIds: {first}).rows.single;
      expect(regenerated.id, isNot(first));
      expect(plan([groceries], deletedIds: {first}).rows.single.id, regenerated.id, reason: 'sempre lo stesso');
      final updated = plan([groceries], deletedIds: {first}, activeIds: {regenerated.id}).rows.single;
      expect(updated.updatesExisting, isTrue);
    });

    test('reimportare lo stesso file non crea duplicati: aggiorna gli stessi movimenti', () {
      final lines = [groceries, groceries, '05/10/2026;entrata;2.400,00;;Conto corrente;;Stipendio;;;'];
      final first = plan(lines);
      expect(first.inserts, hasLength(3));
      final second = plan(lines, activeIds: {for (final r in first.rows) r.id});
      expect(second.rows.map((r) => r.id), first.rows.map((r) => r.id));
      expect(second.inserts, isEmpty);
      expect(second.updates, hasLength(3));
    });
  });

  test('note: spazi tolti, vuota = null', () {
    final p = plan([
      '03/10/2026;spesa;1;;Contanti;;Spesa alimentare;;  pranzo  ;',
      '03/10/2026;spesa;2;;Contanti;;Spesa alimentare;;   ;',
    ]);
    expect(p.rows.map((r) => r.note), ['pranzo', null]);
  });

  test('ogni errore della riga viene riportato, e le altre righe si importano lo stesso', () {
    final p = plan(['ieri;bonifico;;USD;;;;;;', groceries]);
    expect(p.errors.where((e) => e.line == 2).map((e) => e.message), [
      startsWith('data non valida'),
      startsWith('tipo non valido'),
      startsWith('importo non valido'),
      startsWith('valuta'),
      startsWith('portafoglio mancante'),
    ]);
    expect(p.rows.single.line, 3);
  });

  test('un file esportato si reimporta uguale (stesso formato)', () {
    final txs = [
      Transaction(
        id: '01928f0e-4444-7aaa-8bbb-000000000004',
        type: TransactionType.expense,
        amountCents: 123456,
        date: LocalDate(2026, 10, 3),
        walletId: 'w-cc',
        categoryId: 'c-food',
        labelIds: const ['l-home'],
        note: 'Spesa; con "virgolette" e punto e virgola',
      ),
      Transaction(
        id: '01928f0e-5555-7aaa-8bbb-000000000005',
        type: TransactionType.transfer,
        amountCents: 5000,
        date: LocalDate(2026, 10, 4),
        walletId: 'w-cc',
        toWalletId: 'w-cash',
      ),
      Transaction(
        id: '01928f0e-6666-7aaa-8bbb-000000000006',
        type: TransactionType.adjustment,
        amountCents: -900,
        date: LocalDate(2026, 10, 5),
        walletId: 'w-cash',
      ),
    ];
    final csv = transactionsToCsv(
      txs,
      walletNames: {for (final w in wallets) w.id: w.name},
      categoryNames: {for (final c in categories) c.id: c.name},
      labelNames: {for (final l in labels) l.id: l.name},
    );
    final p = planCsvImport(csv, wallets: wallets, categories: categories, labels: labels);
    expect(p.errors, isEmpty);
    expect(p.warnings, isEmpty);
    for (final (row, tx) in [for (var i = 0; i < txs.length; i++) (p.rows[i], txs[i])]) {
      expect(row.id, tx.id);
      expect(row.type, tx.type);
      expect(row.amountCents, tx.amountCents);
      expect(row.date, tx.date);
      expect(row.wallet.id, tx.walletId);
      expect(row.toWallet?.id, tx.toWalletId);
      expect(row.category?.id, tx.categoryId);
      expect(row.labels.map((l) => l.id), tx.labelIds);
      expect(row.note, tx.note);
    }
  });

  group('modello CSV', () {
    test('intestazioni e 3 righe di esempio (spesa con label, entrata, trasferimento), importabili', () {
      final template = csvImportTemplate(today: LocalDate(2026, 10, 3));
      expect(template.startsWith('﻿$header'), isTrue);
      final p = planCsvImport(template, wallets: wallets, categories: categories, labels: labels);
      expect(p.errors, isEmpty);
      expect(p.rows.map((r) => r.type), [TransactionType.expense, TransactionType.income, TransactionType.transfer]);
      expect(p.rows.first.labels.map((l) => l.name), ['casa', 'famiglia']);
      expect(p.rows.last.toWallet!.id, 'w-cash');
      expect(p.unknownLabels, ['famiglia']);
      expect(p.rows.map((r) => r.date), [LocalDate(2026, 10, 1), LocalDate(2026, 10, 2), LocalDate(2026, 10, 3)]);
      expect(csvHeaders.join(';'), header);
    });
  });

  group('file grandi', () {
    String bigFile(int count, {bool withErrors = false}) {
      final buffer = StringBuffer('﻿$header\n');
      for (var i = 0; i < count; i++) {
        final day = (i % 28) + 1;
        final amount = withErrors && i % 100 == 0 ? 'x' : '${i % 500 + 1},${(i % 100).toString().padLeft(2, '0')}';
        final type = i % 3 == 0 ? 'entrata' : 'spesa';
        final category = type == 'entrata' ? 'Stipendio' : 'Spesa alimentare';
        buffer.writeln(
          '$day/${(i % 12) + 1}/2026;$type;$amount;EUR;Conto corrente;;$category;casa|lab${i % 7};riga $i;',
        );
      }
      return buffer.toString();
    }

    test('10.000 righe valide in pochi secondi, con id tutti diversi', () {
      final watch = Stopwatch()..start();
      final p = planCsvImport(bigFile(10000), wallets: wallets, categories: categories, labels: labels);
      watch.stop();
      expect(p.errors, isEmpty);
      expect(p.rows, hasLength(10000));
      expect(p.rows.map((r) => r.id).toSet(), hasLength(10000));
      expect(p.unknownLabels, hasLength(7));
      expect(watch.elapsed, lessThan(const Duration(seconds: 5)), reason: 'tempo: ${watch.elapsed}');
    });

    test('10.000 righe con errori sparsi: righe giuste importate, errori con il numero di riga', () {
      final p = planCsvImport(
        bigFile(10000, withErrors: true),
        wallets: wallets,
        categories: categories,
        labels: labels,
      );
      expect(p.errors, hasLength(100));
      expect(p.rows, hasLength(9900));
      expect(p.errors.first.line, 2);
      expect(p.errors.last.line, 9902);
    });

    test('reimportare 10.000 righe: tutte aggiornamenti, nessun duplicato', () {
      final file = bigFile(10000);
      final first = planCsvImport(file, wallets: wallets, categories: categories, labels: labels);
      final again = planCsvImport(
        file,
        wallets: wallets,
        categories: categories,
        labels: labels,
        activeIds: {for (final r in first.rows) r.id},
      );
      expect(again.updates, hasLength(10000));
      expect(again.inserts, isEmpty);
    });
  });
}
