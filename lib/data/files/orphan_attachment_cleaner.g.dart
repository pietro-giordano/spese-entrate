// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orphan_attachment_cleaner.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(orphanAttachmentCleaner)
final orphanAttachmentCleanerProvider = OrphanAttachmentCleanerProvider._();

final class OrphanAttachmentCleanerProvider
    extends $FunctionalProvider<OrphanAttachmentCleaner, OrphanAttachmentCleaner, OrphanAttachmentCleaner>
    with $Provider<OrphanAttachmentCleaner> {
  OrphanAttachmentCleanerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'orphanAttachmentCleanerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$orphanAttachmentCleanerHash();

  @$internal
  @override
  $ProviderElement<OrphanAttachmentCleaner> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  OrphanAttachmentCleaner create(Ref ref) {
    return orphanAttachmentCleaner(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OrphanAttachmentCleaner value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<OrphanAttachmentCleaner>(value));
  }
}

String _$orphanAttachmentCleanerHash() => r'7b30f74477fc75af293b631f1b5715fc04f53ba8';
