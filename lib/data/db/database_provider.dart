import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'app_database.dart';

part 'database_provider.g.dart';

/// Unica istanza del database per tutta l'app. Nei test si sostituisce con
/// `appDatabaseProvider.overrideWithValue(AppDatabase(NativeDatabase.memory()))`.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
}
