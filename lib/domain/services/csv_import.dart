/// Import dei movimenti da CSV: logica pura che legge il file e prepara un piano, senza scrivere
/// nulla. Il formato è quello dell'export (vedi `csv_format.dart`).
library;

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

import '../../core/dates.dart';
import '../../core/ids.dart';
import '../../core/money.dart';
import '../models/category.dart';
import '../models/enums.dart';
import '../models/label.dart';
import '../models/wallet.dart';
import 'csv_format.dart';

/// Un errore o un avviso su una riga del file. La riga 1 è quella delle intestazioni.
class ImportIssue {
  const ImportIssue(this.line, this.message);

  final int line;
  final String message;

  @override
  bool operator ==(Object other) => other is ImportIssue && other.line == line && other.message == message;

  @override
  int get hashCode => Object.hash(line, message);

  @override
  String toString() => 'Riga $line: $message';
}

/// Portafoglio, categoria o label di una riga: [id] se esiste già, altrimenti null e va creato
/// con [name] (il nome come scritto la prima volta nel file).
class ImportRef {
  const ImportRef(this.name, [this.id]);

  final String name;
  final String? id;

  bool get exists => id != null;

  @override
  bool operator ==(Object other) => other is ImportRef && other.name == name && other.id == id;

  @override
  int get hashCode => Object.hash(name, id);

  @override
  String toString() => id == null ? 'nuovo «$name»' : '«$name» ($id)';
}

/// Una categoria da creare, con il suo tipo.
typedef UnknownCategory = ({String name, CategoryKind kind});

/// Una riga valida, pronta da salvare.
class ImportedRow {
  const ImportedRow({
    required this.line,
    required this.id,
    required this.type,
    required this.amountCents,
    required this.date,
    required this.wallet,
    this.toWallet,
    this.category,
    this.labels = const [],
    this.note,
    required this.updatesExisting,
  });

  /// Riga del file (per i messaggi).
  final int line;

  /// ID del movimento: quello del file, oppure un UUID v5 calcolato dalla riga.
  final String id;
  final TransactionType type;

  /// Positivo, tranne le rettifiche che hanno segno.
  final int amountCents;
  final LocalDate date;
  final ImportRef wallet;

  /// Solo per i trasferimenti.
  final ImportRef? toWallet;

  /// Solo per spese ed entrate.
  final ImportRef? category;

  /// Solo per spese ed entrate.
  final List<ImportRef> labels;
  final String? note;

  /// True se l'id è di un movimento esistente: la riga lo aggiorna invece di crearne uno.
  final bool updatesExisting;
}

/// Risultato della lettura: cosa si importerebbe e cosa non va. Non scrive nulla.
class ImportPlan {
  const ImportPlan({
    required this.rows,
    required this.errors,
    required this.warnings,
    required this.unknownWallets,
    required this.unknownCategories,
    required this.unknownLabels,
  });

  /// Righe valide. Le righe con errori non ci sono.
  final List<ImportedRow> rows;

  /// Righe scartate, con il motivo. Un errore sulla riga 1 (intestazioni) blocca tutto il file.
  final List<ImportIssue> errors;

  /// Righe importate con una correzione o un dato ignorato.
  final List<ImportIssue> warnings;

  /// Nomi da creare, nell'ordine in cui compaiono nel file.
  final List<String> unknownWallets;
  final List<UnknownCategory> unknownCategories;
  final List<String> unknownLabels;

  /// Righe che aggiornano movimenti esistenti.
  List<ImportedRow> get updates => [
    for (final row in rows)
      if (row.updatesExisting) row,
  ];

  /// Righe che creano movimenti nuovi.
  List<ImportedRow> get inserts => [
    for (final row in rows)
      if (!row.updatesExisting) row,
  ];

  bool get hasErrors => errors.isNotEmpty;

  /// Errore sulle intestazioni (o file vuoto): non si può importare nulla.
  bool get isUnreadable => errors.any((e) => e.line == 1);

