import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Titoletto di sezione in maiuscolo (es. "CATEGORIA"), con testo opzionale a destra
/// (es. "2 selezionate").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing, this.indent = false});

  final String text;
  final String? trailing;

  /// Rientro di 4 px, usato sopra le card (es. Impostazioni).
  final bool indent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = Theme.of(context).textTheme.labelSmall;

    return Padding(
      padding: EdgeInsets.only(left: indent ? 4 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(text.toUpperCase(), style: style?.copyWith(color: colors.textMuted, letterSpacing: 0.72)),
            ),
          ),
          if (trailing != null) Text(trailing!, style: style?.copyWith(color: colors.neutral.onTint)),
        ],
      ),
    );
  }
}
