import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'app_chip.dart';
import 'dashed_border.dart';

/// Stato visivo di un [AppFilterChip].
enum AppFilterChipMode { neutral, included, excluded }

/// Chip dei filtri a tre stati: neutro → incluso (✓, inversione) → escluso (✕, testo barrato,
/// bordo tratteggiato nel colore di pericolo) → neutro. Ogni tocco passa allo stato successivo.
///
/// Per lo screen reader dice il nome, lo stato e cosa fa il prossimo tocco.
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.mode,
    required this.onTap,
    this.shape = AppChipShape.pill,
  });

  final String label;
  final AppFilterChipMode mode;
  final VoidCallback onTap;
  final AppChipShape shape;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isPill = shape == AppChipShape.pill;
    final radius = isPill ? 18.0 : AppRadius.labelChip;
    final (Color background, Color foreground, Color border) = switch (mode) {
      AppFilterChipMode.neutral => (colors.surface, colors.text, colors.borderStrong),
      AppFilterChipMode.included => (colors.neutral.fill, colors.neutral.onFill, colors.neutral.fill),
      AppFilterChipMode.excluded => (Colors.transparent, colors.danger, Colors.transparent),
    };
    final (String state, String hint) = switch (mode) {
      AppFilterChipMode.neutral => ('non filtrato', 'tocca per includere'),
      AppFilterChipMode.included => ('incluso', 'tocca per escludere'),
      AppFilterChipMode.excluded => ('escluso', 'tocca per togliere il filtro'),
    };

    return Semantics(
      container: true,
      button: true,
      label: label,
      value: state,
      hint: hint,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: AppSizes.minTouchTarget,
          child: Center(
            widthFactor: 1,
            child: CustomPaint(
              foregroundPainter: mode == AppFilterChipMode.excluded
                  ? DashedBorderPainter(color: colors.danger, radius: radius)
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: isPill ? 36 : 32,
                padding: EdgeInsets.symmetric(horizontal: isPill ? 12 : 10),
                decoration: BoxDecoration(
                  color: background,
                  border: Border.all(color: border),
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (mode != AppFilterChipMode.neutral) ...[
                      Icon(
                        mode == AppFilterChipMode.included ? Icons.check_rounded : Icons.close_rounded,
                        size: 14,
                        color: foreground,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: foreground,
                        decoration: mode == AppFilterChipMode.excluded ? TextDecoration.lineThrough : null,
                        decorationColor: foreground,
                      ),
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