  /// Righe di dati lette: valide più quelle scartate per errori.
  int get readRowCount =>
      rows.length +
      {
        for (final e in errors)
          if (e.line > 1) e.line,
      }.length;

  /// Righe con almeno un errore (saltate).
  int get skippedRowCount => {
    for (final e in errors)
      if (e.line > 1) e.line,
  }.length;
}

/// Legge [content] (UTF-8, con o senza BOM; separatore `;` o `,` riconosciuto dalle intestazioni)
/// e prepara il piano di importazione.
///
/// Portafogli, categorie e label si abbinano per nome senza distinzione tra maiuscole e minuscole
/// (le categorie anche per tipo: spesa → categorie di spesa, entrata → categorie di entrata);
/// quelli che non esistono finiscono negli elenchi "da creare". [activeIds] sono gli id dei
/// movimenti esistenti (una riga con uno di questi id lo aggiorna); [deletedIds] quelli cancellati,
/// che non si reimportano (lapide definitiva). [fallbackWallet] è il portafoglio delle righe con la
/// colonna `portafoglio` vuota; senza, quelle righe sono errori.
ImportPlan planCsvImport(
  String content, {
  required List<Wallet> wallets,
  required List<Category> categories,
  required List<Label> labels,
  Set<String> activeIds = const {},
  Set<String> deletedIds = const {},
  Wallet? fallbackWallet,
}) {
  return _Planner(
    wallets: wallets,
    categories: categories,
    labels: labels,
    activeIds: activeIds,
    deletedIds: deletedIds,
    fallbackWallet: fallbackWallet,
  ).plan(content);
}

/// Modello CSV da compilare: intestazioni e tre righe di esempio (spesa con label, entrata,
/// trasferimento), con date vicine a [today]. Stesso formato dell'export (`;`, BOM, virgola decimale).
String csvImportTemplate({required LocalDate today}) {
  String date(LocalDate d) => DateFormat('dd/MM/yyyy').format(d.toDateTime());
  final rows = <List<String>>[
    csvHeaders,
    [
      date(today.addDays(-2)),
      csvTypeLabel(TransactionType.expense),
      formatCentsForSpreadsheet(6420),
      defaultCurrency,
      'Conto corrente',
      '',
      'Spesa alimentare',
      ['casa', 'famiglia'].join(csvLabelSeparator),
      'Supermercato',
      '',
    ],
    [
      date(today.addDays(-1)),
      csvTypeLabel(TransactionType.income),
      formatCentsForSpreadsheet(240000),
      defaultCurrency,
      'Conto corrente',
      '',
      'Stipendio',
      '',
      'Stipendio del mese',
      '',
    ],
    [
      date(today),
      csvTypeLabel(TransactionType.transfer),
      formatCentsForSpreadsheet(20000),
      defaultCurrency,
      'Conto corrente',
      'Contanti',
      '',
      '',
      'Prelievo',
      '',
    ],
  ];
  return const CsvEncoder(fieldDelimiter: ';', addBom: true).convert(rows);
}

/// Chiave di confronto dei nomi: spazi ai lati tolti, minuscole.
String _key(String name) => name.trim().toLowerCase();

final _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');
final _italianDate = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$');

/// Data `AAAA-MM-GG` o `GG/MM/AAAA`; null se non valida o inesistente (es. 31/02/2026).
LocalDate? _parseDate(String text) {
  try {
    if (_isoDate.hasMatch(text)) return LocalDate.parse(text);
    final match = _italianDate.firstMatch(text);
    if (match != null) return LocalDate(int.parse(match[3]!), int.parse(match[2]!), int.parse(match[1]!));
  } on FormatException {
    return null;
  } on ArgumentError {
    return null;
  }
  return null;
}

