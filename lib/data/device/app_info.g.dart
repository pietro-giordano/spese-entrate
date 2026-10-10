// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_info.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Nome, versione e build letti dai metadati dell'app installata
/// (pubspec `version: x.y.z+build` → Info.plist / build.gradle).

@ProviderFor(packageInfo)
final packageInfoProvider = PackageInfoProvider._();

/// Nome, versione e build letti dai metadati dell'app installata
/// (pubspec `version: x.y.z+build` → Info.plist / build.gradle).

final class PackageInfoProvider extends $FunctionalProvider<AsyncValue<PackageInfo>, PackageInfo, FutureOr<PackageInfo>>
    with $FutureModifier<PackageInfo>, $FutureProvider<PackageInfo> {
  /// Nome, versione e build letti dai metadati dell'app installata
  /// (pubspec `version: x.y.z+build` → Info.plist / build.gradle).
  PackageInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'packageInfoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$packageInfoHash();

  @$internal
  @override
  $FutureProviderElement<PackageInfo> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<PackageInfo> create(Ref ref) {
    return packageInfo(ref);
  }
}

String _$packageInfoHash() => r'854bbb0e381edfdddbd736229351d6cc918a2ad1';
