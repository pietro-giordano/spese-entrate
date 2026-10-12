import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'dashed_border.dart';

/// Forma del chip: pillola (categorie, portafogli, preset) o rettangolo arrotondato (label).
enum AppChipShape { pill, label }

/// Chip selezionabile.
///
/// Da selezionato usa [selectedTone]: di default è l'inversione (sfondo testo, testo su sfondo),
/// per le categorie si passa il colore del tipo (`context.colors.expense` / `income`).
/// L'area toccabile è alta almeno 44 px anche se il chip è più basso.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.shape = AppChipShape.pill,
    this.selectedTone,
    this.showCheck = false,
    this.dashed = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final AppChipShape shape;
  final ColorTone? selectedTone;

  /// Mostra una spunta quando è selezionato (filtri a scelta multipla).
  final bool showCheck;

  /// Bordo tratteggiato e sfondo trasparente, per le azioni (es. "+ Gestisci").
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tone = selectedTone ?? colors.neutral;
    final isPill = shape == AppChipShape.pill;

    final background = selected ? tone.fill : (dashed ? Colors.transparent : colors.surface);
    final foreground = selected ? tone.onFill : (dashed ? colors.neutral.onTint : colors.text);
    final borderColor = selected ? tone.fill : (dashed ? Colors.transparent : colors.borderStrong);
    final radius = isPill ? 18.0 : AppRadius.labelChip;

    final horizontalPadding = isPill ? 12.0 : 10.0;
    final iconWidth = selected && showCheck ? 20.0 : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Il testo è al massimo largo quanto lo spazio disponibile, poi va a capo. In una riga
        // che scorre in orizzontale (larghezza illimitata) resta su una riga.
        final maxTextWidth = constraints.hasBoundedWidth
            ? (constraints.maxWidth - 2 * horizontalPadding - iconWidth - 2).clamp(24.0, double.infinity)
            : double.infinity;
        return _chip(context, background, foreground, borderColor, radius, horizontalPadding, maxTextWidth);
      },
    );
  }

  Widget _chip(
    BuildContext context,
    Color background,
    Color foreground,
    Color borderColor,
    double radius,
    double horizontalPadding,
    double maxTextWidth,
  ) {
    final colors = context.colors;
    final isPill = shape == AppChipShape.pill;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        // Altezze minime, non fisse: un nome più largo della riga va a capo invece di sforare.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: CustomPaint(
              foregroundPainter: dashed ? DashedBorderPainter(color: colors.textMuted, radius: radius) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                constraints: BoxConstraints(minHeight: isPill ? 36 : 32),
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 6),
                decoration: BoxDecoration(
                  color: background,
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selected && showCheck) ...[
                      Icon(Icons.check_rounded, size: 14, color: foreground),
                      const SizedBox(width: 6),
                    ],
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxTextWidth),
                      child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: foreground)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
