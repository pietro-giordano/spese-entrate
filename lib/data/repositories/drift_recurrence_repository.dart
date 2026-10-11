import 'package:drift/drift.dart';

import '../../core/dates.dart';
import '../../core/ids.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/recurrence_exception.dart';
import '../../domain/models/recurrence_rule.dart';
import '../../domain/models/transaction.dart';
import '../../domain/repositories/recurrence_repository.dart';
import '../../domain/services/recurrence.dart';
import '../db/app_database.dart';
import 'drift_transaction_repository.dart';
import 'mappers.dart';

/// Giorni oltre oggi per cui le regole `confirm` propongono i `pending`.
const confirmHorizonDays = 7;

class DriftRecurrenceRepository implements RecurrenceRepository {
  DriftRecurrenceRepository(this._db) : _transactions = DriftTransactionRepository(_db);

  final AppDatabase _db;

  /// I movimenti generati passano dal repository dei movimenti: label e outbox come sempre.
  final DriftTransactionRepository _transactions;

  @override
  Stream<List<RecurrenceRule>> watchAll() {
    final query = _db.select(_db.recurrenceRules)
      ..whereNotDeleted()
      ..orderBy([
        (t) => OrderingTerm(expression: t.name.collate(Collate.noCase)),
        (t) => OrderingTerm(expression: t.id),
      ]);
    return query.watch().map((rows) => rows.map(recurrenceRuleFromRow).toList());
  }

