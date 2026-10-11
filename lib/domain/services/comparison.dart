/// Confronto tra periodi: totali, andamento cumulato e variazioni.
///
/// Come tutte le statistiche, conta solo spese ed entrate confermate
/// (niente trasferimenti, rettifiche o pending).
library;

import '../../core/dates.dart';
import '../models/enums.dart';
import '../models/transaction.dart';
import 'statistics.dart';

/// Grandezza confrontata.
enum CompareMetric { expense, income, balance }

/// Scorciatoie della schermata Confronta.
enum ComparePreset { lastThreeMonths, monthVsLastYear, yearVsYear, custom }

/// Massimo di periodi confrontabili.
const maxComparedPeriods = 3;

/// Periodi di un preset, dal più recente. [ComparePreset.custom] non ne propone.
List<Period> presetPeriods(ComparePreset preset, LocalDate today) {
  final thisMonth = Period.containing(PeriodType.month, today);
  return switch (preset) {
    ComparePreset.lastThreeMonths => [thisMonth, thisMonth.shift(-1), thisMonth.shift(-2)],
    ComparePreset.monthVsLastYear => [thisMonth, thisMonth.shift(-12)],
    ComparePreset.yearVsYear => [
      Period.containing(PeriodType.year, today),
      Period.containing(PeriodType.year, today).shift(-1),
    ],
    ComparePreset.custom => const [],
  };
}

/// Effetto di un movimento sulla grandezza: positivo per spese o entrate, con segno per il saldo.
/// Zero se il movimento non conta nelle statistiche.
int metricValue(Transaction tx, CompareMetric metric) {
  if (!countsInStatistics(tx)) return 0;
  final isIncome = tx.type == TransactionType.income;
  return switch (metric) {
    CompareMetric.expense => isIncome ? 0 : tx.amountCents,
    CompareMetric.income => isIncome ? tx.amountCents : 0,
    CompareMetric.balance => isIncome ? tx.amountCents : -tx.amountCents,
  };
}

/// Totale della grandezza nei movimenti con data in [range].
int metricTotal(Iterable<Transaction> transactions, DateRange range, CompareMetric metric) {
  var total = 0;
  for (final tx in transactions) {
    if (range.contains(tx.date)) total += metricValue(tx, metric);
  }
  return total;
}

/// Valore cumulato giorno per giorno: l'elemento `i` è il totale dal primo giorno di [range]
/// fino al giorno `i` incluso. La lunghezza è il numero di giorni del periodo.
List<int> cumulativeByDay(Iterable<Transaction> transactions, DateRange range, CompareMetric metric) {
  final daily = List<int>.filled(range.dayCount, 0);
  for (final tx in transactions) {
    if (!range.contains(tx.date)) continue;
    daily[range.start.daysUntil(tx.date)] += metricValue(tx, metric);
  }
  var running = 0;
  return [for (final value in daily) running += value];
}

/// Variazione percentuale di [current] rispetto a [previous] (0.12 = +12%).
/// Null se il periodo di riferimento è zero: la percentuale non avrebbe senso.
double? percentChange(int current, int previous) {
  if (previous == 0) return null;
  return (current - previous) / previous.abs();
}

/// Situazioni in cui il confronto tra importi assoluti va letto con cautela.
class ComparisonCaveats {
  const ComparisonCaveats({required this.differentLengths, required this.inProgress});

  /// I periodi non hanno tutti lo stesso numero di giorni (es. 31 e 30).
  final bool differentLengths;

  /// Periodi non ancora finiti: contengono oggi o sono nel futuro.
  final List<Period> inProgress;

  bool get any => differentLengths || inProgress.isNotEmpty;
}

/// Controlla i periodi confrontati. Non cambia i calcoli: serve solo a mostrare un avviso.
ComparisonCaveats comparisonCaveats(List<Period> periods, LocalDate today) {
  final lengths = {for (final period in periods) period.range.dayCount};
  return ComparisonCaveats(
    differentLengths: lengths.length > 1,
    inProgress: [
      for (final period in periods)
        if (!period.end.isBefore(today)) period,
    ],
  );
}
