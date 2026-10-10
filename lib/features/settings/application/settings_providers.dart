import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/app_settings.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/label.dart';

part 'settings_providers.g.dart';

@riverpod
Stream<AppSettings> appSettings(Ref ref) => ref.watch(settingsRepositoryProvider).watch();

/// Categorie non cancellate (anche archiviate).
@riverpod
Stream<List<Category>> categories(Ref ref) => ref.watch(categoryRepositoryProvider).watchAll();

@riverpod
Stream<List<Label>> labels(Ref ref) => ref.watch(labelRepositoryProvider).watchAll();
