import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/models/category.dart';
import '../../../domain/models/label.dart';
import '../../../domain/models/transaction.dart';
import '../../../domain/models/wallet.dart';
import '../../../domain/services/transaction_list.dart';
import '../../../domain/services/transaction_search.dart';
import '../../settings/application/settings_providers.dart';
import '../../wallets/application/wallet_providers.dart';
import 'transaction_list_providers.dart';
import 'transaction_providers.dart';

part 'search_providers.g.dart';

/// Ricerca in Movimenti: aperta o chiusa, e il testo cercato (già "debounced" dalla schermata).
class SearchState {
  const SearchState({this.open = false, this.query = ''});

  final bool open;
  final String query;
}

@Riverpod(keepAlive: true)
class TransactionSearch extends _$TransactionSearch {
  @override
  SearchState build() => const SearchState();

  void open() => state = const SearchState(open: true);

  /// Chiude e dimentica il testo: la lista torna quella del periodo.
  void close() => state = const SearchState();

  void setQuery(String query) => state = SearchState(open: true, query: query);
}

/// Risultati su tutto lo storico, con i filtri attivi, dal più recente.
@riverpod
Future<List<Transaction>> searchResults(Ref ref) async {
  final query = SearchQuery(ref.watch(transactionSearchProvider).query);
  if (query.isEmpty) return const [];
  final filters = ref.watch(activeFiltersProvider);
  final names = SearchNames(
    wallets: {for (final Wallet w in await ref.watch(walletsProvider.future)) w.id: w.name},
    categories: {for (final Category c in await ref.watch(categoriesProvider.future)) c.id: c.name},
    labels: {for (final Label l in await ref.watch(labelsProvider.future)) l.id: l.name},
  );
  final all = await ref.watch(allTransactionsProvider.future);
  return searchTransactions(all, query, names: names, filters: filters);
}

/// Risultati raggruppati per giorno, come la lista normale.
@riverpod
Future<List<DayGroup>> searchDayGroups(Ref ref) async => groupByDay(await ref.watch(searchResultsProvider.future));
