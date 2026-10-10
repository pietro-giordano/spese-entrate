import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:spese_entrate/core/clock.dart';
import 'package:spese_entrate/core/dates.dart';
import 'package:spese_entrate/data/db/app_database.dart';
import 'package:spese_entrate/data/db/database_provider.dart';
import 'package:spese_entrate/data/repositories/repository_providers.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/wallet.dart';
import 'package:spese_entrate/features/transactions/application/quick_add_controller.dart';
import 'package:spese_entrate/features/transactions/presentation/widgets/date_picker_sheet.dart';

void main() {
  group('applyKeypadKey', () {
    int type(String keys) => keys.split(' ').fold(0, applyKeypadKey);

    test('le cifre entrano da destra in centesimi', () {
      expect(type('6'), 6);
      expect(type('6 4'), 64);
      expect(type('6 4 2 0'), 6420);
      expect(type('1 00'), 100);
      expect(type('0 0 5'), 5);
    });

    test('cancella toglie l\'ultima cifra', () {
      expect(type('6 4 2 0 $backspaceKey'), 642);
      expect(type(backspaceKey), 0);
    });

    test('oltre 9 cifre i tasti vengono ignorati', () {
      expect(type('9 9 9 9 9 9 9 9 9'), maxKeypadCents);
      expect(type('9 9 9 9 9 9 9 9 9 1'), maxKeypadCents);
      expect(type('1 2 3 4 5 6 7 8 00'), 12345678);
    });
  });

  group('resolveWalletId', () {
    Wallet wallet(String id, {bool archived = false}) => Wallet(
      id: id,
      name: id,
      type: WalletType.cash,
      initialBalanceDate: LocalDate(2026, 1, 1),
      archivedAt: archived ? DateTime.utc(2026) : null,
    );
    final wallets = [wallet('a'), wallet('b'), wallet('old', archived: true)];

    test('la scelta fatta prevale sul predefinito', () {
      expect(resolveWalletId(chosenId: 'b', defaultId: 'a', wallets: wallets), 'b');
    });

    test('senza scelta usa il predefinito', () {
      expect(resolveWalletId(chosenId: null, defaultId: 'b', wallets: wallets), 'b');
    });

    test('ignora portafogli archiviati o inesistenti e ripiega sul primo', () {
      expect(resolveWalletId(chosenId: 'old', defaultId: 'missing', wallets: wallets), 'a');
      expect(resolveWalletId(chosenId: null, defaultId: null, wallets: const []), isNull);
    });
  });

  group('dateChipLabel', () {
    setUpAll(() => initializeDateFormatting('it_IT'));
    final today = LocalDate(2026, 10, 10);

    test('Oggi, Ieri, giorno e mese, anno se diverso', () {
      expect(dateChipLabel(today, today), 'Oggi');
      expect(dateChipLabel(LocalDate(2026, 10, 9), today), 'Ieri');
      expect(dateChipLabel(LocalDate(2026, 10, 3), today), '3 ott');
      expect(dateChipLabel(LocalDate(2025, 12, 24), today), '24 dic 2025');
    });
  });

  group('QuickAddController', () {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    late ProviderContainer container;
    final provider = quickAddControllerProvider(TransactionType.expense);

    setUp(() {
      final db = AppDatabase(NativeDatabase.memory(), now: () => DateTime.utc(2026, 10, 10, 8));
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => DateTime(2026, 10, 10, 9)),
        ],
      );
      // Il controller si auto-elimina: un ascoltatore lo tiene in vita durante il test.
      container.listen(provider, (_, _) {});
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
    });

    QuickAddController controller() => container.read(provider.notifier);
    QuickAddState state() => container.read(provider);

    test('parte dal tipo scelto e dalla data di oggi', () {
      expect(state().type, TransactionType.expense);
      expect(state().date, LocalDate(2026, 10, 10));
      expect(state().amountCents, 0);
    });

    test('senza importo o categoria non salva e mostra gli errori', () async {
      expect(await controller().save(walletId: 'w'), isNull);
      expect(state().showErrors, isTrue);
      expect(state().isAmountMissing, isTrue);
      expect(state().isCategoryMissing, isTrue);

      controller().pressKey('5');
      expect(await controller().save(walletId: 'w'), isNull);
      expect(await container.read(transactionRepositoryProvider).watchAll().first, isEmpty);
    });

    test('cambiare tipo azzera la categoria', () {
      controller().selectCategory('groceries');
      controller().setType(TransactionType.income);
      expect(state().categoryId, isNull);
    });

    test('il portafoglio scelto a mano vale per il suo tipo', () {
      controller().chooseWallet('cash');
      expect(state().chosenWalletId, 'cash');
      controller().setType(TransactionType.income);
      expect(state().chosenWalletId, isNull);
    });

    test('salva un movimento confermato con label e nota ripulita', () async {
      for (final key in ['6', '4', '2', '0']) {
        controller().pressKey(key);
      }
      controller()
        ..selectCategory('groceries')
        ..toggleLabel('home')
        ..toggleLabel('holiday')
        ..toggleLabel('holiday')
        ..setDate(LocalDate(2026, 10, 9))
        ..setNote('  Esselunga  ');

      final saved = await controller().save(walletId: 'cc');
      expect(saved, isNotNull);

      final stored = (await container.read(transactionRepositoryProvider).watchAll().first).single;
      expect(stored.id, saved!.id);
      expect(stored.type, TransactionType.expense);
      expect(stored.status, TransactionStatus.confirmed);
      expect(stored.amountCents, 6420);
      expect(stored.date, LocalDate(2026, 10, 9));
      expect(stored.walletId, 'cc');
      expect(stored.categoryId, 'groceries');
      expect(stored.labelIds, ['home']);
      expect(stored.note, 'Esselunga');
    });

    test('una nota fatta di soli spazi diventa null', () async {
      controller()
        ..pressKey('1')
        ..selectCategory('c')
        ..setNote('   ');
      final saved = await controller().save(walletId: 'cc');
      expect(saved!.note, isNull);
    });
  });
}
