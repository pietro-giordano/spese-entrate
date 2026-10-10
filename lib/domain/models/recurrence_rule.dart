import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/dates.dart';
import 'enums.dart';

part 'recurrence_rule.freezed.dart';

/// Regola di un movimento ricorrente (spesa, entrata o trasferimento).
@freezed
abstract class RecurrenceRule with _$RecurrenceRule {
  const factory RecurrenceRule({
    required String id,
    required String name,
    required TransactionType type,
    required int amountCents,
    @Default('EUR') String currency,
    required String walletId,
    String? toWalletId,
    String? categoryId,
    String? note,
    @Default([]) List<String> labelIds,
    required RecurrenceFrequency frequency,
    @Default(1) int interval,

    /// 1 = lunedì … 7 = domenica.
    int? byWeekday,
    int? byMonthDay,
    int? byMonth,
    required LocalDate startDate,
    LocalDate? endDate,
    int? maxCount,
    required RecurrenceMode mode,
    DateTime? pausedAt,
  }) = _RecurrenceRule;

  const RecurrenceRule._();

  bool get isPaused => pausedAt != null;
}
