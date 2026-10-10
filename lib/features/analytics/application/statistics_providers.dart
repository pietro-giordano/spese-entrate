import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/dates.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/statistics.dart';
import '../../../domain/services/statistics.dart';
import '../../transactions/application/transaction_providers.dart';

part 'statistics_providers.g.dart';

/// Ciambella per categoria: spese o entrate ([kind]) del periodo.
@riverpod
Future<List<BreakdownItem>> categoryBreakdown(Ref ref, DateRange range, CategoryKind kind) async {
  final transactions = await ref.watch(transactionsInRangeProvider(range).future);
  return breakdownByCategory(transactions, range, kind);
}

/// Ciambella per label: un movimento con più label conta in ciascuna.
@riverpod
Future<List<BreakdownItem>> labelBreakdown(Ref ref, DateRange range, CategoryKind kind) async {
  final transactions = await ref.watch(transactionsInRangeProvider(range).future);
  return breakdownByLabel(transactions, range, kind);
}
