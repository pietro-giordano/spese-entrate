import 'package:flutter/material.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/screen_placeholder.dart';

class WalletDetailScreen extends StatelessWidget {
  const WalletDetailScreen({super.key, required this.walletId});

  final String walletId;

  @override
  Widget build(BuildContext context) {
    return ScreenPlaceholder(
      title: 'Portafoglio',
      description: 'Saldo, andamento e movimenti del portafoglio $walletId.',
      links: {'Modifica portafoglio': AppRoutes.editWallet(walletId)},
    );
  }
}
