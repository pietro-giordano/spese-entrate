import 'package:flutter/material.dart';

import '../../../core/widgets/screen_placeholder.dart';

class FiltersScreen extends StatelessWidget {
  const FiltersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenPlaceholder(
      title: 'Filtri',
      leading: PlaceholderLeading.close,
      description: 'Tipo, periodo, portafogli, categorie e label.',
    );
  }
}
