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

final class WalletsProvider extends $FunctionalProvider<AsyncValue<List<Wallet>>, List<Wallet>, Stream<List<Wallet>>>
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
  $StreamProviderElement<List<Wallet>> $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

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
    extends $FunctionalProvider<AsyncValue<Map<String, int>>, Map<String, int>, FutureOr<Map<String, int>>>
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
  $FutureProviderElement<Map<String, int>> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

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

final class NetWorthProvider extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
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
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return netWorth(ref);
  }
}

String _$netWorthHash() => r'8e15f06af8c66e5dd37a020b86ea0f26c664d58f';

/// Tutti i portafogli con saldo, ultimo aggiornamento e predefiniti, nell'ordine scelto.

@ProviderFor(walletOverviews)
final walletOverviewsProvider = WalletOverviewsProvider._();

/// Tutti i portafogli con saldo, ultimo aggiornamento e predefiniti, nell'ordine scelto.

final class WalletOverviewsProvider
    extends $FunctionalProvider<AsyncValue<List<WalletOverview>>, List<WalletOverview>, FutureOr<List<WalletOverview>>>
    with $FutureModifier<List<WalletOverview>>, $FutureProvider<List<WalletOverview>> {
  /// Tutti i portafogli con saldo, ultimo aggiornamento e predefiniti, nell'ordine scelto.
  WalletOverviewsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walletOverviewsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walletOverviewsHash();

  @$internal
  @override
  $FutureProviderElement<List<WalletOverview>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<WalletOverview>> create(Ref ref) {
    return walletOverviews(ref);
  }
}

String _$walletOverviewsHash() => r'8b227d388befef3e72fcb9411c92d8df1514ac82';

/// Un solo portafoglio (dettaglio e form); null se non esiste.

@ProviderFor(walletOverview)
final walletOverviewProvider = WalletOverviewFamily._();

/// Un solo portafoglio (dettaglio e form); null se non esiste.

final class WalletOverviewProvider
    extends $FunctionalProvider<AsyncValue<WalletOverview?>, WalletOverview?, FutureOr<WalletOverview?>>
    with $FutureModifier<WalletOverview?>, $FutureProvider<WalletOverview?> {
  /// Un solo portafoglio (dettaglio e form); null se non esiste.
  WalletOverviewProvider._({required WalletOverviewFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'walletOverviewProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walletOverviewHash();

  @override
  String toString() {
    return r'walletOverviewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<WalletOverview?> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<WalletOverview?> create(Ref ref) {
    final argument = this.argument as String;
    return walletOverview(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WalletOverviewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$walletOverviewHash() => r'ea2c9f9a345e3ab5b4d9ada737b69ca1601f033d';

/// Un solo portafoglio (dettaglio e form); null se non esiste.

final class WalletOverviewFamily extends $Family with $FunctionalFamilyOverride<FutureOr<WalletOverview?>, String> {
  WalletOverviewFamily._()
    : super(
        retry: null,
        name: r'walletOverviewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Un solo portafoglio (dettaglio e form); null se non esiste.

  WalletOverviewProvider call(String walletId) => WalletOverviewProvider._(argument: walletId, from: this);

  @override
  String toString() => r'walletOverviewProvider';
}

/// Movimenti che toccano il portafoglio (anche come destinazione di un trasferimento), dal più recente.

@ProviderFor(walletTransactions)
final walletTransactionsProvider = WalletTransactionsFamily._();

/// Movimenti che toccano il portafoglio (anche come destinazione di un trasferimento), dal più recente.

final class WalletTransactionsProvider
    extends $FunctionalProvider<AsyncValue<List<Transaction>>, List<Transaction>, FutureOr<List<Transaction>>>
    with $FutureModifier<List<Transaction>>, $FutureProvider<List<Transaction>> {
  /// Movimenti che toccano il portafoglio (anche come destinazione di un trasferimento), dal più recente.
  WalletTransactionsProvider._({required WalletTransactionsFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'walletTransactionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walletTransactionsHash();

  @override
  String toString() {
    return r'walletTransactionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Transaction>> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Transaction>> create(Ref ref) {
    final argument = this.argument as String;
    return walletTransactions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WalletTransactionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$walletTransactionsHash() => r'929e40b02716b86e611eb71474878449af3c7963';

/// Movimenti che toccano il portafoglio (anche come destinazione di un trasferimento), dal più recente.

final class WalletTransactionsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Transaction>>, String> {
  WalletTransactionsFamily._()
    : super(
        retry: null,
        name: r'walletTransactionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Movimenti che toccano il portafoglio (anche come destinazione di un trasferimento), dal più recente.

  WalletTransactionsProvider call(String walletId) => WalletTransactionsProvider._(argument: walletId, from: this);

  @override
  String toString() => r'walletTransactionsProvider';
}

/// Andamento del saldo negli ultimi 6 mesi.

@ProviderFor(walletBalanceHistory)
final walletBalanceHistoryProvider = WalletBalanceHistoryFamily._();

/// Andamento del saldo negli ultimi 6 mesi.

final class WalletBalanceHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<({int balanceCents, LocalDate date})>>,
          List<({int balanceCents, LocalDate date})>,
          FutureOr<List<({int balanceCents, LocalDate date})>>
        >
    with
        $FutureModifier<List<({int balanceCents, LocalDate date})>>,
        $FutureProvider<List<({int balanceCents, LocalDate date})>> {
  /// Andamento del saldo negli ultimi 6 mesi.
  WalletBalanceHistoryProvider._({required WalletBalanceHistoryFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'walletBalanceHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walletBalanceHistoryHash();

  @override
  String toString() {
    return r'walletBalanceHistoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<({int balanceCents, LocalDate date})>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<({int balanceCents, LocalDate date})>> create(Ref ref) {
    final argument = this.argument as String;
    return walletBalanceHistory(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WalletBalanceHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$walletBalanceHistoryHash() => r'60f6c8057dae2e8ee9ca956848e87dcec00ff7d2';

/// Andamento del saldo negli ultimi 6 mesi.

final class WalletBalanceHistoryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<({int balanceCents, LocalDate date})>>, String> {
  WalletBalanceHistoryFamily._()
    : super(
        retry: null,
        name: r'walletBalanceHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Andamento del saldo negli ultimi 6 mesi.

  WalletBalanceHistoryProvider call(String walletId) => WalletBalanceHistoryProvider._(argument: walletId, from: this);

  @override
  String toString() => r'walletBalanceHistoryProvider';
}

@ProviderFor(walletActions)
final walletActionsProvider = WalletActionsProvider._();

final class WalletActionsProvider extends $FunctionalProvider<WalletActions, WalletActions, WalletActions>
    with $Provider<WalletActions> {
  WalletActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walletActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walletActionsHash();

  @$internal
  @override
  $ProviderElement<WalletActions> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  WalletActions create(Ref ref) {
    return walletActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WalletActions value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<WalletActions>(value));
  }
}

String _$walletActionsHash() => r'08294bcd06297737f974f4b5370b71fce2016bea';
