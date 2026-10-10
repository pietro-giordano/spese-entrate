import 'package:drift/drift.dart';

import '../../domain/models/enums.dart';
import 'converters.dart';

/// Colonne comuni a ogni tabella sincronizzabile.
///
/// Timestamp in millisecondi UTC. `deleted_at` valorizzato = cancellato (logicamente).
/// Niente chiavi esterne tra tabelle: con la futura sync le righe possono arrivare
/// in qualsiasi ordine, quindi la coerenza dei riferimenti la garantiscono i repository.
mixin SyncColumns on Table {
  TextColumn get id => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
  TextColumn get deviceId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WalletRow')
class Wallets extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get type => textEnum<WalletType>()();
  TextColumn get currency => text().withDefault(const Constant('EUR'))();
  IntColumn get initialBalanceCents => integer()();
  TextColumn get initialBalanceDate => text().map(const LocalDateConverter())();
  BoolColumn get includeInTotal => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer()();
  IntColumn get archivedAt => integer().nullable()();
}

@DataClassName('CategoryRow')
class Categories extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get kind => textEnum<CategoryKind>()();

  /// Colore ARGB (es. 0xFF15803D).
  IntColumn get color => integer()();
  IntColumn get sortOrder => integer()();
  IntColumn get archivedAt => integer().nullable()();
}

/// Il nome è unico tra le label non cancellate: lo controlla il repository.
@DataClassName('LabelRow')
class Labels extends Table with SyncColumns {
  TextColumn get name => text()();
  IntColumn get color => integer()();
}

@DataClassName('TransactionRow')
@TableIndex(name: 'transactions_date', columns: {#date})
@TableIndex(name: 'transactions_wallet_id', columns: {#walletId})
@TableIndex(name: 'transactions_category_id', columns: {#categoryId})
class Transactions extends Table with SyncColumns {
  TextColumn get type => textEnum<TransactionType>()();
  TextColumn get status => textEnum<TransactionStatus>().withDefault(const Constant('confirmed'))();

  /// Sempre > 0, tranne le rettifiche che hanno segno.
  IntColumn get amountCents => integer()();
  TextColumn get currency => text()();
  TextColumn get date => text().map(const LocalDateConverter())();

  /// Portafoglio del movimento; per i trasferimenti è quello di origine.
  TextColumn get walletId => text()();

  /// Solo per i trasferimenti: portafoglio di destinazione.
  TextColumn get toWalletId => text().nullable()();

  /// Obbligatoria per spese ed entrate.
  TextColumn get categoryId => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get recurrenceId => text().nullable()();
  TextColumn get occurrenceDate => text().map(const LocalDateConverter()).nullable()();

  // SQLite considera distinti i NULL: i movimenti non ricorrenti non entrano in conflitto.
  @override
  List<Set<Column>> get uniqueKeys => [
    {recurrenceId, occurrenceDate},
  ];

  @override
  List<String> get customConstraints => [
    "CHECK (type = 'adjustment' OR amount_cents > 0)",
    "CHECK (type NOT IN ('expense', 'income') OR category_id IS NOT NULL)",
    "CHECK ((type = 'transfer') = (to_wallet_id IS NOT NULL))",
  ];
}

@DataClassName('TransactionLabelRow')
@TableIndex(name: 'transaction_labels_label_id', columns: {#labelId})
class TransactionLabels extends Table with SyncColumns {
  TextColumn get transactionId => text()();
  TextColumn get labelId => text()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {transactionId, labelId},
  ];
}

@DataClassName('AttachmentRow')
@TableIndex(name: 'attachments_transaction_id', columns: {#transactionId})
class Attachments extends Table with SyncColumns {
  TextColumn get transactionId => text()();

  /// Relativo alla cartella documenti dell'app.
  TextColumn get localPath => text()();
  TextColumn get mimeType => text()();
  IntColumn get sizeBytes => integer()();
  TextColumn get sha256 => text()();
  TextColumn get remoteUrl => text().nullable()();
}

@DataClassName('RecurrenceRuleRow')
class RecurrenceRules extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get type => textEnum<TransactionType>()();
  IntColumn get amountCents => integer()();
  TextColumn get currency => text()();
  TextColumn get walletId => text()();
  TextColumn get toWalletId => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get labelIds => text().map(const StringListConverter())();
  TextColumn get frequency => textEnum<RecurrenceFrequency>()();
  IntColumn get interval => integer().withDefault(const Constant(1))();

  /// 1 = lunedì … 7 = domenica.
  IntColumn get byWeekday => integer().nullable()();
  IntColumn get byMonthDay => integer().nullable()();
  IntColumn get byMonth => integer().nullable()();
  TextColumn get startDate => text().map(const LocalDateConverter())();
  TextColumn get endDate => text().map(const LocalDateConverter()).nullable()();
  IntColumn get maxCount => integer().nullable()();
  TextColumn get mode => textEnum<RecurrenceMode>()();
  IntColumn get pausedAt => integer().nullable()();

  @override
  List<String> get customConstraints => [
    "CHECK (type IN ('expense', 'income', 'transfer'))",
    'CHECK (amount_cents > 0)',
    'CHECK (interval >= 1)',
  ];
}

@DataClassName('RecurrenceExceptionRow')
class RecurrenceExceptions extends Table with SyncColumns {
  TextColumn get ruleId => text()();
  TextColumn get occurrenceDate => text().map(const LocalDateConverter())();
  TextColumn get kind => textEnum<RecurrenceExceptionKind>()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {ruleId, occurrenceDate},
  ];
}

/// Impostazioni sincronizzabili (chiave → valore testuale).
@DataClassName('SettingRow')
class Settings extends Table with SyncColumns {
  TextColumn get key => text().unique()();
  TextColumn get value => text()();
}

/// Valori solo locali, mai sincronizzati (device_id, tema, blocco biometrico...).
@DataClassName('AppMetaRow')
class AppMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Coda delle modifiche locali da inviare al server (solo locale).
@DataClassName('OutboxRow')
class Outbox extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entity => text()();
  TextColumn get entityId => text()();
  TextColumn get op => textEnum<OutboxOp>()();
  IntColumn get changedAt => integer()();
}