class _Planner {
  _Planner({
    required List<Wallet> wallets,
    required List<Category> categories,
    required List<Label> labels,
    required this.activeIds,
    required this.deletedIds,
    this.fallbackWallet,
  }) : _wallets = {for (final w in wallets) _key(w.name): w},
       _categories = {for (final c in categories) (c.kind, _key(c.name)): c},
       _labels = {for (final l in labels) _key(l.name): l};

  final Set<String> activeIds;
  final Set<String> deletedIds;
  final Wallet? fallbackWallet;
  final Map<String, Wallet> _wallets;
  final Map<(CategoryKind, String), Category> _categories;
  final Map<String, Label> _labels;

  final _rows = <ImportedRow>[];
  final _errors = <ImportIssue>[];
  final _warnings = <ImportIssue>[];

  // Nomi sconosciuti, per chiave, con il nome come scritto la prima volta.
  final _unknownWallets = <String, String>{};
  final _unknownCategories = <(CategoryKind, String), String>{};
  final _unknownLabels = <String, String>{};

  /// Id già usati nel file (per scartare i doppioni) e contatore delle righe identiche senza id.
  final _seenIds = <String>{};
  final _repeats = <String, int>{};

  ImportPlan plan(String content) {
    final text = content.startsWith('﻿') ? content.substring(1) : content;
    final firstLine = text.split(RegExp(r'\r?\n')).firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
    // Il separatore si riconosce dalle intestazioni: con `;` (Excel italiano) le virgole sono decimali.
    final separator = firstLine.contains(';') ? ';' : ',';
    final records = CsvDecoder(fieldDelimiter: separator, skipEmptyLines: false).convert(text);

    var headerSeen = false;
    for (final (index, record) in records.indexed) {
      final line = index + 1;
      final fields = [for (final field in record) '${field ?? ''}'.trim()];
      if (fields.every((f) => f.isEmpty)) continue; // riga vuota
      if (!headerSeen) {
        headerSeen = true;
        if (!_checkHeader(fields, line)) return _result();
        continue;
      }
      _planRow(fields, line);
    }
    if (!headerSeen) _errors.add(const ImportIssue(1, 'Il file è vuoto'));
    return _result();
  }

  ImportPlan _result() => ImportPlan(
    rows: _rows,
    errors: _errors,
    warnings: _warnings,
    unknownWallets: _unknownWallets.values.toList(),
    unknownCategories: [for (final MapEntry(:key, :value) in _unknownCategories.entries) (name: value, kind: key.$1)],
    unknownLabels: _unknownLabels.values.toList(),
  );

  /// Intestazioni esatte, nell'ordine; eventuali colonne vuote in fondo (Excel) si ignorano.
  bool _checkHeader(List<String> fields, int line) {
    final header = [...fields];
    while (header.length > csvHeaders.length && header.last.isEmpty) {
      header.removeLast();
    }
    if (header.length == csvHeaders.length &&
        [for (var i = 0; i < header.length; i++) header[i] == csvHeaders[i]].every((ok) => ok)) {
      return true;
    }
    _errors.add(ImportIssue(line, 'Intestazioni non riconosciute: servono esattamente ${csvHeaders.join(';')}'));
    return false;
  }

