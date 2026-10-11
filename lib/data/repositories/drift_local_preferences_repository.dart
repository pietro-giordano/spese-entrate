import '../../domain/models/local_preferences.dart';
import '../../domain/repositories/local_preferences_repository.dart';
import '../db/app_database.dart';

/// Preferenze in `app_meta`: tabella solo locale, quindi niente outbox né campi di sync.
class DriftLocalPreferencesRepository implements LocalPreferencesRepository {
  DriftLocalPreferencesRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<LocalPreferences> watch() =>
      _db.select(_db.appMeta).watch().map((rows) => _fromMap({for (final row in rows) row.key: row.value}));

  @override
  Future<LocalPreferences> get() async =>
      _fromMap({for (final row in await _db.select(_db.appMeta).get()) row.key: row.value});

  @override
  Future<void> save(LocalPreferences preferences) {
    return _db.transaction(() async {
      final current = {for (final row in await _db.select(_db.appMeta).get()) row.key: row.value};
      for (final MapEntry(:key, :value) in _toMap(preferences).entries) {
        if (current[key] == value) continue;
        if (value == null) {
          await (_db.delete(_db.appMeta)..where((t) => t.key.equals(key))).go();
        } else {
          await _db.into(_db.appMeta).insertOnConflictUpdate(AppMetaCompanion.insert(key: key, value: value));
        }
      }
    });
  }

  static Map<String, String?> _toMap(LocalPreferences preferences) {
    String? clean(String? text) => (text == null || text.trim().isEmpty) ? null : text.trim();
    return {
      AppMetaKeys.themeMode: preferences.themeMode.name,
      AppMetaKeys.biometricLock: preferences.biometricLock.toString(),
      AppMetaKeys.profileName: clean(preferences.profileName),
      AppMetaKeys.profileEmail: clean(preferences.profileEmail),
    };
  }

  static LocalPreferences _fromMap(Map<String, String> values) {
    return LocalPreferences(
      themeMode: AppThemeMode.values.asNameMap()[values[AppMetaKeys.themeMode]] ?? AppThemeMode.system,
      biometricLock: values[AppMetaKeys.biometricLock] == 'true',
      profileName: values[AppMetaKeys.profileName],
      profileEmail: values[AppMetaKeys.profileEmail],
    );
  }
}
