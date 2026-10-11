import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Spazio occupato in basso dal sistema: barra di navigazione (3 pulsanti o gesti), barra home
/// dell'iPhone e, con [includeKeyboard], la tastiera aperta.
///
/// Si usa `viewPadding` e non `padding`: con l'edge-to-edge di Android e dentro uno Scaffold il
/// `padding` può essere già stato consumato o azzerato dalla tastiera, `viewPadding` no.
/// La tastiera copre anche la barra di sistema: si prende il più grande dei due, non la somma.
double bottomSystemInset(BuildContext context, {bool includeKeyboard = true}) {
  final system = MediaQuery.viewPaddingOf(context).bottom;
  return includeKeyboard ? math.max(system, MediaQuery.viewInsetsOf(context).bottom) : system;
}

/// Barra fissata in basso con i pulsanti di una schermata (salva, applica, …), da mettere in
/// `Scaffold.bottomNavigationBar`.
///
/// Al proprio [padding] aggiunge lo spazio di [bottomSystemInset]: i pulsanti non finiscono mai
/// sotto la barra di navigazione di sistema e, con [avoidKeyboard], restano sopra la tastiera.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.md, AppSpacing.screen, AppSpacing.md),
    this.color,
    this.showBorder = true,
    this.avoidKeyboard = true,
  });

  final Widget child;

  /// Spazio attorno al contenuto, prima di quello del sistema.
  final EdgeInsets padding;

  /// Sfondo della barra; di base il colore delle superfici.
  final Color? color;

  /// Bordo sottile in alto, che separa la barra dal contenuto che scorre.
  final bool showBorder;

  /// False per le barre che la tastiera può coprire (es. la barra delle tab).
  final bool avoidKeyboard;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? colors.surface,
        border: showBorder ? Border(top: BorderSide(color: colors.border)) : null,
      ),
      child: Padding(
        padding: padding.copyWith(bottom: padding.bottom + bottomSystemInset(context, includeKeyboard: avoidKeyboard)),
        child: child,
      ),
    );
  }
}
