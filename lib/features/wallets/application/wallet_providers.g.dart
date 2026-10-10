// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Portafogli non cancellati, archiviati compresi.

@ProviderFor(wallets)
final walletsProvider = WalletsProvider._();

/// Portafogli non cancellati, archiviati compresi.

final class WalletsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Wallet>>,
          List<Wallet>,
          Stream<List<Wallet>>
        >
    with $FutureModifier<List<Wallet>>, $StreamProvider<List<Wallet>> {
  /// Portafogli non cancellati, archiviati compresi.
  WalletsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walletsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walletsHash();

  @$internal
  @override
  $StreamProviderElement<List<Wallet>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Wallet>> create(Ref ref) {
    return wallets(ref);
  }
}

String _$walletsHash() => r'cc0e1245b08bcbcb17eb94bc1ebb89f430582d4e';

/// Saldo di ogni portafoglio, per ID. Si ricalcola quando cambiano portafogli o movimenti.

@ProviderFor(walletBalances)
final walletBalancesProvider = WalletBalancesProvider._();

/// Saldo di ogni portafoglio, per ID. Si ricalcola quando cambiano portafogli o movimenti.

final class WalletBalancesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, int>>,
          Map<String, int>,
          FutureOr<Map<String, int>>
        >
    with $FutureModifier<Map<String, int>>, $FutureProvider<Map<String, int>> {
  /// Saldo di ogni portafoglio, per ID. Si ricalcola quando cambiano portafogli o movimenti.
  WalletBalancesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walletBalancesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walletBalancesHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, int>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, int>> create(Ref ref) {
    return walletBalances(ref);
  }
}

String _$walletBalancesHash() => r'ad747e545d583647727ffb7fd06b8e9b2c7840c3';

/// Patrimonio totale (portafogli inclusi nel totale e non archiviati).

@ProviderFor(netWorth)
final netWorthProvider = NetWorthProvider._();

/// Patrimonio totale (portafogli inclusi nel totale e non archiviati).

final class NetWorthProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Patrimonio totale (portafogli inclusi nel totale e non archiviati).
  NetWorthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'netWorthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$netWorthHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return netWorth(ref);
  }
}

String _$netWorthHash() => r'8e15f06af8c66e5dd37a020b86ea0f26c664d58f';
