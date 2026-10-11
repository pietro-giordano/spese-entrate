import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/dates.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/enums.dart';
import '../../../../domain/models/wallet.dart';

/// Icona del tipo di portafoglio.
IconData walletTypeIcon(WalletType type) => switch (type) {
  WalletType.cash => Icons.payments_outlined,
  WalletType.checking => Icons.account_balance_outlined,
  WalletType.card => Icons.credit_card_rounded,
  WalletType.savings => Icons.savings_outlined,
  WalletType.investment => Icons.trending_up_rounded,
  WalletType.other => Icons.account_balance_wallet_outlined,
};

String walletTypeLabel(WalletType type) => switch (type) {
  WalletType.cash => 'Contanti',
  WalletType.checking => 'Conto corrente',
  WalletType.card => 'Carta',
  WalletType.savings => 'Risparmio',
  WalletType.investment => 'Investimenti',
  WalletType.other => 'Altro',
};

String walletGroupLabel(WalletGroup group) => switch (group) {
  WalletGroup.liquidity => 'Liquidità',
  WalletGroup.savings => 'Risparmi',
  WalletGroup.investments => 'Investimenti',
};

/// Colori del gruppo (barra del patrimonio, icone, badge del tipo).
ColorTone walletGroupTone(BuildContext context, WalletGroup group) => switch (group) {
  WalletGroup.liquidity => context.colors.liquidity,
  WalletGroup.savings => context.colors.savings,
  WalletGroup.investments => context.colors.investments,
};

/// "Aggiornato oggi", "Aggiornato ieri", "Aggiornato il 28 set" (con l'anno se diverso).
String lastUpdateLabel(LocalDate date, LocalDate today) {
  if (date == today) return 'Aggiornato oggi';
  if (date == today.addDays(-1)) return 'Aggiornato ieri';
  final pattern = date.year == today.year ? 'd MMM' : 'd MMM y';
  return 'Aggiornato il ${DateFormat(pattern, 'it_IT').format(date.toDateTime())}';
}

/// Riquadro 40×40 con l'icona del tipo sulla tinta del gruppo.
class WalletIcon extends StatelessWidget {
  const WalletIcon({super.key, required this.type, this.muted = false});

  final WalletType type;

  /// Grigio per i portafogli archiviati.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final tone = muted ? context.colors.neutral : walletGroupTone(context, type.group);
    return ExcludeSemantics(
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: tone.tint, borderRadius: BorderRadius.circular(12)),
        child: Icon(walletTypeIcon(type), size: 20, color: tone.onTint),
      ),
    );
  }
}

/// Etichetta a pillola (es. "Predefinito spese", "Da aggiornare").
class WalletBadge extends StatelessWidget {
  const WalletBadge({super.key, required this.text, required this.tone});

  final String text;
  final ColorTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(color: tone.tint, borderRadius: BorderRadius.circular(10)),
      // widthFactor 1: largo quanto il testo (un Container con alignment si allargherebbe).
      child: Center(
        widthFactor: 1,
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(fontSize: 11, fontWeight: FontWeight.w800, color: tone.onTint),
        ),
      ),
    );
  }
}
