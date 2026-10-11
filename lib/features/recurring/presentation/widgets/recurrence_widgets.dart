import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../../../domain/models/enums.dart';

/// Riquadro 40×40 con l'icona della ripetizione, colorato per tipo
/// (spesa, entrata, trasferimento neutro).
class RecurrenceIcon extends StatelessWidget {
  const RecurrenceIcon({super.key, required this.type});

  final TransactionType type;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tone = switch (type) {
      TransactionType.expense => colors.expense,
      TransactionType.income => colors.income,
      _ => colors.neutral,
    };
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: tone.tint, borderRadius: BorderRadius.circular(12)),
      child: Icon(
        type == TransactionType.transfer ? Icons.swap_horiz_rounded : Icons.repeat_rounded,
        size: 18,
        color: tone.onTint,
      ),
    );
  }
}

/// Segno e colore di [AmountText] per il tipo: "− € 10,99", "+ € 2.400,00", "€ 500,00".
AmountKind amountKindOf(TransactionType type) => switch (type) {
  TransactionType.expense => AmountKind.expense,
  TransactionType.income => AmountKind.income,
  _ => AmountKind.neutral,
};

/// Pillola di stato: "Automatico", "Da confermare", "In pausa", "Conclusa".
class RecurrenceBadge extends StatelessWidget {
  const RecurrenceBadge({super.key, required this.label, required this.tone});

  final String label;
  final ColorTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(color: tone.tint, borderRadius: BorderRadius.circular(10)),
      // widthFactor 1: centrato in verticale ma largo quanto il testo.
      child: Center(
        widthFactor: 1,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: tone.onTint, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
