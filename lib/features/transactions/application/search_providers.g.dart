// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TransactionSearch)
final transactionSearchProvider = TransactionSearchProvider._();

final class TransactionSearchProvider extends $NotifierProvider<TransactionSearch, SearchState> {
  TransactionSearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionSearchProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionSearchHash();

  @$internal
  @override
  TransactionSearch create() => TransactionSearch();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchState value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<SearchState>(value));
  }
}

String _$transactionSearchHash() => r'f3c8d8bd7103fb77146068aae159d1742ef0d76d';

abstract class _$TransactionSearch extends $Notifier<SearchState> {
  SearchState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SearchState, SearchState>;
    final element =
        ref.element as $ClassProviderElement<AnyNotifier<SearchState, SearchState>, SearchState, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

/// Risultati su tutto lo storico, con i filtri attivi, dal più recente.

@ProviderFor(searchResults)
final searchResultsProvider = SearchResultsProvider._();

/// Risultati su tutto lo storico, con i filtri attivi, dal più recente.

final class SearchResultsProvider
    extends $FunctionalProvider<AsyncValue<List<Transaction>>, List<Transaction>, FutureOr<List<Transaction>>>
    with $FutureModifier<List<Transaction>>, $FutureProvider<List<Transaction>> {
  /// Risultati su tutto lo storico, con i filtri attivi, dal più recente.
  SearchResultsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchResultsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchResultsHash();

  @$internal
  @override
  $FutureProviderElement<List<Transaction>> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Transaction>> create(Ref ref) {
    return searchResults(ref);
  }
}

String _$searchResultsHash() => r'8b0c607bdeee93260074cbe2c8789efb174ad454';

/// Risultati raggruppati per giorno, come la lista normale.

@ProviderFor(searchDayGroups)
final searchDayGroupsProvider = SearchDayGroupsProvider._();

/// Risultati raggruppati per giorno, come la lista normale.

final class SearchDayGroupsProvider
    extends $FunctionalProvider<AsyncValue<List<DayGroup>>, List<DayGroup>, FutureOr<List<DayGroup>>>
    with $FutureModifier<List<DayGroup>>, $FutureProvider<List<DayGroup>> {
  /// Risultati raggruppati per giorno, come la lista normale.
  SearchDayGroupsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchDayGroupsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchDayGroupsHash();

  @$internal
  @override
  $FutureProviderElement<List<DayGroup>> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<DayGroup>> create(Ref ref) {
    return searchDayGroups(ref);
  }
}

String _$searchDayGroupsHash() => r'dc1e9e1a4cbb599d67e4d76ce60bb7b50a6e6744';
