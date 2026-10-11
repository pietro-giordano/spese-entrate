import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/clock.dart';
import '../../../core/dates.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/statistics.dart';
import '../../../domain/services/comparison.dart';
import '../../../domain/services/statistics.dart';
import '../../../domain/services/transaction_list.dart';
import '../../transactions/application/transaction_providers.dart';
import 'analytics_filters.dart';

part 'compare_providers.freezed.dart';
part 'compare_providers.g.dart';

enum CompareChart { bars, lines }

@freezed
abstract class CompareState with _$CompareState {
  const factory CompareState({
    required ComparePreset preset,

    /// Periodi confrontati, il primo è quello di riferimento (di solito il più recente).
    required List<Period> periods,
    @Default(CompareMetric.expense) CompareMetric metric,
    @Default(CompareChart.bars) CompareChart chart,
  }) = _CompareState;

  const CompareState._();

  bool get canAddPeriod => periods.length < maxComparedPeriods;
}

/// Stato della tab Confronta. Parte dagli ultimi 3 mesi.
@Riverpod(keepAlive: true)
class CompareController extends _$CompareController {
  @override
  CompareState build() => CompareState(
    preset: ComparePreset.lastThreeMonths,
    periods: presetPeriods(ComparePreset.lastThreeMonths, ref.read(todayProvider)),
  );

  /// "Personalizzato" tiene i periodi attuali e permette di cambiarli.
  void applyPreset(ComparePreset preset) {
    if (preset == ComparePreset.custom) {
      state = state.copyWith(preset: preset);
      return;
    }
    state = state.copyWith(preset: preset, periods: presetPeriods(preset, ref.read(todayProvider)));
  }

  /// Aggiunge un periodo (al massimo 3, niente doppioni). Restituisce false se non è stato aggiunto.
  bool addPeriod(Period period) {
    if (!state.canAddPeriod || state.periods.contains(period)) return false;
    state = state.copyWith(preset: ComparePreset.custom, periods: [...state.periods, period]);
    return true;
  }

  /// Ne resta sempre almeno uno.
  void removePeriod(Period period) {
    if (state.periods.length <= 1) return;
    state = state.copyWith(preset: ComparePreset.custom, periods: [...state.periods]..remove(period));
  }

  void setMetric(CompareMetric metric) => state = state.copyWith(metric: metric);

  void setChart(CompareChart chart) => state = state.copyWith(chart: chart);
}

/// Dati di un periodo confrontato.
class ComparedPeriod {
  const ComparedPeriod({
    required this.period,
    required this.summary,
    required this.byCategory,
    required this.cumulative,
  });

  final Period period;

  /// Entrate e uscite (solo spese ed entrate confermate).
  final PeriodSummary summary;

  /// Totali per categoria della grandezza scelta (vuoto per il saldo).
  final Map<String?, int> byCategory;

  /// Valore cumulato giorno per giorno.
  final List<int> cumulative;

  int total(CompareMetric metric) => switch (metric) {
    CompareMetric.expense => summary.expenseCents,
    CompareMetric.income => summary.incomeCents,
    CompareMetric.balance => summary.balanceCents,
  };
}

/// Calcola i dati di ogni periodo scelto per la grandezza scelta.
@riverpod
Future<List<ComparedPeriod>> comparison(Ref ref) async {
  final state = ref.watch(compareControllerProvider);
  // Filtri della tab Confronta: valgono per barre, linee, totali e tabella delle variazioni.
  final filters = ref.watch(analyticsFiltersProvider(AnalyticsTab.compare));
  final kind = state.metric == CompareMetric.income ? CategoryKind.income : CategoryKind.expense;
  final result = <ComparedPeriod>[];
  for (final period in state.periods) {
    final transactions = filterForAnalytics(await ref.watch(transactionsInRangeProvider(period.range).future), filters);
    result.add(
      ComparedPeriod(
        period: period,
        summary: summarize(transactions, period.range),
        byCategory: state.metric == CompareMetric.balance
            ? const {}
            : {for (final item in breakdownByCategory(transactions, period.range, kind)) item.id: item.totalCents},
        cumulative: cumulativeByDay(transactions, period.range, state.metric),
      ),
    );
  }
  return result;
}
