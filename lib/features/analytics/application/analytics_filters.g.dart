// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_filters.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Filtri di Grafici o Confronta: ogni tab ha il suo stato, indipendente da Movimenti.
/// Contano solo portafogli, categorie e label (vedi `analyticsScope`).

@ProviderFor(AnalyticsFilters)
final analyticsFiltersProvider = AnalyticsFiltersFamily._();

/// Filtri di Grafici o Confronta: ogni tab ha il suo stato, indipendente da Movimenti.
/// Contano solo portafogli, categorie e label (vedi `analyticsScope`).
final class AnalyticsFiltersProvider extends $NotifierProvider<AnalyticsFilters, TransactionFilters> {
  /// Filtri di Grafici o Confronta: ogni tab ha il suo stato, indipendente da Movimenti.
  /// Contano solo portafogli, categorie e label (vedi `analyticsScope`).
  AnalyticsFiltersProvider._({required AnalyticsFiltersFamily super.from, required AnalyticsTab super.argument})
    : super(
        retry: null,
        name: r'analyticsFiltersProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analyticsFiltersHash();

  @override
  String toString() {
    return r'analyticsFiltersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AnalyticsFilters create() => AnalyticsFilters();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransactionFilters value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<TransactionFilters>(value));
  }

  @override
  bool operator ==(Object other) {
    return other is AnalyticsFiltersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$analyticsFiltersHash() => r'f77a478cbb19e8aa1d9ca8f903ec4235981d44e4';

/// Filtri di Grafici o Confronta: ogni tab ha il suo stato, indipendente da Movimenti.
/// Contano solo portafogli, categorie e label (vedi `analyticsScope`).

final class AnalyticsFiltersFamily extends $Family
    with
        $ClassFamilyOverride<
          AnalyticsFilters,
          TransactionFilters,
          TransactionFilters,
          TransactionFilters,
          AnalyticsTab
        > {
  AnalyticsFiltersFamily._()
    : super(
        retry: null,
        name: r'analyticsFiltersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Filtri di Grafici o Confronta: ogni tab ha il suo stato, indipendente da Movimenti.
  /// Contano solo portafogli, categorie e label (vedi `analyticsScope`).

  AnalyticsFiltersProvider call(AnalyticsTab tab) => AnalyticsFiltersProvider._(argument: tab, from: this);

  @override
  String toString() => r'analyticsFiltersProvider';
}

/// Filtri di Grafici o Confronta: ogni tab ha il suo stato, indipendente da Movimenti.
/// Contano solo portafogli, categorie e label (vedi `analyticsScope`).

abstract class _$AnalyticsFilters extends $Notifier<TransactionFilters> {
  late final _$args = ref.$arg as AnalyticsTab;
  AnalyticsTab get tab => _$args;

  TransactionFilters build(AnalyticsTab tab);
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
    return element.handleCreate(ref, () => build(_$args));
  }
}
