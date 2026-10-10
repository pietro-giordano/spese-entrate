import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/clock.dart';
import '../../../core/dates.dart';

part 'charts_providers.g.dart';

/// Mese mostrato nella tab Grafici (indipendente dal periodo della lista Movimenti).
@Riverpod(keepAlive: true)
class ChartsPeriod extends _$ChartsPeriod {
  @override
  Period build() => Period.containing(PeriodType.month, ref.read(todayProvider));

  void shift(int steps) => state = state.shift(steps);
}
