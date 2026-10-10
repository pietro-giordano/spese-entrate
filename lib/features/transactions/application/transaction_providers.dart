import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/dates.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/statistics.dart';
import '../../../domain/models/transaction.dart';
import '../../../domain/services/statistics.dart';

part 'transaction_providers.g.dart';

/// Tutti i movimenti non cancellati (servono ai saldi).
@riverpod
Stream<List<Transaction>> allTransactions(Ref ref) => ref.watch(transactionRepositoryProvider).watchAll();

/// Movimenti con data nel periodo, dal più recente.
@riverpod
Stream<List<Transaction>> transactionsInRange(Ref ref, DateRange range) =>
    ref.watch(transactionRepositoryProvider).watchInRange(range);

/// Entrate, uscite e saldo del periodo (solo spese ed entrate confermate).
@riverpod
Future<PeriodSummary> periodSummary(Ref ref, DateRange range) async {
  final transactions = await ref.watch(transactionsInRangeProvider(range).future);
  return summarize(transactions, range);
}
