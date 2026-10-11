// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statistics_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Movimenti del periodo che passano i filtri della tab Grafici (portafogli, categorie, label).

@ProviderFor(chartsTransactions)
final chartsTransactionsProvider = ChartsTransactionsFamily._();

/// Movimenti del periodo che passano i filtri della tab Grafici (portafogli, categorie, label).

final class ChartsTransactionsProvider
    extends $FunctionalProvider<AsyncValue<List<Transaction>>, List<Transaction>, FutureOr<List<Transaction>>>
    with $FutureModifier<List<Transaction>>, $FutureProvider<List<Transaction>> {
  /// Movimenti del periodo che passano i filtri della tab Grafici (portafogli, categorie, label).
  ChartsTransactionsProvider._({required ChartsTransactionsFamily super.from, required DateRange super.argument})
    : super(
        retry: null,
        name: r'chartsTransactionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chartsTransactionsHash();

  @override
  String toString() {
    return r'chartsTransactionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Transaction>> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Transaction>> create(Ref ref) {
    final argument = this.argument as DateRange;
    return chartsTransactions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ChartsTransactionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chartsTransactionsHash() => r'75f08dea7e8b973655c564a58c434f49312e4efe';

/// Movimenti del periodo che passano i filtri della tab Grafici (portafogli, categorie, label).

final class ChartsTransactionsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Transaction>>, DateRange> {
  ChartsTransactionsFamily._()
    : super(
        retry: null,
        name: r'chartsTransactionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Movimenti del periodo che passano i filtri della tab Grafici (portafogli, categorie, label).

  ChartsTransactionsProvider call(DateRange range) => ChartsTransactionsProvider._(argument: range, from: this);

  @override
  String toString() => r'chartsTransactionsProvider';
}

/// Totali al centro della ciambella, con i filtri di Grafici.

@ProviderFor(chartsSummary)
final chartsSummaryProvider = ChartsSummaryFamily._();

/// Totali al centro della ciambella, con i filtri di Grafici.

final class ChartsSummaryProvider
    extends $FunctionalProvider<AsyncValue<PeriodSummary>, PeriodSummary, FutureOr<PeriodSummary>>
    with $FutureModifier<PeriodSummary>, $FutureProvider<PeriodSummary> {
  /// Totali al centro della ciambella, con i filtri di Grafici.
  ChartsSummaryProvider._({required ChartsSummaryFamily super.from, required DateRange super.argument})
    : super(
        retry: null,
        name: r'chartsSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chartsSummaryHash();

  @override
  String toString() {
    return r'chartsSummaryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PeriodSummary> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<PeriodSummary> create(Ref ref) {
    final argument = this.argument as DateRange;
    return chartsSummary(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ChartsSummaryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chartsSummaryHash() => r'48bbda0a59ff0c882059f24e3b40049e295000a4';

/// Totali al centro della ciambella, con i filtri di Grafici.

final class ChartsSummaryFamily extends $Family with $FunctionalFamilyOverride<FutureOr<PeriodSummary>, DateRange> {
  ChartsSummaryFamily._()
    : super(
        retry: null,
        name: r'chartsSummaryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Totali al centro della ciambella, con i filtri di Grafici.

  ChartsSummaryProvider call(DateRange range) => ChartsSummaryProvider._(argument: range, from: this);

  @override
  String toString() => r'chartsSummaryProvider';
}

/// Ciambella per categoria: spese o entrate ([kind]) del periodo, con i filtri di Grafici.

@ProviderFor(categoryBreakdown)
final categoryBreakdownProvider = CategoryBreakdownFamily._();

/// Ciambella per categoria: spese o entrate ([kind]) del periodo, con i filtri di Grafici.

final class CategoryBreakdownProvider
    extends $FunctionalProvider<AsyncValue<List<BreakdownItem>>, List<BreakdownItem>, FutureOr<List<BreakdownItem>>>
    with $FutureModifier<List<BreakdownItem>>, $FutureProvider<List<BreakdownItem>> {
  /// Ciambella per categoria: spese o entrate ([kind]) del periodo, con i filtri di Grafici.
  CategoryBreakdownProvider._({
    required CategoryBreakdownFamily super.from,
    required (DateRange, CategoryKind) super.argument,
  }) : super(
         retry: null,
         name: r'categoryBreakdownProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$categoryBreakdownHash();

  @override
  String toString() {
    return r'categoryBreakdownProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<BreakdownItem>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<BreakdownItem>> create(Ref ref) {
    final argument = this.argument as (DateRange, CategoryKind);
    return categoryBreakdown(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is CategoryBreakdownProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$categoryBreakdownHash() => r'cbf1e9ea1f2da559ca49b71a00fcc9ef79122e06';

/// Ciambella per categoria: spese o entrate ([kind]) del periodo, con i filtri di Grafici.

final class CategoryBreakdownFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<BreakdownItem>>, (DateRange, CategoryKind)> {
  CategoryBreakdownFamily._()
    : super(
        retry: null,
        name: r'categoryBreakdownProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Ciambella per categoria: spese o entrate ([kind]) del periodo, con i filtri di Grafici.

  CategoryBreakdownProvider call(DateRange range, CategoryKind kind) =>
      CategoryBreakdownProvider._(argument: (range, kind), from: this);

  @override
  String toString() => r'categoryBreakdownProvider';
}

/// Ciambella per label: un movimento con più label conta in ciascuna. Con i filtri di Grafici.

@ProviderFor(labelBreakdown)
final labelBreakdownProvider = LabelBreakdownFamily._();

/// Ciambella per label: un movimento con più label conta in ciascuna. Con i filtri di Grafici.

final class LabelBreakdownProvider
    extends $FunctionalProvider<AsyncValue<List<BreakdownItem>>, List<BreakdownItem>, FutureOr<List<BreakdownItem>>>
    with $FutureModifier<List<BreakdownItem>>, $FutureProvider<List<BreakdownItem>> {
  /// Ciambella per label: un movimento con più label conta in ciascuna. Con i filtri di Grafici.
  LabelBreakdownProvider._({
    required LabelBreakdownFamily super.from,
    required (DateRange, CategoryKind) super.argument,
  }) : super(
         retry: null,
         name: r'labelBreakdownProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$labelBreakdownHash();

  @override
  String toString() {
    return r'labelBreakdownProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<BreakdownItem>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<BreakdownItem>> create(Ref ref) {
    final argument = this.argument as (DateRange, CategoryKind);
    return labelBreakdown(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is LabelBreakdownProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$labelBreakdownHash() => r'5b2da97b4f91660f27d4d30e5f3aacd95186402d';

/// Ciambella per label: un movimento con più label conta in ciascuna. Con i filtri di Grafici.

final class LabelBreakdownFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<BreakdownItem>>, (DateRange, CategoryKind)> {
  LabelBreakdownFamily._()
    : super(
        retry: null,
        name: r'labelBreakdownProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Ciambella per label: un movimento con più label conta in ciascuna. Con i filtri di Grafici.

  LabelBreakdownProvider call(DateRange range, CategoryKind kind) =>
      LabelBreakdownProvider._(argument: (range, kind), from: this);

  @override
  String toString() => r'labelBreakdownProvider';
}
