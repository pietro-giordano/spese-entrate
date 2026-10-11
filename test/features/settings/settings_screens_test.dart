import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:spese_entrate/app.dart';
import 'package:spese_entrate/core/clock.dart';
import 'package:spese_entrate/core/dates.dart';
import 'package:spese_entrate/core/ids.dart';
import 'package:spese_entrate/core/router/app_router.dart';
import 'package:spese_entrate/core/router/app_routes.dart';
import 'package:spese_entrate/data/db/app_database.dart';
import 'package:spese_entrate/data/db/database_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:spese_entrate/data/device/app_info.dart';
import 'package:spese_entrate/data/device/biometric_auth.dart';
import 'package:spese_entrate/data/files/file_sharer.dart';
import 'package:spese_entrate/data/repositories/repository_providers.dart';
import 'package:spese_entrate/domain/models/category.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/local_preferences.dart';
import 'package:spese_entrate/domain/models/transaction.dart';
import 'package:spese_entrate/features/settings/application/csv_exporter.dart';
import 'package:spese_entrate/features/settings/application/settings_providers.dart';
import 'package:spese_entrate/features/transactions/application/transaction_list_providers.dart';
import 'package:spese_entrate/features/wallets/application/balance_visibility.dart';

import 'settings_logic_test.dart' show FakeBiometricAuth;

class FakeFileSharer extends FileSharer {
  final shared = <String>[];

  @override
  Future<void> shareFile(String path, {required String mimeType, String? subject}) async => shared.add(path);
}

