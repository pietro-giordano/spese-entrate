import 'package:flutter/material.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/screen_placeholder.dart';

class RecurringListScreen extends StatelessWidget {
  const RecurringListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenPlaceholder(
      title: 'Movimenti ricorrenti',
      links: {'Ricorrenza di esempio': AppRoutes.recurrence('esempio')},
    );
  }
}
