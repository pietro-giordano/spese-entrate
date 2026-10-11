// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Flusso "Importa da CSV": scelta del file, anteprima, abbinamenti, opzioni, importazione.
/// Si auto-elimina quando la schermata si chiude.

@ProviderFor(ImportController)
final importControllerProvider = ImportControllerProvider._();

/// Flusso "Importa da CSV": scelta del file, anteprima, abbinamenti, opzioni, importazione.
/// Si auto-elimina quando la schermata si chiude.
final class ImportControllerProvider extends $NotifierProvider<ImportController, ImportFlowState> {
  /// Flusso "Importa da CSV": scelta del file, anteprima, abbinamenti, opzioni, importazione.
  /// Si auto-elimina quando la schermata si chiude.
  ImportControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'importControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$importControllerHash();

  @$internal
  @override
  ImportController create() => ImportController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImportFlowState value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<ImportFlowState>(value));
  }
}

String _$importControllerHash() => r'7ac6ea1fcf6104f9afcfdf98de209f064d3f928a';

/// Flusso "Importa da CSV": scelta del file, anteprima, abbinamenti, opzioni, importazione.
/// Si auto-elimina quando la schermata si chiude.

abstract class _$ImportController extends $Notifier<ImportFlowState> {
  ImportFlowState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ImportFlowState, ImportFlowState>;
    final element =
        ref.element
            as $ClassProviderElement<AnyNotifier<ImportFlowState, ImportFlowState>, ImportFlowState, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}