  void _planRow(List<String> raw, int line) {
    final errors = <String>[];
    final warnings = <String>[];

    final fields = [...raw];
    while (fields.length > csvHeaders.length && fields.last.isEmpty) {
      fields.removeLast();
    }
    if (fields.length != csvHeaders.length) {
      _errors.add(ImportIssue(line, '${fields.length} colonne invece di ${csvHeaders.length}'));
      return;
    }
    final [
      dateText,
      typeText,
      amountText,
      currencyText,
      walletColumn,
      toWalletText,
      categoryText,
      labelsText,
      noteText,
      idText,
    ] = fields;
    // Colonna vuota: il portafoglio scelto nelle opzioni, se c'è.
    final walletText = walletColumn.isEmpty ? fallbackWallet?.name ?? '' : walletColumn;

    // Data
    final date = _parseDate(dateText);
    if (date == null) errors.add('data non valida «$dateText»: usa AAAA-MM-GG o GG/MM/AAAA');

    // Tipo
    final type = csvTypeFromLabel(typeText);
    if (type == null) errors.add('tipo non valido «$typeText»: usa spesa, entrata, trasferimento o rettifica');

    // Importo
    var amount = parseCents(amountText);
    if (amountText.isEmpty || amount == null) {
      errors.add('importo non valido «$amountText»: usa ad esempio 1.234,56 oppure 1234.56');
      amount = null;
    } else if (amount == 0) {
      errors.add('importo zero');
    } else if (amount < 0 && (type == TransactionType.expense || type == TransactionType.income)) {
      amount = -amount;
      warnings.add('importo negativo reso positivo: il tipo «${csvTypeLabel(type!)}» dice già il segno');
    } else if (amount < 0 && type == TransactionType.transfer) {
      errors.add('importo negativo in un trasferimento: indica l\'importo positivo e inverti i portafogli');
    }

    // Valuta
    if (currencyText.isNotEmpty && currencyText.toUpperCase() != defaultCurrency) {
      errors.add('valuta «$currencyText» non supportata: per ora solo $defaultCurrency');
    }

    // Portafogli
    ImportRef? wallet;
    if (walletText.isEmpty) {
      errors.add('portafoglio mancante: scrivilo nel file o scegli un portafoglio per le righe senza');
    } else {
      wallet = _walletRef(walletText);
    }
    ImportRef? toWallet;
    if (type == TransactionType.transfer) {
      if (toWalletText.isEmpty) {
        errors.add('portafoglio_destinazione mancante: è obbligatorio per i trasferimenti');
      } else if (_key(toWalletText) == _key(walletText)) {
        errors.add('portafoglio e portafoglio_destinazione devono essere diversi');
      } else {
        toWallet = _walletRef(toWalletText);
      }
    } else if (toWalletText.isNotEmpty && type != null) {
      warnings.add('portafoglio_destinazione ignorato: vale solo per i trasferimenti');
    }

    // Categoria e label: solo per spese ed entrate
    ImportRef? category;
    var rowLabels = const <ImportRef>[];
    final labelNames = [
      for (final name in labelsText.split(csvLabelSeparator))
        if (name.trim().isNotEmpty) name.trim(),
    ];
    if (type == TransactionType.expense || type == TransactionType.income) {
      final kind = type == TransactionType.expense ? CategoryKind.expense : CategoryKind.income;
      if (categoryText.isEmpty) {
        errors.add('categoria mancante: è obbligatoria per ${csvTypeLabel(type!)}');
      } else {
        category = _categoryRef(categoryText, kind);
      }
      final seen = <String>{};
      rowLabels = [
        for (final name in labelNames)
          if (seen.add(_key(name))) _labelRef(name),
      ];
    } else if (type != null) {
      if (categoryText.isNotEmpty) warnings.add('categoria ignorata: vale solo per spese ed entrate');
      if (labelNames.isNotEmpty) warnings.add('label ignorate: valgono solo per spese ed entrate');
    }

    final note = noteText.isEmpty ? null : noteText;

    // Id
    String? id;
    var updatesExisting = false;
    if (idText.isNotEmpty) {
      final normalizedId = idText.toLowerCase();
      if (!isUuid(idText)) {
        errors.add('id non valido «$idText»: deve essere un UUID oppure vuoto');
      } else if (deletedIds.contains(normalizedId)) {
        errors.add('l\'id è di un movimento eliminato: non si reimporta');
      } else if (!_seenIds.add(normalizedId)) {
        errors.add('id ripetuto nel file');
      } else {
        id = normalizedId;
        updatesExisting = activeIds.contains(normalizedId);
      }
    }

    if (errors.isNotEmpty || date == null || type == null || amount == null || wallet == null) {
      for (final message in errors) {
        _errors.add(ImportIssue(line, message));
      }
      return;
    }

    if (id == null) {
      // Riga senza id: UUID v5 dei campi normalizzati più un contatore per le righe identiche,
      // così reimportare lo stesso file produce gli stessi id (e aggiorna invece di duplicare).
      final normalized = [
        date.toString(),
        type.name,
        '$amount',
        defaultCurrency,
        _key(walletText),
        toWallet == null ? '' : _key(toWalletText),
        category == null ? '' : _key(categoryText),
        ([for (final l in rowLabels) _key(l.name)]..sort()).join(csvLabelSeparator),
        note ?? '',
      ].join('\u001f');
      final repeat = _repeats[normalized] ?? 0;
      _repeats[normalized] = repeat + 1;
      // Se l'id è di un movimento eliminato (es. import annullato), la lapide resta: si passa,
      // sempre in modo deterministico, alla "generazione" successiva dell'id. Così reimportare
      // dopo un annullamento ricrea le righe, e un ulteriore reimport le aggiorna senza duplicarle.
      var generation = 0;
      var generated = importedRowId(normalized, repeat);
      while (deletedIds.contains(generated)) {
        generation++;
        generated = importedRowId('$normalized\u001fgen$generation', repeat);
      }
      id = generated;
      if (!_seenIds.add(id)) {
        _errors.add(ImportIssue(line, 'id ripetuto nel file'));
        return;
      }
      updatesExisting = activeIds.contains(id);
    }

    _commitUnknowns(wallet, toWallet, category, type, rowLabels);
    for (final message in warnings) {
      _warnings.add(ImportIssue(line, message));
    }
    _rows.add(
      ImportedRow(
        line: line,
        id: id,
        type: type,
        amountCents: amount,
        date: date,
        wallet: wallet,
        toWallet: toWallet,
        category: category,
        labels: rowLabels,
        note: note,
        updatesExisting: updatesExisting,
      ),
    );
  }

