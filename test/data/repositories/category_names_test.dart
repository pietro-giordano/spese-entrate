import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spese_entrate/core/ids.dart';
import 'package:spese_entrate/data/db/app_database.dart';
import 'package:spese_entrate/data/repositories/drift_category_repository.dart';
import 'package:spese_entrate/domain/models/category.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/repositories/category_repository.dart';

/// Nomi delle categorie: unici per tipo, uguali ammessi solo tra spese ed entrate.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late DriftCategoryRepository categories;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    categories = DriftCategoryRepository(db);
  });
  tearDown(() => db.close());

  Category category(String name, CategoryKind kind) => Category(id: newId(), name: name, kind: kind, color: 0);

  test('stesso nome e stesso tipo: rifiutato, anche con maiuscole e spazi diversi', () async {
    // "Regali" di entrata c'è nei dati iniziali.
    await expectLater(
      categories.save(category(' REGALI ', CategoryKind.income)),
      throwsA(isA<DuplicateCategoryNameException>().having((e) => e.kind, 'tipo', CategoryKind.income)),
    );
  });

  test('stesso nome ma tipo diverso: ammesso', () async {
    await categories.save(category('Regali', CategoryKind.expense));
    final gifts = (await categories.watchAll().first).where((c) => c.name == 'Regali');
    expect(gifts.map((c) => c.kind).toSet(), {CategoryKind.expense, CategoryKind.income});
  });

  test('rinominare con il nome di un\'altra dello stesso tipo: rifiutato; risalvare sé stessa: ammesso', () async {
    final all = await categories.watchAll().first;
    final home = all.firstWhere((c) => c.name == 'Casa');
    await expectLater(categories.save(home.copyWith(name: 'Svago')), throwsA(isA<DuplicateCategoryNameException>()));
    await categories.save(home.copyWith(name: 'casa', color: 1));
    expect((await categories.watchAll().first).firstWhere((c) => c.id == home.id).name, 'casa');
  });

  test('una categoria archiviata occupa il nome, una cancellata no', () async {
    final all = await categories.watchAll().first;
    final fun = all.firstWhere((c) => c.name == 'Svago');
    await categories.save(fun.copyWith(archivedAt: DateTime.utc(2026)));
    await expectLater(
      categories.save(category('Svago', CategoryKind.expense)),
      throwsA(isA<DuplicateCategoryNameException>()),
    );

    final health = all.firstWhere((c) => c.name == 'Salute');
    await categories.delete(health.id);
    await categories.save(category('Salute', CategoryKind.expense));
  });
}
