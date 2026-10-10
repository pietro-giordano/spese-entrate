import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/clock.dart';
import '../../../core/dates.dart';
import '../../../domain/models/statistics.dart';
import '../../../domain/models/transaction.dart';
import '../../../domain/models/transaction_filters.dart';
import '../../../domain/services/statistics.dart';
import '../../../domain/services/transaction_list.dart';
import 'transaction_providers.dart';

part 'transaction_list_providers.g.dart';

/// Cambia il tipo di periodo restando vicino a quello attuale: se il periodo contiene
/// [today] riparte da oggi, altrimenti dal suo primo giorno. "Periodo" mantiene le date attuali.
Period changePeriodType(Period current, PeriodType type, {required LocalDate today, required int weekStart}) {
  if (type == current.type) return current;
  if (type == PeriodType.custom) return Period.custom(current.start, current.end);
  final anchor = current.range.contains(today) ? today : current.start;
  return Period.containing(type, anchor, weekStart: weekStart);
}

/// Periodo scelto, condiviso tra la tab Movimenti e la schermata Filtri. Parte dal mese corrente.
@Riverpod(keepAlive: true)
class SelectedPeriod extends _$SelectedPeriod {
  @override
  Period build() => Period.containing(PeriodType.month, ref.read(todayProvider));

  void set(Period period) => state = period;

  void changeType(PeriodType type, {required LocalDate today, required int weekStart}) =>
      state = changePeriodType(state, type, today: today, weekStart: weekStart);

  /// Frecce: un periodo avanti (1) o indietro (−1).
  void shift(int steps) => state = state.shift(steps);
}

/// Filtri attivi, condivisi tra la tab Movimenti e la schermata Filtri.
@Riverpod(keepAlive: true)
class ActiveFilters extends _$ActiveFilters {
  @override
  TransactionFilters build() => const TransactionFilters();

  void apply(TransactionFilters filters) => state = filters;

  void reset() => state = const TransactionFilters();
}

/// Movimenti confermati del periodo che passano i filtri, dal più recente.
/// I `pending` sono esclusi: compariranno nella sezione "In arrivo".
@riverpod
Future<List<Transaction>> visibleTransactions(Ref ref) async {
  final period = ref.watch(selectedPeriodProvider);
  final filters = ref.watch(activeFiltersProvider);
  final transactions = await ref.watch(transactionsInRangeProvider(period.range).future);
  return transactions.where((tx) => tx.isConfirmed && matchesFilters(tx, filters)).toList();
}

/// Riepilogo del periodo (entrate, uscite, saldo) sui movimenti visibili.
@riverpod
Future<PeriodSummary> visibleSummary(Ref ref) async {
  final period = ref.watch(selectedPeriodProvider);
  return summarize(await ref.watch(visibleTransactionsProvider.future), period.range);
}

/// Lista raggruppata per giorno con il totale giornaliero.
@riverpod
Future<List<DayGroup>> visibleDayGroups(Ref ref) async =>
    groupByDay(await ref.watch(visibleTransactionsProvider.future));
