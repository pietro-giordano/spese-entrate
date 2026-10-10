import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../application/quick_add_controller.dart';

/// Tastierino 3×4: 1–9, 00, 0, cancella. Tenere premuto cancella azzera l'importo.
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({super.key, required this.onKey, required this.onClear});

  final ValueChanged<String> onKey;
  final VoidCallback onClear;

  static const _keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '00', '0', backspaceKey];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var row = 0; row < 4; row++) ...[
          if (row > 0) const SizedBox(height: 8),
          Row(
            children: [
              for (var col = 0; col < 3; col++) ...[
                if (col > 0) const SizedBox(width: 8),
                Expanded(
                  child: _KeypadKey(keyValue: _keys[row * 3 + col], onKey: onKey, onClear: onClear),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _KeypadKey extends StatelessWidget {
  const _KeypadKey({required this.keyValue, required this.onKey, required this.onClear});

  final String keyValue;
  final ValueChanged<String> onKey;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isBackspace = keyValue == backspaceKey;
    final borderRadius = BorderRadius.circular(14);

    return Semantics(
      button: true,
      label: isBackspace ? 'Cancella' : keyValue,
      excludeSemantics: true,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: colors.border),
        ),
        child: InkWell(
          borderRadius: borderRadius,
          onTap: () {
            HapticFeedback.selectionClick();
            onKey(keyValue);
          },
          onLongPress: isBackspace ? onClear : null,
          child: SizedBox(
            height: 48,
            child: Center(
              child: isBackspace
                  ? Icon(Icons.backspace_outlined, size: 22, color: colors.text)
                  : Text(
                      keyValue,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
