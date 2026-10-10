import '../../core/ids.dart';
import '../../core/money.dart';
import '../../domain/models/enums.dart';
import 'app_database.dart';

/// Categorie iniziali: nome → colore ARGB.
const initialExpenseCategories = {
  'Spesa alimentare': 0xFF15803D,
  'Casa': 0xFFB45309,
  'Trasporti': 0xFF0369A1,
  'Ristoranti': 0xFFBE123C,
  'Svago': 0xFF7C3AED,
  'Salute': 0xFF0F766E,
  'Abbonamenti': 0xFF4338CA,
  'Altro': 0xFF57534E,
};

const initialIncomeCategories = {
  'Stipendio': 0xFF1D4ED8,
  'Freelance': 0xFF0E7490,
  'Rimborsi': 0xFF15803D,
  'Regali': 0xFFDB2777,
  'Altro': 0xFF57534E,
};

/// Dati del primo avvio: 2 portafogli, categorie di spesa ed entrata, impostazioni.
/// Ogni riga ha la sua voce nell'outbox, come qualsiasi altra scrittura.
Future<void> seedInitialData(AppDatabase db, {required String deviceId}) {
  return db.transaction(() async {
    final now = db.nowMs();
    final today = db.today();
    final outbox = <OutboxCompanion>[];

    void track(String entity, String id) {
      outbox.add(OutboxCompanion.insert(entity: entity, entityId: id, op: OutboxOp.upsert, changedAt: now));
    }

    final checkingId = newId(nowMs: now);
    final cashId = newId(nowMs: now);
    final wallets = [
      (id: checkingId, name: 'Conto corrente', type: WalletType.checking),
      (id: cashId, name: 'Contanti', type: WalletType.cash),
    ];

    final settings = {
      SettingKeys.defaultExpenseWalletId: checkingId,
      SettingKeys.defaultIncomeWalletId: checkingId,
      SettingKeys.weekStart: '1',
      SettingKeys.defaultPeriod: 'month',
      SettingKeys.currency: defaultCurrency,
    };

    await db.batch((batch) {
      for (final (index, wallet) in wallets.indexed) {
        batch.insert(
          db.wallets,
          WalletsCompanion.insert(
            id: wallet.id,
            createdAt: now,
            updatedAt: now,
            deviceId: deviceId,
            name: wallet.name,
            type: wallet.type,
            initialBalanceCents: 0,
            initialBalanceDate: today,
            sortOrder: index,
          ),
        );
        track(db.wallets.actualTableName, wallet.id);
      }

      void addCategories(Map<String, int> categories, CategoryKind kind) {
        for (final (index, MapEntry(key: name, value: color)) in categories.entries.indexed) {
          final id = newId(nowMs: now);
          batch.insert(
            db.categories,
            CategoriesCompanion.insert(
              id: id,
              createdAt: now,
              updatedAt: now,
              deviceId: deviceId,
              name: name,
              kind: kind,
              color: color,
              sortOrder: index,
            ),
          );
          track(db.categories.actualTableName, id);
        }
      }

      addCategories(initialExpenseCategories, CategoryKind.expense);
      addCategories(initialIncomeCategories, CategoryKind.income);

      for (final MapEntry(:key, :value) in settings.entries) {
        final id = newId(nowMs: now);
        batch.insert(
          db.settings,
          SettingsCompanion.insert(id: id, createdAt: now, updatedAt: now, deviceId: deviceId, key: key, value: value),
        );
        track(db.settings.actualTableName, id);
      }

      batch.insertAll(db.outbox, outbox);
    });
  });
}
