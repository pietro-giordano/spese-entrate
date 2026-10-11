import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
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
import 'package:spese_entrate/data/repositories/repository_providers.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/transaction.dart';

/// Barra di sistema in basso: navigazione Android a 3 pulsanti, a gesti, barra home dell'iPhone.
const _systemBars = {'3 pulsanti': 48.0, 'gesti': 24.0, 'barra home iPhone': 34.0};
const _keyboard = 320.0;
const _screen = Size(390, 844);

void main() {
  setUpAll(() => initializeDateFormatting('it_IT'));
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late ProviderContainer container;
  late String walletId;
  late String txId;

  /// Come un telefono edge-to-edge: l'app disegna fin sotto la barra di sistema, che arriva
  /// come padding/viewPadding. Con la tastiera aperta il padding in basso diventa 0.
  void setInsets(WidgetTester tester, {required double system, double keyboard = 0}) {
    tester.view.viewPadding = FakeViewPadding(bottom: system);
    tester.view.padding = FakeViewPadding(bottom: keyboard > 0 ? 0 : system);
    tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  }

  Future<void> pumpAt(WidgetTester tester, String Function() location, {required double system}) async {
    tester.view.physicalSize = _screen;
    tester.view.devicePixelRatio = 1;
    setInsets(tester, system: system);
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
    await tester.runAsync(() async {
      walletId = (await db.select(db.wallets).get()).first.id;
      txId = newId();
      await container
          .read(transactionRepositoryProvider)
          .save(
            Transaction(
              id: txId,
              type: TransactionType.expense,
              amountCents: 6420,
              date: LocalDate(2026, 10, 3),
              walletId: walletId,
              categoryId: (await db.select(db.categories).get()).first.id,
            ),
          );
    });
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const App()));
    await tester.pumpAndSettle();
    final path = location();
    if (path != AppRoutes.transactions) {
      container.read(appRouterProvider).go(path);
      await tester.pumpAndSettle();
    }
  }

  /// Il fondo di [finder] sta sopra l'ostacolo in basso alto [obstacle].
  void expectAbove(WidgetTester tester, Finder finder, double obstacle, {String? reason}) {
    final bottom = tester.getRect(finder.first).bottom;
    expect(bottom, lessThanOrEqualTo(_screen.height - obstacle), reason: reason);
  }

  final fixedButtons = <String, (String Function(), Finder Function())>{
    'Filtri': (() => AppRoutes.filters, () => find.text('Applica filtri')),
    'Modifica movimento': (() => AppRoutes.transaction(txId), () => find.text('Salva modifiche')),
    'Nuovo portafoglio': (() => AppRoutes.newWallet, () => find.text('Crea portafoglio')),
    'Inserimento rapido': (() => AppRoutes.add('expense'), () => find.text('Salva spesa')),
    'Movimenti (barra delle tab)': (() => AppRoutes.transactions, () => find.text('Confronta')),
  };

  for (final MapEntry(key: bar, value: system) in _systemBars.entries) {
    group('barra di sistema: $bar', () {
      for (final MapEntry(key: screen, value: (location, button)) in fixedButtons.entries) {
        testWidgets('$screen: il pulsante in basso resta sopra la barra di sistema', (tester) async {
          await pumpAt(tester, location, system: system);
          expectAbove(tester, button(), system);
          await tester.pump(const Duration(milliseconds: 10));
        });
      }

      testWidgets('con la tastiera aperta i pulsanti fissi salgono sopra la tastiera', (tester) async {
        await pumpAt(tester, () => AppRoutes.transaction(txId), system: system);
        await tester.showKeyboard(find.byType(TextField).last); // nota
        setInsets(tester, system: system, keyboard: _keyboard);
        await tester.pumpAndSettle();
        expectAbove(tester, find.text('Salva modifiche'), _keyboard);
        // Il campo attivo resta visibile tra l'intestazione e la barra.
        final field = tester.getRect(find.byType(TextField).last);
        final bar = tester.getRect(find.text('Salva modifiche'));
        expect(field.bottom, lessThanOrEqualTo(bar.top));
        expect(field.top, greaterThan(0));
        await tester.pump(const Duration(milliseconds: 10));
      });

      testWidgets('inserimento rapido con la nota: tastierino nascosto, "Salva" sopra la tastiera', (tester) async {
        await pumpAt(tester, () => AppRoutes.add('expense'), system: system);
        await tester.showKeyboard(find.byType(TextField));
        setInsets(tester, system: system, keyboard: _keyboard);
        await tester.pumpAndSettle();
        expectAbove(tester, find.text('Salva spesa'), _keyboard);
        expect(find.text('00'), findsNothing, reason: 'il tastierino lascia spazio alla tastiera');
        expect(
          tester.getRect(find.byType(TextField)).bottom,
          lessThanOrEqualTo(tester.getRect(find.text('Salva spesa')).top),
        );
        await tester.pump(const Duration(milliseconds: 10));
      });

      testWidgets('pannello della data: "Conferma" sopra la barra di sistema, anche dalle tab', (tester) async {
        await pumpAt(tester, () => AppRoutes.add('expense'), system: system);
        await tester.tap(find.bySemanticsLabel(RegExp('^Data del movimento')));
        await tester.pumpAndSettle();
        final confirm = find.descendant(of: find.byType(BottomSheet), matching: find.text('Conferma'));
        await tester.ensureVisible(confirm);
        await tester.pumpAndSettle();
        expectAbove(tester, confirm, system);
        await tester.pump(const Duration(milliseconds: 10));
      });

      testWidgets('Aggiorna saldo: con la tastiera il campo e "Salva" restano visibili', (tester) async {
        await pumpAt(tester, () => AppRoutes.wallet(walletId), system: system);
        await tester.tap(find.text('Aggiorna saldo'));
        await tester.pumpAndSettle();
        setInsets(tester, system: system, keyboard: _keyboard);
        await tester.pumpAndSettle();
        // Lo sfondo del pannello arriva fino in fondo (dietro la tastiera); il contenuto sale.
        final sheet = find.byType(BottomSheet);
        final field = find.descendant(of: sheet, matching: find.byType(TextField));
        expect(tester.getRect(field).bottom, lessThanOrEqualTo(_screen.height - _keyboard));
        expect(tester.getRect(field).top, greaterThanOrEqualTo(0));
        // "Salva aggiornamento" si raggiunge scorrendo il pannello, sempre sopra la tastiera.
        final save = find.descendant(of: sheet, matching: find.text('Salva aggiornamento'));
        await tester.ensureVisible(save);
        await tester.pumpAndSettle();
        expectAbove(tester, save, _keyboard);
        await tester.pump(const Duration(milliseconds: 10));
      });

      testWidgets('liste fuori dalle tab: l\'ultima voce si porta sopra la barra di sistema', (tester) async {
        await pumpAt(tester, () => AppRoutes.categories, system: system);
        final add = find.text('+ Nuova categoria');
        await tester.scrollUntilVisible(add, 300, scrollable: find.byType(Scrollable).first);
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -1000));
        await tester.pumpAndSettle();
        expectAbove(tester, add, system);
        await tester.pump(const Duration(milliseconds: 10));
      });
    });
  }
}
