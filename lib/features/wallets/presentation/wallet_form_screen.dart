import 'package:flutter/material.dart';

import '../../../core/widgets/screen_placeholder.dart';

/// Nuovo portafoglio ([walletId] null) o modifica di uno esistente.
class WalletFormScreen extends StatelessWidget {
  const WalletFormScreen({super.key, this.walletId});

  final String? walletId;

  @override
  Widget build(BuildContext context) {
    final isNew = walletId == null;
    return ScreenPlaceholder(
      title: isNew ? 'Nuovo portafoglio' : 'Modifica portafoglio',
      description: isNew ? 'Nome, tipo e saldo iniziale.' : 'Modifica del portafoglio $walletId.',
    );
  }
}
