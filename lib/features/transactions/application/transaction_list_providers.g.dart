// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_list_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Periodo scelto, condiviso tra la tab Movimenti e la schermata Filtri.
/// Parte dalla "vista predefinita" delle impostazioni (di base il mese) che contiene oggi.

@ProviderFor(SelectedPeriod)
final selectedPeriodProvider = SelectedPeriodProvider._();

/// Periodo scelto, condiviso tra la tab Movimenti e la schermata Filtri.
/// Parte dalla "vista predefinita" delle impostazioni (di base il mese) che contiene oggi.
final class SelectedPeriodProvider extends $NotifierProvider<SelectedPeriod, Period> {
  /// Periodo scelto, condiviso tra la tab Movimenti e la schermata Filtri.
  /// Parte dalla "vista predefinita" delle impostazioni (di base il mese) che contiene oggi.
  SelectedPeriodProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedPeriodProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedPeriodHash();

  @$internal
  @override
  SelectedPeriod create() => SelectedPeriod();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Period value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<Period>(value));
  }
}

String _$selectedPeriodHash() => r'7a8d984d98e6573e17324fc604abaddf93ebf48e';

/// Periodo scelto, condiviso tra la tab Movimenti e la schermata Filtri.
/// Parte dalla "vista predefinita" delle impostazioni (di base il mese) che contiene oggi.

abstract class _$SelectedPeriod extends $Notifier<Period> {
  Period build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Period, Period>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<Period, Period>, Period, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

/// Filtri attivi, condivisi tra la tab Movimenti e la schermata Filtri.

@ProviderFor(ActiveFilters)
final activeFiltersProvider = ActiveFiltersProvider._();

/// Filtri attivi, condivisi tra la tab Movimenti e la schermata Filtri.
final class ActiveFiltersProvider extends $NotifierProvider<ActiveFilters, TransactionFilters> {
  /// Filtri attivi, condivisi tra la tab Movimenti e la schermata Filtri.
  ActiveFiltersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeFiltersProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeFiltersHash();

  @$internal
  @override
  ActiveFilters create() => ActiveFilters();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransactionFilters value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<TransactionFilters>(value));
  }
}

String _$activeFiltersHash() => r'c1dc31d97e7e6f302296074085bed2b3c7ef6746';

/// Filtri attivi, condivisi tra la tab Movimenti e la schermata Filtri.

abstract class _$ActiveFilters extends $Notifier<TransactionFilters> {
  TransactionFilters build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TransactionFilters, TransactionFilters>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TransactionFilters, TransactionFilters>,
              TransactionFilters,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Movimenti confermati del periodo che passano i filtri, dal più recente.
/// I `pending` sono esclusi: compariranno nella sezione "In arrivo".

@ProviderFor(visibleTransactions)
final visibleTransactionsProvider = VisibleTransactionsProvider._();

/// Movimenti confermati del periodo che passano i filtri, dal più recente.
/// I `pending` sono esclusi: compariranno nella sezione "In arrivo".

final class VisibleTransactionsProvider
    extends $FunctionalProvider<AsyncValue<List<Transaction>>, List<Transaction>, FutureOr<List<Transaction>>>
    with $FutureModifier<List<Transaction>>, $FutureProvider<List<Transaction>> {
  /// Movimenti confermati del periodo che passano i filtri, dal più recente.
  /// I `pending` sono esclusi: compariranno nella sezione "In arrivo".
  VisibleTransactionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visibleTransactionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$visibleTransactionsHash();

  @$internal
  @override
  $FutureProviderElement<List<Transaction>> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Transaction>> create(Ref ref) {
    return visibleTransactions(ref);
  }
}

String _$visibleTransactionsHash() => r'73d99845c2e0700411cbd77cba2792dacf442703';

/// Riepilogo del periodo (entrate, uscite, saldo) sui movimenti visibili.

@ProviderFor(visibleSummary)
final visibleSummaryProvider = VisibleSummaryProvider._();

/// Riepilogo del periodo (entrate, uscite, saldo) sui movimenti visibili.

final class VisibleSummaryProvider
    extends $FunctionalProvider<AsyncValue<PeriodSummary>, PeriodSummary, FutureOr<PeriodSummary>>
    with $FutureModifier<PeriodSummary>, $FutureProvider<PeriodSummary> {
  /// Riepilogo del periodo (entrate, uscite, saldo) sui movimenti visibili.
  VisibleSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visibleSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$visibleSummaryHash();

  @$internal
  @override
  $FutureProviderElement<PeriodSummary> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<PeriodSummary> create(Ref ref) {
    return visibleSummary(ref);
  }
}

String _$visibleSummaryHash() => r'c7ee732711d91ee28b4c4c462433c734af6350a0';

/// Lista raggruppata per giorno con il totale giornaliero.

@ProviderFor(visibleDayGroups)
final visibleDayGroupsProvider = VisibleDayGroupsProvider._();

/// Lista raggruppata per giorno con il totale giornaliero.

final class VisibleDayGroupsProvider
    extends $FunctionalProvider<AsyncValue<List<DayGroup>>, List<DayGroup>, FutureOr<List<DayGroup>>>
    with $FutureModifier<List<DayGroup>>, $FutureProvider<List<DayGroup>> {
  /// Lista raggruppata per giorno con il totale giornaliero.
  VisibleDayGroupsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visibleDayGroupsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$visibleDayGroupsHash();

  @$internal
  @override
  $FutureProviderElement<List<DayGroup>> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<DayGroup>> create(Ref ref) {
    return visibleDayGroups(ref);
  }
}

String _$visibleDayGroupsHash() => r'3e57c887fc915635857d2e6f5f5a8447d3c08d16';
