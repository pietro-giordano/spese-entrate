// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_lock.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Stato del blocco con biometria: true = schermata di sblocco visibile.
///
/// Si blocca all'apertura e quando l'app torna in primo piano dopo almeno [lockAfterBackground],
/// se l'utente ha attivato il blocco nelle impostazioni.

@ProviderFor(AppLock)
final appLockProvider = AppLockProvider._();

/// Stato del blocco con biometria: true = schermata di sblocco visibile.
///
/// Si blocca all'apertura e quando l'app torna in primo piano dopo almeno [lockAfterBackground],
/// se l'utente ha attivato il blocco nelle impostazioni.
final class AppLockProvider extends $NotifierProvider<AppLock, bool> {
  /// Stato del blocco con biometria: true = schermata di sblocco visibile.
  ///
  /// Si blocca all'apertura e quando l'app torna in primo piano dopo almeno [lockAfterBackground],
  /// se l'utente ha attivato il blocco nelle impostazioni.
  AppLockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLockHash();

  @$internal
  @override
  AppLock create() => AppLock();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<bool>(value));
  }
}

String _$appLockHash() => r'072c464d9684dcbb1f294f71f4cb871d7d9be79b';

/// Stato del blocco con biometria: true = schermata di sblocco visibile.
///
/// Si blocca all'apertura e quando l'app torna in primo piano dopo almeno [lockAfterBackground],
/// se l'utente ha attivato il blocco nelle impostazioni.

abstract class _$AppLock extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<bool, bool>, bool, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}
