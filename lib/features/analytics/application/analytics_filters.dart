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

  /// Toglie il filtro su un portafoglio, una categoria o una label, che fosse un'inclusione
  /// o un'esclusione.
  void removeWallet(String id) => state = state.copyWith(
    walletIds: {...state.walletIds}..remove(id),
    excludedWalletIds: {...state.excludedWalletIds}..remove(id),
  );

  void removeCategory(String id) => state = state.copyWith(
    categoryIds: {...state.categoryIds}..remove(id),
    excludedCategoryIds: {...state.excludedCategoryIds}..remove(id),
  );

  void removeLabel(String id) => state = state.copyWith(
    labelIds: {...state.labelIds}..remove(id),
    excludedLabelIds: {...state.excludedLabelIds}..remove(id),
  );

  void removeWithoutLabels() => state = state.copyWith(withoutLabels: false, excludeWithoutLabels: false);
}
