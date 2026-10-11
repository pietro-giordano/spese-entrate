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
    this.badgeCount = 0,
  });

  final IconData icon;

  /// Testo per lo screen reader e per la pressione prolungata.
  final String tooltip;
  final VoidCallback? onPressed;
  final bool round;

  /// Numero mostrato nell'angolo (es. filtri attivi). 0 = nessun badge.
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderRadius = BorderRadius.circular(round ? AppSizes.minTouchTarget / 2 : 14);

    final button = Tooltip(
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
    if (badgeCount == 0) return button;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        Positioned(
          top: -5,
          right: -5,
          child: IgnorePointer(
            child: Container(
              constraints: const BoxConstraints(minWidth: 20),
              height: 20,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.income.fill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.background, width: 2),
              ),
              child: Text(
                '$badgeCount',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: colors.income.onFill, fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
