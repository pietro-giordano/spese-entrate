import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/clock.dart';
import '../../../core/dates.dart';
import '../../../core/ids.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/transaction.dart';
import '../../../domain/models/wallet.dart';
// Prefisso: le funzioni del servizio hanno gli stessi nomi dei provider qui sotto.
import '../../../domain/services/balances.dart' as balances;
import '../../settings/application/settings_providers.dart';
import '../../transactions/application/transaction_providers.dart';

part 'wallet_providers.g.dart';

/// Portafogli non cancellati, archiviati compresi.
@riverpod
Stream<List<Wallet>> wallets(Ref ref) => ref.watch(walletRepositoryProvider).watchAll();

/// Saldo di ogni portafoglio, per ID. Si ricalcola quando cambiano portafogli o movimenti.
@riverpod
Future<Map<String, int>> walletBalances(Ref ref) async {
  final wallets = await ref.watch(walletsProvider.future);
  final transactions = await ref.watch(allTransactionsProvider.future);
  return balances.walletBalances(wallets, transactions);
}

/// Patrimonio totale (portafogli inclusi nel totale e non archiviati).
@riverpod
Future<int> netWorth(Ref ref) async {
  final wallets = await ref.watch(walletsProvider.future);
  final walletBalances = await ref.watch(walletBalancesProvider.future);
  return balances.netWorth(wallets, walletBalances);
}

/// Un portafoglio con i valori calcolati che servono alle schermate.
class WalletOverview {
  const WalletOverview({
    required this.wallet,
    required this.balanceCents,
    required this.lastUpdate,
    required this.needsUpdate,
    required this.isDefaultForExpenses,
    required this.isDefaultForIncome,
  });

  final Wallet wallet;
  final int balanceCents;

  /// Data dell'ultima rettifica, altrimenti quella del saldo iniziale.
  final LocalDate lastUpdate;

  /// Badge "Da aggiornare": ultimo aggiornamento più vecchio di 30 giorni.
  final bool needsUpdate;
  final bool isDefaultForExpenses;
  final bool isDefaultForIncome;

  /// Conta nel patrimonio totale.
  bool get countsInNetWorth => wallet.includeInTotal && !wallet.isArchived;
}

/// Tutti i portafogli con saldo, ultimo aggiornamento e predefiniti, nell'ordine scelto.
@riverpod
Future<List<WalletOverview>> walletOverviews(Ref ref) async {
  final wallets = await ref.watch(walletsProvider.future);
  final transactions = await ref.watch(allTransactionsProvider.future);
  final settings = await ref.watch(appSettingsProvider.future);
  final today = ref.watch(todayProvider);
  final walletBalances = balances.walletBalances(wallets, transactions);

  return [
    for (final wallet in wallets)
      WalletOverview(
        wallet: wallet,
        balanceCents: walletBalances[wallet.id]!,
        lastUpdate: balances.lastUpdate(wallet, transactions),
        needsUpdate: balances.needsUpdate(wallet, transactions, today),
        isDefaultForExpenses: settings.defaultExpenseWalletId == wallet.id,
        isDefaultForIncome: settings.defaultIncomeWalletId == wallet.id,
      ),
  ];
}

/// Un solo portafoglio (dettaglio e form); null se non esiste.
@riverpod
Future<WalletOverview?> walletOverview(Ref ref, String walletId) async =>
    (await ref.watch(walletOverviewsProvider.future)).firstWhereOrNull((o) => o.wallet.id == walletId);

/// Movimenti che toccano il portafoglio (anche come destinazione di un trasferimento), dal più recente.
@riverpod
Future<List<Transaction>> walletTransactions(Ref ref, String walletId) async {
  final transactions = await ref.watch(allTransactionsProvider.future);
  return transactions.where((tx) => tx.walletId == walletId || tx.toWalletId == walletId).toList();
}

/// Andamento del saldo negli ultimi 6 mesi.
@riverpod
Future<List<({LocalDate date, int balanceCents})>> walletBalanceHistory(Ref ref, String walletId) async {
  final wallet = (await ref.watch(walletsProvider.future)).firstWhereOrNull((w) => w.id == walletId);
  if (wallet == null) return const [];
  final transactions = await ref.watch(walletTransactionsProvider(walletId).future);
  return balances.monthlyBalances(wallet, transactions, ref.watch(todayProvider));
}

/// Operazioni sui portafogli che toccano più repository. Ognuna è atomica ([AtomicWrites]):
/// se una scrittura fallisce non resta nessuno stato parziale.
class WalletActions {
  WalletActions(this._ref);

  final Ref _ref;

  /// Salva il portafoglio e aggiorna i predefiniti: ce n'è al massimo uno per le spese
  /// e uno per le entrate, quindi sceglierne uno nuovo sostituisce il precedente.
  Future<void> save(Wallet wallet, {required bool defaultForExpenses, required bool defaultForIncome}) {
    return _ref.read(atomicWritesProvider).run(() async {
      await _ref.read(walletRepositoryProvider).save(wallet);

      final settingsRepository = _ref.read(settingsRepositoryProvider);
      final settings = await settingsRepository.get();
      String? next(String? current, bool selected) => selected ? wallet.id : (current == wallet.id ? null : current);
      final updated = settings.copyWith(
        defaultExpenseWalletId: next(settings.defaultExpenseWalletId, defaultForExpenses),
        defaultIncomeWalletId: next(settings.defaultIncomeWalletId, defaultForIncome),
      );
      if (updated != settings) await settingsRepository.save(updated);
    });
  }

  /// Archivia: il portafoglio sparisce dalle scelte e dal patrimonio, ma i movimenti restano.
  /// Se era predefinito, smette di esserlo.
  Future<void> archive(Wallet wallet) {
    final now = _ref.read(clockProvider)().toUtc();
    return save(wallet.copyWith(archivedAt: now), defaultForExpenses: false, defaultForIncome: false);
  }

  Future<void> unarchive(Wallet wallet) => _ref.read(walletRepositoryProvider).save(wallet.copyWith(archivedAt: null));

  /// "Aggiorna saldo": registra la differenza come rettifica o come entrata/spesa e, sempre,
  /// la data di verifica del saldo. Restituisce il movimento creato, o null se il saldo coincideva.
  Future<Transaction?> updateBalance({
    required Wallet wallet,
    required int newBalanceCents,
    required LocalDate date,
    required balances.BalanceUpdateMode mode,
    String? categoryId,
  }) {
    return _ref.read(atomicWritesProvider).run(() async {
      final transactions = _ref.read(transactionRepositoryProvider);
      final wallets = _ref.read(walletRepositoryProvider);

      // Saldo letto dentro la transazione: è quello su cui si basa la differenza scritta.
      final transaction = balances.balanceUpdateTransaction(
        id: newId(),
        wallet: wallet,
        transactions: await transactions.getAll(),
        newBalanceCents: newBalanceCents,
        date: date,
        mode: mode,
        categoryId: categoryId,
      );
      if (transaction != null) await transactions.save(transaction);

      // Si parte dalla versione salvata, per non sovrascrivere modifiche più recenti.
      final current = await wallets.getById(wallet.id) ?? wallet;
      final verified = balances.markBalanceVerified(current, date);
      if (verified != current) await wallets.save(verified);
      return transaction;
    });
  }
}

@Riverpod(keepAlive: true)
WalletActions walletActions(Ref ref) => WalletActions(ref);
