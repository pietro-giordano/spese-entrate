import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/clock.dart';
import '../../../core/dates.dart';
import '../../../data/repositories/drift_recurrence_repository.dart' show confirmHorizonDays;
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/recurrence_exception.dart';
import '../../../domain/models/recurrence_rule.dart';
import '../../../domain/models/transaction.dart';
import '../../../domain/repositories/recurrence_repository.dart';
import '../../../domain/services/recurrence.dart';
import '../../transactions/application/transaction_providers.dart';

part 'recurring_providers.g.dart';

/// Crea le occorrenze mancanti (all'avvio, al ritorno in primo piano, dopo le modifiche).
/// Le richieste si mettono in fila: due esecuzioni non si sovrappongono mai.
class RecurrenceGenerator {
  RecurrenceGenerator(this._repository, this._today);

  final RecurrenceRepository _repository;
  final LocalDate Function() _today;
  Future<int> _queue = Future.value(0);

  Future<int> run() {
    final next = _queue.catchError((_) => 0).then((_) => _repository.generate(today: _today()));
    _queue = next;
    return next;
  }
}

@Riverpod(keepAlive: true)
RecurrenceGenerator recurrenceGenerator(Ref ref) => RecurrenceGenerator(
  ref.watch(recurrenceRepositoryProvider),
  // Si legge l'orologio a ogni esecuzione: l'app può restare aperta oltre la mezzanotte.
  () => LocalDate.fromDateTime(ref.read(clockProvider)()),
);

/// Regole non cancellate, per nome.
@riverpod
Stream<List<RecurrenceRule>> recurrenceRules(Ref ref) => ref.watch(recurrenceRepositoryProvider).watchAll();

/// Date saltate di tutte le regole.
@riverpod
Stream<List<RecurrenceException>> recurrenceExceptions(Ref ref) =>
    ref.watch(recurrenceRepositoryProvider).watchExceptions();

@riverpod
Future<RecurrenceRule?> recurrenceRule(Ref ref, String id) async =>
    (await ref.watch(recurrenceRulesProvider.future)).firstWhereOrNull((r) => r.id == id);

/// Sezione "In arrivo" della home: movimenti da confermare fino a oggi + 7 giorni
/// (anche quelli scaduti e non ancora confermati), dal più vicino.
/// I `pending` delle regole in pausa restano nascosti finché la regola non riprende.
@riverpod
Future<List<Transaction>> upcomingTransactions(Ref ref) async {
  final horizon = ref.watch(todayProvider).addDays(confirmHorizonDays);
  final rules = {for (final rule in await ref.watch(recurrenceRulesProvider.future)) rule.id: rule};
  final transactions = await ref.watch(allTransactionsProvider.future);
  return transactions
      .where(
        (tx) =>
            tx.status == TransactionStatus.pending &&
            !tx.date.isAfter(horizon) &&
            !(rules[tx.recurrenceId]?.isPaused ?? false),
      )
      .sorted((a, b) => a.date.compareTo(b.date));
}

/// Date delle occorrenze eliminate di una regola (non si rigenerano).
@riverpod
Stream<Set<LocalDate>> deletedOccurrences(Ref ref, String ruleId) =>
    ref.watch(recurrenceRepositoryProvider).watchDeletedOccurrences(ruleId);

/// Movimenti (non cancellati) di una regola, dal più recente.
@riverpod
Future<List<Transaction>> ruleTransactions(Ref ref, String ruleId) async =>
    (await ref.watch(allTransactionsProvider.future)).where((tx) => tx.recurrenceId == ruleId).toList();

/// Totali fissi del mese in corso e media mensile prevista.
@riverpod
Future<RecurringTotals> recurringTotalsThisMonth(Ref ref) async {
  final today = ref.watch(todayProvider);
  return recurringTotals(
    rules: await ref.watch(recurrenceRulesProvider.future),
    exceptions: await ref.watch(recurrenceExceptionsProvider.future),
    transactions: await ref.watch(allTransactionsProvider.future),
    month: Period.containing(PeriodType.month, today).range,
    today: today,
  );
}

/// Operazioni delle schermate delle ricorrenze. Dopo le modifiche che cambiano cosa
/// va generato, il generatore riparte subito.
class RecurrenceActions {
  RecurrenceActions(this._ref);

  final Ref _ref;

  RecurrenceRepository get _repository => _ref.read(recurrenceRepositoryProvider);
  LocalDate get _today => LocalDate.fromDateTime(_ref.read(clockProvider)());

  Future<void> setPaused(String ruleId, {required bool paused}) async {
    if (paused) return _repository.pause(ruleId);
    await _repository.resume(ruleId, today: _today);
    await _ref.read(recurrenceGeneratorProvider).run();
  }

  Future<void> skip(String ruleId, LocalDate occurrenceDate) => _repository.skip(ruleId, occurrenceDate);

  Future<void> delete(String ruleId) => _repository.delete(ruleId);

  /// Movimento da aprire per modificare l'occorrenza (creato come `pending` se non c'è ancora).
  Future<Transaction?> occurrenceTransaction(String ruleId, LocalDate occurrenceDate) =>
      _repository.occurrenceTransaction(ruleId, occurrenceDate);
}

@riverpod
RecurrenceActions recurrenceActions(Ref ref) => RecurrenceActions(ref);
