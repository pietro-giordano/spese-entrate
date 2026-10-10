import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_info.g.dart';

/// Nome, versione e build letti dai metadati dell'app installata
/// (pubspec `version: x.y.z+build` → Info.plist / build.gradle).
@Riverpod(keepAlive: true)
Future<PackageInfo> packageInfo(Ref ref) => PackageInfo.fromPlatform();
