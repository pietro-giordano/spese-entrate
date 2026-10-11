// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'charts_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Periodo della tab Grafici (indipendente da quello della lista Movimenti). Parte dal mese di oggi;
/// si cambia con lo stesso selettore Giorno/Sett./Mese/Anno/Periodo di Movimenti.

@ProviderFor(ChartsPeriod)
final chartsPeriodProvider = ChartsPeriodProvider._();

/// Periodo della tab Grafici (indipendente da quello della lista Movimenti). Parte dal mese di oggi;
/// si cambia con lo stesso selettore Giorno/Sett./Mese/Anno/Periodo di Movimenti.
final class ChartsPeriodProvider extends $NotifierProvider<ChartsPeriod, Period> {
  /// Periodo della tab Grafici (indipendente da quello della lista Movimenti). Parte dal mese di oggi;
  /// si cambia con lo stesso selettore Giorno/Sett./Mese/Anno/Periodo di Movimenti.
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

String _$chartsPeriodHash() => r'2da6e2a3e6f8c4f482559a51e56f45cffacc0cda';

/// Periodo della tab Grafici (indipendente da quello della lista Movimenti). Parte dal mese di oggi;
/// si cambia con lo stesso selettore Giorno/Sett./Mese/Anno/Periodo di Movimenti.

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
