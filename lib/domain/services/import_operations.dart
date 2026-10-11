/// Dal piano di un import CSV (vedi `csv_import.dart`) e dalle scelte dell'utente alle operazioni
/// da scrivere: portafogli, categorie e label da creare, movimenti nuovi e movimenti aggiornati.
/// Logica pura: la scrittura (in un'unica transazione) la fa il repository degli import.
library;

import '../../core/dates.dart';
import '../../core/theme/category_palette.dart';
import '../models/category.dart';
import '../models/enums.dart';
import '../models/label.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import 'csv_import.dart';

/// Scelte dell'utente prima di importare.
class ImportChoices {
  const ImportChoices({this.walletMatches = const {}, this.categoryMatches = const {}, this.extraLabel});

  /// Portafogli sconosciuti abbinati a uno esistente: nome (come in `ImportPlan.unknownWallets`) → id.
  /// Quelli senza abbinamento vengono creati.
  final Map<String, String> walletMatches;

  /// Categorie sconosciute abbinate a una esistente dello stesso tipo. Senza abbinamento: create.
  final Map<UnknownCategory, String> categoryMatches;

  /// Label da aggiungere a tutte le spese e le entrate importate (create se non esiste).
  final String? extraLabel;

  ImportChoices copyWith({
    Map<String, String>? walletMatches,
    Map<UnknownCategory, String>? categoryMatches,
    String? Function()? extraLabel,
  }) => ImportChoices(
    walletMatches: walletMatches ?? this.walletMatches,
    categoryMatches: categoryMatches ?? this.categoryMatches,
    extraLabel: extraLabel == null ? this.extraLabel : extraLabel(),
  );
}

/// Cosa scrivere nel database per un import.
class ImportOperations {
  const ImportOperations({
    required this.newWallets,
    required this.newCategories,
    required this.newLabels,
    required this.inserts,
    required this.updates,
    this.skipped = const [],
  });

  final List<Wallet> newWallets;
  final List<Category> newCategories;
  final List<Label> newLabels;

  /// Movimenti nuovi, con `importBatchId` dell'import (annullandolo si cancellano).
  final List<Transaction> inserts;

  /// Movimenti esistenti aggiornati: tengono il loro `importBatchId` (annullare l'import non li
  /// ripristina), lo stato e la ricorrenza.
  final List<Transaction> updates;

  /// Righe valide nel file ma scartate per le scelte fatte (es. un trasferimento che, con gli
  /// abbinamenti, avrebbe origine e destinazione uguali).
  final List<ImportIssue> skipped;

  int get transactionCount => inserts.length + updates.length;
}

