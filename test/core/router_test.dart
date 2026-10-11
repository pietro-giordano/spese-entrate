import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spese_entrate/app.dart';
import 'package:spese_entrate/core/router/app_router.dart';
import 'package:spese_entrate/core/router/app_routes.dart';
import 'package:spese_entrate/data/db/app_database.dart';
import 'package:spese_entrate/data/db/database_provider.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/features/transactions/presentation/quick_add_screen.dart';
import 'package:spese_entrate/features/transactions/presentation/transactions_screen.dart';

/// Avvia l'app su uno schermo da telefono con un database in memoria
/// e restituisce il router, per poter navigare direttamente negli indirizzi.
Future<GoRouter> pumpApp(WidgetTester tester) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final db = AppDatabase(NativeDatabase.memory());
  final container = ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(db)]);
  addTearDown(() async {
    container.dispose();
    await db.close();
  });
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const App()));
  await tester.pumpAndSettle();
  return container.read(appRouterProvider);
}

void main() {
  testWidgets('si apre sul tab Movimenti, in italiano e con Manrope', (tester) async {
    await pumpApp(tester);

    expect(find.byType(TransactionsScreen), findsOneWidget);
    expect(find.text('Portafogli'), findsOneWidget);

    final context = tester.element(find.byType(TransactionsScreen));
    expect(Localizations.localeOf(context), const Locale('it', 'IT'));
    expect(Theme.of(context).textTheme.bodyMedium?.fontFamily, 'Manrope');
  });

  testWidgets('cambiando tab, quello precedente resta in vita', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Portafogli'));
    await tester.pumpAndSettle();

    expect(find.text('Patrimonio totale'), findsOneWidget);
    // Movimenti non è distrutto, solo nascosto (offstage).
    expect(find.byType(TransactionsScreen), findsNothing);
    expect(find.byType(TransactionsScreen, skipOffstage: false), findsOneWidget);
  });

  testWidgets("l'avatar apre le impostazioni e indietro torna alla home", (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Profilo e impostazioni'));
    await tester.pumpAndSettle();
    expect(find.text('Profilo e impostazioni'), findsOneWidget);

    await tester.tap(find.byTooltip('Indietro'));
    await tester.pumpAndSettle();
    expect(find.byType(TransactionsScreen), findsOneWidget);
  });

  testWidgets("il pulsante Spesa apre l'inserimento rapido a schermo intero", (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Spesa'));
    await tester.pumpAndSettle();

    final quickAdd = tester.widget<QuickAddScreen>(find.byType(QuickAddScreen));
    expect(quickAdd.type, TransactionType.expense);
    final route = ModalRoute.of(tester.element(find.byType(QuickAddScreen)))!;
    expect(route is PageRoute && route.fullscreenDialog, isTrue);
    // Copre anche la barra dei tab.
    expect(find.text('Grafici'), findsNothing);

    await tester.tap(find.byTooltip('Chiudi'));
    await tester.pumpAndSettle();
    expect(find.byType(QuickAddScreen), findsNothing);
  });

  testWidgets('tutte le rotte della sezione Navigazione aprono una schermata', (tester) async {
    final router = await pumpApp(tester);

    final expectedTitles = {
      AppRoutes.wallets: 'Portafogli',
      AppRoutes.charts: 'Grafici',
      AppRoutes.compare: 'Confronta',
      AppRoutes.add('income'): 'Salva entrata',
      AppRoutes.transaction('t1'): 'Movimento', // non esiste: pagina di movimento mancante
      AppRoutes.filters: 'Filtri',
      AppRoutes.newWallet: 'Nuovo portafoglio',
      AppRoutes.wallet('w1'): 'Portafoglio', // non esiste: pagina di portafoglio mancante
      AppRoutes.editWallet('w1'): 'Portafoglio',
      AppRoutes.settings: 'Profilo e impostazioni',
      AppRoutes.categories: 'Categorie e label',
      AppRoutes.recurring: 'Movimenti ricorrenti',
      AppRoutes.recurrence('r1'): 'Ricorrenza',
      AppRoutes.backup: 'Backup ed esportazione',
      AppRoutes.componentCatalog: 'Catalogo componenti',
    };

    for (final MapEntry(key: location, value: title) in expectedTitles.entries) {
      router.go(location);
      await tester.pumpAndSettle();
      // Le schermate lasciate chiudono i loro stream Drift con un timer a durata zero: lo si fa scattare.
      await tester.pump(const Duration(milliseconds: 10));
      // "Portafogli" compare anche nella barra dei tab: basta che il titolo ci sia.
      expect(find.text(title), findsWidgets, reason: location);
      expect(find.textContaining('GoException'), findsNothing, reason: location);
    }
  });
}
