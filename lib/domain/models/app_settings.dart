import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/dates.dart';

part 'app_settings.freezed.dart';

/// Impostazioni sincronizzabili (tabella `settings`) in forma tipizzata.
@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    String? defaultExpenseWalletId,
    String? defaultIncomeWalletId,

    /// 1 = lunedì … 7 = domenica.
    @Default(DateTime.monday) int weekStart,
    @Default(PeriodType.month) PeriodType defaultPeriod,
    @Default('EUR') String currency,
  }) = _AppSettings;
}
