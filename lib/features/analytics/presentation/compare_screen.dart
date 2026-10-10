import 'package:flutter/material.dart';

import '../../../core/widgets/screen_placeholder.dart';

/// Tab Confronta.
class CompareScreen extends StatelessWidget {
  const CompareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenPlaceholder(
      title: 'Confronta',
      leading: PlaceholderLeading.none,
      description: 'Confronto fino a 3 periodi.',
    );
  }
}
