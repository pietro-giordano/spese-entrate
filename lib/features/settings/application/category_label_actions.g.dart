// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_label_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(categoryLabelActions)
final categoryLabelActionsProvider = CategoryLabelActionsProvider._();

final class CategoryLabelActionsProvider
    extends $FunctionalProvider<CategoryLabelActions, CategoryLabelActions, CategoryLabelActions>
    with $Provider<CategoryLabelActions> {
  CategoryLabelActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryLabelActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryLabelActionsHash();

  @$internal
  @override
  $ProviderElement<CategoryLabelActions> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  CategoryLabelActions create(Ref ref) {
    return categoryLabelActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategoryLabelActions value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<CategoryLabelActions>(value));
  }
}

String _$categoryLabelActionsHash() => r'8158c2cdb3a4744ca019232b773d5a283ff166fb';
