import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'app_bottom_sheet.dart';
import 'app_list_row.dart';

/// Un'opzione di [showChoiceSheet].
class Choice<T> {
  const Choice({required this.value, required this.label, this.subtitle});

  final T value;
  final String label;
  final String? subtitle;
}

/// Pannello con un elenco a scelta singola. Restituisce il valore scelto, o null se chiuso.
Future<T?> showChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<Choice<T>> choices,
  required T? selected,
  String? hint,
}) {
  return AppBottomSheet.show<T>(
    context,
    title: title,
    builder: (sheetContext) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppListGroup(
          children: [
            for (final choice in choices)
              Semantics(
                inMutuallyExclusiveGroup: true,
                checked: choice.value == selected,
                child: AppListRow(
                  title: choice.label,
                  subtitle: choice.subtitle,
                  trailing: _RadioDot(selected: choice.value == selected),
                  onTap: () => Navigator.pop(sheetContext, choice.value),
                ),
              ),
          ],
        ),
        if (hint != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(hint, style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(height: 1.45)),
        ],
      ],
    ),
  );
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surface,
        border: Border.all(color: selected ? colors.text : colors.textMuted, width: selected ? 6 : 2),
      ),
    );
  }
}
