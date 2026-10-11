import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:spese_entrate/core/clock.dart';
import 'package:spese_entrate/core/dates.dart';
import 'package:spese_entrate/core/ids.dart';
import 'package:spese_entrate/data/db/app_database.dart';
import 'package:spese_entrate/data/db/database_provider.dart';
import 'package:spese_entrate/data/repositories/drift_settings_repository.dart';
import 'package:spese_entrate/data/repositories/drift_wallet_repository.dart';
import 'package:spese_entrate/domain/models/app_settings.dart';
import 'package:spese_entrate/data/repositories/repository_providers.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/wallet.dart';
import 'package:spese_entrate/domain/services/balances.dart';
import 'package:spese_entrate/features/wallets/application/wallet_providers.dart';
import 'package:spese_entrate/features/wallets/presentation/widgets/wallet_visuals.dart';

/// Salva il portafoglio ma fallisce sulle impostazioni (seconda scrittura di WalletActions.save).
class FailingSettingsRepository extends DriftSettingsRepository {
  FailingSettingsRepository(super.db);

  @override
  Future<void> save(AppSettings settings) => Future.error(StateError('impostazioni non salvabili'));
}

/// Fallisce sul salvataggio del portafoglio (la verifica, ultima scrittura di updateBalance).
class FailingWalletRepository extends DriftWalletRepository {
  FailingWalletRepository(super.db);

  @override
  Future<void> save(Wallet wallet) => Future.error(StateError('portafoglio non salvabile'));
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late ProviderContainer container;
  late AppDatabase db;
  late Wallet checking;
  late Wallet cash;

  ProviderContainer makeContainer([List<Override> extra = const []]) {
    final created = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 3, 9)),
        ...extra,
      ],
    );
    addTearDown(created.dispose);
    return created;
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory(), now: () => DateTime.utc(2026, 10, 3, 8));
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

  group('aggiorna saldo: verifica separata dal movimento', () {
    Future<WalletOverview> overviewOf(Wallet wallet) async {
      container.listen(walletOverviewsProvider, (_, _) {});
      return (await container.read(walletOverviewsProvider.future)).firstWhere((o) => o.wallet.id == wallet.id);
    }

    late Wallet stale;
    setUp(() async {
      stale = Wallet(
        id: newId(),
        name: 'Fondo pensione',
        type: WalletType.investment,
        initialBalanceCents: 792000,
        initialBalanceDate: LocalDate(2026, 8, 1),
      );
      await container.read(walletRepositoryProvider).save(stale);
    });

    test('differenza zero: nessun movimento, ma la verifica si aggiorna', () async {
      expect((await overviewOf(stale)).needsUpdate, isTrue);

      final created = await actions().updateBalance(
        wallet: stale,
        newBalanceCents: 792000,
        date: LocalDate(2026, 10, 3),
        mode: BalanceUpdateMode.adjustment,
      );

      expect(created, isNull);
      expect(await container.read(transactionRepositoryProvider).getAll(), isEmpty, reason: 'niente movimenti da 0 €');
      final overview = await overviewOf(stale);
      expect(overview.lastUpdate, LocalDate(2026, 10, 3));
      expect(overview.needsUpdate, isFalse);
      expect(overview.wallet.lastBalanceVerifiedDate, LocalDate(2026, 10, 3));
    });

    test('registrata come entrata o spesa: la verifica si aggiorna comunque', () async {
      final categories = await container.read(categoryRepositoryProvider).watchAll().first;
      final created = await actions().updateBalance(
        wallet: stale,
        newBalanceCents: 800000,
        date: LocalDate(2026, 10, 3),
        mode: BalanceUpdateMode.movement,
        categoryId: categories.firstWhere((c) => c.kind == CategoryKind.income).id,
      );

      expect(created!.type, TransactionType.income);
      final overview = await overviewOf(stale);
      expect(overview.balanceCents, 800000);
      expect(overview.lastUpdate, LocalDate(2026, 10, 3));
      expect(overview.needsUpdate, isFalse);
    });

    test('verificare una data passata non cancella una verifica più recente', () async {
      await actions().updateBalance(
        wallet: stale,
        newBalanceCents: 792000,
        date: LocalDate(2026, 10, 1),
        mode: BalanceUpdateMode.adjustment,
      );
      await actions().updateBalance(
        wallet: stale,
        newBalanceCents: 792000,
        date: LocalDate(2026, 9, 1),
        mode: BalanceUpdateMode.adjustment,
      );
      expect((await overviewOf(stale)).wallet.lastBalanceVerifiedDate, LocalDate(2026, 10, 1));
    });

    test('non sovrascrive modifiche al portafoglio fatte nel frattempo', () async {
      await container.read(walletRepositoryProvider).save(stale.copyWith(name: 'Fondo pensione aperto'));
      // [stale] è la versione vecchia, ancora col nome precedente.
      await actions().updateBalance(
        wallet: stale,
        newBalanceCents: 792000,
        date: LocalDate(2026, 10, 3),
        mode: BalanceUpdateMode.adjustment,
      );
      expect((await container.read(walletRepositoryProvider).getById(stale.id))!.name, 'Fondo pensione aperto');
    });
  });

  group('atomicità', () {
    Future<int> outboxCount() async => (await db.select(db.outbox).get()).length;

    test('creazione con predefiniti: se le impostazioni falliscono, il portafoglio non resta', () async {
      final failing = makeContainer([
        settingsRepositoryProvider.overrideWith((ref) => FailingSettingsRepository(ref.watch(appDatabaseProvider))),
      ]);
      final before = await outboxCount();
      final wallet = Wallet(
        id: newId(),
        name: 'Nuovo',
        type: WalletType.card,
        initialBalanceDate: LocalDate(2026, 10, 3),
      );

      await expectLater(
        failing.read(walletActionsProvider).save(wallet, defaultForExpenses: true, defaultForIncome: false),
        throwsStateError,
      );

      expect(await container.read(walletRepositoryProvider).getById(wallet.id), isNull);
      expect(await defaults(), (expense: checking.id, income: checking.id));
      expect(await outboxCount(), before, reason: 'nemmeno l\'outbox conserva la scrittura annullata');
    });

    test('archiviazione: se le impostazioni falliscono, il portafoglio non risulta archiviato', () async {
      final failing = makeContainer([
        settingsRepositoryProvider.overrideWith((ref) => FailingSettingsRepository(ref.watch(appDatabaseProvider))),
      ]);
      await expectLater(failing.read(walletActionsProvider).archive(checking), throwsStateError);
      expect((await container.read(walletRepositoryProvider).getById(checking.id))!.isArchived, isFalse);
    });

    test('aggiorna saldo: se la verifica fallisce, il movimento non resta', () async {
      final failing = makeContainer([
        walletRepositoryProvider.overrideWith((ref) => FailingWalletRepository(ref.watch(appDatabaseProvider))),
      ]);
      final before = await outboxCount();

      await expectLater(
        failing
            .read(walletActionsProvider)
            .updateBalance(
              wallet: cash,
              newBalanceCents: 5000,
              date: LocalDate(2026, 10, 3),
              mode: BalanceUpdateMode.adjustment,
            ),
        throwsStateError,
      );

      expect(await container.read(transactionRepositoryProvider).getAll(), isEmpty);
      expect(await outboxCount(), before);
    });
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
