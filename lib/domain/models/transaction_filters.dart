import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_filters.freezed.dart';

/// Tipo di movimenti da mostrare.
enum TypeFilter { all, expense, income }

/// Con più label selezionate: almeno una oppure tutte.
enum LabelMatch { any, all }

/// Filtri della lista movimenti (il periodo è a parte, in `selectedPeriodProvider`).
@freezed
abstract class TransactionFilters with _$TransactionFilters {
  const factory TransactionFilters({
    @Default(TypeFilter.all) TypeFilter type,
    @Default(<String>{}) Set<String> walletIds,
    @Default(<String>{}) Set<String> categoryIds,
    @Default(<String>{}) Set<String> labelIds,

    /// Movimenti senza nessuna label ("Senza label"). È una condizione del filtro,
    /// non una label nel database; si combina con [labelIds] secondo [labelMatch].
    @Default(false) bool withoutLabels,
    @Default(LabelMatch.any) LabelMatch labelMatch,
    @Default(true) bool showTransfers,
  }) = _TransactionFilters;

  const TransactionFilters._();

  /// Numero di filtri diversi dal predefinito (il badge sull'icona Filtri).
  int get activeCount => [
    type != TypeFilter.all,
    walletIds.isNotEmpty,
    categoryIds.isNotEmpty,
    hasLabelFilter,
    !showTransfers,
  ].where((active) => active).length;

  bool get isActive => activeCount > 0;

  /// C'è un filtro sulle label (anche solo "Senza label"): conta come un unico filtro.
  bool get hasLabelFilter => labelIds.isNotEmpty || withoutLabels;
}
