import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/screen_placeholder.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenPlaceholder(
      title: 'Profilo e impostazioni',
      links: {
        'Categorie e label': AppRoutes.categories,
        'Movimenti ricorrenti': AppRoutes.recurring,
        'Backup ed esportazione': AppRoutes.backup,
        if (kDebugMode) 'Catalogo componenti': AppRoutes.componentCatalog,
      },
    );
  }
}
