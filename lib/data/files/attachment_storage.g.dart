// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment_storage.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(attachmentStorage)
final attachmentStorageProvider = AttachmentStorageProvider._();

final class AttachmentStorageProvider
    extends $FunctionalProvider<AttachmentStorage, AttachmentStorage, AttachmentStorage>
    with $Provider<AttachmentStorage> {
  AttachmentStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'attachmentStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$attachmentStorageHash();

  @$internal
  @override
  $ProviderElement<AttachmentStorage> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  AttachmentStorage create(Ref ref) {
    return attachmentStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AttachmentStorage value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<AttachmentStorage>(value));
  }
}

String _$attachmentStorageHash() => r'2c4ceb4e3cb8ea570fc0da1b899d7819864329d6';
