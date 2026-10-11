// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balance_visibility.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// true = saldi nascosti in tutta l'app (patrimonio, gruppi, portafogli, scelta del portafoglio,
/// scheda Da/A e saldo della card in Movimenti). Gli importi dei movimenti restano visibili.
///
/// All'apertura segue "Saldi all'apertura" ([BalancesOnOpen]); poi lo cambia l'occhio in Portafogli.

@ProviderFor(BalancesHidden)
final balancesHiddenProvider = BalancesHiddenProvider._();

/// true = saldi nascosti in tutta l'app (patrimonio, gruppi, portafogli, scelta del portafoglio,
/// scheda Da/A e saldo della card in Movimenti). Gli importi dei movimenti restano visibili.
///
/// All'apertura segue "Saldi all'apertura" ([BalancesOnOpen]); poi lo cambia l'occhio in Portafogli.
final class BalancesHiddenProvider extends $NotifierProvider<BalancesHidden, bool> {
  /// true = saldi nascosti in tutta l'app (patrimonio, gruppi, portafogli, scelta del portafoglio,
  /// scheda Da/A e saldo della card in Movimenti). Gli importi dei movimenti restano visibili.
  ///
  /// All'apertura segue "Saldi all'apertura" ([BalancesOnOpen]); poi lo cambia l'occhio in Portafogli.
  BalancesHiddenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'balancesHiddenProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$balancesHiddenHash();

  @$internal
  @override
  BalancesHidden create() => BalancesHidden();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<bool>(value));
  }
}

String _$balancesHiddenHash() => r'2e453e0cff3521dba6164c0f4e8e9b29e617945a';

/// true = saldi nascosti in tutta l'app (patrimonio, gruppi, portafogli, scelta del portafoglio,
/// scheda Da/A e saldo della card in Movimenti). Gli importi dei movimenti restano visibili.
///
/// All'apertura segue "Saldi all'apertura" ([BalancesOnOpen]); poi lo cambia l'occhio in Portafogli.

abstract class _$BalancesHidden extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<bool, bool>, bool, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}
