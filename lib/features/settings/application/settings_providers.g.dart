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

/// Preferenze solo di questo dispositivo (tema, blocco con biometria, profilo).

@ProviderFor(localPreferences)
final localPreferencesProvider = LocalPreferencesProvider._();

/// Preferenze solo di questo dispositivo (tema, blocco con biometria, profilo).

final class LocalPreferencesProvider
    extends $FunctionalProvider<AsyncValue<LocalPreferences>, LocalPreferences, Stream<LocalPreferences>>
    with $FutureModifier<LocalPreferences>, $StreamProvider<LocalPreferences> {
  /// Preferenze solo di questo dispositivo (tema, blocco con biometria, profilo).
  LocalPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localPreferencesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localPreferencesHash();

  @$internal
  @override
  $StreamProviderElement<LocalPreferences> $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<LocalPreferences> create(Ref ref) {
    return localPreferences(ref);
  }
}

String _$localPreferencesHash() => r'8437930005ea53a15993b4f9c84c10dbbf19a561';

/// Quanti movimenti usano ogni categoria (per "48 movimenti" nella gestione categorie).

@ProviderFor(categoryUsage)
final categoryUsageProvider = CategoryUsageProvider._();

/// Quanti movimenti usano ogni categoria (per "48 movimenti" nella gestione categorie).

final class CategoryUsageProvider
    extends $FunctionalProvider<AsyncValue<Map<String, int>>, Map<String, int>, FutureOr<Map<String, int>>>
    with $FutureModifier<Map<String, int>>, $FutureProvider<Map<String, int>> {
  /// Quanti movimenti usano ogni categoria (per "48 movimenti" nella gestione categorie).
  CategoryUsageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryUsageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryUsageHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, int>> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, int>> create(Ref ref) {
    return categoryUsage(ref);
  }
}

String _$categoryUsageHash() => r'41a94a7e1e877e28492081ea7863b4b939e52d89';

/// Quanti movimenti usano ogni label.

@ProviderFor(labelUsage)
final labelUsageProvider = LabelUsageProvider._();

/// Quanti movimenti usano ogni label.

final class LabelUsageProvider
    extends $FunctionalProvider<AsyncValue<Map<String, int>>, Map<String, int>, FutureOr<Map<String, int>>>
    with $FutureModifier<Map<String, int>>, $FutureProvider<Map<String, int>> {
  /// Quanti movimenti usano ogni label.
  LabelUsageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'labelUsageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$labelUsageHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, int>> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, int>> create(Ref ref) {
    return labelUsage(ref);
  }
}

String _$labelUsageHash() => r'465859388391375e9375f2db8bc65ce8a506ce57';

/// Storico degli import da CSV, dal più recente.

@ProviderFor(importHistory)
final importHistoryProvider = ImportHistoryProvider._();

/// Storico degli import da CSV, dal più recente.

final class ImportHistoryProvider
    extends $FunctionalProvider<AsyncValue<List<ImportRecord>>, List<ImportRecord>, Stream<List<ImportRecord>>>
    with $FutureModifier<List<ImportRecord>>, $StreamProvider<List<ImportRecord>> {
  /// Storico degli import da CSV, dal più recente.
  ImportHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'importHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$importHistoryHash();

  @$internal
  @override
  $StreamProviderElement<List<ImportRecord>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<ImportRecord>> create(Ref ref) {
    return importHistory(ref);
  }
}

String _$importHistoryHash() => r'b1b804f692877faeb83b114ac36d18e118def269';
