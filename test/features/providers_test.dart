import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:spese_entrate/core/dates.dart';
import 'package:spese_entrate/core/ids.dart';
import 'package:spese_entrate/data/db/app_database.dart';
import 'package:spese_entrate/data/db/database_provider.dart';
import 'package:spese_entrate/data/repositories/repository_providers.dart';
import 'package:spese_entrate/domain/models/enums.dart';
import 'package:spese_entrate/domain/models/statistics.dart';
import 'package:spese_entrate/domain/models/transaction.dart';
import 'package:spese_entrate/features/analytics/application/statistics_providers.dart';
import 'package:spese_entrate/features/transactions/application/transaction_providers.dart';
import 'package:spese_entrate/features/wallets/application/wallet_providers.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late ProviderContainer container;
  late String checkingId;
  late String cashId;

  setUp(() async {
    final db = AppDatabase(NativeDatabase.memory(), now: () => DateTime.utc(2026, 10, 10, 8));
    container = ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(db)]);
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    final wallets = await container.read(walletRepositoryProvider).watchAll().first;
    checkingId = wallets.firstWhere((w) => w.type == WalletType.checking).id;
    cashId = wallets.firstWhere((w) => w.type == WalletType.cash).id;
  });

  /// Legge un provider che si auto-elimina tenendolo in ascolto durante la lettura.
  Future<T> read<T>(ProviderListenable<Future<T>> provider) async {
    final subscription = container.listen(provider, (_, _) {});
    try {
      return await subscription.read();
    } finally {
      subscription.close();
    }
  }

  Future<void> save(Transaction tx) => container.read(transactionRepositoryProvider).save(tx);

  Transaction tx(TransactionType type, int cents, {String? walletId, String? toWalletId, TransactionStatus? status}) =>
      Transaction(
        id: newId(),
        type: type,
        status: status ?? TransactionStatus.confirmed,
        amountCents: cents,
        date: LocalDate(2026, 10, 5),
        walletId: walletId ?? checkingId,
        toWalletId: toWalletId,
        categoryId: type == TransactionType.expense || type == TransactionType.income ? 'cat' : null,
      );

  test('saldi e patrimonio dal database', () async {
    await save(tx(TransactionType.income, 100000));
    await save(tx(TransactionType.expense, 25000));
    await save(tx(TransactionType.expense, 99999, status: TransactionStatus.pending));
    await save(tx(TransactionType.transfer, 10000, toWalletId: cashId));
    await save(tx(TransactionType.adjustment, -500, walletId: cashId));

    expect(await read(walletBalancesProvider.future), {checkingId: 65000, cashId: 9500});
    expect(await read(netWorthProvider.future), 74500);
  });

  test('riepilogo e grafici escludono trasferimenti, rettifiche e pending', () async {
    await save(tx(TransactionType.income, 100000));
    await save(tx(TransactionType.expense, 25000));
    await save(tx(TransactionType.expense, 99999, status: TransactionStatus.pending));
    await save(tx(TransactionType.transfer, 10000, toWalletId: cashId));
    await save(tx(TransactionType.adjustment, -500));

    final october = Period.containing(PeriodType.month, LocalDate(2026, 10, 1)).range;
    expect(
      await read(periodSummaryProvider(october).future),
      const PeriodSummary(incomeCents: 100000, expenseCents: 25000),
    );
    expect(await read(categoryBreakdownProvider(october, CategoryKind.expense).future), const [
      BreakdownItem(id: 'cat', totalCents: 25000, share: 1),
    ]);
  });
}
