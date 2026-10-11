import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/import_record.dart';
import '../../../domain/models/app_settings.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/label.dart';
import '../../../domain/models/local_preferences.dart';
import '../../transactions/application/transaction_providers.dart';

part 'settings_providers.g.dart';

@riverpod
Stream<AppSettings> appSettings(Ref ref) => ref.watch(settingsRepositoryProvider).watch();

/// Categorie non cancellate (anche archiviate).
@riverpod
Stream<List<Category>> categories(Ref ref) => ref.watch(categoryRepositoryProvider).watchAll();

@riverpod
Stream<List<Label>> labels(Ref ref) => ref.watch(labelRepositoryProvider).watchAll();

/// Preferenze solo di questo dispositivo (tema, blocco con biometria, profilo).
@riverpod
Stream<LocalPreferences> localPreferences(Ref ref) => ref.watch(localPreferencesRepositoryProvider).watch();

/// Quanti movimenti usano ogni categoria (per "48 movimenti" nella gestione categorie).
@riverpod
Future<Map<String, int>> categoryUsage(Ref ref) async {
  final counts = <String, int>{};
  for (final tx in await ref.watch(allTransactionsProvider.future)) {
    if (tx.categoryId != null) counts[tx.categoryId!] = (counts[tx.categoryId!] ?? 0) + 1;
  }
  return counts;
}

/// Quanti movimenti usano ogni label.
@riverpod
Future<Map<String, int>> labelUsage(Ref ref) async {
  final counts = <String, int>{};
  for (final tx in await ref.watch(allTransactionsProvider.future)) {
    for (final id in tx.labelIds.toSet()) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
  }
  return counts;
}

/// Storico degli import da CSV, dal più recente.
@riverpod
Stream<List<ImportRecord>> importHistory(Ref ref) => ref.watch(importRepositoryProvider).watchAll();
