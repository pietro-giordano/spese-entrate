import 'package:flutter/material.dart';

import '../../../core/widgets/screen_placeholder.dart';

/// Modifica movimento.
class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  Widget build(BuildContext context) {
    return ScreenPlaceholder(title: 'Modifica movimento', description: 'Movimento $transactionId.');
  }
}
