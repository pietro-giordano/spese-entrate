import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_filters.freezed.dart';

/// Tipo di movimenti da mostrare.
enum TypeFilter { all, expense, income }

/// Con più label selezionate: almeno una oppure tutte.
enum LabelMatch { any, all }

/// Stato di un chip dei filtri: si tocca per passare da uno all'altro, in quest'ordine.
enum FilterChipState {
  neutral,
  included,
  excluded;

  /// neutro → incluso → escluso → neutro.
  FilterChipState get next => switch (this) {
    neutral => included,
    included => excluded,
    excluded => neutral,
  };
}

/// Filtri della lista movimenti (il periodo è a parte, in `selectedPeriodProvider`).
@freezed
abstract class TransactionFilters with _$TransactionFilters {
  const factory TransactionFilters({
    @Default(TypeFilter.all) TypeFilter type,
    @Default(<String>{}) Set<String> walletIds,
    @Default(<String>{}) Set<String> categoryIds,
    @Default(<String>{}) Set<String> labelIds,

    /// Esclusioni: un movimento con uno di questi portafogli, categorie o label non compare mai,
    /// anche se è incluso da un altro filtro (l'esclusione vince).
    @Default(<String>{}) Set<String> excludedWalletIds,
    @Default(<String>{}) Set<String> excludedCategoryIds,
    @Default(<String>{}) Set<String> excludedLabelIds,

    /// "Senza label" incluso: aggiunge le spese e le entrate senza nessuna label. È una condizione
    /// sull'assenza di label, non una label nel database: [labelMatch] vale solo per [labelIds].
    @Default(false) bool withoutLabels,

    /// "Senza label" escluso: toglie le spese e le entrate senza nessuna label.
    @Default(false) bool excludeWithoutLabels,
    @Default(LabelMatch.any) LabelMatch labelMatch,
    @Default(true) bool showTransfers,
  }) = _TransactionFilters;

  const TransactionFilters._();

  /// Numero di filtri diversi dal predefinito (il badge sull'icona Filtri).
  /// Inclusioni ed esclusioni della stessa sezione contano come un solo filtro.
  int get activeCount => [
    type != TypeFilter.all,
    walletIds.isNotEmpty || excludedWalletIds.isNotEmpty,
    categoryIds.isNotEmpty || excludedCategoryIds.isNotEmpty,
    hasLabelFilter || excludedLabelIds.isNotEmpty || excludeWithoutLabels,
    !showTransfers,
  ].where((active) => active).length;

  bool get isActive => activeCount > 0;

  /// C'è un'inclusione sulle label (anche solo "Senza label"). Le esclusioni sono a parte.
  bool get hasLabelFilter => labelIds.isNotEmpty || withoutLabels;

  /// Stato del chip di un portafoglio, una categoria o una label.
  FilterChipState walletState(String id) => _state(id, walletIds, excludedWalletIds);
  FilterChipState categoryState(String id) => _state(id, categoryIds, excludedCategoryIds);
  FilterChipState labelState(String id) => _state(id, labelIds, excludedLabelIds);
  FilterChipState get withoutLabelsState => excludeWithoutLabels
      ? FilterChipState.excluded
      : withoutLabels
      ? FilterChipState.included
      : FilterChipState.neutral;

  /// Passa il chip allo stato successivo (neutro → incluso → escluso → neutro).
  TransactionFilters cycleWallet(String id) {
    final (included, excluded) = _cycle(id, walletIds, excludedWalletIds);
    return copyWith(walletIds: included, excludedWalletIds: excluded);
  }

  TransactionFilters cycleCategory(String id) {
    final (included, excluded) = _cycle(id, categoryIds, excludedCategoryIds);
    return copyWith(categoryIds: included, excludedCategoryIds: excluded);
  }

  TransactionFilters cycleLabel(String id) {
    final (included, excluded) = _cycle(id, labelIds, excludedLabelIds);
    return copyWith(labelIds: included, excludedLabelIds: excluded);
  }

  TransactionFilters cycleWithoutLabels() {
    final next = withoutLabelsState.next;
    return copyWith(
      withoutLabels: next == FilterChipState.included,
      excludeWithoutLabels: next == FilterChipState.excluded,
    );
  }

  static (Set<String>, Set<String>) _cycle(String id, Set<String> included, Set<String> excluded) {
    final next = _state(id, included, excluded).next;
    return (
      next == FilterChipState.included ? {...included, id} : ({...included}..remove(id)),
      next == FilterChipState.excluded ? {...excluded, id} : ({...excluded}..remove(id)),
    );
  }

  static FilterChipState _state(String id, Set<String> included, Set<String> excluded) => excluded.contains(id)
      ? FilterChipState.excluded
      : included.contains(id)
      ? FilterChipState.included
      : FilterChipState.neutral;
}
