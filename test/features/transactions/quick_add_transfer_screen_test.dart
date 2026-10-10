import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:spese_entrate/app.dart';
import 'package:spese_entrate/core/clock.dart';
import 'package:spese_entrate/core/router/app_router.dart';
import 'package:spese_entrate/core/router/app_routes.dart';
import 'package:spese_entrate/data/db/app_database.dart';
import 'package:spese_entrate/data/db/database_provider.dart';
import 'package:spese_entrate/data/files/attachment_picker.dart';
import 'package:spese_entrate/data/files/attachment_storage.dart';
import 'package:spese_entrate/data/repositories/repository_providers.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/transaction.dart';
import 'package:spese_entrate/features/transactions/presentation/quick_add_screen.dart';
import 'package:spese_entrate/features/transactions/presentation/widgets/amount_keypad.dart';

/// Selettore finto: restituisce un PDF, oppure simula il permesso negato per la fotocamera.
class FakeAttachmentPicker extends AttachmentPicker {
  var _count = 0;

  PickedAttachment _pdf() {
    final name = 'documento${++_count}.pdf';
    return PickedAttachment(name: name, mimeType: 'application/pdf', openRead: () => Stream.value(utf8.encode(name)));
  }

  @override
  Future<PickedAttachment?> pickFile() async => _pdf();

  @override
  Future<PickedAttachment?> pickFromGallery() async => _pdf();

  @override
  Future<PickedAttachment?> takePhoto() async => throw PlatformException(code: 'camera_access_denied');
}

