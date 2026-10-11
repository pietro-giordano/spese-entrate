import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Dialog di conferma con Annulla e un'azione. Restituisce true se l'utente conferma.
/// Con [destructive] il pulsante di conferma usa il colore pieno della spesa.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final colors = context.colors;
      final textTheme = Theme.of(context).textTheme;
      final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
      const size = Size.fromHeight(50);
      return Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.xxl),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(header: true, child: Text(title, style: textTheme.titleLarge)),
              const SizedBox(height: 10),
              Text(message, style: textTheme.bodyMedium?.copyWith(color: colors.neutral.onTint, height: 1.45)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: size, shape: shape),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annulla'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: size,
                        shape: shape,
                        backgroundColor: destructive ? colors.expense.fill : null,
                        foregroundColor: destructive ? colors.expense.onFill : null,
                        textStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(confirmLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  return confirmed ?? false;
}
