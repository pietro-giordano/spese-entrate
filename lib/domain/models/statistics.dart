import 'package:freezed_annotation/freezed_annotation.dart';

part 'statistics.freezed.dart';

/// Riepilogo di un periodo: solo spese ed entrate confermate.
@freezed
abstract class PeriodSummary with _$PeriodSummary {
  const factory PeriodSummary({required int incomeCents, required int expenseCents}) = _PeriodSummary;

  const PeriodSummary._();

  /// Entrate − uscite.
  int get balanceCents => incomeCents - expenseCents;

  /// Quota delle entrate già spesa (0.31 = 31%). Null se non ci sono entrate.
  double? get spentRatio => incomeCents == 0 ? null : expenseCents / incomeCents;
}

/// Totale di una voce di un grafico (categoria o label).
@freezed
abstract class BreakdownItem with _$BreakdownItem {
  const factory BreakdownItem({
    /// ID della categoria o della label; null = "Senza label".
    required String? id,
    required int totalCents,

    /// Quota sul totale del grafico, tra 0 e 1.
    required double share,
  }) = _BreakdownItem;
}
