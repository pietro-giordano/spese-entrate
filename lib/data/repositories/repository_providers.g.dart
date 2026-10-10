// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(walletRepository)
final walletRepositoryProvider = WalletRepositoryProvider._();

final class WalletRepositoryProvider extends $FunctionalProvider<WalletRepository, WalletRepository, WalletRepository>
    with $Provider<WalletRepository> {
  WalletRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walletRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walletRepositoryHash();

  @$internal
  @override
  $ProviderElement<WalletRepository> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  WalletRepository create(Ref ref) {
    return walletRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WalletRepository value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<WalletRepository>(value));
  }
}

String _$walletRepositoryHash() => r'a50b5ded23d760641ca16c68aca684645b6b7de1';

@ProviderFor(categoryRepository)
final categoryRepositoryProvider = CategoryRepositoryProvider._();

final class CategoryRepositoryProvider
    extends $FunctionalProvider<CategoryRepository, CategoryRepository, CategoryRepository>
    with $Provider<CategoryRepository> {
  CategoryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryRepositoryHash();

  @$internal
  @override
  $ProviderElement<CategoryRepository> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  CategoryRepository create(Ref ref) {
    return categoryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategoryRepository value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<CategoryRepository>(value));
  }
}

String _$categoryRepositoryHash() => r'537c6fc33bf30e1d12776c09770f0fc09d5db398';

@ProviderFor(labelRepository)
final labelRepositoryProvider = LabelRepositoryProvider._();

final class LabelRepositoryProvider extends $FunctionalProvider<LabelRepository, LabelRepository, LabelRepository>
    with $Provider<LabelRepository> {
  LabelRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'labelRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$labelRepositoryHash();

  @$internal
  @override
  $ProviderElement<LabelRepository> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  LabelRepository create(Ref ref) {
    return labelRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LabelRepository value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<LabelRepository>(value));
  }
}

String _$labelRepositoryHash() => r'794446753310f207f0043ce01bff8dfbf55d1399';

@ProviderFor(transactionRepository)
final transactionRepositoryProvider = TransactionRepositoryProvider._();

final class TransactionRepositoryProvider
    extends $FunctionalProvider<TransactionRepository, TransactionRepository, TransactionRepository>
    with $Provider<TransactionRepository> {
  TransactionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionRepositoryHash();

  @$internal
  @override
  $ProviderElement<TransactionRepository> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  TransactionRepository create(Ref ref) {
    return transactionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransactionRepository value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<TransactionRepository>(value));
  }
}

String _$transactionRepositoryHash() => r'78244cdf1f73d1d9dd6d0020e29608852925355e';

@ProviderFor(settingsRepository)
final settingsRepositoryProvider = SettingsRepositoryProvider._();

final class SettingsRepositoryProvider
    extends $FunctionalProvider<SettingsRepository, SettingsRepository, SettingsRepository>
    with $Provider<SettingsRepository> {
  SettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SettingsRepository> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  SettingsRepository create(Ref ref) {
    return settingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsRepository value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<SettingsRepository>(value));
  }
}

String _$settingsRepositoryHash() => r'0eda22c9c7a5e68c8661bf58b528d73264ef9a19';

/// Per raggruppare scritture di più repository in un'unica transazione.

@ProviderFor(atomicWrites)
final atomicWritesProvider = AtomicWritesProvider._();

/// Per raggruppare scritture di più repository in un'unica transazione.

final class AtomicWritesProvider extends $FunctionalProvider<AtomicWrites, AtomicWrites, AtomicWrites>
    with $Provider<AtomicWrites> {
  /// Per raggruppare scritture di più repository in un'unica transazione.
  AtomicWritesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'atomicWritesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$atomicWritesHash();

  @$internal
  @override
  $ProviderElement<AtomicWrites> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  AtomicWrites create(Ref ref) {
    return atomicWrites(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AtomicWrites value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<AtomicWrites>(value));
  }
}

String _$atomicWritesHash() => r'bc323f91d74bab0a194d1cbd108f6ee9d66d9ea4';
