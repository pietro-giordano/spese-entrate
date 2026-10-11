// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'biometric_auth.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(biometricAuth)
final biometricAuthProvider = BiometricAuthProvider._();

final class BiometricAuthProvider extends $FunctionalProvider<BiometricAuth, BiometricAuth, BiometricAuth>
    with $Provider<BiometricAuth> {
  BiometricAuthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'biometricAuthProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$biometricAuthHash();

  @$internal
  @override
  $ProviderElement<BiometricAuth> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  BiometricAuth create(Ref ref) {
    return biometricAuth(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BiometricAuth value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<BiometricAuth>(value));
  }
}

String _$biometricAuthHash() => r'8fc4b02f8355793fceb87fa0c89db95289eb4d22';
