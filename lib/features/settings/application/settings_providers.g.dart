// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appSettings)
final appSettingsProvider = AppSettingsProvider._();

final class AppSettingsProvider extends $FunctionalProvider<AsyncValue<AppSettings>, AppSettings, Stream<AppSettings>>
    with $FutureModifier<AppSettings>, $StreamProvider<AppSettings> {
  AppSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appSettingsHash();

  @$internal
  @override
  $StreamProviderElement<AppSettings> $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<AppSettings> create(Ref ref) {
    return appSettings(ref);
  }
}

String _$appSettingsHash() => r'11796137341bf38f3339d80ac6ef4272f5d09740';

/// Categorie non cancellate (anche archiviate).

@ProviderFor(categories)
final categoriesProvider = CategoriesProvider._();

/// Categorie non cancellate (anche archiviate).

final class CategoriesProvider
    extends $FunctionalProvider<AsyncValue<List<Category>>, List<Category>, Stream<List<Category>>>
    with $FutureModifier<List<Category>>, $StreamProvider<List<Category>> {
  /// Categorie non cancellate (anche archiviate).
  CategoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoriesHash();

  @$internal
  @override
  $StreamProviderElement<List<Category>> $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<List<Category>> create(Ref ref) {
    return categories(ref);
  }
}

String _$categoriesHash() => r'521ced16a330d78b1c4bf47536d6622a3b38d6b1';

@ProviderFor(labels)
final labelsProvider = LabelsProvider._();

final class LabelsProvider extends $FunctionalProvider<AsyncValue<List<Label>>, List<Label>, Stream<List<Label>>>
    with $FutureModifier<List<Label>>, $StreamProvider<List<Label>> {
  LabelsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'labelsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$labelsHash();

  @$internal
  @override
  $StreamProviderElement<List<Label>> $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<List<Label>> create(Ref ref) {
    return labels(ref);
  }
}

String _$labelsHash() => r'481e6a3374e8111eb9294f28bcb29a491527f090';
