import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Messaggio centrato per uno stato vuoto o un errore: icona, titolo, spiegazione
/// e, se serve, un pulsante (es. "Riprova", "Nuovo portafoglio").
class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  /// Errore nel caricare [what] (es. "i portafogli"), con "Riprova".
  const StateMessage.error({super.key, required String what, required VoidCallback onRetry})
    : icon = Icons.error_outline_rounded,
      title = 'Non è stato possibile caricare $what',
      message = 'I dati sono al sicuro sul telefono. Riprova; se il problema continua, riavvia l\'app.',
      actionLabel = 'Riprova',
      onAction = onRetry;

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl, horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: Icon(icon, size: 40, color: colors.textMuted)),
          const SizedBox(height: AppSpacing.md),
          Text(title, textAlign: TextAlign.center, style: textTheme.titleMedium),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, AppSizes.minTouchTarget)),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
