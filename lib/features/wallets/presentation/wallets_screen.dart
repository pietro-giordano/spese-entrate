import 'package:flutter/material.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/screen_placeholder.dart';

/// Tab Portafogli.
class WalletsScreen extends StatelessWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenPlaceholder(
      title: 'Portafogli',
      leading: PlaceholderLeading.none,
      description: 'Patrimonio totale e portafogli per gruppo.',
      links: {
        'Nuovo portafoglio': AppRoutes.newWallet,
        'Portafoglio di esempio': AppRoutes.wallet('esempio'),
        'Trasferisci': AppRoutes.add('transfer'),
      },
    );
  }
}
