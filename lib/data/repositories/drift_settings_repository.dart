import 'package:drift/drift.dart';

import '../../core/dates.dart';
import '../../core/ids.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../db/app_database.dart';

class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<AppSettings> watch() {
    final query = _db.select(_db.settings)..whereNotDeleted();
    return query.watch().map((rows) => _fromMap({for (final row in rows) row.key: row.value}));
  }

  @override
  Future<AppSettings> get() async {
    final rows = await (_db.select(_db.settings)..whereNotDeleted()).get();
    return _fromMap({for (final row in rows) row.key: row.value});
  }

  @override
  Future<void> save(AppSettings settings) {
    return _db.transaction(() async {
      // Anche le righe cancellate: `key` è unica, quindi una chiave tornata in uso riprende il suo ID.
      final rows = {for (final row in await _db.select(_db.settings).get()) row.key: row};

      for (final MapEntry(:key, :value) in _toMap(settings).entries) {
        final row = rows[key];
        final isActive = row != null && row.deletedAt == null;
        if (value == null) {
          if (isActive) await _db.softDelete(_db.settings, row.id);
        } else if (!isActive || row.value != value) {
          await _db.upsertSynced(
            _db.settings,
            row?.id ?? newId(nowMs: _db.nowMs()),
            SettingsCompanion(key: Value(key), value: Value(value)),
          );
        }
      }
    });
  }

  static Map<String, String?> _toMap(AppSettings settings) => {
    SettingKeys.defaultExpenseWalletId: settings.defaultExpenseWalletId,
    SettingKeys.defaultIncomeWalletId: settings.defaultIncomeWalletId,
    SettingKeys.weekStart: settings.weekStart.toString(),
    SettingKeys.defaultPeriod: settings.defaultPeriod.name,
    SettingKeys.currency: settings.currency,
  };

  static AppSettings _fromMap(Map<String, String> values) {
    const defaults = AppSettings();
    return AppSettings(
      defaultExpenseWalletId: values[SettingKeys.defaultExpenseWalletId],
      defaultIncomeWalletId: values[SettingKeys.defaultIncomeWalletId],
      weekStart: int.tryParse(values[SettingKeys.weekStart] ?? '') ?? defaults.weekStart,
      defaultPeriod: PeriodType.values.asNameMap()[values[SettingKeys.defaultPeriod]] ?? defaults.defaultPeriod,
      currency: values[SettingKeys.currency] ?? defaults.currency,
    );
  }
}
