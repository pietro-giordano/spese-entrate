// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'external_file_opener.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(externalFileOpener)
final externalFileOpenerProvider = ExternalFileOpenerProvider._();

final class ExternalFileOpenerProvider
    extends $FunctionalProvider<ExternalFileOpener, ExternalFileOpener, ExternalFileOpener>
    with $Provider<ExternalFileOpener> {
  ExternalFileOpenerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'externalFileOpenerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$externalFileOpenerHash();

  @$internal
  @override
  $ProviderElement<ExternalFileOpener> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  ExternalFileOpener create(Ref ref) {
    return externalFileOpener(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExternalFileOpener value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<ExternalFileOpener>(value));
  }
}

String _$externalFileOpenerHash() => r'e3658fa905ac2ec929a160dad73ba04d00b9916e';
