import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/clock.dart';
import '../../../core/dates.dart';
import '../../transactions/application/transaction_list_providers.dart' show changePeriodType;

part 'charts_providers.g.dart';

/// Periodo della tab Grafici (indipendente da quello della lista Movimenti). Parte dal mese di oggi;
/// si cambia con lo stesso selettore Giorno/Sett./Mese/Anno/Periodo di Movimenti.
@Riverpod(keepAlive: true)
class ChartsPeriod extends _$ChartsPeriod {
  @override
  Period build() => Period.containing(PeriodType.month, ref.read(todayProvider));

  void set(Period period) => state = period;

  void changeType(PeriodType type, {required LocalDate today, required int weekStart}) =>
      state = changePeriodType(state, type, today: today, weekStart: weekStart);

  /// Frecce: un periodo avanti (1) o indietro (−1).
  void shift(int steps) => state = state.shift(steps);
}
