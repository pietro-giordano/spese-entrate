// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statistics_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Ciambella per categoria: spese o entrate ([kind]) del periodo.

@ProviderFor(categoryBreakdown)
final categoryBreakdownProvider = CategoryBreakdownFamily._();

/// Ciambella per categoria: spese o entrate ([kind]) del periodo.

final class CategoryBreakdownProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BreakdownItem>>,
          List<BreakdownItem>,
          FutureOr<List<BreakdownItem>>
        >
    with
        $FutureModifier<List<BreakdownItem>>,
        $FutureProvider<List<BreakdownItem>> {
  /// Ciambella per categoria: spese o entrate ([kind]) del periodo.
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
  $FutureProviderElement<List<BreakdownItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

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

String _$categoryBreakdownHash() => r'32ecc58b6fdfad7c14027a4bb09524aee6964f46';

/// Ciambella per categoria: spese o entrate ([kind]) del periodo.

final class CategoryBreakdownFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<BreakdownItem>>,
          (DateRange, CategoryKind)
        > {
  CategoryBreakdownFamily._()
    : super(
        retry: null,
        name: r'categoryBreakdownProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Ciambella per categoria: spese o entrate ([kind]) del periodo.

  CategoryBreakdownProvider call(DateRange range, CategoryKind kind) =>
      CategoryBreakdownProvider._(argument: (range, kind), from: this);

  @override
  String toString() => r'categoryBreakdownProvider';
}

/// Ciambella per label: un movimento con più label conta in ciascuna.

@ProviderFor(labelBreakdown)
final labelBreakdownProvider = LabelBreakdownFamily._();

/// Ciambella per label: un movimento con più label conta in ciascuna.

final class LabelBreakdownProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BreakdownItem>>,
          List<BreakdownItem>,
          FutureOr<List<BreakdownItem>>
        >
    with
        $FutureModifier<List<BreakdownItem>>,
        $FutureProvider<List<BreakdownItem>> {
  /// Ciambella per label: un movimento con più label conta in ciascuna.
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
  $FutureProviderElement<List<BreakdownItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

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

String _$labelBreakdownHash() => r'b04c3b13a1d915d20115bc99db7bcb50c62a34cd';

/// Ciambella per label: un movimento con più label conta in ciascuna.

final class LabelBreakdownFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<BreakdownItem>>,
          (DateRange, CategoryKind)
        > {
  LabelBreakdownFamily._()
    : super(
        retry: null,
        name: r'labelBreakdownProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Ciambella per label: un movimento con più label conta in ciascuna.

  LabelBreakdownProvider call(DateRange range, CategoryKind kind) =>
      LabelBreakdownProvider._(argument: (range, kind), from: this);

  @override
  String toString() => r'labelBreakdownProvider';
}
