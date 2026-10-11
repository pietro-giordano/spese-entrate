import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';

/// Chiede conferma prima di eliminare un movimento. Restituisce true se l'utente conferma.
Future<bool> confirmDeleteTransaction(BuildContext context, {required String summary}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final colors = context.colors;
      final textTheme = Theme.of(context).textTheme;
      final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
      const buttonSize = Size.fromHeight(50);

      return Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.xxl),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(header: true, child: Text('Eliminare questo movimento?', style: textTheme.titleLarge)),
              const SizedBox(height: 10),
              Text(
                '$summary. Verranno eliminati anche gli allegati. Potrai annullare per qualche secondo dalla lista.',
                style: textTheme.bodyMedium?.copyWith(color: colors.neutral.onTint, height: 1.45),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: buttonSize, shape: buttonShape),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annulla'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: buttonSize,
                        shape: buttonShape,
                        backgroundColor: colors.expense.fill,
                        foregroundColor: colors.expense.onFill,
                        textStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Elimina'),
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
