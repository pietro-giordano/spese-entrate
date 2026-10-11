import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:spese_entrate/app.dart';
import 'package:spese_entrate/core/clock.dart';
import 'package:spese_entrate/core/router/app_router.dart';
import 'package:spese_entrate/core/router/app_routes.dart';
import 'package:spese_entrate/core/widgets/tab_header.dart';
import 'package:spese_entrate/data/db/app_database.dart';
import 'package:spese_entrate/data/db/database_provider.dart';
import 'package:spese_entrate/features/settings/presentation/settings_screen.dart';

/// Ogni tab ha l'avatar "Profilo e impostazioni", ultimo a destra nell'intestazione.
void main() {
  setUpAll(() => initializeDateFormatting('it_IT'));
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late ProviderContainer container;

  Future<void> pumpTab(WidgetTester tester, String location) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory(), now: () => DateTime.utc(2026, 10, 3, 8));
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 3, 9)),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const App()));
    await tester.pumpAndSettle();
    container.read(appRouterProvider).go(location);
    await tester.pumpAndSettle();
  }

  final tabs = {
    'Movimenti': (AppRoutes.transactions, ['Cerca', 'Filtri']),
    'Portafogli': (AppRoutes.wallets, ['Nuovo portafoglio']),
    'Grafici': (AppRoutes.charts, <String>[]),
    'Confronta': (AppRoutes.compare, <String>[]),
  };

  for (final MapEntry(key: title, value: (location, actions)) in tabs.entries) {
    testWidgets('$title: azioni della schermata, poi l\'avatar che apre le impostazioni', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpTab(tester, location);

      final header = find.byType(TabHeader);
      expect(header, findsOneWidget);
      expect(find.descendant(of: header, matching: find.text(title)), findsOneWidget);

      final avatar = find.descendant(of: header, matching: find.byTooltip('Profilo e impostazioni'));
      expect(avatar, findsOneWidget);
      final avatarRect = tester.getRect(avatar);
      expect(avatarRect.width, greaterThanOrEqualTo(44));
      expect(avatarRect.height, greaterThanOrEqualTo(44));
      expect(find.bySemanticsLabel('Profilo e impostazioni'), findsOneWidget);

      // Le azioni esistenti restano, tutte prima (a sinistra) dell'avatar.
      for (final action in actions) {
        final button = find.descendant(of: header, matching: find.byTooltip(action));
        expect(button, findsOneWidget, reason: action);
        expect(tester.getRect(button).right, lessThan(avatarRect.left), reason: action);
        expect(tester.getSize(button), const Size(44, 44), reason: action);
      }
      expect(avatarRect.right, closeTo(tester.getRect(header).right, 0.5), reason: 'sempre l\'ultimo a destra');

      await tester.tap(avatar);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      semantics.dispose();
      await tester.pump(const Duration(milliseconds: 10));
    });
  }
}