  @override
  Future<RecurrenceRule?> getById(String id) async {
    final row =
        await (_db.select(_db.recurrenceRules)
              ..whereNotDeleted()
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();
    return row == null ? null : recurrenceRuleFromRow(row);
  }

  @override
  Stream<List<RecurrenceException>> watchExceptions() {
    final query = _db.select(_db.recurrenceExceptions)..whereNotDeleted();
    return query.watch().map((rows) => rows.map(recurrenceExceptionFromRow).toList());
  }

  @override
  Stream<Set<LocalDate>> watchDeletedOccurrences(String ruleId) {
    final query = _db.select(_db.transactions)..where((t) => t.recurrenceId.equals(ruleId) & t.deletedAt.isNotNull());
    return query.watch().map((rows) => {for (final row in rows) row.occurrenceDate!});
  }

  @override
  Future<void> save(RecurrenceRule rule, {List<LocalDate> skippedDates = const []}) {
    return _db.transaction(() async {
      // Una regola cancellata non torna attiva salvandola (lapide definitiva).
      final existing = await (_db.select(_db.recurrenceRules)..where((t) => t.id.equals(rule.id))).getSingleOrNull();
      if (existing?.deletedAt != null) throw StateError('La ricorrenza ${rule.id} è stata eliminata');
      await _db.upsertSynced(_db.recurrenceRules, rule.id, recurrenceRuleToCompanion(rule));
      for (final date in skippedDates) {
        await _addException(rule.id, date);
      }
    });
  }

  @override
  Future<void> pause(String ruleId) => _db.transaction(() async {
    final rule = await _requireRule(ruleId);
    if (rule.isPaused) return;
    await _db.upsertSynced(_db.recurrenceRules, ruleId, RecurrenceRulesCompanion(pausedAt: Value(_db.nowMs())));
  });

  @override
  Future<void> resume(String ruleId, {required LocalDate today}) => _db.transaction(() async {
    final rule = await _requireRule(ruleId);
    final pausedAt = rule.pausedAt;
    if (pausedAt == null) return;
    final pausedOn = LocalDate.fromDateTime(pausedAt.toLocal());
    final slots = await _slots(ruleId);
    for (final date in occurrencesBetween(rule, pausedOn, today.addDays(-1))) {
      final row = slots[date];
      // Un movimento già confermato prima della pausa resta com'è.
      if (row != null && row.deletedAt == null && row.status == TransactionStatus.confirmed) continue;
      await _addException(ruleId, date);
      if (row != null && row.deletedAt == null) await _db.softDelete(_db.transactions, row.id);
    }
    await _db.upsertSynced(_db.recurrenceRules, ruleId, const RecurrenceRulesCompanion(pausedAt: Value(null)));
  });

  @override
  Future<void> skip(String ruleId, LocalDate occurrenceDate) => _db.transaction(() async {
    await _requireRule(ruleId);
    await _addException(ruleId, occurrenceDate);
    final row = (await _slots(ruleId))[occurrenceDate];
    if (row != null && row.deletedAt == null && row.status == TransactionStatus.pending) {
      await _db.softDelete(_db.transactions, row.id);
    }
  });

  @override
  Future<void> delete(String ruleId) => _db.transaction(() async {
    for (final row in (await _slots(ruleId)).values) {
      if (row.deletedAt == null && row.status == TransactionStatus.pending) {
        await _db.softDelete(_db.transactions, row.id);
      }
    }
    await _db.softDelete(_db.recurrenceRules, ruleId);
  });

  @override
  Future<Transaction?> occurrenceTransaction(String ruleId, LocalDate occurrenceDate) => _db.transaction(() async {
    final rule = await _requireRule(ruleId);
    final row = (await _slots(ruleId))[occurrenceDate];
    if (row != null) return row.deletedAt == null ? _transactions.getById(row.id) : null;
    if (await _isSkipped(ruleId, occurrenceDate)) return null;
    if (occurrenceIndex(rule, occurrenceDate) == null) throw ArgumentError.value(occurrenceDate, 'occurrenceDate');
    // Resta `pending` anche per le regole automatiche: un confermato con data futura
    // entrerebbe subito nei saldi. Il generatore lo conferma quando arriva il giorno.
    final tx = _occurrence(rule, occurrenceDate, TransactionStatus.pending);
    await _transactions.save(tx);
    return _transactions.getById(tx.id);
  });

  @override
  Future<RecurrenceRule> split(String ruleId, {required LocalDate boundary, required RecurrenceRule next}) {
    return _db.transaction(() async {
      final old = await _requireRule(ruleId);
      final resolved = <LocalDate>{};
      for (final MapEntry(key: date, value: row) in (await _slots(ruleId)).entries) {
        if (!date.isAfter(boundary)) continue;
        if (row.deletedAt == null && row.status == TransactionStatus.pending) {
          // Proposta non ancora confermata: la rigenera la regola nuova, con i valori nuovi.
          await _db.softDelete(_db.transactions, row.id);
        } else {
          // Confermata o eliminata: è storico, non si tocca e non si duplica.
          resolved.add(date);
        }
      }
      for (final exception in await _exceptions(ruleId)) {
        if (exception.occurrenceDate.isAfter(boundary)) resolved.add(exception.occurrenceDate);
      }

      final result = splitRule(old, boundary: boundary, next: next, resolvedOldDates: resolved);
      await _db.upsertSynced(_db.recurrenceRules, ruleId, recurrenceRuleToCompanion(result.ended));
      await save(result.next, skippedDates: result.nextSkips);
      return result.next;
    });
  }

  @override
  Future<int> generate({required LocalDate today}) {
    return _db.transaction(() async {
      var changed = 0;
      final rules =
          await (_db.select(_db.recurrenceRules)
                ..whereNotDeleted()
                ..where((t) => t.pausedAt.isNull()))
              .get();
      for (final rule in rules.map(recurrenceRuleFromRow)) {
        final auto = rule.mode == RecurrenceMode.auto;
        final horizon = auto ? today : today.addDays(confirmHorizonDays);
        final slots = await _slots(rule.id);
        final skipped = {for (final e in await _exceptions(rule.id)) e.occurrenceDate};

        for (final date in occurrenceDates(rule).takeWhile((d) => !d.isAfter(horizon))) {
          if (slots.containsKey(date) || skipped.contains(date)) continue;
          final tx = _occurrence(rule, date, auto ? TransactionStatus.confirmed : TransactionStatus.pending);
          // Difesa: mai sovrascrivere un movimento esistente con lo stesso ID.
          if (await _exists(tx.id)) continue;
          await _transactions.save(tx);
          changed++;
        }

        if (!auto) continue;
        for (final row in slots.values) {
          if (row.deletedAt == null && row.status == TransactionStatus.pending && !row.date.isAfter(today)) {
            await _db.upsertSynced(
              _db.transactions,
              row.id,
              const TransactionsCompanion(status: Value(TransactionStatus.confirmed)),
            );
            changed++;
          }
        }
      }
      return changed;
    });
  }

  /// Movimento dell'occorrenza [date] di [rule], con i valori della regola.
  Transaction _occurrence(RecurrenceRule rule, LocalDate date, TransactionStatus status) => Transaction(
    id: occurrenceId(rule.id, date),
    type: rule.type,
    status: status,
    amountCents: rule.amountCents,
    currency: rule.currency,
    date: date,
    walletId: rule.walletId,
    toWalletId: rule.toWalletId,
    categoryId: rule.categoryId,
    note: rule.note,
    labelIds: rule.labelIds,
    recurrenceId: rule.id,
    occurrenceDate: date,
  );

  Future<RecurrenceRule> _requireRule(String id) async =>
      await getById(id) ?? (throw StateError('La ricorrenza $id non esiste o è stata eliminata'));

  /// Movimenti della regola per data di occorrenza, compresi quelli cancellati
  /// (occupano comunque la data: il vincolo unico vieta di ricrearli).
  Future<Map<LocalDate, TransactionRow>> _slots(String ruleId) async {
    final rows = await (_db.select(_db.transactions)..where((t) => t.recurrenceId.equals(ruleId))).get();
    return {for (final row in rows) row.occurrenceDate!: row};
  }

  Future<List<RecurrenceException>> _exceptions(String ruleId) async {
    final rows =
        await (_db.select(_db.recurrenceExceptions)
              ..whereNotDeleted()
              ..where((t) => t.ruleId.equals(ruleId)))
            .get();
    return rows.map(recurrenceExceptionFromRow).toList();
  }

  Future<bool> _isSkipped(String ruleId, LocalDate date) async =>
      (await _exceptions(ruleId)).any((e) => e.occurrenceDate == date);

  Future<bool> _exists(String transactionId) async =>
      await (_db.select(_db.transactions)..where((t) => t.id.equals(transactionId))).getSingleOrNull() != null;

  /// Eccezione "salta" per [date], se non c'è già (il vincolo unico vale anche per le cancellate).
  Future<void> _addException(String ruleId, LocalDate date) async {
    final existing = await (_db.select(
      _db.recurrenceExceptions,
    )..where((t) => t.ruleId.equals(ruleId) & t.occurrenceDate.equalsValue(date))).getSingleOrNull();
    if (existing != null) return;
    await _db.upsertSynced(
      _db.recurrenceExceptions,
      newId(nowMs: _db.nowMs()),
      RecurrenceExceptionsCompanion(
        ruleId: Value(ruleId),
        occurrenceDate: Value(date),
        kind: const Value(RecurrenceExceptionKind.skip),
      ),
    );
  }
}