void main() {
  setUpAll(() => initializeDateFormatting('it_IT'));

  late ProviderContainer container;
  late Directory documents;

  Future<void> pumpQuickAdd(WidgetTester tester, String location) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    documents = (await tester.runAsync(() => Directory.systemTemp.createTemp('spese_entrate_docs_')))!;
    final db = AppDatabase(NativeDatabase.memory(), now: () => DateTime.utc(2026, 10, 10, 8));
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 10, 9)),
        attachmentPickerProvider.overrideWithValue(FakeAttachmentPicker()),
        attachmentStorageProvider.overrideWithValue(AttachmentStorage(documentsDirectory: () async => documents)),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
      await documents.delete(recursive: true);
    });
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const App()));
    await tester.pumpAndSettle();
    container.read(appRouterProvider).push(location);
    await tester.pumpAndSettle();
  }

  Future<List<Transaction>> stored(WidgetTester tester) async =>
      (await tester.runAsync(() => container.read(transactionRepositoryProvider).watchAll().first))!;

  Future<String> walletId(WidgetTester tester, String name) async {
    final wallets = (await tester.runAsync(() => container.read(walletRepositoryProvider).watchAll().first))!;
    return wallets.firstWhere((w) => w.name == name).id;
  }

  Future<void> typeAmount(WidgetTester tester, String digits) async {
    for (final digit in digits.split('')) {
      await tester.tap(find.descendant(of: find.byType(AmountKeypad), matching: find.text(digit)));
      await tester.pump();
    }
  }

  /// Il salvataggio copia file veri: lascia lavorare l'I/O reale finché la schermata si chiude.
  Future<void> waitUntilClosed(WidgetTester tester) async {
    for (var i = 0; i < 50 && find.byType(QuickAddScreen).evaluate().isNotEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  testWidgets('trasferimento: Da/A precompilati, inversione e salvataggio', (tester) async {
    await pumpQuickAdd(tester, AppRoutes.add('transfer'));

    expect(find.text('Salva trasferimento'), findsOneWidget);
    expect(find.text('Categoria'.toUpperCase()), findsNothing);
    expect(find.bySemanticsLabel('Da: Conto corrente'), findsOneWidget);
    expect(find.bySemanticsLabel('A: Contanti'), findsOneWidget);

    await tester.tap(find.byTooltip('Inverti portafogli'));
    await tester.pump();
    expect(find.bySemanticsLabel('Da: Contanti'), findsOneWidget);
    expect(find.bySemanticsLabel('A: Conto corrente'), findsOneWidget);

    await typeAmount(tester, '5000');
    await tester.tap(find.text('Salva trasferimento'));
    await tester.pumpAndSettle();

    expect(find.byType(QuickAddScreen), findsNothing);
    expect(find.text('Trasferimento di € 50,00 salvato'), findsOneWidget);
    final saved = (await stored(tester)).single;
    expect(saved.type, TransactionType.transfer);
    expect(saved.walletId, await walletId(tester, 'Contanti'));
    expect(saved.toWalletId, await walletId(tester, 'Conto corrente'));
    expect(saved.categoryId, isNull);
  });

  testWidgets('trasferimento: scegliere come origine la destinazione scambia i portafogli', (tester) async {
    await pumpQuickAdd(tester, AppRoutes.add('transfer'));

    await tester.tap(find.bySemanticsLabel('Da: Conto corrente'));
    await tester.pumpAndSettle();
    expect(find.text('Trasferisci da'), findsOneWidget);
    expect(find.text('€ 0,00 · già selezionato come destinazione'), findsOneWidget);

    await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text('Contanti')));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Da: Contanti'), findsOneWidget);
    expect(find.bySemanticsLabel('A: Conto corrente'), findsOneWidget);
  });

  testWidgets('dal segmented: Spesa → Trasferimento nasconde categorie e label', (tester) async {
    await pumpQuickAdd(tester, AppRoutes.add('expense'));
    expect(find.text('CATEGORIA'), findsOneWidget);

    await tester.tap(find.text('Trasferimento'));
    await tester.pumpAndSettle();
    expect(find.text('CATEGORIA'), findsNothing);
    expect(find.textContaining('LABEL'), findsNothing);
    expect(find.text('I trasferimenti non contano come spese o entrate nei grafici.'), findsOneWidget);
  });

  testWidgets('allegati: aggiunta, rimozione, permesso negato e salvataggio dei file', (tester) async {
    await pumpQuickAdd(tester, AppRoutes.add('expense'));

    await tester.tap(find.byTooltip('Allega foto o file'));
    await tester.pumpAndSettle();
    expect(find.text('0 di 5'), findsOneWidget);

    await tester.tap(find.text('Scegli un file (PDF, immagine)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scegli dalla galleria'));
    await tester.pumpAndSettle();
    expect(find.text('2 di 5'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Rimuovi documento1.pdf'));
    await tester.pumpAndSettle();
    expect(find.text('1 di 5'), findsOneWidget);

    await tester.tap(find.text('Scatta una foto'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Accesso alla fotocamera negato'), findsOneWidget);

    await tester.tap(find.text('Fatto'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('1 allegato, apri'), findsOneWidget);

    await typeAmount(tester, '1250');
    await tester.tap(find.text('Spesa alimentare'));
    await tester.tap(find.text('Salva spesa'));
    await waitUntilClosed(tester);

    expect(find.text('Spesa di € 12,50 salvata'), findsOneWidget);
    final saved = (await stored(tester)).single;
    final attachments = (await tester.runAsync(
      () => container.read(transactionRepositoryProvider).getAttachments(saved.id),
    ))!;
    expect(attachments, hasLength(1));
    final file = File('${documents.path}/${attachments.single.localPath}');
    expect(await tester.runAsync(file.readAsString), 'documento2.pdf');
  });

  testWidgets('allegati: oltre 5 le azioni si disattivano', (tester) async {
    await pumpQuickAdd(tester, AppRoutes.add('expense'));
    await tester.tap(find.byTooltip('Allega foto o file'));
    await tester.pumpAndSettle();

    for (var i = 0; i < 6; i++) {
      await tester.tap(find.text('Scegli un file (PDF, immagine)'));
      await tester.pumpAndSettle();
    }
    expect(find.text('5 di 5'), findsOneWidget);
    expect(find.text('Hai raggiunto il massimo di 5 allegati per movimento.'), findsOneWidget);
  });

  testWidgets('/add?type=transfer arriva dal pulsante dei Portafogli', (tester) async {
    await pumpQuickAdd(tester, AppRoutes.wallets);
    // Torna al tab Portafogli (pumpQuickAdd fa push; i tab si raggiungono con go).
    container.read(appRouterProvider).go(AppRoutes.wallets);
    await tester.pumpAndSettle();
    expect(find.text('Trasferisci tra portafogli'), findsOneWidget);
    await tester.tap(find.text('Trasferisci tra portafogli'));
    await tester.pumpAndSettle();
    expect(find.text('Salva trasferimento'), findsOneWidget);
    // Chiudendo si torna ai portafogli.
    await tester.tap(find.byTooltip('Chiudi'));
    await tester.pumpAndSettle();
    expect(GoRouter.of(tester.element(find.text('Portafogli').first)).state.matchedLocation, AppRoutes.wallets);
  });
}
