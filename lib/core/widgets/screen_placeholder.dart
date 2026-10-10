import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'app_icon_button.dart';
import 'app_list_row.dart';
import 'section_label.dart';

/// Cosa mostrare a sinistra del titolo.
enum PlaceholderLeading { none, back, close }

/// Schermata provvisoria: header nello stile dell'app, una descrizione e collegamenti
/// per provare la navigazione. Verrà sostituita dalle schermate vere nei passi successivi.
class ScreenPlaceholder extends StatelessWidget {
  const ScreenPlaceholder({
    super.key,
    required this.title,
    this.leading = PlaceholderLeading.back,
    this.description,
    this.links = const {},
    this.headerActions = const [],
    this.bottomBar,
  });

  final String title;
  final PlaceholderLeading leading;
  final String? description;

  /// Etichetta → indirizzo da aprire con `context.push`.
  final Map<String, String> links;
  final List<Widget> headerActions;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isTab = leading == PlaceholderLeading.none;

    return Scaffold(
      bottomNavigationBar: bottomBar,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 14, AppSpacing.screen, AppSpacing.xxl),
          children: [
            Row(
              children: [
                if (leading == PlaceholderLeading.back)
                  AppIconButton(icon: Icons.chevron_left_rounded, tooltip: 'Indietro', onPressed: () => context.pop()),
                if (leading == PlaceholderLeading.close)
                  AppIconButton(icon: Icons.close_rounded, tooltip: 'Chiudi', onPressed: () => context.pop()),
                if (!isTab) const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: isTab ? textTheme.headlineLarge : textTheme.headlineMedium),
                  ),
                ),
                for (final action in headerActions) ...[const SizedBox(width: AppSpacing.sm), action],
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              description ?? 'Schermata in costruzione.',
              style: textTheme.bodyLarge?.copyWith(color: context.colors.textMuted),
            ),
            if (links.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xxl),
              const SectionLabel('Collegamenti', indent: true),
              const SizedBox(height: AppSpacing.sm),
              AppListGroup(
                children: [
                  for (final link in links.entries)
                    AppListRow(title: link.key, value: link.value, onTap: () => context.push(link.value)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
