import '../models/app_settings.dart';

abstract interface class SettingsRepository {
  Stream<AppSettings> watch();

  /// Lettura singola, senza restare in ascolto.
  Future<AppSettings> get();

  /// Salva solo le chiavi cambiate.
  Future<void> save(AppSettings settings);
}
