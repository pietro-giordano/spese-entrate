import 'package:flutter/material.dart';

import '../../../../core/money.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';

/// Scheda Da/A del trasferimento con il pulsante per invertire i portafogli.
class TransferWalletsCard extends StatelessWidget {
  const TransferWalletsCard({
    super.key,
    required this.fromName,
    required this.fromBalanceCents,
    required this.toName,
    required this.toBalanceCents,
    required this.onTapFrom,
    required this.onTapTo,
    required this.onSwap,
  });

  final String fromName;
  final int? fromBalanceCents;
  final String toName;
  final int? toBalanceCents;
  final VoidCallback onTapFrom;
  final VoidCallback onTapTo;
  final VoidCallback? onSwap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: colors.border),
      ),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          Column(
            children: [
              _WalletRow(
                prefix: 'Da',
                name: fromName,
                detail: fromBalanceCents == null ? null : 'Disponibile ${formatCents(fromBalanceCents!)}',
                onTap: onTapFrom,
              ),
              const Divider(indent: 14, endIndent: 14),
              _WalletRow(
                prefix: 'A',
                name: toName,
                detail: toBalanceCents == null ? null : 'Saldo ${formatCents(toBalanceCents!)}',
                onTap: onTapTo,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Tooltip(
              message: 'Inverti portafogli',
              child: Material(
                color: colors.background,
                shape: CircleBorder(side: BorderSide(color: colors.borderStrong)),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onSwap,
                  child: SizedBox.square(
                    dimension: AppSizes.minTouchTarget,
                    child: Icon(Icons.swap_vert_rounded, size: 20, color: colors.text),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletRow extends StatelessWidget {
  const _WalletRow({required this.prefix, required this.name, required this.detail, required this.onTap});

  final String prefix;
  final String name;
  final String? detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: '${prefix == 'Da' ? 'Da' : 'A'}: $name',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 72,
          child: Padding(
            // A destra resta lo spazio del pulsante per invertire.
            padding: const EdgeInsets.only(left: 14, right: 64),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    prefix,
                    style: textTheme.labelSmall?.copyWith(color: colors.textMuted, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.titleMedium),
                      if (detail != null) ...[const SizedBox(height: 2), Text(detail!, style: textTheme.bodySmall)],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
