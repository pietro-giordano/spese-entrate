// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Router dell'app. È un provider così in futuro potrà leggere altro stato
/// (es. il blocco biometrico) per i redirect, e ogni test ne ottiene uno nuovo.

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// Router dell'app. È un provider così in futuro potrà leggere altro stato
/// (es. il blocco biometrico) per i redirect, e ogni test ne ottiene uno nuovo.

final class AppRouterProvider extends $FunctionalProvider<GoRouter, GoRouter, GoRouter> with $Provider<GoRouter> {
  /// Router dell'app. È un provider così in futuro potrà leggere altro stato
  /// (es. il blocco biometrico) per i redirect, e ogni test ne ottiene uno nuovo.
  AppRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRouterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return appRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<GoRouter>(value));
  }
}

String _$appRouterHash() => r'cd2dac7a23db6f42ef0f4ab58f3d47c04bfa0e30';
