import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/label_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../db/database_provider.dart';
import 'drift_category_repository.dart';
import 'drift_label_repository.dart';
import 'drift_settings_repository.dart';
import 'drift_transaction_repository.dart';
import 'drift_wallet_repository.dart';

part 'repository_providers.g.dart';

// Il tipo restituito è l'interfaccia: il resto dell'app non sa che sotto c'è Drift.
// In futuro qui si potrà scegliere un'implementazione con sincronizzazione.

@Riverpod(keepAlive: true)
WalletRepository walletRepository(Ref ref) => DriftWalletRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
CategoryRepository categoryRepository(Ref ref) => DriftCategoryRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
LabelRepository labelRepository(Ref ref) => DriftLabelRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
TransactionRepository transactionRepository(Ref ref) => DriftTransactionRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) => DriftSettingsRepository(ref.watch(appDatabaseProvider));
