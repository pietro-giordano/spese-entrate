import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/dates.dart';
import 'enums.dart';

part 'wallet.freezed.dart';

@freezed
abstract class Wallet with _$Wallet {
  const factory Wallet({
    required String id,
    required String name,
    required WalletType type,
    @Default('EUR') String currency,
    @Default(0) int initialBalanceCents,
    required LocalDate initialBalanceDate,
    @Default(true) bool includeInTotal,
    @Default(0) int sortOrder,
    DateTime? archivedAt,

    /// Ultima volta che l'utente ha verificato il saldo con "Aggiorna saldo" (anche senza differenze).
    LocalDate? lastBalanceVerifiedDate,
  }) = _Wallet;

  const Wallet._();

  bool get isArchived => archivedAt != null;
}

/// Gruppi della schermata Portafogli.
enum WalletGroup { liquidity, savings, investments }

extension WalletTypeGroup on WalletType {
  /// Contanti, conto, carta e "altro" sono liquidità.
  WalletGroup get group => switch (this) {
    WalletType.savings => WalletGroup.savings,
    WalletType.investment => WalletGroup.investments,
    _ => WalletGroup.liquidity,
  };
}
