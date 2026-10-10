import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Pannello dal basso con maniglia e titolo.
///
/// Si apre con [AppBottomSheet.show], che restituisce il valore passato a `Navigator.pop`.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({super.key, this.title, this.titleTrailing, required this.child});

  final String? title;

  /// Testo o widget a destra del titolo (es. "1 di 5").
  final Widget? titleTrailing;
  final Widget child;

  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    Widget? titleTrailing,
    required WidgetBuilder builder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => AppBottomSheet(title: title, titleTrailing: titleTrailing, child: builder(context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom + MediaQuery.paddingOf(context).bottom;

    return Padding(
      // Con la tastiera aperta il pannello sale sopra di essa.
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, 10, AppSpacing.xl, 22 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(color: colors.borderStrong, borderRadius: BorderRadius.circular(3)),
            ),
          ),
          if (title != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Semantics(header: true, child: Text(title!, style: Theme.of(context).textTheme.titleLarge)),
                ),
                // `?` aggiunge l'elemento alla lista solo se non è null.
                ?titleTrailing,
              ],
            ),
          ],
          const SizedBox(height: 14),
          Flexible(child: SingleChildScrollView(child: child)),
        ],
      ),
    );
  }
}
