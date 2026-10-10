import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Interruttore 52×32 dei mockup. Acceso = blu entrata, spento = grigio.
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged, this.semanticLabel});

  final bool value;

  /// Null = disattivato.
  final ValueChanged<bool>? onChanged;

  /// Testo letto dallo screen reader quando l'interruttore non ha un'etichetta vicina.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onChanged != null;

    return Semantics(
      toggled: value,
      enabled: enabled,
      label: semanticLabel,
      child: GestureDetector(
        onTap: enabled ? () => onChanged!(!value) : null,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: AppSizes.minTouchTarget,
          child: Center(
            widthFactor: 1,
            child: Opacity(
              opacity: enabled ? 1 : 0.5,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 52,
                height: 32,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: value ? colors.income.fill : colors.switchTrackOff,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: colors.switchThumb,
                      shape: BoxShape.circle,
                      boxShadow: colors.switchThumbShadow,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
