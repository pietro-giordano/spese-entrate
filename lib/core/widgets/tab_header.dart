import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_routes.dart';
import '../theme/app_tokens.dart';
import 'app_icon_button.dart';

/// Intestazione delle 4 tab: titolo, azioni della schermata e, sempre ultimo a destra,
/// l'avatar che apre Profilo e impostazioni. Così le impostazioni si raggiungono da ogni tab.
class TabHeader extends StatelessWidget {
  const TabHeader({super.key, required this.title, this.actions = const []});

  final String title;

  /// Azioni della schermata (es. cerca, filtri, +), mostrate prima dell'avatar.
  /// Di solito `AppIconButton`, che sono già 44×44.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          // container: nodi separati per titolo e pulsanti, anche dentro una lista che li unirebbe.
          child: Semantics(
            container: true,
            header: true,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
        ),
        for (final action in actions) ...[action, const SizedBox(width: AppSpacing.sm)],
        // Un solo nodo per lo screen reader: pulsante "Profilo e impostazioni" che apre /settings.
        Semantics(
          container: true,
          button: true,
          label: 'Profilo e impostazioni',
          onTap: () => _openSettings(context),
          excludeSemantics: true,
          child: AppIconButton(
            icon: Icons.person_outline_rounded,
            tooltip: 'Profilo e impostazioni',
            round: true,
            onPressed: () => _openSettings(context),
          ),
        ),
      ],
    );
  }

  static void _openSettings(BuildContext context) => context.push(AppRoutes.settings);
}
