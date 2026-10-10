// Conversioni tra righe Drift (`...Row`, `...Companion`) e modelli di dominio.
// I Companion non contengono i campi comuni: li imposta AppDatabase.upsertSynced.

import 'package:drift/drift.dart';

import '../../domain/models/attachment.dart';
import '../../domain/models/category.dart';
import '../../domain/models/label.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/wallet.dart';
import '../db/app_database.dart';

DateTime? _fromMs(int? ms) => ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

int? _toMs(DateTime? dateTime) => dateTime?.millisecondsSinceEpoch;

Wallet walletFromRow(WalletRow row) => Wallet(
  id: row.id,
  name: row.name,
  type: row.type,
  currency: row.currency,
  initialBalanceCents: row.initialBalanceCents,
  initialBalanceDate: row.initialBalanceDate,
  includeInTotal: row.includeInTotal,
  sortOrder: row.sortOrder,
  archivedAt: _fromMs(row.archivedAt),
);

WalletsCompanion walletToCompanion(Wallet wallet) => WalletsCompanion(
  name: Value(wallet.name),
  type: Value(wallet.type),
  currency: Value(wallet.currency),
  initialBalanceCents: Value(wallet.initialBalanceCents),
  initialBalanceDate: Value(wallet.initialBalanceDate),
  includeInTotal: Value(wallet.includeInTotal),
  sortOrder: Value(wallet.sortOrder),
  archivedAt: Value(_toMs(wallet.archivedAt)),
);

Category categoryFromRow(CategoryRow row) => Category(
  id: row.id,
  name: row.name,
  kind: row.kind,
  color: row.color,
  sortOrder: row.sortOrder,
  archivedAt: _fromMs(row.archivedAt),
);

CategoriesCompanion categoryToCompanion(Category category) => CategoriesCompanion(
  name: Value(category.name),
  kind: Value(category.kind),
  color: Value(category.color),
  sortOrder: Value(category.sortOrder),
  archivedAt: Value(_toMs(category.archivedAt)),
);

Label labelFromRow(LabelRow row) => Label(id: row.id, name: row.name, color: row.color);

LabelsCompanion labelToCompanion(Label label) => LabelsCompanion(name: Value(label.name), color: Value(label.color));

Transaction transactionFromRow(TransactionRow row, {List<String> labelIds = const []}) => Transaction(
  id: row.id,
  type: row.type,
  status: row.status,
  amountCents: row.amountCents,
  currency: row.currency,
  date: row.date,
  walletId: row.walletId,
  toWalletId: row.toWalletId,
  categoryId: row.categoryId,
  note: row.note,
  labelIds: labelIds,
  recurrenceId: row.recurrenceId,
  occurrenceDate: row.occurrenceDate,
);

/// Le label non stanno nella riga del movimento ma in `transaction_labels`.
TransactionsCompanion transactionToCompanion(Transaction tx) => TransactionsCompanion(
  type: Value(tx.type),
  status: Value(tx.status),
  amountCents: Value(tx.amountCents),
  currency: Value(tx.currency),
  date: Value(tx.date),
  walletId: Value(tx.walletId),
  toWalletId: Value(tx.toWalletId),
  categoryId: Value(tx.categoryId),
  note: Value(tx.note),
  recurrenceId: Value(tx.recurrenceId),
  occurrenceDate: Value(tx.occurrenceDate),
);

Attachment attachmentFromRow(AttachmentRow row) => Attachment(
  id: row.id,
  transactionId: row.transactionId,
  localPath: row.localPath,
  mimeType: row.mimeType,
  sizeBytes: row.sizeBytes,
  sha256: row.sha256,
  remoteUrl: row.remoteUrl,
);

AttachmentsCompanion attachmentToCompanion(Attachment attachment) => AttachmentsCompanion(
  transactionId: Value(attachment.transactionId),
  localPath: Value(attachment.localPath),
  mimeType: Value(attachment.mimeType),
  sizeBytes: Value(attachment.sizeBytes),
  sha256: Value(attachment.sha256),
  remoteUrl: Value(attachment.remoteUrl),
);