  ImportRef _walletRef(String name) {
    final existing = _wallets[_key(name)];
    return existing == null ? ImportRef(_unknownWallets[_key(name)] ?? name) : ImportRef(existing.name, existing.id);
  }

  /// Categoria del tipo giusto. Se esiste solo dell'altro tipo è un errore; se non esiste va creata.
  /// Categoria abbinata per nome (senza distinzione di maiuscole) **e** tipo della riga. Una
  /// categoria con lo stesso nome ma dell'altro tipo non conta: quella della riga è sconosciuta e
  /// va creata (o abbinata) come categoria del tipo della riga.
  ImportRef _categoryRef(String name, CategoryKind kind) {
    final existing = _categories[(kind, _key(name))];
    if (existing != null) return ImportRef(existing.name, existing.id);
    return ImportRef(_unknownCategories[(kind, _key(name))] ?? name);
  }

  ImportRef _labelRef(String name) {
    final existing = _labels[_key(name)];
    return existing == null ? ImportRef(_unknownLabels[_key(name)] ?? name) : ImportRef(existing.name, existing.id);
  }

  /// I nomi da creare si registrano solo per le righe valide.
  void _commitUnknowns(
    ImportRef wallet,
    ImportRef? toWallet,
    ImportRef? category,
    TransactionType type,
    List<ImportRef> labels,
  ) {
    for (final ref in [wallet, ?toWallet]) {
      if (!ref.exists) _unknownWallets.putIfAbsent(_key(ref.name), () => ref.name);
    }
    if (category != null && !category.exists) {
      final kind = type == TransactionType.income ? CategoryKind.income : CategoryKind.expense;
      _unknownCategories.putIfAbsent((kind, _key(category.name)), () => category.name);
    }
    for (final label in labels) {
      if (!label.exists) _unknownLabels.putIfAbsent(_key(label.name), () => label.name);
    }
  }
}
