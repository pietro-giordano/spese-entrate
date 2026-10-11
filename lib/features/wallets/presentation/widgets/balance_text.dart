import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/money.dart';
import '../../application/balance_visibility.dart';

/// Un saldo che segue l'occhio di Portafogli ([balancesHiddenProvider]).
///
/// Nascosto mostra "€ ••••" nello spazio dell'importo vero (che resta invisibile, così
/// l'impaginazione non salta) e lo screen reader dice "Saldo nascosto".
class BalanceText extends ConsumerWidget {
  const BalanceText(this.cents, {super.key, this.format = formatCents, this.prefix = '', this.style, this.textAlign});

  final int cents;

  /// Come scrivere l'importo visibile (es. con "+" davanti).
  final String Function(int cents) format;

  /// Testo prima dell'importo, che resta visibile (es. "Disponibile ").
  final String prefix;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = Text('$prefix${format(cents)}', style: style, textAlign: textAlign, maxLines: 1);
    if (!ref.watch(balancesHiddenProvider)) return visible;

    final alignEnd = textAlign == TextAlign.end || textAlign == TextAlign.right;
    return Semantics(
      label: '${prefix}Saldo nascosto',
      excludeSemantics: true,
      child: Stack(
        alignment: alignEnd ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
        children: [
          Visibility(visible: false, maintainSize: true, maintainAnimation: true, maintainState: true, child: visible),
          Text('$prefix$hiddenBalanceText', style: style, textAlign: textAlign, maxLines: 1),
        ],
      ),
    );
  }
}
