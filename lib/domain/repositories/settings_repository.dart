import '../models/app_settings.dart';

abstract interface class SettingsRepository {
  Stream<AppSettings> watch();

  /// Salva solo le chiavi cambiate.
  Future<void> save(AppSettings settings);
}
