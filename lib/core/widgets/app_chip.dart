import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

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
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final AppChipShape shape;
  final ColorTone? selectedTone;

  /// Mostra una spunta quando è selezionato (filtri a scelta multipla).
  final bool showCheck;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tone = selectedTone ?? colors.neutral;
    final isPill = shape == AppChipShape.pill;

    final background = selected ? tone.fill : colors.surface;
    final foreground = selected ? tone.onFill : colors.text;
    final borderColor = selected ? tone.fill : colors.borderStrong;

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: AppSizes.minTouchTarget,
          child: Center(
            widthFactor: 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: isPill ? 36 : 32,
              padding: EdgeInsets.symmetric(horizontal: isPill ? 12 : 10),
              decoration: BoxDecoration(
                color: background,
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(isPill ? 18 : AppRadius.labelChip),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected && showCheck) ...[
                    Icon(Icons.check_rounded, size: 14, color: foreground),
                    const SizedBox(width: 6),
                  ],
                  Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: foreground)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
