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
            child: CustomPaint(
              foregroundPainter: dashed ? _DashedBorderPainter(color: colors.textMuted, radius: radius) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: isPill ? 36 : 32,
                padding: EdgeInsets.symmetric(horizontal: isPill ? 12 : 10),
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
                    Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: foreground)),
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

/// Disegna un bordo tratteggiato arrotondato (Flutter non ne ha uno pronto).
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rect = RRect.fromRectAndRadius((Offset.zero & size).deflate(0.5), Radius.circular(radius));
    // Percorre il contorno alternando tratti da 4 px e spazi da 3 px.
    for (final metric in (Path()..addRRect(rect)).computeMetrics()) {
      for (var distance = 0.0; distance < metric.length; distance += 7) {
        canvas.drawPath(metric.extractPath(distance, distance + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => oldDelegate.color != color || oldDelegate.radius != radius;
}
