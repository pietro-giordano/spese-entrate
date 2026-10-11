import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/dates.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/statistics.dart';
import '../../../domain/models/transaction.dart';
import '../../../domain/services/statistics.dart';
import '../../../domain/services/transaction_list.dart';
import '../../transactions/application/transaction_providers.dart';
import 'analytics_filters.dart';

part 'statistics_providers.g.dart';

/// Movimenti del periodo che passano i filtri della tab Grafici (portafogli, categorie, label).
@riverpod
Future<List<Transaction>> chartsTransactions(Ref ref, DateRange range) async {
  final filters = ref.watch(analyticsFiltersProvider(AnalyticsTab.charts));
  return filterForAnalytics(await ref.watch(transactionsInRangeProvider(range).future), filters);
}

/// Totali al centro della ciambella, con i filtri di Grafici.
@riverpod
Future<PeriodSummary> chartsSummary(Ref ref, DateRange range) async =>
    summarize(await ref.watch(chartsTransactionsProvider(range).future), range);

/// Ciambella per categoria: spese o entrate ([kind]) del periodo, con i filtri di Grafici.
@riverpod
Future<List<BreakdownItem>> categoryBreakdown(Ref ref, DateRange range, CategoryKind kind) async =>
    breakdownByCategory(await ref.watch(chartsTransactionsProvider(range).future), range, kind);

/// Ciambella per label: un movimento con più label conta in ciascuna. Con i filtri di Grafici.
@riverpod
Future<List<BreakdownItem>> labelBreakdown(Ref ref, DateRange range, CategoryKind kind) async =>
    breakdownByLabel(await ref.watch(chartsTransactionsProvider(range).future), range, kind);
