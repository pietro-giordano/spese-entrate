import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Riga etichetta/valore di un dettaglio ("Tipo   Spesa"). Il valore va a capo e non si
/// tronca mai: con testi lunghi o ingranditi la riga cresce in altezza.
/// Lo screen reader la legge come una frase sola ("Tipo: Spesa").
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, this.value, this.child})
    : assert(value != null || child != null, 'Serve un valore o un widget');

  final String label;
  final String? value;

  /// Al posto di [value], quando il valore è un widget (es. i chip delle label).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final content =
        child ??
        Text(
          value!,
          textAlign: TextAlign.end,
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        );

    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Anche l'etichetta va a capo se serve (testo molto ingrandito): al massimo 2/5 della riga.
            Flexible(
              flex: 2,
              child: Semantics(
                label: '$label:',
                excludeSemantics: true,
                child: Text(label, style: textTheme.bodyMedium?.copyWith(color: colors.textMuted)),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              flex: 3,
              child: Align(alignment: AlignmentDirectional.centerEnd, child: content),
            ),
          ],
        ),
      ),
    );
  }
}

/// Label come piccoli chip ("#casa") che vanno a capo: tutte visibili, senza ellissi.
class LabelTags extends StatelessWidget {
  const LabelTags(this.names, {super.key, this.alignment = WrapAlignment.end});

  final List<String> names;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return Wrap(
      alignment: alignment,
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final name in names)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.neutral.tint,
              borderRadius: BorderRadius.circular(AppRadius.labelChip),
            ),
            child: Text(
              '#$name',
              style: textTheme.labelMedium?.copyWith(color: colors.neutral.onTint, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}