void main() {
  setUpAll(() => initializeDateFormatting('it_IT'));
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late ProviderContainer container;
  late FakeBiometricAuth biometric;
  late FakeFileSharer sharer;
  late Directory exportDir;

  Future<void> pumpAt(WidgetTester tester, String location, {bool lockEnabled = false}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    biometric = FakeBiometricAuth();
    sharer = FakeFileSharer();
    exportDir = (await tester.runAsync(() => Directory.systemTemp.createTemp('spese_entrate_export_')))!;
    final db = AppDatabase(NativeDatabase.memory(), now: () => DateTime.utc(2026, 10, 3, 8));
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 3, 9)),
        biometricAuthProvider.overrideWithValue(biometric),
        csvExporterProvider.overrideWithValue(CsvExporter(sharer: sharer, directory: () async => exportDir)),
        // Metadati finti dell'app installata: la versione non è scritta nel codice.
        packageInfoProvider.overrideWith(
          (ref) async => PackageInfo(appName: 'Finanze', packageName: 'test', version: '2.3.4', buildNumber: '56'),
        ),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
      await exportDir.delete(recursive: true);
    });

    await tester.runAsync(() async {
      if (lockEnabled) {
        await container.read(localPreferencesRepositoryProvider).save(const LocalPreferences(biometricLock: true));
      }
      // Come main.dart: impostazioni e preferenze pronte prima di mostrare l'app.
      container
        ..listen(appSettingsProvider, (_, _) {})
        ..listen(localPreferencesProvider, (_, _) {});
      await container.read(appSettingsProvider.future);
      await container.read(localPreferencesProvider.future);
    });

    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const App()));
    await tester.pumpAndSettle();
    if (location != AppRoutes.transactions) {
      container.read(appRouterProvider).push(location);
      await tester.pumpAndSettle();
    }
  }

  /// Fa scattare i timer con cui Drift chiude gli stream delle schermate lasciate.
  Future<void> finish(WidgetTester tester) => tester.pump(const Duration(milliseconds: 10));

  Future<T> db<T>(WidgetTester tester, Future<T> Function() action) async => (await tester.runAsync(action)) as T;

  /// Le scritture fanno più passi sul database: si lascia lavorare l'I/O finché [done] è vero.
  Future<void> waitFor(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 100 && !done(); i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  group('Impostazioni', () {
    testWidgets('versione e build dai metadati dell\'app', (tester) async {
      await pumpAt(tester, AppRoutes.settings);
      await tester.scrollUntilVisible(find.text('Versione 2.3.4 (56)'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('Versione 2.3.4 (56)'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('tema scuro salvato e applicato', (tester) async {
      await pumpAt(tester, AppRoutes.settings);
      await tester.tap(find.text('Scuro'));
      await waitFor(tester, () => container.read(localPreferencesProvider).value?.themeMode == AppThemeMode.dark);

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
      await finish(tester);
    });

    testWidgets('vista predefinita: si salva e si applica subito alla lista', (tester) async {
      await pumpAt(tester, AppRoutes.settings);
      await tester.tap(find.text('Vista predefinita'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settimana'));
      await waitFor(tester, () => container.read(appSettingsProvider).value?.defaultPeriod == PeriodType.week);

      expect(container.read(selectedPeriodProvider).type, PeriodType.week);
      expect(find.text('Settimana'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('inizio settimana: domenica', (tester) async {
      await pumpAt(tester, AppRoutes.settings);
      await tester.tap(find.text('La settimana inizia di'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Domenica'));
      await waitFor(tester, () => container.read(appSettingsProvider).value?.weekStart == DateTime.sunday);
      expect(find.text('Domenica'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('biometria: si attiva solo dopo averla verificata', (tester) async {
      await pumpAt(tester, AppRoutes.settings);
      await tester.scrollUntilVisible(
        find.text('Blocco con biometria'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      biometric.available = false;
      await tester.tap(find.text('Blocco con biometria'));
      await tester.pumpAndSettle();
      expect(find.text('Su questo telefono la biometria non è disponibile'), findsOneWidget);

      biometric.available = true;
      await tester.tap(find.text('Blocco con biometria'));
      await waitFor(tester, () => container.read(localPreferencesProvider).value?.biometricLock == true);
      expect(biometric.calls, 1);
      await finish(tester);
    });

    testWidgets('Privacy: «Saldi all\'apertura» si salva in app_meta', (tester) async {
      await pumpAt(tester, AppRoutes.settings);
      await tester.scrollUntilVisible(find.text('Saldi all\'apertura'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('PRIVACY'), findsOneWidget);
      expect(find.text('Sempre visibili'), findsOneWidget);
      await tester.ensureVisible(find.text('Saldi all\'apertura'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Saldi all\'apertura'));
      await tester.pumpAndSettle();
      expect(find.text('Ricorda l\'ultima scelta'), findsOneWidget);
      await tester.tap(find.text('Sempre nascosti'));
      await waitFor(
        tester,
        () => container.read(localPreferencesProvider).value?.balancesOnOpen == BalancesOnOpen.hidden,
      );
      expect(find.text('Sempre nascosti'), findsOneWidget);
      expect(container.read(balancesHiddenProvider), isTrue, reason: 'effetto immediato');

      // Con «Ricorda» lo stato corrente resta (qui nascosti).
      await tester.tap(find.text('Saldi all\'apertura'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ricorda l\'ultima scelta'));
      await waitFor(
        tester,
        () => container.read(localPreferencesProvider).value?.balancesOnOpen == BalancesOnOpen.remember,
      );
      expect(container.read(balancesHiddenProvider), isTrue);

      await tester.tap(find.text('Saldi all\'apertura'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sempre visibili'));
      await waitFor(
        tester,
        () => container.read(localPreferencesProvider).value?.balancesOnOpen == BalancesOnOpen.visible,
      );
      expect(container.read(balancesHiddenProvider), isFalse);
      await finish(tester);
    });

    testWidgets('profilo locale: nome ed email', (tester) async {
      await pumpAt(tester, AppRoutes.settings);
      await tester.tap(find.text('Il tuo profilo'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Nome (facoltativo)'), 'Pietro');
      await tester.enterText(find.widgetWithText(TextField, 'Email (facoltativa)'), 'non-valida');
      await tester.tap(find.text('Salva'));
      await tester.pump();
      expect(find.text('Indirizzo email non valido'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'non-valida'), 'pietro@example.com');
      await tester.tap(find.text('Salva'));
      await waitFor(tester, () => container.read(localPreferencesProvider).value?.profileName == 'Pietro');
      expect(find.text('Pietro'), findsOneWidget);
      expect(find.text('pietro@example.com'), findsOneWidget);
      await finish(tester);
    });
  });

  group('Categorie e label', () {
    Future<List<Category>> expenses(WidgetTester tester) async => [
      for (final c in await db(tester, () => container.read(categoryRepositoryProvider).watchAll().first))
        if (c.kind == CategoryKind.expense) c,
    ];

    testWidgets('nuova categoria in fondo all\'elenco', (tester) async {
      await pumpAt(tester, AppRoutes.categories);
      await tester.scrollUntilVisible(find.text('+ Nuova categoria'), 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('+ Nuova categoria'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salva'));
      await tester.pump();
      expect(find.text('Inserisci un nome'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Palestra');
      await tester.tap(find.bySemanticsLabel('Colore 4'));
      await tester.tap(find.text('Salva'));
      await waitFor(tester, () => find.text('Nuova categoria').evaluate().isEmpty);

      final list = await expenses(tester);
      expect(list.last.name, 'Palestra');
      expect(list.last.color, 0xFF7C3AED);
      await finish(tester);
    });

    testWidgets('nome già usato nello stesso tipo: errore; nell\'altro tipo è ammesso', (tester) async {
      await pumpAt(tester, AppRoutes.categories);
      await tester.scrollUntilVisible(find.text('+ Nuova categoria'), 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('+ Nuova categoria'));
      await tester.pumpAndSettle();
      // "Casa" esiste già tra le spese (anche scritto diversamente).
      await tester.enterText(find.byType(TextField), ' casa ');
      await tester.tap(find.text('Salva'));
      await waitFor(tester, () => find.text('Esiste già una categoria di spesa con questo nome').evaluate().isNotEmpty);
      expect(find.text('Esiste già una categoria di spesa con questo nome'), findsOneWidget);

      // "Regali" esiste solo tra le entrate: come spesa si può creare.
      await tester.enterText(find.byType(TextField), 'Regali');
      await tester.tap(find.text('Salva'));
      await waitFor(tester, () => find.text('Nuova categoria').evaluate().isEmpty);
      expect((await expenses(tester)).last.name, 'Regali');
      await finish(tester);
    });

    testWidgets('riordino trascinando: l\'ordine si salva', (tester) async {
      await pumpAt(tester, AppRoutes.categories);
      final before = await expenses(tester);
      expect(before.take(2).map((c) => c.name), ['Spesa alimentare', 'Casa']);

      // Tieni premuto su "Casa" e trascina sopra "Spesa alimentare".
      final gesture = await tester.startGesture(tester.getCenter(find.text('Casa')));
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
      await gesture.moveBy(const Offset(0, -60));
      await tester.pump();
      await gesture.moveBy(const Offset(0, -40));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      await waitFor(tester, () => true);

      final after = await expenses(tester);
      expect(after.take(2).map((c) => c.name), ['Casa', 'Spesa alimentare']);
      expect(after.map((c) => c.sortOrder).toList(), List.generate(after.length, (i) => i));
      await finish(tester);
    });

    testWidgets('archivia con annulla; le archiviate restano in fondo', (tester) async {
      await pumpAt(tester, AppRoutes.categories);
      await tester.tap(find.byTooltip('Modifica Svago'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archivia'));
      await waitFor(tester, () => find.text('«Svago» archiviata').evaluate().isNotEmpty);
      await tester.scrollUntilVisible(find.text('ARCHIVIATE'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.textContaining('Archiviata'), findsOneWidget);

      await tester.tap(find.text('Annulla'));
      await waitFor(tester, () => find.text('ARCHIVIATE').evaluate().isEmpty);
      expect((await expenses(tester)).firstWhere((c) => c.name == 'Svago').isArchived, isFalse);
      await finish(tester);
    });

    testWidgets('unisci in un\'altra categoria', (tester) async {
      await pumpAt(tester, AppRoutes.categories);
      final ristoranti = (await expenses(tester)).firstWhere((c) => c.name == 'Ristoranti');
      final wallet = (await db(tester, () => container.read(walletRepositoryProvider).watchAll().first)).first;
      await tester.runAsync(
        () => container
            .read(transactionRepositoryProvider)
            .save(
              Transaction(
                id: newId(),
                type: TransactionType.expense,
                amountCents: 450,
                date: LocalDate(2026, 10, 1),
                walletId: wallet.id,
                categoryId: ristoranti.id,
              ),
            ),
      );
      await waitFor(tester, () => find.text('1 movimento').evaluate().isNotEmpty);

      await tester.tap(find.byTooltip('Modifica Ristoranti'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unisci in…'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(BottomSheet).last, matching: find.text('Svago')));
      await tester.pumpAndSettle();
      expect(find.text('Unire «Ristoranti» in «Svago»?'), findsOneWidget);
      await tester.tap(find.text('Unisci'));
      await waitFor(tester, () => find.text('«Ristoranti» unita a «Svago»').evaluate().isNotEmpty);

      final list = await expenses(tester);
      expect(list.map((c) => c.name), isNot(contains('Ristoranti')));
      final transactions = await db(tester, () => container.read(transactionRepositoryProvider).getAll());
      expect(transactions.single.categoryId, list.firstWhere((c) => c.name == 'Svago').id);
      await finish(tester);
    });

    testWidgets('label: nome duplicato rifiutato, poi eliminazione', (tester) async {
      await pumpAt(tester, AppRoutes.categories);
      await tester.tap(find.text('Label'));
      await tester.pumpAndSettle();
      expect(find.text('Non hai ancora creato label.'), findsOneWidget);

      for (final name in ['casa', 'Casa']) {
        await tester.tap(find.text('+ Nuova label'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), name);
        await tester.tap(find.text('Salva'));
        await waitFor(
          tester,
          () =>
              find.text('Nuova label').evaluate().isEmpty ||
              find.text('Esiste già una label con questo nome').evaluate().isNotEmpty,
        );
      }
      expect(find.text('Esiste già una label con questo nome'), findsOneWidget);
      await tester.tap(find.byTooltip('Chiudi'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Modifica #casa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elimina'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Elimina')));
      await waitFor(tester, () => find.text('#casa eliminata').evaluate().isNotEmpty);
      expect(find.text('Non hai ancora creato label.'), findsOneWidget);
      await finish(tester);
    });
  });

  testWidgets('export CSV del periodo e dei filtri della lista', (tester) async {
    await pumpAt(tester, AppRoutes.backup);
    expect(find.text('Ottobre 2026'), findsOneWidget);
    expect(find.text('Esporta 0 movimenti'), findsOneWidget);

    final wallet = (await db(tester, () => container.read(walletRepositoryProvider).watchAll().first)).first;
    final category = (await db(tester, () => container.read(categoryRepositoryProvider).watchAll().first)).first;
    await tester.runAsync(
      () => container
          .read(transactionRepositoryProvider)
          .save(
            Transaction(
              id: 'tx-1',
              type: TransactionType.expense,
              amountCents: 6420,
              date: LocalDate(2026, 10, 2),
              walletId: wallet.id,
              categoryId: category.id,
              note: 'Esselunga',
            ),
          ),
    );
    await waitFor(tester, () => find.text('Esporta 1 movimento').evaluate().isNotEmpty);

    await tester.tap(find.text('Esporta 1 movimento'));
    await waitFor(tester, () => sharer.shared.isNotEmpty);

    expect(sharer.shared.single, endsWith('movimenti_2026-10-01_2026-10-31.csv'));
    final content = (await db(tester, () => File(sharer.shared.single).readAsString()));
    expect(content, contains('02/10/2026;spesa;64,20;EUR;Conto corrente;;${category.name};;Esselunga;tx-1'));
    await finish(tester);
  });

  testWidgets('blocco attivo: all\'apertura serve la biometria', (tester) async {
    await pumpAt(tester, AppRoutes.transactions, lockEnabled: true);
    // Il primo tentativo automatico riesce con la biometria finta.
    expect(find.text('Finanze è bloccata'), findsNothing);
    expect(biometric.calls, 1);
    await finish(tester);
  });

  testWidgets('blocco attivo e biometria fallita: resta la schermata di sblocco', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final failing = FakeBiometricAuth(succeeds: false);
    final memory = AppDatabase(NativeDatabase.memory());
    final scoped = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(memory), biometricAuthProvider.overrideWithValue(failing)],
    );
    addTearDown(() async {
      scoped.dispose();
      await memory.close();
    });
    await tester.runAsync(() async {
      await scoped.read(localPreferencesRepositoryProvider).save(const LocalPreferences(biometricLock: true));
      scoped.listen(localPreferencesProvider, (_, _) {});
      await scoped.read(localPreferencesProvider.future);
    });
    await tester.pumpWidget(UncontrolledProviderScope(container: scoped, child: const App()));
    await tester.pumpAndSettle();

    expect(find.text('Finanze è bloccata'), findsOneWidget);
    expect(find.text('Sblocco non riuscito. Riprova.'), findsOneWidget);
    failing.succeeds = true;
    await tester.tap(find.text('Sblocca'));
    await tester.pumpAndSettle();
    expect(find.text('Finanze è bloccata'), findsNothing);
    await finish(tester);
  });
}
