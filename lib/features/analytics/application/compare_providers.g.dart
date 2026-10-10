// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compare_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Stato della tab Confronta. Parte dagli ultimi 3 mesi.

@ProviderFor(CompareController)
final compareControllerProvider = CompareControllerProvider._();

/// Stato della tab Confronta. Parte dagli ultimi 3 mesi.
final class CompareControllerProvider extends $NotifierProvider<CompareController, CompareState> {
  /// Stato della tab Confronta. Parte dagli ultimi 3 mesi.
  CompareControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'compareControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$compareControllerHash();

  @$internal
  @override
  CompareController create() => CompareController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CompareState value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<CompareState>(value));
  }
}

String _$compareControllerHash() => r'02099c2479d56570e30162d2beb0c9b00c262440';

/// Stato della tab Confronta. Parte dagli ultimi 3 mesi.

abstract class _$CompareController extends $Notifier<CompareState> {
  CompareState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CompareState, CompareState>;
    final element =
        ref.element as $ClassProviderElement<AnyNotifier<CompareState, CompareState>, CompareState, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

/// Calcola i dati di ogni periodo scelto per la grandezza scelta.

@ProviderFor(comparison)
final comparisonProvider = ComparisonProvider._();

/// Calcola i dati di ogni periodo scelto per la grandezza scelta.

final class ComparisonProvider
    extends $FunctionalProvider<AsyncValue<List<ComparedPeriod>>, List<ComparedPeriod>, FutureOr<List<ComparedPeriod>>>
    with $FutureModifier<List<ComparedPeriod>>, $FutureProvider<List<ComparedPeriod>> {
  /// Calcola i dati di ogni periodo scelto per la grandezza scelta.
  ComparisonProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'comparisonProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$comparisonHash();

  @$internal
  @override
  $FutureProviderElement<List<ComparedPeriod>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<ComparedPeriod>> create(Ref ref) {
    return comparison(ref);
  }
}

String _$comparisonHash() => r'2f9f83d51228ca9e48370ecc032cb8d31b8fd973';
