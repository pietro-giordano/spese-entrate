import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/models/transaction_filters.dart';

part 'analytics_filters.g.dart';

/// Tab con filtri propri (oltre a Movimenti, che usa `activeFiltersProvider`).
enum AnalyticsTab { charts, compare }

/// Filtri di Grafici o Confronta: ogni tab ha il suo stato, indipendente da Movimenti.
/// Contano solo portafogli, categorie e label (vedi `analyticsScope`).
@Riverpod(keepAlive: true)
class AnalyticsFilters extends _$AnalyticsFilters {
  @override
  TransactionFilters build(AnalyticsTab tab) => const TransactionFilters();

  void apply(TransactionFilters filters) => state = filters;

  void reset() => state = const TransactionFilters();

  void removeWallet(String id) => state = state.copyWith(walletIds: {...state.walletIds}..remove(id));

  void removeCategory(String id) => state = state.copyWith(categoryIds: {...state.categoryIds}..remove(id));

  void removeLabel(String id) => state = state.copyWith(labelIds: {...state.labelIds}..remove(id));

  void removeWithoutLabels() => state = state.copyWith(withoutLabels: false);
}
