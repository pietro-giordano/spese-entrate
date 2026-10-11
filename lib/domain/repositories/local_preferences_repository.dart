import '../models/local_preferences.dart';

abstract interface class LocalPreferencesRepository {
  Stream<LocalPreferences> watch();

  Future<LocalPreferences> get();

  /// Salva solo le chiavi cambiate.
  Future<void> save(LocalPreferences preferences);
}
