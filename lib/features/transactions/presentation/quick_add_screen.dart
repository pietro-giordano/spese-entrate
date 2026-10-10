import 'package:flutter/material.dart';

import '../../../core/widgets/screen_placeholder.dart';

/// Inserimento rapido, aperto a schermo intero dal basso.
class QuickAddScreen extends StatelessWidget {
  const QuickAddScreen({super.key, required this.type});

  /// `expense`, `income` o `transfer`.
  final String type;

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      'income' => 'Entrata',
      'transfer' => 'Trasferimento',
      _ => 'Spesa',
    };
    return ScreenPlaceholder(
      title: 'Nuovo movimento',
      leading: PlaceholderLeading.close,
      description: 'Inserimento rapido · tipo iniziale: $label.',
    );
  }
}
