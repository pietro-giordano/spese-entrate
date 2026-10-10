import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/dates.dart';
import 'enums.dart';

part 'transaction.freezed.dart';

/// Movimento: spesa, entrata, trasferimento o rettifica di saldo.
@freezed
abstract class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required TransactionType type,
    @Default(TransactionStatus.confirmed) TransactionStatus status,

    /// Sempre > 0, tranne le rettifiche che hanno segno.
    required int amountCents,
    @Default('EUR') String currency,
    required LocalDate date,

    /// Portafoglio del movimento; per i trasferimenti è quello di origine.
    required String walletId,

    /// Solo per i trasferimenti.
    String? toWalletId,

    /// Obbligatoria per spese ed entrate.
    String? categoryId,
    String? note,
    @Default([]) List<String> labelIds,
    String? recurrenceId,
    LocalDate? occurrenceDate,
  }) = _Transaction;

  const Transaction._();

  bool get isConfirmed => status == TransactionStatus.confirmed;
}
