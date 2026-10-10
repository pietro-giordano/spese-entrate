import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Pulsante icona 44×44 degli header (chiudi, indietro, cerca, filtri).
///
/// Con [round] diventa un cerchio con la tinta della liquidità (avatar del profilo).
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.round = false,
  });

  final IconData icon;

  /// Testo per lo screen reader e per la pressione prolungata.
  final String tooltip;
  final VoidCallback? onPressed;
  final bool round;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderRadius = BorderRadius.circular(round ? AppSizes.minTouchTarget / 2 : 14);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: round ? colors.liquidity.tint : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: round ? BorderSide.none : BorderSide(color: colors.border),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: borderRadius,
          child: SizedBox.square(
            dimension: AppSizes.minTouchTarget,
            child: Icon(
              icon,
              size: 20,
              color: round ? colors.liquidity.onTint : colors.text.withValues(alpha: onPressed == null ? 0.4 : 1),
            ),
          ),
        ),
      ),
    );
  }
}
