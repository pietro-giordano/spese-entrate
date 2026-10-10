import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/wallet.dart';
// Prefisso: le funzioni del servizio hanno gli stessi nomi dei provider qui sotto.
import '../../../domain/services/balances.dart' as balances;
import '../../transactions/application/transaction_providers.dart';

part 'wallet_providers.g.dart';

/// Portafogli non cancellati, archiviati compresi.
@riverpod
Stream<List<Wallet>> wallets(Ref ref) => ref.watch(walletRepositoryProvider).watchAll();

/// Saldo di ogni portafoglio, per ID. Si ricalcola quando cambiano portafogli o movimenti.
@riverpod
Future<Map<String, int>> walletBalances(Ref ref) async {
  final wallets = await ref.watch(walletsProvider.future);
  final transactions = await ref.watch(allTransactionsProvider.future);
  return balances.walletBalances(wallets, transactions);
}

/// Patrimonio totale (portafogli inclusi nel totale e non archiviati).
@riverpod
Future<int> netWorth(Ref ref) async {
  final wallets = await ref.watch(walletsProvider.future);
  final walletBalances = await ref.watch(walletBalancesProvider.future);
  return balances.netWorth(wallets, walletBalances);
}
