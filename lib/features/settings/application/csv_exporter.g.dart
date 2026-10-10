// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'csv_exporter.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(csvExporter)
final csvExporterProvider = CsvExporterProvider._();

final class CsvExporterProvider extends $FunctionalProvider<CsvExporter, CsvExporter, CsvExporter>
    with $Provider<CsvExporter> {
  CsvExporterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'csvExporterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$csvExporterHash();

  @$internal
  @override
  $ProviderElement<CsvExporter> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  CsvExporter create(Ref ref) {
    return csvExporter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CsvExporter value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<CsvExporter>(value));
  }
}

String _$csvExporterHash() => r'b60268418cc8d505f5797df4ec49ecd3dd9d44ed';
