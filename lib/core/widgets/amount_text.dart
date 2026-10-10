import 'package:flutter/material.dart';

import '../money.dart';
import '../theme/app_colors.dart';

/// Tipo di importo: decide segno e colore.
enum AmountKind { expense, income, neutral }

/// Importo formattato `€ 1.234,56` con cifre tabulari.
///
/// - [AmountKind.expense] → `− € …`, colore spesa (o testo se [colored] è false).
/// - [AmountKind.income] → `+ € …`, colore entrata.
/// - [AmountKind.neutral] → nessun segno se positivo, `− € …` se negativo.
///
/// Nelle liste i movimenti di spesa si mostrano con `colored: false`, come nei mockup.
class AmountText extends StatelessWidget {
  const AmountText(
    this.cents, {
    super.key,
    this.kind = AmountKind.neutral,
    this.showSign = true,
    this.colored = true,
    this.style,
    this.textAlign,
  });

  /// Valore assoluto per spese ed entrate; con segno per [AmountKind.neutral].
  final int cents;
  final AmountKind kind;
  final bool showSign;
  final bool colored;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final text = switch (kind) {
      AmountKind.expense => showSign ? '$minusSign ${formatCents(cents.abs())}' : formatCents(cents.abs()),
      AmountKind.income => showSign ? '+ ${formatCents(cents.abs())}' : formatCents(cents.abs()),
      AmountKind.neutral => showSign ? formatCents(cents) : formatCents(cents.abs()),
    };

    final color = switch (kind) {
      AmountKind.expense when colored => colors.expense.text,
      AmountKind.income when colored => colors.income.text,
      _ => colors.text,
    };

    final baseStyle = style ?? DefaultTextStyle.of(context).style.copyWith(fontWeight: FontWeight.w700);

    return Text(
      text,
      textAlign: textAlign,
      maxLines: 1,
      style: baseStyle.copyWith(color: color, fontFeatures: const [FontFeature.tabularFigures()]),
    );
  }
}
