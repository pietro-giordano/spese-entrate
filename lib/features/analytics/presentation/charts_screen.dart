import 'package:flutter/material.dart';

import '../../../core/widgets/screen_placeholder.dart';

/// Tab Grafici.
class ChartsScreen extends StatelessWidget {
  const ChartsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenPlaceholder(
      title: 'Grafici',
      leading: PlaceholderLeading.none,
      description: 'Spese ed entrate per categoria o label.',
    );
  }
}
