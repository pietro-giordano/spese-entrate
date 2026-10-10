import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:spese_entrate/core/clock.dart';
import 'package:spese_entrate/core/dates.dart';
import 'package:spese_entrate/core/ids.dart';
import 'package:spese_entrate/data/db/app_database.dart';
import 'package:spese_entrate/data/db/database_provider.dart';
import 'package:spese_entrate/data/repositories/repository_providers.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/wallet.dart';
import 'package:spese_entrate/domain/services/balances.dart';
import 'package:spese_entrate/features/wallets/application/wallet_providers.dart';
import 'package:spese_entrate/features/wallets/presentation/widgets/wallet_visuals.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late ProviderContainer container;
  late Wallet checking;
  late Wallet cash;

  setUp(() async {
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
    final wallets = await container.read(walletRepositoryProvider).watchAll().first;
    checking = wallets.firstWhere((w) => w.type == WalletType.checking);
    cash = wallets.firstWhere((w) => w.type == WalletType.cash);
  });

  WalletActions actions() => container.read(walletActionsProvider);
  Future<({String? expense, String? income})> defaults() async {
    final settings = await container.read(settingsRepositoryProvider).watch().first;
    return (expense: settings.defaultExpenseWalletId, income: settings.defaultIncomeWalletId);
  }

  group('predefiniti', () {
    test('sceglierne uno nuovo sostituisce il precedente', () async {
      expect(await defaults(), (expense: checking.id, income: checking.id));

      await actions().save(cash, defaultForExpenses: true, defaultForIncome: false);
      expect(await defaults(), (expense: cash.id, income: checking.id));
    });

    test('togliere il predefinito lascia vuota la scelta', () async {
      await actions().save(checking, defaultForExpenses: false, defaultForIncome: true);
      expect(await defaults(), (expense: null, income: checking.id));
    });

    test('salvare un altro portafoglio non tocca i predefiniti', () async {
      await actions().save(cash.copyWith(name: 'Spiccioli'), defaultForExpenses: false, defaultForIncome: false);
      expect(await defaults(), (expense: checking.id, income: checking.id));
    });
  });

  test('archiviare toglie i predefiniti; ripristinare riporta il portafoglio tra gli attivi', () async {
    await actions().archive(checking);
    final archived = await container.read(walletRepositoryProvider).getById(checking.id);
    expect(archived!.isArchived, isTrue);
    expect(await defaults(), (expense: null, income: null));

    await actions().unarchive(archived);
    expect((await container.read(walletRepositoryProvider).getById(checking.id))!.isArchived, isFalse);
  });

  test('updateBalance registra una rettifica che aggiorna saldo e data', () async {
    container.listen(walletOverviewsProvider, (_, _) {});
    await actions().updateBalance(
      wallet: cash,
      newBalanceCents: 8650,
      date: LocalDate(2026, 10, 3),
      mode: BalanceUpdateMode.adjustment,
    );
    final overview = (await container.read(walletOverviewsProvider.future)).firstWhere((o) => o.wallet.id == cash.id);
    expect(overview.balanceCents, 8650);
    expect(overview.lastUpdate, LocalDate(2026, 10, 3));
  });

  test('badge Da aggiornare oltre 30 giorni', () async {
    final old = Wallet(
      id: newId(),
      name: 'Fondo pensione',
      type: WalletType.investment,
      initialBalanceDate: LocalDate(2026, 8, 31),
    );
    await container.read(walletRepositoryProvider).save(old);
    container.listen(walletOverviewsProvider, (_, _) {});
    final overviews = await container.read(walletOverviewsProvider.future);
    expect(overviews.firstWhere((o) => o.wallet.id == old.id).needsUpdate, isTrue);
    expect(overviews.firstWhere((o) => o.wallet.id == cash.id).needsUpdate, isFalse);
  });

  group('lastUpdateLabel', () {
    setUpAll(() => initializeDateFormatting('it_IT'));
    final today = LocalDate(2026, 10, 3);

    test('oggi, ieri, data e anno se diverso', () {
      expect(lastUpdateLabel(today, today), 'Aggiornato oggi');
      expect(lastUpdateLabel(LocalDate(2026, 10, 2), today), 'Aggiornato ieri');
      expect(lastUpdateLabel(LocalDate(2026, 9, 28), today), 'Aggiornato il 28 set');
      expect(lastUpdateLabel(LocalDate(2025, 12, 31), today), 'Aggiornato il 31 dic 2025');
    });
  });
}
