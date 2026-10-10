// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(attachmentActions)
final attachmentActionsProvider = AttachmentActionsProvider._();

final class AttachmentActionsProvider
    extends $FunctionalProvider<AttachmentActions, AttachmentActions, AttachmentActions>
    with $Provider<AttachmentActions> {
  AttachmentActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'attachmentActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$attachmentActionsHash();

  @$internal
  @override
  $ProviderElement<AttachmentActions> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  AttachmentActions create(Ref ref) {
    return attachmentActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AttachmentActions value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<AttachmentActions>(value));
  }
}

String _$attachmentActionsHash() => r'10a0db67e435dcf87ec89eb03f7488a70772a243';
