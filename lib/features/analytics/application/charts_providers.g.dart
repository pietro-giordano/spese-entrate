// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'charts_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Mese mostrato nella tab Grafici (indipendente dal periodo della lista Movimenti).

@ProviderFor(ChartsPeriod)
final chartsPeriodProvider = ChartsPeriodProvider._();

/// Mese mostrato nella tab Grafici (indipendente dal periodo della lista Movimenti).
final class ChartsPeriodProvider extends $NotifierProvider<ChartsPeriod, Period> {
  /// Mese mostrato nella tab Grafici (indipendente dal periodo della lista Movimenti).
  ChartsPeriodProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chartsPeriodProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chartsPeriodHash();

  @$internal
  @override
  ChartsPeriod create() => ChartsPeriod();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Period value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<Period>(value));
  }
}

String _$chartsPeriodHash() => r'dcdf54147901e6140f29e3813de972eca09c3532';

/// Mese mostrato nella tab Grafici (indipendente dal periodo della lista Movimenti).

abstract class _$ChartsPeriod extends $Notifier<Period> {
  Period build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Period, Period>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<Period, Period>, Period, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}
