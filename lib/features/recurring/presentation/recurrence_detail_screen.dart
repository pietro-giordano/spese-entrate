import 'package:flutter/material.dart';

import '../../../core/widgets/screen_placeholder.dart';

class RecurrenceDetailScreen extends StatelessWidget {
  const RecurrenceDetailScreen({super.key, required this.recurrenceId});

  final String recurrenceId;

  @override
  Widget build(BuildContext context) {
    return ScreenPlaceholder(title: 'Ricorrenza', description: 'Dettaglio della ricorrenza $recurrenceId.');
  }
}