/// Costruisce le [ImportOperations] dell'import [batchId].
///
/// [wallets], [categories] e [labels] sono quelli esistenti (per l'ordine dei nuovi e per abbinare
/// la label aggiuntiva per nome); [existing] i movimenti che le righe aggiornano, per id.
/// I nuovi portafogli sono di tipo "altro", con saldo iniziale 0 a [today].
ImportOperations buildImportOperations({
  required ImportPlan plan,
  required ImportChoices choices,
  required String batchId,
  required List<Wallet> wallets,
  required List<Category> categories,
  required List<Label> labels,
  required Map<String, Transaction> existing,
  required LocalDate today,
  required String Function() newId,
}) {
  String key(String name) => name.trim().toLowerCase();

  // Portafogli: abbinati o nuovi.
  final walletIds = <String, String>{};
  final newWallets = <Wallet>[];
  var walletOrder = wallets.fold(-1, (max, w) => w.sortOrder > max ? w.sortOrder : max);
  for (final name in plan.unknownWallets) {
    final match = choices.walletMatches[name];
    if (match != null) {
      walletIds[name] = match;
      continue;
    }
    final wallet = Wallet(
      id: newId(),
      name: name,
      type: WalletType.other,
      initialBalanceDate: today,
      sortOrder: ++walletOrder,
    );
    newWallets.add(wallet);
    walletIds[name] = wallet.id;
  }

  // Categorie: abbinate o nuove, in fondo all'elenco del loro tipo.
  final categoryIds = <UnknownCategory, String>{};
  final newCategories = <Category>[];
  for (final unknown in plan.unknownCategories) {
    final match = choices.categoryMatches[unknown];
    if (match != null) {
      categoryIds[unknown] = match;
      continue;
    }
    final sameKind = [...categories, ...newCategories].where((c) => c.kind == unknown.kind);
    final category = Category(
      id: newId(),
      name: unknown.name,
      kind: unknown.kind,
      color: categoryPalette[(categories.length + newCategories.length) % categoryPalette.length],
      sortOrder: sameKind.fold(-1, (max, c) => c.sortOrder > max ? c.sortOrder : max) + 1,
    );
    newCategories.add(category);
    categoryIds[unknown] = category.id;
  }

  // Label: le sconosciute del file e, se nuova, quella aggiuntiva.
  final labelIds = <String, String>{for (final l in labels) key(l.name): l.id};
  final newLabels = <Label>[];
  void ensureLabel(String name) {
    if (labelIds.containsKey(key(name))) return;
    final label = Label(
      id: newId(),
      name: name.trim(),
      color: categoryPalette[(labels.length + newLabels.length) % categoryPalette.length],
    );
    newLabels.add(label);
    labelIds[key(name)] = label.id;
  }

  plan.unknownLabels.forEach(ensureLabel);
  final extra = choices.extraLabel?.trim();
  if (extra != null && extra.isNotEmpty) ensureLabel(extra);

  String walletOf(ImportRef ref) => ref.id ?? walletIds[ref.name]!;

  final inserts = <Transaction>[];
  final updates = <Transaction>[];
  final skipped = <ImportIssue>[];
  for (final row in plan.rows) {
    final hasCategory = row.type == TransactionType.expense || row.type == TransactionType.income;
    final categoryId = switch (row.category) {
      null => null,
      final ref when ref.id != null => ref.id,
      final ref =>
        categoryIds[(
          name: ref.name,
          kind: row.type == TransactionType.income ? CategoryKind.income : CategoryKind.expense,
        )],
    };
    final rowLabelIds = !hasCategory
        ? const <String>[]
        : <String>{
            for (final label in row.labels) label.id ?? labelIds[key(label.name)]!,
            if (extra != null && extra.isNotEmpty) labelIds[key(extra)]!,
          }.toList();

    final values = (
      type: row.type,
      amountCents: row.amountCents,
      date: row.date,
      walletId: walletOf(row.wallet),
      toWalletId: row.toWallet == null ? null : walletOf(row.toWallet!),
      categoryId: categoryId,
      labelIds: rowLabelIds,
      note: row.note,
    );

    if (values.toWalletId != null && values.toWalletId == values.walletId) {
      skipped.add(
        ImportIssue(row.line, 'con gli abbinamenti scelti origine e destinazione sono lo stesso portafoglio'),
      );
      continue;
    }

    final current = existing[row.id];
    if (row.updatesExisting && current != null) {
      updates.add(
        current.copyWith(
          type: values.type,
          amountCents: values.amountCents,
          date: values.date,
          walletId: values.walletId,
          toWalletId: values.toWalletId,
          categoryId: values.categoryId,
          labelIds: values.labelIds,
          note: values.note,
        ),
      );
    } else {
      inserts.add(
        Transaction(
          id: row.id,
          type: values.type,
          amountCents: values.amountCents,
          date: values.date,
          walletId: values.walletId,
          toWalletId: values.toWalletId,
          categoryId: values.categoryId,
          labelIds: values.labelIds,
          note: values.note,
          importBatchId: batchId,
        ),
      );
    }
  }

  return ImportOperations(
    newWallets: newWallets,
    newCategories: newCategories,
    newLabels: newLabels,
    inserts: inserts,
    updates: updates,
    skipped: skipped,
  );
}
